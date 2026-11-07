// ---------------------------------------------------------------------------
// Unsharp Gaussian V
// origem : assets/effects/toji-unsharp_gauss_v.xml
// id     : com.alightcreative.effects.unsharp_gauss_v
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_unsharp_gauss_vParams {
    float radius;
    int quality;
};

// --- funcoes auxiliares do efeito
float4 s(float2 uv){ return inputImg.sample(__nv_smp, uv); }
    float w(float x, float sigma){ return exp(-(x*x)/(2.0*sigma*sigma)); }

fragment float4 fx_toji_unsharp_gauss_v(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_unsharp_gauss_vParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float2 texel = 1.0/__nv_getTexSize(inputImg_info.size);
      float r = u.radius;
      if(r<=0.0){ __nv_out = s(uv); return __nv_out; }
      int taps = int(r * (u.quality==0?2.0:(u.quality==1?3.0:4.0)));
      float sigma = max(0.0001, r*0.6);
      float4 acc = float4(0.0);
      float wsum = 0.0;
      for(int i=-1024;i<=1024;i++){
        if(i<-taps) continue; if(i>taps) break;
        float wi = w(float(i), sigma);
        acc += s(uv + float2(0.0, float(i)*texel.y)) * wi;
        wsum += wi;
      }
      __nv_out = acc/max(0.0001,wsum);
    return __nv_out;
}
