// ---------------------------------------------------------------------------
// Fantasma Duplo (Blurrr)
// origem : assets/effects/nv-blurrr-ghost.xml
// id     : nova.effect.blurrr.ghost
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_ghostParams {
    float offset;
    float angle;
    float mistura;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

fragment float4 fx_nv_blurrr_ghost(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_ghostParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float a = u.angle * PI / 180.0;
    float2 d = float2(cos(a), sin(a)) * u.offset;
    d.x /= max(eng.acAspect, 1e-4);
    float4 o  = inputImg.sample(__nv_smp, in.acScreenNorm);
    float4 l  = inputImg.sample(__nv_smp, in.acScreenNorm - d);
    float4 r  = inputImg.sample(__nv_smp, in.acScreenNorm + d);
    float4 dupla = (l + r) * 0.5;
    __nv_out = mix(o, dupla, u.mistura);
    return __nv_out;
}
