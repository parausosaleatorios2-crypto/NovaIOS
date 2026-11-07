// ---------------------------------------------------------------------------
// Drop Shadow
// origem : assets/effects/toji-3drop_shadow.xml
// id     : com.alightcreative.effects.dropshadow.custom
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_3drop_shadowParams {
    float4 shadowColor;
    float shadowAlpha;
    float direction;
    float distance;
    float softness;
    int shadowOnly;
};

fragment float4 fx_toji_3drop_shadow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_3drop_shadowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hdist [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& hdist_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            int from = -max(1,int(u.softness));
            int to = max(1,int(u.softness));

            float2 imgSize = __nv_getTexSize(inputImg_info.size);
            float px = (1.0/imgSize.x);
            float py = (1.0/imgSize.y);

            float ang = radians(u.direction);
            float2 offs = float2(cos(ang), sin(ang)) * u.distance;

            if (eng.acPass == 0) {
                float nearestOutside = u.softness * 2.0;
                for (int i = from; i < to; i++) {
                    float4 inColor = inputImg.sample(__nv_smp, float2(in.acScreenNorm.s + float(i) * px + offs.x * px, in.acScreenNorm.t));
                    float xdistOut = inColor.a > 0.0 ? abs(float(i)) : u.softness * 2.0;
                    nearestOutside = min(nearestOutside, xdistOut);
                }
                __nv_out = float4(nearestOutside / max(0.0001,u.softness), 0.0, 0.0, 1.0);
            } else {
                float tOut = 2.0;
                for (int i = from; i < to; i++) {
                    float4 inColor = hdist.sample(__nv_smp, float2(in.acScreenNorm.s, in.acScreenNorm.t + float(i) * py + offs.y * py));
                    float xdistOut = inColor.r;
                    float ydist = abs(float(i)) / max(0.0001,u.softness);
                    float distOut = length(float2(xdistOut, ydist));
                    tOut = min(tOut, distOut);
                }
                float4 original = inputImg.sample(__nv_smp, in.acScreenNorm.st);
                float4 baseShadow = float4(u.shadowColor.rgb, u.shadowAlpha);
                float4 outColor = mix(baseShadow, float4(0.0), smoothstep(0.0, 1.0, tOut));
                if (u.shadowOnly) {
                    __nv_out = outColor;
                } else {
                    float4 result = original + outColor * (1.0 - original.a);
                    __nv_out = result;
                }
            }
    return __nv_out;
}
