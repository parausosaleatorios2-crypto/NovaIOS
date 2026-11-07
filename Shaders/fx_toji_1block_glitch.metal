// ---------------------------------------------------------------------------
//  Glitch New
// origem : assets/effects/toji-1block_glitch.xml
// id     : com.alightcreative.effects.block_glitch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_1block_glitchParams {
    int contentSrc;
    float speed;
    float blockWidthScale;
    float blockHeightScale;
    float strengthPix;
    float thresholdLevel;
    int cropEdges;
};

// --- funcoes auxiliares do efeito
static float2 getResolution(){ float2 s=__nv_getTexSize(comp_info.size); if(s.x<=0.0||s.y<=0.0) s=__nv_getTexSize(inputImg_info.size); if(s.x<=0.0||s.y<=0.0) s=float2(1920.0,1080.0); return s; }
    static float fractf(float x){ return fract(x); }
    static float3 hash33(float3 p3){ p3=fract(p3*float3(.1031,.1030,.0973)); p3+=dot(p3,p3.yxz+33.33); return fract((p3.xxy+p3.yxx)*p3.zyx); }
    static float2 hash21(float p){ float3 p3=fract(float3(p)*float3(.1031,.1030,.0973)); p3+=dot(p3,p3.yzx+33.33); return fract((p3.xx+p3.yz)*p3.zy); }

    static float4 sampleContent(float2 uv01){ if(u.contentSrc==1) return comp.sample(__nv_smp, uv01); return inputImg.sample(__nv_smp, uv01); }

fragment float4 fx_toji_1block_glitch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_1block_glitchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 iResolution=getResolution();
      float2 uv=in.acScreenNorm;
      float t=floor(eng.acTime*u.speed);
      float2 randomValues=hash21(t);
      float2 randomScale=randomValues*100.0+50.0;
      float2 lod=(iResolution/randomScale)*float2(u.blockWidthScale,u.blockHeightScale);
      float2 p=floor(uv*lod);
      float3 rng=hash33(float3(p,t));
      float2 offset=(rng.xy-0.5)*2.0;
      float fade=sin(fractf(eng.acTime*u.speed)*3.14);
      float th=step(u.thresholdLevel,rng.z);
      float2 strength=float2(u.strengthPix)/iResolution;
      float2 glitchUV=uv+offset*th*fade*strength;
      float4 col=sampleContent(glitchUV);
      if(u.cropEdges){ col.rgb*=step(0.0,glitchUV.x)*step(glitchUV.x,1.0)*step(0.0,glitchUV.y)*step(glitchUV.y,1.0); }
      __nv_out=col;
    return __nv_out;
}
