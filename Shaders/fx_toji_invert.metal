// ---------------------------------------------------------------------------
// @am:string/effect_invert_name
// origem : assets/effects/toji-invert.xml
// id     : com.alightcreative.effects.invert
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_invertParams {
    int invertRed;
    int invertGreen;
    int invertBlue;
};

fragment float4 fx_toji_invert(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_invertParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float r = texColor.r;
            float g = texColor.g;
            float b = texColor.b;
            float a = texColor.a;
            if(u.invertRed)   r = a-r;
            if(u.invertGreen) g = a-g;
            if(u.invertBlue)  b = a-b;
            __nv_out = float4(r,g,b,a);
    return __nv_out;
}
