// ---------------------------------------------------------------------------
// @am:string/effect_pinchbulge_name
// origem : assets/effects/toji-pinchbulge2.xml
// id     : com.alightcreative.effects.pinchbulge2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_pinchbulge2Params {
    float2 centerPoint;
    float strength;
    float radius;
};

fragment float4 fx_toji_pinchbulge2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_pinchbulge2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 UV = in.acScreenNorm;
            float2 center = eng.acLayerCenterNorm-(u.centerPoint/1000. * float2(-1.,1.));

            UV -= center;
            UV.x *= eng.acScreenSize.x / eng.acScreenSize.y;
            float dist = length(UV);
            if ( dist < u.radius ) {
                float p = dist / u.radius;
                if(u.strength > 0.) {
                    UV *= mix(1.0, smoothstep(0.0, u.radius / dist, p), u.strength * 0.75);
                } else {
                    UV *= mix(1.0, pow(p, 1.0 + u.strength * 0.75) * u.radius / dist, 1.0 - p);
                }
            }
            UV.x /= eng.acScreenSize.x / eng.acScreenSize.y;
            UV += center;

            __nv_out = inputImg.sample(__nv_smp, UV);
    return __nv_out;
}
