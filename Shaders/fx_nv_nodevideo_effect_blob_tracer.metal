// ---------------------------------------------------------------------------
// Effect Blob Tracer (NV)
// origem : assets/effects/nv-nodevideo-effect-blob-tracer.xml
// id     : nv.effect.nodevideo-effect-blob-tracer
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_blob_tracerParams {
    float4 _color_key;
    float _color_threshold;
};

// --- funcoes auxiliares do efeito
float3 u_xlat0;
bool u_xlatb0;
float3 u_xlat1;

fragment float4 fx_nv_nodevideo_effect_blob_tracer(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_blob_tracerParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = inputImg.sample(__nv_smp, in.acScreenNorm.xy).xyz;
    u_xlat1.xyz = u._color_key.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u._color_key.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat0.xyz = (-u._color_key.xyz) * u_xlat1.xyz + u_xlat0.xyz;
    u_xlat0.x = dot(u_xlat0.xyz, u_xlat0.xyz);
    u_xlat0.x = sqrt(u_xlat0.x);
    u_xlatb0 = u_xlat0.x<u._color_threshold;
    if(u_xlatb0){
        __nv_out = float4(1.0, 1.0, 1.0, 1.0);
        return __nv_out;
    }
    __nv_out = float4(0.0, 0.0, 0.0, 0.0);
    return __nv_out;
    return __nv_out;
}
