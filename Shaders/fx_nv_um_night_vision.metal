// ---------------------------------------------------------------------------
// Visão Noturna
// origem : assets/effects/nv-um-night-vision.xml
// id     : nova.effect.um-night-vision
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_um_night_visionParams {
    float gain;
    float grain;
    float vignette;
    float scanlines;
    float4 tint;
};

// --- funcoes auxiliares do efeito
float hash(float2 p) { return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }

fragment float4 fx_nv_um_night_vision(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_um_night_visionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float4 c = inputImg.sample(__nv_smp, uv);
    float L = dot(c.rgb, float3(0.2126, 0.7152, 0.0722));
    float boosted = clamp(L * u.gain, 0.0, 1.0);

    // u.tint em verde
    float3 col = mix(float3(boosted), u.tint.rgb * boosted * 1.4, 0.85);

    // u.scanlines horizontais
    float sl = 1.0 - u.scanlines * 0.5 * (0.5 + 0.5 * sin(uv.y * eng.acResolution.y * 3.14159));
    col *= sl;

    // grão
    float n = hash(uv * eng.acResolution + fract(eng.acTime));
    col += (n - 0.5) * u.grain;

    // vinheta radial
    float2 d = uv - 0.5;
    float v = 1.0 - smoothstep(0.3, 0.9, length(d) * 1.4) * u.vignette;
    col *= v;

    __nv_out = float4(clamp(col, 0.0, 1.0), c.a);
    return __nv_out;
}
