// ---------------------------------------------------------------------------
// Raytracing Glass Cube (NV)
// origem : assets/effects/nv-nodevideo-raytracing-glass-cube.xml
// id     : nv.effect.nodevideo-raytracing-glass-cube
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_raytracing_glass_cubeParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float3 _rotation;
    float _zoom;
    float _samples;
    float _blur;
    float _dispersion;
    float _absorbtion;
    float2 _tex_scale;
    float2 _tex_offset;
    float _wrap_texture;
    float _refraction;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float4 u_xlat7;
float4 u_xlat8;
int3 u_xlati8;
float4 u_xlat9;
bool2 u_xlatb9;
float4 u_xlat10;
int3 u_xlati10;
float4 u_xlat11;
float3 u_xlat12;
float3 u_xlat13;
float3 u_xlat14;
float4 u_xlat15;
int3 u_xlati15;
float4 u_xlat16;
int3 u_xlati16;
float3 u_xlat17;
float2 u_xlat18;
float3 u_xlat20;
float u_xlat38;
float2 u_xlat43;
int u_xlati43;
float2 u_xlat47;
float2 u_xlat54;
bool2 u_xlatb54;
int u_xlati57;
float u_xlat59;
bool u_xlatb59;
float u_xlat60;
bool u_xlatb60;
float u_xlat61;
bool u_xlatb61;
float u_xlat62;
bool u_xlatb62;
float u_xlat63;
bool u_xlatb63;
bool u_xlatb65;
float u_xlat69;

fragment float4 fx_nv_nodevideo_raytracing_glass_cube(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_raytracing_glass_cubeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat1.xyz = u._rotation.xyz * float3(6.28318548, 6.28318548, 6.28318548);
    u_xlat2.x = sin(u_xlat1.z);
    u_xlat3.x = cos(u_xlat1.z);
    u_xlat4.x = (-u_xlat2.x);
    u_xlat5.x = cos(u_xlat1.x);
    u_xlat1.x = sin(u_xlat1.x);
    u_xlat6.y = u_xlat2.x * u_xlat5.x;
    u_xlat3.y = (-u_xlat1.x) * u_xlat2.x;
    u_xlat2.y = u_xlat3.x * u_xlat5.x;
    u_xlat4.y = (-u_xlat1.x) * u_xlat3.x;
    u_xlat7.x = sin(u_xlat1.y);
    u_xlat8.x = cos(u_xlat1.y);
    u_xlat9.x = (-u_xlat7.x);
    u_xlat9.y = u_xlat8.x;
    u_xlat6.x = dot(u_xlat3.yx, u_xlat9.xy);
    u_xlat9.z = u_xlat7.x;
    u_xlat6.z = dot(u_xlat3.yx, u_xlat9.yz);
    u_xlat2.x = dot(u_xlat4.yx, u_xlat9.xy);
    u_xlat2.z = dot(u_xlat4.yx, u_xlat9.yz);
    u_xlat3.x = u_xlat5.x * u_xlat9.x;
    u_xlat3.z = u_xlat5.x * u_xlat8.x;
    u_xlat4.x = u_xlat6.z * u._zoom;
    u_xlat4.y = u_xlat2.z * u._zoom;
    u_xlat4.z = u_xlat3.z * u._zoom;
    u_xlat20.xyz = float3(u._dispersion, u._absorbtion, u._samples) * float3(0.100000001, -0.100000001, 0.333333343);
    u_xlat3.y = u_xlat1.x;
    u_xlat5.y = 1.0;
    u_xlat7.x = float(0.0);
    u_xlat7.y = float(0.0);
    u_xlat7.z = float(0.0);
    u_xlat7.w = float(0.0);
    u_xlati57 = int(u._wrap_texture);
    u_xlat1.x = 0.0;
    while(true){
        u_xlatb59 = u_xlat1.x>=u._samples;
        if(u_xlatb59){break;}
        u_xlat59 = u_xlat1.x / u._samples;
        u_xlat60 = u_xlat59 * u._blur;
        u_xlat0.z = u_xlat60 * 0.100000001 + 1.0;
        u_xlat60 = dot(u_xlat0.xyz, u_xlat0.xyz);
        u_xlat60 = rsqrt(u_xlat60);
        u_xlat8.xyz = u_xlat0.xyz * float3(u_xlat60);
        u_xlat9.x = dot(u_xlat6.xyz, u_xlat8.xyz);
        u_xlat9.y = dot(u_xlat2.xyz, u_xlat8.xyz);
        u_xlat9.z = dot(u_xlat3.xyz, u_xlat8.xyz);
        u_xlati8.xyz = int3(uint3(lessThan(float4(0.0, 0.0, 0.0, 0.0), u_xlat9.xyzx).xyz) * 0xFFFFFFFFu);
        u_xlati10.xyz = int3(uint3(lessThan(u_xlat9.xyzx, float4(0.0, 0.0, 0.0, 0.0)).xyz) * 0xFFFFFFFFu);
        u_xlati8.xyz = (-u_xlati8.xyz) + u_xlati10.xyz;
        u_xlat8.xyz = float3(u_xlati8.xyz);
        u_xlat10.xyz = u_xlat8.xyz * float3(0.5, 0.5, 0.5) + u_xlat4.xyz;
        u_xlat10.xyz = u_xlat10.xyz / u_xlat9.xyz;
        u_xlat38 = min(u_xlat10.y, u_xlat10.x);
        u_xlat38 = min(u_xlat10.z, u_xlat38);
        u_xlat8.xyz = u_xlat8.xyz * float3(0.5, 0.5, 0.5) + (-u_xlat4.xyz);
        u_xlat8.xyz = u_xlat8.xyz / u_xlat9.xyz;
        u_xlat60 = min(u_xlat8.y, u_xlat8.x);
        u_xlat60 = min(u_xlat8.z, u_xlat60);
        u_xlatb60 = u_xlat60>=(-u_xlat38);
        u_xlat38 = (u_xlatb60) ? (-u_xlat38) : -1.0;
        u_xlatb60 = 0.0<u_xlat38;
        if(u_xlatb60){
            u_xlat60 = u_xlat59 + -0.5;
            u_xlat5.x = u_xlat20.x * u_xlat60 + 1.5;
            u_xlat8.xyz = u_xlat9.xyz * float3(u_xlat38) + u_xlat4.xyz;
            u_xlat10.xyz = u_xlat8.xyz * float3(1.00001001, 1.00001001, 1.00001001);
            u_xlat10.xyz = rint(u_xlat10.xyz);
            u_xlat38 = float(1.0) / u_xlat5.x;
            u_xlat11.y = dot(u_xlat9.xyz, u_xlat10.xyz);
            u_xlat60 = u_xlat38 * u_xlat38;
            u_xlat61 = (-u_xlat11.y) * u_xlat11.y + 1.0;
            u_xlat61 = (-u_xlat60) * u_xlat61 + 1.0;
            u_xlat43.x = sqrt(u_xlat61);
            u_xlat43.x = u_xlat38 * u_xlat11.y + u_xlat43.x;
            u_xlatb61 = u_xlat61>=0.0;
            u_xlat12.xyz = u_xlat10.xyz * u_xlat43.xxx;
            u_xlat12.xyz = float3(u_xlat38) * u_xlat9.xyz + (-u_xlat12.xyz);
            u_xlat12.xyz = bool(u_xlatb61) ? u_xlat12.xyz : float3(0.0, 0.0, 0.0);
            u_xlat61 = u_xlat11.y + u_xlat11.y;
            u_xlat43.xy = u_xlat10.xy * (-float2(u_xlat61)) + u_xlat9.xy;
            u_xlat11.x = dot(u_xlat12.xyz, u_xlat10.xyz);
            u_xlat11.zw = (-u_xlat11.xy);
            u_xlat9.x = dot(u_xlat5.yx, u_xlat11.yz);
            u_xlat9.y = dot(u_xlat5.yx, u_xlat11.xw);
            u_xlat10.x = dot(u_xlat5.xy, u_xlat11.xy);
            u_xlat10.y = dot(u_xlat5.yx, u_xlat11.xy);
            u_xlat9.xy = u_xlat9.xy / u_xlat10.xy;
            u_xlat61 = dot(u_xlat9.xy, u_xlat9.xy);
            u_xlat63 = u_xlat61 * 0.5;
            u_xlatb65 = u_xlati57==1;
            u_xlat9.xy = u_xlat43.xy * in.acScreenNorm.xy;
            u_xlat9.xy = (bool(u_xlatb65)) ? u_xlat9.xy : in.acScreenNorm.xy;
            u_xlat9.xy = u_xlat9.xy + float2(-0.5, -0.5);
            u_xlat9.xy = u_xlat9.xy * u._tex_scale.xy + float2(u._tex_offset.x, u._tex_offset.y);
            u_xlat43.xy = u_xlat43.xy * float2(float2(u._refraction, u._refraction)) + u_xlat9.xy;
            u_xlat43.xy = (int(u_xlati57) != 0) ? u_xlat9.xy : u_xlat43.xy;
            u_xlat43.xy = u_xlat43.xy + float2(0.5, 0.5);
            u_xlatb9.xy = greaterThanEqual(u_xlat43.xyxx, (-u_xlat43.xyxx)).xy;
            u_xlat43.xy = fract(abs(u_xlat43.xy));
            {
                float2 hlslcc_movcTemp = u_xlat43;
                hlslcc_movcTemp.x = (u_xlatb9.x) ? u_xlat43.x : (-u_xlat43.x);
                hlslcc_movcTemp.y = (u_xlatb9.y) ? u_xlat43.y : (-u_xlat43.y);
                u_xlat43 = hlslcc_movcTemp;
            }
            u_xlatb9.xy = lessThan(u_xlat43.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
            u_xlat47.xy = u_xlat43.xy + float2(1.0, 1.0);
            {
                float2 hlslcc_movcTemp = u_xlat43;
                hlslcc_movcTemp.x = (u_xlatb9.x) ? u_xlat47.x : u_xlat43.x;
                hlslcc_movcTemp.y = (u_xlatb9.y) ? u_xlat47.y : u_xlat43.y;
                u_xlat43 = hlslcc_movcTemp;
            }
            u_xlat9 = inputImg.sample(__nv_smp, u_xlat43.xy);
            u_xlat9 = float4(u_xlat63) * u_xlat9;
            u_xlat61 = (-u_xlat61) * 0.5 + 1.0;
            u_xlat10 = float4(u_xlat61);
            u_xlat11 = u_xlat9;
            u_xlat13.xyz = u_xlat12.xyz;
            u_xlat14.xyz = u_xlat8.xyz;
            for(int u_xlati_loop_1 = 0 ; u_xlati_loop_1<2 ; u_xlati_loop_1++)
            {
                u_xlati15.xyz = int3(uint3(lessThan(float4(0.0, 0.0, 0.0, 0.0), u_xlat13.xyzx).xyz) * 0xFFFFFFFFu);
                u_xlati16.xyz = int3(uint3(lessThan(u_xlat13.xyzx, float4(0.0, 0.0, 0.0, 0.0)).xyz) * 0xFFFFFFFFu);
                u_xlati15.xyz = (-u_xlati15.xyz) + u_xlati16.xyz;
                u_xlat15.xyz = float3(u_xlati15.xyz);
                u_xlat15.xyz = u_xlat15.xyz * float3(0.5, 0.5, 0.5) + (-u_xlat14.xyz);
                u_xlat15.xyz = u_xlat15.xyz / u_xlat13.xyz;
                u_xlat62 = min(u_xlat15.y, u_xlat15.x);
                u_xlat62 = min(u_xlat15.z, u_xlat62);
                u_xlat14.xyz = u_xlat13.xyz * float3(u_xlat62) + u_xlat14.xyz;
                u_xlat15.xyz = u_xlat14.xyz * float3(1.00001001, 1.00001001, 1.00001001);
                u_xlat15.xyz = rint(u_xlat15.xyz);
                u_xlat16.y = dot(u_xlat13.xyz, (-u_xlat15.xyz));
                u_xlat63 = (-u_xlat16.y) * u_xlat16.y + 1.0;
                u_xlat63 = (-u_xlat60) * u_xlat63 + 1.0;
                u_xlat69 = sqrt(u_xlat63);
                u_xlat69 = u_xlat38 * u_xlat16.y + u_xlat69;
                u_xlatb63 = u_xlat63>=0.0;
                u_xlat17.xyz = (-u_xlat15.xyz) * float3(u_xlat69);
                u_xlat17.xyz = float3(u_xlat38) * u_xlat13.xyz + (-u_xlat17.xyz);
                u_xlat17.xyz = bool(u_xlatb63) ? u_xlat17.xyz : float3(0.0, 0.0, 0.0);
                u_xlat63 = u_xlat16.y + u_xlat16.y;
                u_xlat13.xyz = u_xlat15.xyz * float3(u_xlat63) + u_xlat13.xyz;
                u_xlat16.x = dot(u_xlat17.xyz, (-u_xlat15.xyz));
                u_xlat16.zw = (-u_xlat16.xy);
                u_xlat15.x = dot(u_xlat5.xy, u_xlat16.yz);
                u_xlat15.y = dot(u_xlat5.xy, u_xlat16.xw);
                u_xlat18.x = dot(u_xlat5.yx, u_xlat16.xy);
                u_xlat18.y = dot(u_xlat5.xy, u_xlat16.xy);
                u_xlat15.xy = u_xlat15.xy / u_xlat18.xy;
                u_xlat63 = dot(u_xlat15.xy, u_xlat15.xy);
                u_xlat69 = u_xlat63 * 0.5;
                u_xlat62 = u_xlat20.y * u_xlat62;
                u_xlat62 = u_xlat62 * 1.44269502;
                u_xlat62 = exp2(u_xlat62);
                u_xlat15 = float4(u_xlat62) * u_xlat10;
                u_xlat16.xy = u_xlat17.xy * in.acScreenNorm.xy;
                u_xlat16.xy = (bool(u_xlatb65)) ? u_xlat16.xy : in.acScreenNorm.xy;
                u_xlat16.xy = u_xlat16.xy + float2(-0.5, -0.5);
                u_xlat16.xy = u_xlat16.xy * u._tex_scale.xy + float2(u._tex_offset.x, u._tex_offset.y);
                u_xlat54.xy = u_xlat17.xy * float2(float2(u._refraction, u._refraction)) + u_xlat16.xy;
                u_xlat16.xy = (int(u_xlati57) != 0) ? u_xlat16.xy : u_xlat54.xy;
                u_xlat16.xy = u_xlat16.xy + float2(0.5, 0.5);
                u_xlatb54.xy = greaterThanEqual(u_xlat16.xyxy, (-u_xlat16.xyxy)).xy;
                u_xlat16.xy = fract(abs(u_xlat16.xy));
                {
                    float4 hlslcc_movcTemp = u_xlat16;
                    hlslcc_movcTemp.x = (u_xlatb54.x) ? u_xlat16.x : (-u_xlat16.x);
                    hlslcc_movcTemp.y = (u_xlatb54.y) ? u_xlat16.y : (-u_xlat16.y);
                    u_xlat16 = hlslcc_movcTemp;
                }
                u_xlatb54.xy = lessThan(u_xlat16.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat17.xy = u_xlat16.xy + float2(1.0, 1.0);
                {
                    float4 hlslcc_movcTemp = u_xlat16;
                    hlslcc_movcTemp.x = (u_xlatb54.x) ? u_xlat17.x : u_xlat16.x;
                    hlslcc_movcTemp.y = (u_xlatb54.y) ? u_xlat17.y : u_xlat16.y;
                    u_xlat16 = hlslcc_movcTemp;
                }
                u_xlat16 = inputImg.sample(__nv_smp, u_xlat16.xy);
                u_xlat62 = (-u_xlat63) * 0.5 + 1.0;
                u_xlat16 = float4(u_xlat62) * u_xlat16;
                u_xlat11 = u_xlat16 * u_xlat15 + u_xlat11;
                u_xlat10 = float4(u_xlat69) * u_xlat15;
            }
        } else {
            u_xlat11.x = float(0.0);
            u_xlat11.y = float(0.0);
            u_xlat11.z = float(0.0);
            u_xlat11.w = float(0.0);
        }
        u_xlat8 = float4(u_xlat59) + float4(-0.0, -0.25, -0.5, -1.0);
        u_xlat8 = u_xlat8 * float4(6.28318548, 6.28318548, 6.28318548, 6.28318548);
        u_xlat8 = sin(u_xlat8);
        u_xlat8 = max(u_xlat8, float4(0.0, 0.0, 0.0, 0.0));
        u_xlat7 = u_xlat11 * u_xlat8 + u_xlat7;
        u_xlat1.x = u_xlat1.x + 1.0;
    }
    u_xlat0 = u_xlat7 / u_xlat20.zzzz;
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
