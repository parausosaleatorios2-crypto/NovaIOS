// ---------------------------------------------------------------------------
// Bordas Neon (Ultra Motion)
// origem : assets/effects/um-neon-edges.xml
// id     : nova.effect.ultramotion.neonedges
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_neon_edgesParams {
    float sens;
    float thickness;
    float4 inner;
    float4 outer;
    int dark;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_um_neon_edges(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_neon_edgesParams&  u    [[buffer(1)]],
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
    float halo = clamp(sqrt(gx*gx + gy*gy) * u.sens * 0.4, 0.0, 1.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float3 fundo = u.dark ? float3(0.0) : orig.rgb;
    float3 cor = fundo + u.outer.rgb * u.outer.a * halo + u.inner.rgb * u.inner.a * g;
    __nv_out = float4(cor, orig.a);
    return __nv_out;
}
