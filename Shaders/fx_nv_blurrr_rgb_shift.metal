// ---------------------------------------------------------------------------
// Separação RGB (Blurrr)
// origem : assets/effects/nv-blurrr-rgb-shift.xml
// id     : nova.effect.blurrr.rgbshift
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_rgb_shiftParams {
    float amount;
    float angle;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

fragment float4 fx_nv_blurrr_rgb_shift(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_rgb_shiftParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float a = u.angle * PI / 180.0;
    float2 d = float2(cos(a), sin(a)) * u.amount;
    d.x /= max(eng.acAspect, 1e-4);
    float r = inputImg.sample(__nv_smp, in.acScreenNorm + d).r;
    float g = inputImg.sample(__nv_smp, in.acScreenNorm).g;
    float b = inputImg.sample(__nv_smp, in.acScreenNorm - d).b;
    float al = inputImg.sample(__nv_smp, in.acScreenNorm).a;
    __nv_out = float4(r, g, b, al);
    return __nv_out;
}
