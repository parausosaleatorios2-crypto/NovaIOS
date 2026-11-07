// ---------------------------------------------------------------------------
// @am:string/effect_ribbon_name
// origem : assets/effects/toji-ribbon.xml
// id     : com.alightcreative.effects.ribbon
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_ribbonParams {
    float amplitude;
    float frequency;
    float width;
    float phase;
    float offset;
    float4 color;
    int punchout;
    float smoothing;
    float4 tintColor;
    float tint;
    float angle;
};

fragment float4 fx_toji_ribbon(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_ribbonParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st = in.acLayerNorm.st;

            float a = u.angle * 0.0174533;
            st -= 0.5;
            st *= float2x2(
                cos(a), -sin(a),
                sin(a), cos(a)
            );
            st += 0.5;

            float x = st.x;

            float y;
            float t;

            y = sin(x * u.frequency);
            t = 0.01*(-u.phase*130.0);
            y += sin(x*u.frequency*2.1 + t)*4.5;
            y += sin(x*u.frequency*1.72 + t*1.121)*4.0;
            y += sin(x*u.frequency*2.221 + t*0.437)*5.0;
            y += sin(x*u.frequency*3.1122+ t*4.269)*2.5;
            y *= u.amplitude*0.03;
            y += 0.5 + u.offset;

            float y1 = y;

            y = sin(x * u.frequency);
            t = 0.01*(-u.phase*130.0)+u.width;
            y += sin(x*u.frequency*2.1 + t)*4.5;
            y += sin(x*u.frequency*1.72 + t*1.121)*4.0;
            y += sin(x*u.frequency*2.221 + t*0.437)*5.0;
            y += sin(x*u.frequency*3.1122+ t*4.269)*2.5;
            y *= u.amplitude*0.03;
            y += 0.5 + u.offset;

            float y2 = y;

            //float p = = st.y > min(y1,y2) && st.y < max(y1,y2) ? u.color : float4(0.);

            float lowy = min(y1,y2);
            float highy = max(y1,y2);

            //float b = u.smoothing*(highy-lowy)/2.;
            float b = u.smoothing/20.;

            //float p = st.y > lowy && st.y < highy ? 1.0 : 0.0;

            float p = min(smoothstep(lowy-b/2.,lowy+b/2.,st.y), 1.-smoothstep(highy-b/2.,highy+b/2.,st.y));

            float4 mixedColor = mix(u.color,u.tintColor,smoothstep(y1,y2,st.y)*u.tint);

            float4 c = mixedColor * p;
            if( u.punchout ) {
                __nv_out = texColor * (1.0-p);
            } else {
                c *= texColor.a;
                __nv_out = c + (texColor*(1.0-c.a));
            }
    return __nv_out;
}
