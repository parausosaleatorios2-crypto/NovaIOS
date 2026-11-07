// ---------------------------------------------------------------------------
// Color Transfer
// origem : assets/effects/toji-coloradjust.xml
// id     : com.alightcreative.effects.color_transfer_adjustment
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_coloradjustParams {
    int useLayerBelowAsRef;
    float strength;
    float chromaStrength;
    int preserveLuma;
    int matchContrast;
    int robustContrast;
    float sampleGrid;
    int halfSamples;
    float alpha;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

    static float3 rgb2yuv(float3 c){
      float y = dot(c, LUMA);
      float u = c.b - y;
      float v = c.r - y;
      return float3(y,u,v);
    }
    static float3 yuv2rgb(float3 yuv){
      float y = yuv.x; float u = yuv.y; float v = yuv.z;
      float r = v + y;
      float b = u + y;
      float g = (y - 0.2126*r - 0.0722*b) / max(0.7152, 1e-6);
      return clamp(float3(r,g,b), 0.0, 1.0);
    }

    static void accumStats(float3 c, inout float3 sum, inout float3 sum2, inout float3 minv, inout float3 maxv){
      sum += c; sum2 += c*c; minv = min(minv, c); maxv = max(maxv, c);
    }

fragment float4 fx_toji_coloradjust(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_coloradjustParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> compSrc [[texture(0)]],
    texture2d<float> refImg [[texture(1)]],
    constant NovaTexInfo& compSrc_info [[buffer(2)]],
    constant NovaTexInfo& refImg_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;

      // Source: composite below this layer
      float3 srcRGB = compSrc.sample(__nv_smp, uv).rgb;

      // Build stats over grid from source and reference
      const int MAXN = 32;
      int N = int(floor(u.sampleGrid + 0.5));
      N = max(4, min(32, N));
      bool halfFlag = u.halfSamples;
      float3 sumS=float3(0.0), sum2S=float3(0.0), minS=float3(1e9), maxS=float3(-1e9);
      float3 sumR=float3(0.0), sum2R=float3(0.0), minR=float3(1e9), maxR=float3(-1e9);
      int count=0;
      for(int y=0;y<MAXN;y++){
        if(y>=N) break;
        for(int x=0;x<MAXN;x++){
          if(x>=N) break;
          if(halfFlag && __nv_mod(float(x+y), 2.0)>0.5) continue;
          float2 p=(float2(float(x)+0.5,float(y)+0.5)/float(N));
          float3 s = compSrc.sample(__nv_smp, p).rgb;
          float3 r;
          if(u.useLayerBelowAsRef){
            r = compSrc.sample(__nv_smp, p).rgb; // reference = same comp (use refImg off)
          } else {
            r = refImg.sample(__nv_smp, p).rgb;
          }
          accumStats(rgb2yuv(s), sumS, sum2S, minS, maxS);
          accumStats(rgb2yuv(r), sumR, sum2R, minR, maxR);
          count++;
        }
      }

      float fcount=float(count);
      float3 meanS=sumS/max(fcount,1.0);
      float3 meanR=sumR/max(fcount,1.0);
      float3 varS=max(sum2S/max(fcount,1.0)-meanS*meanS, float3(0.0));
      float3 varR=max(sum2R/max(fcount,1.0)-meanR*meanR, float3(0.0));
      float3 stdS=sqrt(varS+float3(1e-6));
      float3 stdR=sqrt(varR+float3(1e-6));

      float3 yuvS = rgb2yuv(srcRGB);
      float3 yuv = yuvS;

      if(u.matchContrast){
        float yMinS = u.robustContrast ? (meanS.x - 2.0*stdS.x) : minS.x;
        float yMaxS = u.robustContrast ? (meanS.x + 2.0*stdS.x) : maxS.x;
        float yMinR = u.robustContrast ? (meanR.x - 2.0*stdR.x) : minR.x;
        float yMaxR = u.robustContrast ? (meanR.x + 2.0*stdR.x) : maxR.x;
        float yNorm=(yuv.x - yMinS)/max(yMaxS - yMinS, 1e-5);
        float yMatched=mix(yMinR, yMaxR, clamp(yNorm,0.0,1.0));
        yuv.x = mix(yuv.x, yMatched, 0.7);
      }

      float3 z=(yuv - meanS)/stdS;
      float3 yuvT=z*stdR + meanR;
      if(u.preserveLuma){ yuvT.x = yuvS.x; }
      yuvT.yz = mix(yuvS.yz, yuvT.yz, u.chromaStrength);

      float3 cMatch = yuv2rgb(yuvT);
      float3 outRGB = mix(srcRGB, cMatch, u.strength);

      __nv_out = float4(outRGB, 1.0) * u.alpha;
    return __nv_out;
}
