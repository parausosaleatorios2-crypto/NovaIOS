// ---------------------------------------------------------------------------
// Contorno de Bordas (Ultra Motion)
// origem : assets/effects/um-edge-outline.xml
// id     : nova.effect.ultramotion.edgeoutline
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_edge_outlineParams {
    float sens;
    float thickness;
    float4 lineColor;
    float fill;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_um_edge_outline(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_edge_outlineParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 t = eng.acTexelSize * u.thickness;
    float tl = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2(-t.x,-t.y)).rgb, LUMA);
    float tc = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2( 0.0,-t.y)).rgb, LUMA);
    float tr = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2( t.x,-t.y)).rgb, LUMA);
    float ml = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2(-t.x, 0.0)).rgb, LUMA);
    float mr = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2( t.x, 0.0)).rgb, LUMA);
    float bl = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2(-t.x, t.y)).rgb, LUMA);
    float bc = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2( 0.0, t.y)).rgb, LUMA);
    float br = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2( t.x, t.y)).rgb, LUMA);

    float gx = -tl - 2.0*ml - bl + tr + 2.0*mr + br;
    float gy = -tl - 2.0*tc - tr + bl + 2.0*bc + br;
    float g = clamp(sqrt(gx*gx + gy*gy) * u.sens, 0.0, 1.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float3 fundo = mix(orig.rgb, float3(1.0), u.fill);
    __nv_out = float4(mix(fundo, u.lineColor.rgb, g * u.lineColor.a), orig.a);
    return __nv_out;
}
