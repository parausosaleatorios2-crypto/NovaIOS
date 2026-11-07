// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-internal-shadow.xml
// id     : com.alightcreative.internal.shadow
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_internal_shadowParams {
    float sigma;
    float sdx;
    float sdy;
    float4 color;
    float alpha;
};

// --- funcoes auxiliares do efeito
#define MULTISAMPLE 1.0

        static float4 blurInternal(sampler2D texture, float2 texOffset, float2 st, float rate)
        {
            if(u.sigma <= 0.0) {
                if(st.x >= 0.0 && st.x <= 1.0 && st.y >= 0.0 && st.y <= 1.0)
                    return texture.sample(__nv_smp, st).rgba;
                else
                    return float4(0, 0, 0, 0);
            }
            const float PI = 3.14159265;
            //To get gauss(x) <= gauss(0)*0.1
            //x>=u.sigma*sqrt(2*ln10) = 2.14596602...
            //If you want to get gauss(x) <= gauss(0)*0.01 to get more dedicated result,
            //x>=2.0*u.sigma*sqrt(ln10) = 3.03485425....
            //currently, in my thought, 0.1 of the center pixel will be enough.
            float adjSigma = u.sigma * rate;
            float numBlurPixelsPerSide = (2.14596602 * adjSigma);


            float3 incrementalGaussian;
            incrementalGaussian.x = 1.0 / (sqrt(2.0 * PI) * adjSigma);
            incrementalGaussian.y = exp(-0.5 / (adjSigma * adjSigma));
            incrementalGaussian.z = incrementalGaussian.y * incrementalGaussian.y;

            float4 avgValue = float4(0.0, 0.0, 0.0, 0.0);
            float coefficientSum = 0.0;

            if(st.x >= 0.0 && st.x <= 1.0 && st.y >= 0.0 && st.y <= 1.0)
                avgValue += (texture.sample(__nv_smp, st).rgba * incrementalGaussian.x);
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
                float2 stL = st - offsetL * texOffset;
                float2 stR = st + offsetL * texOffset;
                if(stL.x >= 0.0 && stL.x <= 1.0 && stL.y >= 0.0 && stL.y <= 1.0)
                    avgValue += (texture.sample(__nv_smp, stL) * weightL);
                if(stR.x >= 0.0 && stR.x <= 1.0 && stR.y >= 0.0 && stR.y <= 1.0)
                    avgValue += (texture.sample(__nv_smp, stR) * weightL);
            }

            return avgValue / coefficientSum;
        }

fragment float4 fx_toji_internal_shadow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_internal_shadowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> downImg [[texture(1)]],
    texture2d<float> hblur [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& downImg_info [[buffer(3)]],
    constant NovaTexInfo& hblur_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            if( eng.acPass == 0 ) {
                __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            }
            else if( eng.acPass==1 ) {
                float2 texOffset = float2(1.0/eng.acProjectSize.x, 0.0);
                __nv_out = blurInternal(downImg, texOffset, float2(in.acScreenNorm.s - u.sdx*(texOffset.x/MULTISAMPLE),in.acScreenNorm.t), 0.5);
            } else {
                float2 texOffset = float2(0.0, 1.0/eng.acProjectSize.y);
                float4 result = blurInternal(hblur, texOffset, float2(in.acScreenNorm.s, in.acScreenNorm.t + u.sdy*(texOffset.y/MULTISAMPLE)), 0.5);
                float4 original = inputImg.sample(__nv_smp, in.acScreenNorm.st);
                result = original + u.color*result.a*u.alpha*(1.0-original.a);
                __nv_out = result;
            }
    return __nv_out;
}
