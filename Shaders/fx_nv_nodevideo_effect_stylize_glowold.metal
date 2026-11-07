// ---------------------------------------------------------------------------
// Effect Stylize Glowold (NV)
// origem : assets/effects/nv-nodevideo-effect-stylize-glowold.xml
// id     : nv.effect.nodevideo-effect-stylize-glowold
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_stylize_glowoldParams {
    float4 _BloomThreshold;
    float4 _glow_color;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _SourceTex_TexelSize (1.0 / float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))))
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
float4 u_xlat3;
float3 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float4 u_xlat7;
float3 u_xlat8;
float4 u_xlat9;
float3 u_xlat10;
float4 u_xlat11;
float3 u_xlat12;
float u_xlat14;
float u_xlat39;

fragment float4 fx_nv_nodevideo_effect_stylize_glowold(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_stylize_glowoldParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = (-_SourceTex_TexelSize.xy) * float2(0.0, 0.899999976) + in.acScreenNorm.xy;
    u_xlat0.xyz = inputImg.sample(__nv_smp, u_xlat0.xy).xyz;
    u_xlat1 = _SourceTex_TexelSize.xyxy * float4(-0.899999976, -0.899999976, 0.899999976, -0.899999976) + in.acScreenNorm.xyxy;
    u_xlat2.xyz = inputImg.sample(__nv_smp, u_xlat1.xy).xyz;
    u_xlat1.xyz = inputImg.sample(__nv_smp, u_xlat1.zw).xyz;
    u_xlat3.xy = (-_SourceTex_TexelSize.xy) * float2(0.899999976, 0.0) + in.acScreenNorm.xy;
    u_xlat3.xyz = inputImg.sample(__nv_smp, u_xlat3.xy).xyz;
    u_xlat4.xyz = inputImg.sample(__nv_smp, in.acScreenNorm.xy).xyz;
    u_xlat5.xyz = u_xlat3.xyz + u_xlat4.xyz;
    u_xlat2.xyz = u_xlat2.xyz + u_xlat5.xyz;
    u_xlat2.xyz = u_xlat0.xyz + u_xlat2.xyz;
    u_xlat5 = _SourceTex_TexelSize.xyxy * float4(0.899999976, 0.899999976, -1.45000005, 0.449999988) + in.acScreenNorm.xyxy;
    u_xlat6.xyz = inputImg.sample(__nv_smp, u_xlat5.xy).xyz;
    u_xlat5.xyz = inputImg.sample(__nv_smp, u_xlat5.zw).xyz;
    u_xlat7 = _SourceTex_TexelSize.xyxy * float4(-0.899999976, 0.899999976, 0.0, 0.899999976) + in.acScreenNorm.xyxy;
    u_xlat8.xyz = inputImg.sample(__nv_smp, u_xlat7.zw).xyz;
    u_xlat7.xyz = inputImg.sample(__nv_smp, u_xlat7.xy).xyz;
    u_xlat7.xyz = u_xlat8.xyz + u_xlat7.xyz;
    u_xlat6.xyz = u_xlat6.xyz + u_xlat8.xyz;
    u_xlat6.xyz = u_xlat4.xyz + u_xlat6.xyz;
    u_xlat3.xyz = u_xlat3.xyz + u_xlat7.xyz;
    u_xlat3.xyz = u_xlat4.xyz + u_xlat3.xyz;
    u_xlat3.xyz = u_xlat3.xyz * float3(0.0208333004, 0.0208333004, 0.0208333004);
    u_xlat7 = _SourceTex_TexelSize.xyxy * float4(1.45000005, 0.449999988, 0.899999976, 0.0) + in.acScreenNorm.xyxy;
    u_xlat8.xyz = inputImg.sample(__nv_smp, u_xlat7.zw).xyz;
    u_xlat7.xyz = inputImg.sample(__nv_smp, u_xlat7.xy).xyz;
    u_xlat6.xyz = u_xlat6.xyz + u_xlat8.xyz;
    u_xlat4.xyz = u_xlat4.xyz + u_xlat8.xyz;
    u_xlat0.xyz = u_xlat0.xyz + u_xlat4.xyz;
    u_xlat0.xyz = u_xlat1.xyz + u_xlat0.xyz;
    u_xlat1 = _SourceTex_TexelSize.xyxy * float4(-0.449999988, 0.449999988, 0.449999988, 0.449999988) + in.acScreenNorm.xyxy;
    u_xlat4.xyz = inputImg.sample(__nv_smp, u_xlat1.xy).xyz;
    u_xlat1.xyz = inputImg.sample(__nv_smp, u_xlat1.zw).xyz;
    u_xlat8.xyz = u_xlat1.xyz + u_xlat4.xyz;
    u_xlat9 = _SourceTex_TexelSize.xyxy * float4(-1.45000005, -0.449999988, -0.449999988, -0.449999988) + in.acScreenNorm.xyxy;
    u_xlat10.xyz = inputImg.sample(__nv_smp, u_xlat9.zw).xyz;
    u_xlat9.xyz = inputImg.sample(__nv_smp, u_xlat9.xy).xyz;
    u_xlat8.xyz = u_xlat8.xyz + u_xlat10.xyz;
    u_xlat11 = _SourceTex_TexelSize.xyxy * float4(0.449999988, -0.449999988, 1.45000005, -0.449999988) + in.acScreenNorm.xyxy;
    u_xlat12.xyz = inputImg.sample(__nv_smp, u_xlat11.xy).xyz;
    u_xlat11.xyz = inputImg.sample(__nv_smp, u_xlat11.zw).xyz;
    u_xlat8.xyz = u_xlat8.xyz + u_xlat12.xyz;
    u_xlat3.xyz = u_xlat8.xyz * float3(0.0833332986, 0.0833332986, 0.0833332986) + u_xlat3.xyz;
    u_xlat3.xyz = u_xlat6.xyz * float3(0.0208333004, 0.0208333004, 0.0208333004) + u_xlat3.xyz;
    u_xlat2.xyz = u_xlat2.xyz * float3(0.0208333004, 0.0208333004, 0.0208333004) + u_xlat3.xyz;
    u_xlat0.xyz = u_xlat0.xyz * float3(0.0208333004, 0.0208333004, 0.0208333004) + u_xlat2.xyz;
    u_xlat2 = _SourceTex_TexelSize.xyxy * float4(-1.45000005, 1.45000005, -0.449999988, 1.45000005) + in.acScreenNorm.xyxy;
    u_xlat3.xyz = inputImg.sample(__nv_smp, u_xlat2.xy).xyz;
    u_xlat2.xyz = inputImg.sample(__nv_smp, u_xlat2.zw).xyz;
    u_xlat3.xyz = u_xlat2.xyz + u_xlat3.xyz;
    u_xlat3.xyz = u_xlat5.xyz + u_xlat3.xyz;
    u_xlat5.xyz = u_xlat4.xyz + u_xlat5.xyz;
    u_xlat5.xyz = u_xlat9.xyz + u_xlat5.xyz;
    u_xlat6.xyz = u_xlat10.xyz + u_xlat9.xyz;
    u_xlat5.xyz = u_xlat10.xyz + u_xlat5.xyz;
    u_xlat9.xyz = u_xlat10.xyz + u_xlat12.xyz;
    u_xlat3.xyz = u_xlat4.xyz + u_xlat3.xyz;
    u_xlat0.xyz = u_xlat3.xyz * float3(0.00923329964, 0.00923329964, 0.00923329964) + u_xlat0.xyz;
    u_xlat3 = _SourceTex_TexelSize.xyxy * float4(0.449999988, 1.45000005, 1.45000005, 1.45000005) + in.acScreenNorm.xyxy;
    u_xlat10.xyz = inputImg.sample(__nv_smp, u_xlat3.xy).xyz;
    u_xlat3.xyz = inputImg.sample(__nv_smp, u_xlat3.zw).xyz;
    u_xlat3.xyz = u_xlat3.xyz + u_xlat10.xyz;
    u_xlat2.xyz = u_xlat2.xyz + u_xlat10.xyz;
    u_xlat2.xyz = u_xlat4.xyz + u_xlat2.xyz;
    u_xlat2.xyz = u_xlat1.xyz + u_xlat2.xyz;
    u_xlat0.xyz = u_xlat2.xyz * float3(0.00923329964, 0.00923329964, 0.00923329964) + u_xlat0.xyz;
    u_xlat2.xyz = u_xlat1.xyz + u_xlat3.xyz;
    u_xlat1.xyz = u_xlat7.xyz + u_xlat1.xyz;
    u_xlat2.xyz = u_xlat7.xyz + u_xlat2.xyz;
    u_xlat0.xyz = u_xlat2.xyz * float3(0.00923329964, 0.00923329964, 0.00923329964) + u_xlat0.xyz;
    u_xlat0.xyz = u_xlat5.xyz * float3(0.00923329964, 0.00923329964, 0.00923329964) + u_xlat0.xyz;
    u_xlat0.xyz = u_xlat8.xyz * float3(0.00923329964, 0.00923329964, 0.00923329964) + u_xlat0.xyz;
    u_xlat1.xyz = u_xlat12.xyz + u_xlat1.xyz;
    u_xlat2.xyz = u_xlat11.xyz + u_xlat12.xyz;
    u_xlat1.xyz = u_xlat11.xyz + u_xlat1.xyz;
    u_xlat0.xyz = u_xlat1.xyz * float3(0.00923329964, 0.00923329964, 0.00923329964) + u_xlat0.xyz;
    u_xlat1 = _SourceTex_TexelSize.xyxy * float4(-1.45000005, -1.45000005, -0.449999988, -1.45000005) + in.acScreenNorm.xyxy;
    u_xlat3.xyz = inputImg.sample(__nv_smp, u_xlat1.xy).xyz;
    u_xlat1.xyz = inputImg.sample(__nv_smp, u_xlat1.zw).xyz;
    u_xlat3.xyz = u_xlat3.xyz + u_xlat6.xyz;
    u_xlat3.xyz = u_xlat1.xyz + u_xlat3.xyz;
    u_xlat1.xyz = u_xlat1.xyz + u_xlat9.xyz;
    u_xlat0.xyz = u_xlat3.xyz * float3(0.00923329964, 0.00923329964, 0.00923329964) + u_xlat0.xyz;
    u_xlat3 = _SourceTex_TexelSize.xyxy * float4(0.449999988, -1.45000005, 1.45000005, -1.45000005) + in.acScreenNorm.xyxy;
    u_xlat4.xyz = inputImg.sample(__nv_smp, u_xlat3.xy).xyz;
    u_xlat3.xyz = inputImg.sample(__nv_smp, u_xlat3.zw).xyz;
    u_xlat1.xyz = u_xlat1.xyz + u_xlat4.xyz;
    u_xlat2.xyz = u_xlat2.xyz + u_xlat4.xyz;
    u_xlat2.xyz = u_xlat3.xyz + u_xlat2.xyz;
    u_xlat0.xyz = u_xlat1.xyz * float3(0.00923329964, 0.00923329964, 0.00923329964) + u_xlat0.xyz;
    u_xlat0.xyz = u_xlat2.xyz * float3(0.00923329964, 0.00923329964, 0.00923329964) + u_xlat0.xyz;
    u_xlat39 = dot(u_xlat0.xyz, u_xlat0.xyz);
    u_xlat39 = rsqrt(u_xlat39);
    u_xlat1.xyz = float3(u_xlat39) * u_xlat0.xyz;
    u_xlat0.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
    u_xlat1.xyz = u_xlat1.xyz * u._BloomThreshold.yyy;
    u_xlat0.xyz = min(u_xlat0.xyz, u_xlat1.xyz);
    u_xlat0.xyz = u_xlat0.xyz * float3(0.908999979, 0.908999979, 0.908999979);
    u_xlat39 = max(u_xlat0.z, u_xlat0.y);
    u_xlat39 = max(u_xlat39, u_xlat0.x);
    u_xlat1.x = u_xlat39 + (-u._BloomThreshold.x);
    u_xlat39 = max(u_xlat39, 9.99999975e-05);
    u_xlat14 = u_xlat1.x + 9.99999975e-05;
    u_xlat14 = max(u_xlat14, 0.0);
    u_xlat14 = min(u_xlat14, 0.000199999995);
    u_xlat14 = u_xlat14 * u_xlat14;
    u_xlat14 = u_xlat14 * 2000.00012;
    u_xlat1.x = max(u_xlat1.x, u_xlat14);
    u_xlat0.xyz = u_xlat0.xyz * u_xlat1.xxx;
    u_xlat0.xyz = u_xlat0.xyz / float3(u_xlat39);
    u_xlat0.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
    u_xlat0.w = 1.0;
    __nv_out = u_xlat0 * u._glow_color;
    return __nv_out;
    return __nv_out;
}
