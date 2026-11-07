// ---------------------------------------------------------------------------
// Data Collapse Pro
// origem : assets/effects/gm-data_collapse.xml
// id     : gm.custom.data_collapse
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_data_collapseParams {
    float rows;
    float shift;
    float chance;
    float dropouts;
    float speed;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
static float gmHash(float2 p){ return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123); }

fragment float4 fx_gm_data_collapse(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_data_collapseParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 baseUv = in.acScreenNorm;
  float4 origin = inputImg.sample(__nv_smp, baseUv);
  float t = floor(eng.acTime * u.speed);
  float row = floor(baseUv.y * u.rows);
  float r1 = gmHash(float2(row, t));
  float r2 = gmHash(float2(row * 3.7, t + 5.1));
  float active = step(1.0 - u.chance, r1);
  float dropped = step(1.0 - u.dropouts * u.chance, gmHash(float2(row * 7.3, t + 11.0)));
  float2 uv = baseUv;
  uv.x += (r2 - 0.5) * 2.0 * u.shift * active * u.mixAmt;
  float split = u.shift * 0.10 * active * u.mixAmt;
  float4 sr = inputImg.sample(__nv_smp, uv + float2(split, 0.0));
  float4 sg = inputImg.sample(__nv_smp, uv);
  float4 sb = inputImg.sample(__nv_smp, uv - float2(split, 0.0));
  float a = max(sg.a, 1e-4);
  float3 broken = float3(sr.r / max(sr.a, 1e-4), sg.g / max(sg.a, 1e-4), sb.b / max(sb.a, 1e-4));
  broken = mix(broken, broken * float3(1.55, 0.62, 1.28), active * 0.72);
  broken *= 1.0 - dropped * 0.70;
  float4 outSrc = float4(clamp(broken, 0.0, 1.0) * a, a);
  __nv_out = mix(origin, outSrc, u.mixAmt);
    return __nv_out;
}
