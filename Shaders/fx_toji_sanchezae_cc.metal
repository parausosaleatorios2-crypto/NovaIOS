// ---------------------------------------------------------------------------
// sanchezae_cc
// origem : assets/effects/toji-sanchezae_cc.xml
// id     : com.alightcreative.effects.sanchezae_cc
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_sanchezae_ccParams {
    float contrast;
    float bloom;
    float clarity;
    float vignette;
    float4 highlightTint;
    float4 shadowTint;
    float tintStrength;
};

// --- funcoes auxiliares do efeito
// sanchezae_cc: Cinematic color correction
        static float3 applyTint(float3 color, float3 shadows, float3 highlights, float strength) {
            float lum = dot(color, float3(0.299, 0.587, 0.114));
            float3 tint = mix(shadows, highlights, smoothstep(0.2, 0.8, lum));
            return mix(color, tint, strength);
        }
        static float vignetteMask(float2 uv, float strength) {
            float d = distance(uv, float2(0.5));
            return 1.0 - smoothstep(0.5-strength*0.5, 0.75-strength*0.5, d);
        }
        static float3 bloomPass(sampler2D tex, float2 uv, float strength) {
            float3 sum = float3(0.0);
            float w = 0.0;
            for (int x = -2; x <= 2; ++x)
            for (int y = -2; y <= 2; ++y) {
                float k = exp(-float(x*x + y*y)/4.0);
                sum += tex.sample(__nv_smp, uv + float2(x, y)*0.003).rgb * k;
                w += k;
            }
            return mix(float3(0.0), sum/w, strength);
        }
        static float3 clarityPass(sampler2D tex, float2 uv, float strength) {
            float3 orig = tex.sample(__nv_smp, uv).rgb;
            float3 sharp = orig * 2.0 - 0.25 * (
                tex.sample(__nv_smp, uv + float2(0.002,0)).rgb +
                tex.sample(__nv_smp, uv - float2(0.002,0)).rgb +
                tex.sample(__nv_smp, uv + float2(0,0.002)).rgb +
                tex.sample(__nv_smp, uv - float2(0,0.002)).rgb
            );
            return mix(orig, sharp, strength);
        }

fragment float4 fx_toji_sanchezae_cc(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_sanchezae_ccParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm;
            float4 src = inputImg.sample(__nv_smp, uv);
            // Clarity
            float3 color = clarityPass(inputImg, uv, u.clarity);
            // Contrast
            color = (color - 0.5) * u.contrast + 0.5;
            // Tint
            color = applyTint(color, u.shadowTint.rgb, u.highlightTint.rgb, u.tintStrength);
            // Bloom
            color += bloomPass(inputImg, uv, u.bloom);
            // Vignette
            float vign = vignetteMask(uv, u.vignette);
            color *= vign;
            __nv_out = float4(color, src.a);
    return __nv_out;
}
