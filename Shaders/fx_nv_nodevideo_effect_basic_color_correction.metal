// ---------------------------------------------------------------------------
// Effect Basic Color Correction (NV)
// origem : assets/effects/nv-nodevideo-effect-basic-color-correction.xml
// id     : nv.effect.nodevideo-effect-basic-color-correction
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_basic_color_correctionParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _temperature;
    float _tint;
    float _exposure;
    float _gamma;
    float _contrast;
    float _highlights;
    float _shadows;
    float _whites;
    float _blacks;
    float _saturation;
    float _sharpen;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool3 u_xlatb2;
float4 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
bool2 u_xlatb5;
float3 u_xlat6;
bool2 u_xlatb7;
float u_xlat9;
bool2 u_xlatb9;
float u_xlat10;
bool u_xlatb10;
float u_xlat11;
bool u_xlatb11;
float2 u_xlat12;
bool u_xlatb12;
float3 u_xlat13;
float u_xlat18;
bool u_xlatb18;
float2 u_xlat19;
bool2 u_xlatb19;
bool u_xlatb21;
float u_xlat25;
float u_xlat26;
bool u_xlatb26;
float u_xlat27;
bool u_xlatb27;
float u_xlat28;

fragment float4 fx_nv_nodevideo_effect_basic_color_correction(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_basic_color_correctionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb1 = 0.00100000005<u._sharpen;
    if(u_xlatb1){
        u_xlat1.xy = float2(1.0, 1.0) / _resolution.xy;
        u_xlat2.xy = (-u_xlat1.yx);
        u_xlat2.z = 0.0;
        u_xlat2 = u_xlat2.zxyz + in.acScreenNorm.xyxy;
        u_xlat3.xyz = inputImg.sample(__nv_smp, u_xlat2.xy).xyz;
        u_xlat3.xyz = u_xlat0.xyz * float3(5.0, 5.0, 5.0) + (-u_xlat3.xyz);
        u_xlat2.xyz = inputImg.sample(__nv_smp, u_xlat2.zw).xyz;
        u_xlat2.xyz = (-u_xlat2.xyz) + u_xlat3.xyz;
        u_xlat1.z = 0.0;
        u_xlat1 = u_xlat1.xzzy + in.acScreenNorm.xyxy;
        u_xlat3.xyz = inputImg.sample(__nv_smp, u_xlat1.xy).xyz;
        u_xlat2.xyz = u_xlat2.xyz + (-u_xlat3.xyz);
        u_xlat1.xyz = inputImg.sample(__nv_smp, u_xlat1.zw).xyz;
        u_xlat1.xyz = (-u_xlat1.xyz) + u_xlat2.xyz;
        u_xlat1.xyz = (-u_xlat0.xyz) + u_xlat1.xyz;
        u_xlat1.xyz = float3(float3(u._sharpen, u._sharpen, u._sharpen)) * u_xlat1.xyz + u_xlat0.xyz;
    } else {
        u_xlat1.xyz = u_xlat0.xyz;
    }
    u_xlat25 = u._temperature * 1.66666675;
    u_xlat2.xy = float2(float2(u._exposure, u._exposure)) * float2(0.971000016, 0.971000016) + float2(0.00899999961, 1.00899994);
    u_xlatb18 = u_xlat2.x<0.0;
    u_xlat3.xyz = u_xlat1.xyz * u_xlat2.yyy;
    u_xlat4.xyz = u_xlat2.yyy * (-u_xlat1.xyz) + u_xlat1.xyz;
    u_xlat4.xyz = (-u_xlat4.xyz) * float3(0.899999976, 0.899999976, 0.899999976) + float3(1.0, 1.0, 1.0);
    u_xlat3.xyz = u_xlat3.xyz / u_xlat4.xyz;
    u_xlat3.xyz = min(u_xlat3.xyz, float3(1.0, 1.0, 1.0));
    u_xlat4.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat4.xyz = u_xlat2.xxx * u_xlat4.xyz + u_xlat1.xyz;
    u_xlat5.xyz = log2(abs(u_xlat1.xyz));
    u_xlat5.xyz = u_xlat5.xyz * float3(1.42857146, 1.42857146, 1.42857146);
    u_xlat5.xyz = exp2(u_xlat5.xyz);
    u_xlat5.xyz = u_xlat5.xyz + float3(-1.0, -1.0, -1.0);
    u_xlat2.xyw = u_xlat2.xxx * u_xlat5.xyz + float3(1.0, 1.0, 1.0);
    u_xlat4.xyz = (-u_xlat4.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat2.xyw = u_xlat4.xyz / u_xlat2.xyw;
    u_xlat2.xyw = (-u_xlat2.xyw) + float3(1.0, 1.0, 1.0);
    u_xlat2.xyw = max(u_xlat2.xyw, float3(0.0, 0.0, 0.0));
    u_xlat2.xyz = (bool(u_xlatb18)) ? u_xlat3.xyz : u_xlat2.xyw;
    u_xlat26 = min(u_xlat1.y, u_xlat1.x);
    u_xlat26 = min(u_xlat1.z, u_xlat26);
    u_xlat3.x = max(u_xlat1.y, u_xlat1.x);
    u_xlat3.x = max(u_xlat1.z, u_xlat3.x);
    u_xlatb11 = u_xlat26<u_xlat3.x;
    if(u_xlatb11){
        u_xlat11 = min(u_xlat2.y, u_xlat2.x);
        u_xlat11 = min(u_xlat2.z, u_xlat11);
        u_xlat19.x = max(u_xlat2.y, u_xlat2.x);
        u_xlat19.x = max(u_xlat2.z, u_xlat19.x);
        u_xlat4.z = (-u_xlat11) + u_xlat19.x;
        u_xlatb11 = u_xlat1.x==u_xlat26;
        u_xlatb19.x = u_xlat1.z==u_xlat3.x;
        u_xlatb27 = u_xlatb19.x && u_xlatb11;
        if(u_xlatb27){
            u_xlat27 = u_xlat1.y + (-u_xlat26);
            u_xlat27 = u_xlat4.z * u_xlat27;
            u_xlat5.x = (-u_xlat26) + u_xlat3.x;
            u_xlat4.y = u_xlat27 / u_xlat5.x;
            u_xlat4.x = 0.0;
        } else {
            u_xlatb5.xy = equal(u_xlat1.yxyy, u_xlat3.xxxx).xy;
            u_xlatb11 = u_xlatb11 && u_xlatb5.x;
            u_xlat5.xzw = u_xlat1.zxy + (-float3(u_xlat26));
            u_xlat5.xzw = u_xlat4.zzz * u_xlat5.xzw;
            u_xlat1.x = (-u_xlat26) + u_xlat3.x;
            u_xlatb9.xy = equal(u_xlat1.yzyy, float4(u_xlat26)).xy;
            u_xlatb26 = u_xlatb19.x && u_xlatb9.x;
            u_xlatb9.x = u_xlatb5.y && u_xlatb9.x;
            u_xlatb9.y = u_xlatb5.y && u_xlatb9.y;
            u_xlat3.xzw = u_xlat5.zwx / u_xlat1.xxx;
            u_xlat4.y = 0.0;
            u_xlat4.xw = u_xlat3.zx;
            u_xlat5.xyz = (u_xlatb9.y) ? u_xlat4.zxy : u_xlat4.wzy;
            u_xlat3.xz = u_xlat4.yz;
            u_xlat1.xyz = (u_xlatb9.x) ? u_xlat3.zxw : u_xlat5.xyz;
            u_xlat1.xyz = (bool(u_xlatb26)) ? u_xlat4.wyz : u_xlat1.xyz;
            u_xlat4.xyz = (bool(u_xlatb11)) ? u_xlat3.xzw : u_xlat1.xyz;
        }
    } else {
        u_xlat4.x = float(0.0);
        u_xlat4.y = float(0.0);
        u_xlat4.z = float(0.0);
    }
    u_xlat1.x = dot(u_xlat2.xyz, float3(0.298999995, 0.587000012, 0.114));
    u_xlat9 = dot(u_xlat4.xyz, float3(0.298999995, 0.587000012, 0.114));
    u_xlat1.x = (-u_xlat9) + u_xlat1.x;
    u_xlat1.xyz = u_xlat1.xxx + u_xlat4.xyz;
    u_xlat2.xy = u_xlat1.xy * float2(0.298999995, 0.587000012);
    u_xlat2.x = u_xlat2.y + u_xlat2.x;
    u_xlat2.x = u_xlat1.z * 0.114 + u_xlat2.x;
    u_xlat10 = min(u_xlat1.y, u_xlat1.x);
    u_xlat10 = min(u_xlat1.z, u_xlat10);
    u_xlat18 = max(u_xlat1.y, u_xlat1.x);
    u_xlat18 = max(u_xlat1.z, u_xlat18);
    u_xlatb26 = u_xlat10<0.0;
    u_xlat3.xyz = u_xlat1.xyz + (-u_xlat2.xxx);
    u_xlat3.xyz = u_xlat2.xxx * u_xlat3.xyz;
    u_xlat10 = (-u_xlat10) + u_xlat2.x;
    u_xlat3.xyz = u_xlat3.xyz / float3(u_xlat10);
    u_xlat3.xyz = u_xlat2.xxx + u_xlat3.xyz;
    u_xlat1.xyz = (bool(u_xlatb26)) ? u_xlat3.xyz : u_xlat1.xyz;
    u_xlatb10 = 1.0<u_xlat18;
    u_xlat3.xyz = (-u_xlat2.xxx) + u_xlat1.xyz;
    u_xlat26 = (-u_xlat2.x) + 1.0;
    u_xlat3.xyz = float3(u_xlat26) * u_xlat3.xyz;
    u_xlat18 = (-u_xlat2.x) + u_xlat18;
    u_xlat3.xyz = u_xlat3.xyz / float3(u_xlat18);
    u_xlat2.xzw = u_xlat2.xxx + u_xlat3.xyz;
    u_xlat1.xyz = (bool(u_xlatb10)) ? u_xlat2.xzw : u_xlat1.xyz;
    u_xlat2.x = u._gamma + 1.0;
    u_xlat2.x = (-u_xlat2.x) * 0.5 + 1.0;
    u_xlat10 = u_xlat2.x + u_xlat2.x;
    u_xlatb18 = u_xlat2.x>=0.5;
    u_xlat2.x = u_xlat2.x * 2.0 + -1.0;
    u_xlat26 = (-u_xlat2.x) + 1.0;
    u_xlat2.x = u_xlat2.x * 0.933200002;
    u_xlat2.x = u_xlat26 * 0.5 + u_xlat2.x;
    u_xlat2.x = log2(u_xlat2.x);
    u_xlat2.x = u_xlat2.x * 0.693147182;
    u_xlat2.x = -0.693147182 / u_xlat2.x;
    u_xlat2.x = (u_xlatb18) ? u_xlat2.x : u_xlat10;
    u_xlat2.x = max(u_xlat2.x, 0.00100000005);
    u_xlat2.x = min(u_xlat2.x, 10.0);
    u_xlat1.xyz = log2(abs(u_xlat1.xyz));
    u_xlat1.xyz = u_xlat1.xyz * u_xlat2.xxx;
    u_xlat1.xyz = exp2(u_xlat1.xyz);
    u_xlatb2.x = u._contrast<0.0;
    u_xlat10 = u._contrast * 0.5;
    u_xlat2.x = (u_xlatb2.x) ? u_xlat10 : u._contrast;
    u_xlat3.x = dot(float3(0.377225906, 0.469278336, 0.159005448), u_xlat1.xyz);
    u_xlat3.y = dot(float3(-0.0909328535, 1.02429903, 0.0768049061), u_xlat1.xyz);
    u_xlat3.z = dot(float3(-0.0341310538, 0.14288865, 0.866726279), u_xlat1.xyz);
    u_xlat1.x = u_xlat0.w * u_xlat2.x;
    u_xlat2.xyz = u_xlat3.xyz + float3(-0.5, -0.5, -0.5);
    u_xlat1.xyz = u_xlat1.xxx * u_xlat2.xyz + float3(0.5, 0.5, 0.5);
    u_xlatb2.xyz = lessThan(u_xlat3.xyzx, float4(0.5, 0.5, 0.5, 0.0)).xyz;
    u_xlat26 = dot(u_xlat1.xx, u_xlat3.xx);
    u_xlat4.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat4.xyz = u_xlat4.xyz + u_xlat4.xyz;
    u_xlat5.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat4.xyz = (-u_xlat4.xyz) * u_xlat5.xyz + float3(1.0, 1.0, 1.0);
    u_xlat5.x = (u_xlatb2.x) ? u_xlat26 : u_xlat4.x;
    u_xlat1.x = dot(u_xlat1.yy, u_xlat3.yy);
    u_xlat5.y = (u_xlatb2.y) ? u_xlat1.x : u_xlat4.y;
    u_xlat1.x = dot(u_xlat1.zz, u_xlat3.zz);
    u_xlat5.z = (u_xlatb2.z) ? u_xlat1.x : u_xlat4.z;
    u_xlat1.x = dot(float3(2.36973262, -1.03786719, -0.342769116), u_xlat5.xyz);
    u_xlat1.y = dot(float3(0.205922827, 0.89830929, -0.11738126), u_xlat5.xyz);
    u_xlat1.z = dot(float3(0.0593699813, -0.188965991, 1.15962029), u_xlat5.xyz);
    u_xlatb2.xyz = lessThan(float4(0.00100000005, 0.00100000005, 0.00100000005, 0.0), abs(float4(u._highlights, u._shadows, u._whites, u._highlights))).xyz;
    u_xlatb2.x = u_xlatb2.y || u_xlatb2.x;
    if(u_xlatb2.x){
        u_xlat2.x = dot(u_xlat0.xyz, float3(0.298999995, 0.587000012, 0.114));
        u_xlat2.x = (-u_xlat2.x) + 1.0;
        u_xlat10 = (-u._highlights) + u._shadows;
        u_xlat2.x = u_xlat2.x * u_xlat10 + u._highlights;
        u_xlat2.x = u_xlat0.w * u_xlat2.x;
        u_xlatb10 = u_xlat2.x<0.0;
        u_xlat26 = u_xlat2.x + u_xlat2.x;
        u_xlat2.x = (u_xlatb10) ? u_xlat26 : u_xlat2.x;
        u_xlat3.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
        u_xlat3.xyz = u_xlat2.xxx * u_xlat3.xyz + u_xlat1.xyz;
        u_xlat4.xyz = log2(abs(u_xlat1.xyz));
        u_xlat4.xyz = u_xlat4.xyz * float3(1.42857146, 1.42857146, 1.42857146);
        u_xlat4.xyz = exp2(u_xlat4.xyz);
        u_xlat4.xyz = u_xlat4.xyz + float3(-1.0, -1.0, -1.0);
        u_xlat2.xyw = u_xlat2.xxx * u_xlat4.xyz + float3(1.0, 1.0, 1.0);
        u_xlat3.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
        u_xlat2.xyw = u_xlat3.xyz / u_xlat2.xyw;
        u_xlat2.xyw = (-u_xlat2.xyw) + float3(1.0, 1.0, 1.0);
        u_xlat2.xyw = max(u_xlat2.xyw, float3(0.0, 0.0, 0.0));
        u_xlat3.x = min(u_xlat1.y, u_xlat1.x);
        u_xlat3.x = min(u_xlat1.z, u_xlat3.x);
        u_xlat11 = max(u_xlat1.y, u_xlat1.x);
        u_xlat3.y = max(u_xlat1.z, u_xlat11);
        u_xlatb19.x = u_xlat3.x<u_xlat3.y;
        if(u_xlatb19.x){
            u_xlat19.x = min(u_xlat2.y, u_xlat2.x);
            u_xlat19.x = min(u_xlat2.w, u_xlat19.x);
            u_xlat27 = max(u_xlat2.y, u_xlat2.x);
            u_xlat27 = max(u_xlat2.w, u_xlat27);
            u_xlat4.z = (-u_xlat19.x) + u_xlat27;
            u_xlatb19.xy = equal(u_xlat1.xzxz, u_xlat3.xyxy).xy;
            u_xlatb5.x = u_xlatb19.y && u_xlatb19.x;
            if(u_xlatb5.x){
                u_xlat5.x = u_xlat1.y + (-u_xlat3.x);
                u_xlat5.x = u_xlat4.z * u_xlat5.x;
                u_xlat13.x = (-u_xlat3.x) + u_xlat3.y;
                u_xlat4.y = u_xlat5.x / u_xlat13.x;
                u_xlat4.x = 0.0;
            } else {
                u_xlatb5.xy = equal(u_xlat1.yxyy, u_xlat3.yyyy).xy;
                u_xlatb19.x = u_xlatb19.x && u_xlatb5.x;
                u_xlat5.xzw = u_xlat1.zxy + (-u_xlat3.xxx);
                u_xlat5.xzw = u_xlat4.zzz * u_xlat5.xzw;
                u_xlat11 = (-u_xlat3.x) + u_xlat3.y;
                u_xlat6.z = u_xlat5.x / u_xlat11;
                u_xlatb7.xy = equal(u_xlat1.yzyy, u_xlat3.xxxx).xy;
                u_xlatb3 = u_xlatb19.y && u_xlatb7.x;
                u_xlatb5.x = u_xlatb5.y && u_xlatb7.x;
                u_xlatb5.y = u_xlatb5.y && u_xlatb7.y;
                u_xlat4.xy = u_xlat5.zw / float2(u_xlat11);
                u_xlat4.w = 0.0;
                u_xlat13.xyz = (u_xlatb5.y) ? u_xlat4.zyw : u_xlat4.xzw;
                u_xlat6.xy = u_xlat4.wz;
                u_xlat5.xyz = (u_xlatb5.x) ? u_xlat6.yxz : u_xlat13.xyz;
                u_xlat3.xyw = (bool(u_xlatb3)) ? u_xlat4.xwz : u_xlat5.xyz;
                u_xlat4.xyz = (u_xlatb19.x) ? u_xlat6.xyz : u_xlat3.xyw;
            }
        } else {
            u_xlat4.x = float(0.0);
            u_xlat4.y = float(0.0);
            u_xlat4.z = float(0.0);
        }
        u_xlat2.x = dot(u_xlat2.xyw, float3(0.298999995, 0.587000012, 0.114));
        u_xlat10 = dot(u_xlat4.xyz, float3(0.298999995, 0.587000012, 0.114));
        u_xlat2.x = (-u_xlat10) + u_xlat2.x;
        u_xlat2.xyw = u_xlat2.xxx + u_xlat4.xyz;
        u_xlat3.xy = u_xlat2.xy * float2(0.298999995, 0.587000012);
        u_xlat3.x = u_xlat3.y + u_xlat3.x;
        u_xlat3.x = u_xlat2.w * 0.114 + u_xlat3.x;
        u_xlat11 = min(u_xlat2.y, u_xlat2.x);
        u_xlat11 = min(u_xlat2.w, u_xlat11);
        u_xlat19.x = max(u_xlat2.y, u_xlat2.x);
        u_xlat19.x = max(u_xlat2.w, u_xlat19.x);
        u_xlatb27 = u_xlat11<0.0;
        u_xlat4.xyz = u_xlat2.xyw + (-u_xlat3.xxx);
        u_xlat4.xyz = u_xlat3.xxx * u_xlat4.xyz;
        u_xlat11 = (-u_xlat11) + u_xlat3.x;
        u_xlat4.xyz = u_xlat4.xyz / float3(u_xlat11);
        u_xlat4.xyz = u_xlat3.xxx + u_xlat4.xyz;
        u_xlat2.xyw = (bool(u_xlatb27)) ? u_xlat4.xyz : u_xlat2.xyw;
        u_xlatb11 = 1.0<u_xlat19.x;
        u_xlat4.xyz = (-u_xlat3.xxx) + u_xlat2.xyw;
        u_xlat27 = (-u_xlat3.x) + 1.0;
        u_xlat4.xyz = float3(u_xlat27) * u_xlat4.xyz;
        u_xlat19.x = (-u_xlat3.x) + u_xlat19.x;
        u_xlat4.xyz = u_xlat4.xyz / u_xlat19.xxx;
        u_xlat3.xzw = u_xlat3.xxx + u_xlat4.xyz;
        u_xlat1.xyz = (bool(u_xlatb11)) ? u_xlat3.xzw : u_xlat2.xyw;
        u_xlat2.xyw = u_xlat1.xyz;
    } else {
        u_xlat2.xyw = u_xlat1.xyz;
    }
    u_xlatb3 = 0.00100000005<abs(u._blacks);
    u_xlatb18 = u_xlatb2.z || u_xlatb3;
    if(u_xlatb18){
        u_xlat18 = max(u_xlat1.z, u_xlat1.y);
        u_xlat18 = max(u_xlat1.x, u_xlat18);
        u_xlat3.x = min(u_xlat1.z, u_xlat1.y);
        u_xlat3.x = min(u_xlat1.x, u_xlat3.x);
        u_xlat18 = u_xlat18 + u_xlat3.x;
        u_xlat3.x = u_xlat18 * 0.5;
        u_xlat3.y = u_xlat3.x * u_xlat3.x;
        u_xlat19.xy = u_xlat3.xy * u_xlat3.yy;
        u_xlat4.xyz = u_xlat3.yyy * float3(0.666424334, 2.81294537, -3.41849589);
        u_xlat4.xyz = float3(u_xlat18) * float3(0.00266838935, -0.0940516368, 0.418836355) + u_xlat4.xyz;
        u_xlat4.xyz = u_xlat19.xxx * float3(3.02376127, -14.9509687, 8.07805443) + u_xlat4.xyz;
        u_xlat4.xyz = u_xlat19.yyy * float3(-6.99441338, 33.4941635, -12.0993872) + u_xlat4.xyz;
        u_xlat28 = u_xlat3.y * u_xlat19.x;
        u_xlat4.xyz = float3(u_xlat28) * float3(3.29398704, -34.3302498, 9.52031612) + u_xlat4.xyz;
        u_xlat5.x = (-u_xlat18) * 0.5 + 1.0;
        u_xlat4.x = min(u_xlat4.x, u_xlat5.x);
        u_xlat13.x = u_xlat19.x * u_xlat19.x;
        u_xlat12.xy = u_xlat13.xx * float2(13.1430817, -2.91934061) + u_xlat4.yz;
        u_xlat12.x = max((-u_xlat3.x), u_xlat12.x);
        u_xlatb21 = u._whites>=0.0;
        u_xlat4.x = u_xlat4.x * u._whites + u_xlat3.x;
        u_xlat6.xyz = u_xlat1.xyz * u_xlat4.xxx;
        u_xlat6.xyz = u_xlat6.xyz / u_xlat3.xxx;
        u_xlat4.x = (-u_xlat12.x) * u._whites + u_xlat3.x;
        u_xlat1.xyz = u_xlat1.xyz * u_xlat4.xxx;
        u_xlat1.xyz = u_xlat1.xyz / u_xlat3.xxx;
        u_xlat1.xyz = (bool(u_xlatb21)) ? u_xlat6.xyz : u_xlat1.xyz;
        u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
        u_xlat4.x = min(u_xlat5.x, u_xlat12.y);
        u_xlatb12 = 0.460000008>=u_xlat18;
        u_xlat18 = u_xlat18 * -4.88368559 + 0.508865297;
        u_xlat18 = u_xlat3.y * 49.1070557 + u_xlat18;
        u_xlat18 = u_xlat19.x * -121.215088 + u_xlat18;
        u_xlat18 = u_xlat19.y * 160.620529 + u_xlat18;
        u_xlat18 = u_xlat28 * -108.566086 + u_xlat18;
        u_xlat18 = u_xlat13.x * 29.3158226 + u_xlat18;
        u_xlat18 = (u_xlatb12) ? (-u_xlat3.x) : u_xlat18;
        u_xlat18 = max((-u_xlat3.x), u_xlat18);
        u_xlatb11 = u._blacks>=0.0;
        u_xlat19.x = u_xlat4.x * u._blacks + u_xlat3.x;
        u_xlat4.xyz = u_xlat1.xyz * u_xlat19.xxx;
        u_xlat4.xyz = u_xlat4.xyz / u_xlat3.xxx;
        u_xlat18 = (-u_xlat18) * u._blacks + u_xlat3.x;
        u_xlat1.xyz = u_xlat1.xyz * float3(u_xlat18);
        u_xlat1.xyz = u_xlat1.xyz / u_xlat3.xxx;
        u_xlat2.xyw = (bool(u_xlatb11)) ? u_xlat4.xyz : u_xlat1.xyz;
        u_xlat2.xyw = clamp(u_xlat2.xyw, 0.0, 1.0);
    }
    u_xlat1.x = dot(u_xlat2.xyw, float3(0.298999995, 0.587000012, 0.114));
    u_xlat1.xyz = (-u_xlat2.xyw) + u_xlat1.xxx;
    u_xlat1.xyz = (-float3(float3(u._saturation, u._saturation, u._saturation))) * u_xlat1.xyz + u_xlat2.xyw;
    u_xlatb2.x = u._temperature<0.0;
    u_xlat2.x = (u_xlatb2.x) ? 0.100000001 : 0.0500000007;
    u_xlat25 = (-u_xlat25) * u_xlat2.x + 0.312709987;
    u_xlat2.x = u_xlat25 * u_xlat25;
    u_xlat2.x = u_xlat2.x * 3.0;
    u_xlat2.x = u_xlat25 * 2.86999989 + (-u_xlat2.x);
    u_xlat2.x = u_xlat2.x + -0.275095075;
    u_xlat2.x = u._tint * 0.0833333358 + u_xlat2.x;
    u_xlat10 = u_xlat25 / u_xlat2.x;
    u_xlat25 = (-u_xlat25) + 1.0;
    u_xlat25 = (-u_xlat2.x) + u_xlat25;
    u_xlat25 = u_xlat25 / u_xlat2.x;
    u_xlat2.xyz = float3(u_xlat10) * float3(0.732800007, -0.703599989, 0.00300000003) + float3(0.4296, 1.69749999, 0.0136000002);
    u_xlat2.x = (-u_xlat25) * 0.162400007 + u_xlat2.x;
    u_xlat2.yz = float2(u_xlat25) * float2(0.00609999988, 0.983399987) + u_xlat2.yz;
    u_xlat3.xyz = float3(0.949236989, 1.03541994, 1.08728004) / u_xlat2.xyz;
    u_xlat2.x = dot(float3(0.390404999, 0.549941003, 0.00892631989), u_xlat1.xyz);
    u_xlat2.y = dot(float3(0.070841603, 0.963172019, 0.00135775004), u_xlat1.xyz);
    u_xlat2.z = dot(float3(0.0231081992, 0.128021002, 0.936245024), u_xlat1.xyz);
    u_xlat2.xyz = u_xlat3.xyz * u_xlat2.xyz;
    u_xlat3.x = dot(float3(2.85846996, -1.62879002, -0.0248910002), u_xlat2.xyz);
    u_xlat3.y = dot(float3(-0.210181996, 1.15820003, 0.000324280991), u_xlat2.xyz);
    u_xlat3.z = dot(float3(-0.0418119989, -0.118169002, 1.06867003), u_xlat2.xyz);
    u_xlat2.xyz = (-u_xlat1.xyz) + u_xlat3.xyz;
    u_xlat1.xyz = u_xlat0.www * u_xlat2.xyz + u_xlat1.xyz;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat1.w = u_xlat0.w;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat5 = u_xlat0 * u_xlat5;
        u_xlat3 = u_xlat3 * u_xlat4 + u_xlat5;
        u_xlat0.x = u_xlat4.x * u_xlat3.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat0.x : u_xlat3.w;
        __nv_out.xyz = u_xlat3.xyz;
    } else {
        __nv_out.xyz = u_xlat1.xyz;
        __nv_out.w = u_xlat0.w;
    }
    return __nv_out;
    return __nv_out;
}
