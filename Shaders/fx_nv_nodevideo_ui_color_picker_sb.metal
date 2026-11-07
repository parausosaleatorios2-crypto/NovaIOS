// ---------------------------------------------------------------------------
// Ui Color Picker Sb (NV)
// origem : assets/effects/nv-nodevideo-ui-color-picker-sb.xml
// id     : nv.effect.nodevideo-ui-color-picker-sb
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_ui_color_picker_sbParams {
    float _color_picker_h;
};

// --- funcoes auxiliares do efeito
float3 u_xlat0;
float3 u_xlat1;
bool3 u_xlatb1;
float u_xlat16_2;

fragment float4 fx_nv_nodevideo_ui_color_picker_sb(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_ui_color_picker_sbParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = float3(u._color_picker_h) * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
    u_xlat0.xyz = u_xlat0.xyz * float3(0.166666672, 0.166666672, 0.166666672);
    u_xlatb1.xyz = greaterThanEqual(u_xlat0.xyzx, (-u_xlat0.xyzx)).xyz;
    u_xlat0.xyz = fract(abs(u_xlat0.xyz));
    {
        float3 hlslcc_movcTemp = u_xlat0;
        hlslcc_movcTemp.x = (u_xlatb1.x) ? u_xlat0.x : (-u_xlat0.x);
        hlslcc_movcTemp.y = (u_xlatb1.y) ? u_xlat0.y : (-u_xlat0.y);
        hlslcc_movcTemp.z = (u_xlatb1.z) ? u_xlat0.z : (-u_xlat0.z);
        u_xlat0 = hlslcc_movcTemp;
    }
    u_xlat0.xyz = u_xlat0.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
    u_xlat0.xyz = abs(u_xlat0.xyz) + float3(-1.0, -1.0, -1.0);
    u_xlat0.xyz = clamp(u_xlat0.xyz, 0.0, 1.0);
    u_xlat1.xyz = u_xlat0.xyz * u_xlat0.xyz;
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xyz;
    u_xlat0.xyz = (-u_xlat0.xyz) * float3(2.0, 2.0, 2.0) + float3(3.0, 3.0, 3.0);
    u_xlat0.xyz = u_xlat1.xyz * u_xlat0.xyz + float3(-1.0, -1.0, -1.0);
    u_xlat0.xyz = in.acScreenNorm.xxx * u_xlat0.xyz + float3(1.0, 1.0, 1.0);
    u_xlat16_2 = (-in.acScreenNorm.y) + 1.0;
    u_xlat16_2 = u_xlat16_2 * -4.1844244;
    u_xlat16_2 = exp2(u_xlat16_2);
    u_xlat0.xyz = u_xlat0.xyz * float3(u_xlat16_2);
    u_xlat1.xyz = u_xlat0.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    __nv_out.xyz = u_xlat0.xyz * u_xlat1.xyz;
    __nv_out.w = 1.0;
    return __nv_out;
    return __nv_out;
}
