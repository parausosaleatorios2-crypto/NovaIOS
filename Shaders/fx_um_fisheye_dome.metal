// ---------------------------------------------------------------------------
// Olho de Peixe Domo (Ultra Motion)
// origem : assets/effects/um-fisheye-dome.xml
// id     : nova.effect.ultramotion.fisheyedome
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_fisheye_domeParams {
    float fov;
    float zoom;
    int black;
};

fragment float4 fx_um_fisheye_dome(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_fisheye_domeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // o alfa da camada manda: "fora = preto" pinta de preto, nao inventa opacidade
    float aOrig = inputImg.sample(__nv_smp, in.acScreenNorm).a;
    float2 p = (in.acScreenNorm - 0.5) * 2.0;
    p.x *= eng.acAspect;
    float r = length(p);
    if (r > 1.0) {
        if (u.black) { __nv_out = float4(0.0, 0.0, 0.0, aOrig); return __nv_out; }
        else { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); return __nv_out; }
    }
    float theta = r * u.fov;
    float2 dir = (r > 1e-5) ? p / r : float2(0.0);
    float2 q = dir * tan(theta) / u.zoom;
    q.x /= eng.acAspect;
    q = q * 0.5 + 0.5;
    if (q.x < 0.0 || q.x > 1.0 || q.y < 0.0 || q.y > 1.0) {
        if (u.black) { __nv_out = float4(0.0, 0.0, 0.0, aOrig); return __nv_out; }
    }
    __nv_out = inputImg.sample(__nv_smp, clamp(q, 0.0, 1.0));
    return __nv_out;
}
