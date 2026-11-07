// ---------------------------------------------------------------------------
// Rendercommand Pathmirror (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-pathmirror.xml
// id     : nv.effect.nodevideo-rendercommand-pathmirror
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_pathmirrorParams {
    float _path_seg_count;
    float2 _shape_center;
    float _shape_rotation;
    float _shape_scale;
    float _strength;
    float _quality;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
float3 u_xlat2;
bool u_xlatb2;
float3 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
float3 u_xlat5;
float2 u_xlat6;
float2 u_xlat7;
float3 u_xlat8;
float3 u_xlat13;
float3 u_xlat15;
bool u_xlatb15;
float2 u_xlat18;
float2 u_xlat21;
float2 u_xlat24;
bool u_xlatb24;
float u_xlat25;
float u_xlat27;
int u_xlati29;
int u_xlati32;
float u_xlat34;

fragment float4 fx_nv_nodevideo_rendercommand_pathmirror(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_pathmirrorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat18.xy = u._shape_center.xy + float2(-0.5, -0.5);
    u_xlat0.xy = (-u_xlat18.xy) + u_xlat0.xy;
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat18.x = u._shape_rotation * 0.0174532924;
    u_xlat1.x = sin(u_xlat18.x);
    u_xlat2.x = cos(u_xlat18.x);
    u_xlat3.x = sin((-u_xlat18.x));
    u_xlat3.y = u_xlat2.x;
    u_xlat3.z = u_xlat1.x;
    u_xlat1.x = dot(u_xlat0.xy, u_xlat3.yz);
    u_xlat1.y = dot(u_xlat0.xy, u_xlat3.xy);
    u_xlat0.xy = u_xlat1.xy / float2(float2(u._shape_scale, u._shape_scale));
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat18.x = u._quality * 100.0;
    u_xlat27 = u._quality * 100.0 + -1.0;
    u_xlat2.x = float(0.0);
    u_xlat2.y = float(0.0);
    u_xlat2.z = float(1e+10);
    for(int u_xlati_loop_1 = int(0) ; u_xlati_loop_1<u._path_seg_count ; u_xlati_loop_1++)
    {
        u_xlat3.xy = (-_path_p0s[u_xlati_loop_1].xy) + _path_p0s[u_xlati_loop_1].zw;
        u_xlat21.xy = u_xlat3.xy * float2(3.0, 3.0);
        u_xlat4 = (-_path_p0s[u_xlati_loop_1].zxwy) + _path_p1s[u_xlati_loop_1].zxwy;
        u_xlat4.xz = u_xlat4.xz * float2(3.0, 3.0) + (-u_xlat21.xy);
        u_xlat3.xy = (-u_xlat3.xy) * float2(3.0, 3.0) + u_xlat4.yw;
        u_xlat3.xy = (-u_xlat4.xz) + u_xlat3.xy;
        u_xlat13.xz = _path_p0s[u_xlati_loop_1].xy;
        u_xlat5.x = float(0.0);
        u_xlat5.y = float(0.0);
        u_xlat5.z = float(1e+10);
        u_xlati32 = int(1);
        while(true){
            u_xlat6.x = float(u_xlati32);
            u_xlatb15 = u_xlat6.x>=u_xlat18.x;
            if(u_xlatb15){break;}
            u_xlat6.x = u_xlat6.x / u_xlat27;
            u_xlat15.x = u_xlat6.x * u_xlat6.x;
            u_xlat24.x = u_xlat6.x * u_xlat15.x;
            u_xlat15.xz = u_xlat4.xz * u_xlat15.xx;
            u_xlat15.xy = u_xlat3.xy * u_xlat24.xx + u_xlat15.xz;
            u_xlat6.xy = u_xlat21.xy * u_xlat6.xx + u_xlat15.xy;
            u_xlat6.xy = u_xlat6.xy + _path_p0s[u_xlati_loop_1].xy;
            u_xlat24.xy = u_xlat0.xy + (-u_xlat13.xz);
            u_xlat7.xy = (-u_xlat13.xz) + u_xlat6.xy;
            u_xlat25 = dot(u_xlat24.xy, u_xlat7.xy);
            u_xlat34 = dot(u_xlat7.xy, u_xlat7.xy);
            u_xlat25 = u_xlat25 / u_xlat34;
            u_xlat25 = clamp(u_xlat25, 0.0, 1.0);
            u_xlat8.xy = u_xlat7.xy * float2(u_xlat25) + u_xlat13.xz;
            u_xlat24.xy = (-u_xlat7.xy) * float2(u_xlat25) + u_xlat24.xy;
            u_xlat24.x = dot(u_xlat24.xy, u_xlat24.xy);
            u_xlat8.z = sqrt(u_xlat24.x);
            u_xlatb24 = u_xlat8.z<u_xlat5.z;
            u_xlat5.xyz = (bool(u_xlatb24)) ? u_xlat8.xyz : u_xlat5.xyz;
            u_xlati32 = u_xlati32 + 1;
            u_xlat13.xz = u_xlat6.xy;
        }
        u_xlatb3 = u_xlat5.z<u_xlat2.z;
        u_xlat2.xyz = (bool(u_xlatb3)) ? u_xlat5.xyz : u_xlat2.xyz;
    }
    u_xlat0.xy = u_xlat0.xy + (-u_xlat2.xy);
    u_xlat0.xy = u_xlat0.xy * float2(float2(u._shape_scale, u._shape_scale));
    u_xlat0.xy = u_xlat0.xy * float2(u._strength);
    u_xlat0.xy = (-u_xlat0.xy) * float2(2.0, 2.0) + in.acScreenNorm.xy;
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
    u_xlatb2 = u._path_seg_count<1;
    __nv_out = (bool(u_xlatb2)) ? u_xlat1 : u_xlat0;
    return __nv_out;
    return __nv_out;
}
