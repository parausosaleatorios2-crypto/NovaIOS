// ---------------------------------------------------------------------------
// particles Dissolve
// origem : assets/effects/toji-particles_dissolve.xml
// id     : com.alightcreative.effects.granular_dissolve
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_particles_dissolveParams {
    float progress;
    float density;
    float size;
    float zDist;
    float scatter;
};

// --- funcoes auxiliares do efeito
float3 hash3(float2 p) {
      float3 q = float3(
        dot(p, float2(127.1, 311.7)),
        dot(p, float2(269.5, 183.3)),
        dot(p, float2(419.2, 371.9))
      );
      return fract(sin(q) * 43758.5453);
    }

    float gradientNoise(float2 p) {
      float2 i = floor(p);
      float2 f = fract(p);
      float2 u = f * f * (3.0 - 2.0 * f);

      float n = mix(
        mix(
          dot(-1.0 + 2.0 * hash3(i).xy, f - float2(0.0, 0.0)),
          dot(-1.0 + 2.0 * hash3(i + float2(1.0, 0.0)).xy, f - float2(1.0, 0.0)),
          u.x
        ),
        mix(
          dot(-1.0 + 2.0 * hash3(i + float2(0.0, 1.0)).xy, f - float2(0.0, 1.0)),
          dot(-1.0 + 2.0 * hash3(i + float2(1.0, 1.0)).xy, f - float2(1.0, 1.0)),
          u.x
        ),
        u.y
      );

      return 0.5 + 0.5 * n;
    }

    float fbm(float2 p) {
      float v = 0.0;
      float amp = 0.5;
      float freq = 1.0;
      for (int i = 0; i < 4; i++) {
        v += amp * gradientNoise(p * freq);
        freq *= 2.0;
        amp *= 0.5;
      }
      return v;
    }

fragment float4 fx_toji_particles_dissolve(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_particles_dissolveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 iResolution = eng.acScreenSize;
      float2 fragCoord = in.acScreenNorm * iResolution;
      float2 uv = fragCoord / iResolution;
      float aspect = iResolution.x / iResolution.y;

      float noiseScale = 3.0;
      float dissolveMap = fbm(uv * float2(aspect, 1.0) * noiseScale + 10.0);

      float t = u.progress * 1.6;
      float solidAlpha = smoothstep(t - 0.05, t + 0.05, dissolveMap);

      float3 finalColor = float3(0.0);

      if (solidAlpha > 0.001) {
        float3 imgCol = inputImg.sample(__nv_smp, uv).rgb;
        finalColor = imgCol * solidAlpha;
      }

      float gridDim = u.density;
      float2 dims = float2(gridDim * aspect, gridDim);
      float2 cellSize = 1.0 / dims;
      float2 id = floor(uv * dims);

      int range = 2;
      for (int y = -2; y <= 2; y++) {
        for (int x = -2; x <= 2; x++) {
          float2 offset = float2(float(x), float(y));
          float2 neighborID = id + offset;

          float2 origin = (neighborID + 0.5) * cellSize;

          float3 rnd = hash3(neighborID);

          float pThreshold = fbm(origin * float2(aspect, 1.0) * noiseScale + 10.0);

          if (t < pThreshold) {
            continue;
          }

          float age = t - pThreshold;

          float z = 1.0 + (age * u.zDist);
          if (z < 0.05) {
            continue;
          }

          if (z > 1.0 && solidAlpha > 0.5) {
            continue;
          }

          float2 flow = float2(
            gradientNoise(neighborID * 0.1 + age),
            gradientNoise(neighborID * 0.1 + age + 100.0)
          ) - 0.5;
          float2 jitter = rnd.xy - 0.5;

          float2 posOffset = (flow * 0.8 + jitter * 0.2) * u.scatter * age;

          float2 worldPos = (origin - 0.5) * aspect;
          worldPos += posOffset;

          float2 projectedPos = worldPos / z;
          projectedPos.x /= aspect;
          float2 screenPos = projectedPos + 0.5;

          float2 diff = uv - screenPos;
          diff.x *= aspect;
          float dist = length(diff);

          float pSize = u.size * (0.8 + 0.4 * rnd.z);
          float radius = (0.5 * pSize) / u.density / z;

          float alpha = 1.0 - smoothstep(radius * 0.5, radius, dist);

          if (alpha > 0.0) {
            float3 pCol = inputImg.sample(__nv_smp, origin).rgb;

            float distFade = 1.0;
            if (z > 1.0) {
              distFade = 1.0 / (1.0 + age * 2.0);
            } else {
              distFade = smoothstep(0.05, 0.3, z);
            }

            alpha *= distFade;

            finalColor = mix(finalColor, pCol, alpha);
          }
        }
      }

      __nv_out = float4(finalColor, 1.0);
    return __nv_out;
}
