// ---------------------------------------------------------------------------
// Meio-tom
// origem : assets/effects/halftone.xml
// id     : nova.effect.halftone
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct halftoneParams {
    int shape;
    int colorMode;
    float dotSize;
    float gridAngle;
    float phase;
    float softness;
    float4 inkColor;
    float4 paperColor;
    int transparentPaper;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

float luminancia(float3 c) {
    return dot(c, float3(0.299, 0.587, 0.114));
}

/*
 * Onde este pixel está na retícula.
 *
 * `local` é a posição dentro da célula, de -0.5 a 0.5. `uvDoCentro` é onde a
 * imagem é lida para decidir o tamanho do ponto — o centro da célula, levado
 * de volta pelo giro da grade.
 *
 * Nas LINHAS não há célula no comprimento: a linha é contínua. Ela é lida no
 * centro só na espessura, e ao longo dela no próprio pixel — é o que faz a
 * linha engrossar e afinar suavemente acompanhando a imagem.
 */
struct Celula {
    float2 local;
    float2 uvDoCentro;
};

Celula celulaEm(float2 uv, float anguloGraus, bool continuaNoComprimento) {
    // Células quadradas em qualquer proporção de composição: sem o eng.acAspect,
    // um projeto 9:16 teria pontos ovais.
    float porAltura = eng.acResolution.y / (max(u.dotSize, 1.0) * eng.acEscalaDePixel);
    float2 p = float2(uv.x * eng.acAspect, uv.y) * porAltura;

    float ang = radians(anguloGraus);
    float c = cos(ang);
    float s = sin(ang);
    float2 r = float2(p.x * c - p.y * s, p.x * s + p.y * c) + float2(u.phase, 0.0);

    float2 centro = floor(r) + 0.5;
    if (continuaNoComprimento) centro.x = r.x;

    float2 rc = centro - float2(u.phase, 0.0);
    // O giro inverso é a transposta: a matriz de rotação é ortogonal.
    float2 pc = float2(rc.x * c + rc.y * s, -rc.x * s + rc.y * c);

    Celula cel;
    cel.local = r - centro;
    cel.uvDoCentro = float2(pc.x / porAltura / max(eng.acAspect, 1e-4), pc.y / porAltura);
    return cel;
}

/*
 * Quanto da célula a forma cobre neste pixel, para uma quantidade de tinta.
 *
 * O limite de cada forma sai da ÁREA: `tinta` é a fração da célula que deve
 * ficar coberta. Um quadrado de lado 2L cobre 4L², então L = √tinta / 2. O
 * círculo cobre πr² até encostar nas bordas (78% da célula) e daí cresce até
 * fechar os cantos. O losango cobre 2L² até encostar, e depois perde só os
 * quatro triângulos dos cantos.
 */
float cobertura(float2 local, float tinta, int forma, float borda) {
    float t = clamp(tinta, 0.0, 1.0);
    float metrica;
    float limite;

    if (forma == 1) {
        metrica = abs(local.y);
        limite = t * 0.5;
    } else if (forma == 2) {
        metrica = max(abs(local.x), abs(local.y));
        limite = sqrt(t) * 0.5;
    } else if (forma == 3) {
        metrica = abs(local.x) + abs(local.y);
        limite = t <= 0.5 ? sqrt(t * 0.5) : 1.0 - sqrt((1.0 - t) * 0.5);
    } else {
        metrica = length(local);
        float encosta = PI * 0.25;
        limite = t <= encosta
            ? sqrt(t / PI)
            : mix(0.5, 0.7072, (t - encosta) / (1.0 - encosta));
    }

    if (t <= 0.0) return 0.0;
    return 1.0 - smoothstep(limite - borda, limite + borda, metrica);
}

float4 paraCmyk(float3 cor) {
    float k = 1.0 - max(max(cor.r, cor.g), cor.b);
    float resto = max(1.0 - k, 1e-4);
    return float4(
        (1.0 - cor.r - k) / resto,
        (1.0 - cor.g - k) / resto,
        (1.0 - cor.b - k) / resto,
        k
    );
}

fragment float4 fx_halftone(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant halftoneParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    bool linhas = u.shape == 1;

    // Um pixel, medido em células: a borda antisserrilhada tem essa largura.
    // A borda macia soma por cima, até meia célula.
    float borda = 0.75 / (max(u.dotSize, 1.0) * eng.acEscalaDePixel) + u.softness * 0.5;

    float3 sobrePapel;   // o resultado impresso no papel escolhido
    float3 soTinta;      // a cor da tinta sozinha, para o papel transparente
    float quantaTinta; // quanto do pixel tem tinta, de 0 a 1

    if (u.colorMode == 2) {
        float base = u.gridAngle - 45.0;
        Celula cC = celulaEm(in.acScreenNorm, base + 15.0, linhas);
        Celula cM = celulaEm(in.acScreenNorm, base + 75.0, linhas);
        Celula cY = celulaEm(in.acScreenNorm, base + 0.0, linhas);
        Celula cK = celulaEm(in.acScreenNorm, base + 45.0, linhas);

        float4 aC = inputImg.sample(__nv_smp, cC.uvDoCentro);
        float4 aM = inputImg.sample(__nv_smp, cM.uvDoCentro);
        float4 aY = inputImg.sample(__nv_smp, cY.uvDoCentro);
        float4 aK = inputImg.sample(__nv_smp, cK.uvDoCentro);

        // Fora da camada não há tinta: o transparente guarda preto, e sem o
        // alfa aqui ele viraria retícula preta em volta do recorte.
        float covC = cobertura(cC.local, paraCmyk(aC.rgb).x * aC.a, u.shape, borda);
        float covM = cobertura(cM.local, paraCmyk(aM.rgb).y * aM.a, u.shape, borda);
        float covY = cobertura(cY.local, paraCmyk(aY.rgb).z * aY.a, u.shape, borda);
        float covK = cobertura(cK.local, paraCmyk(aK.rgb).w * aK.a, u.shape, borda);

        // Tinta sobre tinta MULTIPLICA: o ciano tira o vermelho da luz, o
        // magenta tira o verde, e onde os dois caem juntos sobra azul.
        float3 filtro = mix(float3(1.0), float3(0.0, 1.0, 1.0), covC)
                    * mix(float3(1.0), float3(1.0, 0.0, 1.0), covM)
                    * mix(float3(1.0), float3(1.0, 1.0, 0.0), covY)
                    * mix(float3(1.0), float3(0.0), covK);

        sobrePapel = u.paperColor.rgb * filtro;
        quantaTinta = 1.0 - (1.0 - covC) * (1.0 - covM) * (1.0 - covY) * (1.0 - covK);
        // A cor que, pousada com esse alfa sobre branco, dá o mesmo filtro.
        soTinta = quantaTinta > 0.0
            ? (filtro - (1.0 - quantaTinta)) / quantaTinta
            : float3(0.0);
    } else {
        Celula cel = celulaEm(in.acScreenNorm, u.gridAngle, linhas);
        float4 lida = inputImg.sample(__nv_smp, cel.uvDoCentro);

        float lumaPapel = luminancia(u.paperColor.rgb);
        float3 corDaTinta = u.colorMode == 1 ? lida.rgb : u.inkColor.rgb;
        // Nas cores da imagem a tinta é "o contrário do papel": o ponto cresce
        // no escuro sobre papel claro, e no claro sobre papel escuro.
        float lumaTinta = u.colorMode == 1
            ? (lumaPapel > 0.5 ? 0.0 : 1.0)
            : luminancia(u.inkColor.rgb);

        float faixa = lumaTinta - lumaPapel;
        float tinta = abs(faixa) < 0.02
            ? 1.0 - luminancia(lida.rgb)
            : (luminancia(lida.rgb) - lumaPapel) / faixa;

        quantaTinta = cobertura(cel.local, tinta * lida.a, u.shape, borda);
        sobrePapel = mix(u.paperColor.rgb, corDaTinta, quantaTinta);
        soTinta = corDaTinta;
    }

    float4 impresso = u.transparentPaper
        ? float4(clamp(soTinta, 0.0, 1.0), quantaTinta * original.a)
        : float4(sobrePapel, original.a);

    __nv_out = impresso;
    return __nv_out;
}
