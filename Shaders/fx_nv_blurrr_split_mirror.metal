// ---------------------------------------------------------------------------
// Espelho Dividido (Blurrr)
// origem : assets/effects/nv-blurrr-split-mirror.xml
// id     : nova.effect.blurrr.splitmirror
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_split_mirrorParams {
    float axis;
    float split;
    float softness;
    float flip;
};

fragment float4 fx_nv_blurrr_split_mirror(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_split_mirrorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float c = (int(u.axis) == 0) ? uv.x : uv.y;
    float lado = step(u.split, c);
    float2 other = uv;
    if (int(u.axis) == 0) other.x = (int(u.flip) == 1) ? (2.0 * u.split - uv.x) : uv.x;
    else                other.y = (int(u.flip) == 1) ? (2.0 * u.split - uv.y) : uv.y;

    float k = smoothstep(u.split - u.softness, u.split + u.softness, c);
    float4 esq = inputImg.sample(__nv_smp, other);
    float4 dir = inputImg.sample(__nv_smp, uv);
    __nv_out = mix(esq, dir, k);
    return __nv_out;
}
