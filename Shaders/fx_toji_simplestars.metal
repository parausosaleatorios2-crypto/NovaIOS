// ---------------------------------------------------------------------------
// @am:string/effect_simplestars_name
// origem : assets/effects/toji-simplestars.xml
// id     : com.alightcreative.effects.simplestars
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_simplestarsParams {
    float2 starParallax;
    float starDepth;
    float starSize;
    float starFeather;
    float4 color;
    float alpha;
    float starCount;
    float brightness;
    int blendMode;
};

// --- funcoes auxiliares do efeito
static float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }

        static float rand(float2 co){
            return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
        }

        static float2 rand2(float2 co){
            return float2(rand(co), rand(co+float2(3.7321,9.2517)*float2(7.1231,6.9377)));
        }

        static float star(float2 st, float size, float feather) {
            float adjFeather = size * feather;
            return smoothstep(1.0-size-adjFeather,1.0-size,sin(st.x*20.)*sin(st.y*20.));
        }

        static float stars(float2 st, float2 parallax, float depth, float size, float feather) {
            float p = 0.;

            size *= 0.001;

            float f = fract(depth);
            float layer = floor(depth);
            //const float layers = 25.;

            for( float i=1.; i<u.starCount; i+=1.) {
                float2 uv = st;
                uv *= (i-f)/9.;
                uv += parallax;
                p += star(uv+rand2(float2(i+layer,2.904)), size, feather) * smoothstep(u.starCount,1.,i-f);
            }

            return p;
        }

fragment float4 fx_toji_simplestars(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_simplestarsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st = in.acLayerNorm;
            st.y = 1. - st.y;
            st -= 0.5;
            st.x *= eng.acLayerSize.x/eng.acLayerSize.y;

            float p = stars(st, -u.starParallax/1000., u.starDepth, u.starSize, u.starFeather);

            float4 adjColor = clamp(float4(mix(u.color.rgb+float3(0.15,0.15,0.15),float3(1.),0.05)*p*u.brightness,1.),0.,1.)*p;

            float4 result;
            if( u.blendMode==1 ) {
                result = float4((texColor.rgb/texColor.a)*adjColor.rgb,1.0) * texColor.a;
            } else if( u.blendMode==2 ) {
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-adjColor.rgb)),1.0) * texColor.a;
            } else if( u.blendMode==3 ) {
                result = texColor * (1.0-min(p,1.0));
            } else {
                result = adjColor*texColor.a;
                result = texColor*(1.-result.a) + result;
            }
            __nv_out = mix(texColor,result,u.alpha);
    return __nv_out;
}
