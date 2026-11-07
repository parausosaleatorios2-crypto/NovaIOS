// ---------------------------------------------------------------------------
// Hue/Saturation (AE)
// origem : assets/effects/ae-hue-saturation.xml
// id     : nova.effect.aehuesat
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_hue_saturationParams {
    float masterHue;
    float masterSaturation;
    float masterLightness;
    int colorize;
    float colorizeHue;
    float colorizeSaturation;
    float colorizeLightness;
    float redsHue;
    float redsSaturation;
    float redsLightness;
    float redsRange0;
    float redsRange1;
    float redsRange2;
    float redsRange3;
    float yellowsHue;
    float yellowsSaturation;
    float yellowsLightness;
    float yellowsRange0;
    float yellowsRange1;
    float yellowsRange2;
    float yellowsRange3;
    float greensHue;
    float greensSaturation;
    float greensLightness;
    float greensRange0;
    float greensRange1;
    float greensRange2;
    float greensRange3;
    float cyansHue;
    float cyansSaturation;
    float cyansLightness;
    float cyansRange0;
    float cyansRange1;
    float cyansRange2;
    float cyansRange3;
    float bluesHue;
    float bluesSaturation;
    float bluesLightness;
    float bluesRange0;
    float bluesRange1;
    float bluesRange2;
    float bluesRange3;
    float magentasHue;
    float magentasSaturation;
    float magentasLightness;
    float magentasRange0;
    float magentasRange1;
    float magentasRange2;
    float magentasRange3;
};

// --- funcoes auxiliares do efeito
// ---- o fator da saturação para cada valor inteiro de −100 a 100, em 1/256 (medido; tools/huesat/benchmark/tabela.py) ----
const float FATOR[201] = float[201](0.0, 3.0, 6.0, 8.0, 11.0, 13.0, 16.0, 18.0, 21.0, 24.0, 26.0, 29.0, 31.0, 34.0, 36.0, 39.0, 41.0, 44.0, 47.0, 49.0, 52.0, 54.0, 57.0, 59.0, 62.0, 64.0, 67.0, 70.0, 72.0, 75.0, 77.0, 80.0, 82.0, 85.0, 88.0, 90.0, 93.0, 95.0, 98.0, 100.0, 103.0, 105.0, 108.0, 111.0, 113.0, 116.0, 118.0, 121.0, 123.0, 126.0, 128.0, 131.0, 134.0, 136.0, 139.0, 141.0, 144.0, 146.0, 149.0, 152.0, 154.0, 157.0, 159.0, 162.0, 164.0, 167.0, 169.0, 172.0, 175.0, 177.0, 180.0, 182.0, 185.0, 187.0, 190.0, 192.0, 195.0, 198.0, 200.0, 203.0, 205.0, 208.0, 210.0, 213.0, 216.0, 218.0, 221.0, 223.0, 226.0, 228.0, 231.0, 233.0, 236.0, 239.0, 241.0, 244.0, 246.0, 249.0, 251.0, 254.0, 256.0, 258.0, 261.0, 263.0, 266.0, 268.0, 272.0, 274.0, 277.0, 280.0, 283.0, 286.0, 290.0, 294.0, 296.0, 300.0, 303.0, 307.0, 310.0, 315.0, 318.0, 323.0, 326.0, 331.0, 334.0, 340.0, 345.0, 349.0, 354.0, 358.0, 364.0, 368.0, 375.0, 379.0, 386.0, 390.0, 398.0, 402.0, 410.0, 418.0, 423.0, 432.0, 438.0, 447.0, 453.0, 462.0, 469.0, 480.0, 487.0, 498.0, 510.0, 518.0, 530.0, 539.0, 553.0, 562.0, 577.0, 588.0, 604.0, 615.0, 633.0, 646.0, 666.0, 687.0, 701.0, 725.0, 741.0, 768.0, 786.0, 816.0, 836.0, 870.0, 894.0, 932.0, 960.0, 1004.0, 1052.0, 1088.0, 1145.0, 1186.0, 1255.0, 1305.0, 1388.0, 1450.0, 1554.0, 1632.0, 1764.0, 1865.0, 2040.0, 2251.0, 2417.0, 2720.0, 2967.0, 3435.0, 3840.0, 4662.0, 5440.0, 7253.0, 9325.0, 16320.0, 65280.0);

float fator(float v) {
    float x = clamp(v + 100.0, 0.0, 200.0);
    int i = min(int(floor(x)), 199);
    return mix(FATOR[i], FATOR[i + 1], x - float(i)) / 256.0;
}

/** RGB -> (matiz em voltas, saturação, luminosidade), HSL. */
float3 paraHsl(float3 c) {
    float mx = max(c.r, max(c.g, c.b)), mn = min(c.r, min(c.g, c.b)), d = mx - mn;
    float l = 0.5 * (mx + mn);
    if (d <= 0.0) return float3(0.0, 0.0, l);
    float s = d / (l <= 0.5 ? max(mx + mn, 1e-9) : max(2.0 - mx - mn, 1e-9));
    float h = mx == c.r ? __nv_mod((c.g - c.b) / d, 6.0) : (mx == c.g ? (c.b - c.r) / d + 2.0 : (c.r - c.g) / d + 4.0);
    return float3(h / 6.0, s, l);
}

float canalDoHsl(float p, float q, float t) {
    t = fract(t);
    if (t < 1.0 / 6.0) return p + (q - p) * 6.0 * t;
    if (t < 0.5) return q;
    if (t < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
    return p;
}

float3 deHsl(float3 hsl) {
    float q = hsl.z <= 0.5 ? hsl.z * (1.0 + hsl.y) : hsl.z + hsl.y - hsl.z * hsl.y;
    float p = 2.0 * hsl.z - q;
    return float3(canalDoHsl(p, q, hsl.x + 1.0 / 3.0), canalDoHsl(p, q, hsl.x), canalDoHsl(p, q, hsl.x - 1.0 / 3.0));
}

/** Lightness (medido): para cima mistura com branco; para baixo, com preto. `v` em −1..1. */
float3 clarear(float3 c, float v) {
    return v >= 0.0 ? c + (1.0 - c) * v : c * (1.0 + v);
}

/** Um ponto da faixa em graus de verdade: no matiz inteiro de lá (1536 por volta) ele cai em round(g · 1540 / 360). */
float ponto(float g) {
    return floor(g * 1540.0 / 360.0 + 0.5) * 360.0 / 1536.0;
}

/** O peso da faixa (início da rampa, início do miolo, fim do miolo, fim da rampa) no matiz `hg`, em graus. */
float peso(float hg, float4 faixa) {
    float a = ponto(faixa.x);
    float x = __nv_mod(hg - a, 360.0);
    float b = __nv_mod(ponto(faixa.y) - a, 360.0), c = __nv_mod(ponto(faixa.z) - a, 360.0), d = __nv_mod(ponto(faixa.w) - a, 360.0);
    if (x >= d) return 0.0;
    if (x < b) return clamp(x / max(b, 1e-6), 0.0, 1.0);
    if (x > c) return clamp((d - x) / max(d - c, 1e-6), 0.0, 1.0);
    return 1.0;
}

/** Soma o ajuste de uma cor: (matiz em voltas, luminosidade em −1..1, saturação em fator − 1). */
void somar(float hg, float4 faixa, float3 hsl, inout float3 soma) {
    if (hsl == float3(0.0)) return;
    float w = peso(hg, faixa);
    soma += w * float3(hsl.x / 360.0, hsl.z / 100.0, fator(hsl.y) - 1.0);
}

fragment float4 fx_ae_hue_saturation(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_hue_saturationParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 cor = inputImg.sample(__nv_smp, in.acScreenNorm);
    float3 c = cor.rgb;
    if (u.colorize) {
        float l = paraHsl(clarear(c, u.colorizeLightness / 100.0)).z;
        __nv_out = float4(deHsl(float3(u.colorizeHue / 360.0, clamp(u.colorizeSaturation / 100.0, 0.0, 1.0), l)), cor.a);
        return __nv_out;
    }
    // as seis cores, antes do master: pesam pela faixa do matiz do pixel de entrada (cinza não entra)
    float3 hsl0 = paraHsl(c);
    if (hsl0.y > 0.0) {
        float hg = hsl0.x * 360.0;
        float3 soma = float3(0.0);
        somar(hg, float4(u.redsRange0, u.redsRange1, u.redsRange2, u.redsRange3), float3(u.redsHue, u.redsSaturation, u.redsLightness), soma);
        somar(hg, float4(u.yellowsRange0, u.yellowsRange1, u.yellowsRange2, u.yellowsRange3), float3(u.yellowsHue, u.yellowsSaturation, u.yellowsLightness), soma);
        somar(hg, float4(u.greensRange0, u.greensRange1, u.greensRange2, u.greensRange3), float3(u.greensHue, u.greensSaturation, u.greensLightness), soma);
        somar(hg, float4(u.cyansRange0, u.cyansRange1, u.cyansRange2, u.cyansRange3), float3(u.cyansHue, u.cyansSaturation, u.cyansLightness), soma);
        somar(hg, float4(u.bluesRange0, u.bluesRange1, u.bluesRange2, u.bluesRange3), float3(u.bluesHue, u.bluesSaturation, u.bluesLightness), soma);
        somar(hg, float4(u.magentasRange0, u.magentasRange1, u.magentasRange2, u.magentasRange3), float3(u.magentasHue, u.magentasSaturation, u.magentasLightness), soma);
        if (soma != float3(0.0)) {
            float mx = max(c.r, max(c.g, c.b)), mn = min(c.r, min(c.g, c.b));
            // luminosidade por cor: até o maior canal (para cima) ou até o menor (para baixo)
            c = soma.y >= 0.0 ? c + (mx - c) * soma.y : c - (c - mn) * (-soma.y);
            float3 h = paraHsl(c);
            c = deHsl(float3(h.x + soma.x, clamp(h.y * max(1.0 + soma.z, 0.0), 0.0, 1.0), h.z));
        }
    }
    float3 h = paraHsl(clarear(c, u.masterLightness / 100.0));
    __nv_out = float4(clamp(deHsl(float3(h.x + u.masterHue / 360.0, clamp(h.y * fator(u.masterSaturation), 0.0, 1.0), h.z)), 0.0, 1.0), cor.a);
    return __nv_out;
}
