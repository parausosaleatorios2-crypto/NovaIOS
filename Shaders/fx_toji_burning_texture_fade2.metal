// ---------------------------------------------------------------------------
// Burning Texture Fade
// origem : assets/effects/toji-burning_texture_fade2.xml
// id     : com.alightcreative.effects.burning_texture_fade
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_burning_texture_fade2Params {
    float progress;
    float feather;
    float noiseScale;
    float4 heatColor;
    float burnIntensity;
    int useBackground;
    float bgScale;
    float time;
    float bgSpeed;
};

// --- funcoes auxiliares do efeito
// Burning Texture Fade (ShaderToy port with controls)
        // Original by Krzysztof Kondrak @k_kondrak; this port exposes u.progress and u.feather.

        // Hash random
        static float r(float2 p){
            return fract(cos(p.x*42.98 + p.y*43.23) * 1127.53);
        }
        // Smoothed interpolation noise
        static float n(float2 p){
            float2 fn = floor(p);
            float2 sn = smoothstep(float2(0.0), float2(1.0), fract(p));
            float h1 = mix(r(fn), r(fn + float2(1.0,0.0)), sn.x);
            float h2 = mix(r(fn + float2(0.0,1.0)), r(fn + float2(1.0)), sn.x);
            return mix(h1, h2, sn.y);
        }
        static float noiseFBM(float2 p){
            return n(p/32.0) * 0.58 +
                   n(p/16.0) * 0.20 +
                   n(p/8.0)  * 0.10 +
                   n(p/4.0)  * 0.05 +
                   n(p/2.0)  * 0.02 +
                   n(p)      * 0.0125;
        }

        // Smokey/Hellish background using optional bgTex, animated by u.time parameters
        static float3 backgroundTex(float2 pos){
            // Map ShaderToy iTime*0.01 to controllable u.time/u.bgSpeed
            float2 offset = float2(0.0, u.bgSpeed * u.time);
            float3 color = float3(1.0);
            for(int i=0; i<3; ++i){
                float w = abs(__nv_mod(float(i) * 0.666, 2.0) - 1.0);
                float3 a = bgTex.sample(__nv_smp, pos - 0.25 * offset + 0.5).rgb;
                float3 b = bgTex.sample(__nv_smp, pos - offset).rgb;
                color += mix(a, b, w) * color * color;
            }
            return color * float3(0.0666, 0.0266, 0.00333);
        }

fragment float4 fx_toji_burning_texture_fade2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_burning_texture_fade2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> bgTex [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& bgTex_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 res = eng.acScreenSize;
            float2 fragCoord = in.acScreenNorm * res;
            // ShaderToy used uv = p/iResolution.xx; replicate largest-axis normalization
            // Use aspect-correct screen-normalized UVs to avoid stretching
            float2 uv = in.acScreenNorm;

            // Map u.progress [0,1] to original t range [0,1.2]
            float t = u.progress * 1.2;

            // Fade to black using noisy threshold with controllable u.feather and scale
            float val = noiseFBM(fragCoord * (u.noiseScale));
            // Original used smoothstep(t+0.1, t-0.1, val) (note reversed edges)
            float m = smoothstep(t + u.feather, t - u.feather, val);

            float4 src = inputImg.sample(__nv_smp, uv);
            float4 c = mix(src, float4(0.0), m);

            // Burning on edges where alpha got low
            float edge = step(c.a, 0.10);
            float3 heat = u.heatColor.rgb * (u.burnIntensity * noiseFBM(2000.0 * uv));
            c.rgb = clamp(c.rgb + edge * heat, 0.0, 1.0);

            // Background under holes (alpha very small)
            if (u.useBackground) {
                float3 bg = backgroundTex(u.bgScale * uv);
                c.rgb = c.rgb * step(0.01, c.a) + bg * step(c.a, 0.01);
            } else {
                // Plain burn-to-black
                c.rgb *= step(0.01, c.a);
            }

            __nv_out = c;
    return __nv_out;
}
