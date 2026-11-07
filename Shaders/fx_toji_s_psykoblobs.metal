// ---------------------------------------------------------------------------
// PsykoBlobs
// origem : assets/effects/toji-s_psykoblobs.xml
// id     : com.alightcreative.effects.s_psykoblobs
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_s_psykoblobsParams {
    float noiseFreq;
    float sourceScale;
    float freqColors;
    float phaseSpeed;
    float saturation;
    float outlineStrength;
    float mixWithSource;
};

// --- funcoes auxiliares do efeito
static float hash(float2 p) {
      return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453123);
    }

    float smoothNoise(float2 p) {
      float2 i = floor(p);
      float2 f = fract(p);
      f = f * f * (3.0 - 2.0 * f); 
      float bottom = mix(hash(i), hash(i + float2(1.0, 0.0)), f.x);
      float top = mix(hash(i + float2(0.0, 1.0)), hash(i + float2(1.0, 1.0)), f.x);
      return mix(bottom, top, f.y);
    }

    float fbm(float2 p) {
      float v = 0.0;
      float a = 0.5;
      float2 shift = float2(100.0);
      for (int i = 0; i < 3; ++i) {
        v += a * smoothNoise(p);
        p = p * 2.0 + shift;
        a *= 0.5;
      }
      return v;
    }

    float gray(float3 c){ return dot(c, float3(0.299, 0.587, 0.114)); }

fragment float4 fx_toji_s_psykoblobs(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_s_psykoblobsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      
      float4 srcSample = inputImg.sample(__nv_smp, uv);
      float srcLuma = gray(srcSample.rgb);
      
      float2 noiseUV = uv * u.noiseFreq;
      float blobs = fbm(noiseUV);
      
      float combinedVal = (srcLuma * u.sourceScale) + blobs;
      
      float3 freqRGB = float3(1.0, 1.15, 1.3); 
      float3 phaseRGB = float3(0.0, 0.33, 0.67); 
      
      float3 colorPhase = (combinedVal * u.freqColors * freqRGB) + phaseRGB + (eng.acTime * u.phaseSpeed);
      float3 outCol = 0.5 + 0.5 * sin(colorPhase * 6.283185);
      
      float lumaOut = gray(outCol);
      outCol = mix(float3(lumaOut), outCol, u.saturation);
      
      float outlineMask = smoothstep(0.05, 0.3 * u.outlineStrength, srcLuma);
      outCol *= mix(1.0, outlineMask, u.outlineStrength);
      
      float3 finalCol = mix(outCol, srcSample.rgb, u.mixWithSource);
      __nv_out = float4(finalCol, srcSample.a);
    return __nv_out;
}
