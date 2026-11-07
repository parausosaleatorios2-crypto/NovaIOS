// ---------------------------------------------------------------------------
// Zoom Blur
// origem : assets/effects/gm-zoom_blur.xml
// id     : gm.custom.zoom_blur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_zoom_blurParams {
    float centerX;
    float centerY;
    float amount;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
const int TAPS = 12;

fragment float4 fx_gm_zoom_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_zoom_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float2 c = float2(u.centerX, u.centerY);
  float4 sum = float4(0.0);
  for (int i = 0; i < TAPS; i++){
    float t = float(i) / float(TAPS - 1);
    float sc = 1.0 - u.amount * t * u.mixAmt;
    float2 p = c + (uv - c) * sc;
    sum += inputImg.sample(__nv_smp, p);
  }
  __nv_out = sum / float(TAPS);
    return __nv_out;
}
