// ---------------------------------------------------------------------------
// 2D Camera Shake (Wiggle)
// origem : assets/effects/toji-Awiggle.xml
// id     : com.alightcreative.effects.motion_wiggle
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_AwiggleParams {
    float ampPosX;
    float ampPosY;
    float ampRot;
    float ampScale;
    float frequency;
    float octaves;
    float roughness;
    float seed;
    float strength;
    float pivotX;
    float pivotY;
    int mirrorEdges;
    float expand;
};

// --- funcoes auxiliares do efeito
static float4 sampleTex(sampler2D t, float2 uv){ return t.sample(__nv_smp, uv); }

    // Hash and value noise
    float hash(float n){ return fract(sin(n)*43758.5453123); }
    float noise1(float x){
      float i = floor(x), f = fract(x);
      float u = f*f*(3.0-2.0*f);
      return mix(hash(i+u.seed), hash(i+1.0+u.seed), u);
    }
    // Fractal brownian motion
    float fbm(float x, float oct, float rough){
      float a = 1.0, f = 1.0, sum = 0.0, norm = 0.0;
      for(int i=0;i<8;i++){
        if(float(i) >= oct) break;
        sum += noise1(x*f) * a;
        norm += a;
        a *= clamp(rough, 0.0, 1.0);
        f *= 2.0;
      }
      return (norm>0.0)? sum/norm : 0.0;
    }

    float2x2 rot2(float a){ float s=sin(a), c=cos(a); return float2x2(c,-s,s,c); }

    // Mirror-edge UV helper
    float2 mirror(float2 uv){ return abs(fract(uv*0.5+0.5)*2.0-1.0); }

fragment float4 fx_toji_Awiggle(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_AwiggleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;

      // Noise timebase
      float t = eng.acTime * u.frequency;
      float oct = clamp(u.octaves, 1.0, 6.0);

      // Generate 3 channels of fbm for x,y,rot,scale using offsets
      float nX = fbm(t + 37.17, oct, u.roughness) * 2.0 - 1.0;
      float nY = fbm(t + 91.73, oct, u.roughness) * 2.0 - 1.0;
      float nR = fbm(t + 153.11, oct, u.roughness) * 2.0 - 1.0;
      float nS = fbm(t + 241.57, oct, u.roughness) * 2.0 - 1.0;

      // Amplitudes
      float2 posPx = float2(u.ampPosX*nX, u.ampPosY*nY) * u.strength;
      float rotDeg = u.ampRot * nR * u.strength;
      float scl = 1.0 + u.ampScale * nS * u.strength;

      // Convert pixel translation to UV
      float2 texSize = __nv_getTexSize(inputImg_info.size);
      float2 posUV = posPx / max(texSize, float2(1.0));

      // Pivot
      float2 pivot = float2(u.pivotX, u.pivotY);

      // Auto u.expand to hide borders (scale up slightly)
      float autoS = 1.0 + u.expand;

      // For each screen uv, compute source uv by applying inverse transform
      // Forward T: scale*scl -> rotate(rot) -> translate(posUV), also autoS
      // Inverse: undo translate, then rotate(-rot), then scale by 1/(scl*autoS)
      float rot = radians(rotDeg);
      float2 rel = uv - pivot;
      rel -= posUV;                // undo translation
      rel = rot2(-rot) * rel;      // undo rotation
      rel /= max(scl*autoS, 1e-6); // undo scale
      float2 srcUV = pivot + rel;

      // Edge handling
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
