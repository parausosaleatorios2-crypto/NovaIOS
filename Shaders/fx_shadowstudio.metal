// ---------------------------------------------------------------------------
// Shadow Studio
// origem : assets/effects/shadowstudio.xml
// id     : nova.effect.shadowstudio
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct shadowstudioParams {
    int lightType;
    float lightDirection;
    float2 lightOrigin;
    float lightSoftness;
    float lightRadius;
    float shadowLength;
    int innerShadow;
    int inverseShadow;
    float opacityStart;
    float opacityEnd;
    float easeOpacity;
    float4 color;
    float alphaThreshold;
    float sourceOpacity;
    float shadowOpacity;
};

// --- funcoes auxiliares do efeito
// Medidos no plugin (tools/shadowstudio/benchmark):
const int DIRECOES = 48;      // o máximo de direções da luz (o tamanho dela) que entram na média

float2 tamanho() { return float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))); }

/** 1 dentro da forma (o alfa passa do Alpha Threshold); com Inner Shadow, quem faz sombra é o lado de FORA. */
float forma(float2 px) {
    float2 R = tamanho();
    float a = (px.x < 0.0 || px.y < 0.0 || px.x > R.x || px.y > R.y) ? 0.0 : inputImg.sample(__nv_smp, px / R).a;
    float dentro = step(u.alphaThreshold, a);
    return u.innerShadow ? 1.0 - dentro : dentro;
}

/**
 * Os mapas de blocos (passes 0 e 1): "neste bloco há forma?" (R) e "há lado de fora?" (G). É o que
 * deixa o raio andar de 24 em 24 px numa sombra de milhares de px sem pular um detalhe fino: só onde o
 * bloco acusa alguma coisa ele desce para o mapa de 8 px, e daí para a imagem.
 */
float4 blocos(float2 uv, bool daImagem) {
    float2 R = tamanho();
    float temForma = 0.0, temFora = 0.0;
    if (daImagem) {
        float2 pe = R / eng.acResolution;                       // o bloco, em px da imagem
        for (int j = 0; j < 8; j++) for (int i = 0; i < 8; i++) {
            float2 px = uv * R + ((float2(float(i), float(j)) + 0.5) / 8.0 - 0.5) * pe;
            float a = (px.x < 0.0 || px.y < 0.0 || px.x > R.x || px.y > R.y) ? 0.0 : inputImg.sample(__nv_smp, px / R).a;
            float d = step(u.alphaThreshold, a);
            temForma = max(temForma, d); temFora = max(temFora, 1.0 - d);
        }
    } else {
        float2 pe = 1.0 / eng.acResolution;                     // o bloco, em UV
        for (int j = 0; j < 6; j++) for (int i = 0; i < 6; i++) {
            float4 m = medio.sample(__nv_smp, uv + ((float2(float(i), float(j)) + 0.5) / 6.0 - 0.5) * pe * 1.2);
            temForma = max(temForma, m.r); temFora = max(temFora, m.g);
        }
    }
    return float4(temForma, temFora, 0.0, 1.0);
}

/** O bloco em volta de `px` pode ter o que faz sombra? (filtro linear: acusa também os blocos vizinhos) */
bool podeTer(sampler2D mapa, float2 px) {
    float2 R = tamanho();
    if (px.x < 0.0 || px.y < 0.0 || px.x > R.x || px.y > R.y) return u.innerShadow;
    float4 m = mapa.sample(__nv_smp, px / R);
    return (u.innerShadow ? m.g : m.r) > 0.002;
}

/**
 * A opacidade ao longo da sombra, x = 0 (encostada) a 1 (a ponta). Medido: vai de Opacity Start a
 * Opacity End por x elevado a (100 − Ease Opacity) / Ease Opacity — com 0 não cai nunca, com 100 já
 * começa no fim, com 60 (padrão) cai depressa no começo.
 */
float opacidade(float x) {
    float e = clamp(u.easeOpacity, 0.0, 100.0);
    float f = e < 0.01 ? 0.0 : e > 99.99 ? 1.0 : pow(x, (100.0 - e) / e);
    return mix(u.opacityStart, u.opacityEnd, f) / 100.0;
}

/**
 * A distância (px) do ponto até a forma andando contra a luz (`contra` unitário), até `L`; −1 = não achou.
 * Três andares: o mapa de 32 px (passo de 24 px ou mais), o de 8 px e a imagem.
 */
float ateAForma(float2 p, float2 contra, float L) {
    if (forma(p) > 0.5) return 0.0;
    float pa = max(24.0, L / 128.0);
    for (int i = 0; i < 128; i++) {
        float ta = pa * (float(i) + 0.5);
        if (ta - 0.5 * pa > L) break;
        if (!podeTer(grosso, p + contra * ta)) continue;
        float b0 = max(ta - 0.5 * pa - 4.0, 0.0), b1 = min(ta + 0.5 * pa + 4.0, L);
        float pb = max(6.0, (b1 - b0) / 24.0);
        for (int j = 0; j < 24; j++) {
            float tb = b0 + pb * (float(j) + 0.5);
            if (tb - 0.5 * pb > b1) break;
            if (!podeTer(medio, p + contra * tb)) continue;
            float f0 = max(tb - 0.5 * pb - 2.0, 0.0), f1 = min(tb + 0.5 * pb + 2.0, L);
            float pf = max(1.5, (f1 - f0) / 10.0);
            float antes = f0;
            for (int m = 0; m < 10; m++) {
                float tf = f0 + pf * (float(m) + 0.5);
                if (tf - 0.5 * pf > f1) break;
                if (forma(p + contra * tf) > 0.5) {
                    // achou: afina entre o último ponto de fora e este
                    float a = antes, b = tf;
                    for (int k = 0; k < 4; k++) {
                        float meio = 0.5 * (a + b);
                        if (forma(p + contra * meio) > 0.5) b = meio; else a = meio;
                    }
                    return 0.5 * (a + b);
                }
                antes = tf;
            }
        }
    }
    return -1.0;
}

/**
 * O peso de uma direção: a corda do disco da luz (raio `rho`, visto de uma distância 1) nessa direção.
 * De fora do disco só as direções que o cortam contam; de dentro, todas.
 */
float corda(float rho, float ang, bool dentroDoDisco) {
    float s = sin(ang), c = cos(ang);
    float raiz = sqrt(max(rho * rho - s * s, 0.0));
    if (dentroDoDisco) return max(c + raiz, 0.0);
    return c > 0.0 ? 2.0 * raiz : 0.0;
}

fragment float4 fx_shadowstudio(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant shadowstudioParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> medio [[texture(1)]],
    texture2d<float> grosso [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float2 R = tamanho();
    float2 p = uv * R;
    if (eng.acPass == 0) { __nv_out = blocos(uv, true); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = blocos(uv, false); return __nv_out; }
    float4 orig = inputImg.sample(__nv_smp, uv);
    float esc = eng.acEscalaDePixel;

    // PARA ONDE A SOMBRA VAI. Direcional: 135° = para baixo e para a direita. Pontual: para longe da origem.
    float2 vai; float L = abs(u.shadowLength) * esc;
    float2 origem = u.lightOrigin * R;
    if (u.lightType == 0) {
        float a = radians(u.lightDirection);
        vai = float2(sin(a), -cos(a));
    } else {
        float2 d = p - origem;
        vai = length(d) > 1e-3 ? normalize(d) : float2(0.0, 1.0);
    }
    float sinal = (u.shadowLength < 0.0 ? -1.0 : 1.0) * (u.inverseShadow ? -1.0 : 1.0);

    // A LUZ TEM TAMANHO (medido): a sombra é a MÉDIA de sombras duras para um leque de direções.
    // Direcional: o leque abre Light Softness × Light Radius / 7200.0 radianos para cada lado e não
    // depende do comprimento. Pontual: a luz é um disco em volta da origem — perto dela o leque abre
    // muito, longe quase nada.
    float tamanho = u.lightSoftness * u.lightRadius;
    float semente = fract(52.9829189 * fract(dot(floor(p), float2(0.06711056, 0.00583715))));
    float soma = 0.0, pesos = 0.0;
    // quanto mais aberto o leque, mais direções (senão a sombra larga sai raiada)
    float razao = tamanho * 0.07 * esc / max(length(p - origem), 1.0);
    float abertura = u.lightType == 0 ? (tamanho / 7200.0 < 0.927 ? tamanho / 7200.0 : 3.1416) : (razao < 0.8 ? asin(razao) : 3.1416);
    int n = tamanho > 1e-3 ? int(clamp(10.0 + abertura * 24.0, 10.0, float(DIRECOES))) : 1;
    for (int k = 0; k < DIRECOES; k++) {
        if (k >= n) break;
        float u = n == 1 ? 0.0 : (float(k) + semente) / float(n) * 2.0 - 1.0;
        float2 dir;
        float peso = 1.0;
        if (u.lightType == 0) {
            // A luz é um DISCO visto de uma distância 1, e cada direção pesa pela corda do disco nela.
            // Medido: o disco aparece sob um meio-ângulo de Softness × Radius / 7200.0 radianos. Até
            // 90° o leque fecha nesse ângulo; passando disso o ponto fica DENTRO do disco e há luz de
            // todos os lados (mais do lado de onde ela vem), até o teto de 1.6.
            float teta = min(tamanho / 7200.0, 3.1416);
            float rho = teta < 1.5708 ? sin(teta) : min(1.0 / max(sin(teta), 1e-3), 1.6);
            float ang = (rho < 0.8 && teta < 1.5708 ? teta : 3.1416) * u;
            peso = corda(rho, ang, teta >= 1.5708);
            dir = float2(vai.x * cos(ang) - vai.y * sin(ang), vai.x * sin(ang) + vai.y * cos(ang));
        } else {
            // a luz pontual é o mesmo disco, de raio Softness × Radius × 0.07 px em volta da origem:
            // longe dela o leque é fino, perto abre, e DENTRO do disco a sombra sai para todos os lados
            float rho = min(tamanho * 0.07 * esc / max(length(p - origem), 1.0), 3.0);
            float ang = (rho < 0.8 ? asin(rho) : 3.1416) * u;
            peso = corda(rho, ang, rho >= 1.0);
            dir = float2(vai.x * cos(ang) - vai.y * sin(ang), vai.x * sin(ang) + vai.y * cos(ang));
        }
        if (n == 1) peso = 1.0;                  // luz sem tamanho: uma direção só
        dir *= sinal;
        float tau = ateAForma(p, -dir, L);
        pesos += peso;
        if (tau >= 0.0) soma += peso * opacidade(clamp(tau / max(L, 1e-3), 0.0, 1.0));
    }
    // (medido: Shadow Opacity entra ao quadrado — 50 dá um quarto)
    float sombra = soma / max(pesos, 1e-4) * (u.shadowOpacity / 100.0) * (u.shadowOpacity / 100.0);

    // A COMPOSIÇÃO: a camada por cima da sombra (com Inner Shadow, a sombra por cima e só dentro da camada).
    float4 fonte = float4(orig.rgb, orig.a * u.sourceOpacity / 100.0);
    float4 saida;
    if (u.innerShadow) {
        float s = sombra * u.color.a;
        saida = float4(mix(fonte.rgb, u.color.rgb, s), fonte.a);
    } else {
        float s = sombra * u.color.a;
        float a = fonte.a + s * (1.0 - fonte.a);
        saida = float4(a > 0.0 ? (fonte.rgb * fonte.a + u.color.rgb * s * (1.0 - fonte.a)) / a : float3(0.0), a);
    }
    __nv_out = saida;
    return __nv_out;
}
