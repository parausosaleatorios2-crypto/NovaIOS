// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-outline-basic.xml
// id     : com.alightcreative.effects.outlinebasic
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_outline_basicParams {
    float radius;
};

fragment float4 fx_toji_outline_basic(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_outline_basicParams&  u    [[buffer(1)]],
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
            float4 outColor;
            if( eng.acPass==0 ) {
                float nearest = u.radius * 2.0;
                for(int i=from; i<to; i++ ) {
                    float4 inColor = inputImg.sample(__nv_smp, float2(in.acScreenNorm.s + float(i)*(1.0/__nv_getTexSize(inputImg_info.size).x),in.acScreenNorm.t));
                    float xdist = inColor.a > 0.0 ? abs(float(i)) : u.radius*2.0;
                    nearest = min(nearest,xdist);
                }
                outColor = float4(nearest/u.radius);
            } else {
                float t = 2.0;
                for(int i=from; i<to; i++ ) {
                    float4 inColor = hdist.sample(__nv_smp, float2(in.acScreenNorm.s,in.acScreenNorm.t + float(i)*(1.0/__nv_getTexSize(inputImg_info.size).y)));
                    float xdist = inColor.r;
                    float ydist = abs(float(i))/u.radius;
                    float dist = length(float2(xdist,ydist));
                    t = min(t,dist);
                }
                outColor = t <= 0.95 ? float4(1.0,0.0,0.0,1.0) : float4(0.0);
                float4 original = inputImg.sample(__nv_smp, in.acScreenNorm.st);
                outColor = original + outColor*(1.0-original.a);
                //outColor = float4(t,0.0,0.0,t);
            }
            __nv_out = outColor;
    return __nv_out;
}
