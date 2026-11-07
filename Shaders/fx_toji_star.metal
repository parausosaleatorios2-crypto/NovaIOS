// ---------------------------------------------------------------------------
// @am:string/effect_star_name
// origem : assets/effects/toji-star.xml
// id     : com.alightcreative.effects.star
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_starParams {
    float2 position;
    float radius;
    float brightness;
    float shine;
    float4 color;
    float pointCount;
    float alpha;
    int blendMode;
};

// --- funcoes auxiliares do efeito
//float2 l2s( float2 v ) {
        //    return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        //}
        
        #define l2s(v) ((float4(v,0.,1.)*eng.acLayerToScreen).xy)

        float star(float2 st, float2 center, float r, float insideRadiusScale, float points) {
            float2 dc = st-center;
            float ir = r*insideRadiusScale;
            float a = (__nv_atan(dc.x, dc.y)+3.14159)/2.;
            float p = smoothstep(r,ir,length(dc));

            a = smoothstep(p,ir,abs(sin(a*points)));
            return clamp((p*1.264+a)*p*p,0.,1.);
        }

fragment float4 fx_toji_star(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_starParams&  u    [[buffer(1)]],
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

            float p = star(st,u.position/1000.0,u.radius,u.shine*0.995,u.pointCount);

            float4 adjColor = clamp(float4(mix(u.color.rgb+float3(0.15,0.15,0.15),float3(1.),0.05)*p*u.brightness,1.),0.,1.)*p;

            float4 result;
            if( u.blendMode==1 ) {
                result = float4((texColor.rgb/texColor.a)*adjColor.rgb,1.0) * texColor.a;
            } else if( u.blendMode==2 ) {
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-adjColor.rgb)),1.0) * texColor.a;
            } else {
                result = adjColor*texColor.a;
                result = texColor*(1.-result.a) + result;
            }
            __nv_out = mix(texColor,result,u.alpha);
    return __nv_out;
}
