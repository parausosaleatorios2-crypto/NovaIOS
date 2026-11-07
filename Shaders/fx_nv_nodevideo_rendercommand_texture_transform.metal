// ---------------------------------------------------------------------------
// Rendercommand Texture Transform (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-texture-transform.xml
// id     : nv.effect.nodevideo-rendercommand-texture-transform
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_texture_transformParams {
    float2 _tex_offset;
    float _tex_angle;
    float2 _tex_scale;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
bool4 u_xlatb0;
float4 u_xlat1;
float3 u_xlat2;

fragment float4 fx_nv_nodevideo_rendercommand_texture_transform(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_texture_transformParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = u._tex_angle * 0.0174532998;
    u_xlat1.x = cos(u_xlat0.x);
    u_xlat0.x = sin(u_xlat0.x);
    u_xlat2.z = u_xlat0.x;
    u_xlat2.y = u_xlat1.x;
    u_xlat2.x = (-u_xlat0.x);
    u_xlat0.y = dot(in.acScreenNorm.xy, u_xlat2.xy);
    u_xlat0.x = dot(in.acScreenNorm.xy, u_xlat2.yz);
    u_xlat0.xy = u_xlat0.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * u._tex_scale.xy + float2(0.5, 0.5);
    u_xlat0.xy = u_xlat0.xy + (-u._tex_offset.xy);
    u_xlat1 = inputImg.sample(__nv_smp, u_xlat0.xy);
    u_xlatb0.zw = greaterThanEqual(u_xlat0.xxxy, float4(0.0, 0.0, 0.0, 0.0)).zw;
    u_xlat0.xy = (-u_xlat0.xy) + float2(1.0, 1.0);
    u_xlatb0.xy = greaterThanEqual(u_xlat0.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlat0.x = u_xlatb0.x ? float(1.0) : 0.0;
    u_xlat0.y = u_xlatb0.y ? float(1.0) : 0.0;
    u_xlat0.z = u_xlatb0.z ? float(1.0) : 0.0;
    u_xlat0.w = u_xlatb0.w ? float(1.0) : 0.0;
;
    u_xlat1 = u_xlat0.zzzz * u_xlat1;
    u_xlat1 = u_xlat0.xxxx * u_xlat1;
    u_xlat1 = u_xlat0.wwww * u_xlat1;
    __nv_out = u_xlat0.yyyy * u_xlat1;
    return __nv_out;
    return __nv_out;
}
