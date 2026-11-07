// ---------------------------------------------------------------------------
// Rays Generate
// origem : assets/effects/toji-rays_generate.xml
// id     : com.alightcreative.effects.rays_generate
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_rays_generateParams {
    float angle;
    float count;
    float length;
    float decay;
    float spread;
    float jitter;
    float soft;
};

// --- funcoes auxiliares do efeito
static float4 s(float2 uv){ return inputImg.sample(__nv_smp, uv); }
    static float rnd(float2 p){ return fract(sin(dot(p,float2(12.9898,78.233)))*43758.5453); }
    static float4 blur(float2 uv, float r){ if(r<=0.0) return s(uv); float2 px=1.0/eng.acScreenSize; float4 c=s(uv)*4.0; c+=s(uv+float2(px.x,0.0))*2.0; c+=s(uv-float2(px.x,0.0))*2.0; c+=s(uv+float2(0.0,px.y))*2.0; c+=s(uv-float2(0.0,px.y))*2.0; c+=s(uv+float2(px.x,px.y)); c+=s(uv+float2(-px.x,px.y)); c+=s(uv+float2(px.x,-px.y)); c+=s(uv+float2(-px.x,-px.y)); return c/14.0; }

fragment float4 fx_toji_rays_generate(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_rays_generateParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float2 px = 1.0/eng.acScreenSize;
      float baseAng = radians(u.angle);
      int ic = int(u.count+0.5);
      float seg = 3.14159265359 * 2.0 / max(1.0, float(ic));
      float4 acc = float4(0.0);
      for(int k=0;k<16;k++){
        if(k>=ic) break;
        float a = baseAng + seg*float(k);
        float2 dir = float2(cos(a), sin(a));
        float len = u.length;
        int steps = int(min(256.0, len));
        float stepScale = u.spread;
        for(int i=0;i<256;i++){
          if(i>=steps) break;
          float fi = float(i);
          float w = exp(-u.decay*fi);
          float j = (rnd(uv.xy+fi) - 0.5) * u.jitter;
          float2 offs = (-dir * fi * stepScale + dir * j) * px;
          float2 p = uv + offs;
          acc += blur(p, u.soft) * w;
        }
      }
      float4 rays = acc;
      __nv_out = float4(rays.rgb, clamp(rays.a,0.0,1.0));
    return __nv_out;
}
