// ---------------------------------------------------------------------------
// Wipe Checker
// origem : assets/effects/toji-3wipechecker.xml
// id     : com.alightcreative.effects.wipe_checker
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_3wipecheckerParams {
    float wipe_percent;
    int mode;
    float edge_softness;
    float angle;
    float frequency;
    float rel_width;
    float rel_width_pre;
    float shift_x;
    float shift_y;
    float grad_add;
    float grad_angle;
    float size_grad;
    float4 fill_color;
    float fill_alpha;
};

// --- funcoes auxiliares do efeito
// Checkerboard wipe using rotated squares in a grid.
    // Reveals the source where the wipe progresses; unrevealed can be transparent or filled.

    float2x2 rot(float a){ float c=cos(a), s=sin(a); return float2x2(c,-s,s,c); }

fragment float4 fx_toji_3wipechecker(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_3wipecheckerParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;

      // Shift in pixels -> UV
      float2 shiftUV = float2(u.shift_x / max(eng.acScreenSize.x,1.0), u.shift_y / max(eng.acScreenSize.y,1.0));
      uv += shiftUV;

      float ang = radians(u.angle);
      float freq = max(u.frequency, 0.0001);

      // Pre-rotation anisotropy
      float2 preScale = float2(u.rel_width_pre, 1.0);
      float2 p = uv * preScale;
      // Rotate grid
      p = rot(ang) * p;
      // Post-rotation anisotropy (squash/expand diamonds)
      float2 postScale = float2(u.rel_width, 1.0);
      p *= postScale;

      // Grid coordinate
      float2 g = p * freq;
      // Center within a cell
      float2 f = fract(g) - 0.5;

      // Diamond/square distance using L-infinity norm
      float d = max(abs(f.x), abs(f.y)); // 0..0.5

      // Wipe progression mapped to shape size
      float s = clamp(u.wipe_percent/100.0, 0.0, 1.0) * 0.5;
      if (float(u.mode) > 1.5) {
        // Shrink: invert progression (start full squares, shrink holes)
        s = 0.5 - s;
      }

      // Gradient‑driven threshold with edge softness
      float es = max(u.edge_softness, 0.0);

      // Project UV onto gradient direction; normalize to [-0.5, 0.5]
      // so a value of 1.0 shifts the threshold roughly from one corner to the opposite.
      float gAng = radians(u.grad_angle);
      float2 gdir = normalize(float2(cos(gAng), sin(gAng)));
      float grad = dot(uv - 0.5, gdir) * (1.0 / 0.7071067811865476); // 1/sqrt(2)

      // Positive u.grad_add pushes the wipe in +gdir; negative reverses it
      float sBias = s + u.grad_add * grad;

      float2 res = eng.acScreenSize;
      float2 uvC = (in.acScreenNorm * res - 0.5 * res) / min(res.x, res.y);
      float rad = clamp(length(uvC) * 2.0, 0.0, 1.0);
      float sRadial = (rad - 0.5) * 2.0 * u.size_grad;
      float sAll = sBias + sRadial;

      float t = d - sAll;
      float inside = 1.0 - smoothstep(-es, es, t);

      // Revealed content (premultiplied) vs unrevealed fill
      float4 src = inputImg.sample(__nv_smp, in.acScreenNorm);
      float4 revealed = float4(src.rgb * src.a, src.a) * inside;
      float4 fill = float4(u.fill_color.rgb * u.fill_alpha, u.fill_alpha) * (1.0 - inside);
      __nv_out = revealed + fill;
    return __nv_out;
}
