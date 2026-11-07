// ---------------------------------------------------------------------------
// @am:string/effect_curl_name
// origem : assets/effects/toji-curl.xml
// id     : com.alightcreative.effects.curl
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_curlParams {
    float offset;
    float radius;
    int curlFrom;
    int curlDirection;
    float stretch;
};

// --- funcoes auxiliares do efeito
#define PI 3.1415926536

        static float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }

fragment float4 fx_toji_curl(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_curlParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            //float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st = in.acLayerNorm;
            //st.x *= eng.acLayerSize.x/eng.acLayerSize.y;

            float2 adjCenter;// = center/1000.;
            if( u.curlDirection==0 ) {
                adjCenter = float2(u.offset,-u.radius);
            } else {
                adjCenter = float2(u.offset,1.+u.radius);
            }
            adjCenter.y = 1.-adjCenter.y;

            float2 dd = st-adjCenter;
            dd.x *= eng.acLayerSize.x/eng.acLayerSize.y;

            float circ = 2. * PI * u.radius / (eng.acLayerSize.x/eng.acLayerSize.y) * u.stretch;
            float a = 0.5 - (__nv_atan(dd.x, dd.y) / (2. * PI));
            float r = length(dd);

            //bool top = (origin==0 || origin==1);
            //bool right = (origin==1 || origin==3);
            bool top = (u.curlDirection==1); // (center.y>=500.);
            bool right = (u.curlFrom==0);

            float cline = smoothstep(1.0-(2./eng.acLayerSize.y),1.0,1.-abs(u.radius-length(dd)));

            if( top ) {
                float topY = adjCenter.y + u.radius;
                a = __nv_mod(a - 0.500, 1.);
                float arcDist = a*circ;
                if( right ) {
                    float2 v = float2(adjCenter.x-(arcDist),topY+(r-u.radius));

                    if( st.x < adjCenter.x || st.y < topY ) {
                        st = v;
                    }
                } else {
                    float2 v = float2((circ-arcDist+adjCenter.x),topY+(r-u.radius));

                    if( st.x > adjCenter.x || st.y < topY ) {
                        st = v;
                    }
                }
            } else {
                float bottomY = adjCenter.y - u.radius;
                float arcDist = a*circ;
                if( right ) {
                    float2 v = float2(adjCenter.x-(circ-arcDist),bottomY-(r-u.radius));

                    if( st.x < adjCenter.x || st.y > bottomY ) {
                        st = v;
                    }
                } else {
                    float2 v = float2(arcDist+adjCenter.x,bottomY-(r-u.radius));

                    if( st.x > adjCenter.x || st.y > bottomY ) {
                        st = v;
                    }
                }
            }

            float inside = step(0.,st.x) * step(st.x,1.) * step(0.,st.y) * step(st.y,1.) * step(u.radius,r);

            float4 result = inputImg.sample(__nv_smp, l2s(st))*inside;
            float4 circleColor = float4(0.2,0.6,0.9,1.0);
            float circleAlpha = eng.acShowGuides?0.5:0.0;
            __nv_out = mix(result,circleColor,cline*circleAlpha);
    return __nv_out;
}
