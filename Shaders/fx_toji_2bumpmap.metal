// ---------------------------------------------------------------------------
// Bump Map pro
// origem : assets/effects/toji-2bumpmap.xml
// id     : com.alightcreative.effects.bumpmap_universal
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_2bumpmapParams {
    int heightSource;
    float heightScale;
    float bumpIntensity;
    float normalRes;
    int quality;
    int lightType;
    float2 lightDir;
    float lightDepth;
    float lightIntensity;
    float ambient;
    float roughness;
    float specularIntensity;
    float4 specularTint;
    int preserveAlpha;
    int unpremultBeforeShade;
    float exposure;
};

// --- funcoes auxiliares do efeito
const float3 W = float3(0.2126, 0.7152, 0.0722);

    float luma(float3 c){ return dot(c, W); }

    float heightAt(float2 uv){
      if (u.heightSource == 1) {
        float4 h = heightMap.sample(__nv_smp, uv);
        return luma(h.rgb) * u.heightScale;
      }
      float4 s = inputImg.sample(__nv_smp, uv);
      return luma(s.rgb) * u.heightScale;
    }

    float3 computeNormal(float2 uv, float2 texel, float radius){
      float r = radius;
      if (u.quality == 1) {
        // Sobel (8 taps)
        float tl = heightAt(uv + float2(-texel.x,  texel.y) * r);
        float tc = heightAt(uv + float2( 0.0     ,  texel.y) * r);
        float tr = heightAt(uv + float2( texel.x ,  texel.y) * r);
        float ml = heightAt(uv + float2(-texel.x,  0.0    ) * r);
        float mr = heightAt(uv + float2( texel.x ,  0.0    ) * r);
        float bl = heightAt(uv + float2(-texel.x, -texel.y) * r);
        float bc = heightAt(uv + float2( 0.0     , -texel.y) * r);
        float br = heightAt(uv + float2( texel.x , -texel.y) * r);
        float dx = (tr + 2.0*mr + br) - (tl + 2.0*ml + bl);
        float dy = (tl + 2.0*tc + tr) - (bl + 2.0*bc + br);
        return normalize(float3(-dx * u.bumpIntensity, -dy * u.bumpIntensity, 1.0));
      } else {
        // Standard (4 taps)
        float hR = heightAt(uv + float2(texel.x * r, 0.0));
        float hL = heightAt(uv - float2(texel.x * r, 0.0));
        float hU = heightAt(uv + float2(0.0, texel.y * r));
        float hD = heightAt(uv - float2(0.0, texel.y * r));
        float dx = (hR - hL);
        float dy = (hU - hD);
        return normalize(float3(-dx * u.bumpIntensity, -dy * u.bumpIntensity, 1.0));
      }
    }

    float shininessFromRoughness(float r){
      // Map u.roughness 0..1 to shininess ~ 256..8 (inverse relation)
      return mix(256.0, 8.0, clamp(r, 0.0, 1.0));
    }

fragment float4 fx_toji_2bumpmap(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_2bumpmapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> heightMap [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& heightMap_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;
      float2 texel = 1.0 / eng.acScreenSize;

      float4 base = inputImg.sample(__nv_smp, uv);
      float4 src = base;
      if (u.unpremultBeforeShade && src.a > 0.0) src.rgb /= src.a;

      // Normal from height
      float3 n = computeNormal(uv, texel, u.normalRes);

      // Light vector: directional or point
      float3 V = float3(0.0, 0.0, 1.0);
      float3 L;
      if (u.lightType == 1) {
        // Point: position in screen space, depth controls Z
        float3 lightPos = float3(u.lightDir.x / 2.0, -u.lightDir.y / 2.0, -u.lightDepth * 0.02);
        float3 p = float3(uv * 2.0 - 1.0, 0.0);
        L = normalize(lightPos - p);
      } else {
        // Directional: use (u.lightDir, u.lightDepth) as a direction vector
        L = normalize(float3(u.lightDir.x, -u.lightDir.y, u.lightDepth));
      }

      float diff = max(dot(n, L), 0.0) * u.lightIntensity;

      float3 H = normalize(L + V);
      float specPow = shininessFromRoughness(u.roughness);
      float spec = pow(max(dot(n, H), 0.0), specPow) * u.specularIntensity;

      // Composite lighting
      float amb = u.ambient;
      float3 lit = src.rgb * (amb + diff * (1.0 - amb));
      lit += u.specularTint.rgb * spec;
      lit *= u.exposure;

      float4 outC = float4(lit, src.a);
      if (u.unpremultBeforeShade && src.a > 0.0) outC.rgb *= src.a;
      if (u.preserveAlpha) outC.a = base.a;
      __nv_out = outC;
    return __nv_out;
}
