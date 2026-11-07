// ---------------------------------------------------------------------------
// Mapa Térmico (Ultra Motion)
// origem : assets/effects/um-heatmap-thermal.xml
// id     : nova.effect.ultramotion.heatmapthermal
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_heatmap_thermalParams {
    float gamma;
    float brightness;
    float blend;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

float3 termico(float t) {
    t = clamp(t, 0.0, 1.0);
    float3 preto = float3(0.0, 0.0, 0.05);
    float3 roxo  = float3(0.25, 0.0, 0.5);
    float3 azul  = float3(0.0, 0.3, 0.8);
    float3 verde = float3(0.0, 0.8, 0.2);
    float3 amar  = float3(1.0, 0.9, 0.0);
    float3 laran = float3(1.0, 0.45, 0.0);
    float3 verm  = float3(1.0, 0.1, 0.1);
    float3 branco = float3(1.0);
    if (t < 0.15) return mix(preto, roxo, t / 0.15);
    if (t < 0.30) return mix(roxo, azul, (t - 0.15) / 0.15);
    if (t < 0.50) return mix(azul, verde, (t - 0.30) / 0.20);
    if (t < 0.65) return mix(verde, amar, (t - 0.50) / 0.15);
    if (t < 0.80) return mix(amar, laran, (t - 0.65) / 0.15);
    if (t < 0.92) return mix(laran, verm, (t - 0.80) / 0.12);
    return mix(verm, branco, (t - 0.92) / 0.08);
}

fragment float4 fx_um_heatmap_thermal(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_heatmap_thermalParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
    float l = clamp(dot(c.rgb, LUMA) + u.brightness, 0.0, 1.0);
    l = pow(l, u.gamma);
    float3 cor = termico(l);
    __nv_out = float4(mix(c.rgb, cor, u.blend), c.a);
    return __nv_out;
}
