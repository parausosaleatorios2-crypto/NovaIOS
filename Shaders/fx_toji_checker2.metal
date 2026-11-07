// ---------------------------------------------------------------------------
// @am:string/effect_checker_name
// origem : assets/effects/toji-checker2.xml
// id     : com.alightcreative.effects.checker2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_checker2Params {
    float2 position;
    float amount;
    float2 stretch;
    float4 color;
    int punchout;
    float angle;
    int screenSpace;
};

fragment float4 fx_toji_checker2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_checker2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st;
            if(u.screenSpace) {
                st = in.acScreenNorm;
                st.y = 1.0  - st.y;
                st -= 0.5;
                st.x *= eng.acScreenSize.x/eng.acScreenSize.y;
                st -= (u.position/1200.0);
            } else {
                st = in.acLayerNorm;
                st.y = 1.0  - st.y;
                st -= 0.5;
                st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
                st -= (u.position/1200.0);
            }
            
            //st.y *= u.stretch;
            float a = u.angle * 0.0174533;
            st *= float2x2(
                sin(a), -cos(a),
                cos(a), sin(a)
            );
            float px = floor(st.x*u.amount/u.stretch.y);
            float py = floor(st.y*u.amount/u.stretch.x);
            float p = step(__nv_mod(px+py, 2.0),0.5);
            //p = smoothstep(0.5+smoothing/2.0,0.5,p)*smoothstep(0.0,smoothing/0.2,p);
            float4 c = u.color * p;
            if( u.punchout ) {
                __nv_out = texColor * (1.0-p);
            } else {
                float alpha = c.a*texColor.a;
                __nv_out = c*alpha + (texColor*(1.0-alpha));
            }
    return __nv_out;
}
