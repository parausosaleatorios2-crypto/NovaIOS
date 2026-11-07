// ---------------------------------------------------------------------------
// Ghost
// origem : assets/effects/toji-1ghost.xml
// id     : com.alightcreative.effects.ghost
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_1ghostParams {
    float zoomStrength;
    float opacityStrength;
    float speed;
    int ghostType;
};

// --- funcoes auxiliares do efeito
static float2 getResolution(){ float2 s=__nv_getTexSize(inputImg_info.size); if(s.x<=0.0||s.y<=0.0) s=float2(1920.0,1080.0); return s; }
    const float PI=3.14159265358979323846;
    float luma(float3 c){ return dot(c, float3(0.299,0.587,0.114)); }

    float4 sampleLayer(float2 uv01){ return inputImg.sample(__nv_smp, uv01); }

    float clamp01(float x){ return clamp(x,0.0,1.0); }

    float3 applyType(float2 uv, float3 src){
      if(u.ghostType==0){ return src; }
      if(u.ghostType==1){ float g=1.0 - luma(src); return float3(g); }
      if(u.ghostType==2){ return float3(1.0) - src; }
      float2 texel=1.0/getResolution();
      float tl=luma(sampleLayer(uv+texel*float2(-1.0,-1.0)).rgb);
      float tc=luma(sampleLayer(uv+texel*float2( 0.0,-1.0)).rgb);
      float tr=luma(sampleLayer(uv+texel*float2( 1.0,-1.0)).rgb);
      float ml=luma(sampleLayer(uv+texel*float2(-1.0, 0.0)).rgb);
      float mc=luma(sampleLayer(uv).rgb);
      float mr=luma(sampleLayer(uv+texel*float2( 1.0, 0.0)).rgb);
      float bl=luma(sampleLayer(uv+texel*float2(-1.0, 1.0)).rgb);
      float bc=luma(sampleLayer(uv+texel*float2( 0.0, 1.0)).rgb);
      float br=luma(sampleLayer(uv+texel*float2( 1.0, 1.0)).rgb);
      float gx = -tl - 2.0*ml - bl + tr + 2.0*mr + br;
      float gy = -tl - 2.0*tc - tr + bl + 2.0*bc + br;
      float edge = clamp01(sqrt(gx*gx + gy*gy));
      return mix(src, float3(1.0), edge);
    }

fragment float4 fx_toji_1ghost(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_1ghostParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv=in.acScreenNorm;
      float4 base=sampleLayer(uv);
      float progress = clamp01(u.speed * eng.acTime);
      float s = smoothstep(0.0, 1.0, progress);
      float op = clamp01(u.opacityStrength * (1.0 - s));
      float z = clamp01(u.zoomStrength * s);
      float2 ctr=float2(0.5);
      float2 delta=uv-ctr;
      float2 zuv=ctr + delta * (1.0 - z);
      float4 zcol=sampleLayer(zuv);
      float mask = step(0.0,zuv.x)*step(zuv.x,1.0)*step(0.0,zuv.y)*step(zuv.y,1.0);
      float3 proc = applyType(zuv, zcol.rgb);
      float4 ghost = float4(proc, base.a);
      float4 outColor = mix(base, ghost, op*mask);
      __nv_out = outColor;
    return __nv_out;
}
