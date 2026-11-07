// ---------------------------------------------------------------------------
// Audio Spectrum (Transparent)
// origem : assets/effects/toji-3audiospactrum.xml
// id     : com.alightcreative.effects.audio_spectrum_purple
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_3audiospactrumParams {
    float4 color;
    float alpha;
    float line_thickness;
    float bar_width;
    float dot_size;
    float baseline_y;
    float left_margin;
    float bar_count;
    float bar_max_height;
    float audio_level;
    float reactivity;
    float jitter;
    float speed;
    float seed;
};

// --- funcoes auxiliares do efeito
// Transparent audio spectrum visualizer
    // Bars and dots around a horizontal baseline. No background fill.

    // Hash for deterministic u.jitter
    static float hash11(float n){ return fract(sin(n * 127.1 + 311.7) * 43758.5453); }

    // Smooth rectangle (x-axis) and circle (for dots)
    static float smoothRect(float x, float halfW){
      return 1.0 - smoothstep(halfW - 1e-4, halfW + 1e-4, abs(x));
    }
    static float smoothLine(float y, float halfT){
      return 1.0 - smoothstep(halfT - 1e-4, halfT + 1e-4, abs(y));
    }
    static float smoothCircle(float2 p, float r){
      float d = length(p);
      return 1.0 - smoothstep(r - 1e-4, r + 1e-4, d);
    }

    static float bandAmp(float i, float N){
      float base = pow(u.audio_level, u.reactivity); // global level with u.reactivity curve
      float rnd = (hash11(i + u.seed) * 2.0 - 1.0) * u.jitter; // symmetric u.jitter
      float wob = 0.5 + 0.5 * sin(eng.acTime * (2.5 * u.speed) + i * 0.9);
      float env = 0.85 - 0.35 * abs((i/(N-1.0)) * 2.0 - 1.0); // slight mid emphasis
      float amp = clamp(base * env * (0.6 + 0.8 * wob + rnd), 0.0, 1.0);
      return amp;
    }

fragment float4 fx_toji_3audiospactrum(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_3audiospactrumParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;

      float margin = clamp(u.left_margin, 0.0, 0.49);
      float N = float(u.bar_count);
      float usableW = 1.0 - 2.0 * margin;
      float xIn = (uv.x - margin) / max(usableW, 1e-4);

      // Outside drawing area: fully transparent
      if(xIn < 0.0 || xIn > 1.0){ __nv_out = float4(0.0); return __nv_out; }

      float i = floor(xIn * N);
      float cx = margin + (i + 0.5) / N * usableW; // bar center
      float dx = uv.x - cx;

      float amp = bandAmp(i, N);
      float h = u.bar_max_height * amp;
      float halfW = u.bar_width * 0.5;
      float baseline = u.baseline_y;

      // Coverage accumulation: baseline line + bar + dot
      float cov = 0.0;

      // Baseline
      cov = max(cov, smoothLine(uv.y - baseline, u.line_thickness * 0.5));

      // Vertical bar centered on baseline (extends up and down)
      // X coverage by width, Y coverage by height symmetrical around baseline
      float cxCov = smoothRect(dx, halfW);
      float yTop = baseline + h;
      float yBot = baseline - h;
      float yDist = max(0.0, max(uv.y - yTop, yBot - uv.y));
      float yCov = 1.0 - smoothstep(0.0, 1e-4, yDist);
      cov = max(cov, cxCov * yCov);

      // Dot between bars: centered halfway to next bar, on baseline
      float nextCx = margin + (i + 1.0) / N * usableW;
      float midX = mix(cx, nextCx, 0.5);
      float2 dp = float2(uv.x - midX, uv.y - baseline);
      cov = max(cov, smoothCircle(dp, u.dot_size));

      // Final u.color: premultiplied by coverage, transparent elsewhere
      float3 col = u.color.rgb;
      float a = cov * u.alpha;
      __nv_out = float4(col * a, a);
    return __nv_out;
}
