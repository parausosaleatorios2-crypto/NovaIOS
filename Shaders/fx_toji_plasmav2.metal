// ---------------------------------------------------------------------------
// Procedural Plasma Isolines
// origem : assets/effects/toji-plasmav2.xml
// id     : com.alightcreative.effects.procedural_plasma_isolines
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_plasmav2Params {
    float alpha;
};

// --- funcoes auxiliares do efeito
// Procedural Plasma Isolines – AM official style
    // - 3D value noise (hash + trilinear)
    // - Fixed-iteration FBM (6 octaves)
    // - No dynamic loops/arrays; only AM built-ins

    static float rand3(float3 st){
      return fract(sin(dot(st, float3(12.9898, 78.233, 45.543))) * 43758.5453123);
    }

    static float noise3(float3 st){
      float3 i=floor(st); float3 f=fract(st);
      float3 u=f*f*(3.0-2.0*f);
      float a=rand3(i);
      float b=rand3(i+float3(1.0,0.0,0.0));
      float c=rand3(i+float3(0.0,1.0,0.0));
      float d=rand3(i+float3(1.0,1.0,0.0));
      float e=rand3(i+float3(0.0,0.0,1.0));
      float f0=rand3(i+float3(1.0,0.0,1.0));
      float g=rand3(i+float3(0.0,1.0,1.0));
      float h=rand3(i+float3(1.0,1.0,1.0));
      float bottom = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
      float top    = mix(mix(e,f0,u.x), mix(g,h,u.x), u.y);
      return mix(bottom, top, u.z);
    }

    static float fbm6(float3 st){
      float v=0.0; float amp=0.5;
      v += amp * noise3(st); st*=2.0; amp*=0.5;
      v += amp * noise3(st); st*=2.0; amp*=0.5;
      v += amp * noise3(st); st*=2.0; amp*=0.5;
      v += amp * noise3(st); st*=2.0; amp*=0.5;
      v += amp * noise3(st); st*=2.0; amp*=0.5;
      v += amp * noise3(st);
      return v;
    }

fragment float4 fx_toji_plasmav2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_plasmav2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      uv.x *= eng.acScreenSize.x / max(eng.acScreenSize.y, 1.0);
      float time = eng.acTime * 0.25;

      // Background
      float bgN = fbm6(float3(uv * 0.8, time));
      float3 col = float3(0.05, 0.10, 0.20);
      col = mix(col, float3(0.10, 0.35, 0.40), smoothstep(0.4, 0.6, bgN));
      col = mix(col, float3(0.70, 0.50, 0.40), smoothstep(0.65, 0.8, bgN));

      // Isolines
      float lineN = fbm6(float3(uv * 1.4, time * 1.5));
      float iso = fract(lineN * 5.0);
      float dline = min(iso, 1.0 - iso);
      float line = smoothstep(0.03, 0.02, dline);
      line += smoothstep(0.10, 0.00, dline) * 0.4;

      float3 finalRGB = col + line * float3(1.0, 0.95, 0.90);

      float a = inputImg.sample(__nv_smp, in.acScreenNorm).a * u.alpha;
      __nv_out = float4(finalRGB, 1.0) * a;
    return __nv_out;
}
