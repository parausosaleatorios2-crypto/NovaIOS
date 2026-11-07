// ---------------------------------------------------------------------------
// Fill Assetstore Water Caustics3 (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-water-caustics3.xml
// id     : nv.effect.nodevideo-fill-assetstore-water-caustics3
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_water_caustics3Params {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _blend_mode;
    float2 _tex_offset;
    float2 _tex_scale;
    float _tex_angle;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat7;
bool2 u_xlatb13;

fragment float4 fx_nv_nodevideo_fill_assetstore_water_caustics3(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_water_caustics3Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> WaterCausticsTex [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = u._tex_angle * 0.0174532998;
    u_xlat2.x = cos(u_xlat1.x);
    u_xlat1.x = sin(u_xlat1.x);
    u_xlat3.x = (-u_xlat1.x);
    u_xlat7.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat7.xy = u_xlat7.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat3.y = u_xlat2.x;
    u_xlat3.z = u_xlat1.x;
    u_xlat2.x = dot(u_xlat7.xy, u_xlat3.yz);
    u_xlat2.y = dot(u_xlat7.xy, u_xlat3.xy);
    u_xlat1.xy = u_xlat2.xy * u._tex_scale.xy + float2(0.5, 0.5);
    u_xlat1.xy = u_xlat1.xy + (-float2(u._tex_offset.x, u._tex_offset.y));
    u_xlatb13.xy = greaterThanEqual(u_xlat1.xyxy, (-u_xlat1.xyxy)).xy;
    u_xlat1.xy = fract(abs(u_xlat1.xy));
    {
        float4 hlslcc_movcTemp = u_xlat1;
        hlslcc_movcTemp.x = (u_xlatb13.x) ? u_xlat1.x : (-u_xlat1.x);
        hlslcc_movcTemp.y = (u_xlatb13.y) ? u_xlat1.y : (-u_xlat1.y);
        u_xlat1 = hlslcc_movcTemp;
    }
    u_xlatb13.xy = lessThan(u_xlat1.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    {
        float4 hlslcc_movcTemp = u_xlat1;
        hlslcc_movcTemp.x = (u_xlatb13.x) ? (-u_xlat1.x) : u_xlat1.x;
        hlslcc_movcTemp.y = (u_xlatb13.y) ? (-u_xlat1.y) : u_xlat1.y;
        u_xlat1 = hlslcc_movcTemp;
    }
    u_xlat1 = WaterCausticsTex.sample(__nv_smp, u_xlat1.xy);
    u_xlatb2.x = int(u._blend_mode)==1;
    u_xlat3 = u_xlat0 * u_xlat1;
    u_xlat4.xyz = u_xlat0.xyz + u_xlat1.xyz;
    u_xlat4.w = u_xlat0.w;
    u_xlat2 = (u_xlatb2.x) ? u_xlat3 : u_xlat4;
    u_xlat3.xyz = u_xlat1.xyz;
    u_xlat1 = (int(u._blend_mode) != 0) ? u_xlat2 : u_xlat3;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat3 * u_xlat4 + u_xlat0;
        u_xlat2.x = u_xlat4.x * u_xlat0.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat0.w;
        __nv_out.xyz = u_xlat0.xyz;
    } else {
        __nv_out = u_xlat1;
    }
    return __nv_out;
    return __nv_out;
}
