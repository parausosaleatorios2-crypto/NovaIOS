// ---------------------------------------------------------------------------
// Seleção por faixa HSL
// origem : assets/effects/hsl-range-selection.xml
// id     : nova.effect.hslrange
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct hsl_range_selectionParams {
    float hue;
    float hueRange;
    float satMin;
    float satMax;
    float lightMin;
    float lightMax;
    float softness;
    int invert;
    int showMask;
};

// --- funcoes auxiliares do efeito
// A mesma conversão RGB↔HSV de `replace-color.xml` — provada ali, repetida
// aqui porque cada efeito deste catálogo é autocontido (sem import entre
// arquivos de shader).
float3 paraHsv(float3 c) {
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

/** Uma faixa [min,max] com rampa suave nos dois lados, largura `soft`. */
float faixaSuave(float valor, float minimo, float maximo, float suave) {
    float rampa = max(suave, 0.001);
    float subindo = smoothstep(minimo - rampa, minimo + rampa, valor);
    float descendo = 1.0 - smoothstep(maximo - rampa, maximo + rampa, valor);
    return clamp(subindo, 0.0, 1.0) * clamp(descendo, 0.0, 1.0);
}

fragment float4 fx_hsl_range_selection(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant hsl_range_selectionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 cor = inputImg.sample(__nv_smp, in.acScreenNorm);
    float3 hsv = paraHsv(clamp(cor.rgb, 0.0, 1.0));

    // Matiz: distância circular até o centro escolhido, em voltas (0..1).
    float alvoHue = u.hue / 360.0;
    float dh = abs(hsv.x - alvoHue);
    dh = min(dh, 1.0 - dh);
    float faixaHueNorm = clamp(u.hueRange, 0.0, 180.0) / 360.0;
    float suaveHue = max(u.softness, 0.001) * 0.5;
    float mHue = 1.0 - smoothstep(faixaHueNorm - suaveHue, faixaHueNorm + suaveHue, dh);

    // Pixel pouco saturado: o matiz é ruído, então a faixa de matiz para de
    // opinar e a seleção passa a depender só de saturação/luminosidade.
    mHue = mix(1.0, mHue, smoothstep(0.0, 0.15, hsv.y));

    float mSat = faixaSuave(hsv.y, u.satMin, u.satMax, u.softness);
    float mLight = faixaSuave(hsv.z, u.lightMin, u.lightMax, u.softness);

    float selecao = clamp(mHue * mSat * mLight, 0.0, 1.0);
    if (u.invert) selecao = 1.0 - selecao;

    if (u.showMask) {
        __nv_out = float4(float3(selecao), 1.0);
        return __nv_out;
    }

    __nv_out = float4(cor.rgb, cor.a * selecao);
    return __nv_out;
}
