// ---------------------------------------------------------------------------
// Film Grain
// origem : assets/effects/gm-film_grain.xml
// id     : gm.custom.film_grain
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_film_grainParams {
    float amount;
    float size;
    int animate;
    float shadowBias;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
static float gmHash(float2 p){ return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123); }

fragment float4 fx_gm_film_grain(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_film_grainParams&  u    [[buffer(1)]],
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
  float t = u.animate ? floor(eng.acTime * 24.0) : 0.0;
  float2 gp = floor(uv * eng.acScreenSize / max(u.size, 0.5)) + t * 13.0;
  float n = gmHash(gp) - 0.5;
  float l = gmLum(c);
  float resp = mix(1.0, 1.0 - l, u.shadowBias);
  float3 col = c + n * u.amount * resp * u.mixAmt;
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
