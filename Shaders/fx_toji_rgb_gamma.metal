// ---------------------------------------------------------------------------
// @am:string/effect_rgb_gamma_name
// origem : assets/effects/toji-rgb-gamma.xml
// id     : com.alightcreative.effects.rgb-gamma
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_rgb_gammaParams {
    float redGamma;
    float greenGamma;
    float blueGamma;
};

fragment float4 fx_toji_rgb_gamma(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_rgb_gammaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            texColor.rgb = pow(texColor.rgb,float3(1.0/u.redGamma,1.0/u.greenGamma,1.0/u.blueGamma));
            __nv_out = texColor;
    return __nv_out;
}
