// ---------------------------------------------------------------------------
// Sabre (Ultra)
// origem : assets/effects/nv-um-saber.xml
// id     : nova.effect.um-saber
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_um_saberParams {
    float4 color;
    float threshold;
    float width;
    float intensity;
    float softness;
};

// --- funcoes auxiliares do efeito
static float luma(float3 c) { return dot(c, float3(0.2126, 0.7152, 0.0722)); }

fragment float4 fx_nv_um_saber(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_um_saberParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float4 base = inputImg.sample(__nv_smp, uv);
    float cx = 1.0 / eng.acResolution.x;
    float cy = 1.0 / eng.acResolution.y;
    float L0 = luma(base.rgb) * base.a;

    float glow = 0.0;
    float r = u.width;
    for (int i = -3; i <= 3; i++) {
        for (int j = -3; j <= 3; j++) {
            if (i == 0 && j == 0) continue;
            float2 o = float2(float(i), float(j)) * r / 3.0;
            float4 s = inputImg.sample(__nv_smp, uv + float2(o.x * cx, o.y * cy));
            float ls = luma(s.rgb) * s.a;
            float edge = max(0.0, ls - u.threshold);
            float dist = length(o);
            float w = exp(-dist * dist / (r * r * (0.2 + u.softness)));
            glow += edge * w;
        }
    }
    glow = clamp(glow * u.intensity / 24.0, 0.0, 4.0);

    float3 outRgb = base.rgb + u.color.rgb * glow;
    __nv_out = float4(outRgb, max(base.a, min(1.0, glow)));
    return __nv_out;
}
