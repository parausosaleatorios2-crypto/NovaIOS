// ---------------------------------------------------------------------------
// Effect Radial Distortion (NV)
// origem : assets/effects/nv-nodevideo-effect-radial-distortion.xml
// id     : nv.effect.nodevideo-effect-radial-distortion
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_radial_distortionParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _glow;
    float _strength;
    float _offset;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float3 u_xlat1;
bool3 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat7;
bool u_xlatb7;
float u_xlat12;
bool u_xlatb13;
float u_xlat18;

fragment float4 fx_nv_nodevideo_effect_radial_distortion(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_radial_distortionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat12 = dot(u_xlat0.xy, u_xlat0.xy);
    u_xlat12 = sqrt(u_xlat12);
    u_xlat18 = min(abs(u_xlat0.x), abs(u_xlat0.y));
    u_xlat1.x = max(abs(u_xlat0.x), abs(u_xlat0.y));
    u_xlat1.x = float(1.0) / u_xlat1.x;
    u_xlat18 = u_xlat18 * u_xlat1.x;
    u_xlat1.x = u_xlat18 * u_xlat18;
    u_xlat7 = u_xlat1.x * 0.0208350997 + -0.0851330012;
    u_xlat7 = u_xlat1.x * u_xlat7 + 0.180141002;
    u_xlat7 = u_xlat1.x * u_xlat7 + -0.330299497;
    u_xlat1.x = u_xlat1.x * u_xlat7 + 0.999866009;
    u_xlat7 = u_xlat18 * u_xlat1.x;
    u_xlatb13 = abs(u_xlat0.x)<abs(u_xlat0.y);
    u_xlat7 = u_xlat7 * -2.0 + 1.57079637;
    u_xlat7 = u_xlatb13 ? u_xlat7 : float(0.0);
    u_xlat18 = u_xlat18 * u_xlat1.x + u_xlat7;
    u_xlatb1.x = u_xlat0.x<(-u_xlat0.x);
    u_xlat1.x = u_xlatb1.x ? -3.14159274 : float(0.0);
    u_xlat18 = u_xlat18 + u_xlat1.x;
    u_xlat1.x = min(u_xlat0.x, u_xlat0.y);
    u_xlat7 = max(u_xlat0.x, u_xlat0.y);
    u_xlatb1.x = u_xlat1.x<(-u_xlat1.x);
    u_xlatb7 = u_xlat7>=(-u_xlat7);
    u_xlatb1.x = u_xlatb7 && u_xlatb1.x;
    u_xlat18 = (u_xlatb1.x) ? (-u_xlat18) : u_xlat18;
    u_xlat18 = u_xlat18 + 3.14159274;
    u_xlat1.y = u_xlat18 * 0.159154937;
    u_xlat1.x = u._offset;
    u_xlat1.xyz = inputImg.sample(__nv_smp, u_xlat1.xy).xyz;
    u_xlat2.w = inputImg.sample(__nv_smp, u_xlat0.xy).w;
    u_xlat0.xyw = u_xlat1.xyz * float3(float3(u._strength, u._strength, u._strength)) + float3(0.5, 0.5, 0.5);
    u_xlatb1.xyz = lessThan(float4(u_xlat12), u_xlat0.xywx).xyz;
    u_xlat0.xyz = (-float3(u_xlat12)) + u_xlat0.xyw;
    u_xlat0.xyz = u_xlat0.xyz * float3(u._glow);
    u_xlat0.xyz = clamp(u_xlat0.xyz, 0.0, 1.0);
    u_xlat3.xyz = u_xlat0.xyz * float3(-2.0, -2.0, -2.0) + float3(3.0, 3.0, 3.0);
    u_xlat0.xyz = u_xlat0.xyz * u_xlat0.xyz;
    u_xlat0.xyz = u_xlat0.xyz * u_xlat3.xyz;
    u_xlat2.x = u_xlatb1.x ? u_xlat0.x : 0.0;
    u_xlat2.y = u_xlatb1.y ? u_xlat0.y : 0.0;
    u_xlat2.z = u_xlatb1.z ? u_xlat0.z : 0.0;
;
    if(int(u._use_inner_mask) != 0) {
        u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat2;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat3 * u_xlat4 + u_xlat0;
        u_xlat1.x = u_xlat4.x * u_xlat0.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat0.w;
        __nv_out.xyz = u_xlat0.xyz;
    } else {
        __nv_out = u_xlat2;
    }
    return __nv_out;
    return __nv_out;
}
