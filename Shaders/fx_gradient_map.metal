// ---------------------------------------------------------------------------
// Mapa de gradiente
// origem : assets/effects/gradient-map.xml
// id     : nova.effect.gradientmap
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gradient_mapParams {
    float4 shadows;
    float4 midtones;
    float4 highlights;
    float midPoint;
};

fragment float4 fx_gradient_map(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gradient_mapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Luma perceptual (coeficientes ITU-R BT.601). Usar a média simples dos
    // canais daria peso igual ao azul, que o olho enxerga bem menos — e o
    // resultado ficaria com o mapeamento errado em céu e em pele.
    float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));

    float3 mapped;
    if (luma < u.midPoint) {
        mapped = mix(u.shadows.rgb, u.midtones.rgb, luma / u.midPoint);
    } else {
        mapped = mix(u.midtones.rgb, u.highlights.rgb, (luma - u.midPoint) / (1.0 - u.midPoint));
    }

    __nv_out = float4(clamp(mapped, 0.0, 1.0), color.a);
    return __nv_out;
}
