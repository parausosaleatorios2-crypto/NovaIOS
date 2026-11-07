// ---------------------------------------------------------------------------
// Holo Depth Pro
// origem : assets/effects/gm-holo_depth.xml
// id     : gm.custom.holo_depth
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_holo_depthParams {
    float depth;
    float cyanTint;
    float scanlines;
    float speed;
    float mixAmt;
};

fragment float4 fx_gm_holo_depth(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_holo_depthParams&  u    [[buffer(1)]],
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
  float l = gmLum(c);
  float o = u.depth * (l - 0.5) * 2.0 * u.mixAmt;
  float r = inputImg.sample(__nv_smp, uv + float2(o, 0.0)).r;
  float g = inputImg.sample(__nv_smp, uv).g;
  float b = inputImg.sample(__nv_smp, uv - float2(o, 0.0)).b;
  float3 stereo = float3(r, g, b);
  float3 holo = float3(l * 0.12, l * 1.20 + 0.035, l * 1.42 + 0.075) * a;
  float scan = 1.0 - u.scanlines * (0.5 + 0.5 * sin((uv.y * eng.acScreenSize.y + eng.acTime * u.speed * 42.0) * 3.1415926));
  float flicker = 0.92 + 0.08 * sin(eng.acTime * 37.0 + uv.y * 4.0);
  float3 glow = float3(max(l - 0.52, 0.0) * 0.95) * a;
  float3 strong = (mix(stereo, holo, u.cyanTint) + glow) * scan * flicker;
  float3 finalColor = mix(stereo, clamp(strong, 0.0, 1.0), u.mixAmt);
  __nv_out = float4(finalColor, a);
    return __nv_out;
}
