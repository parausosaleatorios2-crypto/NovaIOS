// ---------------------------------------------------------------------------
// @am:string/effect_unsharp_mask_name
// origem : assets/effects/toji-unsharpmask.xml
// id     : com.alightcreative.effects.unsharpmask
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_unsharpmaskParams {
    float strength;
    float amount;
    float threshold;
    int showMask;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_toji_unsharpmask(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_unsharpmaskParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& hblur_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 blur = hblur.sample(__nv_smp, in.acScreenNorm.st);
            float4 base = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            float blurY = dot(blur.rgb, luminanceWeighting);
            float baseY = dot(base.rgb, luminanceWeighting);
            float4 adjColor = base * (1.+u.amount) - (blur*u.amount);
            float t = step(u.threshold,abs(blurY-baseY)*4.);
            t = smoothstep(u.threshold*0.75, (u.threshold+1.01)/2., abs(blurY-baseY)*4.);
            __nv_out = u.showMask ? float4(t,0.,0.,1.)*base.a : mix(base,adjColor,t);
    return __nv_out;
}
