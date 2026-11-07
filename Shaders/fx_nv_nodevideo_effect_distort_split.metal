// ---------------------------------------------------------------------------
// Effect Distort Split (NV)
// origem : assets/effects/nv-nodevideo-effect-distort-split.xml
// id     : nv.effect.nodevideo-effect-distort-split
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_distort_splitParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _split;
    float2 _scale;
    float2 _pointA;
    float2 _pointB;
    float _fix_edge;
    float _bidirection;
    float _shape;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float2 u_xlat0;
bool2 u_xlatb0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float u_xlat8;
bool u_xlatb8;
float u_xlat12;
float u_xlat13;
float u_xlat18;
float u_xlat19;
bool u_xlatb19;

fragment float4 fx_nv_nodevideo_effect_distort_split(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_distort_splitParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = float2(_viewport_ratio.x, _viewport_ratio.y) * u._pointA.xy;
    u_xlat1.xy = float2(u._pointB.x, u._pointB.y) * float2(_viewport_ratio.x, _viewport_ratio.y) + (-u_xlat0.xy);
    u_xlat12 = u_xlat0.y * u_xlat1.x;
    u_xlat12 = u_xlat1.y * u_xlat0.x + (-u_xlat12);
    u_xlat1.zw = (-u_xlat1.yy);
    u_xlat18 = dot(u_xlat1.xz, u_xlat1.xw);
    u_xlat13 = sqrt(u_xlat18);
    u_xlat2.xy = in.acScreenNorm.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat19 = u_xlat1.x * u_xlat2.y;
    u_xlat19 = (-u_xlat1.y) * u_xlat2.x + u_xlat19;
    u_xlat12 = u_xlat12 + u_xlat19;
    u_xlat12 = u_xlat12 / u_xlat13;
    u_xlat0.xy = in.acScreenNorm.xy * float2(_viewport_ratio.x, _viewport_ratio.y) + (-u_xlat0.xy);
    u_xlat0.x = dot(u_xlat1.xy, u_xlat0.xy);
    u_xlat6.x = dot(u_xlat1.xy, u_xlat1.xy);
    u_xlat0.x = u_xlat0.x / u_xlat6.x;
    if(int(u._shape) == 0) {
        u_xlat13 = u_xlat0.x + -0.5;
        u_xlat13 = dot(float2(u_xlat13), u._scale.xxyx.yy);
        u_xlat13 = u_xlat13 * u_xlat13;
        u_xlat13 = u_xlat13 * -0.5;
        u_xlat13 = u_xlat13 / u._scale.xxyx.z;
        u_xlat13 = u_xlat13 * 1.44269502;
        u_xlat13 = exp2(u_xlat13);
        u_xlat19 = u._scale.xxyx.z * 6.28318548;
        u_xlat19 = sqrt(u_xlat19);
        u_xlat13 = u_xlat13 / u_xlat19;
        u_xlat19 = sqrt(u_xlat6.x);
        u_xlat13 = u_xlat19 * u_xlat13;
    } else {
        u_xlatb19 = int(u._shape)==1;
        u_xlat0.x = u_xlat0.x + -0.5;
        u_xlat0.x = u_xlat0.x * u._scale.xxyx.y;
        u_xlat2.x = (-u_xlat0.x) * u_xlat0.x + u._scale.xxyx.z;
        u_xlatb8 = u_xlat2.x>=0.0;
        u_xlat2.x = sqrt(u_xlat2.x);
        u_xlat2.x = u_xlatb8 ? u_xlat2.x : float(0.0);
        u_xlat6.x = sqrt(u_xlat6.x);
        u_xlat2.x = u_xlat6.x * u_xlat2.x;
        u_xlat0.x = u_xlat0.x + u_xlat0.x;
        u_xlat8 = u._scale.xxyx.y + u._scale.xxyx.y;
        u_xlat0.x = u_xlat0.x / u_xlat8;
        u_xlat0.x = u_xlat0.x + 0.5;
        u_xlatb8 = u_xlat0.x<0.0;
        u_xlatb0.x = 1.0<u_xlat0.x;
        u_xlatb0.x = u_xlatb0.x || u_xlatb8;
        u_xlat0.x = (u_xlatb0.x) ? 0.0 : u._scale.xxyx.z;
        u_xlat0.x = u_xlat6.x * u_xlat0.x;
        u_xlat13 = (u_xlatb19) ? u_xlat2.x : u_xlat0.x;
    }
    u_xlat2 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0.x = rsqrt(u_xlat18);
    u_xlat6.xz = u_xlat1.yx * float2(-1.0, 1.0);
    u_xlat0.xy = u_xlat0.xx * u_xlat6.xz;
    u_xlat0.xy = u_xlat0.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat18 = u_xlat13 * u._split;
    u_xlatb1 = 0.0<u_xlat12;
    if(u_xlatb1){
        u_xlatb1 = u_xlat18<u_xlat12;
        if(u_xlatb1){
            u_xlat1.xy = float2(u_xlat18) * u_xlat0.xy;
            u_xlat19 = (-u_xlat13) * u._split + u_xlat12;
            u_xlat19 = (-u_xlat19) * u._fix_edge;
            u_xlat19 = u_xlat19 * 14.4269505;
            u_xlat19 = exp2(u_xlat19);
            u_xlat1.xy = (-u_xlat1.xy) * float2(u_xlat19) + in.acScreenNorm.xy;
            u_xlat3 = inputImg.sample(__nv_smp, u_xlat1.xy);
        } else {
            u_xlat3.x = float(0.0);
            u_xlat3.y = float(0.0);
            u_xlat3.z = float(0.0);
            u_xlat3.w = float(0.0);
        }
    } else {
        u_xlatb1 = 0<int(u._bidirection);
        if(u_xlatb1){
            u_xlatb1 = u_xlat18<(-u_xlat12);
            if(u_xlatb1){
                u_xlat0.xy = float2(u_xlat18) * u_xlat0.xy;
                u_xlat12 = (-u_xlat13) * u._split + (-u_xlat12);
                u_xlat12 = (-u_xlat12) * u._fix_edge;
                u_xlat12 = u_xlat12 * 14.4269505;
                u_xlat12 = exp2(u_xlat12);
                u_xlat0.xy = u_xlat0.xy * float2(u_xlat12) + in.acScreenNorm.xy;
                u_xlat3 = inputImg.sample(__nv_smp, u_xlat0.xy);
            } else {
                u_xlat3.x = float(0.0);
                u_xlat3.y = float(0.0);
                u_xlat3.z = float(0.0);
                u_xlat3.w = float(0.0);
            }
        } else {
            u_xlat3 = u_xlat2;
        }
    }
    if(int(u._use_inner_mask) != 0) {
        u_xlatb0.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat1 = (u_xlatb0.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat3;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat2 = u_xlat2 * u_xlat5;
        u_xlat1 = u_xlat1 * u_xlat4 + u_xlat2;
        u_xlat0.x = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb0.y) ? u_xlat0.x : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat3;
    }
    return __nv_out;
    return __nv_out;
}
