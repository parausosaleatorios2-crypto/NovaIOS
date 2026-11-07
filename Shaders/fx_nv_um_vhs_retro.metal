// ---------------------------------------------------------------------------
// VHS Retrô
// origem : assets/effects/nv-um-vhs-retro.xml
// id     : nova.effect.um-vhs-retro
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_um_vhs_retroParams {
    float chroma;
    float warp;
    float scanAmount;
    float grain;
    float speed;
};

// --- funcoes auxiliares do efeito
static float hash(float2 p) { return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453); }

fragment float4 fx_nv_um_vhs_retro(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_um_vhs_retroParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float t = eng.acTime * u.speed;

    // u.warp horizontal animado
    float w = sin(uv.y * 80.0 + t * 3.0) * u.warp + sin(uv.y * 12.0 - t) * u.warp * 0.5;
    float2 uvW = float2(uv.x + w, uv.y);

    // u.chroma shift
    float dx = u.chroma / eng.acResolution.x;
    float r = inputImg.sample(__nv_smp, uvW + float2(dx, 0.0)).r;
    float4 g = inputImg.sample(__nv_smp, uvW);
    float b = inputImg.sample(__nv_smp, uvW - float2(dx, 0.0)).b;
    float3 col = float3(r, g.g, b);

    // scanlines
    float sl = 1.0 - u.scanAmount * 0.5 * (0.5 + 0.5 * sin(uv.y * eng.acResolution.y * 3.14159));
    col *= sl;

    // grão
    float n = hash(uv * eng.acResolution + fract(t));
    col += (n - 0.5) * u.grain;

    // leve saturação-queda para vibe de fita
    float L = dot(col, float3(0.2126, 0.7152, 0.0722));
    col = mix(float3(L), col, 0.85);

    __nv_out = float4(clamp(col, 0.0, 1.0), g.a);
    return __nv_out;
}
