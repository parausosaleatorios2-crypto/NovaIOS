// ---------------------------------------------------------------------------
// BCC Blur V
// origem : assets/effects/toji-bcc_blur_v.xml
// id     : com.alightcreative.effects.bcc_blur_v
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_bcc_blur_vParams {
    float yWidth;
    float glowRadius;
    int blurType;
    float triangleIterations;
    int mirrorEdge;
};

// --- funcoes auxiliares do efeito
static float2 clampMirror(float2 uv){
      if(u.mirrorEdge){
        uv = float2(1.0,1.0) - abs(__nv_mod(uv, float2(2.0,2.0)) - float2(1.0,1.0));
      } else {
        uv = clamp(uv, float2(0.0), float2(1.0));
      }
      return uv;
    }
    float4 sample(float2 uv){ return inputImg.sample(__nv_smp, clampMirror(uv)); }
    float4 blurBox(float2 uv, float radiusPx){
      if(radiusPx<=0.0) return sample(uv);
      float2 texel = 1.0/__nv_getTexSize(inputImg_info.size);
      int r = int(max(1.0,radiusPx));
      float4 acc = float4(0.0); float w = 0.0;
      for(int i=-1024;i<=1024;i++){
        if(i<-r) continue; if(i>r) break;
        float2 offs = float2(0.0,float(i)*texel.y);
        acc += sample(uv+offs);
        w += 1.0;
      }
      return acc/max(1.0,w);
    }
    float gaussW(float x, float sigma){ return exp(-(x*x)/(2.0*sigma*sigma)); }
    float4 blurGaussian(float2 uv, float radiusPx){
      if(radiusPx<=0.0) return sample(uv);
      float2 texel = 1.0/__nv_getTexSize(inputImg_info.size);
      int r = int(max(1.0,radiusPx));
      float sigma = radiusPx*0.35;
      float4 acc = float4(0.0); float wsum = 0.0;
      for(int i=-1024;i<=1024;i++){
        if(i<-r) continue; if(i>r) break;
        float w = gaussW(float(i), sigma);
        acc += sample(uv + float2(0.0,float(i)*texel.y)) * w;
        wsum += w;
      }
      return acc/max(0.0001,wsum);
    }
    float4 blurTriangle(float2 uv, float radiusPx, int iterations){
      float4 c = sample(uv);
      float4 outC = c;
      for(int it=0; it<4; it++){
        if(it>=iterations) break;
        outC = blurBox(uv, radiusPx);
      }
      return outC;
    }

fragment float4 fx_toji_bcc_blur_v(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_bcc_blur_vParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float radiusPx = u.yWidth * (u.glowRadius/100.0);
      float2 uv = in.acScreenNorm;
      float4 col;
      if(u.blurType==0){ col = blurTriangle(uv, radiusPx, int(u.triangleIterations)); }
      else if(u.blurType==1){ col = blurGaussian(uv, radiusPx); }
      else { col = blurBox(uv, radiusPx); }
      __nv_out = col;
    return __nv_out;
}
