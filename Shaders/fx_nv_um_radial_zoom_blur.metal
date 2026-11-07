// ---------------------------------------------------------------------------
// Zoom Radial Blur
// origem : assets/effects/nv-um-radial-zoom-blur.xml
// id     : nova.effect.um-radial-zoom-blur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_um_radial_zoom_blurParams {
    float2 center;
    float amount;
    float samples;
};

fragment float4 fx_nv_um_radial_zoom_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_um_radial_zoom_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float2 d = uv - u.center;

    int N = int(u.samples);
    float4 acc = float4(0.0);
    for (int i = 0; i < 48; i++) {
        if (i >= N) break;
        float t = float(i) / float(N - 1);
        float s = mix(1.0, 1.0 - u.amount, t);
        acc += inputImg.sample(__nv_smp, u.center + d * s);
    }
    __nv_out = acc / float(N);
    return __nv_out;
}
