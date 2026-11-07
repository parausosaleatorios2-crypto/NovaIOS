// ---------------------------------------------------------------------------
// Halftone pro
// origem : assets/effects/toji-halftone_dots.xml
// id     : com.alightcreative.effects.halftone_dots
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_halftone_dotsParams {
    int dotsMode;
    float dotsFrequency;
    float dotsAngle;
    float dotsRelWidth;
    float dotsSharpness;
    float dotsLighten;
    float smoothSource;
    float4 color1;
    float4 color0;
    float shiftX;
    float shiftY;
    float alpha;
};

// --- funcoes auxiliares do efeito
// Halftone / Dot Screen (ported from Shadertoy and adapted for Alight Motion)
    // Ruofei Du references: https://www.shadertoy.com/view/4sBBDK, https://www.shadertoy.com/view/lsSfWV

    const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

    static float greyScale(float3 c){ return dot(c, LUMA); }

    static float2x2 rot(float a){ float s=sin(a), c=cos(a); return float2x2(c,-s,s,c); }

    // Simple 3x3 box smooth of luminance controlled by u.smoothSource
    static float smoothLum(float2 uv){
      if(u.smoothSource <= 0.0) return greyScale(inputImg.sample(__nv_smp, uv).rgb);
      float2 texel = 1.0 / __nv_getTexSize(inputImg_info.size);
      float r = clamp(u.smoothSource, 0.0, 2.0);
      float2 o = texel * r;
      float acc = 0.0; float w = 0.0;
      for(int j=-1;j<=1;j++){
        for(int i=-1;i<=1;i++){
          float ww = (i==0 && j==0) ? 2.0 : 1.0;
          acc += greyScale(inputImg.sample(__nv_smp, uv + float2(i,j)*o).rgb) * ww;
          w += ww;
        }
      }
      return acc / max(w, 1.0);
    }

    // Dot screen pattern (returns roughly -4..+4 like the Shadertoy version*4)
    static float dotScreen(float2 uv, float angle, float scale, float relWidth){
      // shift in pixels -> UV
      float2 shiftPx = float2(u.shiftX, -u.shiftY);
      float2 uvShift = uv + shiftPx / eng.acScreenSize;
      // pixel space centered
      float2 p = (uvShift - 0.5) * eng.acScreenSize;
      // anisotropic scaling
      float2 q = rot(angle) * p;
      q.x *= relWidth;
      q *= scale;
      return (sin(q.x) * sin(q.y)) * 4.0;
    }

fragment float4 fx_toji_halftone_dots(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_halftone_dotsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float4 src = inputImg.sample(__nv_smp, uv);
      float grey = smoothLum(uv);

      // Map UI parameters
      float ang = radians(u.dotsAngle);
      // Frequency maps to scale (empirical mapping for useful range)
      // Higher frequency -> denser dots -> larger multiplier
      float scale = u.dotsFrequency * 0.06; // tuneable mapping

      float pat = dotScreen(uv, ang, scale, u.dotsRelWidth);

      // Original Shadertoy combination
      float v = grey * 10.0 - 5.0 + pat + u.dotsLighten;

      // Convert to 0..1 mask with adjustable sharpness
      float s = max(u.dotsSharpness, 0.0001);
      float m = smoothstep(-s, s, v);

      // Dots mode: 0 -> Black dots, 1 -> White dots (swap mask)
      if(int(u.dotsMode)==1) m = 1.0 - m;

      // Map mask to two colors
      float3 c0 = u.color0.rgb;
      float3 c1 = u.color1.rgb;
      float3 halftone = mix(c0, c1, m);

      // Preserve original u.alpha and allow overall u.alpha control
      float a = src.a * u.alpha;
      __nv_out = float4(halftone, 1.0) * a;
    return __nv_out;
}
