// ---------------------------------------------------------------------------
// Fill Assetstore Ice Caustics (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-ice-caustics.xml
// id     : nv.effect.nodevideo-fill-assetstore-ice-caustics
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_ice_causticsParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _evolution;
    float _blend_mode;
    float2 _scale;
    float2 _offset;
    float _angle;
    float _intensity;
    float4 _color1;
    float4 _color2;
    float _speed;
    float _gradient;
    float _iteration;
    float _phase;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
int u_xlati2;
float4 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
float4 u_xlat6;
float4 u_xlat7;
float u_xlat9;
float2 u_xlat10;
int u_xlati10;
bool u_xlatb10;
float2 u_xlat16;
float2 u_xlat17;
float2 u_xlat18;
int u_xlati18;
bool u_xlatb18;
float2 u_xlat19;
float2 u_xlat20;
float2 u_xlat21;
bool u_xlatb21;
float2 u_xlat22;
float u_xlat24;
float u_xlat25;
float u_xlat26;
bool u_xlatb26;
int u_xlati28;
float u_xlat29;
float u_xlat30;

fragment float4 fx_nv_nodevideo_fill_assetstore_ice_caustics(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_ice_causticsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = in.acScreenNorm.xyxy * _resolution.xyxy;
    u_xlat0 = u_xlat0 * float4(2.0, 2.0, 2.0, 2.0) + (-_resolution.xyxy);
    u_xlat1.x = min(_resolution.y, _resolution.x);
    u_xlat0 = u_xlat0 / u_xlat1.xxxx;
    u_xlat1 = u_xlat0 * float4(0.5, 0.5, 0.100000001, 0.100000001);
    u_xlat16.xy = u_xlat1.zw;
    u_xlat2.x = float(0.0);
    for(int u_xlati_loop_1 = int(0) ; u_xlati_loop_1<3 ; u_xlati_loop_1++)
    {
        u_xlat18.x = dot(u_xlat16.xy, u_xlat16.xy);
        u_xlat2.x = sqrt(u_xlat18.x);
        u_xlat18.x = u_xlat16.y + u._gradient;
        u_xlat18.x = u_xlat18.x + 0.850000024;
        u_xlat18.x = sin(u_xlat18.x);
        u_xlat16.x = u_xlat18.x * 2.0999999 + u_xlat16.x;
        u_xlat18.x = u_xlat16.x + u._gradient;
        u_xlat18.x = u_xlat18.x + 0.850000024;
        u_xlat26 = cos(u_xlat2.x);
        u_xlat18.x = u_xlat26 + u_xlat18.x;
        u_xlat18.x = cos(u_xlat18.x);
        u_xlat16.y = u_xlat16.y + u_xlat18.x;
    }
    u_xlat16.x = u_xlat2.x + -3.0;
    u_xlat24 = u._angle * -0.0174532942;
    u_xlat2.x = sin(u_xlat24);
    u_xlat3.x = cos(u_xlat24);
    u_xlat4.x = sin((-u_xlat24));
    u_xlat4.y = u_xlat3.x;
    u_xlat24 = dot(u_xlat4.yx, float2(1.0, 1.0));
    u_xlat0.w = u_xlat24 * u._evolution;
    u_xlat4.zw = u_xlat2.xx;
    u_xlat17.xy = u_xlat1.xy;
    u_xlat3.x = u_xlat0.w;
    u_xlat10.x = float(0.100000001);
    for(int u_xlati_loop_2 = int(0) ; u_xlati_loop_2<int(u._iteration) ; u_xlati_loop_2++)
    {
        u_xlat19.xy = floor(u_xlat17.xy);
        u_xlat5.xy = fract(u_xlat17.xy);
        u_xlat5.xy = u_xlat5.xy * float2(10.0, 3.33333325);
        u_xlat5.xy = min(u_xlat5.xy, float2(1.0, 1.0));
        u_xlat21.xy = u_xlat5.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
        u_xlat5.xy = u_xlat5.xy * u_xlat5.xy;
        u_xlat5.xy = u_xlat5.xy * u_xlat21.xy;
        u_xlat26 = dot(u_xlat19.xy, float2(-0.819999993, -0.839999974));
        u_xlat26 = sin(u_xlat26);
        u_xlat26 = u_xlat26 * 4757.15283;
        u_xlat26 = fract(u_xlat26);
        u_xlat6 = u_xlat19.xyxy + float4(1.0, 0.0, 0.0, 1.0);
        u_xlat21.x = dot(u_xlat6.xy, float2(-0.819999993, -0.839999974));
        u_xlat21.x = sin(u_xlat21.x);
        u_xlat21.x = u_xlat21.x * 4757.15283;
        u_xlat21.x = fract(u_xlat21.x);
        u_xlat21.x = (-u_xlat26) + u_xlat21.x;
        u_xlat26 = u_xlat5.x * u_xlat21.x + u_xlat26;
        u_xlat21.x = dot(u_xlat6.zw, float2(-0.819999993, -0.839999974));
        u_xlat21.x = sin(u_xlat21.x);
        u_xlat21.x = u_xlat21.x * 4757.15283;
        u_xlat21.x = fract(u_xlat21.x);
        u_xlat19.xy = u_xlat19.xy + float2(1.0, 1.0);
        u_xlat19.x = dot(u_xlat19.xy, float2(-0.819999993, -0.839999974));
        u_xlat19.x = sin(u_xlat19.x);
        u_xlat19.x = u_xlat19.x * 4757.15283;
        u_xlat19.x = fract(u_xlat19.x);
        u_xlat19.x = (-u_xlat21.x) + u_xlat19.x;
        u_xlat19.x = u_xlat5.x * u_xlat19.x + u_xlat21.x;
        u_xlat19.x = (-u_xlat26) + u_xlat19.x;
        u_xlat26 = u_xlat5.y * u_xlat19.x + u_xlat26;
        u_xlat3.x = u_xlat10.x * u_xlat26 + u_xlat3.x;
        u_xlat5.x = dot(u_xlat4.yx, u_xlat17.xy);
        u_xlat5.y = dot(u_xlat4.zy, u_xlat17.xy);
        u_xlat17.xy = u_xlat5.xy * float2(u._scale.x, u._scale.y) + u._offset.xy;
        u_xlat10.x = u_xlat10.x * u._intensity;
    }
    u_xlat1.xy = u_xlat0.xy * float2(0.5, 0.5) + float2(-0.449999988, 0.649999976);
    u_xlat17.xy = u_xlat1.xy;
    u_xlat3.y = u_xlat0.w;
    u_xlat10.x = float(0.100000001);
    for(int u_xlati_loop_3 = int(0) ; u_xlati_loop_3<int(u._iteration) ; u_xlati_loop_3++)
    {
        u_xlat19.xy = floor(u_xlat17.xy);
        u_xlat5.xy = fract(u_xlat17.xy);
        u_xlat5.xy = u_xlat5.xy * float2(10.0, 3.33333325);
        u_xlat5.xy = min(u_xlat5.xy, float2(1.0, 1.0));
        u_xlat21.xy = u_xlat5.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
        u_xlat5.xy = u_xlat5.xy * u_xlat5.xy;
        u_xlat5.xy = u_xlat5.xy * u_xlat21.xy;
        u_xlat26 = dot(u_xlat19.xy, float2(-0.819999993, -0.839999974));
        u_xlat26 = sin(u_xlat26);
        u_xlat26 = u_xlat26 * 4757.15283;
        u_xlat26 = fract(u_xlat26);
        u_xlat6 = u_xlat19.xyxy + float4(1.0, 0.0, 0.0, 1.0);
        u_xlat20.x = dot(u_xlat6.xy, float2(-0.819999993, -0.839999974));
        u_xlat20.x = sin(u_xlat20.x);
        u_xlat20.x = u_xlat20.x * 4757.15283;
        u_xlat20.x = fract(u_xlat20.x);
        u_xlat20.x = (-u_xlat26) + u_xlat20.x;
        u_xlat26 = u_xlat5.x * u_xlat20.x + u_xlat26;
        u_xlat20.x = dot(u_xlat6.zw, float2(-0.819999993, -0.839999974));
        u_xlat20.x = sin(u_xlat20.x);
        u_xlat20.x = u_xlat20.x * 4757.15283;
        u_xlat20.x = fract(u_xlat20.x);
        u_xlat19.xy = u_xlat19.xy + float2(1.0, 1.0);
        u_xlat19.x = dot(u_xlat19.xy, float2(-0.819999993, -0.839999974));
        u_xlat19.x = sin(u_xlat19.x);
        u_xlat19.x = u_xlat19.x * 4757.15283;
        u_xlat19.x = fract(u_xlat19.x);
        u_xlat19.x = (-u_xlat20.x) + u_xlat19.x;
        u_xlat19.x = u_xlat5.x * u_xlat19.x + u_xlat20.x;
        u_xlat19.x = (-u_xlat26) + u_xlat19.x;
        u_xlat26 = u_xlat5.y * u_xlat19.x + u_xlat26;
        u_xlat3.y = u_xlat10.x * u_xlat26 + u_xlat3.y;
        u_xlat5.x = dot(u_xlat4.yx, u_xlat17.xy);
        u_xlat5.y = dot(u_xlat4.wy, u_xlat17.xy);
        u_xlat17.xy = u_xlat5.xy * float2(u._scale.x, u._scale.y) + u._offset.xy;
        u_xlat10.x = u_xlat10.x * u._intensity;
    }
    u_xlat1.x = _cur_time * u._speed;
    u_xlat1.x = u_xlat1.x * 0.100000001;
    u_xlat9 = u._phase * 6.28318548;
    u_xlat17.x = sin((-u_xlat9));
    u_xlat9 = cos(u_xlat9);
    u_xlat10.xy = u_xlat0.xy * float2(0.5, 0.5) + u_xlat3.xy;
    u_xlat17.xy = u_xlat17.xx * u_xlat1.xx + u_xlat10.xy;
    u_xlat3.xz = u_xlat2.xx;
    u_xlat3.yw = u_xlat4.yy;
    u_xlat2.xw = u_xlat17.xy;
    u_xlat5.x = u_xlat0.w;
    u_xlat20.x = float(0.100000001);
    for(int u_xlati_loop_4 = int(0) ; u_xlati_loop_4<int(u._iteration) ; u_xlati_loop_4++)
    {
        u_xlat21.xy = floor(u_xlat2.xw);
        u_xlat6.xy = fract(u_xlat2.xw);
        u_xlat6.xy = u_xlat6.xy * float2(10.0, 3.33333325);
        u_xlat6.xy = min(u_xlat6.xy, float2(1.0, 1.0));
        u_xlat22.xy = u_xlat6.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
        u_xlat6.xy = u_xlat6.xy * u_xlat6.xy;
        u_xlat6.xy = u_xlat6.xy * u_xlat22.xy;
        u_xlat22.x = dot(u_xlat21.xy, float2(-0.819999993, -0.839999974));
        u_xlat22.x = sin(u_xlat22.x);
        u_xlat22.x = u_xlat22.x * 4757.15283;
        u_xlat7 = u_xlat21.xyxy + float4(1.0, 0.0, 0.0, 1.0);
        u_xlat30 = dot(u_xlat7.xy, float2(-0.819999993, -0.839999974));
        u_xlat30 = sin(u_xlat30);
        u_xlat22.y = u_xlat30 * 4757.15283;
        u_xlat22.xy = fract(u_xlat22.xy);
        u_xlat30 = (-u_xlat22.x) + u_xlat22.y;
        u_xlat22.x = u_xlat6.x * u_xlat30 + u_xlat22.x;
        u_xlat30 = dot(u_xlat7.zw, float2(-0.819999993, -0.839999974));
        u_xlat30 = sin(u_xlat30);
        u_xlat30 = u_xlat30 * 4757.15283;
        u_xlat30 = fract(u_xlat30);
        u_xlat21.xy = u_xlat21.xy + float2(1.0, 1.0);
        u_xlat21.x = dot(u_xlat21.xy, float2(-0.819999993, -0.839999974));
        u_xlat21.x = sin(u_xlat21.x);
        u_xlat21.x = u_xlat21.x * 4757.15283;
        u_xlat21.x = fract(u_xlat21.x);
        u_xlat21.x = (-u_xlat30) + u_xlat21.x;
        u_xlat21.x = u_xlat6.x * u_xlat21.x + u_xlat30;
        u_xlat21.x = (-u_xlat22.x) + u_xlat21.x;
        u_xlat21.x = u_xlat6.y * u_xlat21.x + u_xlat22.x;
        u_xlat5.x = u_xlat20.x * u_xlat21.x + u_xlat5.x;
        u_xlat6.x = dot(u_xlat4.yx, u_xlat2.xw);
        u_xlat6.y = dot(u_xlat3.xy, u_xlat2.xw);
        u_xlat2.xw = u_xlat6.xy * float2(u._scale.x, u._scale.y) + u._offset.xy;
        u_xlat20.x = u_xlat20.x * u._intensity;
    }
    u_xlat1.xy = float2(u_xlat9) * u_xlat1.xx + u_xlat10.xy;
    u_xlat17.xy = u_xlat1.xy;
    u_xlat5.y = u_xlat0.w;
    u_xlat2.x = float(0.100000001);
    for(int u_xlati_loop_5 = int(0) ; u_xlati_loop_5<int(u._iteration) ; u_xlati_loop_5++)
    {
        u_xlat18.xy = floor(u_xlat17.xy);
        u_xlat20.xy = fract(u_xlat17.xy);
        u_xlat20.xy = u_xlat20.xy * float2(10.0, 3.33333325);
        u_xlat20.xy = min(u_xlat20.xy, float2(1.0, 1.0));
        u_xlat21.xy = u_xlat20.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
        u_xlat20.xy = u_xlat20.xy * u_xlat20.xy;
        u_xlat20.xy = u_xlat20.xy * u_xlat21.xy;
        u_xlat21.x = dot(u_xlat18.xy, float2(-0.819999993, -0.839999974));
        u_xlat21.x = sin(u_xlat21.x);
        u_xlat21.x = u_xlat21.x * 4757.15283;
        u_xlat6 = u_xlat18.xyxy + float4(1.0, 0.0, 0.0, 1.0);
        u_xlat29 = dot(u_xlat6.xy, float2(-0.819999993, -0.839999974));
        u_xlat29 = sin(u_xlat29);
        u_xlat21.y = u_xlat29 * 4757.15283;
        u_xlat21.xy = fract(u_xlat21.xy);
        u_xlat29 = (-u_xlat21.x) + u_xlat21.y;
        u_xlat21.x = u_xlat20.x * u_xlat29 + u_xlat21.x;
        u_xlat29 = dot(u_xlat6.zw, float2(-0.819999993, -0.839999974));
        u_xlat29 = sin(u_xlat29);
        u_xlat29 = u_xlat29 * 4757.15283;
        u_xlat29 = fract(u_xlat29);
        u_xlat18.xy = u_xlat18.xy + float2(1.0, 1.0);
        u_xlat18.x = dot(u_xlat18.xy, float2(-0.819999993, -0.839999974));
        u_xlat18.x = sin(u_xlat18.x);
        u_xlat18.x = u_xlat18.x * 4757.15283;
        u_xlat18.x = fract(u_xlat18.x);
        u_xlat18.x = (-u_xlat29) + u_xlat18.x;
        u_xlat18.x = u_xlat20.x * u_xlat18.x + u_xlat29;
        u_xlat18.x = (-u_xlat21.x) + u_xlat18.x;
        u_xlat18.x = u_xlat20.y * u_xlat18.x + u_xlat21.x;
        u_xlat5.y = u_xlat2.x * u_xlat18.x + u_xlat5.y;
        u_xlat6.x = dot(u_xlat4.yx, u_xlat17.xy);
        u_xlat6.y = dot(u_xlat3.zw, u_xlat17.xy);
        u_xlat17.xy = u_xlat6.xy * float2(u._scale.x, u._scale.y) + u._offset.xy;
        u_xlat2.x = u_xlat2.x * u._intensity;
    }
    u_xlat0.xy = u_xlat0.xy * float2(0.5, 0.5) + u_xlat5.xy;
    u_xlat1.xyz = u_xlat0.xyw;
    u_xlat25 = 0.100000001;
    for(int u_xlati_loop_6 = 0 ; u_xlati_loop_6<int(u._iteration) ; u_xlati_loop_6++)
    {
        u_xlat10.xy = floor(u_xlat1.xy);
        u_xlat19.xy = fract(u_xlat1.xy);
        u_xlat19.xy = u_xlat19.xy * float2(10.0, 3.33333325);
        u_xlat19.xy = min(u_xlat19.xy, float2(1.0, 1.0));
        u_xlat20.xy = u_xlat19.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
        u_xlat19.xy = u_xlat19.xy * u_xlat19.xy;
        u_xlat19.xy = u_xlat19.xy * u_xlat20.xy;
        u_xlat26 = dot(u_xlat10.xy, float2(-0.819999993, -0.839999974));
        u_xlat26 = sin(u_xlat26);
        u_xlat26 = u_xlat26 * 4757.15283;
        u_xlat26 = fract(u_xlat26);
        u_xlat5 = u_xlat10.xyxy + float4(1.0, 0.0, 0.0, 1.0);
        u_xlat20.x = dot(u_xlat5.xy, float2(-0.819999993, -0.839999974));
        u_xlat20.x = sin(u_xlat20.x);
        u_xlat20.x = u_xlat20.x * 4757.15283;
        u_xlat20.x = fract(u_xlat20.x);
        u_xlat20.x = (-u_xlat26) + u_xlat20.x;
        u_xlat26 = u_xlat19.x * u_xlat20.x + u_xlat26;
        u_xlat20.x = dot(u_xlat5.zw, float2(-0.819999993, -0.839999974));
        u_xlat20.x = sin(u_xlat20.x);
        u_xlat20.x = u_xlat20.x * 4757.15283;
        u_xlat20.x = fract(u_xlat20.x);
        u_xlat10.xy = u_xlat10.xy + float2(1.0, 1.0);
        u_xlat10.x = dot(u_xlat10.xy, float2(-0.819999993, -0.839999974));
        u_xlat10.x = sin(u_xlat10.x);
        u_xlat10.x = u_xlat10.x * 4757.15283;
        u_xlat10.x = fract(u_xlat10.x);
        u_xlat10.x = (-u_xlat20.x) + u_xlat10.x;
        u_xlat10.x = u_xlat19.x * u_xlat10.x + u_xlat20.x;
        u_xlat10.x = (-u_xlat26) + u_xlat10.x;
        u_xlat10.x = u_xlat19.y * u_xlat10.x + u_xlat26;
        u_xlat1.z = u_xlat25 * u_xlat10.x + u_xlat1.z;
        u_xlat5.x = dot(u_xlat4.yx, u_xlat1.xy);
        u_xlat5.y = dot(u_xlat3.xy, u_xlat1.xy);
        u_xlat1.xy = u_xlat5.xy * float2(u._scale.x, u._scale.y) + u._offset.xy;
        u_xlat25 = u_xlat25 * u._intensity;
    }
    u_xlat0.xyw = u._color1.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat0.xyw = u._color1.xyz * u_xlat0.xyw + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat0.xyw = u_xlat0.xyw * u._color1.xyz;
    u_xlat1.xyw = u._color2.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyw = u._color2.xyz * u_xlat1.xyw + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat16.x = cos(u_xlat16.x);
    u_xlat1.xyw = u._color2.xyz * u_xlat1.xyw + (-u_xlat0.xyw);
    u_xlat0.xyz = u_xlat16.xxx * u_xlat1.xyw + u_xlat0.xyw;
    u_xlat2 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat24 = u_xlat1.z * u_xlat1.z;
    u_xlat1.x = u_xlat24 * 0.600000024;
    u_xlat24 = u_xlat24 * u_xlat1.z + u_xlat1.x;
    u_xlat24 = u_xlat1.z * 0.5 + u_xlat24;
    u_xlat1.xyz = u_xlat0.xyz * float3(u_xlat24);
    u_xlatb3 = int(u._blend_mode)==1;
    u_xlat1.w = 1.0;
    u_xlat4 = u_xlat2 * u_xlat1;
    u_xlat0.xyz = float3(u_xlat24) * u_xlat0.xyz + u_xlat2.xyz;
    u_xlat0.w = u_xlat2.w;
    u_xlat3 = (bool(u_xlatb3)) ? u_xlat4 : u_xlat0;
    u_xlat0.xyz = u_xlat1.xyz;
    u_xlat0 = (int(u._blend_mode) != 0) ? u_xlat3 : u_xlat0;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat2 = u_xlat2 * u_xlat5;
        u_xlat2 = u_xlat3 * u_xlat4 + u_xlat2;
        u_xlat1.x = u_xlat4.x * u_xlat2.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat2.w;
        __nv_out.xyz = u_xlat2.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
