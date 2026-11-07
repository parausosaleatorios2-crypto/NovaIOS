// ---------------------------------------------------------------------------
// Water Droplets
// origem : assets/effects/toji-water_droplets.xml
// id     : com.alightcreative.effects.water_droplets
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_water_dropletsParams {
    float dropletCount;
    float expandSpeed;
    float heightFactor;
    float rippleFreq;
    float timeSpeed;
    float seed;
    float normalOffset;
    float normalStrength;
    float blend;
    float alpha;
    int dropletsOnly;
    int shockwave;
    float shockStrength;
    float shockWidth;
};

// --- funcoes auxiliares do efeito
// Water Droplets (Shadertoy-style) -> Alight Motion port

    const float PI = 3.141592653589793;

    // Small hash helpers (no texture required)
    float hash11(float p) {
      p = fract(p * 0.1031);
      p *= p + 33.33;
      p *= p + p;
      return fract(p);
    }
    float hash21(float2 p) {
      float3 p3 = fract(float3(p.xyx) * 0.1031);
      p3 += dot(p3, p3.yzx + 33.33);
      return fract((p3.x + p3.y) * p3.z);
    }
    float2 hash22(float2 p) {
      float n = hash21(p);
      float m = hash21(p + 17.17);
      return float2(n, m);
    }

    // Droplet height field
    float getDropletHeight(float2 uv) {
      float timeVal = (eng.acTime + u.seed) * u.timeSpeed;
      float height = 0.0;

      int N = int(clamp(float(u.dropletCount), 1.0, 64.0));
      for (int i = 0; i < 64; ++i) {
        if (i >= N) break;
        float fi = float(i);

        // Derive per-droplet properties from hashes
        float decayRate = 0.323 + 2.0 * hash11(fi * 1.123 + 0.237);
        float dropletStrength = hash11(fi * 0.713 + 0.001);
        float dropletStrengthBias = 0.1 + 0.2 * hash11(fi * 2.371 + 0.345);

        float dropFractionFull = timeVal / decayRate;
        float dropIndex = floor(dropFractionFull);
        float dropFraction = fract(dropFractionFull);

        // Position per (i, dropIndex)
        float2 rnd = hash22(float2(fi * 0.731 + dropIndex * 0.1, dropIndex * 1.123));
        float2 dropletPosition = rnd * 2.0 - 1.0; // [-1,1] range like original code

        float ringRadius = u.expandSpeed * dropFraction * dropletStrength - dropletStrengthBias;
        ringRadius = max(ringRadius, 0.0001);

        float distToDroplet = distance(uv, dropletPosition);
        float within = distToDroplet > ringRadius ? 0.0 : 1.0;

        float edgeDist = max(0.0, ringRadius - distToDroplet) / ringRadius;
        float h = within > 0.5 ? distToDroplet : 0.0;
        // Cosine ripples
        h = cos(PI + (h - ringRadius) * u.rippleFreq * dropletStrength) * 0.5 + 0.5;
        h *= 1.0 - dropFraction; // fade as ring expands
        h *= within > 0.5 ? distToDroplet / ringRadius : 0.0;

        // Nonlinear shaping similar to original
        float shaped = (1.0 - (cos(h * PI) + 1.0) * 0.5);
        height += shaped * u.heightFactor;
      }
      return height;
    }

    // Compute surface normal from height field
    float3 getDropletNormal(float2 uv) {
      float off = u.normalOffset;
      float3 ofs = float3(-off, 0.0, off);

      float s11 = getDropletHeight(uv);
      float s01 = getDropletHeight(uv + ofs.xy);
      float s21 = getDropletHeight(uv + ofs.zy);
      float s10 = getDropletHeight(uv + ofs.yx);
      float s12 = getDropletHeight(uv + ofs.yz);

      float3 va = normalize(float3(ofs.z, 0.0, s21 - s11));
      float3 vb = normalize(float3(0.0, ofs.z, s12 - s11));

      float3 n = normalize(cross(va, vb));
      n.xy *= s11 * u.normalStrength;
      return normalize(n);
    }

fragment float4 fx_toji_water_droplets(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_water_dropletsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> envTex [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& envTex_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      // Aspect-correct droplet space: x scaled by screen aspect, centered [-1,1]
      float2 aspect = float2(eng.acScreenSize.x / eng.acScreenSize.y, 1.0);
      float2 uv = (in.acScreenNorm - 0.5) * 2.0;
      uv.x *= aspect.x;

      // Generate normal
      float3 normal = getDropletNormal(uv);

      // Droplet mask from height field (limits effect region)
      float h = getDropletHeight(uv);
      float mask = clamp(h * 8.0, 0.0, 1.0);

      // Sample environment by normal.xy mapped to UV
      // If no envTex provided, sample the input image instead
      float2 envUV = normal.xy * 0.5 + 0.5;
      float3 envColor = envTex.sample(__nv_smp, envUV).rgb;

      // Optionally distort the clip using a u.shockwave derived from the droplet gradient
      float2 srcUV = in.acScreenNorm;
      if(u.shockwave && !u.dropletsOnly){
        float eps = max(0.001, u.normalOffset);
        float hx = getDropletHeight(uv + float2(eps, 0.0)) - getDropletHeight(uv - float2(eps, 0.0));
        float hy = getDropletHeight(uv + float2(0.0, eps)) - getDropletHeight(uv - float2(0.0, eps));
        float2 grad = float2(hx, hy) / (2.0 * eps);
        float edge = clamp(length(grad) * u.shockWidth, 0.0, 1.0);
        float2 dir = normalize(grad + 1e-6);
        float2 offset = dir * edge * u.shockStrength;
        // Convert from aspect-correct droplet space to normalized screen UVs
        float2 offsetScreen = float2(offset.x / aspect.x, offset.y) * 0.5;
        // apply only where droplets exist
        srcUV += offsetScreen * mask;
      }

      float4 src = inputImg.sample(__nv_smp, srcUV);

      // Output
      if(u.dropletsOnly){
        // Only droplets: color from env, masked by droplet presence
        float3 col = envColor * mask;
        float a = mask * u.alpha;
        __nv_out = float4(col, 1.0) * a;
      } else {
        // Masked additive over source to avoid global brightening
        float3 outRGB = mix(src.rgb, src.rgb + envColor * mask, clamp(u.blend, 0.0, 1.0));
        float a = src.a * u.alpha;
        __nv_out = float4(outRGB, 1.0) * a;
      }
    return __nv_out;
}
