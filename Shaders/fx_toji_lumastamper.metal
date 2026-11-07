// ---------------------------------------------------------------------------
// @am:string/effect_luma_stamper_name
// origem : assets/effects/toji-lumastamper.xml
// id     : com.alightcreative.effects.lumastamper
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_lumastamperParams {
    float4 color;
    float clipLow;
    float clipHigh;
    float gamma;
    int invert;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_toji_lumastamper(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_lumastamperParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float luminance = dot(texColor.rgb/max(0.000001,texColor.a), luminanceWeighting);
            float p = saturate((luminance-u.clipLow)/(max(1.-u.clipHigh,u.clipLow+0.0001)-u.clipLow));
            p = pow(p,1.0/u.gamma);
            if(u.invert) p = 1.-p;
            p *= texColor.a;
            __nv_out = u.color * p;
    return __nv_out;
}
