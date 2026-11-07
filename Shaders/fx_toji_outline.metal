// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-outline.xml
// id     : com.alightcreative.effects.outline
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_outlineParams {
    float radius;
};

fragment float4 fx_toji_outline(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_outlineParams&  u    [[buffer(1)]],
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
            // Size of a pixel
            float2 imgSize = __nv_getTexSize(inputImg_info.size);
            float px = (1.0/imgSize.x);
            float py = (1.0/imgSize.y);
            if( eng.acPass==0 ) {
                float nearestOutside = u.radius * 2.0;
                float nearestInside = u.radius * 2.0;
                for(int i=from; i<to; i++ ) {
                    float4 inColor = inputImg.sample(__nv_smp, float2(in.acScreenNorm.s + float(i)*px,in.acScreenNorm.t));
                    float xdistOut = inColor.a > 0.0 ? abs(float(i)) : u.radius*2.0;
                    float xdistIn = inColor.a < 0.003 ? abs(float(i)) : u.radius*2.0;
                    nearestOutside = min(nearestOutside,xdistOut);
                    nearestInside = min(nearestInside,xdistIn);
                }
                __nv_out = float4(nearestOutside/u.radius, nearestInside/u.radius, 0.0, 1.0);
            } else {
                float tIn = 2.0;
                float tOut = 2.0;
                for(int i=from; i<to; i++ ) {
                    float4 inColor = hdist.sample(__nv_smp, float2(in.acScreenNorm.s,in.acScreenNorm.t + float(i)*py));
                    float xdistOut = inColor.r;
                    float xdistIn = inColor.g;
                    float ydist = abs(float(i))/u.radius;
                    float distOut = length(float2(xdistOut,ydist));
                    float distIn = length(float2(xdistIn,ydist));
                    tIn = min(tIn,distIn);
                    tOut = min(tOut,distOut);
                }
                float tMid = tIn*2.0 + tOut*2.0;
                float4 original = inputImg.sample(__nv_smp, in.acScreenNorm.st);
                float4 outColor = mix(float4(1.0,0.0,0.0,1.0), float4(0.0), smoothstep(1.0-1.5/u.radius,1.0,tOut));
                float4 inColor = mix(float4(0.0,0.0,1.0,1.0), float4(0.0), smoothstep(1.0-1.5/u.radius,1.0,tIn)) * original.a;
                float4 midColor = mix(float4(0.0,1.0,0.0,1.0), float4(0.0), smoothstep(1.0-1.5/u.radius,1.0,tMid));
                float4 result = outColor;
                result = original + result*(1.0-original.a);
                result = inColor + result*(1.0-inColor.a);
                result = midColor + result*(1.0-midColor.a);
                __nv_out = result;
            }
    return __nv_out;
}
