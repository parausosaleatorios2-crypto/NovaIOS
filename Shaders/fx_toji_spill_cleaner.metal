// ---------------------------------------------------------------------------
// @am:string/effect_key_spill_cleaner_name
// origem : assets/effects/toji-spill-cleaner.xml
// id     : com.alightcreative.effects.spill-cleanup
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_spill_cleanerParams {
    float strength;
};

// --- funcoes auxiliares do efeito
static float4 sampleTex(float2 uv) {
            if( eng.acPass==1 ) {
                return blurImg.sample(__nv_smp, uv);
            } else {
                return hstreak.sample(__nv_smp, uv);
            }
        }
        
        static float4 xstreak() {
            float texelSize = 1.0 / eng.acScreenSize.x;
            float dist = u.strength * 0.05;
            int nSamples = int(clamp(dist/texelSize,1.01,100.01));
            float4 c = float4(0.);
            for( int i=1; i<nSamples; i++ ) {
                float offset = dist * (float(i)/float(nSamples-1) - 0.5);
                float2 sampleCoord = in.acScreenNorm + float2(offset,0.);
                float4 tc = sampleTex(sampleCoord);
                if( offset < 0. ) {
                    c = c * (1.-tc.a) + tc;
                } else {
                    c = tc * (1.-c.a) + c;
                }
            }
            return c;
        }
        
        static float4 ystreak() {
            float texelSize = 1.0 / eng.acScreenSize.y;
            float dist = u.strength * 0.05;
            int nSamples = int(clamp(dist/texelSize,1.01,100.01));
            float4 c = float4(0.);
            for( int i=1; i<nSamples; i++ ) {
                float offset = dist * (float(i)/float(nSamples-1) - 0.5);
                float2 sampleCoord = in.acScreenNorm + float2(0.,offset);
                float4 tc = sampleTex(sampleCoord);
                if( offset < 0. ) {
                    c = c * (1.-tc.a) + tc;
                } else {
                    c = tc * (1.-c.a) + c;
                }
            }
            return c;
        }
        
        static float4 composite( float4 a, float4 b) {
            return a * (1. - b.a) + b;
        }

        float3x3 rgb2yuv = float3x3(
             0.299,     0.587,    0.114,
            -0.14713,  -0.28886,  0.436,
             0.615,    -0.51499, -0.10001
        );
        float3x3 yuv2rgb = float3x3(
            1.0,  0.0,      1.13983,
            1.0, -0.39465, -0.58060,
            1.0,  2.03211,  0.0
        );

fragment float4 fx_toji_spill_cleaner(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_spill_cleanerParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> blurImg [[texture(1)]],
    texture2d<float> hstreak [[texture(2)]],
    texture2d<float> vstreak [[texture(3)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& blurImg_info [[buffer(3)]],
    constant NovaTexInfo& hstreak_info [[buffer(4)]],
    constant NovaTexInfo& vstreak_info [[buffer(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            if( eng.acPass==1 || eng.acPass==2 ) {
                float4 c1 = xstreak();
                float4 c2 = ystreak();
                float4 blur = blurImg.sample(__nv_smp, in.acScreenNorm);
                __nv_out = composite(composite(c1,c2),blur);
            } else {
                float4 base = inputImg.sample(__nv_smp, in.acScreenNorm);
                float4 blur = blurImg.sample(__nv_smp, in.acScreenNorm);
                float4 streak = vstreak.sample(__nv_smp, in.acScreenNorm);
                float4 c = streak * saturate((1.-blur.a)*2.) * base.a;
                float3 baseYUV = (base.rgb/max(0.00001,base.a)) * rgb2yuv;
                float3 cYUV = (c.rgb/max(0.00001,c.a)) * rgb2yuv;
                cYUV.x = baseYUV.x;
                c = float4(cYUV * yuv2rgb,1.) * c.a;
                __nv_out = composite(base,c);
            }
    return __nv_out;
}
