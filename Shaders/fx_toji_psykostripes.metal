// ---------------------------------------------------------------------------
// Psykostripes
// origem : assets/effects/toji-psykostripes.xml
// id     : com.alightcreative.effects.psykostripes
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_psykostripesParams {
    float stripeDirDeg;
    float stripeMag;
    float phaseStart;
    float phaseSpeed;
    float offset;
    float freqColors;
    float freqRed;
    float freqGreen;
    float freqBlue;
    float phaseRed;
    float phaseGreen;
    float phaseBlue;
    float brightness;
    float4 tintColor;
    float saturation;
    float edgeAmt;
    float edgeWarp;
    float edgeWidth;
    int edgeInvert;
    float mixWithSource;
};

// --- funcoes auxiliares do efeito
static float2 getResolution(){
      float2 s = __nv_getTexSize(inputImg_info.size);
      if (s.x <= 0.0 || s.y <= 0.0) s = float2(1920.0, 1080.0);
      return s;
    }
    float gray(float4 c){ return dot(c.rgb, float3(0.299,0.587,0.114)); }
    float2x2 rot2(float a){ float c=cos(a), s=sin(a); return float2x2(c,-s,s,c); }

    float getLuma(float2 uv) {
      return gray(inputImg.sample(__nv_smp, uv));
    }

    float sobel(float2 uv, float2 pixel, float w) {
      float2 p = pixel * w;
      float t00 = getLuma(uv + p * float2(-1, -1));
      float t10 = getLuma(uv + p * float2( 0, -1));
      float t20 = getLuma(uv + p * float2( 1, -1));
      float t01 = getLuma(uv + p * float2(-1,  0));
      float t21 = getLuma(uv + p * float2( 1,  0));
      float t02 = getLuma(uv + p * float2(-1,  1));
      float t12 = getLuma(uv + p * float2( 0,  1));
      float t22 = getLuma(uv + p * float2( 1,  1));
      float gx = t00 + 2.0 * t01 + t02 - (t20 + 2.0 * t21 + t22);
      float gy = t00 + 2.0 * t10 + t20 - (t02 + 2.0 * t12 + t22);
      return length(float2(gx, gy));
    }

fragment float4 fx_toji_psykostripes(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_psykostripesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 res = getResolution();
      float2 uv = in.acScreenNorm;
      float2 pixel = 1.0 / res;

      float ang = radians(u.stripeDirDeg);
      float2 dir = rot2(ang) * float2(1.0, 0.0);

      // Edge detection
      float edge = sobel(uv, pixel, u.edgeWidth) * u.edgeAmt;
      float maskEdge = clamp(edge, 0.0, 1.0);
      if(u.edgeInvert) maskEdge = 1.0 - maskEdge;

      float4 s0 = inputImg.sample(__nv_smp, uv);
      float amp = gray(s0);

      float basePhase = u.phaseStart + eng.acTime * u.phaseSpeed + u.offset;
      float mag = u.stripeMag;
      
      // Distort wave based on edges and original luminance
      float wave = dot(uv - 0.5, dir) * mag + basePhase;
      wave += edge * u.edgeWarp;
      wave += amp * u.edgeWarp * 0.5;

      float fBase = u.freqColors;
      float rC = 0.5 + 0.5 * sin(wave * fBase * u.freqRed + u.phaseRed);
      float gC = 0.5 + 0.5 * sin(wave * fBase * u.freqGreen + u.phaseGreen);
      float bC = 0.5 + 0.5 * sin(wave * fBase * u.freqBlue + u.phaseBlue);
      float3 colS = float3(rC, gC, bC);

      float3 tint = u.tintColor.rgb;
      float3 colT = colS * tint;
      
      // Apply "Find Edges" look: dark boundaries or glowing lines
      if(!u.edgeInvert) {
          colT *= (1.0 - maskEdge * 0.8); // Darken edges
      } else {
          colT += maskEdge * 0.5; // Glow edges
      }

      float g = dot(colT, float3(0.299,0.587,0.114));
      float3 colSat = mix(float3(g), colT, clamp(u.saturation, 0.0, 2.0));
      colSat *= u.brightness;

      float3 srcCol = s0.rgb;
      float aIn = s0.a;
      float3 stripeBlend = mix(colSat, srcCol, u.mixWithSource);
      float3 outCol = mix(srcCol, stripeBlend, aIn);
      
      __nv_out = float4(outCol, aIn);
    return __nv_out;
}
