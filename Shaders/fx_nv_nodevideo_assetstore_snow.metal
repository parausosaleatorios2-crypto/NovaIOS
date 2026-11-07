// ---------------------------------------------------------------------------
// Snow (NV)
// origem : assets/effects/nv-nodevideo-assetstore-snow.xml
// id     : nv.effect.nodevideo-assetstore-snow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_snowParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _size;
    float _amount;
    float _speed;
    float _flicker;
    float _intensity;
    float4 _color;
    float _direction;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat12;
float u_xlat18;

fragment float4 fx_nv_nodevideo_assetstore_snow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_snowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy * float2(_viewport_ratio.x, _viewport_ratio.y) + float2(-0.5, -0.5);
    u_xlat12 = u._direction * -0.0174532942;
    u_xlat1.x = sin(u_xlat12);
    u_xlat2.x = cos(u_xlat12);
    u_xlat3.x = sin((-u_xlat12));
    u_xlat3.y = u_xlat2.x;
    u_xlat2.x = dot(u_xlat3.yx, u_xlat0.xy);
    u_xlat3.z = u_xlat1.x;
    u_xlat2.y = dot(u_xlat3.zy, u_xlat0.xy);
    u_xlat0.xy = float2(u._size, u._amount) * float2(9.5, -49.0) + float2(0.5, 50.0);
    u_xlat0.xz = u_xlat2.xy / u_xlat0.xx;
    u_xlat0.xz = u_xlat0.xz + float2(0.5, 0.5);
    u_xlat1 = float4(float4(_cur_time, _cur_time, _cur_time, _cur_time)) * float4(u._speed, u._speed, u._flicker, u._flicker);
    u_xlat2.xyz = u_xlat1.xzw * float3(0.100000001, -0.00300000003, 0.00200000009);
    u_xlat18 = sin(u_xlat2.x);
    u_xlat3.y = (-u_xlat18) * 0.5 + u_xlat0.x;
    u_xlat3.zw = u_xlat1.xy * float2(0.100000001, 0.0714285746) + u_xlat0.zz;
    u_xlat3.x = u_xlat18 * 0.111111112 + u_xlat0.x;
    u_xlat1 = u_xlat3.yzxw * float4(0.600000024, 0.600000024, 0.899999976, 0.899999976) + u_xlat2.yyzz;
    u_xlat0.x = texture0.sample(__nv_smp, u_xlat1.xy).x;
    u_xlat12 = texture0.sample(__nv_smp, u_xlat1.zw).z;
    u_xlat0.x = u_xlat12 * u_xlat0.x;
    u_xlat0.x = log2(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * u_xlat0.y;
    u_xlat0.x = exp2(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * u._intensity;
    u_xlat0.x = u_xlat0.x * 18.0;
    u_xlat0.xyz = u_xlat0.xxx * u._color.xyz;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0.w = 1.0;
    u_xlat0 = u_xlat0 + u_xlat1;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat2.x = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
