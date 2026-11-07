// ---------------------------------------------------------------------------
// Fill Assetstore Water Caustics (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-water-caustics.xml
// id     : nv.effect.nodevideo-fill-assetstore-water-caustics
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_water_causticsParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _color;
    float2 _scale;
    float2 _offset;
    float _intensity;
    float _evolution;
    float _iteration;
    float _blend_mode;
    float _type;
    float _brightness;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
bool u_xlatb2;
float4 u_xlat3;
int u_xlati3;
bool3 u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat6;
bool u_xlatb6;
float3 u_xlat8;
float2 u_xlat9;
bool u_xlatb9;
float u_xlat12;
float2 u_xlat14;
float u_xlat15;
float u_xlat18;
bool u_xlatb18;
float u_xlat21;

fragment float4 fx_nv_nodevideo_fill_assetstore_water_caustics(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_water_causticsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = u._color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat0.xyz = u._color.xyz * u_xlat0.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat1.xzw = u_xlat0.xzy * u._color.xzy;
    u_xlat0.xw = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xw = u_xlat0.xw * u._scale.xy;
    u_xlat0.xw = u_xlat0.xw * float2(10.0, 10.0) + float2(u._offset.x, u._offset.y);
    u_xlat0.xw = u_xlat0.xw + float2(-19.0, -19.0);
    u_xlat2.x = u._brightness * 0.00999999978;
    u_xlat8.x = 1.0;
    u_xlat14.xy = u_xlat0.xw;
    u_xlati3 = 0;
    while(true){
        u_xlatb9 = u_xlati3>=int(u._iteration);
        if(u_xlatb9){break;}
        u_xlati3 = u_xlati3 + 1;
        u_xlat9.x = float(u_xlati3);
        u_xlat9.x = 0.200000003 / u_xlat9.x;
        u_xlat9.x = (-u_xlat9.x) + 0.699999988;
        u_xlat15 = u._evolution * u_xlat9.x + (-u_xlat14.x);
        u_xlat15 = cos(u_xlat15);
        u_xlat21 = u._evolution * u_xlat9.x + u_xlat14.y;
        u_xlat21 = sin(u_xlat21);
        u_xlat4.x = u_xlat21 + u_xlat15;
        u_xlat15 = u._evolution * u_xlat9.x + (-u_xlat14.y);
        u_xlat15 = sin(u_xlat15);
        u_xlat21 = u._evolution * u_xlat9.x + u_xlat14.x;
        u_xlat21 = cos(u_xlat21);
        u_xlat4.y = u_xlat21 + u_xlat15;
        u_xlat14.xy = u_xlat0.xw + u_xlat4.xy;
        u_xlat9.xy = float2(float2(u._evolution, u._evolution)) * u_xlat9.xx + u_xlat14.xy;
        u_xlat9.x = sin(u_xlat9.x);
        u_xlat9.x = u_xlat9.x + u_xlat9.x;
        u_xlat9.x = u_xlat9.x / u_xlat2.x;
        u_xlat4.x = u_xlat0.x / u_xlat9.x;
        u_xlat9.x = cos(u_xlat9.y);
        u_xlat9.x = u_xlat9.x / u_xlat2.x;
        u_xlat4.y = u_xlat0.w / u_xlat9.x;
        u_xlat9.x = dot(u_xlat4.xy, u_xlat4.xy);
        u_xlat9.x = sqrt(u_xlat9.x);
        u_xlat9.x = float(1.0) / u_xlat9.x;
        u_xlat8.x = u_xlat8.x + u_xlat9.x;
    }
    u_xlat0.x = float(int(u._iteration));
    u_xlat0.x = u_xlat8.x / u_xlat0.x;
    u_xlat0.x = -abs(u_xlat0.x) + 1.5;
    if(int(u._type) == 0) {
        u_xlat1.xyz = u_xlat1.xwz;
    } else {
        u_xlatb18 = int(u._type)==1;
        if(u_xlatb18){
            u_xlat18 = log2(u_xlat0.x);
            u_xlat18 = u_xlat18 * u._intensity;
            u_xlat18 = exp2(u_xlat18);
            u_xlat1.y = u_xlat18 * in.acScreenNorm.x;
        } else {
            u_xlatb18 = int(u._type)==2;
            if(u_xlatb18){
                u_xlatb18 = u_xlat1.w>=u_xlat1.z;
                u_xlat18 = u_xlatb18 ? 1.0 : float(0.0);
                u_xlat2.xy = u._color.yz * u_xlat0.yz + (-u_xlat1.zw);
                u_xlat1.zw = float2(u_xlat18) * u_xlat2.yx + u_xlat1.wz;
                u_xlatb18 = u_xlat1.x>=u_xlat1.w;
                u_xlat18 = u_xlatb18 ? 1.0 : float(0.0);
                u_xlat2.xyz = (-u_xlat1.wzx) + u_xlat1.xzw;
                u_xlat2.xyz = float3(u_xlat18) * u_xlat2.xyz + u_xlat1.wzx;
                u_xlat18 = min(u_xlat2.y, u_xlat2.z);
                u_xlat18 = (-u_xlat18) + u_xlat2.x;
                u_xlat8.x = u_xlat2.x + 1.00000001e-10;
                u_xlat18 = u_xlat18 / u_xlat8.x;
                u_xlat8.x = u_xlat0.x * in.acScreenNorm.x;
                u_xlat8.x = u_xlat8.x * u._intensity;
                u_xlat8.xyz = u_xlat8.xxx * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
                u_xlat8.xyz = u_xlat8.xyz * float3(0.166666672, 0.166666672, 0.166666672);
                u_xlatb3.xyz = greaterThanEqual(u_xlat8.xyzx, (-u_xlat8.xyzx)).xyz;
                u_xlat8.xyz = fract(abs(u_xlat8.xyz));
                {
                    float3 hlslcc_movcTemp = u_xlat8;
                    hlslcc_movcTemp.x = (u_xlatb3.x) ? u_xlat8.x : (-u_xlat8.x);
                    hlslcc_movcTemp.y = (u_xlatb3.y) ? u_xlat8.y : (-u_xlat8.y);
                    hlslcc_movcTemp.z = (u_xlatb3.z) ? u_xlat8.z : (-u_xlat8.z);
                    u_xlat8 = hlslcc_movcTemp;
                }
                u_xlat8.xyz = u_xlat8.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
                u_xlat8.xyz = abs(u_xlat8.xyz) + float3(-1.0, -1.0, -1.0);
                u_xlat8.xyz = clamp(u_xlat8.xyz, 0.0, 1.0);
                u_xlat3.xyz = u_xlat8.xyz * u_xlat8.xyz;
                u_xlat3.xyz = u_xlat8.xyz * u_xlat3.xyz;
                u_xlat8.xyz = (-u_xlat8.xyz) * float3(2.0, 2.0, 2.0) + float3(3.0, 3.0, 3.0);
                u_xlat8.xyz = u_xlat3.xyz * u_xlat8.xyz + float3(-1.0, -1.0, -1.0);
                u_xlat8.xyz = float3(u_xlat18) * u_xlat8.xyz + float3(1.0, 1.0, 1.0);
                u_xlat1.xyz = u_xlat8.xyz * u_xlat2.xxx;
            } else {
                u_xlatb18 = int(u._type)==3;
                u_xlatb2 = u_xlat1.w>=u_xlat1.z;
                u_xlat2.x = u_xlatb2 ? 1.0 : float(0.0);
                u_xlat6.xy = u._color.yz * u_xlat0.yz + (-u_xlat1.zw);
                u_xlat2.xy = u_xlat2.xx * u_xlat6.xy + u_xlat1.zw;
                u_xlatb6 = u_xlat1.x>=u_xlat2.x;
                u_xlat6.x = u_xlatb6 ? 1.0 : float(0.0);
                u_xlat2.z = u_xlat1.x;
                u_xlat3.xyz = (-u_xlat2.xyz) + u_xlat2.zyx;
                u_xlat2.xyz = u_xlat6.xxx * u_xlat3.xyz + u_xlat2.xyz;
                u_xlat6.x = min(u_xlat2.y, u_xlat2.z);
                u_xlat6.x = (-u_xlat6.x) + u_xlat2.x;
                u_xlat12 = u_xlat2.x + 1.00000001e-10;
                u_xlat6.x = u_xlat6.x / u_xlat12;
                u_xlat12 = u_xlat0.x * u._intensity;
                u_xlat8.xyz = float3(u_xlat12) * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
                u_xlat8.xyz = u_xlat8.xyz * float3(0.166666672, 0.166666672, 0.166666672);
                u_xlatb3.xyz = greaterThanEqual(u_xlat8.xyzx, (-u_xlat8.xyzx)).xyz;
                u_xlat8.xyz = fract(abs(u_xlat8.xyz));
                {
                    float3 hlslcc_movcTemp = u_xlat8;
                    hlslcc_movcTemp.x = (u_xlatb3.x) ? u_xlat8.x : (-u_xlat8.x);
                    hlslcc_movcTemp.y = (u_xlatb3.y) ? u_xlat8.y : (-u_xlat8.y);
                    hlslcc_movcTemp.z = (u_xlatb3.z) ? u_xlat8.z : (-u_xlat8.z);
                    u_xlat8 = hlslcc_movcTemp;
                }
                u_xlat8.xyz = u_xlat8.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
                u_xlat8.xyz = abs(u_xlat8.xyz) + float3(-1.0, -1.0, -1.0);
                u_xlat8.xyz = clamp(u_xlat8.xyz, 0.0, 1.0);
                u_xlat3.xyz = u_xlat8.xyz * u_xlat8.xyz;
                u_xlat3.xyz = u_xlat8.xyz * u_xlat3.xyz;
                u_xlat8.xyz = (-u_xlat8.xyz) * float3(2.0, 2.0, 2.0) + float3(3.0, 3.0, 3.0);
                u_xlat8.xyz = u_xlat3.xyz * u_xlat8.xyz + float3(-1.0, -1.0, -1.0);
                u_xlat8.xyz = u_xlat6.xxx * u_xlat8.xyz + float3(1.0, 1.0, 1.0);
                u_xlat2.xyz = u_xlat8.xyz * u_xlat2.xxx;
                u_xlat1.xyz = (bool(u_xlatb18)) ? u_xlat2.xyz : u_xlat1.xwz;
            }
        }
    }
    u_xlat2 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat3.xyz = u_xlat0.xxx * u_xlat1.xyz;
    u_xlatb6 = int(u._blend_mode)==1;
    u_xlat3.w = u._brightness;
    u_xlat4 = u_xlat2 * u_xlat3;
    u_xlat1.xyz = u_xlat1.xyz * u_xlat0.xxx + u_xlat2.xyz;
    u_xlat1.w = u_xlat2.w;
    u_xlat0 = (bool(u_xlatb6)) ? u_xlat4 : u_xlat1;
    u_xlat4.xyz = u_xlat3.xyz;
    u_xlat0 = (int(u._blend_mode) != 0) ? u_xlat0 : u_xlat4;
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
