// ---------------------------------------------------------------------------
// Ui Color Picker Hue Wheel (NV)
// origem : assets/effects/nv-nodevideo-ui-color-picker-hue-wheel.xml
// id     : nv.effect.nodevideo-ui-color-picker-hue-wheel
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_ui_color_picker_hue_wheelParams { int __vazio; };

// --- funcoes auxiliares do efeito
float2 u_xlat16_0;
float3 u_xlat1;
float3 u_xlat2;
bool3 u_xlatb2;
float u_xlat4;
bool u_xlatb4;
float2 u_xlat7;
bool u_xlatb7;
bool u_xlatb10;

fragment float4 fx_nv_nodevideo_ui_color_picker_hue_wheel(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_ui_color_picker_hue_wheelParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat16_0.xy = (-in.acScreenNorm.yx) + float2(0.5, 0.5);
    u_xlat1.x = max(abs(u_xlat16_0.y), abs(u_xlat16_0.x));
    u_xlat1.x = float(1.0) / u_xlat1.x;
    u_xlat4 = min(abs(u_xlat16_0.y), abs(u_xlat16_0.x));
    u_xlat1.x = u_xlat1.x * u_xlat4;
    u_xlat4 = u_xlat1.x * u_xlat1.x;
    u_xlat7.x = u_xlat4 * 0.0208350997 + -0.0851330012;
    u_xlat7.x = u_xlat4 * u_xlat7.x + 0.180141002;
    u_xlat7.x = u_xlat4 * u_xlat7.x + -0.330299497;
    u_xlat4 = u_xlat4 * u_xlat7.x + 0.999866009;
    u_xlat7.x = u_xlat4 * u_xlat1.x;
    u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
    u_xlatb10 = abs(u_xlat16_0.y)<abs(u_xlat16_0.x);
    u_xlat7.x = u_xlatb10 ? u_xlat7.x : float(0.0);
    u_xlat1.x = u_xlat1.x * u_xlat4 + u_xlat7.x;
    u_xlatb4 = u_xlat16_0.y<(-u_xlat16_0.y);
    u_xlat4 = u_xlatb4 ? -3.14159274 : float(0.0);
    u_xlat1.x = u_xlat4 + u_xlat1.x;
    u_xlat4 = min(u_xlat16_0.y, u_xlat16_0.x);
    u_xlat7.x = max(u_xlat16_0.y, u_xlat16_0.x);
    u_xlatb7 = u_xlat7.x>=(-u_xlat7.x);
    u_xlatb4 = u_xlat4<(-u_xlat4);
    u_xlatb4 = u_xlatb7 && u_xlatb4;
    u_xlat1.x = (u_xlatb4) ? (-u_xlat1.x) : u_xlat1.x;
    u_xlat1.x = u_xlat1.x * 0.159154937 + 0.5;
    u_xlat1.xyz = u_xlat1.xxx * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
    u_xlat1.xyz = u_xlat1.xyz * float3(0.166666672, 0.166666672, 0.166666672);
    u_xlatb2.xyz = greaterThanEqual(u_xlat1.xyzx, (-u_xlat1.xyzx)).xyz;
    u_xlat1.xyz = fract(abs(u_xlat1.xyz));
    {
        float3 hlslcc_movcTemp = u_xlat1;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? u_xlat1.x : (-u_xlat1.x);
        hlslcc_movcTemp.y = (u_xlatb2.y) ? u_xlat1.y : (-u_xlat1.y);
        hlslcc_movcTemp.z = (u_xlatb2.z) ? u_xlat1.z : (-u_xlat1.z);
        u_xlat1 = hlslcc_movcTemp;
    }
    u_xlat1.xyz = u_xlat1.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
    u_xlat1.xyz = abs(u_xlat1.xyz) + float3(-1.0, -1.0, -1.0);
    u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
    u_xlat2.xyz = u_xlat1.xyz * u_xlat1.xyz;
    u_xlat2.xyz = u_xlat1.xyz * u_xlat2.xyz;
    u_xlat1.xyz = (-u_xlat1.xyz) * float3(2.0, 2.0, 2.0) + float3(3.0, 3.0, 3.0);
    u_xlat1.xyz = u_xlat1.xyz * u_xlat2.xyz;
    u_xlat2.xyz = u_xlat1.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat2.xyz = u_xlat1.xyz * u_xlat2.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    __nv_out.xyz = u_xlat1.xyz * u_xlat2.xyz;
    u_xlat1.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat1.x = dot(u_xlat1.xy, u_xlat1.xy);
    u_xlat1.xy = u_xlat1.xx * float2(4.0, 4.0) + float2(-0.99000001, -0.495000005);
    u_xlat1.xy = u_xlat1.xy * float2(50.0000496, 100.000099);
    u_xlat1.xy = clamp(u_xlat1.xy, 0.0, 1.0);
    u_xlat7.xy = u_xlat1.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
    u_xlat1.xy = u_xlat1.xy * u_xlat1.xy;
    u_xlat1.xy = (-u_xlat7.xy) * u_xlat1.xy + float2(1.0, 1.0);
    u_xlat4 = (-u_xlat1.y) + 1.0;
    __nv_out.w = u_xlat4 * u_xlat1.x;
    return __nv_out;
    return __nv_out;
}
