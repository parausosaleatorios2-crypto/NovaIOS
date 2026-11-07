// ---------------------------------------------------------------------------
// Turbulent Distortion (NV)
// origem : assets/effects/nv-nodevideo-assetstore-turbulent-distortion.xml
// id     : nv.effect.nodevideo-assetstore-turbulent-distortion
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_turbulent_distortionParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _center;
    float2 _offset;
    float2 _scale;
    float _type;
    float _octaves;
    float _evolution;
    float _random_seed;
    float _amount;
    float _strength;
    float _frequency;
    float _amp_mult;
    float _amplitude;
    float _keep_edge;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
bool u_xlatb0;
float4 u_xlat1;
int u_xlati1;
bool2 u_xlatb1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float4 u_xlat6;
float4 u_xlat7;
bool u_xlatb7;
float4 u_xlat8;
bool3 u_xlatb8;
float4 u_xlat9;
bool3 u_xlatb9;
float4 u_xlat10;
float4 u_xlat11;
float3 u_xlat12;
float4 u_xlat13;
float4 u_xlat14;
float4 u_xlat15;
bool4 u_xlatb15;
float4 u_xlat16;
bool4 u_xlatb16;
float4 u_xlat17;
float2 u_xlat18;
float u_xlat19;
bool u_xlatb19;
float u_xlat21;
bool u_xlatb21;
float u_xlat22;
float u_xlat23;
float2 u_xlat36;
float2 u_xlat37;
bool2 u_xlatb37;
float2 u_xlat38;
bool u_xlatb38;
float u_xlat39;
bool u_xlatb39;
float u_xlat40;
float u_xlat41;
float u_xlat55;
int u_xlati55;
float u_xlat56;
int u_xlati56;
bool u_xlatb56;
float u_xlat57;
int u_xlati57;
bool u_xlatb57;
float u_xlat61;

fragment float4 fx_nv_nodevideo_assetstore_turbulent_distortion(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_turbulent_distortionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat36.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y) + float2(0.5, 0.5);
    u_xlat1.xy = u._center.xy + float2(-0.5, -0.5);
    u_xlat36.xy = u_xlat36.xy + (-u_xlat1.xy);
    if(int(u._type) == 0) {
        u_xlat1.y = u_xlat36.y + -0.5;
        u_xlat1.x = 0.0;
    } else {
        u_xlatb37.x = int(u._type)==1;
        if(u_xlatb37.x){
            u_xlat1.x = u_xlat36.x + -0.5;
            u_xlat1.y = 0.0;
        } else {
            u_xlatb37.x = int(u._type)==2;
            if(u_xlatb37.x){
                u_xlat1.xy = u_xlat36.xy + float2(-0.5, -0.5);
            } else {
                u_xlat36.xy = u_xlat36.xy + float2(-0.5, -0.5);
                u_xlat37.x = dot(u_xlat36.xy, u_xlat36.xy);
                u_xlat38.y = sqrt(u_xlat37.x);
                u_xlatb37.xy = equal(int4(int4(int(u._type), int(u._type), int(u._type), int(u._type))), int4(3, 4, 3, 4)).xy;
                u_xlat3.x = min(abs(u_xlat36.y), abs(u_xlat36.x));
                u_xlat21 = max(abs(u_xlat36.y), abs(u_xlat36.x));
                u_xlat21 = float(1.0) / u_xlat21;
                u_xlat3.x = u_xlat21 * u_xlat3.x;
                u_xlat21 = u_xlat3.x * u_xlat3.x;
                u_xlat39 = u_xlat21 * 0.0208350997 + -0.0851330012;
                u_xlat39 = u_xlat21 * u_xlat39 + 0.180141002;
                u_xlat39 = u_xlat21 * u_xlat39 + -0.330299497;
                u_xlat21 = u_xlat21 * u_xlat39 + 0.999866009;
                u_xlat39 = u_xlat21 * u_xlat3.x;
                u_xlatb57 = abs(u_xlat36.y)<abs(u_xlat36.x);
                u_xlat39 = u_xlat39 * -2.0 + 1.57079637;
                u_xlat39 = u_xlatb57 ? u_xlat39 : float(0.0);
                u_xlat3.x = u_xlat3.x * u_xlat21 + u_xlat39;
                u_xlatb21 = u_xlat36.y<(-u_xlat36.y);
                u_xlat21 = u_xlatb21 ? -3.14159274 : float(0.0);
                u_xlat3.x = u_xlat21 + u_xlat3.x;
                u_xlat21 = min(u_xlat36.y, u_xlat36.x);
                u_xlat39 = max(u_xlat36.y, u_xlat36.x);
                u_xlatb21 = u_xlat21<(-u_xlat21);
                u_xlatb39 = u_xlat39>=(-u_xlat39);
                u_xlatb21 = u_xlatb39 && u_xlatb21;
                u_xlat3.x = (u_xlatb21) ? (-u_xlat3.x) : u_xlat3.x;
                u_xlat3.x = u_xlat3.x * 0.159155071;
                u_xlat2.x = abs(u_xlat3.x) + abs(u_xlat3.x);
                u_xlat2.y = float(0.0);
                u_xlat38.x = float(0.0);
                u_xlat36.xy = (u_xlatb37.y) ? u_xlat2.xy : u_xlat36.xy;
                u_xlat1.xy = (u_xlatb37.x) ? u_xlat38.xy : u_xlat36.xy;
            }
        }
    }
    u_xlat36.xy = u_xlat1.xy / u._scale.xy;
    u_xlat36.xy = u_xlat36.xy + float2(0.5, 0.5);
    u_xlati1 = int(u._octaves);
    u_xlat2.z = u._random_seed * 7391.93506 + u._evolution;
    u_xlat3.x = float(0.0);
    u_xlat3.w = float(1.0);
    u_xlat4.x = float(0.0);
    u_xlat4.w = float(1.0);
    u_xlat5.x = float(0.0);
    u_xlat5.w = float(1.0);
    u_xlat2.xy = u_xlat36.xy;
    u_xlat37.x = u._amplitude;
    u_xlat19 = float(0.0);
    for(int u_xlati_loop_1 = int(0) ; u_xlati_loop_1<u_xlati1 ; u_xlati_loop_1++)
    {
        u_xlat56 = dot(u_xlat2.xyz, float3(0.333333343, 0.333333343, 0.333333343));
        u_xlat6.xyz = float3(u_xlat56) + u_xlat2.xyz;
        u_xlat6.xyz = floor(u_xlat6.xyz);
        u_xlat7.xyz = u_xlat2.xyz + (-u_xlat6.xyz);
        u_xlat56 = dot(u_xlat6.xyz, float3(0.166666672, 0.166666672, 0.166666672));
        u_xlat7.xyz = float3(u_xlat56) + u_xlat7.xyz;
        u_xlatb8.xyz = greaterThanEqual(u_xlat7.zxyz, u_xlat7.xyzx).xyz;
        u_xlat9.x = u_xlatb8.y ? float(1.0) : 0.0;
        u_xlat9.y = u_xlatb8.z ? float(1.0) : 0.0;
        u_xlat9.z = u_xlatb8.x ? float(1.0) : 0.0;
;
        u_xlat8.x = (u_xlatb8.x) ? float(0.0) : float(1.0);
        u_xlat8.y = (u_xlatb8.y) ? float(0.0) : float(1.0);
        u_xlat8.z = (u_xlatb8.z) ? float(0.0) : float(1.0);
        u_xlat10.xyz = min(u_xlat8.xyz, u_xlat9.xyz);
        u_xlat8.xyz = max(u_xlat8.xyz, u_xlat9.xyz);
        u_xlat9.xyz = u_xlat7.xyz + (-u_xlat10.xyz);
        u_xlat9.xyz = u_xlat9.xyz + float3(0.166666672, 0.166666672, 0.166666672);
        u_xlat11.xyz = u_xlat7.xyz + (-u_xlat8.xyz);
        u_xlat11.xyz = u_xlat11.xyz + float3(0.333333343, 0.333333343, 0.333333343);
        u_xlat12.xyz = u_xlat7.xyz + float3(-0.5, -0.5, -0.5);
        u_xlat13.xyz = u_xlat6.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat13.xyz = floor(u_xlat13.xyz);
        u_xlat6.xyz = (-u_xlat13.xyz) * float3(289.0, 289.0, 289.0) + u_xlat6.xyz;
        u_xlat3.y = u_xlat10.z;
        u_xlat3.z = u_xlat8.z;
        u_xlat13 = u_xlat3 + u_xlat6.zzzz;
        u_xlat14 = u_xlat13 * u_xlat13;
        u_xlat13 = u_xlat14 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat13;
        u_xlat14 = u_xlat13 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat14 = floor(u_xlat14);
        u_xlat13 = (-u_xlat14) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat13;
        u_xlat13 = u_xlat6.yyyy + u_xlat13;
        u_xlat4.y = u_xlat10.y;
        u_xlat4.z = u_xlat8.y;
        u_xlat13 = u_xlat4 + u_xlat13;
        u_xlat14 = u_xlat13 * u_xlat13;
        u_xlat13 = u_xlat14 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat13;
        u_xlat14 = u_xlat13 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat14 = floor(u_xlat14);
        u_xlat13 = (-u_xlat14) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat13;
        u_xlat6 = u_xlat6.xxxx + u_xlat13;
        u_xlat5.y = u_xlat10.x;
        u_xlat5.z = u_xlat8.x;
        u_xlat6 = u_xlat5 + u_xlat6;
        u_xlat8 = u_xlat6 * u_xlat6;
        u_xlat6 = u_xlat8 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat6;
        u_xlat8 = u_xlat6 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat8 = floor(u_xlat8);
        u_xlat6 = (-u_xlat8) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat6;
        u_xlat8 = u_xlat6 * float4(0.0204081647, 0.0204081647, 0.0204081647, 0.0204081647);
        u_xlat8 = floor(u_xlat8);
        u_xlat6 = (-u_xlat8) * float4(49.0, 49.0, 49.0, 49.0) + u_xlat6;
        u_xlat8 = u_xlat6 * float4(0.142857149, 0.142857149, 0.142857149, 0.142857149);
        u_xlat8 = floor(u_xlat8);
        u_xlat6 = (-u_xlat8) * float4(7.0, 7.0, 7.0, 7.0) + u_xlat6;
        u_xlat8 = u_xlat8 * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
        u_xlat6 = u_xlat6.xzyw * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
        u_xlat10 = -abs(u_xlat8) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat10 = -abs(u_xlat6.xzwy) + u_xlat10.xywz;
        u_xlat13.xz = floor(u_xlat8.xy);
        u_xlat13.yw = floor(u_xlat6.xz);
        u_xlat13 = u_xlat13 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat14.xz = floor(u_xlat8.zw);
        u_xlat14.yw = floor(u_xlat6.yw);
        u_xlat14 = u_xlat14 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlatb15 = greaterThanEqual(float4(0.0, 0.0, 0.0, 0.0), u_xlat10.xywz);
        u_xlat15.x = (u_xlatb15.x) ? float(-1.0) : float(-0.0);
        u_xlat15.y = (u_xlatb15.y) ? float(-1.0) : float(-0.0);
        u_xlat15.z = (u_xlatb15.z) ? float(-1.0) : float(-0.0);
        u_xlat15.w = (u_xlatb15.w) ? float(-1.0) : float(-0.0);
        u_xlat16.xz = u_xlat8.xy;
        u_xlat16.yw = u_xlat6.xz;
        u_xlat13 = u_xlat13.zwxy * u_xlat15.yyxx + u_xlat16.zwxy;
        u_xlat6.xz = u_xlat8.zw;
        u_xlat6 = u_xlat14 * u_xlat15.zzww + u_xlat6;
        u_xlat8.xy = u_xlat13.zw;
        u_xlat8.z = u_xlat10.x;
        u_xlat56 = dot(u_xlat8.xyz, u_xlat8.xyz);
        u_xlat13.z = u_xlat10.y;
        u_xlat21 = dot(u_xlat13.xyz, u_xlat13.xyz);
        u_xlat14.xy = u_xlat6.xy;
        u_xlat14.z = u_xlat10.w;
        u_xlat39 = dot(u_xlat14.xyz, u_xlat14.xyz);
        u_xlat10.xy = u_xlat6.zw;
        u_xlat22 = dot(u_xlat10.xyz, u_xlat10.xyz);
        u_xlat56 = rsqrt(u_xlat56);
        u_xlat21 = rsqrt(u_xlat21);
        u_xlat39 = rsqrt(u_xlat39);
        u_xlat22 = rsqrt(u_xlat22);
        u_xlat6.xyz = float3(u_xlat56) * u_xlat8.xyz;
        u_xlat8.xyz = float3(u_xlat21) * u_xlat13.xyz;
        u_xlat13.xyz = float3(u_xlat39) * u_xlat14.xyz;
        u_xlat10.xyz = float3(u_xlat22) * u_xlat10.xyz;
        u_xlat14.x = dot(u_xlat7.xyz, u_xlat7.xyz);
        u_xlat14.y = dot(u_xlat9.xyz, u_xlat9.xyz);
        u_xlat14.z = dot(u_xlat11.xyz, u_xlat11.xyz);
        u_xlat14.w = dot(u_xlat12.xyz, u_xlat12.xyz);
        u_xlat14 = (-u_xlat14) + float4(0.600000024, 0.600000024, 0.600000024, 0.600000024);
        u_xlat14 = max(u_xlat14, float4(0.0, 0.0, 0.0, 0.0));
        u_xlat14 = u_xlat14 * u_xlat14;
        u_xlat14 = u_xlat14 * u_xlat14;
        u_xlat6.x = dot(u_xlat6.xyz, u_xlat7.xyz);
        u_xlat6.y = dot(u_xlat8.xyz, u_xlat9.xyz);
        u_xlat6.z = dot(u_xlat13.xyz, u_xlat11.xyz);
        u_xlat6.w = dot(u_xlat10.xyz, u_xlat12.xyz);
        u_xlat56 = dot(u_xlat14, u_xlat6);
        u_xlat56 = u_xlat37.x * u_xlat56;
        u_xlat19 = u_xlat56 * 42.0 + u_xlat19;
        u_xlat2.xy = u_xlat2.xy * float2(u._frequency) + (-float2(u._offset.x, u._offset.y));
        u_xlat37.x = u_xlat37.x * u._amp_mult;
    }
    u_xlat37.x = u._amount + -0.25;
    u_xlat19 = u_xlat37.x + u_xlat19;
    u_xlat55 = u_xlat19 * u._strength;
    if(int(u._type) == 0) {
        u_xlat2.x = u_xlat19 * u._strength + in.acScreenNorm.x;
        u_xlat2.y = in.acScreenNorm.y;
    } else {
        u_xlatb38 = int(u._type)==1;
        if(u_xlatb38){
            u_xlat2.y = u_xlat19 * u._strength + in.acScreenNorm.y;
            u_xlat2.x = in.acScreenNorm.x;
        } else {
            u_xlatb38 = int(u._type)==2;
            if(u_xlatb38){
                u_xlat38.x = u._random_seed + 6.33790016;
                u_xlat3.z = u_xlat38.x * 3937.72485 + u._evolution;
                u_xlat4.x = float(0.0);
                u_xlat4.w = float(1.0);
                u_xlat5.x = float(0.0);
                u_xlat5.w = float(1.0);
                u_xlat6.x = float(0.0);
                u_xlat6.w = float(1.0);
                u_xlat3.xy = u_xlat36.xy;
                u_xlat38.x = 0.0;
                u_xlat56 = u._amplitude;
                for(int u_xlati_loop_2 = 0 ; u_xlati_loop_2<u_xlati1 ; u_xlati_loop_2++)
                {
                    u_xlat7.x = dot(u_xlat3.xyz, float3(0.333333343, 0.333333343, 0.333333343));
                    u_xlat7.xyz = u_xlat3.xyz + u_xlat7.xxx;
                    u_xlat7.xyz = floor(u_xlat7.xyz);
                    u_xlat8.xyz = u_xlat3.xyz + (-u_xlat7.xyz);
                    u_xlat61 = dot(u_xlat7.xyz, float3(0.166666672, 0.166666672, 0.166666672));
                    u_xlat8.xyz = float3(u_xlat61) + u_xlat8.xyz;
                    u_xlatb9.xyz = greaterThanEqual(u_xlat8.zxyz, u_xlat8.xyzx).xyz;
                    u_xlat10.x = u_xlatb9.y ? float(1.0) : 0.0;
                    u_xlat10.y = u_xlatb9.z ? float(1.0) : 0.0;
                    u_xlat10.z = u_xlatb9.x ? float(1.0) : 0.0;
;
                    u_xlat9.x = (u_xlatb9.x) ? float(0.0) : float(1.0);
                    u_xlat9.y = (u_xlatb9.y) ? float(0.0) : float(1.0);
                    u_xlat9.z = (u_xlatb9.z) ? float(0.0) : float(1.0);
                    u_xlat11.xyz = min(u_xlat9.xyz, u_xlat10.xyz);
                    u_xlat9.xyz = max(u_xlat9.xyz, u_xlat10.xyz);
                    u_xlat10.xyz = u_xlat8.xyz + (-u_xlat11.xyz);
                    u_xlat10.xyz = u_xlat10.xyz + float3(0.166666672, 0.166666672, 0.166666672);
                    u_xlat12.xyz = u_xlat8.xyz + (-u_xlat9.xyz);
                    u_xlat12.xyz = u_xlat12.xyz + float3(0.333333343, 0.333333343, 0.333333343);
                    u_xlat13.xyz = u_xlat8.xyz + float3(-0.5, -0.5, -0.5);
                    u_xlat14.xyz = u_xlat7.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
                    u_xlat14.xyz = floor(u_xlat14.xyz);
                    u_xlat7.xyz = (-u_xlat14.xyz) * float3(289.0, 289.0, 289.0) + u_xlat7.xyz;
                    u_xlat4.y = u_xlat11.z;
                    u_xlat4.z = u_xlat9.z;
                    u_xlat14 = u_xlat4 + u_xlat7.zzzz;
                    u_xlat15 = u_xlat14 * u_xlat14;
                    u_xlat14 = u_xlat15 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat14;
                    u_xlat15 = u_xlat14 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
                    u_xlat15 = floor(u_xlat15);
                    u_xlat14 = (-u_xlat15) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat14;
                    u_xlat14 = u_xlat7.yyyy + u_xlat14;
                    u_xlat5.y = u_xlat11.y;
                    u_xlat5.z = u_xlat9.y;
                    u_xlat14 = u_xlat5 + u_xlat14;
                    u_xlat15 = u_xlat14 * u_xlat14;
                    u_xlat14 = u_xlat15 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat14;
                    u_xlat15 = u_xlat14 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
                    u_xlat15 = floor(u_xlat15);
                    u_xlat14 = (-u_xlat15) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat14;
                    u_xlat7 = u_xlat7.xxxx + u_xlat14;
                    u_xlat6.y = u_xlat11.x;
                    u_xlat6.z = u_xlat9.x;
                    u_xlat7 = u_xlat6 + u_xlat7;
                    u_xlat9 = u_xlat7 * u_xlat7;
                    u_xlat7 = u_xlat9 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat7;
                    u_xlat9 = u_xlat7 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
                    u_xlat9 = floor(u_xlat9);
                    u_xlat7 = (-u_xlat9) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat7;
                    u_xlat9 = u_xlat7 * float4(0.0204081647, 0.0204081647, 0.0204081647, 0.0204081647);
                    u_xlat9 = floor(u_xlat9);
                    u_xlat7 = (-u_xlat9) * float4(49.0, 49.0, 49.0, 49.0) + u_xlat7;
                    u_xlat9 = u_xlat7 * float4(0.142857149, 0.142857149, 0.142857149, 0.142857149);
                    u_xlat9 = floor(u_xlat9);
                    u_xlat7 = (-u_xlat9) * float4(7.0, 7.0, 7.0, 7.0) + u_xlat7;
                    u_xlat9 = u_xlat9 * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
                    u_xlat7 = u_xlat7.xzyw * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
                    u_xlat11 = -abs(u_xlat9) + float4(1.0, 1.0, 1.0, 1.0);
                    u_xlat11 = -abs(u_xlat7.xzwy) + u_xlat11.xywz;
                    u_xlat14.xz = floor(u_xlat9.xy);
                    u_xlat14.yw = floor(u_xlat7.xz);
                    u_xlat14 = u_xlat14 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
                    u_xlat15.xz = floor(u_xlat9.zw);
                    u_xlat15.yw = floor(u_xlat7.yw);
                    u_xlat15 = u_xlat15 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
                    u_xlatb16 = greaterThanEqual(float4(0.0, 0.0, 0.0, 0.0), u_xlat11.xywz);
                    u_xlat16.x = (u_xlatb16.x) ? float(-1.0) : float(-0.0);
                    u_xlat16.y = (u_xlatb16.y) ? float(-1.0) : float(-0.0);
                    u_xlat16.z = (u_xlatb16.z) ? float(-1.0) : float(-0.0);
                    u_xlat16.w = (u_xlatb16.w) ? float(-1.0) : float(-0.0);
                    u_xlat17.xz = u_xlat9.xy;
                    u_xlat17.yw = u_xlat7.xz;
                    u_xlat14 = u_xlat14.zwxy * u_xlat16.yyxx + u_xlat17.zwxy;
                    u_xlat7.xz = u_xlat9.zw;
                    u_xlat7 = u_xlat15 * u_xlat16.zzww + u_xlat7;
                    u_xlat9.xy = u_xlat14.zw;
                    u_xlat9.z = u_xlat11.x;
                    u_xlat22 = dot(u_xlat9.xyz, u_xlat9.xyz);
                    u_xlat14.z = u_xlat11.y;
                    u_xlat40 = dot(u_xlat14.xyz, u_xlat14.xyz);
                    u_xlat15.xy = u_xlat7.xy;
                    u_xlat15.z = u_xlat11.w;
                    u_xlat23 = dot(u_xlat15.xyz, u_xlat15.xyz);
                    u_xlat11.xy = u_xlat7.zw;
                    u_xlat41 = dot(u_xlat11.xyz, u_xlat11.xyz);
                    u_xlat22 = rsqrt(u_xlat22);
                    u_xlat40 = rsqrt(u_xlat40);
                    u_xlat23 = rsqrt(u_xlat23);
                    u_xlat41 = rsqrt(u_xlat41);
                    u_xlat7.xyz = float3(u_xlat22) * u_xlat9.xyz;
                    u_xlat9.xyz = float3(u_xlat40) * u_xlat14.xyz;
                    u_xlat14.xyz = float3(u_xlat23) * u_xlat15.xyz;
                    u_xlat11.xyz = float3(u_xlat41) * u_xlat11.xyz;
                    u_xlat15.x = dot(u_xlat8.xyz, u_xlat8.xyz);
                    u_xlat15.y = dot(u_xlat10.xyz, u_xlat10.xyz);
                    u_xlat15.z = dot(u_xlat12.xyz, u_xlat12.xyz);
                    u_xlat15.w = dot(u_xlat13.xyz, u_xlat13.xyz);
                    u_xlat15 = (-u_xlat15) + float4(0.600000024, 0.600000024, 0.600000024, 0.600000024);
                    u_xlat15 = max(u_xlat15, float4(0.0, 0.0, 0.0, 0.0));
                    u_xlat15 = u_xlat15 * u_xlat15;
                    u_xlat15 = u_xlat15 * u_xlat15;
                    u_xlat7.x = dot(u_xlat7.xyz, u_xlat8.xyz);
                    u_xlat7.y = dot(u_xlat9.xyz, u_xlat10.xyz);
                    u_xlat7.z = dot(u_xlat14.xyz, u_xlat12.xyz);
                    u_xlat7.w = dot(u_xlat11.xyz, u_xlat13.xyz);
                    u_xlat22 = dot(u_xlat15, u_xlat7);
                    u_xlat22 = u_xlat56 * u_xlat22;
                    u_xlat38.x = u_xlat22 * 42.0 + u_xlat38.x;
                    u_xlat3.xy = u_xlat3.xy * float2(u._frequency) + (-float2(u._offset.x, u._offset.y));
                    u_xlat56 = u_xlat56 * u._amp_mult;
                }
                u_xlat38.x = u_xlat37.x + u_xlat38.x;
                u_xlat2.x = u_xlat19 * u._strength + in.acScreenNorm.x;
                u_xlat2.y = u_xlat38.x * u._strength + in.acScreenNorm.y;
            } else {
                u_xlatb19 = int(u._type)==3;
                if(u_xlatb19){
                    u_xlat3.x = sin(u_xlat55);
                    u_xlat4.x = cos(u_xlat55);
                    u_xlat5.x = (-u_xlat3.x);
                    u_xlat5.y = u_xlat4.x;
                    u_xlat5.z = u_xlat3.x;
                    u_xlat2.x = dot(u_xlat5.yz, in.acScreenNorm.xy);
                    u_xlat2.y = dot(u_xlat5.xy, in.acScreenNorm.xy);
                } else {
                    u_xlatb19 = int(u._type)==4;
                    if(u_xlatb19){
                        u_xlat19 = dot(u_xlat0.xy, u_xlat0.xy);
                        u_xlat19 = rsqrt(u_xlat19);
                        u_xlat38.xy = u_xlat0.xy * float2(u_xlat19);
                        u_xlat2.xy = u_xlat38.xy * float2(u_xlat55) + in.acScreenNorm.xy;
                    } else {
                        u_xlatb19 = int(u._type)==5;
                        if(u_xlatb19){
                            u_xlat19 = u._random_seed + 6.33790016;
                            u_xlat3.z = u_xlat19 * 3937.72485 + u._evolution;
                            u_xlat4.x = float(0.0);
                            u_xlat4.w = float(1.0);
                            u_xlat5.x = float(0.0);
                            u_xlat5.w = float(1.0);
                            u_xlat6.x = float(0.0);
                            u_xlat6.w = float(1.0);
                            u_xlat3.xy = u_xlat36.xy;
                            u_xlat19 = 0.0;
                            u_xlat38.x = u._amplitude;
                            for(int u_xlati_loop_3 = 0 ; u_xlati_loop_3<u_xlati1 ; u_xlati_loop_3++)
                            {
                                u_xlat57 = dot(u_xlat3.xyz, float3(0.333333343, 0.333333343, 0.333333343));
                                u_xlat7.xyz = float3(u_xlat57) + u_xlat3.xyz;
                                u_xlat7.xyz = floor(u_xlat7.xyz);
                                u_xlat8.xyz = u_xlat3.xyz + (-u_xlat7.xyz);
                                u_xlat57 = dot(u_xlat7.xyz, float3(0.166666672, 0.166666672, 0.166666672));
                                u_xlat8.xyz = float3(u_xlat57) + u_xlat8.xyz;
                                u_xlatb9.xyz = greaterThanEqual(u_xlat8.zxyz, u_xlat8.xyzx).xyz;
                                u_xlat10.x = u_xlatb9.y ? float(1.0) : 0.0;
                                u_xlat10.y = u_xlatb9.z ? float(1.0) : 0.0;
                                u_xlat10.z = u_xlatb9.x ? float(1.0) : 0.0;
;
                                u_xlat9.x = (u_xlatb9.x) ? float(0.0) : float(1.0);
                                u_xlat9.y = (u_xlatb9.y) ? float(0.0) : float(1.0);
                                u_xlat9.z = (u_xlatb9.z) ? float(0.0) : float(1.0);
                                u_xlat11.xyz = min(u_xlat9.xyz, u_xlat10.xyz);
                                u_xlat9.xyz = max(u_xlat9.xyz, u_xlat10.xyz);
                                u_xlat10.xyz = u_xlat8.xyz + (-u_xlat11.xyz);
                                u_xlat10.xyz = u_xlat10.xyz + float3(0.166666672, 0.166666672, 0.166666672);
                                u_xlat12.xyz = u_xlat8.xyz + (-u_xlat9.xyz);
                                u_xlat12.xyz = u_xlat12.xyz + float3(0.333333343, 0.333333343, 0.333333343);
                                u_xlat13.xyz = u_xlat8.xyz + float3(-0.5, -0.5, -0.5);
                                u_xlat14.xyz = u_xlat7.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
                                u_xlat14.xyz = floor(u_xlat14.xyz);
                                u_xlat7.xyz = (-u_xlat14.xyz) * float3(289.0, 289.0, 289.0) + u_xlat7.xyz;
                                u_xlat4.y = u_xlat11.z;
                                u_xlat4.z = u_xlat9.z;
                                u_xlat14 = u_xlat4 + u_xlat7.zzzz;
                                u_xlat15 = u_xlat14 * u_xlat14;
                                u_xlat14 = u_xlat15 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat14;
                                u_xlat15 = u_xlat14 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
                                u_xlat15 = floor(u_xlat15);
                                u_xlat14 = (-u_xlat15) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat14;
                                u_xlat14 = u_xlat7.yyyy + u_xlat14;
                                u_xlat5.y = u_xlat11.y;
                                u_xlat5.z = u_xlat9.y;
                                u_xlat14 = u_xlat5 + u_xlat14;
                                u_xlat15 = u_xlat14 * u_xlat14;
                                u_xlat14 = u_xlat15 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat14;
                                u_xlat15 = u_xlat14 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
                                u_xlat15 = floor(u_xlat15);
                                u_xlat14 = (-u_xlat15) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat14;
                                u_xlat7 = u_xlat7.xxxx + u_xlat14;
                                u_xlat6.y = u_xlat11.x;
                                u_xlat6.z = u_xlat9.x;
                                u_xlat7 = u_xlat6 + u_xlat7;
                                u_xlat9 = u_xlat7 * u_xlat7;
                                u_xlat7 = u_xlat9 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat7;
                                u_xlat9 = u_xlat7 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
                                u_xlat9 = floor(u_xlat9);
                                u_xlat7 = (-u_xlat9) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat7;
                                u_xlat9 = u_xlat7 * float4(0.0204081647, 0.0204081647, 0.0204081647, 0.0204081647);
                                u_xlat9 = floor(u_xlat9);
                                u_xlat7 = (-u_xlat9) * float4(49.0, 49.0, 49.0, 49.0) + u_xlat7;
                                u_xlat9 = u_xlat7 * float4(0.142857149, 0.142857149, 0.142857149, 0.142857149);
                                u_xlat9 = floor(u_xlat9);
                                u_xlat7 = (-u_xlat9) * float4(7.0, 7.0, 7.0, 7.0) + u_xlat7;
                                u_xlat9 = u_xlat9 * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
                                u_xlat7 = u_xlat7.xzyw * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
                                u_xlat11 = -abs(u_xlat9) + float4(1.0, 1.0, 1.0, 1.0);
                                u_xlat11 = -abs(u_xlat7.xzwy) + u_xlat11.xywz;
                                u_xlat14.xz = floor(u_xlat9.xy);
                                u_xlat14.yw = floor(u_xlat7.xz);
                                u_xlat14 = u_xlat14 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
                                u_xlat15.xz = floor(u_xlat9.zw);
                                u_xlat15.yw = floor(u_xlat7.yw);
                                u_xlat15 = u_xlat15 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
                                u_xlatb16 = greaterThanEqual(float4(0.0, 0.0, 0.0, 0.0), u_xlat11.xywz);
                                u_xlat16.x = (u_xlatb16.x) ? float(-1.0) : float(-0.0);
                                u_xlat16.y = (u_xlatb16.y) ? float(-1.0) : float(-0.0);
                                u_xlat16.z = (u_xlatb16.z) ? float(-1.0) : float(-0.0);
                                u_xlat16.w = (u_xlatb16.w) ? float(-1.0) : float(-0.0);
                                u_xlat17.xz = u_xlat9.xy;
                                u_xlat17.yw = u_xlat7.xz;
                                u_xlat14 = u_xlat14.zwxy * u_xlat16.yyxx + u_xlat17.zwxy;
                                u_xlat7.xz = u_xlat9.zw;
                                u_xlat7 = u_xlat15 * u_xlat16.zzww + u_xlat7;
                                u_xlat9.xy = u_xlat14.zw;
                                u_xlat9.z = u_xlat11.x;
                                u_xlat57 = dot(u_xlat9.xyz, u_xlat9.xyz);
                                u_xlat14.z = u_xlat11.y;
                                u_xlat22 = dot(u_xlat14.xyz, u_xlat14.xyz);
                                u_xlat15.xy = u_xlat7.xy;
                                u_xlat15.z = u_xlat11.w;
                                u_xlat40 = dot(u_xlat15.xyz, u_xlat15.xyz);
                                u_xlat11.xy = u_xlat7.zw;
                                u_xlat23 = dot(u_xlat11.xyz, u_xlat11.xyz);
                                u_xlat57 = rsqrt(u_xlat57);
                                u_xlat22 = rsqrt(u_xlat22);
                                u_xlat40 = rsqrt(u_xlat40);
                                u_xlat23 = rsqrt(u_xlat23);
                                u_xlat7.xyz = float3(u_xlat57) * u_xlat9.xyz;
                                u_xlat9.xyz = float3(u_xlat22) * u_xlat14.xyz;
                                u_xlat14.xyz = float3(u_xlat40) * u_xlat15.xyz;
                                u_xlat11.xyz = float3(u_xlat23) * u_xlat11.xyz;
                                u_xlat15.x = dot(u_xlat8.xyz, u_xlat8.xyz);
                                u_xlat15.y = dot(u_xlat10.xyz, u_xlat10.xyz);
                                u_xlat15.z = dot(u_xlat12.xyz, u_xlat12.xyz);
                                u_xlat15.w = dot(u_xlat13.xyz, u_xlat13.xyz);
                                u_xlat15 = (-u_xlat15) + float4(0.600000024, 0.600000024, 0.600000024, 0.600000024);
                                u_xlat15 = max(u_xlat15, float4(0.0, 0.0, 0.0, 0.0));
                                u_xlat15 = u_xlat15 * u_xlat15;
                                u_xlat15 = u_xlat15 * u_xlat15;
                                u_xlat7.x = dot(u_xlat7.xyz, u_xlat8.xyz);
                                u_xlat7.y = dot(u_xlat9.xyz, u_xlat10.xyz);
                                u_xlat7.z = dot(u_xlat14.xyz, u_xlat12.xyz);
                                u_xlat7.w = dot(u_xlat11.xyz, u_xlat13.xyz);
                                u_xlat57 = dot(u_xlat15, u_xlat7);
                                u_xlat57 = u_xlat38.x * u_xlat57;
                                u_xlat19 = u_xlat57 * 42.0 + u_xlat19;
                                u_xlat3.xy = u_xlat3.xy * float2(u._frequency) + (-float2(u._offset.x, u._offset.y));
                                u_xlat38.x = u_xlat38.x * u._amp_mult;
                            }
                            u_xlat36.x = u_xlat37.x + u_xlat19;
                            u_xlat36.x = u_xlat36.x * u._strength;
                            u_xlat1.x = sin(u_xlat36.x);
                            u_xlat3.x = cos(u_xlat36.x);
                            u_xlat36.x = dot(u_xlat0.xy, u_xlat0.xy);
                            u_xlat36.x = rsqrt(u_xlat36.x);
                            u_xlat0.xy = u_xlat36.xx * u_xlat0.xy;
                            u_xlat0.xy = u_xlat0.xy * float2(u_xlat55) + in.acScreenNorm.xy;
                            u_xlat4.x = (-u_xlat1.x);
                            u_xlat4.y = u_xlat3.x;
                            u_xlat4.z = u_xlat1.x;
                            u_xlat2.x = dot(u_xlat4.yz, u_xlat0.xy);
                            u_xlat2.y = dot(u_xlat4.xy, u_xlat0.xy);
                        } else {
                            u_xlat2.xy = in.acScreenNorm.xy;
                        }
                    }
                }
            }
        }
    }
    u_xlatb0 = int(u._keep_edge)==1;
    u_xlat18.xy = u_xlat2.xy + float2(-0.5, -0.5);
    u_xlat18.xy = u_xlat18.xy * float2(1.00100005, 1.00100005) + float2(0.5, 0.5);
    u_xlatb1.xy = lessThan(u_xlat18.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb37.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat18.xyxy).xy;
    u_xlat38.xy = fract(u_xlat18.xy);
    u_xlat38.xy = (-u_xlat38.xy) + float2(1.0, 1.0);
    u_xlat37.x = (u_xlatb37.x) ? u_xlat38.x : u_xlat18.x;
    u_xlat37.y = (u_xlatb37.y) ? u_xlat38.y : u_xlat18.y;
    {
        float2 hlslcc_movcTemp = u_xlat18;
        hlslcc_movcTemp.x = (u_xlatb1.x) ? (-u_xlat18.x) : u_xlat37.x;
        hlslcc_movcTemp.y = (u_xlatb1.y) ? (-u_xlat18.y) : u_xlat37.y;
        u_xlat18 = hlslcc_movcTemp;
    }
    u_xlat18.xy = u_xlat18.xy + float2(-0.5, -0.5);
    u_xlat18.xy = u_xlat18.xy * float2(0.999000967, 0.999000967) + float2(0.5, 0.5);
    u_xlat0.xy = (bool(u_xlatb0)) ? u_xlat18.xy : u_xlat2.xy;
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
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
