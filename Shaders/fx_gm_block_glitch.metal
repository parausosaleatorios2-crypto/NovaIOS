// ---------------------------------------------------------------------------
// Block Glitch
// origem : assets/effects/gm-block_glitch.xml
// id     : gm.custom.block_glitch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_block_glitchParams {
    float rows;
    float amount;
    float chance;
    float speed;
    float tint;
};

// --- funcoes auxiliares do efeito
float gmHash(float2 p){ return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123); }

fragment float4 fx_gm_block_glitch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_block_glitchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float t = floor(eng.acTime * u.speed);
  float row = floor(uv.y * u.rows);
  float r1 = gmHash(float2(row, t));
  float r2 = gmHash(float2(row * 3.7, t + 5.1));
  float active = step(1.0 - u.chance, r1);
  uv.x += (r2 - 0.5) * 2.0 * u.amount * active;
  float4 src = inputImg.sample(__nv_smp, uv);
  float a = src.a;
  float3 c = src.rgb / max(a, 1e-4);
  c = mix(c, c * float3(1.4, 0.8, 1.2), active * u.tint);
  __nv_out = float4(clamp(c, 0.0, 1.0) * a, a);
    return __nv_out;
}
