// ---------------------------------------------------------------------------
// Solarizar
// origem : assets/effects/solarize.xml
// id     : nova.effect.solarize
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct solarizeParams {
    float level;
    float softness;
    int channels;
};

// --- funcoes auxiliares do efeito
float solarizeChannel(float value) {
    float folded = 1.0 - abs(value - u.level) / max(1.0 - u.level, 0.001);
    return mix(value, folded, smoothstep(u.level - u.softness, u.level + u.softness, value));
}

fragment float4 fx_solarize(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant solarizeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);
    float3 result = color.rgb;

    if (u.channels == 1) {
        result = float3(
            solarizeChannel(color.r),
            solarizeChannel(color.g),
            solarizeChannel(color.b)
        );
    } else if (u.channels == 2) {
        result.r = solarizeChannel(color.r);
    } else if (u.channels == 3) {
        result.g = solarizeChannel(color.g);
    } else if (u.channels == 4) {
        result.b = solarizeChannel(color.b);
    } else {
        // Pela luminância: a cor não muda de matiz, só a claridade dobra. Fica
        // bem menos agressivo que inverter canal por canal.
        float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
        float folded = solarizeChannel(luma);
        result = color.rgb * (luma > 0.0001 ? folded / luma : 0.0);
    }

    __nv_out = float4(clamp(result, 0.0, 1.0), color.a);
    return __nv_out;
}
