// ---------------------------------------------------------------------------
// @am:string/effect_smooth_edges_name
// origem : assets/effects/toji-smoothedges.xml
// id     : com.alightcreative.effects.smoothedges
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_smoothedgesParams {
    float strength;
    int maskToLayer;
};

// --- funcoes auxiliares do efeito
float4 xstreak() {
            float texelSize = 1.0 / eng.acScreenSize.x;
            float dist = u.strength * 0.05;
            int nSamples = int(clamp(dist/texelSize,1.01,100.01));
            float4 c = float4(0.);
            for( int i=1; i<nSamples; i++ ) {
                float offset = dist * (float(i)/float(nSamples-1) - 0.5);
                float2 sampleCoord = in.acScreenNorm + float2(offset,0.);
                float4 tc;
                if(eng.acPass==1) {
                    tc = inputImg.sample(__nv_smp, sampleCoord);
                } else {
                    tc = hstreak.sample(__nv_smp, sampleCoord);
                }
                if( offset < 0. ) {
                    c = c * (1.-tc.a) + tc;
                } else {
                    c = tc * (1.-c.a) + c;
                }
            }
            return c;
        }
        
        float4 ystreak() {
            float texelSize = 1.0 / eng.acScreenSize.y;
            float dist = u.strength * 0.05;
            int nSamples = int(clamp(dist/texelSize,1.01,100.01));
            float4 c = float4(0.);
            for( int i=1; i<nSamples; i++ ) {
                float offset = dist * (float(i)/float(nSamples-1) - 0.5);
                float2 sampleCoord = in.acScreenNorm + float2(0.,offset);
                float4 tc;
                if(eng.acPass==1) {
                    tc = inputImg.sample(__nv_smp, sampleCoord);
                } else {
                    tc = hstreak.sample(__nv_smp, sampleCoord);
                }
                if( offset < 0. ) {
                    c = c * (1.-tc.a) + tc;
                } else {
                    c = tc * (1.-c.a) + c;
                }
            }
            return c;
        }
        
        float4 composite( float4 a, float4 b) {
            return a * (1. - b.a) + b;
        }

fragment float4 fx_toji_smoothedges(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_smoothedgesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]],
    texture2d<float> hstreak [[texture(2)]],
    texture2d<float> vstreak [[texture(3)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& hblur_info [[buffer(3)]],
    constant NovaTexInfo& hstreak_info [[buffer(4)]],
    constant NovaTexInfo& vstreak_info [[buffer(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            if( u.maskToLayer ) {
                if( eng.acPass==1 || eng.acPass==2 ) {
                    __nv_out = float4(0.);
                } else {
                    float4 blur = hblur.sample(__nv_smp, in.acScreenNorm.st);
                    float4 base = inputImg.sample(__nv_smp, in.acScreenNorm.st);
                    float dd = 0.05 / ((1.+u.strength)*(1.+u.strength));
                    __nv_out = base * smoothstep(0.5-dd,0.5+dd,blur.a);
                }
            } else if( eng.acPass==1 || eng.acPass==2 ) {
                float4 c1 = xstreak();
                float4 c2 = ystreak();
                float4 base = inputImg.sample(__nv_smp, in.acScreenNorm);
                __nv_out = composite(composite(c1,c2),base);
            } else {
                float4 blur = hblur.sample(__nv_smp, in.acScreenNorm);
                float4 base = vstreak.sample(__nv_smp, in.acScreenNorm);
                float dd = 0.05 / ((1.+u.strength)*(1.+u.strength));
                float p = smoothstep(0.5-dd,0.5+dd,blur.a);
                __nv_out = base * p;
            }
    return __nv_out;
}
