// ---------------------------------------------------------------------------
// @am:string/effect_cartoon_name
// origem : assets/effects/toji-cartoon.xml
// id     : com.alightcreative.effects.cartoon
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_cartoonParams {
    float strength;
    float4 outline_color;
};

// --- funcoes auxiliares do efeito
#define OUTLINE_BIAS -.5
        #define OUTLINE_POWER 1.
        #define PRECISION 6.

fragment float4 fx_toji_cartoon(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_cartoonParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float4 p = pow(texColor, float4(2.2));
            float4 s = pow(inputImg.sample(__nv_smp, in.acScreenNorm + float2(0.5, 0.5) / eng.acScreenSize), float4(2.2));
            float l = clamp(pow(length(p-s),OUTLINE_POWER)*u.strength+OUTLINE_BIAS,0.,1.);
            p = floor(pow(p,float4(1./2.2))*(PRECISION+.999))/PRECISION;
            float4 outColor = mix(p,u.outline_color,l);
            __nv_out = float4(outColor.rgb,texColor.a);
    return __nv_out;
}
