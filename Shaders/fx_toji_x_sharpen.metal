// ---------------------------------------------------------------------------
// Sharpen pro
// origem : assets/effects/toji-x_sharpen.xml
// id     : com.alightcreative.effects.denoise_sharpen
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_x_sharpenParams {
    float noiseStrength;
    float sharpenStrength;
    int viewMode;
    float alpha;
};

// --- funcoes auxiliares do efeito
// Advanced Denoise + Sharpen (Bilateral + Unsharp)
    // Port adapted to Alight Motion shader API

fragment float4 fx_toji_x_sharpen(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_x_sharpenParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float2 texel = 1.0 / __nv_getTexSize(inputImg_info.size);

      float3 centerColor = inputImg.sample(__nv_smp, uv).rgb;

      // Bilateral 5x5
      float3 accum = float3(0.0);
      float wsum = 0.0;
      for(int j=-2;j<=2;j++){
        for(int i=-2;i<=2;i++){
          float2 off = float2(float(i), float(j));
          float3 nc = inputImg.sample(__nv_smp, uv + off * texel).rgb;
          float spatial = exp(-(off.x*off.x + off.y*off.y) / 8.0);
          float cd = length(centerColor - nc);
          float range = exp(-(cd*cd) / (2.0 * u.noiseStrength * u.noiseStrength + 1e-6));
          float w = spatial * range;
          accum += nc * w;
          wsum += w;
        }
      }

      float3 denoised = accum / max(wsum, 1e-6);

      // Unsharp mask using denoised as base to avoid boosting noise
      float3 detail = centerColor - denoised;
      float3 finalSharpened = centerColor + detail * u.sharpenStrength;

      // View selection
      float3 outRGB = finalSharpened;
      if(int(u.viewMode)==0) outRGB = denoised;
      else if(int(u.viewMode)==1) outRGB = centerColor;

      float a = inputImg.sample(__nv_smp, uv).a * u.alpha;
      __nv_out = float4(clamp(outRGB, 0.0, 1.0), 1.0) * a;
    return __nv_out;
}
