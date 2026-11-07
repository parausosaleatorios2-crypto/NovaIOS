// ---------------------------------------------------------------------------
// @am:string/effect_dark_glow_name
// origem : assets/effects/toji-darkglow.xml
// id     : com.alightcreative.effects.darkglow
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_darkglowParams {
    float strength;
    float threshold;
    float4 color;
    float blend;
    float alpha;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

        float4 composite( float4 a, float4 b) {
            return a * (1. - b.a) + b;
        }

        float4 blurInternal(float2 texOffset, float2 st, float numBlurPixelsPerSide)
        {
            if(u.strength <= 0.0)
                return float4(0,0,0,0);
            const float PI = 3.14159265;
            //To get gauss(x) <= gauss(0)*0.1
            //x>=sigma*sqrt(2*ln10) = 2.14596602...
            //If you want to get gauss(x) <= gauss(0)*0.01 to get more dedicated result,
            //x>=2.0*sigma*sqrt(ln10) = 3.03485425....
            //currently, in my thought, 0.1 of the center pixel will be enough.
            float adjSigma = numBlurPixelsPerSide / 2.14596602;


            float3 incrementalGaussian;
            incrementalGaussian.x = 1.0 / (sqrt(2.0 * PI) * adjSigma);
            incrementalGaussian.y = exp(-0.5 / (adjSigma * adjSigma));
            incrementalGaussian.z = incrementalGaussian.y * incrementalGaussian.y;

            float4 avgValue = float4(0.0, 0.0, 0.0, 0.0);
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
                float2 stL = clamp(st - offsetL * texOffset, float2(0.0, 0.0), float2(1.0,1.0));
                float2 stR = clamp(st + offsetL * texOffset, float2(0.0, 0.0), float2(1.0, 1.0));
                avgValue += ((eng.acPass==1 ? downImg.sample(__nv_smp, stL) : hblur.sample(__nv_smp, stL)) * weightL);
                avgValue += ((eng.acPass==1 ? downImg.sample(__nv_smp, stR) : hblur.sample(__nv_smp, stR)) * weightL);
            }

            return avgValue / coefficientSum;
        }

fragment float4 fx_toji_darkglow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_darkglowParams&  u    [[buffer(1)]],
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

            if( eng.acPass == 0 ) {
                float4 c = inputImg.sample(__nv_smp, in.acScreenNorm.st);
                float luminance = dot(c.rgb, luminanceWeighting);
                __nv_out = (luminance < u.threshold) ? mix(c,u.color*c.a,u.blend) : float4(0.);
            }
            else if( eng.acPass==1 ) {
                float kernelSize = u.strength / 2.0 * 1.14 / 4.0 / 3.0 * length(eng.acPreviewSize);
                float2 texOffset = float2(1.0/downImg_info.size.x, 0.0);
                __nv_out = blurInternal(texOffset, in.acScreenNorm.st, kernelSize);
            } else if( eng.acPass==2 ) {
                float kernelSize = u.strength / 2.0 * 1.14 / 4.0 / 3.0 * length(eng.acPreviewSize);
                float2 texOffset = float2(0.0, 1.0/hblur_info.size.y);
                float4 base = inputImg.sample(__nv_smp, in.acScreenNorm.st);
                float4 result;
                if(u.strength <= 0.0) { 
                    float luminance = dot(base.rgb, luminanceWeighting);
                    result = (luminance < u.threshold) ? mix(base,u.color*base.a,u.blend) : float4(0.);
                } else {
                    result = blurInternal(texOffset, in.acScreenNorm.st, kernelSize);
                }
                __nv_out = composite(base,float4((result.rgb/max(result.a,0.0001))*(base.rgb/max(base.a,0.0001)),1)*min(base.a,result.a)*u.alpha);
            } else {
                __nv_out = vblur.sample(__nv_smp, in.acScreenNorm.st);
            }
    return __nv_out;
}
