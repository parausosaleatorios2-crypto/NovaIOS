// ---------------------------------------------------------------------------
// Fisheye / Anti‑Fisheye
// origem : assets/effects/toji-fisheye.xml
// id     : com.alightcreative.effects.fisheye_antifisheye
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_fisheyeParams {
    float power;
    float centerX;
    float centerY;
    int aspectMode;
    float alpha;
};

// --- funcoes auxiliares do efeito
// Fisheye / Anti‑Fisheye
    // Ported from the Shadertoy snippet provided by the user and adapted for Alight Motion
    // Inspired by: https://stackoverflow.com/questions/6030814

    // Notes:
    // - u.power > 0 : fisheye (barrel)
    // - u.power < 0 : anti‑fisheye (pincushion)
    // - u.aspectMode!=0 applies aspect correction so the effect remains circular on non‑square frames

fragment float4 fx_toji_fisheye(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_fisheyeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;            // 0..1
      float2 uvWork = uv;                  // working UVs (may be aspect-adjusted)

      float prop = eng.acScreenSize.x / eng.acScreenSize.y;  // aspect ratio (width/height)

      // Aspect-corrected center
      float2 m = float2(u.centerX, (u.aspectMode != 0) ? (u.centerY / prop) : u.centerY);

      // Aspect-corrected working coordinates for circular behavior
      if(u.aspectMode != 0){
        uvWork = float2(uv.x, uv.y / prop);
      }

      float2 d = uvWork - m;              // vector from center
      float r = length(d);              // distance from center

      // Map UI u.power [-1..1] to a usable curvature scale (radians-like)
      // Using PI scaling provides a useful range similar to the original mouse mapping
      float k = u.power * 3.14159265;

      // Compute bind radius according to original logic
      float bind;
      if(k > 0.0){
        bind = length(m);                 // stick to corners for fisheye
      } else if(k < 0.0){
        bind = (prop < 1.0) ? m.x : m.y; // borders when anti‑fisheye
      } else {
        bind = 1.0; // not used when k == 0
      }

      float2 uv2;
      if(k > 0.0){
        // fisheye
        uv2 = m + normalize(d) * tan(r * k) * bind / tan(bind * k);
      } else if(k < 0.0){
        // anti‑fisheye (scaled by 10 like the reference)
        float kk = -k * 10.0;
        uv2 = m + normalize(d) * __nv_atan(r * kk) * bind / __nv_atan(kk * bind);
      } else {
        uv2 = uvWork; // no effect
      }

      // Undo aspect correction for sampling
      if(u.aspectMode != 0){
        uv2 = float2(uv2.x, uv2.y * prop);
      }

      // Sample with clamping at edges
      float4 src = inputImg.sample(__nv_smp, clamp(uv2, 0.0, 1.0));

      // Preserve original u.alpha and allow overall u.alpha control
      float a = src.a * u.alpha;
      __nv_out = float4(src.rgb, 1.0) * a;
    return __nv_out;
}
