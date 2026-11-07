// ---------------------------------------------------------------------------
// Rendercommand Blend (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-blend.xml
// id     : nv.effect.nodevideo-rendercommand-blend
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_blendParams {
    float _blend_mode;
    float _opacity;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float3 u_xlat1;
float3 u_xlat16_2;
float3 u_xlat3;
float4 u_xlat4;
bool3 u_xlatb4;
float3 u_xlat5;
bool2 u_xlatb5;
float3 u_xlat6;
float3 u_xlat7;
float u_xlat12;
bool u_xlatb13;
bool u_xlatb20;
float u_xlat24;
float u_xlat25;
int u_xlati27;
float u_xlat28;
bool u_xlatb28;

fragment float4 fx_nv_nodevideo_rendercommand_blend(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_blendParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> dst [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.xyz = dst.sample(__nv_smp, in.acScreenNorm.xy).xyz;
    u_xlat16_2.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
    u_xlat0.xyz = log2(u_xlat16_2.xyz);
    u_xlat0.xyz = u_xlat0.xyz * float3(0.416666657, 0.416666657, 0.416666657);
    u_xlat0.xyz = exp2(u_xlat0.xyz);
    u_xlat0.xyz = u_xlat0.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
    u_xlat0.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
    u_xlat16_2.xyz = max(u_xlat1.xyz, float3(0.0, 0.0, 0.0));
    u_xlat1.xyz = log2(u_xlat16_2.xyz);
    u_xlat1.xyz = u_xlat1.xyz * float3(0.416666657, 0.416666657, 0.416666657);
    u_xlat1.xyz = exp2(u_xlat1.xyz);
    u_xlat1.xyz = u_xlat1.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
    u_xlat1.xyz = max(u_xlat1.xyz, float3(0.0, 0.0, 0.0));
    u_xlat25 = u_xlat0.w * u._opacity;
    if(int(u._blend_mode) == 0) {
        u_xlat3.x = (-u_xlat0.w) * u._opacity + 1.0;
        u_xlat3.xyz = u_xlat1.xyz * u_xlat3.xxx;
        u_xlat3.xyz = u_xlat0.xyz * float3(u_xlat25) + u_xlat3.xyz;
        u_xlati27 = int(0xFFFFFFFFu);
    } else {
        u_xlatb4.x = int(u._blend_mode)==1;
        if(u_xlatb4.x){
            u_xlat4.x = u_xlat25 * u._opacity;
            u_xlat12 = dot(in.acScreenNorm.xy, float2(12.9898005, 78.2330017));
            u_xlat12 = sin(u_xlat12);
            u_xlat12 = u_xlat12 * 43758.5469;
            u_xlat12 = fract(u_xlat12);
            u_xlatb4.x = u_xlat4.x<u_xlat12;
            u_xlat3.xyz = (u_xlatb4.x) ? u_xlat1.xyz : u_xlat0.xyz;
            u_xlati27 = int(0xFFFFFFFFu);
        } else {
            u_xlatb4.x = int(u._blend_mode)==2;
            if(u_xlatb4.x){
                u_xlat4.xyz = float3(u_xlat25) * u_xlat1.xyz;
                u_xlat3.xyz = min(u_xlat0.xyz, u_xlat4.xyz);
                u_xlati27 = int(0xFFFFFFFFu);
            } else {
                u_xlatb4.x = int(u._blend_mode)==3;
                if(u_xlatb4.x){
                    u_xlat3.xyz = u_xlat0.xyz * u_xlat1.xyz;
                    u_xlati27 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb4.x = int(u._blend_mode)==4;
                    if(u_xlatb4.x){
                        u_xlat4.xyz = (-u_xlat1.xyz) * float3(u_xlat25) + float3(1.0, 1.0, 1.0);
                        u_xlat4.xyz = u_xlat4.xyz / u_xlat0.xyz;
                        u_xlat3.xyz = (-u_xlat4.xyz) + float3(1.0, 1.0, 1.0);
                        u_xlati27 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb4.x = int(u._blend_mode)==5;
                        if(u_xlatb4.x){
                            u_xlat4.xyz = u_xlat0.xyz + u_xlat1.xyz;
                            u_xlat3.xyz = u_xlat4.xyz + float3(-1.0, -1.0, -1.0);
                            u_xlati27 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb4.x = int(u._blend_mode)==6;
                            if(u_xlatb4.x){
                                u_xlat4.xyz = float3(u_xlat25) * u_xlat1.xyz;
                                u_xlat5.xyz = u_xlat0.xyz * float3(0.212599993, 0.715200007, 0.0722000003);
                                u_xlat28 = dot(u_xlat5.xyz, u_xlat5.xyz);
                                u_xlat28 = sqrt(u_xlat28);
                                u_xlat5.xyz = u_xlat4.xyz * float3(0.212599993, 0.715200007, 0.0722000003);
                                u_xlat5.x = dot(u_xlat5.xyz, u_xlat5.xyz);
                                u_xlat5.x = sqrt(u_xlat5.x);
                                u_xlatb28 = u_xlat5.x<u_xlat28;
                                u_xlat3.xyz = (bool(u_xlatb28)) ? u_xlat4.xyz : u_xlat0.xyz;
                                u_xlati27 = int(0xFFFFFFFFu);
                            } else {
                                u_xlatb4.x = int(u._blend_mode)==7;
                                if(u_xlatb4.x){
                                    u_xlat3.xyz = max(u_xlat0.xyz, u_xlat1.xyz);
                                    u_xlati27 = int(0xFFFFFFFFu);
                                } else {
                                    u_xlatb4.x = int(u._blend_mode)==8;
                                    if(u_xlatb4.x){
                                        u_xlat4.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                        u_xlat5.xyz = (-u_xlat0.xyz) + float3(1.0, 1.0, 1.0);
                                        u_xlat3.xyz = (-u_xlat4.xyz) * u_xlat5.xyz + float3(1.0, 1.0, 1.0);
                                        u_xlati27 = int(0xFFFFFFFFu);
                                    } else {
                                        u_xlatb4.x = int(u._blend_mode)==9;
                                        if(u_xlatb4.x){
                                            u_xlat4.xyz = float3(u_xlat25) * u_xlat1.xyz;
                                            u_xlat5.xyz = (-u_xlat0.xyz) + float3(1.0, 1.0, 1.0);
                                            u_xlat3.xyz = u_xlat4.xyz / u_xlat5.xyz;
                                            u_xlati27 = int(0xFFFFFFFFu);
                                        } else {
                                            u_xlatb4.x = int(u._blend_mode)==10;
                                            if(u_xlatb4.x){
                                                u_xlat3.xyz = u_xlat1.xyz * float3(u_xlat25) + u_xlat0.xyz;
                                                u_xlati27 = int(0xFFFFFFFFu);
                                            } else {
                                                u_xlatb4.x = int(u._blend_mode)==11;
                                                if(u_xlatb4.x){
                                                    u_xlat4.xyz = float3(u_xlat25) * u_xlat1.xyz;
                                                    u_xlat5.xyz = u_xlat0.xyz * float3(0.212599993, 0.715200007, 0.0722000003);
                                                    u_xlat28 = dot(u_xlat5.xyz, u_xlat5.xyz);
                                                    u_xlat28 = sqrt(u_xlat28);
                                                    u_xlat5.xyz = u_xlat4.xyz * float3(0.212599993, 0.715200007, 0.0722000003);
                                                    u_xlat5.x = dot(u_xlat5.xyz, u_xlat5.xyz);
                                                    u_xlat5.x = sqrt(u_xlat5.x);
                                                    u_xlatb28 = u_xlat5.x<u_xlat28;
                                                    u_xlat3.xyz = (bool(u_xlatb28)) ? u_xlat0.xyz : u_xlat4.xyz;
                                                    u_xlati27 = int(0xFFFFFFFFu);
                                                } else {
                                                    u_xlatb4.x = int(u._blend_mode)==12;
                                                    if(u_xlatb4.x){
                                                        u_xlatb4.xyz = lessThan(u_xlat1.xyzx, float4(0.5, 0.5, 0.5, 0.0)).xyz;
                                                        u_xlat28 = dot(u_xlat0.xx, u_xlat1.xx);
                                                        u_xlat5.xyz = (-u_xlat0.xyz) + float3(1.0, 1.0, 1.0);
                                                        u_xlat5.xyz = u_xlat5.xyz + u_xlat5.xyz;
                                                        u_xlat6.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                                        u_xlat5.xyz = (-u_xlat5.xyz) * u_xlat6.xyz + float3(1.0, 1.0, 1.0);
                                                        u_xlat3.x = (u_xlatb4.x) ? u_xlat28 : u_xlat5.x;
                                                        u_xlat4.x = dot(u_xlat0.yy, u_xlat1.yy);
                                                        u_xlat3.y = (u_xlatb4.y) ? u_xlat4.x : u_xlat5.y;
                                                        u_xlat4.x = dot(u_xlat0.zz, u_xlat1.zz);
                                                        u_xlat3.z = (u_xlatb4.z) ? u_xlat4.x : u_xlat5.z;
                                                        u_xlati27 = int(0xFFFFFFFFu);
                                                    } else {
                                                        u_xlatb4.x = int(u._blend_mode)==13;
                                                        if(u_xlatb4.x){
                                                            u_xlat4.xyz = u_xlat0.xyz * u_xlat1.xyz;
                                                            u_xlat5.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                                            u_xlat6.xyz = (-u_xlat0.xyz) + float3(1.0, 1.0, 1.0);
                                                            u_xlat6.xyz = (-u_xlat5.xyz) * u_xlat6.xyz + float3(1.0, 1.0, 1.0);
                                                            u_xlat6.xyz = u_xlat1.xyz * u_xlat6.xyz;
                                                            u_xlat3.xyz = u_xlat5.xyz * u_xlat4.xyz + u_xlat6.xyz;
                                                            u_xlati27 = int(0xFFFFFFFFu);
                                                        } else {
                                                            u_xlatb4.x = int(u._blend_mode)==14;
                                                            if(u_xlatb4.x){
                                                                u_xlatb4.xyz = lessThan(float4(0.5, 0.5, 0.5, 0.0), u_xlat0.xyzx).xyz;
                                                                u_xlat5.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                                                u_xlat6.xyz = u_xlat0.xyz + float3(-0.5, -0.5, -0.5);
                                                                u_xlat6.xyz = (-u_xlat6.xyz) * float3(2.0, 2.0, 2.0) + float3(1.0, 1.0, 1.0);
                                                                u_xlat5.xyz = (-u_xlat5.xyz) * u_xlat6.xyz + float3(1.0, 1.0, 1.0);
                                                                u_xlat5.xyz = min(u_xlat5.xyz, float3(1.0, 1.0, 1.0));
                                                                u_xlat28 = dot(u_xlat0.xx, u_xlat1.xx);
                                                                u_xlat28 = min(u_xlat28, 1.0);
                                                                u_xlat3.x = (u_xlatb4.x) ? u_xlat5.x : u_xlat28;
                                                                u_xlat4.x = dot(u_xlat0.yy, u_xlat1.yy);
                                                                u_xlat4.x = min(u_xlat4.x, 1.0);
                                                                u_xlat3.y = (u_xlatb4.y) ? u_xlat5.y : u_xlat4.x;
                                                                u_xlat4.x = dot(u_xlat0.zz, u_xlat1.zz);
                                                                u_xlat4.x = min(u_xlat4.x, 1.0);
                                                                u_xlat3.z = (u_xlatb4.z) ? u_xlat5.z : u_xlat4.x;
                                                                u_xlati27 = int(0xFFFFFFFFu);
                                                            } else {
                                                                u_xlatb4.x = int(u._blend_mode)==15;
                                                                if(u_xlatb4.x){
                                                                    u_xlatb4.xyz = greaterThanEqual(float4(0.5, 0.5, 0.5, 0.0), u_xlat0.xyzx).xyz;
                                                                    u_xlat5.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                                                    u_xlat6.xyz = u_xlat0.xyz + u_xlat0.xyz;
                                                                    u_xlat5.xyz = u_xlat5.xyz / u_xlat6.xyz;
                                                                    u_xlat5.xyz = (-u_xlat5.xyz) + float3(1.0, 1.0, 1.0);
                                                                    u_xlat5.xyz = max(u_xlat5.xyz, float3(0.0, 0.0, 0.0));
                                                                    u_xlat6.xyz = (-u_xlat0.xyz) + float3(1.0, 1.0, 1.0);
                                                                    u_xlat6.xyz = u_xlat6.xyz + u_xlat6.xyz;
                                                                    u_xlat6.xyz = u_xlat1.xyz / u_xlat6.xyz;
                                                                    u_xlat6.xyz = min(u_xlat6.xyz, float3(1.0, 1.0, 1.0));
                                                                    u_xlat3.x = (u_xlatb4.x) ? u_xlat5.x : u_xlat6.x;
                                                                    u_xlat3.y = (u_xlatb4.y) ? u_xlat5.y : u_xlat6.y;
                                                                    u_xlat3.z = (u_xlatb4.z) ? u_xlat5.z : u_xlat6.z;
                                                                    u_xlati27 = int(0xFFFFFFFFu);
                                                                } else {
                                                                    u_xlatb4.x = int(u._blend_mode)==16;
                                                                    if(u_xlatb4.x){
                                                                        u_xlatb4.xyz = greaterThanEqual(float4(0.5, 0.5, 0.5, 0.0), u_xlat0.xyzx).xyz;
                                                                        u_xlat5.xyz = u_xlat0.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
                                                                        u_xlat5.xyz = u_xlat5.xyz + float3(-1.0, -1.0, -1.0);
                                                                        u_xlat6.xyz = u_xlat0.xyz + float3(-0.5, -0.5, -0.5);
                                                                        u_xlat6.xyz = u_xlat6.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
                                                                        u_xlat3.x = (u_xlatb4.x) ? u_xlat5.x : u_xlat6.x;
                                                                        u_xlat3.y = (u_xlatb4.y) ? u_xlat5.y : u_xlat6.y;
                                                                        u_xlat3.z = (u_xlatb4.z) ? u_xlat5.z : u_xlat6.z;
                                                                        u_xlati27 = int(0xFFFFFFFFu);
                                                                    } else {
                                                                        u_xlatb4.x = int(u._blend_mode)==17;
                                                                        if(u_xlatb4.x){
                                                                            u_xlatb4.xyz = lessThan(float4(0.5, 0.5, 0.5, 0.0), u_xlat0.xyzx).xyz;
                                                                            u_xlat5.xyz = u_xlat0.xyz + float3(-0.5, -0.5, -0.5);
                                                                            u_xlat5.xyz = u_xlat5.xyz + u_xlat5.xyz;
                                                                            u_xlat5.xyz = max(u_xlat1.xyz, u_xlat5.xyz);
                                                                            u_xlat6.xyz = u_xlat0.xyz + u_xlat0.xyz;
                                                                            u_xlat6.xyz = min(u_xlat1.xyz, u_xlat6.xyz);
                                                                            u_xlat3.x = (u_xlatb4.x) ? u_xlat5.x : u_xlat6.x;
                                                                            u_xlat3.y = (u_xlatb4.y) ? u_xlat5.y : u_xlat6.y;
                                                                            u_xlat3.z = (u_xlatb4.z) ? u_xlat5.z : u_xlat6.z;
                                                                            u_xlati27 = int(0xFFFFFFFFu);
                                                                        } else {
                                                                            u_xlatb4.x = int(u._blend_mode)==18;
                                                                            if(u_xlatb4.x){
                                                                                u_xlat4.xyz = u_xlat0.xyz + u_xlat1.xyz;
                                                                                u_xlatb4.xyz = lessThan(u_xlat4.xyzx, float4(1.0, 1.0, 1.0, 0.0)).xyz;
                                                                                u_xlat3.x = (u_xlatb4.x) ? float(0.0) : float(1.0);
                                                                                u_xlat3.y = (u_xlatb4.y) ? float(0.0) : float(1.0);
                                                                                u_xlat3.z = (u_xlatb4.z) ? float(0.0) : float(1.0);
                                                                                u_xlati27 = int(0xFFFFFFFFu);
                                                                            } else {
                                                                                u_xlatb4.x = int(u._blend_mode)==19;
                                                                                if(u_xlatb4.x){
                                                                                    u_xlat3.xyz = u_xlat1.xyz * float3(u_xlat25) + (-u_xlat0.xyz);
                                                                                    u_xlat3.xyz = abs(u_xlat3.xyz);
                                                                                    u_xlati27 = int(0xFFFFFFFFu);
                                                                                } else {
                                                                                    u_xlatb4.x = int(u._blend_mode)==20;
                                                                                    if(u_xlatb4.x){
                                                                                        u_xlat4.xyz = u_xlat1.xyz * float3(u_xlat25) + float3(-0.5, -0.5, -0.5);
                                                                                        u_xlat4.xyz = u_xlat4.xyz + u_xlat4.xyz;
                                                                                        u_xlat5.xyz = u_xlat0.xyz + float3(-0.5, -0.5, -0.5);
                                                                                        u_xlat3.xyz = (-u_xlat4.xyz) * u_xlat5.xyz + float3(0.5, 0.5, 0.5);
                                                                                        u_xlati27 = int(0xFFFFFFFFu);
                                                                                    } else {
                                                                                        u_xlatb4.x = int(u._blend_mode)==21;
                                                                                        if(u_xlatb4.x){
                                                                                            u_xlat3.xyz = (-u_xlat0.xyz) + u_xlat1.xyz;
                                                                                            u_xlati27 = int(0xFFFFFFFFu);
                                                                                        } else {
                                                                                            u_xlatb4.x = int(u._blend_mode)==22;
                                                                                            if(u_xlatb4.x){
                                                                                                u_xlat4.xyz = float3(u_xlat25) * u_xlat1.xyz;
                                                                                                u_xlat3.xyz = u_xlat4.xyz / u_xlat0.xyz;
                                                                                                u_xlati27 = int(0xFFFFFFFFu);
                                                                                            } else {
                                                                                                u_xlatb4.x = int(u._blend_mode)==23;
                                                                                                if(u_xlatb4.x){
                                                                                                    u_xlat4.x = min(u_xlat0.y, u_xlat0.x);
                                                                                                    u_xlat4.x = min(u_xlat0.z, u_xlat4.x);
                                                                                                    u_xlat12 = max(u_xlat0.y, u_xlat0.x);
                                                                                                    u_xlat12 = max(u_xlat0.z, u_xlat12);
                                                                                                    u_xlat4.x = (-u_xlat4.x) + u_xlat12;
                                                                                                    u_xlatb20 = 9.99999975e-05<u_xlat4.x;
                                                                                                    u_xlat28 = min(u_xlat1.y, u_xlat1.x);
                                                                                                    u_xlat28 = min(u_xlat1.z, u_xlat28);
                                                                                                    u_xlat5.x = max(u_xlat1.y, u_xlat1.x);
                                                                                                    u_xlat5.x = max(u_xlat1.z, u_xlat5.x);
                                                                                                    u_xlat28 = (-u_xlat28) + u_xlat5.x;
                                                                                                    u_xlatb13 = float4(0.0, 0.0, 0.0, 0.0)!=float4(u_xlat5.x);
                                                                                                    u_xlat28 = u_xlat28 / u_xlat5.x;
                                                                                                    u_xlat28 = u_xlatb13 ? u_xlat28 : float(0.0);
                                                                                                    u_xlat28 = u_xlat5.x * u_xlat28;
                                                                                                    u_xlat4.x = u_xlat28 / u_xlat4.x;
                                                                                                    u_xlat12 = (-u_xlat12) * u_xlat4.x + u_xlat5.x;
                                                                                                    u_xlat4.xyw = u_xlat0.xyz * u_xlat4.xxx + float3(u_xlat12);
                                                                                                    u_xlat3.xyz = (bool(u_xlatb20)) ? u_xlat4.xyw : u_xlat1.xyz;
                                                                                                    u_xlati27 = int(0xFFFFFFFFu);
                                                                                                } else {
                                                                                                    u_xlatb4.x = int(u._blend_mode)==24;
                                                                                                    if(u_xlatb4.x){
                                                                                                        u_xlat4.x = min(u_xlat1.y, u_xlat1.x);
                                                                                                        u_xlat4.x = min(u_xlat1.z, u_xlat4.x);
                                                                                                        u_xlat12 = max(u_xlat1.y, u_xlat1.x);
                                                                                                        u_xlat12 = max(u_xlat1.z, u_xlat12);
                                                                                                        u_xlat4.x = (-u_xlat4.x) + u_xlat12;
                                                                                                        u_xlatb20 = 9.99999975e-05<u_xlat4.x;
                                                                                                        u_xlat28 = min(u_xlat0.y, u_xlat0.x);
                                                                                                        u_xlat28 = min(u_xlat0.z, u_xlat28);
                                                                                                        u_xlat5.x = max(u_xlat0.y, u_xlat0.x);
                                                                                                        u_xlat5.x = max(u_xlat0.z, u_xlat5.x);
                                                                                                        u_xlat28 = (-u_xlat28) + u_xlat5.x;
                                                                                                        u_xlatb13 = float4(0.0, 0.0, 0.0, 0.0)!=float4(u_xlat5.x);
                                                                                                        u_xlat28 = u_xlat28 / u_xlat5.x;
                                                                                                        u_xlat28 = u_xlatb13 ? u_xlat28 : float(0.0);
                                                                                                        u_xlat28 = u_xlat12 * u_xlat28;
                                                                                                        u_xlat4.x = u_xlat28 / u_xlat4.x;
                                                                                                        u_xlat28 = (-u_xlat4.x) + 1.0;
                                                                                                        u_xlat28 = u_xlat12 * u_xlat28;
                                                                                                        u_xlat5.xyz = u_xlat1.xyz * u_xlat4.xxx + float3(u_xlat28);
                                                                                                        u_xlat3.xyz = (bool(u_xlatb20)) ? u_xlat5.xyz : float3(u_xlat12);
                                                                                                        u_xlati27 = int(0xFFFFFFFFu);
                                                                                                    } else {
                                                                                                        u_xlat4.xyz = float3(u_xlat25) * u_xlat1.xyz;
                                                                                                        u_xlat5.x = dot(float3(0.298999995, 0.587000012, 0.114), u_xlat4.xyz);
                                                                                                        u_xlat5.y = dot(float3(-0.147129998, -0.288859993, 0.43599999), u_xlat0.xyz);
                                                                                                        u_xlat5.z = dot(float3(0.61500001, -0.514989972, -0.10001), u_xlat0.xyz);
                                                                                                        u_xlat6.x = dot(float2(1.0, 1.13982999), u_xlat5.xz);
                                                                                                        u_xlat6.y = dot(float3(1.0, -0.394650012, -0.580600023), u_xlat5.xyz);
                                                                                                        u_xlat6.z = dot(float2(1.0, 2.03210998), u_xlat5.xy);
                                                                                                        u_xlatb5.xy = equal(int4(int(u._blend_mode)), int4(25, 26, 0, 0)).xy;
                                                                                                        u_xlat7.x = dot(float3(0.298999995, 0.587000012, 0.114), u_xlat0.xyz);
                                                                                                        u_xlat7.y = dot(float3(-0.147129998, -0.288859993, 0.43599999), u_xlat4.xyz);
                                                                                                        u_xlat7.z = dot(float3(0.61500001, -0.514989972, -0.10001), u_xlat4.xyz);
                                                                                                        u_xlat4.x = dot(float2(1.0, 1.13982999), u_xlat7.xz);
                                                                                                        u_xlat4.y = dot(float3(1.0, -0.394650012, -0.580600023), u_xlat7.xyz);
                                                                                                        u_xlat4.z = dot(float2(1.0, 2.03210998), u_xlat7.xy);
                                                                                                        u_xlat3.xyz = (u_xlatb5.x) ? u_xlat6.xyz : u_xlat4.xyz;
                                                                                                        u_xlati27 = int(uint((uint(u_xlatb5.y) * 0xffffffffu) | (uint(u_xlatb5.x) * 0xffffffffu)));
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    u_xlat24 = (-u_xlat0.w) * u._opacity + 1.0;
    u_xlat1.xyz = u_xlat1.xyz * float3(u_xlat24);
    u_xlat0.xyz = u_xlat0.xyz * float3(u_xlat25) + u_xlat1.xyz;
    u_xlat0.xyz = (int(u_xlati27) != 0) ? u_xlat3.xyz : u_xlat0.xyz;
    u_xlat0.xyz = clamp(u_xlat0.xyz, 0.0, 1.0);
    u_xlat1.xyz = u_xlat0.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    __nv_out.xyz = u_xlat0.xyz * u_xlat1.xyz;
    __nv_out.w = u_xlat25;
    return __nv_out;
    return __nv_out;
}
