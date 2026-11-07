// ---------------------------------------------------------------------------
// Fractal Zoom Trails
// origem : assets/effects/toji-afractalzoom.xml
// id     : com.alightcreative.effects.fractal_zoom_trails
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_afractalzoomParams {
    float centerX;
    float centerY;
    float zoomAmount;
    float rotation;
    float trailSteps;
    float trailDecay;
    float chromaticShift;
    float radialBlur;
    float time;
    float pulse;
    float speed;
    float alpha;
};

// --- funcoes auxiliares do efeito
// Fractal Zoom Trails: multi-sample zoom smear toward a center

    static float3 sampleRGB(float2 uv){ return inputImg.sample(__nv_smp, uv).rgb; }

    static float2x2 rot(float a){ float c=cos(a), s=sin(a); return float2x2(c,-s,s,c); }

fragment float4 fx_toji_afractalzoom(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_afractalzoomParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float2 texSize = __nv_getTexSize(inputImg_info.size);
      float2 aspect = float2(texSize.x/max(texSize.y,1.0), 1.0);
      float2 center = float2(u.centerX, u.centerY);

      // Animated u.pulse for zoom
      float pulsePhase = sin(u.time*u.speed*6.28318)*0.5+0.5;
      float zAmt = u.zoomAmount + u.pulse * (pulsePhase - 0.5) * 2.0 * abs(u.zoomAmount);

      // Vector from center (aspect-corrected), with optional u.rotation
      float2 d = (uv - center) * aspect;
      d = rot(u.rotation) * d;

      // Base color
      float4 src = inputImg.sample(__nv_smp, uv);
      float3 acc = float3(0.0);
      float wsum = 0.0;

      int maxSteps = 32;
      float N = clamp(u.trailSteps, 1.0, float(maxSteps));

      // Accumulate samples along a geometric progression toward center
      for(int i=0;i<32;i++){
        if(float(i) >= N) break;
        float t = (float(i)+1.0) / N; // 0..1
        // geometric zoom factor: closer to center for larger i
        float g = pow(1.0 - clamp(zAmt*0.95, -0.95, 0.95), t);
        float2 dv = d * g;
        float2 suv = center + (rot(-u.rotation)*dv)/aspect;

        // optional radial blur along direction to center
        float2 dir = normalize((uv - center) + 1e-6);
        float rb = u.radialBlur * float(i) / N;

        // chromatic shift per step
        float cs = u.chromaticShift * float(i) / N;
        float3 c;
        c.r = inputImg.sample(__nv_smp, suv + dir*rb + float2( cs, 0.0)).r;
        c.g = inputImg.sample(__nv_smp, suv + dir*rb).g;
        c.b = inputImg.sample(__nv_smp, suv + dir*rb + float2(-cs, 0.0)).b;

        float w = pow(u.trailDecay, float(i));
        acc += c * w;
        wsum += w;
      }

      float3 trail = acc / max(wsum, 1e-6);

      // Mix trails with original
      float3 outRGB = mix(src.rgb, trail, u.alpha);
      __nv_out = float4(clamp(outRGB,0.0,1.0), src.a);
    return __nv_out;
}
