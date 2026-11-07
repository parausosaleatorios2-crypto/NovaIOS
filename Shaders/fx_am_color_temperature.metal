// ---------------------------------------------------------------------------
// Temperatura de cor (AM)
// origem : assets/effects/am-color-temperature.xml
// id     : nova.effect.am-color-temperature
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_color_temperatureParams {
    float temperature;
    float strength;
};

// --- funcoes auxiliares do efeito
// A curva do AM (válida de 1000 a 40000 K, e 0 para o branco puro), em como no AM (o padrão dele).
float3 colorTemperatureToRGB(const in float u.temperature) {
    float3x3 m = (u.temperature <= 6500.0) ? float3x3(float3(0.0, -2902.1955373783176, -8257.7997278925690),
                                                    float3(0.0, 1669.5803561666639, 2575.2827530017594),
                                                    float3(1.0, 1.3302673723350029, 1.8993753891711275)) :
                                               float3x3(float3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),
                                                    float3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),
                                                    float3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275));
    return mix(clamp(float3(m[0] / (float3(clamp(u.temperature, 1000.0, 40000.0)) + m[1]) + m[2]), float3(0.0), float3(1.0)),
               float3(1.0), smoothstep(1000.0, 0.0, u.temperature));
}

fragment float4 fx_am_color_temperature(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_color_temperatureParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 camada = inputImg.sample(__nv_smp, in.acScreenNorm);
    // A camada do AM chega pré-multiplicada EM 8 BITS (o premul do Android); no opaco, o float da textura. A leitura
    // dele é mediump.
    float3 p = camada.a < 1.0 ? floor(camada.rgb * camada.a * 255.0 + 0.5) / 255.0 : camada.rgb;
    float4 texColor = float4(p, camada.a);
    float3 rgb = texColor.rgb;
    float a = texColor.a;
    // Os uniforms do AM são (os do Nova nascem highp): a conta da temperatura começa em mediump, como lá.
    float temperaturaDoAm = u.temperature;
    float intensidadeDoAm = u.strength;
    rgb = mix(rgb, rgb * colorTemperatureToRGB(temperaturaDoAm * 1000.0), intensidadeDoAm);
    float3 saida = clamp(rgb, 0.0, 1.0);                            // o buffer de 8 bits do AM corta em 0 e 1
    __nv_out = a > 0.0 ? float4(min(saida / a, float3(1.0)), a) : float4(0.0);
    return __nv_out;
}
