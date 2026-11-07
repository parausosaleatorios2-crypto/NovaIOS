// ---------------------------------------------------------------------------
// Particle Rain (NV)
// origem : assets/effects/nv-nodevideo-particle-rain.xml
// id     : nv.effect.nodevideo-particle-rain
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_particle_rainParams {
    float _BumpAmt;
    float _ColorStrength;
    float4 _TintColor;
};

// --- funcoes auxiliares do efeito
float3 u_xlat0;
float2 u_xlat16_1;
float3 u_xlat2;
float u_xlat3;

fragment float4 fx_nv_nodevideo_particle_rain(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_particle_rainParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> env_tex [[texture(1)]],
    texture2d<float> MainTex [[texture(2)]],
    texture2d<float> CutOut [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = inputImg.sample(__nv_smp, in.vs_TEXCOORD1.xy).xy;
    u_xlat16_1.xy = u_xlat0.xy * float2(2.0, 2.0) + float2(-1.0, -1.0);
    u_xlat0.xy = u_xlat16_1.xy * float2(u._BumpAmt);
    u_xlat0.xy = u_xlat0.xy * in.vs_COLOR0.xx;
    u_xlat0.xy = u_xlat0.xy * in.acScreenNorm.ww + in.acScreenNorm.xy;
    u_xlat0.xy = u_xlat0.xy / in.acScreenNorm.ww;
    u_xlat0.xyz = env_tex.sample(__nv_smp, u_xlat0.xy).xyz;
    u_xlat2.xyz = MainTex.sample(__nv_smp, in.vs_TEXCOORD2.xy).xyz;
    u_xlat2.xyz = u_xlat2.xyz * in.vs_COLOR0.xyz;
    u_xlat2.xyz = u_xlat2.xyz * float3(float3(u._ColorStrength, u._ColorStrength, u._ColorStrength));
    __nv_out.xyz = u_xlat2.xyz * u._TintColor.xyz + u_xlat0.xyz;
    u_xlat0.x = CutOut.sample(__nv_smp, in.vs_TEXCOORD3.xy).w;
    u_xlat0.x = u_xlat0.x * in.vs_COLOR0.w;
    u_xlat3 = in.vs_COLOR0.w * u._TintColor.w;
    __nv_out.w = u_xlat0.x * u_xlat3;
    return __nv_out;
    return __nv_out;
}
