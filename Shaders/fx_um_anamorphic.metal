// ---------------------------------------------------------------------------
// Faixa Anamórfica (Ultra Motion)
// origem : assets/effects/um-anamorphic.xml
// id     : nova.effect.ultramotion.anamorphic
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_anamorphicParams {
    float reach;
    float threshold;
    float intensity;
    float4 tint;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_um_anamorphic(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_anamorphicParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        float3 soma = float3(0.0);
        float pt = 0.0;
        for (int i = -24; i <= 24; i++) {
            float t = float(i) / 24.0;
            float2 off = float2(t * u.reach, 0.0);
            float3 c = inputImg.sample(__nv_smp, in.acScreenNorm + off).rgb;
            float l = dot(c, LUMA);
            float k = smoothstep(u.threshold, u.threshold + 0.1, l);
            float w = exp(-t * t * 3.0);
            soma += c * k * w;
            pt += w;
        }
        __nv_out = float4(soma / pt, 1.0);
    } else {
        // mini desfoque vertical no streak + u.tint
        float3 soma = float3(0.0);
        float pt = 0.0;
        for (int i = -3; i <= 3; i++) {
            float2 off = float2(0.0, float(i) * eng.acTexelSize.y * 2.0);
            soma += hblur.sample(__nv_smp, in.acScreenNorm + off).rgb;
            pt += 1.0;
        }
        float3 streak = (soma / pt) * u.tint.rgb * u.tint.a;
        float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
        __nv_out = float4(orig.rgb + streak * u.intensity, orig.a);
    }
    return __nv_out;
}
