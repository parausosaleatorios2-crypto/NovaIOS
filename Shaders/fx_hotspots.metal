// ---------------------------------------------------------------------------
// Pontos de luz
// origem : assets/effects/hotspots.xml
// id     : nova.effect.hotspots
// passes : 6
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct hotspotsParams {
    int preset;
    int mode;
    float threshold;
    float softness;
    float blur;
    float brightness;
    float saturation;
    float opacity;
    int colorFromBlur;
    float glowAmount;
    float glowRadius;
    int addColorEnabled;
    float4 addColor;
    float addColorAmount;
    float addColorRadius;
    int linearLuma;
    int useMask;
    int invertMask;
};

// --- funcoes auxiliares do efeito
// Rec.709 — os mesmos pesos de `extract.xml` e `luma-key.xml`.
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

// Treze leituras por passe, de -6 a +6. O sigma é de duas leituras, então as
// pontas (±6) caem a três sigmas do centro — o mesmo corte de uma gaussiana de
// verdade. O espaçamento entre leituras é o raio dividido por seis: cresce com
// o desfoque, e por isso o custo por pixel é sempre o mesmo, de raio 1 a 100.
// Espaçamento igual a meio sigma é denso o bastante para não deixar "pente".
const int METADE = 6;

struct Ajustes {
    float limiar;
    float suavidade;
    float borrao;
    float brilho;
    float saturacao;
};

// As predefinições do documento de especificação. Personalizado (0) devolve os
// controles como estão.
Ajustes ajustes() {
    if (u.preset == 1) return Ajustes(0.70, 0.10, 8.0, 1.0, 1.0);   // realces suaves
    if (u.preset == 2) return Ajustes(0.85, 0.05, 3.0, 1.5, 1.1);   // realces fortes
    if (u.preset == 3) return Ajustes(0.65, 0.15, 10.0, 1.2, 1.0);  // fonte de bloom
    if (u.preset == 4) return Ajustes(0.90, 0.03, 2.0, 1.0, 1.0);   // só luz
    return Ajustes(u.threshold, u.softness, u.blur, u.brightness, u.saturation);
}

// Pixels de uma composição de 1080 de lado curto. Ver o cabeçalho.
float escalaDePixel() {
    return min(eng.acResolution.x, eng.acResolution.y) / 1080.0;
}

// Cor pré-multiplicada -> cor reta. Sem a guarda, alfa 0 dividiria por zero e o
// NaN viraria pixel preto ou branco aleatório, conforme o driver.
float3 desmultiplicar(float4 cor) {
    return cor.a > 0.0001 ? cor.rgb / cor.a : float3(0.0);
}

// sRGB -> luz linear, a curva exata (com o trecho reto perto do preto).
float3 paraLinear(float3 cor) {
    float3 baixo = cor / 12.92;
    float3 alto = pow((max(cor, float3(0.0)) + 0.055) / 1.055, float3(2.4));
    return mix(alto, baixo, step(cor, float3(0.04045)));
}

// Uma direção do borrão gaussiano separável. SAI pré-multiplicado: é a única
// forma de o borrão não misturar a cor "escondida" de um pixel transparente com
// a dos vizinhos. `deEntrada` diz que a textura ainda é cor reta (a camada
// original) e precisa ser pré-multiplicada na leitura; os buffers intermediários
// já são.
float4 borrar(sampler2D tex, float2 direcao, float raioPx, bool deEntrada) {
    float2 passoUv = direcao * eng.acTexelSize * (raioPx / float(METADE));
    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int i = -METADE; i <= METADE; i++) {
        float x = float(i);
        float peso = exp(-0.125 * x * x);   // -x²/(2·σ²), com σ = 2
        float4 leitura = tex.sample(__nv_smp, in.acScreenNorm + passoUv * x);
        if (deEntrada) leitura.rgb *= leitura.a;
        soma += leitura * peso;
        pesos += peso;
    }
    return soma / pesos;
}

fragment float4 fx_hotspots(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant hotspotsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hBlur [[texture(1)]],
    texture2d<float> vBlur [[texture(2)]],
    texture2d<float> hot [[texture(3)]],
    texture2d<float> glowH [[texture(4)]],
    texture2d<float> glowV [[texture(5)]],
    texture2d<float> maskImg [[texture(6)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    Ajustes aj = ajustes();
    float escala = escalaDePixel();
    float raioDeEntrada = aj.borrao * escala;
    bool temBorrao = raioDeEntrada >= 0.5;

    // ---------------------------------------------- 0 e 1: borrão da entrada
    if (eng.acPass == 0) {
        if (!temBorrao) { __nv_out = float4(0.0); return __nv_out; }
        __nv_out = borrar(inputImg, float2(1.0, 0.0), raioDeEntrada, true);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        if (!temBorrao) { __nv_out = float4(0.0); return __nv_out; }
        __nv_out = borrar(hBlur, float2(0.0, 1.0), raioDeEntrada, false);
        return __nv_out;
    }

    // ------------------------------------------------ 2: a detecção em si
    if (eng.acPass == 2) {
        float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

        // Sem desfoque a detecção lê a imagem crua: passar pelo buffer
        // pré-multiplicado de 8 bits só perderia precisão nos alfas baixos.
        float3 borrada = original.rgb;
        if (temBorrao) borrada = desmultiplicar(vBlur.sample(__nv_smp, in.acScreenNorm));

        float3 paraMedir = borrada;
        if (u.linearLuma) paraMedir = paraLinear(paraMedir);
        float luz = dot(paraMedir, LUMA);

        // "Limiar por cor": perto da cor escolhida o limiar desce (a cor entra
        // mais fácil) ou sobe (mais difícil), com queda suave — sem a queda a
        // fronteira da cor viraria um contorno duro na máscara.
        float limiar = aj.limiar;
        if (u.addColorEnabled) {
            float distanciaDaCor = distance(borrada, u.addColor.rgb);
            float influencia = 1.0 - smoothstep(0.0, max(u.addColorRadius, 0.01), distanciaDaCor);
            limiar -= u.addColorAmount * influencia;
        }

        // A suavidade nunca é zero: smoothstep com as duas bordas iguais é
        // indefinido, e o degrau resultante é serrilhado na máscara.
        float suave = max(aj.suavidade, 0.004);
        float mascara = smoothstep(limiar - suave, limiar + suave, luz);

        // Máscara externa: a luminância da outra camada, vezes o alfa dela (o
        // mesmo "pré-multiplicar" de `set-matte.xml`, que é o padrão do After
        // Effects). Sem camada escolhida, a textura cai no próprio conteúdo.
        if (u.useMask) {
            float4 externa = maskImg.sample(__nv_smp, in.acScreenNorm);
            float valor = dot(externa.rgb, LUMA) * externa.a;
            mascara *= u.invertMask ? 1.0 - valor : valor;
        }

        // Pixel transparente nunca gera realce (PNG, texto, recorte).
        mascara *= original.a;

        // A cor do realce: a da imagem original (ou a do borrão, se pedido),
        // com a saturação ajustada pela luminância. Nunca negativa — saturação
        // acima de 1 empurra o canal mais fraco para baixo de zero.
        float3 cor = (temBorrao && u.colorFromBlur) ? borrada : original.rgb;
        float cinza = dot(cor, LUMA);
        cor = max(mix(float3(cinza), cor, aj.saturacao), float3(0.0));

        // PRÉ-MULTIPLICADO, de novo: é o formato que o borrão do brilho
        // integrado precisa. O último passe desmultiplica.
        __nv_out = float4(clamp(cor * mascara, 0.0, 1.0), mascara);
        return __nv_out;
    }

    // ------------------------------------------- 3 e 4: brilho integrado
    if (eng.acPass == 3) {
        if (u.glowAmount <= 0.0) { __nv_out = float4(0.0); return __nv_out; }
        __nv_out = borrar(hot, float2(1.0, 0.0), u.glowRadius * escala, false);
        return __nv_out;
    }
    if (eng.acPass == 4) {
        if (u.glowAmount <= 0.0) { __nv_out = float4(0.0); return __nv_out; }
        __nv_out = borrar(glowH, float2(0.0, 1.0), u.glowRadius * escala, false);
        return __nv_out;
    }

    // ------------------------------------------------------- 5: a saída
    float4 nucleo = hot.sample(__nv_smp, in.acScreenNorm);
    float4 halo = (u.glowAmount > 0.0) ? glowV.sample(__nv_smp, in.acScreenNorm) : float4(0.0);

    // Cobertura total: a máscara mais a do brilho. Sem limitar ainda — o
    // Brilho multiplica a energia antes do corte.
    float cobertura = nucleo.a + halo.a * u.glowAmount;

    // ----- Matte (alfa): branco puro, e a máscara vai no alfa. É o que o
    // "Definir matte" lê como Alfa — e como Luminância com "pré-multiplicar"
    // ligado (o padrão), porque branco × alfa é a própria máscara.
    if (u.mode == 1) {
        __nv_out = float4(1.0, 1.0, 1.0, clamp(cobertura, 0.0, 1.0) * u.opacity);
        return __nv_out;
    }

    // ----- Matte (preto e branco): a máscara na cor, opaca onde a camada era.
    // É o que se OLHA, e o que serve de luminância sem pré-multiplicar.
    if (u.mode == 2) {
        float silhueta = inputImg.sample(__nv_smp, in.acScreenNorm).a;
        __nv_out = float4(float3(clamp(cobertura, 0.0, 1.0) * u.opacity), silhueta);
        return __nv_out;
    }

    // ----- Cor. Aqui o Brilho entra. Ele multiplica a ENERGIA — cor vezes
    // cobertura — e a divisão dela por uma cobertura já multiplicada devolve a
    // cor reta: nas bordas (energia baixa) o resultado é alfa maior com a
    // mesma cor; no miolo (alfa já 1) a cor clareia até estourar.
    float alfa = clamp(cobertura * aj.brilho, 0.0, 1.0);
    float3 energia = (nucleo.rgb + halo.rgb * u.glowAmount) * aj.brilho;
    float3 rgb = alfa > 0.0001 ? clamp(energia / alfa, 0.0, 1.0) : float3(0.0);

    __nv_out = float4(rgb, alfa * u.opacity);
    return __nv_out;
}
