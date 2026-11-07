// ---------------------------------------------------------------------------
// Effect Trail Light (NV)
// origem : assets/effects/nv-nodevideo-effect-trail-light.xml
// id     : nv.effect.nodevideo-effect-trail-light
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_trail_lightParams {
    float _path_seg_count;
    float _evolution;
    float _next_evolution;
    float _decay;
    float _radius;
    float4 _color;
    float _disable;
    float _fade;
    float2 _shape_center;
    float _shape_rotation;
    float _shape_scale;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
bool u_xlatb0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
float3 u_xlat3;
float4 u_xlat4;
float3 u_xlat5;
bool u_xlatb5;
float4 u_xlat6;
float4 u_xlat7;
float4 u_xlat8;
float3 u_xlat9;
float4 u_xlat10;
int u_xlati10;
bool u_xlatb10;
float4 u_xlat11;
int u_xlati11;
bool u_xlatb11;
float4 u_xlat12;
int u_xlati14;
float u_xlat15;
int u_xlati17;
float u_xlat18;
int u_xlati19;
float3 u_xlat23;
float2 u_xlat26;
float2 u_xlat27;
bool2 u_xlatb27;
float2 u_xlat29;
float2 u_xlat31;
float u_xlat36;
int u_xlati39;
bool u_xlatb39;
float u_xlat40;
int u_xlati40;
bool u_xlatb40;
float u_xlat41;
int u_xlati42;
float u_xlat43;
int u_xlati43;
bool u_xlatb43;
int u_xlati45;
int u_xlati48;
bool u_xlatb48;

fragment float4 fx_nv_nodevideo_effect_trail_light(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_trail_lightParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0 = u._disable<0;
    if(u_xlatb0){
        u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
        u_xlat26.xy = u._shape_center.xy + float2(-0.5, -0.5);
        u_xlat0.xy = (-u_xlat26.xy) + u_xlat0.xy;
        u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
        u_xlat26.x = u._shape_rotation * 0.0174532924;
        u_xlat1.x = sin(u_xlat26.x);
        u_xlat2.x = cos(u_xlat26.x);
        u_xlat3.x = sin((-u_xlat26.x));
        u_xlat3.y = u_xlat2.x;
        u_xlat3.z = u_xlat1.x;
        u_xlat1.x = dot(u_xlat0.xy, u_xlat3.yz);
        u_xlat1.y = dot(u_xlat0.xy, u_xlat3.xy);
        u_xlat0.xy = u_xlat1.xy / float2(float2(u._shape_scale, u._shape_scale));
        u_xlat1.z = 0.0;
        u_xlat2.x = float(0.0);
        u_xlat2.y = float(0.0);
        u_xlat2.z = float(as_type<float>(int(0xFFFFFFFFu)));
        u_xlat26.x = float(0.0);
        u_xlati39 = int(0);
        while(true){
            u_xlatb40 = u_xlati39>=u._path_seg_count;
            if(u_xlatb40){break;}
            u_xlat3.xy = (-_path_p0s[u_xlati39].xy) + _path_p0s[u_xlati39].zw;
            u_xlat29.xy = u_xlat3.xy * float2(3.0, 3.0);
            u_xlat4 = (-_path_p0s[u_xlati39].zxwy) + _path_p1s[u_xlati39].zxwy;
            u_xlat4.xz = u_xlat4.xz * float2(3.0, 3.0) + (-u_xlat29.xy);
            u_xlat3.xy = (-u_xlat3.xy) * float2(3.0, 3.0) + u_xlat4.yw;
            u_xlat3.xy = (-u_xlat4.xz) + u_xlat3.xy;
            u_xlat1.xy = u_xlat2.xy;
            u_xlat40 = u_xlat26.x;
            u_xlat41 = u_xlat2.z;
            u_xlati17 = 0;
            while(true){
                u_xlatb43 = u_xlati17>=140;
                if(u_xlatb43){break;}
                u_xlat43 = float(u_xlati17);
                u_xlat43 = u_xlat43 * 0.00719424477;
                u_xlat5.x = u_xlat43 * u_xlat43;
                u_xlat18 = u_xlat43 * u_xlat5.x;
                u_xlat5.xz = u_xlat4.xz * u_xlat5.xx;
                u_xlat5.xy = u_xlat3.xy * float2(u_xlat18) + u_xlat5.xz;
                u_xlat5.xy = u_xlat29.xy * float2(u_xlat43) + u_xlat5.xy;
                u_xlat5.xy = u_xlat5.xy + _path_p0s[u_xlati39].xy;
                if(uint(as_type<uint>(u_xlat41)) != uint(0)) {
                    u_xlati43 = u_xlati17 + 1;
                    u_xlat41 = 0.0;
                    u_xlat1.xy = u_xlat5.xy;
                    u_xlati17 = u_xlati43;
                    continue;
                }
                u_xlat31.xy = (-u_xlat1.xy) + u_xlat5.xy;
                u_xlat43 = dot(u_xlat31.xy, u_xlat31.xy);
                u_xlat43 = sqrt(u_xlat43);
                u_xlat40 = u_xlat40 + u_xlat43;
                u_xlat1.xy = u_xlat5.xy;
                u_xlati17 = u_xlati17 + 1;
                u_xlat41 = 0.0;
            }
            u_xlat26.x = u_xlat40;
            u_xlati39 = u_xlati39 + 1;
            u_xlat2.xyz = u_xlat1.xyz;
        }
        u_xlatb39 = 1.0<u._next_evolution;
        u_xlatb1.xy = greaterThanEqual(float4(u._evolution, u._next_evolution, u._evolution, u._evolution), (-float4(u._evolution, u._next_evolution, u._evolution, u._evolution))).xy;
        u_xlat27.xy = fract(abs(float2(u._evolution, u._next_evolution)));
        u_xlat1.x = (u_xlatb1.x) ? u_xlat27.x : (-u_xlat27.x);
        u_xlat1.y = (u_xlatb1.y) ? u_xlat27.y : (-u_xlat27.y);
        u_xlat1.xy = (bool(u_xlatb39)) ? u_xlat1.xy : float2(u._evolution, u._next_evolution);
        u_xlatb27.xy = lessThan(u_xlat1.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlat2.xy = u_xlat1.xy + float2(1.0, 1.0);
        {
            float4 hlslcc_movcTemp = u_xlat1;
            hlslcc_movcTemp.x = (u_xlatb27.x) ? u_xlat2.x : u_xlat1.x;
            hlslcc_movcTemp.y = (u_xlatb27.y) ? u_xlat2.y : u_xlat1.y;
            u_xlat1 = hlslcc_movcTemp;
        }
        u_xlat26.xy = u_xlat26.xx * u_xlat1.xy;
        u_xlat27.x = u._radius * 0.100000001;
        u_xlatb1.x = u_xlat1.y<u_xlat1.x;
        u_xlat2.x = float(0.0);
        u_xlat2.y = float(0.0);
        u_xlat2.z = float(0.0);
        u_xlat2.w = float(0.0);
        u_xlat3.x = float(0.0);
        u_xlat3.y = float(0.0);
        u_xlat3.z = float(0.0);
        u_xlati42 = int(int(0xFFFFFFFFu));
        u_xlat4.x = float(0.0);
        u_xlat4.y = float(0.0);
        u_xlat4.z = float(0.0);
        u_xlat4.w = float(0.0);
        u_xlati14 = int(0);
        u_xlati40 = int(0);
        while(true){
            u_xlatb5 = u_xlati14>=u._path_seg_count;
            u_xlati40 = 0;
            if(u_xlatb5){break;}
            u_xlat5.xy = (-_path_p0s[u_xlati14].xy) + _path_p0s[u_xlati14].zw;
            u_xlat31.xy = u_xlat5.xy * float2(3.0, 3.0);
            u_xlat6 = (-_path_p0s[u_xlati14].zxwy) + _path_p1s[u_xlati14].zxwy;
            u_xlat6.xz = u_xlat6.xz * float2(3.0, 3.0) + (-u_xlat31.xy);
            u_xlat5.xy = (-u_xlat5.xy) * float2(3.0, 3.0) + u_xlat6.yw;
            u_xlat5.xy = (-u_xlat6.xz) + u_xlat5.xy;
            u_xlat7 = u_xlat2;
            u_xlat8 = u_xlat4;
            u_xlat9.xyz = u_xlat3.xyz;
            u_xlati19 = u_xlati42;
            u_xlati45 = 0;
            u_xlati48 = 0;
            while(true){
                u_xlatb10 = u_xlati45>=140;
                u_xlati48 = 0;
                if(u_xlatb10){break;}
                u_xlat10.x = float(u_xlati45);
                u_xlat10.x = u_xlat10.x * 0.00719424477;
                u_xlat23.x = u_xlat10.x * u_xlat10.x;
                u_xlat36 = u_xlat10.x * u_xlat23.x;
                u_xlat23.xz = u_xlat6.xz * u_xlat23.xx;
                u_xlat23.xy = u_xlat5.xy * float2(u_xlat36) + u_xlat23.xz;
                u_xlat10.xy = u_xlat31.xy * u_xlat10.xx + u_xlat23.xy;
                u_xlat10.yz = u_xlat10.xy + _path_p0s[u_xlati14].xy;
                if(u_xlati19 != 0) {
                    u_xlati11 = u_xlati45 + 1;
                    u_xlat10.x = u_xlat9.x;
                    u_xlati19 = 0;
                    u_xlati48 = 0;
                    u_xlat9.xyz = u_xlat10.xyz;
                    u_xlati45 = u_xlati11;
                    continue;
                }
                u_xlat11.xy = (-u_xlat9.yz) + u_xlat10.yz;
                u_xlat10.x = dot(u_xlat11.xy, u_xlat11.xy);
                u_xlat10.x = sqrt(u_xlat10.x);
                u_xlat10.w = u_xlat9.x + u_xlat10.x;
                u_xlat11.xy = u_xlat0.xy + (-u_xlat10.yz);
                u_xlat10.x = dot(u_xlat11.xy, u_xlat11.xy);
                u_xlat10.x = u_xlat27.x / u_xlat10.x;
                u_xlatb11 = u_xlat10.w>=u_xlat26.x;
                u_xlat12 = u_xlat8 + u_xlat10.xxxx;
                u_xlat11 = (bool(u_xlatb11)) ? u_xlat12 : u_xlat8;
                if(u_xlatb1.x){
                    u_xlati10 = u_xlati45 + 1;
                    u_xlat8 = u_xlat11;
                    u_xlat9.xyz = u_xlat10.wyz;
                    u_xlati19 = 0;
                    u_xlati48 = 0;
                    u_xlati45 = u_xlati10;
                    continue;
                }
                u_xlatb10 = u_xlat26.y<u_xlat10.w;
                if(u_xlatb10){
                    u_xlat8 = u_xlat11;
                    u_xlat9.xyz = u_xlat10.wyz;
                    u_xlati19 = 0;
                    u_xlati48 = int(0xFFFFFFFFu);
                    u_xlat7 = u_xlat11;
                    break;
                }
                u_xlatb48 = u_xlatb10;
                u_xlat8 = u_xlat11;
                u_xlat9.xyz = u_xlat10.wyz;
                u_xlati45 = u_xlati45 + 1;
                u_xlati19 = 0;
            }
            u_xlat3.xyz = u_xlat9.xyz;
            u_xlati42 = u_xlati19;
            u_xlat2 = u_xlat7;
            u_xlat4 = u_xlat8;
            u_xlati40 = u_xlati48;
            if(u_xlati48 != 0) {break;}
            u_xlati14 = u_xlati14 + 1;
            u_xlat2 = u_xlat7;
            u_xlat4 = u_xlat8;
            u_xlati40 = u_xlati48;
        }
        u_xlat0 = (int(u_xlati40) != 0) ? u_xlat2 : u_xlat4;
        u_xlat1.xyz = u_xlat0.xyz * u._color.xyz;
        u_xlat0.xyz = u_xlat1.xyz + u_xlat1.xyz;
    } else {
        u_xlat0.x = float(0.0);
        u_xlat0.y = float(0.0);
        u_xlat0.z = float(0.0);
        u_xlat0.w = float(0.0);
    }
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat2.x = (-u._decay) + 1.0;
    u_xlat2.x = u_xlat2.x * 0.0998999998 + 0.899999976;
    u_xlat15 = max(u_xlat1.x, 0.0);
    u_xlat15 = min(u_xlat1.x, u_xlat15);
    u_xlat15 = u_xlat15 * u._fade;
    u_xlat2.x = (-u_xlat15) * 0.100000001 + u_xlat2.x;
    u_xlat2.x = max(u_xlat2.x, 0.5);
    u_xlat2.x = min(u_xlat2.x, 0.999000013);
    u_xlat15 = (-u_xlat2.x) + 1.0;
    u_xlat0 = u_xlat0 * float4(u_xlat15);
    u_xlat1 = u_xlat1 * u_xlat2.xxxx;
    __nv_out = u_xlat0 * float4(0.00999999978, 0.00999999978, 0.00999999978, 0.00999999978) + u_xlat1;
    return __nv_out;
    return __nv_out;
}
