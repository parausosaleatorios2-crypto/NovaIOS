// ---------------------------------------------------------------------------
// Camera Render Motion Vector (NV)
// origem : assets/effects/nv-nodevideo-camera-render-motion-vector.xml
// id     : nv.effect.nodevideo-camera-render-motion-vector
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_camera_render_motion_vectorParams { int __vazio; };

// --- funcoes auxiliares do efeito
float2 u_xlat0;
float2 u_xlat2;

fragment float4 fx_nv_nodevideo_camera_render_motion_vector(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_camera_render_motion_vectorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.vs_TEXCOORD1.xy / in.vs_TEXCOORD1.ww;
    u_xlat0.xy = u_xlat0.xy + float2(1.0, 1.0);
    u_xlat0.xy = u_xlat0.xy * float2(0.5, 0.5);
    u_xlat2.xy = in.acScreenNorm.xy / in.acScreenNorm.ww;
    u_xlat2.xy = u_xlat2.xy + float2(1.0, 1.0);
    u_xlat0.xy = u_xlat2.xy * float2(0.5, 0.5) + (-u_xlat0.xy);
    __nv_out.xy = abs(u_xlat0.xy);
    __nv_out.zw = float2(0.0, 1.0);
    return __nv_out;
    return __nv_out;
}
