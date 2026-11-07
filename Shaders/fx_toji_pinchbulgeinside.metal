// ---------------------------------------------------------------------------
// @am:string/effect_pinchbulgeinside_name
// origem : assets/effects/toji-pinchbulgeinside.xml
// id     : com.alightcreative.effects.pinchbulgeinside
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_pinchbulgeinsideParams {
    float2 centerPoint;
    float strength;
    float radius;
    float feather;
    int gaussian;
};

// --- funcoes auxiliares do efeito
float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }

        float gsmooth(float low, float high, float value) {
            float p = clamp((value-low)/(high-low),0.,1.);
            p -= 1.0;
            return pow(2.71828,-((p*p)/0.125));
        }

fragment float4 fx_toji_pinchbulgeinside(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_pinchbulgeinsideParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 st = in.acLayerNorm;
            float2 center = u.centerPoint/1000. * float2(1.,-1.);

            float insideLayer = step(0.0,in.acLayerNorm.x) * step(in.acLayerNorm.x,1.0) * step(0.0,in.acLayerNorm.y) * step(in.acLayerNorm.y,1.0);
            float damping = smoothstep(0.0,u.feather,in.acLayerNorm.x) * smoothstep(0.0,u.feather,in.acLayerNorm.y) * smoothstep(1.0,1.0-u.feather,in.acLayerNorm.x) * smoothstep(1.0,1.0-u.feather,in.acLayerNorm.y);

            st -= 0.5;
            st.x *= eng.acLayerSize.x / eng.acLayerSize.y;
            st -= center;
            float dist = length(st);
            float2 prevSt = st;
            if ( dist < u.radius ) {
                float p = dist / u.radius;

                //p *= damping * insideLayer;

                if(u.strength > 0.) {
                    if( u.gaussian ) {
                        st *= mix(1.0, gsmooth(0.0, u.radius / dist, p), u.strength * 0.75);
                    } else {
                        st *= mix(1.0, smoothstep(0.0, u.radius / dist, p), u.strength * 0.75);
                    }
                } else {
                    st *= mix(1.0, pow(p, 1.0 + u.strength * 0.75) * u.radius / dist, 1.0 - p);
                }

                st = mix(prevSt,st,damping*insideLayer);
            }
            st += center;
            st.x /= eng.acLayerSize.x / eng.acLayerSize.y;
            st += 0.5;

            __nv_out = inputImg.sample(__nv_smp, l2s(st));
    return __nv_out;
}
