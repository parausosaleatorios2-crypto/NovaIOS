// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-outline-bad.xml
// id     : com.alightcreative.effects.outlinebad
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_outline_badParams {
    float radius;
};

fragment float4 fx_toji_outline_bad(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_outline_badParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hdist [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& hdist_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            int from = -max(1,int(u.radius));
            int to = max(1,int(u.radius));
            float nearest = u.radius * 2.0;
            float4 outColor;
            if( eng.acPass==0 ) {
                for(int i=from; i<to; i++ ) {
                    float4 inColor = inputImg.sample(__nv_smp, float2(in.acScreenNorm.s + float(i)*(1.0/__nv_getTexSize(inputImg_info.size).x),in.acScreenNorm.t));
                    float dist = inColor.a > 0.0 ? abs(float(i)) : u.radius*2.0;
                    nearest = min(nearest,dist);
                }
                outColor = float4(nearest <= u.radius ? 1.0 : 0.0);
            } else {
                for(int i=from; i<to; i++ ) {
                    //outColor += hblur.texture.sample(__nv_smp, float2(in.acScreenNorm.s,in.acScreenNorm.t + float(i)*(1.0/720.0)));
                    float4 inColor = hdist.sample(__nv_smp, float2(in.acScreenNorm.s,in.acScreenNorm.t + float(i)*(1.0/__nv_getTexSize(inputImg_info.size).y)));
                    float dist = inColor.a > 0.0 ? abs(float(i)) : u.radius*2.0;
                    nearest = min(nearest,dist);
                }
                outColor = nearest <= u.radius ? float4(1.0,0.0,0.0,1.0) : float4(0.0);
            }
            __nv_out = outColor;
    return __nv_out;
}
