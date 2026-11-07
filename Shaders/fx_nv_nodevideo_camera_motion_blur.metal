// ---------------------------------------------------------------------------
// Camera Motion Blur (NV)
// origem : assets/effects/nv-nodevideo-camera-motion-blur.xml
// id     : nv.effect.nodevideo-camera-motion-blur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_camera_motion_blurParams {
    float4 unity_OrthoParams;
    float4 _ZBufferParams;
    float4 _CameraMotionVectorsTexture_TexelSize;
    float _VelocityScale;
    float _RcpMaxBlurRadius;
};

// --- funcoes auxiliares do efeito
float2 u_xlat0;
float u_xlat1;
float2 u_xlat2;

fragment float4 fx_nv_nodevideo_camera_motion_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_camera_motion_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> CameraDepthTexture [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = u._VelocityScale * 0.5;
    u_xlat0.xy = u_xlat0.xx * u._CameraMotionVectorsTexture_TexelSize.zw;
    u_xlat2.xy = inputImg.sample(__nv_smp, in.acScreenNorm.xy).xy;
    u_xlat0.xy = u_xlat0.xy * u_xlat2.xy;
    u_xlat2.x = dot(u_xlat0.xy, u_xlat0.xy);
    u_xlat2.x = sqrt(u_xlat2.x);
    u_xlat2.x = u_xlat2.x * u._RcpMaxBlurRadius;
    u_xlat2.x = max(u_xlat2.x, 1.0);
    u_xlat0.xy = u_xlat0.xy / u_xlat2.xx;
    u_xlat0.xy = u_xlat0.xy * float2(float2(u._RcpMaxBlurRadius, u._RcpMaxBlurRadius)) + float2(1.0, 1.0);
    __nv_out.xy = u_xlat0.xy * float2(0.5, 0.5);
    u_xlat0.x = (-u.unity_OrthoParams.w) + 1.0;
    u_xlat1 = CameraDepthTexture.sample(__nv_smp, in.acScreenNorm.xy).x;
    u_xlat1 = u_xlat1 * u._ZBufferParams.x;
    u_xlat0.x = u_xlat0.x * u_xlat1 + u._ZBufferParams.y;
    u_xlat1 = (-u.unity_OrthoParams.w) * u_xlat1 + 1.0;
    __nv_out.z = u_xlat1 / u_xlat0.x;
    __nv_out.w = 0.0;
    return __nv_out;
    return __nv_out;
}
