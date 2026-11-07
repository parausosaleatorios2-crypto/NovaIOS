// ---------------------------------------------------------------------------
// Datamosh (corrupção de compressão)
// origem : assets/effects/datamosh.xml
// id     : nova.effect.datamosh
// passes : 6
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct datamoshParams {
    int colorspace;
    float amplification;
    float errorGamma;
    float errorThreshold;
    int invertError;
    float errorBlur;
};

// --- funcoes auxiliares do efeito
// ===========================================================================
//  A base de cosseno da DCT-II — a MESMA fórmula que qualquer JPEG usa
// ===========================================================================
const float PI_16 = 3.14159265359 / 16.0;

// alpha(0) = 1/sqrt(2), alpha(u>0) = 1 — a normalização padrão da DCT-II
// ortonormal (é o que faz a matriz de base ser ORTOGONAL, e por isso a
// inversa ser só a transposta escalada por 0,25 — ver a nota da direção 3.4).
float alphaDct(int u) {
    return u == 0 ? 0.70710678118 : 1.0;
}

float baseDct(int u, int x) {
    return cos((2.0 * float(x) + 1.0) * float(u) * PI_16);
}

// ===========================================================================
//  Conversão de espaço de cor — YCbCr é a fórmula ITU-R BT.601 exata (a
//  mesma que todo decodificador de vídeo do mundo usa), conferida numericamente
//  como inversa uma da outra (RGB->YCbCr->RGB recupera o original a 1e-6).
// ===========================================================================
float3 paraEspaco(float3 rgb) {
    if (u.colorspace == 0) return rgb;
    float y  =  0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
    float cb = -0.168736 * rgb.r - 0.331264 * rgb.g + 0.5 * rgb.b + 0.5;
    float cr =  0.5 * rgb.r - 0.418688 * rgb.g - 0.081312 * rgb.b + 0.5;
    return float3(y, cb, cr);
}

float3 deEspaco(float3 v) {
    if (u.colorspace == 0) return v;
    float r = v.x + 1.402 * (v.z - 0.5);
    float g = v.x - 0.344136 * (v.y - 0.5) - 0.714136 * (v.z - 0.5);
    float b = v.x + 1.772 * (v.y - 0.5);
    return float3(r, g, b);
}

// ===========================================================================
//  Os limites de magnitude de cada buffer intermediário — de uma varredura
//  numérica de pior caso, não de um chute. Ver o cabeçalho do arquivo.
// ===========================================================================
const float ESCALA_DIFF   = 1.0;    // a diferença crua cabe exatamente em [-1,1]
const float ESCALA_DCT1   = 6.0;    // 1 passe de DCT direta sobre [-1,1]: pico real 5,657
const float ESCALA_DCT2   = 128.0;  // DCT 2D completa: pico real 32, com folga de ganho até 4×
const float ESCALA_IDCT1  = 24.0;   // simétrico ao ESCALA_DCT1, com a mesma folga de ganho
const float ESCALA_FINAL  = 4.0;    // erro espacial reconstruído: pico real 1,0, com a mesma folga

float3 codificar(float3 real, float escala) {
    return clamp(real / escala, -1.0, 1.0) * 0.5 + 0.5;
}
float3 decodificar(float3 armazenado, float escala) {
    return (armazenado - 0.5) * 2.0 * escala;
}

// ===========================================================================
//  Passe 0 — diferença: quadro atual menos a previsão temporal
// ===========================================================================
float4 passeDiferenca(int2 px) {
    float4 atualBruto = inputImg.read(uint2(px), uint(0));
    float4 h1 = hist1.read(uint2(px), uint(0));
    float4 h2 = hist2.read(uint2(px), uint(0));

    // Sem histórico ainda (textura vazia = alfa zero, ver FrameHistory): usa
    // o próprio quadro atual como previsão, então a diferença nasce zero em
    // vez de o efeito aparecer "corrompido" nos primeiros quadros do clipe.
    float3 p1 = h1.a > 0.001 ? h1.rgb : atualBruto.rgb;
    float3 p2 = h2.a > 0.001 ? h2.rgb : p1;
    float3 previsao = (p1 + p2) * 0.5;

    float3 atual = paraEspaco(atualBruto.rgb);
    float3 prev = paraEspaco(previsao);
    float3 diff = clamp(atual - prev, -1.0, 1.0);

    return float4(codificar(diff, ESCALA_DIFF), atualBruto.a);
}

// ===========================================================================
//  Passe 1 — DCT direta ao longo de X, dentro de blocos de 8 px
// ===========================================================================
float4 passeDctX(int2 px, int2 tam) {
    int baseX = (px.x / 8) * 8;
    int u = px.x - baseX;

    float3 soma = float3(0.0);
    for (int x = 0; x < 8; x++) {
        int2 amostra = int2(min(baseX + x, tam.x - 1), px.y);
        float3 diff = decodificar(diffBuf.read(uint2(amostra), uint(0)).rgb, ESCALA_DIFF);
        soma += baseDct(u, x) * diff;
    }
    soma *= alphaDct(u);

    return float4(codificar(soma, ESCALA_DCT1), 1.0);
}

// ===========================================================================
//  Passe 2 — DCT direta ao longo de Y (fecha a 2D) + processamento do erro
// ===========================================================================
float4 passeDctYEProcessa(int2 px, int2 tam) {
    int baseY = (px.y / 8) * 8;
    int v = px.y - baseY;

    float3 soma = float3(0.0);
    for (int y = 0; y < 8; y++) {
        int2 amostra = int2(px.x, min(baseY + y, tam.y - 1));
        float3 dctx = decodificar(dctXBuf.read(uint2(amostra), uint(0)).rgb, ESCALA_DCT1);
        soma += baseDct(v, y) * dctx;
    }
    float3 coef = soma * alphaDct(v); // o coeficiente 2D real F(u,v)

    // O processamento GUARDA O SINAL — ver a nota do cabeçalho do arquivo
    // sobre por que isto importa pra reconstrução fazer sentido.
    //
    // ATENÇÃO À NORMALIZAÇÃO: `coef` NÃO está em [-1,1] — é o coeficiente 2D
    // real. `pow()` só se comporta como uma curva de gama quando a entrada
    // está em [0,1]; aplicado direto sobre um valor grande, um gama acima de
    // 1 explode e satura o coeficiente inteiro — foi isto que transformava a
    // imagem num borrão de cor sólida em qualquer gama alto, em vez do padrão
    // de blocos do datamosh de verdade. Por isso a magnitude é normalizada
    // ANTES do pow(), e só volta à escala real (com o ganho) depois.
    //
    // O PICO usado aqui NÃO é o pico teórico absoluto (esse é ~32, e seguiu
    // sendo o que ESCALA_DCT2 acima usa para nunca estourar o buffer). É o
    // pico TÍPICO: a diferença entre dois quadros de vídeo de verdade quase
    // nunca chega perto do caso adversário de 32 (isso exigiria um bloco
    // 8×8 alternando preto e branco a cada pixel) — uma diferença de
    // movimento real e perceptível já é um F(0,0) = 32×d bem menor. Testado
    // e relatado: com o pico teórico, Threshold e Gama do PADRÃO (0,03 e
    // 1,0) não deixavam passar quase nada — só em Threshold zerado e Gama
    // bem abaixo de 1 (forçando os valores típicos, pequenos, pra cima) o
    // efeito aparecia. Um F(0,0) de ~6 já corresponde a uma diferença
    // uniforme de bloco de quase 19% (6/32) — movimento real, visível, não
    // sutil — e é isso que passa a valer a magnitude MÁXIMA da faixa.
    const float PICO_COEFICIENTE = 6.0;
    float3 sinal = sign(coef);
    float3 magNormalizada = clamp(abs(coef) / PICO_COEFICIENTE, 0.0, 1.0);
    float3 magnitudeProcessada = pow(magNormalizada, float3(u.errorGamma)) * PICO_COEFICIENTE * u.amplification;

    /*
     * LIMIAR SUAVE, NÃO UM CORTE DURO.
     *
     * Era um corte binário: acima do limiar, o coeficiente passa inteiro;
     * abaixo, vira zero — um interruptor. O grão/ruído que já existe em
     * qualquer vídeo de verdade (compressão, granulação do material de
     * origem) faz um coeficiente oscilar de leve por cima e por baixo do
     * limiar de um quadro pro outro, sem a CENA ter mudado quase nada — e
     * um interruptor binário transforma essa oscilação pequena em um bloco
     * inteiro ligando e desligando de vez, de um quadro para o seguinte.
     * Era exatamente o "aparece do nada" relatado comparando dois quadros
     * consecutivos quase idênticos. `smoothstep` troca o interruptor por
     * uma rampa: perto do limiar, o coeficiente entra e sai aos poucos.
     */
    const float LARGURA_DA_RAMPA = 0.03;
    float3 peso = smoothstep(
        float3(u.errorThreshold - LARGURA_DA_RAMPA),
        float3(u.errorThreshold + LARGURA_DA_RAMPA),
        magNormalizada
    );
    if (u.invertError) peso = float3(1.0) - peso;

    float3 processado = sinal * magnitudeProcessada * peso;

    return float4(codificar(processado, ESCALA_DCT2), 1.0);
}

// ===========================================================================
//  Passe 3 — DCT inversa ao longo de Y (desfaz o SEGUNDO passe direto primeiro
//  — inverter uma transformada separável exige a ordem contrária da direta)
// ===========================================================================
float4 passeIdctY(int2 px, int2 tam) {
    int baseY = (px.y / 8) * 8;
    int y = px.y - baseY; // posição espacial de SAÍDA dentro do bloco, eixo Y

    float3 soma = float3(0.0);
    for (int v = 0; v < 8; v++) {
        int2 amostra = int2(px.x, min(baseY + v, tam.y - 1));
        float3 coef = decodificar(dctBuf.read(uint2(amostra), uint(0)).rgb, ESCALA_DCT2);
        soma += alphaDct(v) * baseDct(v, y) * coef;
    }
    soma *= 0.25; // o fator por passe inverso — conferido numericamente, ver o cabeçalho.

    return float4(codificar(soma, ESCALA_IDCT1), 1.0);
}

// ===========================================================================
//  Passe 4 — DCT inversa ao longo de X (fecha a reconstrução espacial)
// ===========================================================================
float4 passeIdctX(int2 px, int2 tam) {
    int baseX = (px.x / 8) * 8;
    int x = px.x - baseX;

    float3 soma = float3(0.0);
    for (int u = 0; u < 8; u++) {
        int2 amostra = int2(min(baseX + u, tam.x - 1), px.y);
        float3 v1 = decodificar(idctYBuf.read(uint2(amostra), uint(0)).rgb, ESCALA_IDCT1);
        soma += alphaDct(u) * baseDct(u, x) * v1;
    }
    soma *= 0.25;
    // soma é o "erro" espacial real, já processado (ganho/gama/limiar aplicados).

    return float4(codificar(soma, ESCALA_FINAL), 1.0);
}

// ===========================================================================
//  Passe 5 — desenha: desfoque leve do erro + composição sobre o original
// ===========================================================================
float3 erroEm(int2 px, int2 tam) {
    int2 c = clamp(px, int2(0), tam - 1);
    return decodificar(idctBuf.read(uint2(c), uint(0)).rgb, ESCALA_FINAL);
}

fragment float4 fx_datamosh(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant datamoshParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hist1 [[texture(1)]],
    texture2d<float> hist2 [[texture(2)]],
    texture2d<float> diffBuf [[texture(3)]],
    texture2d<float> dctXBuf [[texture(4)]],
    texture2d<float> dctBuf [[texture(5)]],
    texture2d<float> idctYBuf [[texture(6)]],
    texture2d<float> idctBuf [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 t = int2(__nv_fragCoord.xy);
    int2 tam = int2(eng.acResolution);

    if (eng.acPass == 0) { __nv_out = passeDiferenca(t); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = passeDctX(t, tam); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = passeDctYEProcessa(t, tam); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = passeIdctY(t, tam); return __nv_out; }
    if (eng.acPass == 4) { __nv_out = passeIdctX(t, tam); return __nv_out; }

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float3 erro = erroEm(t, tam);
    if (u.errorBlur > 0.02) {
        int raio = int(ceil(u.errorBlur));
        float3 soma = erro;
        float peso = 1.0;
        soma += erroEm(t + int2(raio, 0), tam); peso += 1.0;
        soma += erroEm(t - int2(raio, 0), tam); peso += 1.0;
        soma += erroEm(t + int2(0, raio), tam); peso += 1.0;
        soma += erroEm(t - int2(0, raio), tam); peso += 1.0;
        erro = soma / peso;
    }

    // O erro está no espaço de cor ESCOLHIDO (RGB ou YCbCr) — somar direto
    // com o original em RGB só faz sentido matematicamente quando os dois
    // lados estão no MESMO espaço. Converte, soma, converte de volta.
    float3 baseNoEspaco = paraEspaco(original.rgb);
    float3 resultadoNoEspaco = baseNoEspaco + erro;
    float3 resultadoRgb = clamp(deEspaco(resultadoNoEspaco), 0.0, 1.0);

    __nv_out = float4(resultadoRgb, original.a);
    return __nv_out;
}
