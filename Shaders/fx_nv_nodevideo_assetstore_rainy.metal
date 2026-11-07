// ---------------------------------------------------------------------------
// Rainy (NV)
// origem : assets/effects/nv-nodevideo-assetstore-rainy.xml
// id     : nv.effect.nodevideo-assetstore-rainy
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_rainyParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _blend;
    float _intensity;
    float _direction;
    float _speed;
    float _scale;
    float _distortion;
    float _flash;
    float _drops;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat6;
float u_xlat12;
float u_xlat18;

fragment float4 fx_nv_nodevideo_assetstore_rainy(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_rainyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy * float2(u._scale);
    u_xlat12 = _cur_time * u._speed;
    u_xlat0.x = u._direction * u_xlat0.y + u_xlat0.x;
    u_xlat18 = u._intensity * 0.25;
    u_xlat1.x = u_xlat0.x * 3.0 + 0.100000001;
    u_xlat2 = float4(u_xlat12) * float4(0.800000012, 0.00999999978, 1.20000005, 0.200000003);
    u_xlat1.y = u_xlat0.y * 3.0 + u_xlat2.x;
    u_xlat0.x = texture0.sample(__nv_smp, u_xlat1.xy).x;
    u_xlat0.x = u_xlat18 * u_xlat0.x;
    u_xlat3.x = u_xlat1.x * 0.649999976 + 0.100000001;
    u_xlat3.y = u_xlat1.y * 0.649999976 + u_xlat12;
    u_xlat6.x = texture0.sample(__nv_smp, u_xlat3.xy).x;
    u_xlat6.x = u_xlat18 * u_xlat6.x;
    u_xlat6.x = u_xlat6.x * 0.5;
    u_xlat0.x = u_xlat0.x * 0.300000012 + u_xlat6.x;
    u_xlat1.x = u_xlat3.x * 0.649999976 + 0.100000001;
    u_xlat1.y = u_xlat3.y * 0.649999976 + u_xlat2.z;
    u_xlat6.x = texture0.sample(__nv_smp, u_xlat1.xy).x;
    u_xlat6.x = u_xlat18 * u_xlat6.x;
    u_xlat0.x = u_xlat6.x * 0.699999988 + u_xlat0.x;
    u_xlat3.x = u_xlat1.x * 0.5 + 0.100000001;
    u_xlat3.y = u_xlat1.y * 0.5 + u_xlat2.z;
    u_xlat6.x = texture0.sample(__nv_smp, u_xlat3.xy).x;
    u_xlat6.x = u_xlat18 * u_xlat6.x;
    u_xlat0.x = u_xlat6.x * 0.899999976 + u_xlat0.x;
    u_xlat1.x = u_xlat3.x * 0.400000006 + 0.100000001;
    u_xlat1.y = u_xlat3.y * 0.400000006 + u_xlat2.z;
    u_xlat6.x = texture0.sample(__nv_smp, u_xlat1.xy).x;
    u_xlat6.x = u_xlat18 * u_xlat6.x;
    u_xlat0.x = u_xlat6.x * 0.899999976 + u_xlat0.x;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat3.xy = u_xlat0.xx * float2(float2(u._distortion, u._distortion)) + in.acScreenNorm.xy;
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.xy);
    u_xlat3 = u_xlat0.xxxx + u_xlat3;
    u_xlat3 = (-u_xlat1) + u_xlat3;
    u_xlat3 = float4(u._blend) * u_xlat3 + u_xlat1;
    u_xlat2.x = in.acScreenNorm.x * 0.00100000005 + u_xlat2.w;
    u_xlat0.x = texture0.sample(__nv_smp, u_xlat2.xy).y;
    u_xlat0.x = u_xlat18 * u_xlat0.x;
    u_xlat0.x = dot(u_xlat0.xx, float2(float2(u._flash, u._flash)));
    u_xlat2 = u_xlat0.xxxx + u_xlat3;
    u_xlat0.x = u_xlat12 * 32.0;
    u_xlat0.x = floor(u_xlat0.x);
    u_xlat6.x = u_xlat0.x * 0.0625;
    u_xlat6.x = in.acScreenNorm.x * 2.0 + u_xlat6.x;
    u_xlat0.x = u_xlat0.x * 0.055555556 + in.acScreenNorm.y;
    u_xlat18 = u_xlat12 * u._direction;
    u_xlat3.x = (-u_xlat18) * 0.550000012 + u_xlat6.x;
    u_xlat3.y = u_xlat12 * 0.150000006 + u_xlat0.x;
    u_xlat0.x = texture0.sample(__nv_smp, u_xlat3.xy).z;
    u_xlat3 = in.acScreenNorm.xyxy * _resolution.xyxy + float4(3.0, 3.0, 3.0, -3.0);
    u_xlat3 = u_xlat3 / _resolution.xyxy;
    u_xlat4 = inputImg.sample(__nv_smp, u_xlat3.xy);
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.zw);
    u_xlat3 = (-u_xlat3) + u_xlat4;
    u_xlat6.xy = in.acScreenNorm.xy * _resolution.xy + float2(-3.0, 3.0);
    u_xlat6.xy = u_xlat6.xy / _resolution.xy;
    u_xlat5 = inputImg.sample(__nv_smp, u_xlat6.xy);
    u_xlat4 = u_xlat4 + (-u_xlat5);
    u_xlat3 = abs(u_xlat3) + abs(u_xlat4);
    u_xlat3 = u_xlat3 * float4(0.5, 0.5, 0.5, 0.5);
    u_xlat6.x = dot(u_xlat3, u_xlat3);
    u_xlat6.x = sqrt(u_xlat6.x);
    u_xlat0.x = u_xlat0.x * u_xlat6.x;
    u_xlat0 = float4(float4(u._drops, u._drops, u._drops, u._drops)) * u_xlat0.xxxx + u_xlat2;
    u_xlat0 = (-u_xlat1) + u_xlat0;
    u_xlat0 = float4(u._blend) * u_xlat0 + u_xlat1;
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
