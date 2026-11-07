// ---------------------------------------------------------------------------
// Brilho Profundo
// origem : assets/effects/nv-um-deep-bloom.xml
// id     : nova.effect.um-deep-bloom
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_um_deep_bloomParams {
    float threshold;
    float radius;
    float intensity;
    float mistura;
};

// --- funcoes auxiliares do efeito
static float3 bright(float3 c) {
    float L = dot(c, float3(0.2126, 0.7152, 0.0722));
    return c * max(0.0, L - u.threshold);
}

fragment float4 fx_nv_um_deep_bloom(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_um_deep_bloomParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float4 base = inputImg.sample(__nv_smp, uv);

    float3 glow = float3(0.0);
    float wsum = 0.0;
    float r = u.radius;
    for (int i = 0; i < 16; i++) {
        float ang = float(i) * 0.3927; // 22.5°
        for (int j = 1; j <= 3; j++) {
            float rr = r * float(j) / 3.0;
            float2 off = float2(cos(ang), sin(ang)) * rr / eng.acResolution;
            float w = exp(-float(j) * float(j) * 0.4);
            glow += bright(inputImg.sample(__nv_smp, uv + off).rgb) * w;
            wsum += w;
        }
    }
    glow = glow * u.intensity / wsum;

    float3 outRgb = base.rgb + glow * u.mistura;
    __nv_out = float4(outRgb, base.a);
    return __nv_out;
}
