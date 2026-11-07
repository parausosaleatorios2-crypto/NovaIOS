// ---------------------------------------------------------------------------
// Rays Edge Detect
// origem : assets/effects/toji-rays_edge_detect.xml
// id     : com.alightcreative.effects.rays_edge_detect
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_rays_edge_detectParams {
    float edgeThreshold;
    float brightThreshold;
    float feather;
    int useLuma;
};

// --- funcoes auxiliares do efeito
const float3 W = float3(0.2126,0.7152,0.0722);
    float4 s(float2 uv){ return inputImg.sample(__nv_smp, uv); }
    float lum(float3 c){ return dot(c,W); }

fragment float4 fx_toji_rays_edge_detect(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_rays_edge_detectParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acLayerNorm;
      float2 px = 1.0/eng.acLayerSize;
      float4 c = s(uv);
      float a = c.a;
      float v = u.useLuma ? lum(c.rgb) : a;
      // Sobel gradient
      float tl = u.useLuma?lum(s(uv+float2(-px.x,-px.y)).rgb):s(uv+float2(-px.x,-px.y)).a;
      float tc = u.useLuma?lum(s(uv+float2(0.0,-px.y)).rgb):s(uv+float2(0.0,-px.y)).a;
      float tr = u.useLuma?lum(s(uv+float2(px.x,-px.y)).rgb):s(uv+float2(px.x,-px.y)).a;
      float ml = u.useLuma?lum(s(uv+float2(-px.x,0.0)).rgb):s(uv+float2(-px.x,0.0)).a;
      float mr = u.useLuma?lum(s(uv+float2(px.x,0.0)).rgb):s(uv+float2(px.x,0.0)).a;
      float bl = u.useLuma?lum(s(uv+float2(-px.x,px.y)).rgb):s(uv+float2(-px.x,px.y)).a;
      float bc = u.useLuma?lum(s(uv+float2(0.0,px.y)).rgb):s(uv+float2(0.0,px.y)).a;
      float br = u.useLuma?lum(s(uv+float2(px.x,px.y)).rgb):s(uv+float2(px.x,px.y)).a;
      float gx = (tr + 2.0*mr + br) - (tl + 2.0*ml + bl);
      float gy = (bl + 2.0*bc + br) - (tl + 2.0*tc + tr);
      float g = length(float2(gx,gy));
      float e = smoothstep(u.edgeThreshold, 1.0, g);
      float b = smoothstep(u.brightThreshold-0.02, u.brightThreshold+0.02, v);
      float m = e*b;
      // Simple u.feather by neighbor max
      float f = u.feather;
      float2 k = f*px;
      float m1 = m;
      m1 = max(m1, (u.useLuma?lum(s(uv+float2(k.x,0.0)).rgb):s(uv+float2(k.x,0.0)).a) * m);
      m1 = max(m1, (u.useLuma?lum(s(uv+float2(-k.x,0.0)).rgb):s(uv+float2(-k.x,0.0)).a) * m);
      m1 = max(m1, (u.useLuma?lum(s(uv+float2(0.0,k.y)).rgb):s(uv+float2(0.0,k.y)).a) * m);
      m1 = max(m1, (u.useLuma?lum(s(uv+float2(0.0,-k.y)).rgb):s(uv+float2(0.0,-k.y)).a) * m);
      m1 *= a;
      __nv_out = float4(float3(m1), m1);
    return __nv_out;
}
