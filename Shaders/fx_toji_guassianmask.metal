// ---------------------------------------------------------------------------
// Circular Mask Gaussian Blur
// origem : assets/effects/toji-guassianmask.xml
// id     : com.alightcreative.effects.circular_mask_blur
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_guassianmaskParams {
    float2 center;
    float radiusPx;
    float featherPx;
    int invert;
    float blurRadius;
    float intensity;
    int blendMode;
};

// --- funcoes auxiliares do efeito
// Circular Mask Gaussian Blur
    // Pass 0: Horizontal blur of input
    // Pass 1: Vertical blur of imgH
    // Pass 2: Composite using circular mask with feather

    // Convert u.center: accept either normalized (0..1) or pixels (>2)
    float2 normCenter(float2 c){
      if(c.x > 2.0 || c.y > 2.0){
        return c / eng.acScreenSize; // px -> norm
      }
      return c;
    }

    float4 blur1D(sampler2D tex, float2 uv, float2 dirPx, float u.radiusPx){
      float sigma = max(u.radiusPx, 1e-4) / 2.14596602;
      const float PIc = 3.14159265;
      float3 incG; incG.x = 1.0/(sqrt(2.0*PIc)*max(sigma,1e-4)); incG.y = exp(-0.5/(sigma*sigma)); incG.z = incG.y*incG.y;
      float4 acc = tex.sample(__nv_smp, uv) * incG.x; float wsum = incG.x;
      for(float i=1.0;i<=128.0;i+=2.0){
        float o0=i, o1=i+1.0; incG.xy *= incG.yz; float w0=incG.x; incG.xy *= incG.yz; float w1=incG.x;
        float w = w0+w1; float off=(o0*w0 + o1*w1)/max(w,1e-6);
        float2 ofs = dirPx * off;
        acc += tex.sample(__nv_smp, uv - ofs) * w;
        acc += tex.sample(__nv_smp, uv + ofs) * w;
        wsum += 2.0*w;
        if(i>u.radiusPx) break;
      }
      return acc / max(wsum,1e-6);
    }

    float3 blend_screen(float3 a, float3 b){ return 1.0 - (1.0-a)*(1.0-b); }
    float3 blend_overlay(float3 base, float3 over){ return mix(2.0*base*over, 1.0 - 2.0*(1.0-base)*(1.0-over), step(0.5, base)); }

fragment float4 fx_toji_guassianmask(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_guassianmaskParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> imgH [[texture(1)]],
    texture2d<float> imgV [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& imgH_info [[buffer(3)]],
    constant NovaTexInfo& imgV_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float2 px = 1.0 / inputImg_info.size;

      if(eng.acPass==0){
        __nv_out = blur1D(inputImg, uv, float2(px.x, 0.0), u.blurRadius);
        return __nv_out;
      }
      if(eng.acPass==1){
        __nv_out = blur1D(imgH, uv, float2(0.0, px.y), u.blurRadius);
        return __nv_out;
      }

      // Final composite with circular mask
      float4 src = inputImg.sample(__nv_smp, uv);
      float3 blurRGB = imgV.sample(__nv_smp, uv).rgb;

      float2 cN = normCenter(u.center);
      // Convert radius and feather from px to normalized (approx using screen X)
      float r = u.radiusPx / max(eng.acScreenSize.x, 1.0);
      float f = max(u.featherPx, 0.0) / max(eng.acScreenSize.x, 1.0);

      float dist = length(uv - cN);
      float edge0 = r - 0.5*f;
      float edge1 = r + 0.5*f;
      float mask = smoothstep(edge1, edge0, dist); // 1 inside, 0 outside with feather
      if(u.invert){ mask = 1.0 - mask; }

      float k = clamp(u.intensity * mask, 0.0, 1.0);
      float3 mixed = mix(src.rgb, blurRGB, k);

      if(u.blendMode==1){ mixed = blend_screen(src.rgb, mixed); }
      else if(u.blendMode==2){ mixed = blend_overlay(src.rgb, mixed); }

      __nv_out = float4(mixed, src.a);
    return __nv_out;
}
