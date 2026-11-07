// ---------------------------------------------------------------------------
// Rendercommand Color Mask (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-color-mask.xml
// id     : nv.effect.nodevideo-rendercommand-color-mask
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_color_maskParams {
    float4 _h_range;
    float4 _s_range;
    float4 _l_range;
    float _invert;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
int2 u_xlati2;
bool2 u_xlatb2;
float3 u_xlat3;
int2 u_xlati3;
bool2 u_xlatb3;
float2 u_xlat4;
float2 u_xlat5;
bool u_xlatb5;
float2 u_xlat6;
int2 u_xlati6;
bool2 u_xlatb6;
float u_xlat7;
bool u_xlatb7;
float u_xlat10;
bool u_xlatb10;
float u_xlat11;
bool u_xlatb11;
float2 u_xlat12;
bool2 u_xlatb13;
float u_xlat15;
bool u_xlatb15;
float u_xlat16;
bool u_xlatb16;

fragment float4 fx_nv_nodevideo_rendercommand_color_mask(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_color_maskParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.z = float(-1.0);
    u_xlat0.w = float(0.666666687);
    u_xlat1.z = float(1.0);
    u_xlat1.w = float(-1.0);
    u_xlat2.xyz = inputImg.sample(__nv_smp, in.acScreenNorm.xy).xyz;
    u_xlat3.xyz = max(u_xlat2.xyz, float3(0.0, 0.0, 0.0));
    __nv_out.xyz = u_xlat2.xyz;
    u_xlat2.xyz = log2(u_xlat3.xyz);
    u_xlat2.xyz = u_xlat2.xyz * float3(0.416666657, 0.416666657, 0.416666657);
    u_xlat2.xyz = exp2(u_xlat2.xyz);
    u_xlat2.xyz = u_xlat2.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
    u_xlat2.xyw = max(u_xlat2.yzx, float3(0.0, 0.0, 0.0));
    u_xlatb3.x = u_xlat2.x>=u_xlat2.y;
    u_xlat3.x = u_xlatb3.x ? 1.0 : float(0.0);
    u_xlat0.xy = u_xlat2.yx;
    u_xlat1.xy = (-u_xlat0.xy) + u_xlat2.xy;
    u_xlat0 = u_xlat3.xxxx * u_xlat1 + u_xlat0;
    u_xlatb1 = u_xlat2.w>=u_xlat0.x;
    u_xlat1.x = u_xlatb1 ? 1.0 : float(0.0);
    u_xlat2.xyz = u_xlat0.xyw;
    u_xlat0.xyw = u_xlat2.wyx;
    u_xlat0 = (-u_xlat2) + u_xlat0;
    u_xlat0 = u_xlat1.xxxx * u_xlat0 + u_xlat2;
    u_xlat1.x = min(u_xlat0.y, u_xlat0.w);
    u_xlat1.x = u_xlat0.x + (-u_xlat1.x);
    u_xlat6.x = u_xlat1.x * 6.0 + 1.00000001e-10;
    u_xlat5.x = (-u_xlat0.y) + u_xlat0.w;
    u_xlat5.x = u_xlat5.x / u_xlat6.x;
    u_xlat5.x = u_xlat5.x + u_xlat0.z;
    u_xlat10 = u._h_range.y + u._h_range.x;
    u_xlatb15 = u_xlat10<abs(u_xlat5.x);
    u_xlat6.x = u_xlat10 + u._h_range.z;
    u_xlatb11 = abs(u_xlat5.x)<u_xlat6.x;
    u_xlatb15 = u_xlatb15 && u_xlatb11;
    u_xlat11 = (-u_xlat10) + abs(u_xlat5.x);
    u_xlat11 = u_xlat11 / u._h_range.z;
    u_xlat11 = (-u_xlat11) + 1.0;
    u_xlatb16 = abs(u_xlat5.x)<u_xlat10;
    u_xlat2.x = (-u._h_range.y) + u._h_range.x;
    u_xlatb7 = u_xlat2.x<abs(u_xlat5.x);
    u_xlatb16 = u_xlatb16 && u_xlatb7;
    u_xlat16 = u_xlatb16 ? 1.0 : float(0.0);
    u_xlat15 = (u_xlatb15) ? u_xlat11 : u_xlat16;
    u_xlatb11 = abs(u_xlat5.x)<u_xlat2.x;
    u_xlat16 = u_xlat2.x + (-u._h_range.z);
    u_xlatb7 = u_xlat16<abs(u_xlat5.x);
    u_xlatb11 = u_xlatb11 && u_xlatb7;
    u_xlat7 = abs(u_xlat5.x) + (-u_xlat16);
    u_xlat12.xy = abs(u_xlat5.xx) + float2(1.0, -1.0);
    u_xlat5.x = (-u_xlat16) + u_xlat2.x;
    u_xlat7 = u_xlat7 / u_xlat5.x;
    u_xlat7 = (-u_xlat7) + 1.0;
    u_xlat15 = (u_xlatb11) ? u_xlat7 : u_xlat15;
    u_xlatb3.xy = lessThan(float4(u_xlat10), u_xlat12.xyxx).xy;
    u_xlatb6.xy = lessThan(u_xlat12.xyxx, u_xlat6.xxxx).xy;
    u_xlati6.xy = int2(uint2((uint(u_xlatb6.x) * 0xffffffffu) & (uint(u_xlatb3.x) * 0xffffffffu), (uint(u_xlatb6.y) * 0xffffffffu) & (uint(u_xlatb3.y) * 0xffffffffu)));
    u_xlatb3.xy = lessThan(u_xlat2.xxxx, u_xlat12.xyxx).xy;
    u_xlatb2.xy = lessThan(u_xlat12.xyxx, u_xlat2.xxxx).xy;
    u_xlatb13.xy = lessThan(u_xlat12.xyxy, float4(u_xlat10)).xy;
    u_xlat4.xy = (-float2(u_xlat10)) + u_xlat12.xy;
    u_xlat4.xy = u_xlat4.xy / u._h_range.zz;
    u_xlat4.xy = (-u_xlat4.xy) + float2(1.0, 1.0);
    u_xlati3.xy = int2(uint2((uint(u_xlatb13.x) * 0xffffffffu) & (uint(u_xlatb3.x) * 0xffffffffu), (uint(u_xlatb13.y) * 0xffffffffu) & (uint(u_xlatb3.y) * 0xffffffffu)));
    u_xlat3.xy = as_type<float>(uint2(uint(u_xlati3.x) & uint(1065353216u), uint(u_xlati3.y) & uint(1065353216u)));
    u_xlat6.x = (u_xlati6.x != 0) ? u_xlat4.x : u_xlat3.x;
    u_xlat6.y = (u_xlati6.y != 0) ? u_xlat4.y : u_xlat3.y;
    u_xlatb3.xy = lessThan(float4(u_xlat16), u_xlat12.xyxx).xy;
    u_xlat12.xy = (-float2(u_xlat16)) + u_xlat12.xy;
    u_xlat5.xy = u_xlat12.xy / u_xlat5.xx;
    u_xlat5.xy = (-u_xlat5.xy) + float2(1.0, 1.0);
    u_xlati2.xy = int2(uint2((uint(u_xlatb2.x) * 0xffffffffu) & (uint(u_xlatb3.x) * 0xffffffffu), (uint(u_xlatb2.y) * 0xffffffffu) & (uint(u_xlatb3.y) * 0xffffffffu)));
    {
        float2 hlslcc_movcTemp = u_xlat5;
        hlslcc_movcTemp.x = (u_xlati2.x != 0) ? u_xlat5.x : u_xlat6.x;
        hlslcc_movcTemp.y = (u_xlati2.y != 0) ? u_xlat5.y : u_xlat6.y;
        u_xlat5 = hlslcc_movcTemp;
    }
    u_xlat5.x = u_xlat5.x + u_xlat15;
    u_xlat5.x = u_xlat5.y + u_xlat5.x;
    u_xlat10 = u_xlat0.x + 1.00000001e-10;
    u_xlat10 = u_xlat1.x / u_xlat10;
    u_xlat15 = u._s_range.y + u._s_range.x;
    u_xlat1.x = u_xlat15 + u._s_range.z;
    u_xlatb1 = u_xlat10<u_xlat1.x;
    u_xlatb6.x = u_xlat15<u_xlat10;
    u_xlatb1 = u_xlatb1 && u_xlatb6.x;
    u_xlat6.x = (-u_xlat15) + u_xlat10;
    u_xlatb15 = u_xlat10<u_xlat15;
    u_xlat6.x = u_xlat6.x / u._s_range.z;
    u_xlat6.x = (-u_xlat6.x) + 1.0;
    u_xlat11 = (-u._s_range.y) + u._s_range.x;
    u_xlatb16 = u_xlat11<u_xlat10;
    u_xlatb15 = u_xlatb15 && u_xlatb16;
    u_xlat15 = u_xlatb15 ? 1.0 : float(0.0);
    u_xlat15 = (u_xlatb1) ? u_xlat6.x : u_xlat15;
    u_xlat1.x = u_xlat11 + (-u._s_range.z);
    u_xlat6.x = u_xlat10 + (-u_xlat1.x);
    u_xlat16 = (-u_xlat1.x) + u_xlat11;
    u_xlatb11 = u_xlat10<u_xlat11;
    u_xlatb10 = u_xlat1.x<u_xlat10;
    u_xlatb10 = u_xlatb11 && u_xlatb10;
    u_xlat1.x = u_xlat6.x / u_xlat16;
    u_xlat1.x = (-u_xlat1.x) + 1.0;
    u_xlat10 = (u_xlatb10) ? u_xlat1.x : u_xlat15;
    u_xlat5.x = u_xlat10 * u_xlat5.x;
    u_xlat10 = u._l_range.y + u._l_range.x;
    u_xlat15 = u_xlat10 + u._l_range.z;
    u_xlatb15 = u_xlat0.x<u_xlat15;
    u_xlatb1 = u_xlat10<u_xlat0.x;
    u_xlatb15 = u_xlatb15 && u_xlatb1;
    u_xlat1.x = (-u_xlat10) + u_xlat0.x;
    u_xlatb10 = u_xlat0.x<u_xlat10;
    u_xlat1.x = u_xlat1.x / u._l_range.z;
    u_xlat1.x = (-u_xlat1.x) + 1.0;
    u_xlat6.x = (-u._l_range.y) + u._l_range.x;
    u_xlatb11 = u_xlat6.x<u_xlat0.x;
    u_xlatb10 = u_xlatb10 && u_xlatb11;
    u_xlat10 = u_xlatb10 ? 1.0 : float(0.0);
    u_xlat10 = (u_xlatb15) ? u_xlat1.x : u_xlat10;
    u_xlatb15 = u_xlat0.x<u_xlat6.x;
    u_xlat1.x = u_xlat6.x + (-u._l_range.z);
    u_xlat6.x = (-u_xlat1.x) + u_xlat6.x;
    u_xlatb11 = u_xlat1.x<u_xlat0.x;
    u_xlat0.x = u_xlat0.x + (-u_xlat1.x);
    u_xlat0.x = u_xlat0.x / u_xlat6.x;
    u_xlat0.x = (-u_xlat0.x) + 1.0;
    u_xlatb15 = u_xlatb15 && u_xlatb11;
    u_xlat0.x = (u_xlatb15) ? u_xlat0.x : u_xlat10;
    u_xlat10 = u_xlat0.x * u_xlat5.x;
    u_xlat0.x = (-u_xlat5.x) * u_xlat0.x + 1.0;
    u_xlatb5 = int(u._invert)==1;
    __nv_out.w = (u_xlatb5) ? u_xlat0.x : u_xlat10;
    return __nv_out;
    return __nv_out;
}
