// ---------------------------------------------------------------------------
// @am:string/effect_kaleidoscope_name
// origem : assets/effects/toji-kaleidoscope.xml
// id     : com.alightcreative.effects.kaleidoscope
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_kaleidoscopeParams {
    float rcount;
    float2 centerPoint;
    float offsetAngle;
    int mirror;
};

fragment float4 fx_toji_kaleidoscope(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_kaleidoscopeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float segmentAngle = 360.0 / u.rcount;
            float rad = segmentAngle * 0.0174533;

            float offsetRad = u.offsetAngle * 0.0174533;

            float2 origin = (u.centerPoint*float2(1.0,-1.0))/1000.0 + 0.5;
            float2 pos = in.acLayerNorm-origin;
            pos.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            float r = length(pos);
            float a = __nv_atan(pos.y, pos.x);

            float sampleAngle = __nv_mod(a, rad);
            if( u.mirror ) {
                sampleAngle = abs(sampleAngle-rad/2.0);
            }
            sampleAngle += offsetRad;

            float2x2 rmat = float2x2(cos(sampleAngle),-sin(sampleAngle),sin(sampleAngle),cos(sampleAngle));

            float2 sampleCoord = float2(r,0.0) * rmat;

            sampleCoord.x /= eng.acLayerSize.x/eng.acLayerSize.y;

            sampleCoord += origin;

            sampleCoord = (float4(sampleCoord,0.0,1.0) * eng.acLayerToScreen).xy;

            __nv_out = inputImg.sample(__nv_smp, sampleCoord);
    return __nv_out;
}
