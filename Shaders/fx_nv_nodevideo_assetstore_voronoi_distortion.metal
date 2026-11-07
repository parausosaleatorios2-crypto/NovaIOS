// ---------------------------------------------------------------------------
// Voronoi Distortion (NV)
// origem : assets/effects/nv-nodevideo-assetstore-voronoi-distortion.xml
// id     : nv.effect.nodevideo-assetstore-voronoi-distortion
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_voronoi_distortionParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _offset;
    float _noise_scale;
    float _distortion;
    float _keep_edge;
    float _type;
    float2 _scale;
    float _evolution;
    float _feather;
    float _enable_turbulence;
    float _turbulence;
    float _speed;
    float _direction;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
int u_xlati6;
float4 u_xlat7;
float3 u_xlat8;
bool u_xlatb8;
float3 u_xlat9;
float u_xlat11;
float2 u_xlat14;
float u_xlat16;
int u_xlati16;
bool u_xlatb16;
float2 u_xlat18;
float2 u_xlat20;
float u_xlat21;
bool2 u_xlatb21;
float2 u_xlat22;
float2 u_xlat23;
int u_xlati25;
bool u_xlatb26;
float2 u_xlat27;
int u_xlati27;
float2 u_xlat28;
float2 u_xlat29;
float u_xlat32;
float u_xlat34;
int u_xlati34;
float u_xlat35;
bool u_xlatb35;
float u_xlat36;
int u_xlati36;
bool u_xlatb37;
float u_xlat38;
bool u_xlatb38;

fragment float4 fx_nv_nodevideo_assetstore_voronoi_distortion(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_voronoi_distortionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy + (-u._offset.xy);
    u_xlat0.xy = u_xlat0.xy * _resolution.xy;
    u_xlat20.xy = float2(u._scale.x, u._scale.y) * float2(64.0, 64.0);
    u_xlat1.xy = u_xlat0.xy / u_xlat20.xy;
    u_xlat21 = u._direction + 90.0;
    u_xlat21 = u_xlat21 * 0.0174532942;
    u_xlat2.x = sin((-u_xlat21));
    u_xlat2.y = cos(u_xlat21);
    u_xlatb21.xy = equal(int4(int(u._type), int(u._keep_edge), int(u._type), int(u._keep_edge)), int4(1, 1, 1, 1)).xy;
    u_xlat3.xy = u_xlat0.xy / _resolution.xy;
    u_xlat32 = dot(u_xlat3.xy, u_xlat3.xy);
    u_xlat3.z = sqrt(u_xlat32);
    u_xlat4.z = abs(u_xlat3.x);
    u_xlat4.x = u_xlat3.x;
    u_xlat4.y = 0.0;
    u_xlat4.xyz = (u_xlatb21.x) ? u_xlat3.xyz : u_xlat4.xyz;
    u_xlat2.z = 0.0;
    u_xlat2.xyz = (int(u._type) != 0) ? u_xlat4.xyz : u_xlat2.xyz;
    u_xlat23.xy = floor(u_xlat1.xy);
    u_xlat1.xy = fract(u_xlat1.xy);
    u_xlat21 = u._noise_scale * 256.0;
    u_xlat32 = dot(u_xlat2.xy, u_xlat2.xy);
    u_xlat4.x = sqrt(u_xlat32);
    u_xlat32 = rsqrt(u_xlat32);
    u_xlat2.xy = float2(u_xlat32) * u_xlat2.xy;
    u_xlat2.xy = u_xlat2.xy * float2(u._evolution);
    u_xlat32 = _cur_time * u._speed;
    u_xlat32 = u_xlat32 * 4.0;
    u_xlat4.x = log2(u_xlat4.x);
    u_xlat4.x = u_xlat4.x * u._feather;
    u_xlat4.x = exp2(u_xlat4.x);
    u_xlat14.x = float(-1.0);
    u_xlat14.y = float(-1.0);
    u_xlati34 = int(u._type);
    u_xlati25 = int(u._enable_turbulence);
    u_xlat5.x = float(0.0);
    u_xlat5.y = float(0.0);
    u_xlat5.w = float(80.0);
    for(int u_xlati_loop_1 = int(0xFFFFFFFEu) ; u_xlati_loop_1<=2 ; u_xlati_loop_1++)
    {
        u_xlat16 = (u_xlati34 != 0) ? u_xlat4.x : 1.0;
        u_xlatb26 = u_xlati25==1;
        u_xlat7.y = float(u_xlati_loop_1);
        u_xlat27.xy = u_xlat14.xy;
        u_xlat8.xyz = u_xlat5.xyw;
        for(int u_xlati_loop_2 = int(0xFFFFFFFEu) ; u_xlati_loop_2<=2 ; u_xlati_loop_2++)
        {
            u_xlat7.x = float(u_xlati_loop_2);
            u_xlat9.xy = u_xlat23.xy + u_xlat7.xy;
            u_xlat9.xy = u_xlat9.xy + float2(0.5, 0.5);
            u_xlat9.xy = u_xlat9.xy / float2(u_xlat21);
            u_xlat9.xy = texture0.sample(__nv_smp, u_xlat9.xy).xy;
            u_xlat9.xy = u_xlat2.xy * float2(u_xlat16) + u_xlat9.xy;
            u_xlat29.xy = u_xlat9.xy * float2(6.28318548, 6.28318548) + float2(u_xlat32);
            u_xlat29.xy = sin(u_xlat29.xy);
            u_xlat29.xy = float2(float2(u._turbulence, u._turbulence)) * u_xlat29.xy + float2(0.5, 0.5);
            u_xlat9.xy = (bool(u_xlatb26)) ? u_xlat29.xy : u_xlat9.xy;
            u_xlat9.xy = u_xlat7.xy + u_xlat9.xy;
            u_xlat9.xy = (-u_xlat1.xy) + u_xlat9.xy;
            u_xlat9.z = dot(u_xlat9.xy, u_xlat9.xy);
            u_xlatb38 = u_xlat9.z<u_xlat8.z;
            u_xlat27.xy = (bool(u_xlatb38)) ? u_xlat7.xy : u_xlat27.xy;
            u_xlat8.xyz = (bool(u_xlatb38)) ? u_xlat9.xyz : u_xlat8.xyz;
        }
        u_xlat14.xy = u_xlat27.xy;
        u_xlat5.xyw = u_xlat8.xyz;
    }
    u_xlati6 = int(u._type);
    u_xlati16 = int(u._enable_turbulence);
    u_xlat34 = 80.0;
    for(int u_xlati_loop_3 = int(0xFFFFFFFEu) ; u_xlati_loop_3<=2 ; u_xlati_loop_3++)
    {
        u_xlat35 = (u_xlati6 != 0) ? u_xlat4.x : 1.0;
        u_xlatb26 = u_xlati16==1;
        u_xlat7.y = float(u_xlati_loop_3);
        u_xlat36 = u_xlat34;
        for(int u_xlati_loop_4 = int(0xFFFFFFFEu) ; u_xlati_loop_4<=2 ; u_xlati_loop_4++)
        {
            u_xlat7.x = float(u_xlati_loop_4);
            u_xlat7.xw = u_xlat14.xy + u_xlat7.xy;
            u_xlat8.xy = u_xlat23.xy + u_xlat7.xw;
            u_xlat8.xy = u_xlat8.xy + float2(0.5, 0.5);
            u_xlat8.xy = u_xlat8.xy / float2(u_xlat21);
            u_xlat8.xy = texture0.sample(__nv_smp, u_xlat8.xy).xy;
            u_xlat8.xy = u_xlat2.xy * float2(u_xlat35) + u_xlat8.xy;
            u_xlat28.xy = u_xlat8.xy * float2(6.28318548, 6.28318548) + float2(u_xlat32);
            u_xlat28.xy = sin(u_xlat28.xy);
            u_xlat28.xy = float2(float2(u._turbulence, u._turbulence)) * u_xlat28.xy + float2(0.5, 0.5);
            u_xlat8.xy = (bool(u_xlatb26)) ? u_xlat28.xy : u_xlat8.xy;
            u_xlat7.xw = u_xlat7.xw + u_xlat8.xy;
            u_xlat7.xw = (-u_xlat1.xy) + u_xlat7.xw;
            u_xlat8.xy = u_xlat5.xy + (-u_xlat7.xw);
            u_xlat8.x = dot(u_xlat8.xy, u_xlat8.xy);
            u_xlatb8 = 9.99999975e-06<u_xlat8.x;
            u_xlat18.xy = u_xlat5.xy + u_xlat7.xw;
            u_xlat18.xy = u_xlat18.xy * float2(0.5, 0.5);
            u_xlat7.xw = (-u_xlat5.xy) + u_xlat7.xw;
            u_xlat38 = dot(u_xlat7.xw, u_xlat7.xw);
            u_xlat38 = rsqrt(u_xlat38);
            u_xlat7.xw = u_xlat7.xw * float2(u_xlat38);
            u_xlat7.x = dot(u_xlat18.xy, u_xlat7.xw);
            u_xlat7.x = min(u_xlat36, u_xlat7.x);
            u_xlat36 = (u_xlatb8) ? u_xlat7.x : u_xlat36;
        }
        u_xlat34 = u_xlat36;
    }
    u_xlat1.xy = u_xlat23.xy + u_xlat14.xy;
    u_xlat1.xy = (-u_xlat1.xy) + float2(0.5, 0.5);
    u_xlat1.xy = u_xlat1.xy / float2(u_xlat21);
    u_xlat1.xy = texture0.sample(__nv_smp, u_xlat1.xy).xy;
    u_xlat21 = (int(u._type) != 0) ? u_xlat4.x : 1.0;
    u_xlat1.xy = u_xlat2.xy * float2(u_xlat21) + u_xlat1.xy;
    u_xlatb21.x = int(u._enable_turbulence)==1;
    u_xlat2.xy = u_xlat1.xy * float2(6.28318548, 6.28318548) + float2(u_xlat32);
    u_xlat2.xy = sin(u_xlat2.xy);
    u_xlat2.xy = float2(float2(u._turbulence, u._turbulence)) * u_xlat2.xy + float2(0.5, 0.5);
    u_xlat1.xy = (u_xlatb21.x) ? u_xlat2.xy : u_xlat1.xy;
    u_xlat1.xy = u_xlat1.xy + float2(-0.5, -0.5);
    u_xlat20.xy = u_xlat20.xy * u_xlat1.xy;
    u_xlat20.xy = u_xlat20.xy * float2(float2(u._distortion, u._distortion));
    u_xlat1.x = (-u_xlat2.z) + 1.0;
    u_xlat1.x = log2(u_xlat1.x);
    u_xlat1.x = u_xlat1.x * u._feather;
    u_xlat1.x = exp2(u_xlat1.x);
    u_xlat11 = u_xlat34 + u_xlat34;
    u_xlat11 = clamp(u_xlat11, 0.0, 1.0);
    u_xlat0.xy = u_xlat20.xy * u_xlat1.xx + u_xlat0.xy;
    u_xlat0.xy = u_xlat0.xy / _resolution.xy;
    u_xlat0.xy = (-u_xlat3.xy) + u_xlat0.xy;
    u_xlat0.xy = float2(u_xlat11) * u_xlat0.xy + u_xlat3.xy;
    u_xlat0.xy = u_xlat0.xy + u._offset.xy;
    u_xlat20.xy = u_xlat0.xy + float2(0.5, 0.5);
    u_xlat0.xy = u_xlat0.xy * float2(1.00100005, 1.00100005) + float2(0.5, 0.5);
    u_xlatb1.xy = lessThan(u_xlat0.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb2.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.xyxx).xy;
    u_xlat22.xy = fract(u_xlat0.xy);
    u_xlat22.xy = (-u_xlat22.xy) + float2(1.0, 1.0);
    u_xlat2.x = (u_xlatb2.x) ? u_xlat22.x : u_xlat0.x;
    u_xlat2.y = (u_xlatb2.y) ? u_xlat22.y : u_xlat0.y;
    {
        float4 hlslcc_movcTemp = u_xlat0;
        hlslcc_movcTemp.x = (u_xlatb1.x) ? (-u_xlat0.x) : u_xlat2.x;
        hlslcc_movcTemp.y = (u_xlatb1.y) ? (-u_xlat0.y) : u_xlat2.y;
        u_xlat0 = hlslcc_movcTemp;
    }
    u_xlat0.xy = u_xlat0.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * float2(0.999000967, 0.999000967) + float2(0.5, 0.5);
    u_xlat0.xy = (u_xlatb21.y) ? u_xlat0.xy : u_xlat20.xy;
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
