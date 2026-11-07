// ---------------------------------------------------------------------------
// Organic Particles Up
// origem : assets/effects/toji-organic_particles_up.xml
// id     : com.alightcreative.effects.organic_particles_up
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_organic_particles_upParams {
    float particleCount;
    float speedScale;
    float sizeScale;
    float tailFreqScale;
    float seedOffset;
    float4 tint;
    float intensity;
    float blend;
    float alpha;
};

// --- funcoes auxiliares do efeito
// Procedural upward organic particles (Buffer A port)

    static float rand(float2 co){
      return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
    }

    static float organicWave(float y, float id) {
      float freq1 = rand(float2(id + u.seedOffset, 5.0)) * 3.0 + 2.0;
      float amp1  = rand(float2(id + u.seedOffset, 6.0)) * 0.04;
      float freq2 = rand(float2(id + u.seedOffset, 7.0)) * 10.0 + 8.0;
      float amp2  = rand(float2(id + u.seedOffset, 8.0)) * 0.02;
      float drift = sin(eng.acTime * (rand(float2(id + u.seedOffset, 1.1)) * 0.3 + 0.1));
      return sin(y * freq1 + id) * amp1 + sin(y * freq2 + id) * amp2 + drift * 0.02;
    }

    static float3 createParticle(float2 uv, float id, float aspect) {
      float initial_x      = rand(float2(id + u.seedOffset, 1.0));
      float speed          = mix(0.04, 0.12, rand(float2(id + u.seedOffset, 2.0))) * u.speedScale;
      float phase          = rand(float2(id + u.seedOffset, 3.0)) * 200.0;
      float size           = mix(0.6, 1.3, rand(float2(id + u.seedOffset, 4.0))) * u.sizeScale;
      float tail_dot_freq  = (mix(150.0, 200.0, rand(float2(id + u.seedOffset, 9.0))) * u.tailFreqScale);

      float y_pos = fract((eng.acTime + phase) * speed);
      float x_pos = initial_x + organicWave(y_pos, id);
      float2 pos = float2(x_pos, y_pos);

      float2 uv_aspect = uv; uv_aspect.x *= aspect; pos.x *= aspect;

      // Head
      float2 p_head = uv_aspect - pos;
      float head_dist = length(p_head) - p_head.y * 0.4;
      float head_size = 0.009 * size;
      float head = smoothstep(head_size, head_size * 0.3, head_dist);

      // Tail
      float tail = 0.0;
      if (uv.y < pos.y) {
        float y_dist_from_head = (pos.y - uv.y);
        float tail_x_center = (initial_x + organicWave(uv.y, id)) * aspect;
        float x_dist_from_center = uv_aspect.x - tail_x_center;
        float dots = smoothstep(0.7, 0.8, sin(y_dist_from_head * -tail_dot_freq));
        float falloff = exp(-y_dist_from_head * 18.0);
        float dot_size = 0.005 * falloff * size;
        tail = smoothstep(dot_size, 0.0, abs(x_dist_from_center)) * falloff * dots;
      }

      float intensityLocal = head + tail * 1.5;
      if (intensityLocal < 0.01) return float3(0.0);

      float3 base = pow(intensityLocal, 2.0) * u.tint.rgb;
      float3 glow = pow(intensityLocal, 4.0) * mix(float3(1.0, 0.2, 0.1), u.tint.rgb, 0.5);
      return (base + glow) * u.intensity;
    }

fragment float4 fx_toji_organic_particles_up(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_organic_particles_upParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float aspect = eng.acScreenSize.x / eng.acScreenSize.y;

      // Accumulate particles
      float3 final_color = float3(0.0);
      int count = int(clamp(float(u.particleCount), 1.0, 200.0));
      for(int i=0;i<200;i++){
        if(i>=count) break;
        final_color += createParticle(uv, float(i), aspect);
      }

      // Composite over source additively
      float4 src = inputImg.sample(__nv_smp, uv);
      float3 outRGB = mix(src.rgb, src.rgb + final_color, clamp(u.blend, 0.0, 1.0));
      float a = src.a * u.alpha;
      __nv_out = float4(outRGB, 1.0) * a;
    return __nv_out;
}
