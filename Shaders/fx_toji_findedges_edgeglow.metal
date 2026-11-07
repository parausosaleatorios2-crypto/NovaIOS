// ---------------------------------------------------------------------------
// @am:string/effect_findedges_name
// origem : assets/effects/toji-findedges-edgeglow.xml
// id     : com.alightcreative.effects.findedges-edgeglow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_findedges_edgeglowParams {
    float smoothing;
    float threshold;
    int invert;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_toji_findedges_edgeglow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_findedges_edgeglowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st = in.acScreenNorm;
            float2 fragSize = float2(1.)/__nv_getTexSize(inputImg_info.size) * u.smoothing;
            float w  = dot(float3(1.),inputImg.sample(__nv_smp, float2(in.acScreenNorm.x - fragSize.x, in.acScreenNorm.y)).rgb*luminanceWeighting);
            float e  = dot(float3(1.),inputImg.sample(__nv_smp, float2(in.acScreenNorm.x + fragSize.x, in.acScreenNorm.y)).rgb*luminanceWeighting);
            float n  = dot(float3(1.),inputImg.sample(__nv_smp, float2(in.acScreenNorm.x, in.acScreenNorm.y + fragSize.y)).rgb*luminanceWeighting);
            float s  = dot(float3(1.),inputImg.sample(__nv_smp, float2(in.acScreenNorm.x, in.acScreenNorm.y - fragSize.y)).rgb*luminanceWeighting);
            float nw  = dot(float3(1.),inputImg.sample(__nv_smp, float2(in.acScreenNorm.x - fragSize.x, in.acScreenNorm.y + fragSize.y)).rgb*luminanceWeighting);
            float ne  = dot(float3(1.),inputImg.sample(__nv_smp, float2(in.acScreenNorm.x + fragSize.x, in.acScreenNorm.y + fragSize.y)).rgb*luminanceWeighting);
            float sw  = dot(float3(1.),inputImg.sample(__nv_smp, float2(in.acScreenNorm.x - fragSize.x, in.acScreenNorm.y - fragSize.y)).rgb*luminanceWeighting);
            float se  = dot(float3(1.),inputImg.sample(__nv_smp, float2(in.acScreenNorm.x + fragSize.x, in.acScreenNorm.y - fragSize.y)).rgb*luminanceWeighting);

            float v = nw * 3. + n * 10. + ne * 3. + sw * -3. + s * -10. + se * -3.;
            float h = nw * -3. + w * -10. + sw * -3. + ne * 3. + e * 10. + se * 3.;
            float g = clamp(sqrt(h*h + v*v)-u.threshold, 0., 1.);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);

            if( u.invert ) {
                __nv_out = float4(1.-g,1.-g,1.-g,1.) * texColor.a;
            } else {
                __nv_out = float4(g,g,g,1.) * texColor;
            }
    return __nv_out;
}
