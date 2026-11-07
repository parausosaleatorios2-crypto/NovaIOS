// ---------------------------------------------------------------------------
// Flare 
// origem : assets/effects/toji-_Aflare.xml
// id     : com.alightcreative.effects.flare_shadertoy
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji__AflareParams {
    float level;
    float iterations;
    float radiusScale;
    float basePower;
    float peakPower;
    float falloffExp;
    float strength;
    float gamma;
    float4 tintColor;
    float bloomThreshold;
    float bloomRadius;
    float bloomStrength;
    int blendMode;
    float mixAmount;
};

// --- funcoes auxiliares do efeito
float4 src(float2 uv){ return inputImg.sample(__nv_smp, uv); }

fragment float4 fx_toji__Aflare(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji__AflareParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float4 srcCol = src(uv);
      float3 hdr = srcCol.rgb;
      float3 accum = float3(floor(u.level + pow(hdr.r, u.basePower)));

      float c = float(max(u.iterations, 1.0));
      float2 r = eng.acScreenSize * max(u.radiusScale, 1e-3);
      int samples = int(u.iterations);

      for(int i=0;i<2048;i++){
        if(i>=samples) break;
        float it = float(i);
        float w = (1.0 - it / c);

        float texL = src(uv + float2(it / r.x, 0.0)).r;
        float texR = src(uv - float2(it / r.x, 0.0)).r;
        accum += floor(u.level + pow(max(texL, texR), float(u.peakPower))) * w;

        float texU = src(uv + float2(0.0, it / r.y)).r;
        float texD = src(uv - float2(0.0, it / r.y)).r;
        accum += floor(u.level + pow(max(texU, texD), float(u.peakPower))) * w;

        float ring = smoothstep(0.5, 0.75, length(float2(it / r.x, it / r.y))) / c;
        accum += pow(ring, 1.0 / max(u.falloffExp, 1e-3));
      }

      float3 effectRGB = pow(accum * u.strength, float3(1.0 / max(u.gamma, 1e-6)));
      effectRGB *= u.tintColor.rgb;

      float3 luma = float3(0.299, 0.587, 0.114);
      float lum = dot(srcCol.rgb, luma);
      float gate = smoothstep(u.bloomThreshold, 1.0, lum);
      float3 b0 = srcCol.rgb * gate;
      float2 texel = float2(u.bloomRadius) / max(eng.acScreenSize, float2(1.0));
      float3 b = b0;
      float3 s1 = src(uv + texel * float2( 1.0,  0.0)).rgb; b += s1 * smoothstep(u.bloomThreshold, 1.0, dot(s1, luma));
      float3 s2 = src(uv + texel * float2(-1.0,  0.0)).rgb; b += s2 * smoothstep(u.bloomThreshold, 1.0, dot(s2, luma));
      float3 s3 = src(uv + texel * float2( 0.0,  1.0)).rgb; b += s3 * smoothstep(u.bloomThreshold, 1.0, dot(s3, luma));
      float3 s4 = src(uv + texel * float2( 0.0, -1.0)).rgb; b += s4 * smoothstep(u.bloomThreshold, 1.0, dot(s4, luma));
      float3 s5 = src(uv + texel * float2( 1.0,  1.0)).rgb; b += s5 * smoothstep(u.bloomThreshold, 1.0, dot(s5, luma));
      float3 s6 = src(uv + texel * float2(-1.0,  1.0)).rgb; b += s6 * smoothstep(u.bloomThreshold, 1.0, dot(s6, luma));
      float3 s7 = src(uv + texel * float2( 1.0, -1.0)).rgb; b += s7 * smoothstep(u.bloomThreshold, 1.0, dot(s7, luma));
      float3 s8 = src(uv + texel * float2(-1.0, -1.0)).rgb; b += s8 * smoothstep(u.bloomThreshold, 1.0, dot(s8, luma));
      b *= (1.0/9.0);
      float3 bloom = b * u.bloomStrength;

      int bm = int(u.blendMode);
      float3 outRGB;
      if(bm==1){
        outRGB = effectRGB;
      } else if(bm==2){
        outRGB = srcCol.rgb + effectRGB;
      } else if(bm==3){
        outRGB = 1.0 - (1.0 - srcCol.rgb) * (1.0 - effectRGB);
      } else {
        outRGB = mix(effectRGB, srcCol.rgb, srcCol.a);
      }

      outRGB += bloom;

      float3 mixed = mix(srcCol.rgb, outRGB, clamp(u.mixAmount, 0.0, 1.0));
      __nv_out = float4(mixed, srcCol.a);
    return __nv_out;
}
