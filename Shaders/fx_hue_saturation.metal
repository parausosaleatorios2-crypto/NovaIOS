// ---------------------------------------------------------------------------
// Matiz e saturação
// origem : assets/effects/hue-saturation.xml
// id     : nova.effect.huesat
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct hue_saturationParams {
    float hue;
    float saturation;
    float vibrance;
    float lightness;
};

// --- funcoes auxiliares do efeito
static float3 rgb2hsv(float3 c) {
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    // O epsilon evita divisão por zero em cinza puro, onde d = 0.
    const float EPS = 1.0e-10;
    return float3(
        abs(q.z + (q.w - q.y) / (6.0 * d + EPS)),
        d / (q.x + EPS),
        q.x
    );
}

static float3 hsv2rgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

fragment float4 fx_hue_saturation(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant hue_saturationParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);
    float3 hsv = rgb2hsv(color.rgb);

    // fract() faz o matiz dar a volta: 350° + 30° = 20°, e não 380°.
    hsv.x = fract(hsv.x + u.hue / 360.0);

    // Vibração é saturação seletiva: mexe pouco no que já está saturado e muito
    // no que está sem graça. É o motivo de fotógrafo preferir vibração a
    // saturação — ela não estoura tom de pele.
    float boost = u.vibrance * (1.0 - hsv.y);
    hsv.y = clamp(hsv.y * (1.0 + u.saturation) + boost, 0.0, 1.0);

    hsv.z = clamp(hsv.z + u.lightness, 0.0, 1.0);

    __nv_out = float4(hsv2rgb(hsv), color.a);
    return __nv_out;
}
