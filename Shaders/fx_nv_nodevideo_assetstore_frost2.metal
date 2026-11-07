// ---------------------------------------------------------------------------
// Frost2 (NV)
// origem : assets/effects/nv-nodevideo-assetstore-frost2.xml
// id     : nv.effect.nodevideo-assetstore-frost2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_frost2Params {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _color;
    float _refraction;
    float _spread;
    float _transparency;
    float _smoothness;
    float _direction;
    float2 _scale;
    float2 _offset;
    float _type;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float2 u_xlat12;
float u_xlat18;
float u_xlat19;
float u_xlat20;

fragment float4 fx_nv_nodevideo_assetstore_frost2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_frost2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]],
    texture2d<float> texture1 [[texture(2)]],
    texture2d<float> texture2 [[texture(3)]],
    texture2d<float> texture3 [[texture(4)]],
    texture2d<float> texture4 [[texture(5)]],
    texture2d<float> texture5 [[texture(6)]],
    texture2d<float> Mask [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat12.x = (-u._direction) + 180.0;
    u_xlat12.x = u_xlat12.x * 0.0174532942;
    u_xlat1.x = sin(u_xlat12.x);
    u_xlat2.x = cos(u_xlat12.x);
    u_xlat3.x = sin((-u_xlat12.x));
    u_xlat3.y = u_xlat2.x;
    u_xlat2.x = dot(u_xlat3.yx, u_xlat0.xy);
    u_xlat3.z = u_xlat1.x;
    u_xlat2.y = dot(u_xlat3.zy, u_xlat0.xy);
    u_xlat0.xy = u_xlat2.xy * float2(u._scale.x, u._scale.y) + float2(0.5, 0.5);
    u_xlat0.xy = (int(u._type) != 0) ? in.acScreenNorm.xy : u_xlat0.xy;
    u_xlat1.xyz = u._color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u._color.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat1.xyz = u_xlat1.xyz * u._color.xyz;
    u_xlat12.xy = u_xlat0.xy + float2(-0.5, -0.5);
    u_xlat12.xy = u_xlat12.xy * float2(u._scale.x, u._scale.y) + float2(0.5, 0.5);
    u_xlat12.xy = u_xlat12.xy + (-u._offset.xy);
    u_xlat2 = texture0.sample(__nv_smp, u_xlat12.xy);
    u_xlat12.xy = texture1.sample(__nv_smp, u_xlat12.xy).xy;
    u_xlat12.xy = u_xlat12.xy * float2(2.0, 2.0) + float2(-1.0, -1.0);
    u_xlat19 = (-u_xlat2.w) * u._transparency + 1.0;
    if(int(u._type) == 0) {
        u_xlat20 = texture2.sample(__nv_smp, u_xlat0.xy).x;
    } else {
        u_xlatb3 = int(u._type)==1;
        if(u_xlatb3){
            u_xlat20 = texture3.sample(__nv_smp, u_xlat0.xy).x;
        } else {
            u_xlatb3 = int(u._type)==2;
            if(u_xlatb3){
                u_xlat20 = texture4.sample(__nv_smp, u_xlat0.xy).x;
            } else {
                u_xlat20 = texture5.sample(__nv_smp, u_xlat0.xy).x;
            }
        }
    }
    u_xlat0.x = u_xlat19 * u._spread;
    u_xlat0.x = u_xlat0.x * -2.0 + 1.0;
    u_xlat0.x = (-u_xlat0.x) + u_xlat20;
    u_xlat0.x = u_xlat0.x / u._smoothness;
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat6.xy = u_xlat12.xy * float2(u._refraction);
    u_xlat6.xy = u_xlat6.xy * u_xlat0.xx + in.acScreenNorm.xy;
    u_xlat6.xyz = inputImg.sample(__nv_smp, u_xlat6.xy).xyz;
    u_xlat3.xyz = (-u_xlat6.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat4.xyz = (-u_xlat2.xyz) * u_xlat1.xyz + float3(1.0, 1.0, 1.0);
    u_xlat3.xyz = (-u_xlat3.xyz) * u_xlat4.xyz + float3(1.0, 1.0, 1.0);
    u_xlat1.xyz = u_xlat2.xyz * u_xlat1.xyz + (-u_xlat3.xyz);
    u_xlat1.xyz = u._color.www * u_xlat1.xyz + u_xlat3.xyz;
    u_xlat1.xyz = (-u_xlat6.xyz) + u_xlat1.xyz;
    u_xlat0.xyz = u_xlat0.xxx * u_xlat1.xyz + u_xlat6.xyz;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat0.w = u_xlat1.w;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat5 = u_xlat1 * u_xlat5;
        u_xlat3 = u_xlat3 * u_xlat4 + u_xlat5;
        u_xlat18 = u_xlat4.x * u_xlat3.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat18 : u_xlat3.w;
        __nv_out.xyz = u_xlat3.xyz;
    } else {
        __nv_out.xyz = u_xlat0.xyz;
        __nv_out.w = u_xlat1.w;
    }
    return __nv_out;
    return __nv_out;
}
