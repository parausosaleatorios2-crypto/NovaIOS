// ---------------------------------------------------------------------------
// @am:string/effect_stripes_name
// origem : assets/effects/toji-stripes.xml
// id     : com.alightcreative.effects.stripes
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_stripesParams {
    float amount;
    float width;
    float angle;
    float phase;
    float4 color;
    int punchout;
    float smoothing;
    int screenSpace;
};

fragment float4 fx_toji_stripes(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_stripesParams&  u    [[buffer(1)]],
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
            } else {
                st = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/length(eng.acLayerSize);
            }
            //st /= st.y;
            //st /= eng.acLayerSize.y;
            float a = u.angle * 0.0174533;
            st *= float2x2(
                sin(a), -cos(a),
                cos(a), sin(a)
            );
            float p = __nv_mod(st.x*u.amount+u.phase, 1.0);
            p = smoothstep(u.width,u.width-u.smoothing,p)*smoothstep(0.0,u.smoothing,p);
            float4 c = u.color * p;
            if( u.punchout ) {
                __nv_out = texColor * (1.0-p);
            } else {
                c *= texColor.a;
                __nv_out = c + (texColor*(1.0-c.a));
            }
    return __nv_out;
}
