// ---------------------------------------------------------------------------
// Camera Quad (NV)
// origem : assets/effects/nv-nodevideo-camera-quad.xml
// id     : nv.effect.nodevideo-camera-quad
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_camera_quadParams {
    float _opacity;
    float _alpha_clip;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float u_xlat1;
bool u_xlatb1;

fragment float4 fx_nv_nodevideo_camera_quad(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_camera_quadParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1 = u_xlat0.w * u._opacity + (-u._alpha_clip);
    u_xlatb1 = u_xlat1<0.0;
    if(u_xlatb1){discard_fragment();}
    u_xlat0.w = u_xlat0.w * u._opacity;
    __nv_out = u_xlat0;
    return __nv_out;
    return __nv_out;
}
