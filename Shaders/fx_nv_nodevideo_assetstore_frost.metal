// ---------------------------------------------------------------------------
// Frost (NV)
// origem : assets/effects/nv-nodevideo-assetstore-frost.xml
// id     : nv.effect.nodevideo-assetstore-frost
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_frostParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _color;
    float _strength;
    float _colorize;
    float _direction;
    float2 _scale;
    float _keep_edge;
};

// --- funcoes auxiliares do efeito
float3 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat9;
float u_xlat12;
bool2 u_xlatb12;
float2 u_xlat14;
bool2 u_xlatb14;
float u_xlat18;

fragment float4 fx_nv_nodevideo_assetstore_frost(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_frostParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat12 = u._direction * -0.0174532942;
    u_xlat1.x = sin(u_xlat12);
    u_xlat2.x = cos(u_xlat12);
    u_xlat3.x = sin((-u_xlat12));
    u_xlat3.y = u_xlat2.x;
    u_xlat2.x = dot(u_xlat3.yx, u_xlat0.xy);
    u_xlat3.z = u_xlat1.x;
    u_xlat2.y = dot(u_xlat3.zy, u_xlat0.xy);
    u_xlat0.xy = u_xlat2.xy * u._scale.xy + float2(0.5, 0.5);
    u_xlat0.xyz = texture0.sample(__nv_smp, u_xlat0.xy).xyz;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat2 = u_xlat0.xxzz * float4(0.0500000007, 0.0500000007, 0.0500000007, 0.0500000007) + in.acScreenNorm.xyxy;
    u_xlat12 = dot(u_xlat2.xy, float2(92.0, 80.0));
    u_xlat18 = dot(u_xlat2.xy, float2(41.0, 62.0));
    u_xlat12 = sin(u_xlat12);
    u_xlat18 = cos(u_xlat18);
    u_xlat12 = u_xlat18 * 51.0 + u_xlat12;
    u_xlat2.x = fract(u_xlat12);
    u_xlat12 = dot(u_xlat2.zw, float2(92.0, 80.0));
    u_xlat18 = dot(u_xlat2.zw, float2(41.0, 62.0));
    u_xlat12 = sin(u_xlat12);
    u_xlat18 = cos(u_xlat18);
    u_xlat12 = u_xlat18 * 51.0 + u_xlat12;
    u_xlat2.y = fract(u_xlat12);
    u_xlat0.xy = u_xlat0.xy * float2(u._strength);
    u_xlat0.xy = u_xlat2.xy * u_xlat0.xy;
    u_xlat0.z = u._direction + 125.0;
    u_xlat0.xyz = u_xlat0.xyz * float3(0.100000001, 0.100000001, 0.0174532942);
    u_xlat2.x = sin(u_xlat0.z);
    u_xlat3.x = cos(u_xlat0.z);
    u_xlat4.x = sin((-u_xlat0.z));
    u_xlat4.y = u_xlat3.x;
    u_xlat3.x = dot(u_xlat4.yx, u_xlat0.xy);
    u_xlat4.z = u_xlat2.x;
    u_xlat3.y = dot(u_xlat4.zy, u_xlat0.xy);
    u_xlat0.xy = u_xlat3.xy + in.acScreenNorm.xy;
    u_xlatb12.x = int(u._keep_edge)==1;
    u_xlatb2.xy = lessThan(u_xlat0.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb14.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat0.xyxy).xy;
    u_xlat9.xy = fract(u_xlat0.xy);
    u_xlat9.xy = (-u_xlat9.xy) + float2(1.0, 1.0);
    u_xlat14.x = (u_xlatb14.x) ? u_xlat9.x : u_xlat0.x;
    u_xlat14.y = (u_xlatb14.y) ? u_xlat9.y : u_xlat0.y;
    u_xlat2.x = (u_xlatb2.x) ? (-u_xlat0.x) : u_xlat14.x;
    u_xlat2.y = (u_xlatb2.y) ? (-u_xlat0.y) : u_xlat14.y;
    u_xlat0.xy = (u_xlatb12.x) ? u_xlat2.xy : u_xlat0.xy;
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat0.xy);
    u_xlat12 = abs(u_xlat3.x) * u._colorize;
    u_xlat3.xyz = (-u_xlat2.xyz) + u._color.xyz;
    u_xlat3.w = u_xlat1.w + (-u_xlat2.w);
    u_xlat2 = float4(u_xlat12) * u_xlat3 + u_xlat2;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb12.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._b_clip_mask)), int4(1, 1, 1, 1)).xy;
        u_xlat3 = (u_xlatb12.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat2;
        u_xlat4 = Mask.sample(__nv_smp, u_xlat0.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat0.x = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb12.y) ? u_xlat0.x : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat2;
    }
    return __nv_out;
    return __nv_out;
}
