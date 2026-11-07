// ---------------------------------------------------------------------------
// Poster Impact Pro
// origem : assets/effects/gm-poster_impact.xml
// id     : gm.custom.poster_impact
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_poster_impactParams {
    float steps;
    float gamma;
    float edge;
    float edgeWidth;
    float4 inkColor;
    float mixAmt;
};

fragment float4 fx_gm_poster_impact(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_poster_impactParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float4 src = inputImg.sample(__nv_smp, uv);
  float a = max(src.a, 1e-4);
  float3 c = src.rgb / a;
  float l0 = gmLum(c);
  float2 px = float2(u.edgeWidth / max(eng.acScreenSize.x, 1.0), u.edgeWidth / max(eng.acScreenSize.y, 1.0));
  float l1 = gmLum(inputImg.sample(__nv_smp, uv + float2(px.x, 0.0)).rgb / max(inputImg.sample(__nv_smp, uv + float2(px.x, 0.0)).a, 1e-4));
  float l2 = gmLum(inputImg.sample(__nv_smp, uv - float2(px.x, 0.0)).rgb / max(inputImg.sample(__nv_smp, uv - float2(px.x, 0.0)).a, 1e-4));
  float l3 = gmLum(inputImg.sample(__nv_smp, uv + float2(0.0, px.y)).rgb / max(inputImg.sample(__nv_smp, uv + float2(0.0, px.y)).a, 1e-4));
  float l4 = gmLum(inputImg.sample(__nv_smp, uv - float2(0.0, px.y)).rgb / max(inputImg.sample(__nv_smp, uv - float2(0.0, px.y)).a, 1e-4));
  float edgeAmt = smoothstep(0.04, 0.55, abs(l0 - l1) + abs(l0 - l2) + abs(l0 - l3) + abs(l0 - l4));
  float3 toned = pow(clamp(c, 0.0, 1.0), float3(1.0 / max(u.gamma, 0.05)));
  float n = max(u.steps, 2.0) - 1.0;
  float3 poster = floor(toned * n + 0.5) / n;
  poster = mix(poster, u.inkColor.rgb, edgeAmt * u.edge);
  float3 col = mix(c, poster, u.mixAmt);
  __nv_out = float4(clamp(col, 0.0, 1.0) * src.a, src.a);
    return __nv_out;
}
