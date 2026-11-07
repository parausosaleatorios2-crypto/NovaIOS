// ---------------------------------------------------------------------------
// Effect Distort Displacement Map (NV)
// origem : assets/effects/nv-nodevideo-effect-distort-displacement-map.xml
// id     : nv.effect.nodevideo-effect-distort-displacement-map
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_distort_displacement_mapParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _max_horizaontal_displacement;
    float _max_vertical_displacement;
    float _keep_edge;
    float _use_for_horizontal_displacement;
    float _use_for_vertical_displacement;
    float _from_center;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float2 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat6;
float u_xlat7;
bool2 u_xlatb7;
float2 u_xlat12;
bool2 u_xlatb12;
float u_xlat13;
bool u_xlatb13;
float2 u_xlat14;
bool2 u_xlatb14;
float u_xlat18;
float u_xlat19;

fragment float4 fx_nv_nodevideo_effect_distort_displacement_map(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_distort_displacement_mapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> displacement_source [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = displacement_source.sample(__nv_smp, in.acScreenNorm.xy).yzwx;
    u_xlatb1 = int(u._keep_edge)==1;
    if(int(u._use_for_horizontal_displacement) == 0) {
        u_xlat2.x = u_xlat0.w;
    } else {
        u_xlatb7.x = int(u._use_for_horizontal_displacement)==1;
        if(u_xlatb7.x){
            u_xlat2.x = u_xlat0.x;
        } else {
            u_xlatb7.x = int(u._use_for_horizontal_displacement)==2;
            if(u_xlatb7.x){
                u_xlat2.x = u_xlat0.y;
            } else {
                u_xlatb7.x = int(u._use_for_horizontal_displacement)==3;
                if(u_xlatb7.x){
                    u_xlat2.x = u_xlat0.z;
                } else {
                    u_xlatb7.x = int(u._use_for_horizontal_displacement)==4;
                    if(u_xlatb7.x){
                        u_xlat2.x = dot(u_xlat0.wxy, float3(0.300000012, 0.589999974, 0.109999999));
                    } else {
                        u_xlatb7.x = u_xlat0.x>=u_xlat0.y;
                        u_xlat7 = u_xlatb7.x ? 1.0 : float(0.0);
                        u_xlat3.xy = u_xlat0.yx;
                        u_xlat3.z = float(-1.0);
                        u_xlat3.w = float(0.666666687);
                        u_xlat4.xy = u_xlat0.xy + (-u_xlat3.xy);
                        u_xlat4.z = float(1.0);
                        u_xlat4.w = float(-1.0);
                        u_xlat3 = float4(u_xlat7) * u_xlat4 + u_xlat3;
                        u_xlatb7.x = u_xlat0.w>=u_xlat3.x;
                        u_xlat7 = u_xlatb7.x ? 1.0 : float(0.0);
                        u_xlat4.xyz = u_xlat3.xyw;
                        u_xlat4.w = u_xlat0.w;
                        u_xlat3.xyw = u_xlat4.wyx;
                        u_xlat3 = (-u_xlat4) + u_xlat3;
                        u_xlat3 = float4(u_xlat7) * u_xlat3 + u_xlat4;
                        u_xlat7 = min(u_xlat3.y, u_xlat3.w);
                        u_xlat7 = (-u_xlat7) + u_xlat3.x;
                        u_xlat13 = (-u_xlat3.y) + u_xlat3.w;
                        u_xlat19 = u_xlat7 * 6.0 + 1.00000001e-10;
                        u_xlat13 = u_xlat13 / u_xlat19;
                        u_xlat13 = u_xlat13 + u_xlat3.z;
                        u_xlatb14.xy = equal(int4(int4(int(u._use_for_horizontal_displacement), int(u._use_for_horizontal_displacement), int(u._use_for_horizontal_displacement), int(u._use_for_horizontal_displacement))), int4(5, 6, 5, 6)).xy;
                        u_xlat19 = u_xlat3.x + 1.00000001e-10;
                        u_xlat7 = u_xlat7 / u_xlat19;
                        u_xlat7 = (u_xlatb14.y) ? u_xlat3.x : u_xlat7;
                        u_xlat2.x = (u_xlatb14.x) ? abs(u_xlat13) : u_xlat7;
                    }
                }
            }
        }
    }
    u_xlatb7.x = int(u._from_center)==1;
    if(int(u._use_for_vertical_displacement) == 0) {
        u_xlat2.y = u_xlat0.w;
    } else {
        u_xlatb13 = int(u._use_for_vertical_displacement)==1;
        if(u_xlatb13){
            u_xlat2.y = u_xlat0.x;
        } else {
            u_xlatb13 = int(u._use_for_vertical_displacement)==2;
            if(u_xlatb13){
                u_xlat2.y = u_xlat0.y;
            } else {
                u_xlatb13 = int(u._use_for_vertical_displacement)==3;
                if(u_xlatb13){
                    u_xlat2.y = u_xlat0.z;
                } else {
                    u_xlatb13 = int(u._use_for_vertical_displacement)==4;
                    if(u_xlatb13){
                        u_xlat2.y = dot(u_xlat0.wxy, float3(0.300000012, 0.589999974, 0.109999999));
                    } else {
                        u_xlatb13 = u_xlat0.x>=u_xlat0.y;
                        u_xlat13 = u_xlatb13 ? 1.0 : float(0.0);
                        u_xlat3.xy = u_xlat0.yx;
                        u_xlat3.z = float(-1.0);
                        u_xlat3.w = float(0.666666687);
                        u_xlat4.xy = u_xlat0.xy + (-u_xlat3.xy);
                        u_xlat4.z = float(1.0);
                        u_xlat4.w = float(-1.0);
                        u_xlat3 = float4(u_xlat13) * u_xlat4 + u_xlat3;
                        u_xlatb13 = u_xlat0.w>=u_xlat3.x;
                        u_xlat13 = u_xlatb13 ? 1.0 : float(0.0);
                        u_xlat0.xyz = u_xlat3.xyw;
                        u_xlat3.xyw = u_xlat0.wyx;
                        u_xlat3 = (-u_xlat0) + u_xlat3;
                        u_xlat0 = float4(u_xlat13) * u_xlat3 + u_xlat0;
                        u_xlat13 = min(u_xlat0.y, u_xlat0.w);
                        u_xlat13 = u_xlat0.x + (-u_xlat13);
                        u_xlat6 = (-u_xlat0.y) + u_xlat0.w;
                        u_xlat18 = u_xlat13 * 6.0 + 1.00000001e-10;
                        u_xlat6 = u_xlat6 / u_xlat18;
                        u_xlat6 = u_xlat6 + u_xlat0.z;
                        u_xlatb12.xy = equal(int4(int(u._use_for_vertical_displacement)), int4(5, 6, 5, 6)).xy;
                        u_xlat19 = u_xlat0.x + 1.00000001e-10;
                        u_xlat13 = u_xlat13 / u_xlat19;
                        u_xlat0.x = (u_xlatb12.y) ? u_xlat0.x : u_xlat13;
                        u_xlat2.y = (u_xlatb12.x) ? abs(u_xlat6) : u_xlat0.x;
                    }
                }
            }
        }
    }
    u_xlat0.xy = u_xlat2.xy + float2(-0.5, -0.5);
    u_xlat0.xy = (u_xlatb7.x) ? u_xlat2.xy : u_xlat0.xy;
    u_xlat0.xy = float2(u._max_horizaontal_displacement, u._max_vertical_displacement) * u_xlat0.xy + in.acScreenNorm.xy;
    u_xlat12.xy = u_xlat0.xy + float2(-0.5, -0.5);
    u_xlat12.xy = u_xlat12.xy * float2(1.00100005, 1.00100005) + float2(0.5, 0.5);
    u_xlatb7.xy = lessThan(u_xlat12.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb2.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat12.xyxx).xy;
    u_xlat14.xy = fract(u_xlat12.xy);
    u_xlat14.xy = (-u_xlat14.xy) + float2(1.0, 1.0);
    u_xlat2.x = (u_xlatb2.x) ? u_xlat14.x : u_xlat12.x;
    u_xlat2.y = (u_xlatb2.y) ? u_xlat14.y : u_xlat12.y;
    {
        float2 hlslcc_movcTemp = u_xlat12;
        hlslcc_movcTemp.x = (u_xlatb7.x) ? (-u_xlat12.x) : u_xlat2.x;
        hlslcc_movcTemp.y = (u_xlatb7.y) ? (-u_xlat12.y) : u_xlat2.y;
        u_xlat12 = hlslcc_movcTemp;
    }
    u_xlat12.xy = u_xlat12.xy + float2(-0.5, -0.5);
    u_xlat12.xy = u_xlat12.xy * float2(0.999000967, 0.999000967) + float2(0.5, 0.5);
    u_xlat0.xy = (bool(u_xlatb1)) ? u_xlat12.xy : u_xlat0.xy;
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
