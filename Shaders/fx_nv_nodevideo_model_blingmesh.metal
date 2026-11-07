// ---------------------------------------------------------------------------
// Model Blingmesh (NV)
// origem : assets/effects/nv-nodevideo-model-blingmesh.xml
// id     : nv.effect.nodevideo-model-blingmesh
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_model_blingmeshParams {
    float _intensity;
    float _angle;
    float4 _color;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float3 u_xlat1;
float2 u_xlat2;
float u_xlat3;
float u_xlat8;

fragment float4 fx_nv_nodevideo_model_blingmesh(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_model_blingmeshParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * _viewport_ratio.xy;
    u_xlat8 = u._angle * 0.0174532924;
    u_xlat1.x = sin((-u_xlat8));
    u_xlat2.x = sin(u_xlat8);
    u_xlat3 = cos(u_xlat8);
    u_xlat1.y = u_xlat3;
    u_xlat1.z = u_xlat2.x;
    u_xlat2.y = dot(u_xlat1.zy, u_xlat0.xy);
    u_xlat2.x = dot(u_xlat1.yx, u_xlat0.xy);
    u_xlat0.xy = u_xlat2.xy + float2(0.5, 0.5);
    u_xlat0.xy = clamp(u_xlat0.xy, 0.0, 1.0);
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
    u_xlat0 = u_xlat0 * in.vs_COLOR0;
    u_xlat0 = u_xlat0 * float4(float4(u._intensity, u._intensity, u._intensity, u._intensity));
    __nv_out = u_xlat0 * u._color;
    return __nv_out;
    return __nv_out;
}
