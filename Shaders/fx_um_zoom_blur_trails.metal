// ---------------------------------------------------------------------------
// Rastros de Zoom (Ultra Motion)
// origem : assets/effects/um-zoom-blur-trails.xml
// id     : nova.effect.ultramotion.zoomblurtrails
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_zoom_blur_trailsParams {
    float strength;
    float echoes;
    float fade;
    float2 center;
};

fragment float4 fx_um_zoom_blur_trails(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_zoom_blur_trailsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (u.strength <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); return __nv_out; }
    int n = clamp(int(u.echoes), 2, 16);
    float2 p = in.acScreenNorm - u.center;

    float4 soma = float4(0.0);
    float pesoTot = 0.0;
    float w = 1.0;
    for (int i = 0; i <= 16; i++) {
        if (i >= n) break;
        float t = float(i) / float(n);
        float2 u = u.center + p * (1.0 - u.strength * t);
        soma += inputImg.sample(__nv_smp, u) * w;
        pesoTot += w;
        w *= u.fade;
    }
    __nv_out = soma / max(pesoTot, 1e-4);
    return __nv_out;
}
