// ---------------------------------------------------------------------------
// @am:string/effect_gradientoverlay_name
// origem : assets/effects/toji-gradientoverlay2.xml
// id     : com.alightcreative.gradientoverlay2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_gradientoverlay2Params {
    float4 color1;
    float4 color2;
    float angle;
    float2 offset;
    float scale;
    float alpha;
    int gradType;
    int blendMode;
};

fragment float4 fx_toji_gradientoverlay2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_gradientoverlay2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float a = u.angle * 0.0174533;
            float2 st = in.acLayerNorm;
            st -= 0.5;
            st -= (u.offset*float2(1,-1)) / 500.;
            st /= u.scale;
            st *= float2x2(
                sin(a), -cos(a),
                cos(a), sin(a)
            );
            st += 0.5;
            float t;

            if( u.gradType == 0 ) {
                t = st.x;
            } else if ( u.gradType == 1 ) {
                t = length( st - 0.5 ) * 2.0;
            } else if ( u.gradType == 2 ) {
                float2 xy = st - 0.5;
                float2 zw = float2(0,1.0);
                float a = __nv_atan(xy.x, xy.y);
                float b = __nv_atan(zw.x, zw.y);
                t = __nv_mod(((a-b)+6.28), 6.28)/6.28;
            } else {
                t = st.x;
            }

            t = clamp(t,0.0,1.0);

            float4 color = mix(u.color1, u.color2, t);
            float4 result;
            if( u.blendMode==1 ) {
                result = float4((texColor.rgb/texColor.a)*color.rgb,1.0) * texColor.a;
            } else if( u.blendMode==2 ) {
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-color.rgb)),1.0) * texColor.a;
            } else {
                result = float4(color.rgb,1.0)*texColor.a;
            }
            __nv_out = mix(texColor,result,u.alpha*color.a);
    return __nv_out;
}
