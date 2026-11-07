// ---------------------------------------------------------------------------
// Color-Luma Key
// origem : assets/effects/toji-luma_color.xml
// id     : com.alightcreative.effects.color_luma_key
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_luma_colorParams {
    float4 keyColor;
    float tolerance;
    float softness;
    float lumaWeight;
    int invertKey;
    float despill;
    float alpha;
};

// --- funcoes auxiliares do efeito
// Color-Luma Key (official AM style)
    // - Only AM builtins
    // - No dynamic loops/derivatives

    const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

    // Simple YUV-like chroma for distance that's less sensitive to brightness
    static float2 chroma(float3 c){
      float y = dot(c, LUMA);
      return float2(c.b - y, c.r - y);
    }

fragment float4 fx_toji_luma_color(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_luma_colorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float4 src = inputImg.sample(__nv_smp, uv);
      float3 c = src.rgb;

      // Key color chroma and luma
      float3 k = u.keyColor.rgb;
      float y  = dot(c, LUMA);
      float yk = dot(k, LUMA);
      float2 cc = chroma(c);
      float2 ck = chroma(k);

      float chromaDist = length(cc - ck);          // 0..~1
      float lumaDist   = abs(y - yk);              // 0..1

      // Combined distance (scaled by u.lumaWeight)
      float d = chromaDist + u.lumaWeight * lumaDist;

      // Soft thresholding to build matte
      float t = u.tolerance;
      float s = max(u.softness, 1e-5);
      float matte = 1.0 - smoothstep(t - s, t + s, d); // 1 where color matches key
      if(u.invertKey) matte = 1.0 - matte;

      // Despill: reduce contribution of keyed color on remaining pixels
      // Simple projection toward neutral luma
      float match = matte; // 1 near key
      float3 neutral = float3(y);
      float3 cDespill = mix(c, mix(c, neutral, 0.6), u.despill * match);

      // Compose: attenuate u.alpha where key matched
      float aOut = src.a * (1.0 - matte) * u.alpha;
      __nv_out = float4(cDespill, 1.0) * aOut;
    return __nv_out;
}
