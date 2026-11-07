// ---------------------------------------------------------------------------
// Bevel + Light Sweep
// origem : assets/effects/toji-bevel_light_sweep.xml
// id     : com.alightcreative.effects.bevel_light_sweep
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_bevel_light_sweepParams {
    float2 center;
    float directionDeg;
    int shape;
    float edgeThickness;
    float edgeIntensity;
    float widthPx;
    float sweepIntensity;
    float4 lightColor;
    int lightReception;
    float rimWidthPx;
    float rimIntensity;
    float4 rimColor;
    int rimReception;
    float rimAngleDeg;
    float innerWidthPx;
    float innerIntensity;
    float4 innerColor;
    int innerReception;
    float alpha;
};

// --- funcoes auxiliares do efeito
// Bevel + Light Sweep (official-style AM shader)
    // - Only AM builtins; no dynamic loops/derivatives

    const float PI = 3.141592653589793;

fragment float4 fx_toji_bevel_light_sweep(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_bevel_light_sweepParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float4 src = inputImg.sample(__nv_smp, uv);

      // Texture texel size
      float2 texel = 1.0 / __nv_getTexSize(inputImg_info.size);

      // Alpha gradient (Sobel-lite, 4 taps)
      float a_t = inputImg.sample(__nv_smp, uv + float2(0.0,  texel.y)).a;
      float a_b = inputImg.sample(__nv_smp, uv + float2(0.0, -texel.y)).a;
      float a_r = inputImg.sample(__nv_smp, uv + float2( texel.x, 0.0)).a;
      float a_l = inputImg.sample(__nv_smp, uv + float2(-texel.x, 0.0)).a;
      float2 grad = float2(a_r - a_l, a_t - a_b);
      float edgeStrength = length(grad);

      // Bevel lighting with a fixed light from top-left (135deg)
      float bevelAngle = radians(135.0);
      float2 lightDir = normalize(float2(cos(bevelAngle), sin(bevelAngle)));
      float lighting = dot(normalize(grad + 1e-6), lightDir);

      // Edge thickness: map px -> threshold in gradient domain
      float thickness = u.edgeThickness * 0.01; // empirical mapping
      float bevelMask = smoothstep(0.0, thickness + 1e-6, edgeStrength);

      float softness = 0.5;
      float powExp = 1.0 + (1.0 - softness) * 4.0;
      float highlight = pow(max(0.0,  lighting), powExp);
      float shadow    = pow(max(0.0, -lighting), powExp);

      float edgeGain = u.edgeIntensity / 100.0;
      float3 beveled = src.rgb;
      beveled = mix(beveled, float3(1.0), highlight * bevelMask * edgeGain);
      beveled = mix(beveled, float3(0.0), shadow    * bevelMask * edgeGain);

      // Sweep line setup (static; no auto animation)
      float2 centerPx = u.center; // in pixels
      float2 centerUV = centerPx / eng.acScreenSize; // normalize
      float2 p = uv - centerUV;
      // aspect compensation
      p.x *= eng.acScreenSize.x / max(eng.acScreenSize.y, 1.0);
      float ang = radians(u.directionDeg);
      float2 dir = float2(cos(ang), sin(ang));
      float2 nrm = float2(-dir.y, dir.x);

      float width = u.widthPx / max(eng.acScreenSize.y, 1.0); // px -> uv units (y-based)
      float d = abs(dot(p, nrm));

      // Beam + soft glow
      float beam = pow(1.0 - smoothstep(0.0, width, d), 8.0);
      float glow = (1.0 - smoothstep(0.0, width * 5.0, d)) * 0.4;
      float sweep = (beam + glow) * (u.sweepIntensity / 25.0);

      // Edge boost when sweep hits edges
      sweep += bevelMask * beam * 2.0;

      // Light color and reception blend
      float3 sweepCol = u.lightColor.rgb * sweep;
      float3 outRGB;
      if(int(u.lightReception)==0){
        // Add
        outRGB = beveled + sweepCol;
      } else {
        // Screen
        outRGB = 1.0 - (1.0 - beveled) * (1.0 - sweepCol);
      }

      // Rim Light (inner edge band): sample u.alpha inward along edge normal
      float2 n = normalize(grad + 1e-6);
      float rimWidth = u.rimWidthPx / max(eng.acScreenSize.y, 1.0);
      float rang = radians(u.rimAngleDeg);
      float2 rn = float2(cos(rang) * n.x - sin(rang) * n.y, sin(rang) * n.x + cos(rang) * n.y);
      float a_in_rim = inputImg.sample(__nv_smp, uv - rn * rimWidth).a;
      float rimBand = clamp(src.a - a_in_rim, 0.0, 1.0);
      // u.shape the band softly
      rimBand = smoothstep(0.0, 0.6, rimBand);
      float3 rimCol = u.rimColor.rgb * rimBand * (u.rimIntensity / 100.0);
      if(int(u.rimReception)==0){
        outRGB += rimCol;
      } else {
        outRGB = 1.0 - (1.0 - outRGB) * (1.0 - rimCol);
      }

      // Inner Light (broader inner glow from edge inward)
      float innerWidth = u.innerWidthPx / max(eng.acScreenSize.y, 1.0);
      float a_in_inner = inputImg.sample(__nv_smp, uv - n * innerWidth).a;
      float innerBand = clamp(src.a - a_in_inner, 0.0, 1.0);
      // boost and soften
      innerBand = 1.0 - exp(-innerBand * 3.0);
      float3 innerCol = u.innerColor.rgb * innerBand * (u.innerIntensity / 100.0);
      if(int(u.innerReception)==0){
        outRGB += innerCol;
      } else {
        outRGB = 1.0 - (1.0 - outRGB) * (1.0 - innerCol);
      }

      float aOut = src.a * u.alpha;
      __nv_out = float4(outRGB, 1.0) * aOut;
    return __nv_out;
}
