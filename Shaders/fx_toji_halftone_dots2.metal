// ---------------------------------------------------------------------------
// Bcc Halftone
// origem : assets/effects/toji-halftone_dots2.xml
// id     : com.alightcreative.effects.halftone_lightdots
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_halftone_dots2Params {
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
// Classic Halftone Dots: dot size driven by source luminance
    // Dark areas -> larger dots, Light areas -> smaller dots

    const float3 LUMA = float3(0.2126, 0.7152, 0.0722);
    static float greyScale(float3 c){ return dot(c, LUMA); }
    static float2x2 rot(float a){ float s=sin(a), c=cos(a); return float2x2(c,-s,s,c); }

    // Optional 3x3 luminance smooth to avoid flicker at high frequency
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

fragment float4 fx_toji_halftone_dots2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_halftone_dots2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float4 src = inputImg.sample(__nv_smp, uv);
      float lum = smoothLum(uv);            // 0=black, 1=white

      // Build rotated grid coordinates in pixel space, normalize by height for AR stability
      float ang = radians(u.dotsAngle);
      float2 shiftPx = float2(u.shiftX, -u.shiftY);
      float2 uvShift = uv + shiftPx / eng.acScreenSize;
      float2 p = (uvShift - 0.5) * eng.acScreenSize; // pixel space centered
      float2 s = rot(ang) * p;                    // rotate grid
      float2 st = s / max(eng.acScreenSize.y, 1.0);   // normalize

      // Frequency: how many dots per height
      float freq = max(u.dotsFrequency, 0.0001);
      float2 grid = st * freq;
      float2 f = fract(grid) - 0.5;               // cell-local coords in [-0.5, 0.5]

      // Allow elliptical dots via relative width
      f.x *= u.dotsRelWidth;
      float dist = length(f);

      // Dot radius from luminance: darker -> larger
      // u.dotsLighten shifts the curve (+ makes dots lighter/smaller)
      float rLuma = clamp(1.0 - lum + u.dotsLighten, 0.0, 1.0);
      float radius = 0.5 * rLuma;               // 0..0.5 cell radius

      // Edge softness: higher sharpness -> crisper edges
      float edge = 0.01 / max(u.dotsSharpness, 0.0001);
      float dotMask = 1.0 - smoothstep(radius - edge, radius + edge, dist);

      // Mode swap: 0 = black dots on white, 1 = white dots on black
      if(u.dotsMode == 1) dotMask = 1.0 - dotMask;

      float3 c0 = u.color0.rgb; // dot color (black by default)
      float3 c1 = u.color1.rgb; // background color (white by default)
      float3 halftone = mix(c1, c0, dotMask);

      float a = src.a * u.alpha;
      __nv_out = float4(halftone, 1.0) * a;
    return __nv_out;
}
