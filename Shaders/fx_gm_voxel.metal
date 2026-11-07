// ---------------------------------------------------------------------------
// Voxel Look
// origem : assets/effects/gm-voxel.xml
// id     : gm.custom.voxel
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_voxelParams {
    float blocks;
    float levels;
    float lightAngle;
    float ambient;
    float mixAmt;
};

fragment float4 fx_gm_voxel(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_voxelParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float ar = eng.acScreenSize.x / max(eng.acScreenSize.y, 1.0);
  float2 grid = float2(u.blocks * ar, u.blocks) / max(ar, 1.0);
  float2 cell = floor(uv * grid) / grid + 0.5 / grid;
  float4 src = inputImg.sample(__nv_smp, cell);
  float a = max(src.a, 1e-4);
  float3 c = src.rgb / a;
  float l = gmLum(c);
  float n = max(u.levels, 2.0) - 1.0;
  float h = floor(l * n + 0.5) / n;
  float lx = gmLum(inputImg.sample(__nv_smp, cell + float2(1.0 / grid.x, 0.0)).rgb) - l;
  float ly = gmLum(inputImg.sample(__nv_smp, cell + float2(0.0, 1.0 / grid.y)).rgb) - l;
  float rad = radians(u.lightAngle);
  float lam = clamp((lx * cos(rad) + ly * sin(rad)) * 6.0 + u.ambient + h * 0.5, 0.0, 1.4);
  float3 col = c * lam;
  col = mix(c, col, u.mixAmt);
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
