// ---------------------------------------------------------------------------
// Dream Bloom
// origem : assets/effects/toji-2Dreambloom.xml
// id     : com.alightcreative.effects.dream_bloom
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_2DreambloomParams {
    float strength;
    float threshold;
    float intensity;
    float4 tint;
    float colorR;
    float colorG;
    float colorB;
    float dispersion;
    float dispersionAngle;
    float halo;
    float blend;
    float alpha;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

        static float4 composite(float4 a, float4 b) {
            return a * (1. - b.a) + b;
        }

        static float4 blurInternal(float2 texOffset, float2 st, float numBlurPixelsPerSide)
        {
            if(u.strength <= 0.0)
                return float4(0,0,0,0);
            const float PI = 3.14159265;
            float adjSigma = numBlurPixelsPerSide / 2.14596602;

            float3 incrementalGaussian;
            incrementalGaussian.x = 1.0 / (sqrt(2.0 * PI) * adjSigma);
            incrementalGaussian.y = exp(-0.5 / (adjSigma * adjSigma));
            incrementalGaussian.z = incrementalGaussian.y * incrementalGaussian.y;

            float4 avgValue = float4(0.0);
            float coefficientSum = 0.0;

            avgValue += ((eng.acPass==1 ? downImg.sample(__nv_smp, st) : hblur.sample(__nv_smp, st)).rgba * incrementalGaussian.x);
            coefficientSum += incrementalGaussian.x;

            for (float i = 1.0; i <= numBlurPixelsPerSide; i += 2.0) {
                float offset0 = i;
                float offset1 = i + 1.0;
                incrementalGaussian.xy *= incrementalGaussian.yz;
                coefficientSum += (2.0 * incrementalGaussian.x);
                float weight0 = incrementalGaussian.x;
                incrementalGaussian.xy *= incrementalGaussian.yz;
                coefficientSum += (2.0 * incrementalGaussian.x);
                float weight1 = incrementalGaussian.x;
                float weightL = weight0 + weight1;
                float offsetL = (offset0*weight0 + offset1*weight1) / weightL;
                float2 stL = clamp(st - offsetL * texOffset, float2(0.0), float2(1.0));
                float2 stR = clamp(st + offsetL * texOffset, float2(0.0), float2(1.0));
                avgValue += ((eng.acPass==1 ? downImg.sample(__nv_smp, stL) : hblur.sample(__nv_smp, stL)) * weightL);
                avgValue += ((eng.acPass==1 ? downImg.sample(__nv_smp, stR) : hblur.sample(__nv_smp, stR)) * weightL);
            }
            return avgValue / coefficientSum;
        }

fragment float4 fx_toji_2Dreambloom(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_2DreambloomParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> downImg [[texture(1)]],
    texture2d<float> hblur [[texture(2)]],
    texture2d<float> vblur [[texture(3)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& downImg_info [[buffer(3)]],
    constant NovaTexInfo& hblur_info [[buffer(4)]],
    constant NovaTexInfo& vblur_info [[buffer(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            if (eng.acPass == 0) {
                // Bright-pass
                float4 c = inputImg.sample(__nv_smp, in.acScreenNorm.st);
                float lum = dot(c.rgb, luminanceWeighting);
                float3 tintRGB = u.tint.rgb; // base u.tint
                float3 colored = mix(c.rgb, tintRGB * c.a, u.blend);
                __nv_out = (lum > u.threshold) ? float4(colored, c.a) : float4(0.0);
            } else if (eng.acPass == 1) {
                float kernelSize = u.strength * 0.285 * length(eng.acPreviewSize);
                float2 texOffset = float2(1.0/downImg_info.size.x, 0.0);
                __nv_out = blurInternal(texOffset, in.acScreenNorm.st, kernelSize);
            } else if (eng.acPass == 2) {
                float kernelSize = u.strength * 0.285 * length(eng.acPreviewSize);
                float2 texOffset = float2(0.0, 1.0/hblur_info.size.y);
                __nv_out = blurInternal(texOffset, in.acScreenNorm.st, kernelSize);
            } else {
                // Final composite with chromatic u.dispersion and u.halo
                float4 base = inputImg.sample(__nv_smp, in.acScreenNorm.st);
                float4 blurTex = vblur.sample(__nv_smp, in.acScreenNorm.st);
                float blurAlpha = blurTex.a;

                // Dispersion direction
                float2 dir = float2(cos(u.dispersionAngle), sin(u.dispersionAngle));
                float2 offR = dir * u.dispersion * 0.5;
                float2 offG = -dir * u.dispersion * 0.25;
                float2 offB = dir * u.dispersion;

                // Sample per-channel at different offsets
                float r = vblur.sample(__nv_smp, clamp(in.acScreenNorm.st + offR, float2(0.0), float2(1.0))).r;
                float g = vblur.sample(__nv_smp, clamp(in.acScreenNorm.st + offG, float2(0.0), float2(1.0))).g;
                float b = vblur.sample(__nv_smp, clamp(in.acScreenNorm.st + offB, float2(0.0), float2(1.0))).b;

                float3 glowRGB = float3(r * u.colorR, g * u.colorG, b * u.colorB);
                glowRGB *= u.intensity;

                // Halo based on blur u.alpha squeeze
                float hsq = 0.15;
                float h = (1. - smoothstep(0.0, hsq, abs(blurAlpha - hsq))) * u.halo;
                float3 haloRGB = mix(glowRGB/hsq * u.halo, u.tint.rgb * u.halo, u.blend) * h;
                glowRGB += haloRGB;

                // Screen composite
                float3 baseRGB = base.rgb / max(base.a, 0.0001);
                float3 outRGB = 1.0 - (1.0 - baseRGB) * (1.0 - glowRGB);
                float4 outColor = float4(outRGB, 1.0) * min(base.a, blurAlpha) * u.alpha;
                __nv_out = composite(base, outColor);
            }
    return __nv_out;
}
