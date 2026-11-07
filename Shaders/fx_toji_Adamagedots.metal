// ---------------------------------------------------------------------------
// Film Damage Dots
// origem : assets/effects/toji-Adamagedots.xml
// id     : com.alightcreative.effects.film_damage_dots
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_AdamagedotsParams {
    float4 dotColor;
    float dotSize;
    float softness;
    float density;
    float opacity;
    float speed;
    float flicker;
    float seed;
    int blendMode;
    float mixAmount;
};

// --- funcoes auxiliares do efeito
// Procedural film damage dots
    static float4 src(float2 uv){ return inputImg.sample(__nv_smp, uv); }

    static float hash11(float n){ return fract(sin(n)*43758.5453123); }
    static float hash12(float2 p){ return fract(sin(dot(p, float2(127.1,311.7)) + u.seed)*43758.5453); }
    static float2  hash22(float2 p){
      float n = sin(dot(p, float2(12.9898,78.233)) + u.seed);
      return fract(float2(262144.0, 32768.0) * n);
    }

fragment float4 fx_toji_Adamagedots(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_AdamagedotsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float2 px = uv * eng.acScreenSize; // pixel space for consistent radius

      // Convert u.density per 1000x1000 pixels to expected cell size in px
      float D = max(u.density, 1e-3);
      float area = eng.acScreenSize.x * eng.acScreenSize.y;
      float cells = D * (area / 1000000.0);
      float cellSize = sqrt(max(area / max(cells, 1.0), 1.0));

      // Grid cell in pixel space
      float2 cell = floor(px / cellSize);
      float2 cellOrigin = cell * cellSize;

      // Random jittered dot center per cell
      float2 rnd = hash22(cell);
      // Drift over time for organic motion
      float t = eng.acTime * u.speed;
      float2 drift = 0.35 * (rnd - 0.5) * cellSize * t;
      float2 center = cellOrigin + (rnd * cellSize) + drift;

      // Circle SDF
      float r = max(u.dotSize, 0.0);
      float d = length(px - center);
      float feather = mix(0.001, 0.8, clamp(u.softness, 0.0, 1.0));
      float m = 1.0 - smoothstep(r, r * (1.0 + feather), d);

      // Sparse u.flicker to emulate film dust popping
      float f = mix(1.0, hash12(cell + floor(t*7.0)), u.flicker);
      m *= f;

      float4 base = src(uv);
      float3 dotRGB = u.dotColor.rgb * u.opacity * m;

      int bm = int(u.blendMode);
      float3 outRGB;
      if (bm == 1) {
        // Normal (over)
        float3 mixed = mix(base.rgb, dotRGB, clamp(u.mixAmount, 0.0, 1.0));
        outRGB = mixed;
      } else if (bm == 2) {
        // Add
        outRGB = base.rgb + dotRGB * clamp(u.mixAmount, 0.0, 1.0);
      } else if (bm == 3) {
        // Screen
        float3 scr = 1.0 - (1.0 - base.rgb) * (1.0 - clamp(dotRGB, 0.0, 100.0));
        outRGB = mix(base.rgb, scr, clamp(u.mixAmount, 0.0, 1.0));
      } else {
        // Multiply
        float3 mul = base.rgb * (1.0 - m + dotRGB);
        outRGB = mix(base.rgb, mul, clamp(u.mixAmount, 0.0, 1.0));
      }

      __nv_out = float4(outRGB, base.a);
    return __nv_out;
}
