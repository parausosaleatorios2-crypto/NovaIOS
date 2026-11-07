// ---------------------------------------------------------------------------
// @am:string/effect_colortemperature_name
// origem : assets/effects/toji-colortemperature.xml
// id     : com.alightcreative.effects.colortemperature
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_colortemperatureParams {
    float temperature;
    float strength;
};

// --- funcoes auxiliares do efeito
// Valid from 1000 to 40000 K (and additionally 0 for pure full white)
        static float3 colorTemperatureToRGB(const in float u.temperature){
            float3x3 m = (u.temperature <= 6500.0) ? float3x3(float3(0.0, -2902.1955373783176, -8257.7997278925690),
                                                  float3(0.0, 1669.5803561666639, 2575.2827530017594),
                                                  float3(1.0, 1.3302673723350029, 1.8993753891711275)) :
                                             float3x3(float3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),
                                                  float3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),
                                                  float3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275));
            return mix(clamp(float3(m[0] / (float3(clamp(u.temperature, 1000.0, 40000.0)) + m[1]) + m[2]), float3(0.0), float3(1.0)), float3(1.0), smoothstep(1000.0, 0.0, u.temperature));
        }

fragment float4 fx_toji_colortemperature(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_colortemperatureParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float3 rgb = texColor.rgb;
            float a = texColor.a;
            rgb = mix(rgb, rgb * colorTemperatureToRGB(u.temperature * 1000.0), u.strength);
            __nv_out = float4(rgb,a);
    return __nv_out;
}
