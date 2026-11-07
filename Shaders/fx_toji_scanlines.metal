// ---------------------------------------------------------------------------
// VHS Scanline
// origem : assets/effects/toji-scanlines.xml
// id     : com.alightcreative.effects.vhs_scanline
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_scanlinesParams {
    float blendFactor;
    float scanlineHeight;
    float scanlineIntensity;
    float scrollSpeed;
    float scanAngle;
    float4 scanColor;
    float progress;
    float grainIntensity;
    float grainTimeScale;
    float glitchProbability;
    float glitchIntensityX;
    float glitchIntensityY;
    float glitchPhase;
    float bandSpeed;
    float bandHeight;
    float bandIntensity;
    float bandChoppiness;
    float staticAmount;
    float warpFactor;
    float chromaAmount;
    float bandPos;
};

// --- funcoes auxiliares do efeito
static float hash12(float2 p) {
            return fract(sin(dot(p, float2(12.9898,78.233))) * 43758.5453);
        }

fragment float4 fx_toji_scanlines(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_scanlinesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 res = eng.acScreenSize;
            float2 uv  = in.acScreenNorm;

            // ---- Scanline with angle ----
            float ang = radians(u.scanAngle);
            float2 dir = float2(cos(ang), sin(ang));
            float scanCoord = dot(uv * res, dir);

            float scanline = sin((scanCoord - u.progress * u.scrollSpeed) / max(u.scanlineHeight, 1.0));
            float3 vhsColor = u.scanColor.rgb * scanline * u.scanlineIntensity;

            // Grain
            float2 grainSeed = float2(12.9898, 78.233) + u.progress * u.grainTimeScale;
            float grain = fract(sin(dot((uv * res) * uv, grainSeed)) * 43758.5453);
            vhsColor += float3(grain) * u.grainIntensity;

            // Glitch
            float2 tuv = uv;
            if (u.glitchPhase < u.glitchProbability) {
                float gx = (fract(sin(u.progress * 12.9898) * 43758.5453) - 0.5) * u.glitchIntensityX;
                float gy = (fract(cos(u.progress * 78.233) * 43758.5453) - 0.5) * u.glitchIntensityY;
                tuv += float2(gx, gy);
            }

            // Vertical band
            float bandNoise = hash12(uv * res);
            float3 chromaColor = inputImg.sample(__nv_smp, tuv).rgb;

            if (abs(uv.y - u.bandPos) < u.bandHeight) {
                float rs = bandNoise * u.bandChoppiness;
                vhsColor += float3(rs) * u.staticAmount;

                tuv.x += sin(uv.y * res.y * 10.0 + rs) * u.warpFactor;

                chromaColor = float3(
                    inputImg.sample(__nv_smp, tuv + float2(u.chromaAmount * rs, 0.0)).r,
                    inputImg.sample(__nv_smp, tuv).g,
                    inputImg.sample(__nv_smp, tuv - float2(u.chromaAmount * rs, 0.0)).b
                );

                vhsColor = mix(vhsColor, chromaColor, u.bandIntensity * (1.0 - rs));
            }

            float3 originalColor = inputImg.sample(__nv_smp, tuv).rgb;
            __nv_out = float4(mix(originalColor, vhsColor, u.blendFactor), 1.0);
    return __nv_out;
}
