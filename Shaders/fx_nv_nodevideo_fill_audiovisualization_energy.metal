// ---------------------------------------------------------------------------
// Fill Audiovisualization Energy (NV)
// origem : assets/effects/nv-nodevideo-fill-audiovisualization-energy.xml
// id     : nv.effect.nodevideo-fill-audiovisualization-energy
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_audiovisualization_energyParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _shift;
    float _colour;
    float _power;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
bool3 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat7;
float u_xlat13;
float u_xlat18;
float u_xlat19;
bool u_xlatb19;

fragment float4 fx_nv_nodevideo_fill_audiovisualization_energy(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_audiovisualization_energyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> audio_sampler [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = in.acScreenNorm.xxxy + float4(-0.75, -0.5, -0.25, -0.5);
    u_xlat0.xyz = u_xlat0.xyz * float3(float3(u._colour, u._colour, u._colour));
    u_xlatb1.xyz = lessThan(float4(1.0, 1.0, 1.0, 0.0), abs(u_xlat0.xyzx)).xyz;
    u_xlat0.xyz = (-u_xlat0.xyz) * u_xlat0.xyz + float3(1.0, 1.0, 1.0);
    {
        float4 hlslcc_movcTemp = u_xlat0;
        hlslcc_movcTemp.x = (u_xlatb1.x) ? float(0.0) : u_xlat0.x;
        hlslcc_movcTemp.y = (u_xlatb1.y) ? float(0.0) : u_xlat0.y;
        hlslcc_movcTemp.z = (u_xlatb1.z) ? float(0.0) : u_xlat0.z;
        u_xlat0 = hlslcc_movcTemp;
    }
    u_xlat1.xy = (-in.acScreenNorm.yx) + float2(0.5, 0.5);
    u_xlat1.x = 0.00999999978 / abs(u_xlat1.x);
    u_xlat13 = abs(u_xlat1.y) + u._shift;
    u_xlat13 = u_xlat13 + u_xlat13;
    u_xlatb19 = u_xlat13>=(-u_xlat13);
    u_xlat13 = fract(abs(u_xlat13));
    u_xlat13 = (u_xlatb19) ? u_xlat13 : (-u_xlat13);
    u_xlat2.x = u_xlat13 * 0.5;
    u_xlat2.y = 0.0;
    u_xlat19 = audio_sampler.sample(__nv_smp, u_xlat2.xy).x;
    u_xlat13 = (-u_xlat13) * 0.5 + 0.5;
    u_xlat13 = dot(float2(u_xlat13), float2(u_xlat19));
    u_xlat18 = -abs(u_xlat0.w) + 0.5;
    u_xlat18 = u_xlat18 + u_xlat18;
    u_xlat13 = u_xlat18 * u_xlat13;
    u_xlat7 = -abs(u_xlat1.y) * 2.0 + 1.0;
    u_xlat19 = float(1.0) / u._power;
    u_xlat13 = log2(abs(u_xlat13));
    u_xlat13 = u_xlat13 * u_xlat19;
    u_xlat13 = exp2(u_xlat13);
    u_xlat7 = u_xlat13 * 30.0 + u_xlat7;
    u_xlat1.x = u_xlat7 * u_xlat1.x;
    u_xlat0.xyz = u_xlat0.xyz * u_xlat1.xxx;
    u_xlat1.xyz = float3(u_xlat18) * u_xlat0.xyz;
    u_xlat2 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb3 = int(u._blend_mode)==1;
    u_xlat1.w = 1.0;
    u_xlat4 = u_xlat1 * u_xlat2;
    u_xlat0.xyz = u_xlat0.xyz * float3(u_xlat18) + u_xlat2.xyz;
    u_xlat0.w = u_xlat2.w;
    u_xlat3 = (bool(u_xlatb3)) ? u_xlat4 : u_xlat0;
    u_xlat0.xyz = u_xlat1.xyz;
    u_xlat0 = (int(u._blend_mode) != 0) ? u_xlat3 : u_xlat0;
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
