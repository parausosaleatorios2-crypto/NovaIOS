// ---------------------------------------------------------------------------
// VHS (Blurrr)
// origem : assets/effects/nv-blurrr-vhs.xml
// id     : nova.effect.blurrr.vhs
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_vhsParams {
    float bleed;
    float chroma;
    float lines;
    float rollSpeed;
    float jitter;
};

// --- funcoes auxiliares do efeito
float hash(float2 p) { return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453); }

fragment float4 fx_nv_blurrr_vhs(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_vhsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float linha = floor(in.acScreenNorm.y * u.lines);
    float j = (hash(float2(linha, floor(eng.acTime * 30.0))) - 0.5) * 2.0 * u.jitter;
    float2 uv = in.acScreenNorm + float2(j, 0.0);

    // sangria horizontal: média de várias amostras laterais
    float3 bl = float3(0.0);
    for (int i = -4; i <= 4; i++) {
        float w = 1.0 - abs(float(i)) / 4.0;
        bl += inputImg.sample(__nv_smp, uv + float2(float(i) * u.bleed * 0.25, 0.0)).rgb * w;
    }
    bl /= 5.0;

    // separação RG / B
    float r = inputImg.sample(__nv_smp, uv + float2(u.chroma, 0.0)).r;
    float g = bl.g;
    float b = inputImg.sample(__nv_smp, uv - float2(u.chroma, 0.0)).b;

    // linhas rolando
    float roll = 0.5 + 0.5 * sin(in.acScreenNorm.y * u.lines * 0.5 + eng.acTime * u.rollSpeed * 10.0);
    float3 cor = float3(r, g, b) * mix(0.85, 1.15, roll);

    float a = inputImg.sample(__nv_smp, uv).a;
    __nv_out = float4(cor, a);
    return __nv_out;
}
