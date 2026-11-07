// ---------------------------------------------------------------------------
// T_Halftone
// origem : assets/effects/toji-newhalf.xml
// id     : com.alightcreative.effects.halftone_displace_edges
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_newhalfParams {
    float dotSize;
    float spacing;
    float angle;
    float progress;
    float scale;
    int ellipse;
    float ellipseX;
    float ellipseY;
    float4 primaryColor;
    float4 secondaryColor;
    int colorMode;
    float contrast;
    float brightness;
    float edgeSoft;
    int useDisplacement;
    float dispAmount;
    float dispThreshold;
    int dispInvert;
    float dispSoft;
    int edgesHalftone;
    float edgeThreshold;
    float edgeBlur;
    float edgeStrength;
    int overlay;
    float blend;
};

// --- funcoes auxiliares do efeito
// Helpers
    static float2 getResolution(){
      float2 s = __nv_getTexSize(inputImg_info.size);
      if (s.x <= 0.0 || s.y <= 0.0) s = float2(1920.0, 1080.0);
      return s;
    }
    static float2 rot(float2 p, float a){
      float c = cos(a);
      float s = sin(a);
      return float2(p.x * c - p.y * s, p.x * s + p.y * c);
    }
    static float applyToneF(float v, float u.contrast, float u.brightness){
      v = (v - 0.5) * u.contrast + 0.5 + u.brightness;
      return clamp(v, 0.0, 1.0);
    }
    static float colorDist(float3 a, float3 b){ return length(a - b); }

    // Sobel edge detector (luminance-based)
    static float sobelEdge(float2 uv, float2 px){
      // sample 3x3 luminances
      float tl = dot(inputImg.sample(__nv_smp, clamp(uv + float2(-px.x, -px.y), float2(0.0), float2(1.0))).rgb, float3(0.2126,0.7152,0.0722));
      float  l = dot(inputImg.sample(__nv_smp, clamp(uv + float2(0.0, -px.y), float2(0.0), float2(1.0))).rgb, float3(0.2126,0.7152,0.0722));
      float tr = dot(inputImg.sample(__nv_smp, clamp(uv + float2(px.x, -px.y), float2(0.0), float2(1.0))).rgb, float3(0.2126,0.7152,0.0722));
      float ml = dot(inputImg.sample(__nv_smp, clamp(uv + float2(-px.x, 0.0), float2(0.0), float2(1.0))).rgb, float3(0.2126,0.7152,0.0722));
      float mm = dot(inputImg.sample(__nv_smp, clamp(uv, float2(0.0), float2(1.0))).rgb, float3(0.2126,0.7152,0.0722));
      float mr = dot(inputImg.sample(__nv_smp, clamp(uv + float2(px.x, 0.0), float2(0.0), float2(1.0))).rgb, float3(0.2126,0.7152,0.0722));
      float bl = dot(inputImg.sample(__nv_smp, clamp(uv + float2(-px.x, px.y), float2(0.0), float2(1.0))).rgb, float3(0.2126,0.7152,0.0722));
      float  b = dot(inputImg.sample(__nv_smp, clamp(uv + float2(0.0, px.y), float2(0.0), float2(1.0))).rgb, float3(0.2126,0.7152,0.0722));
      float br = dot(inputImg.sample(__nv_smp, clamp(uv + float2(px.x, px.y), float2(0.0), float2(1.0))).rgb, float3(0.2126,0.7152,0.0722));

      // Sobel X and Y
      float gx = -tl - 2.0*ml - bl + tr + 2.0*mr + br;
      float gy = -tl - 2.0*l - tr + bl + 2.0*b + br;
      return length(float2(gx, gy));
    }

    // simple box blur of mask (3x3)
    static float blurMask(float2 uv, float2 px, float radius){
      // radius expressed as number of px steps; use small kernel around uv
      float s = 0.0;
      float count = 0.0;
      int r = int(max(0.0, floor(radius)));
      for(int y = -r; y <= r; y++){
        for(int x = -r; x <= r; x++){
          float2 off = float2(float(x) * px.x, float(y) * px.y);
          s += sobelEdge(clamp(uv + off, float2(0.0), float2(1.0)), px);
          count += 1.0;
        }
      }
      return s / max(1.0, count);
    }

fragment float4 fx_toji_newhalf(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_newhalfParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 res = getResolution();
      float2 uv = in.acScreenNorm;
      float2 frag = uv * res;
      float2 center = 0.5 * res;
      float2 px = float2(1.0 / res.x, 1.0 / res.y);

      // halftone params
      float dSize = max(1.0, u.dotSize);
      float dSpacing = max(1.0, u.spacing);
      float angDeg = u.angle;
      float rotAngle = radians(angDeg) + u.progress * 6.2831853;
      float s = u.scale;
      float edgeSoftness = max(0.001, u.edgeSoft);
      float cont = max(0.0, u.contrast);
      float bright = u.brightness;
      bool useSampleColor = u.colorMode;
      bool useEllipse = u.ellipse;
      float eX = max(0.001, u.ellipseX);
      float eY = max(0.001, u.ellipseY);
      // use renamed parameter (u.blend) and local name blendOut
      float blendOut = clamp(u.blend, 0.0, 1.0);

      // displacement params
      bool doDisp = u.useDisplacement;
      float dispAmountPx = u.dispAmount;
      float dispThresholdVal = clamp(u.dispThreshold, 0.0, 1.0);
      bool dispInv = u.dispInvert;
      float u.dispSoft = max(0.0, u.dispSoft);

      // colors
      float3 colPrimary = u.primaryColor.rgb;
      float3 colSecondary = u.secondaryColor.rgb;

      // edges params
      bool onlyEdges = u.edgesHalftone;
      float eThresh = clamp(u.edgeThreshold, 0.0, 1.0);
      float eBlur = max(0.0, u.edgeBlur);
      float eStr = max(0.0, u.edgeStrength);

      // rotate coordinate system
      float2 local = frag - center;
      local = rot(local, rotAngle);
      float2 rotPos = local + center;

      // cell coordinates and center in px
      float2 cell = floor(rotPos / dSpacing);
      float2 cellCenterPx = (cell + 0.5) * dSpacing;

      // sample the source at cell center
      float2 sampleUV = clamp(cellCenterPx / res, float2(0.0), float2(1.0));
      float3 sampleColor = inputImg.sample(__nv_smp, sampleUV).rgb;
      float lum = dot(sampleColor, float3(0.2126, 0.7152, 0.0722));
      lum = applyToneF(lum, cont, bright);

      // compute dot radius
      float inv = 1.0 - lum;
      float baseRadius = clamp((dSize * s) * 0.5 / dSpacing, 0.0, 0.5);
      float radius = baseRadius * inv;

      // distance to cell center for this fragment (rotated px space)
      float dx = (rotPos.x - cellCenterPx.x);
      float dy = (rotPos.y - cellCenterPx.y);
      if (useEllipse){
        dx /= eX;
        dy /= eY;
      }
      float dist = length(float2(dx, dy));
      float pxRadius = radius * dSpacing;
      float edge = max(1.0, dSpacing * 0.01) * edgeSoftness;
      float alphaDot = 1.0 - smoothstep(pxRadius - edge, pxRadius + edge, dist);

      // choose dot color
      float primaryMatch = 1.0 - smoothstep(dispThresholdVal, dispThresholdVal + 0.2, colorDist(sampleColor, colPrimary));
      float3 dotCol;
      if (useSampleColor){
        dotCol = sampleColor;
      } else {
        dotCol = mix(colSecondary, colPrimary, primaryMatch);
      }

      // displacement mask
      float match = 1.0 - smoothstep(dispThresholdVal, dispThresholdVal + 0.25, colorDist(sampleColor, colPrimary));
      match = pow(match, 1.0 + u.dispSoft * 2.0);
      float2 dir = normalize(float2(rotPos.x - cellCenterPx.x, rotPos.y - cellCenterPx.y) + float2(1e-6, 0.0));
      if (length(float2(rotPos.x - cellCenterPx.x, rotPos.y - cellCenterPx.y)) < 0.5){
        dir = float2(0.0, -1.0);
      }
      float sign = dispInv ? -1.0 : 1.0;
      float2 dispUVoffset = sign * dir * (match * dispAmountPx) / res.y;
      float2 displacedUV = clamp(uv + dispUVoffset, float2(0.0), float2(1.0));
      float3 displacedBackground = inputImg.sample(__nv_smp, displacedUV).rgb;

      // halftone color
      float3 finalDotCol;
      if (useSampleColor){
        finalDotCol = sampleColor * (0.3 + 0.7 * (1.0 - lum));
      } else {
        finalDotCol = dotCol;
      }
      float3 halftone = finalDotCol * alphaDot;

      // EDGE MASK: compute edge strength around uv (Sobel), optionally blur it, then map by threshold & strength
      float e = sobelEdge(uv, px);        // raw edge magnitude
      if (eBlur > 0.5){
        // small blur to soften edge mask (costly kernels but small radius expected)
        float b = blurMask(uv, px, eBlur);
        e = mix(e, b, 0.6);
      }
      // normalize and apply threshold -> mask 0..1, multiply by u.edgeStrength parameter
      float eMask = smoothstep(eThresh, eThresh + 0.25 * max(0.001, eBlur), e) * eStr;
      eMask = clamp(eMask, 0.0, 1.0);

      // determine base background (displaced or original)
      float3 baseBg = doDisp ? displacedBackground : inputImg.sample(__nv_smp, uv).rgb;

      // compute final composition:
      // if edges-only is on, modulate halftone by edge mask so middle is unaffected
      float finalDotMix = alphaDot * blendOut;
      if (onlyEdges){
        finalDotMix *= eMask;
      }

      float3 outCol;
      if (u.overlay){
        outCol = mix(baseBg, halftone, finalDotMix);
      } else {
        float3 original = inputImg.sample(__nv_smp, uv).rgb;
        // when replacing: allow edges-only to still mask the halftone in middle
        if (onlyEdges){
          outCol = mix(original, mix(baseBg, halftone, finalDotMix), blendOut);
        } else {
          outCol = mix(original, halftone, blendOut);
        }
      }

      __nv_out = float4(outCol, 1.0);
    return __nv_out;
}
