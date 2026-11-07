// ---------------------------------------------------------------------------
// @am:string/effect_offset_name
// origem : assets/effects/toji-offset.xml
// id     : com.alightcreative.effects.offset
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_offsetParams {
    float2 offset;
    float feather;
    int mask;
};

fragment float4 fx_toji_offset(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_offsetParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            //float2 pixel = float2(1.,1.)/__nv_getTexSize(inputImg_info.size);
            //float2 layerPixel = float2(1.,1.)/eng.acLayerSize;
            float2 sampleCoord = __nv_mod(in.acLayerNorm + (u.offset * float2(-1.,1.))/1000.0, 1.);
            float2 featherDist = (0.5-abs(__nv_mod(u.offset/1000.0, 1.)-0.5)) * 2.0 * u.feather;
            float2 featherAmount = u.feather<0.0001 ? float2(1.,1.) : smoothstep(float2(0.,0.),featherDist,min(sampleCoord, float2(1.,1.)-sampleCoord));
            sampleCoord = (float4(sampleCoord,0.0,1.0) * eng.acLayerToScreen).xy;
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float maskFactor;
            if( u.mask ) {
                maskFactor = texColor.a;
            } else {
                float2 s = step(float2(0.,0.), in.acLayerNorm) - step(float2(1.,1.), in.acLayerNorm);
                maskFactor = s.x * s.y;
            }
            float4 overColor = texColor * (1.-(featherAmount.x * featherAmount.y));
            //sampleCoord += pixel/2.;
            __nv_out = overColor + (inputImg.sample(__nv_smp, sampleCoord) * maskFactor * (1. - overColor.a));
    return __nv_out;
}
