// ---------------------------------------------------------------------------
// Rendercommand Hsl Adjust (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-hsl-adjust.xml
// id     : nv.effect.nodevideo-rendercommand-hsl-adjust
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_hsl_adjustParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _shadow;
    float _shadow_range;
    float2 _midtone;
    float _midtone_range;
    float2 _highlight;
    float _highlight_range;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
bool3 u_xlatb4;
float4 u_xlat5;
bool3 u_xlatb5;
bool3 u_xlatb6;
float u_xlat8;
float u_xlat9;
float u_xlat15;
float u_xlat16;
float u_xlat22;

fragment float4 fx_nv_nodevideo_rendercommand_hsl_adjust(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_hsl_adjustParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb1 = u_xlat0.y>=u_xlat0.z;
    u_xlat1.x = u_xlatb1 ? 1.0 : float(0.0);
    u_xlat2.xy = u_xlat0.zy;
    u_xlat2.z = float(-1.0);
    u_xlat2.w = float(0.666666687);
    u_xlat3.xy = u_xlat0.yz + (-u_xlat2.xy);
    u_xlat3.z = float(1.0);
    u_xlat3.w = float(-1.0);
    u_xlat1 = u_xlat1.xxxx * u_xlat3 + u_xlat2;
    u_xlatb2.x = u_xlat0.x>=u_xlat1.x;
    u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
    u_xlat3.xyz = u_xlat1.xyw;
    u_xlat3.w = u_xlat0.x;
    u_xlat1.xyw = u_xlat3.wyx;
    u_xlat1 = (-u_xlat3) + u_xlat1;
    u_xlat1 = u_xlat2.xxxx * u_xlat1 + u_xlat3;
    u_xlat2.x = min(u_xlat1.y, u_xlat1.w);
    u_xlat2.x = u_xlat1.x + (-u_xlat2.x);
    u_xlat8 = (-u_xlat1.y) + u_xlat1.w;
    u_xlat22 = u_xlat2.x * 6.0 + 1.00000001e-10;
    u_xlat8 = u_xlat8 / u_xlat22;
    u_xlat8 = u_xlat8 + u_xlat1.z;
    u_xlat15 = u_xlat1.x + 1.00000001e-10;
    u_xlat15 = u_xlat2.x / u_xlat15;
    u_xlat22 = (-u_xlat1.x) + 1.0;
    u_xlat22 = u_xlat22 + (-u._shadow_range);
    u_xlat22 = max(u_xlat22, 0.0);
    u_xlat2.x = (-u._shadow_range) + 1.0;
    u_xlat22 = u_xlat22 / u_xlat2.x;
    u_xlat22 = min(u_xlat22, 1.0);
    u_xlat22 = u_xlat22 * u._shadow.y;
    u_xlat2.x = (-u._midtone_range) + 1.0;
    u_xlat2.x = u_xlat2.x * u._midtone.y;
    u_xlat9 = u_xlat1.x + (-u._highlight_range);
    u_xlat9 = max(u_xlat9, 0.0);
    u_xlat16 = (-u._highlight_range) + 1.0;
    u_xlat9 = u_xlat9 / u_xlat16;
    u_xlat9 = min(u_xlat9, 1.0);
    u_xlat2.y = u_xlat9 * u._highlight.y;
    u_xlat22 = u_xlat22 * 0.5;
    u_xlat3.xyz = u._shadow.xxx * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
    u_xlat3.xyz = u_xlat3.xyz * float3(0.166666672, 0.166666672, 0.166666672);
    u_xlatb4.xyz = greaterThanEqual(u_xlat3.xyzx, (-u_xlat3.xyzx)).xyz;
    u_xlat3.xyz = fract(abs(u_xlat3.xyz));
    {
        float4 hlslcc_movcTemp = u_xlat3;
        hlslcc_movcTemp.x = (u_xlatb4.x) ? u_xlat3.x : (-u_xlat3.x);
        hlslcc_movcTemp.y = (u_xlatb4.y) ? u_xlat3.y : (-u_xlat3.y);
        hlslcc_movcTemp.z = (u_xlatb4.z) ? u_xlat3.z : (-u_xlat3.z);
        u_xlat3 = hlslcc_movcTemp;
    }
    u_xlat3.xyz = u_xlat3.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
    u_xlat3.xyz = abs(u_xlat3.xyz) + float3(-1.0, -1.0, -1.0);
    u_xlat3.xyz = clamp(u_xlat3.xyz, 0.0, 1.0);
    u_xlat3.xyz = float3(u_xlat22) * u_xlat3.xyz;
    u_xlat22 = u_xlat2.x * 0.5;
    u_xlat2.xzw = u._midtone.xxx * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
    u_xlat2 = u_xlat2 * float4(0.166666672, 0.5, 0.166666672, 0.166666672);
    u_xlatb4.xyz = greaterThanEqual(u_xlat2.xzwx, (-u_xlat2.xzwx)).xyz;
    u_xlat2.xzw = fract(abs(u_xlat2.xzw));
    {
        float4 hlslcc_movcTemp = u_xlat2;
        hlslcc_movcTemp.x = (u_xlatb4.x) ? u_xlat2.x : (-u_xlat2.x);
        hlslcc_movcTemp.z = (u_xlatb4.y) ? u_xlat2.z : (-u_xlat2.z);
        hlslcc_movcTemp.w = (u_xlatb4.z) ? u_xlat2.w : (-u_xlat2.w);
        u_xlat2 = hlslcc_movcTemp;
    }
    u_xlat2.xzw = u_xlat2.xzw * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
    u_xlat2.xzw = abs(u_xlat2.xzw) + float3(-1.0, -1.0, -1.0);
    u_xlat2.xzw = clamp(u_xlat2.xzw, 0.0, 1.0);
    u_xlat4.xyz = u._highlight.xxx * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
    u_xlat4.xyz = u_xlat4.xyz * float3(0.166666672, 0.166666672, 0.166666672);
    u_xlatb5.xyz = greaterThanEqual(u_xlat4.xyzx, (-u_xlat4.xyzx)).xyz;
    u_xlat4.xyz = fract(abs(u_xlat4.xyz));
    {
        float4 hlslcc_movcTemp = u_xlat4;
        hlslcc_movcTemp.x = (u_xlatb5.x) ? u_xlat4.x : (-u_xlat4.x);
        hlslcc_movcTemp.y = (u_xlatb5.y) ? u_xlat4.y : (-u_xlat4.y);
        hlslcc_movcTemp.z = (u_xlatb5.z) ? u_xlat4.z : (-u_xlat4.z);
        u_xlat4 = hlslcc_movcTemp;
    }
    u_xlat4.xyz = u_xlat4.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
    u_xlat4.xyz = abs(u_xlat4.xyz) + float3(-1.0, -1.0, -1.0);
    u_xlat4.xyz = clamp(u_xlat4.xyz, 0.0, 1.0);
    u_xlat5.xyz = abs(float3(u_xlat8)) * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
    u_xlat5.xyz = u_xlat5.xyz * float3(0.166666672, 0.166666672, 0.166666672);
    u_xlatb6.xyz = greaterThanEqual(u_xlat5.xyzx, (-u_xlat5.xyzx)).xyz;
    u_xlat5.xyz = fract(u_xlat5.xyz);
    {
        float4 hlslcc_movcTemp = u_xlat5;
        hlslcc_movcTemp.x = (u_xlatb6.x) ? u_xlat5.x : (-u_xlat5.x);
        hlslcc_movcTemp.y = (u_xlatb6.y) ? u_xlat5.y : (-u_xlat5.y);
        hlslcc_movcTemp.z = (u_xlatb6.z) ? u_xlat5.z : (-u_xlat5.z);
        u_xlat5 = hlslcc_movcTemp;
    }
    u_xlat5.xyz = u_xlat5.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
    u_xlat5.xyz = abs(u_xlat5.xyz) + float3(-1.0, -1.0, -1.0);
    u_xlat5.xyz = clamp(u_xlat5.xyz, 0.0, 1.0);
    u_xlat5.xyz = u_xlat5.xyz + float3(-1.0, -1.0, -1.0);
    u_xlat5.xyz = float3(u_xlat15) * u_xlat5.xyz + float3(1.0, 1.0, 1.0);
    u_xlat1.xyz = u_xlat1.xxx * u_xlat5.xyz + u_xlat3.xyz;
    u_xlat1.xyz = float3(u_xlat22) * u_xlat2.xzw + u_xlat1.xyz;
    u_xlat1.xyz = u_xlat2.yyy * u_xlat4.xyz + u_xlat1.xyz;
    u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
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
