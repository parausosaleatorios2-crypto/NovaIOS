// ---------------------------------------------------------------------------
// Impact Shake (Per-Beat Punch)
// origem : assets/effects/toji-Amimpact.xml
// id     : com.alightcreative.effects.motion_impact_shake
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_AmimpactParams {
    float triggerTime;
    float duration;
    float frequency;
    float damping;
    float strength;
    float ampPos;
    float angle;
    float ampRot;
    float ampScale;
    float pivotX;
    float pivotY;
    int mirrorEdges;
    float expand;
    int enableRepeat;
    float repeatPeriod;
};

// --- funcoes auxiliares do efeito
static float4 sampleTex(sampler2D t, float2 uv){ return t.sample(__nv_smp, uv); }
    float2x2 rot2(float a){ float s=sin(a), c=cos(a); return float2x2(c,-s,s,c); }
    float2 mirror(float2 uv){ return abs(fract(uv*0.5+0.5)*2.0-1.0); }

    float envelope(float t, float freq, float damp, float dur){
      if(t < 0.0) return 0.0;
      if(t > dur) return 0.0;
      float w = 6.28318530718 * freq;
      return exp(-damp * t) * sin(w * t);
    }

    float repeatTime(float time, float trig, bool en, float period){
      if(!en) return time - trig;
      float tau = time - trig;
      if(period <= 0.0) return tau;
      float m = floor(tau / period);
      float local = tau - m * period;
      return local;
    }

fragment float4 fx_toji_Amimpact(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_AmimpactParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;

      // Time since trigger (with optional repeat)
      float tauBase = repeatTime(eng.acTime, u.triggerTime, u.enableRepeat, u.repeatPeriod);
      float env = envelope(tauBase, u.frequency, u.damping, u.duration) * u.strength;

      // Directional position delta in pixels
      float ang = radians(u.angle);
      float2 dir = float2(cos(ang), sin(ang));
      float2 posPx = dir * u.ampPos * env;

      // Rotation (deg) and scale
      float rotDeg = u.ampRot * env;
      float scl = 1.0 + u.ampScale * env;

      // Convert pixel translation to UV
      float2 texSize = __nv_getTexSize(inputImg_info.size);
      float2 posUV = posPx / max(texSize, float2(1.0));

      // Pivot and auto u.expand
      float2 pivot = float2(u.pivotX, u.pivotY);
      float autoS = 1.0 + u.expand;

      // Apply inverse transform to find source uv
      float rot = radians(rotDeg);
      float2 rel = uv - pivot;
      rel -= posUV;                // undo translation
      rel = rot2(-rot) * rel;      // undo rotation
      rel /= max(scl*autoS, 1e-6); // undo scale
      float2 srcUV = pivot + rel;

      float4 col;
      if(u.mirrorEdges){
        col = sampleTex(inputImg, mirror(srcUV));
      } else {
        if(any(lessThan(srcUV, float2(0.0))) || any(greaterThan(srcUV, float2(1.0)))){
          col = float4(0.0);
        } else {
          col = sampleTex(inputImg, srcUV);
        }
      }

      __nv_out = col;
    return __nv_out;
}
