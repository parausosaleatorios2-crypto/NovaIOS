// ---------------------------------------------------------------------------
// Broken Glass (NV)
// origem : assets/effects/nv-nodevideo-assetstore-broken-glass.xml
// id     : nv.effect.nodevideo-assetstore-broken-glass
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_broken_glassParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _strength;
    float _noise_offset;
    float _noise_scale;
    float _offset_seed;
    float _scale_seed;
    float _keep_edge;
    float _randomize;
    float _evolution;
    float _feather;
    float2 _tex_offset;
    float2 _tex_scale;
    float _tex_angle;
    float4 _tint;
    float _type;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
bool2 u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
bool3 u_xlatb5;
float3 u_xlat6;
float4 u_xlat7;
float3 u_xlat8;
float3 u_xlat9;
float4 u_xlat10;
float4 u_xlat11;
float4 u_xlat12;
bool4 u_xlatb12;
float4 u_xlat13;
bool4 u_xlatb13;
float4 u_xlat14;
float2 u_xlat16;
bool2 u_xlatb16;
float u_xlat17;
float2 u_xlat30;
bool2 u_xlatb30;
float u_xlat31;
bool2 u_xlatb32;
float2 u_xlat33;
float u_xlat34;
bool u_xlatb46;
float u_xlat48;
float u_xlat49;

fragment float4 fx_nv_nodevideo_assetstore_broken_glass(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_broken_glassParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]],
    texture2d<float> texture2 [[texture(2)]],
    texture2d<float> texture4 [[texture(3)]],
    texture2d<float> texture1 [[texture(4)]],
    texture2d<float> texture3 [[texture(5)]],
    texture2d<float> texture5 [[texture(6)]],
    texture2d<float> Mask [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat30.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat1.x = (-u._tex_angle) + 180.0;
    u_xlat1.x = u_xlat1.x * 0.0174532942;
    u_xlat2.x = sin(u_xlat1.x);
    u_xlat3.x = cos(u_xlat1.x);
    u_xlat1.x = sin((-u_xlat1.x));
    u_xlat1.y = u_xlat3.x;
    u_xlat1.z = u_xlat2.x;
    u_xlat2.x = dot(u_xlat30.xy, u_xlat1.yz);
    u_xlat2.y = dot(u_xlat30.xy, u_xlat1.xy);
    u_xlat1 = (-u_xlat2.xyxy) * u._tex_scale.xyxy + float4(0.5, 0.5, 0.5, 0.5);
    u_xlat1 = u_xlat1 + (-float4(u._tex_offset.x, u._tex_offset.y, u._tex_offset.x, u._tex_offset.y));
    u_xlat2 = u_xlat1 + float4(-0.5, -0.5, -0.5, -0.550000012);
    u_xlatb30.x = _resolution.x<_resolution.y;
    u_xlat3 = u_xlat2.xyxy * float4(0.699999988, 1.0, 1.0, 1.5);
    u_xlat30.xy = (u_xlatb30.x) ? u_xlat3.xy : u_xlat3.zw;
    u_xlat1.xy = u_xlat30.xy + float2(0.5, 0.5);
    u_xlatb46 = int(u._blend_mode)==1;
    if(int(u._type) == 0) {
        u_xlat3.xy = texture0.sample(__nv_smp, u_xlat1.xy).xy;
    } else {
        u_xlatb2.x = int(u._type)==1;
        if(u_xlatb2.x){
            u_xlat3.xy = texture2.sample(__nv_smp, u_xlat1.xy).xy;
        } else {
            u_xlat3.xy = texture4.sample(__nv_smp, u_xlat1.xy).xy;
        }
    }
    u_xlat4.xyz = float3(float3(u._evolution, u._evolution, u._evolution)) * float3(0.150000006, 0.14850001, 1.5);
    u_xlat1.x = u_xlat4.x * u._feather + u_xlat4.x;
    u_xlat16.x = dot(u_xlat2.zw, u_xlat2.zw);
    u_xlat1.x = (-u._evolution) * 0.14850001 + u_xlat1.x;
    u_xlat16.x = u_xlat16.x * 4.0 + (-u_xlat4.y);
    u_xlat1.x = float(1.0) / u_xlat1.x;
    u_xlat1.x = u_xlat1.x * u_xlat16.x;
    u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
    u_xlat16.x = u_xlat1.x * -2.0 + 3.0;
    u_xlat1.x = u_xlat1.x * u_xlat1.x;
    u_xlat1.x = (-u_xlat16.x) * u_xlat1.x + 1.0;
    u_xlat16.x = (-u._feather) * 0.100000001 + u_xlat4.z;
    u_xlat2.x = u._evolution * 1.5 + (-u_xlat16.x);
    u_xlat16.x = (-u_xlat16.x) + u_xlat1.z;
    u_xlat31 = float(1.0) / u_xlat2.x;
    u_xlat16.x = u_xlat31 * u_xlat16.x;
    u_xlat16.x = clamp(u_xlat16.x, 0.0, 1.0);
    u_xlat31 = u_xlat16.x * -2.0 + 3.0;
    u_xlat16.x = u_xlat16.x * u_xlat16.x;
    u_xlat16.x = (-u_xlat31) * u_xlat16.x + 1.0;
    u_xlat1.x = (int(u._type) != 0) ? u_xlat16.x : u_xlat1.x;
    u_xlat3.z = u._offset_seed;
    u_xlat16.x = dot(u_xlat3.xyz, float3(0.333333343, 0.333333343, 0.333333343));
    u_xlat2.xyz = u_xlat16.xxx + u_xlat3.xyz;
    u_xlat2.xyz = floor(u_xlat2.xyz);
    u_xlat4.xyz = (-u_xlat2.xyz) + u_xlat3.xyz;
    u_xlat16.x = dot(u_xlat2.xyz, float3(0.166666672, 0.166666672, 0.166666672));
    u_xlat4.xyz = u_xlat16.xxx + u_xlat4.xyz;
    u_xlatb5.xyz = greaterThanEqual(u_xlat4.zxyz, u_xlat4.xyzx).xyz;
    u_xlat6.x = u_xlatb5.y ? float(1.0) : 0.0;
    u_xlat6.y = u_xlatb5.z ? float(1.0) : 0.0;
    u_xlat6.z = u_xlatb5.x ? float(1.0) : 0.0;
;
    u_xlat5.x = (u_xlatb5.x) ? float(0.0) : float(1.0);
    u_xlat5.y = (u_xlatb5.y) ? float(0.0) : float(1.0);
    u_xlat5.z = (u_xlatb5.z) ? float(0.0) : float(1.0);
    u_xlat7.xyz = min(u_xlat5.xyz, u_xlat6.xyz);
    u_xlat5.xyz = max(u_xlat5.yzx, u_xlat6.yzx);
    u_xlat6.xyz = u_xlat4.xyz + (-u_xlat7.xyz);
    u_xlat6.xyz = u_xlat6.xyz + float3(0.166666672, 0.166666672, 0.166666672);
    u_xlat8.xyz = u_xlat4.xyz + (-u_xlat5.zxy);
    u_xlat8.xyz = u_xlat8.xyz + float3(0.333333343, 0.333333343, 0.333333343);
    u_xlat9.xyz = u_xlat4.xyz + float3(-0.5, -0.5, -0.5);
    u_xlat10.xyz = u_xlat2.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
    u_xlat10.xyz = floor(u_xlat10.xyz);
    u_xlat2.xyz = (-u_xlat10.xyz) * float3(289.0, 289.0, 289.0) + u_xlat2.xyz;
    u_xlat10.x = float(0.0);
    u_xlat10.w = float(1.0);
    u_xlat10.y = u_xlat7.z;
    u_xlat10.z = u_xlat5.y;
    u_xlat10 = u_xlat2.zzzz + u_xlat10;
    u_xlat11 = u_xlat10 * u_xlat10;
    u_xlat10 = u_xlat11 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat10;
    u_xlat11 = u_xlat10 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
    u_xlat11 = floor(u_xlat11);
    u_xlat10 = (-u_xlat11) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat10;
    u_xlat10 = u_xlat2.yyyy + u_xlat10;
    u_xlat11.x = float(0.0);
    u_xlat11.w = float(1.0);
    u_xlat11.y = u_xlat7.y;
    u_xlat11.z = u_xlat5.x;
    u_xlat10 = u_xlat10 + u_xlat11;
    u_xlat11 = u_xlat10 * u_xlat10;
    u_xlat10 = u_xlat11 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat10;
    u_xlat11 = u_xlat10 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
    u_xlat11 = floor(u_xlat11);
    u_xlat10 = (-u_xlat11) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat10;
    u_xlat2 = u_xlat2.xxxx + u_xlat10;
    u_xlat5.x = float(0.0);
    u_xlat5.w = float(1.0);
    u_xlat5.y = u_xlat7.x;
    u_xlat2 = u_xlat2 + u_xlat5;
    u_xlat5 = u_xlat2 * u_xlat2;
    u_xlat2 = u_xlat5 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat2;
    u_xlat5 = u_xlat2 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
    u_xlat5 = floor(u_xlat5);
    u_xlat2 = (-u_xlat5) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat2;
    u_xlat5 = u_xlat2 * float4(0.0204081647, 0.0204081647, 0.0204081647, 0.0204081647);
    u_xlat5 = floor(u_xlat5);
    u_xlat2 = (-u_xlat5) * float4(49.0, 49.0, 49.0, 49.0) + u_xlat2;
    u_xlat5 = u_xlat2 * float4(0.142857149, 0.142857149, 0.142857149, 0.142857149);
    u_xlat5 = floor(u_xlat5);
    u_xlat2 = (-u_xlat5) * float4(7.0, 7.0, 7.0, 7.0) + u_xlat2;
    u_xlat5 = u_xlat5 * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
    u_xlat2 = u_xlat2.xzyw * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
    u_xlat7 = -abs(u_xlat5) + float4(1.0, 1.0, 1.0, 1.0);
    u_xlat7 = -abs(u_xlat2.xzwy) + u_xlat7.xywz;
    u_xlat10.xz = floor(u_xlat5.xy);
    u_xlat10.yw = floor(u_xlat2.xz);
    u_xlat10 = u_xlat10 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
    u_xlat11.xz = floor(u_xlat5.zw);
    u_xlat11.yw = floor(u_xlat2.yw);
    u_xlat11 = u_xlat11 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
    u_xlatb12 = greaterThanEqual(float4(0.0, 0.0, 0.0, 0.0), u_xlat7.xywz);
    u_xlat12.x = (u_xlatb12.x) ? float(-1.0) : float(-0.0);
    u_xlat12.y = (u_xlatb12.y) ? float(-1.0) : float(-0.0);
    u_xlat12.z = (u_xlatb12.z) ? float(-1.0) : float(-0.0);
    u_xlat12.w = (u_xlatb12.w) ? float(-1.0) : float(-0.0);
    u_xlat13.xz = u_xlat5.xy;
    u_xlat13.yw = u_xlat2.xz;
    u_xlat10 = u_xlat10.zwxy * u_xlat12.yyxx + u_xlat13.zwxy;
    u_xlat2.xz = u_xlat5.zw;
    u_xlat2 = u_xlat11 * u_xlat12.zzww + u_xlat2;
    u_xlat5.xy = u_xlat10.zw;
    u_xlat5.z = u_xlat7.x;
    u_xlat16.x = dot(u_xlat5.xyz, u_xlat5.xyz);
    u_xlat10.z = u_xlat7.y;
    u_xlat31 = dot(u_xlat10.xyz, u_xlat10.xyz);
    u_xlat11.xy = u_xlat2.xy;
    u_xlat11.z = u_xlat7.w;
    u_xlat2.x = dot(u_xlat11.xyz, u_xlat11.xyz);
    u_xlat7.xy = u_xlat2.zw;
    u_xlat17 = dot(u_xlat7.xyz, u_xlat7.xyz);
    u_xlat16.x = rsqrt(u_xlat16.x);
    u_xlat31 = rsqrt(u_xlat31);
    u_xlat2.x = rsqrt(u_xlat2.x);
    u_xlat17 = rsqrt(u_xlat17);
    u_xlat5.xyz = u_xlat16.xxx * u_xlat5.xyz;
    u_xlat10.xyz = float3(u_xlat31) * u_xlat10.xyz;
    u_xlat2.xzw = u_xlat2.xxx * u_xlat11.xyz;
    u_xlat7.xyz = float3(u_xlat17) * u_xlat7.xyz;
    u_xlat11.x = dot(u_xlat4.xyz, u_xlat4.xyz);
    u_xlat11.y = dot(u_xlat6.xyz, u_xlat6.xyz);
    u_xlat11.z = dot(u_xlat8.xyz, u_xlat8.xyz);
    u_xlat11.w = dot(u_xlat9.xyz, u_xlat9.xyz);
    u_xlat11 = (-u_xlat11) + float4(0.600000024, 0.600000024, 0.600000024, 0.600000024);
    u_xlat11 = max(u_xlat11, float4(0.0, 0.0, 0.0, 0.0));
    u_xlat11 = u_xlat11 * u_xlat11;
    u_xlat11 = u_xlat11 * u_xlat11;
    u_xlat4.x = dot(u_xlat5.xyz, u_xlat4.xyz);
    u_xlat4.y = dot(u_xlat10.xyz, u_xlat6.xyz);
    u_xlat4.z = dot(u_xlat2.xzw, u_xlat8.xyz);
    u_xlat4.w = dot(u_xlat7.xyz, u_xlat9.xyz);
    u_xlat16.x = dot(u_xlat11, u_xlat4);
    u_xlat16.x = u_xlat16.x * u._noise_offset;
    u_xlat2.xy = u_xlat3.xy + float2(-0.5, -0.5);
    u_xlatb32.xy = lessThan(int4(0, 0, 0, 0), int4(int(u._randomize), int(u._keep_edge), int(u._randomize), int(u._keep_edge))).xy;
    u_xlat2.xy = (u_xlatb32.x) ? float2(0.0, 1.0) : u_xlat2.xy;
    u_xlat16.x = u_xlat16.x * 263.893799;
    u_xlat4.x = sin(u_xlat16.x);
    u_xlat5.x = cos(u_xlat16.x);
    u_xlat6.x = sin((-u_xlat16.x));
    u_xlat6.y = u_xlat5.x;
    u_xlat6.z = u_xlat4.x;
    u_xlat4.x = dot(u_xlat2.xy, u_xlat6.yz);
    u_xlat4.y = dot(u_xlat2.xy, u_xlat6.xy);
    u_xlat16.x = u_xlat1.x * u._strength;
    u_xlat3.w = u._scale_seed;
    u_xlat31 = dot(u_xlat3.xyw, float3(0.333333343, 0.333333343, 0.333333343));
    u_xlat2.xyz = float3(u_xlat31) + u_xlat3.xyw;
    u_xlat2.xyz = floor(u_xlat2.xyz);
    u_xlat3.xyz = (-u_xlat2.xyz) + u_xlat3.xyw;
    u_xlat31 = dot(u_xlat2.xyz, float3(0.166666672, 0.166666672, 0.166666672));
    u_xlat3.xyz = float3(u_xlat31) + u_xlat3.xyz;
    u_xlatb5.xyz = greaterThanEqual(u_xlat3.zxyz, u_xlat3.xyzx).xyz;
    u_xlat6.x = u_xlatb5.y ? float(1.0) : 0.0;
    u_xlat6.y = u_xlatb5.z ? float(1.0) : 0.0;
    u_xlat6.z = u_xlatb5.x ? float(1.0) : 0.0;
;
    u_xlat5.x = (u_xlatb5.x) ? float(0.0) : float(1.0);
    u_xlat5.y = (u_xlatb5.y) ? float(0.0) : float(1.0);
    u_xlat5.z = (u_xlatb5.z) ? float(0.0) : float(1.0);
    u_xlat7.xyz = min(u_xlat5.xyz, u_xlat6.xyz);
    u_xlat5.xyz = max(u_xlat5.yzx, u_xlat6.yzx);
    u_xlat6.xyz = u_xlat3.xyz + (-u_xlat7.xyz);
    u_xlat6.xyz = u_xlat6.xyz + float3(0.166666672, 0.166666672, 0.166666672);
    u_xlat8.xyz = u_xlat3.xyz + (-u_xlat5.zxy);
    u_xlat8.xyz = u_xlat8.xyz + float3(0.333333343, 0.333333343, 0.333333343);
    u_xlat9.xyz = u_xlat3.xyz + float3(-0.5, -0.5, -0.5);
    u_xlat10.xyz = u_xlat2.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
    u_xlat10.xyz = floor(u_xlat10.xyz);
    u_xlat2.xyz = (-u_xlat10.xyz) * float3(289.0, 289.0, 289.0) + u_xlat2.xyz;
    u_xlat10.x = float(0.0);
    u_xlat10.w = float(1.0);
    u_xlat10.y = u_xlat7.z;
    u_xlat10.z = u_xlat5.y;
    u_xlat10 = u_xlat2.zzzz + u_xlat10;
    u_xlat11 = u_xlat10 * u_xlat10;
    u_xlat10 = u_xlat11 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat10;
    u_xlat11 = u_xlat10 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
    u_xlat11 = floor(u_xlat11);
    u_xlat10 = (-u_xlat11) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat10;
    u_xlat10 = u_xlat2.yyyy + u_xlat10;
    u_xlat11.x = float(0.0);
    u_xlat11.w = float(1.0);
    u_xlat11.y = u_xlat7.y;
    u_xlat11.z = u_xlat5.x;
    u_xlat10 = u_xlat10 + u_xlat11;
    u_xlat11 = u_xlat10 * u_xlat10;
    u_xlat10 = u_xlat11 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat10;
    u_xlat11 = u_xlat10 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
    u_xlat11 = floor(u_xlat11);
    u_xlat10 = (-u_xlat11) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat10;
    u_xlat10 = u_xlat2.xxxx + u_xlat10;
    u_xlat5.x = float(0.0);
    u_xlat5.w = float(1.0);
    u_xlat5.y = u_xlat7.x;
    u_xlat5 = u_xlat5 + u_xlat10;
    u_xlat7 = u_xlat5 * u_xlat5;
    u_xlat5 = u_xlat7 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat5;
    u_xlat7 = u_xlat5 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
    u_xlat7 = floor(u_xlat7);
    u_xlat5 = (-u_xlat7) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat5;
    u_xlat7 = u_xlat5 * float4(0.0204081647, 0.0204081647, 0.0204081647, 0.0204081647);
    u_xlat7 = floor(u_xlat7);
    u_xlat5 = (-u_xlat7) * float4(49.0, 49.0, 49.0, 49.0) + u_xlat5;
    u_xlat7 = u_xlat5 * float4(0.142857149, 0.142857149, 0.142857149, 0.142857149);
    u_xlat7 = floor(u_xlat7);
    u_xlat5 = (-u_xlat7) * float4(7.0, 7.0, 7.0, 7.0) + u_xlat5;
    u_xlat7 = u_xlat7 * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
    u_xlat5 = u_xlat5.xzyw * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
    u_xlat10 = -abs(u_xlat7) + float4(1.0, 1.0, 1.0, 1.0);
    u_xlat10 = -abs(u_xlat5.xzwy) + u_xlat10.xywz;
    u_xlat11.xz = floor(u_xlat7.xy);
    u_xlat11.yw = floor(u_xlat5.xz);
    u_xlat11 = u_xlat11 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
    u_xlat12.xz = floor(u_xlat7.zw);
    u_xlat12.yw = floor(u_xlat5.yw);
    u_xlat12 = u_xlat12 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
    u_xlatb13 = greaterThanEqual(float4(0.0, 0.0, 0.0, 0.0), u_xlat10.xywz);
    u_xlat13.x = (u_xlatb13.x) ? float(-1.0) : float(-0.0);
    u_xlat13.y = (u_xlatb13.y) ? float(-1.0) : float(-0.0);
    u_xlat13.z = (u_xlatb13.z) ? float(-1.0) : float(-0.0);
    u_xlat13.w = (u_xlatb13.w) ? float(-1.0) : float(-0.0);
    u_xlat14.xz = u_xlat7.xy;
    u_xlat14.yw = u_xlat5.xz;
    u_xlat11 = u_xlat11.zwxy * u_xlat13.yyxx + u_xlat14.zwxy;
    u_xlat5.xz = u_xlat7.zw;
    u_xlat5 = u_xlat12 * u_xlat13.zzww + u_xlat5;
    u_xlat2.xy = u_xlat11.zw;
    u_xlat2.z = u_xlat10.x;
    u_xlat31 = dot(u_xlat2.xyz, u_xlat2.xyz);
    u_xlat11.z = u_xlat10.y;
    u_xlat48 = dot(u_xlat11.xyz, u_xlat11.xyz);
    u_xlat7.xy = u_xlat5.xy;
    u_xlat7.z = u_xlat10.w;
    u_xlat34 = dot(u_xlat7.xyz, u_xlat7.xyz);
    u_xlat10.xy = u_xlat5.zw;
    u_xlat49 = dot(u_xlat10.xyz, u_xlat10.xyz);
    u_xlat31 = rsqrt(u_xlat31);
    u_xlat48 = rsqrt(u_xlat48);
    u_xlat34 = rsqrt(u_xlat34);
    u_xlat49 = rsqrt(u_xlat49);
    u_xlat2.xyz = float3(u_xlat31) * u_xlat2.xyz;
    u_xlat5.xyz = float3(u_xlat48) * u_xlat11.xyz;
    u_xlat7.xyz = float3(u_xlat34) * u_xlat7.xyz;
    u_xlat10.xyz = float3(u_xlat49) * u_xlat10.xyz;
    u_xlat11.x = dot(u_xlat3.xyz, u_xlat3.xyz);
    u_xlat11.y = dot(u_xlat6.xyz, u_xlat6.xyz);
    u_xlat11.z = dot(u_xlat8.xyz, u_xlat8.xyz);
    u_xlat11.w = dot(u_xlat9.xyz, u_xlat9.xyz);
    u_xlat11 = (-u_xlat11) + float4(0.600000024, 0.600000024, 0.600000024, 0.600000024);
    u_xlat11 = max(u_xlat11, float4(0.0, 0.0, 0.0, 0.0));
    u_xlat11 = u_xlat11 * u_xlat11;
    u_xlat11 = u_xlat11 * u_xlat11;
    u_xlat3.x = dot(u_xlat2.xyz, u_xlat3.xyz);
    u_xlat3.y = dot(u_xlat5.xyz, u_xlat6.xyz);
    u_xlat3.z = dot(u_xlat7.xyz, u_xlat8.xyz);
    u_xlat3.w = dot(u_xlat10.xyz, u_xlat9.xyz);
    u_xlat31 = dot(u_xlat11, u_xlat3);
    u_xlat31 = u_xlat31 * u_xlat16.x;
    u_xlat31 = u_xlat31 * u._evolution;
    u_xlat31 = u_xlat31 * u._noise_scale;
    u_xlat31 = u_xlat31 * 42.0 + 1.0;
    u_xlat0.xy = u_xlat0.xy * float2(u_xlat31) + float2(0.5, 0.5);
    u_xlat16.xy = u_xlat16.xx * u_xlat4.xy;
    u_xlat16.xy = u_xlat16.xy * float2(float2(u._evolution, u._evolution));
    u_xlat0.xy = (-u_xlat16.xy) * float2(0.400000006, 0.400000006) + u_xlat0.xy;
    u_xlat16.xy = u_xlat0.xy + float2(-0.5, -0.5);
    u_xlat16.xy = u_xlat16.xy * float2(1.00999999, 1.00999999) + float2(0.5, 0.5);
    u_xlatb2.xy = lessThan(u_xlat16.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb3.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat16.xyxx).xy;
    u_xlat33.xy = fract(u_xlat16.xy);
    u_xlat33.xy = (-u_xlat33.xy) + float2(1.0, 1.0);
    u_xlat3.x = (u_xlatb3.x) ? u_xlat33.x : u_xlat16.x;
    u_xlat3.y = (u_xlatb3.y) ? u_xlat33.y : u_xlat16.y;
    {
        float2 hlslcc_movcTemp = u_xlat16;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? (-u_xlat16.x) : u_xlat3.x;
        hlslcc_movcTemp.y = (u_xlatb2.y) ? (-u_xlat16.y) : u_xlat3.y;
        u_xlat16 = hlslcc_movcTemp;
    }
    u_xlat16.xy = u_xlat16.xy + float2(-0.5, -0.5);
    u_xlat16.xy = u_xlat16.xy * float2(0.990099013, 0.990099013) + float2(0.5, 0.5);
    u_xlat0.xy = (u_xlatb32.y) ? u_xlat16.xy : u_xlat0.xy;
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat0.xy);
    u_xlat0.xy = u_xlat30.xy * float2(1.00999999, 1.00999999) + float2(0.5, 0.5);
    u_xlatb30.xy = lessThan(u_xlat0.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb16.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.xyxx).xy;
    u_xlat3.xy = fract(u_xlat0.xy);
    u_xlat3.xy = (-u_xlat3.xy) + float2(1.0, 1.0);
    u_xlat16.x = (u_xlatb16.x) ? u_xlat3.x : u_xlat0.x;
    u_xlat16.y = (u_xlatb16.y) ? u_xlat3.y : u_xlat0.y;
    {
        float4 hlslcc_movcTemp = u_xlat0;
        hlslcc_movcTemp.x = (u_xlatb30.x) ? (-u_xlat0.x) : u_xlat16.x;
        hlslcc_movcTemp.y = (u_xlatb30.y) ? (-u_xlat0.y) : u_xlat16.y;
        u_xlat0 = hlslcc_movcTemp;
    }
    u_xlat0.xy = u_xlat0.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * float2(0.990099013, 0.990099013) + float2(0.5, 0.5);
    if(int(u._type) == 0) {
        u_xlat3.xyz = texture1.sample(__nv_smp, u_xlat0.xy).xyz;
    } else {
        u_xlatb30.x = int(u._type)==1;
        if(u_xlatb30.x){
            u_xlat3.xyz = texture3.sample(__nv_smp, u_xlat0.xy).xyz;
        } else {
            u_xlat3.xyz = texture5.sample(__nv_smp, u_xlat0.xy).xyz;
        }
    }
    u_xlat0.xyz = u_xlat3.xyz * u._tint.xyz;
    u_xlat3.xyz = u_xlat1.xxx * u_xlat0.xyz;
    u_xlat0.x = (-u_xlat0.x) * u_xlat1.x + 1.0;
    u_xlat4.xyz = u_xlat3.xxx * u_xlat3.xyz;
    u_xlat4.w = 0.0;
    u_xlat0 = u_xlat2 * u_xlat0.xxxx + u_xlat4;
    u_xlat1.xyz = rsqrt(u_xlat3.xyz);
    u_xlat1.xyz = float3(1.0, 1.0, 1.0) / u_xlat1.xyz;
    u_xlat1.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat4.xyz = u_xlat1.xyz * u_xlat2.xyz;
    u_xlat5 = (-u_xlat2) + float4(1.0, 1.0, 1.0, 1.0);
    u_xlat3.w = 0.0;
    u_xlat3 = (-u_xlat3) + float4(1.0, 1.0, 1.0, 1.0);
    u_xlat3 = (-u_xlat5) * u_xlat3 + float4(1.0, 1.0, 1.0, 1.0);
    u_xlat4.w = u_xlat2.w;
    u_xlat1 = (bool(u_xlatb46)) ? u_xlat4 : u_xlat3;
    u_xlat0 = (int(u._blend_mode) != 0) ? u_xlat1 : u_xlat0;
    if(int(u._use_inner_mask) != 0) {
        u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
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
