// ---------------------------------------------------------------------------
// Cosmic Burn(نار كونيه)
// origem : assets/effects/toji-cosmicburn.xml
// id     : com.alightcreative.effects.cosmic_burn_star
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_cosmicburnParams {
    float starRadius;
    float points;
    float inner;
    float edgeSoft;
    float scale1;
    float speed1;
    float scale2;
    float speed2;
    float scale3;
    float speed3;
    float glowFalloff;
    float timeSpeed;
    float distance;
    float thickness;
    int edgeSide;
    float burnProgress;
    float burnWidth;
    float burnHardness;
    int autoAnimate;
    float burnRate;
    float smoothFeather;
    float cutFeather;
    float glowFeather;
    float cutAmount;
    float4 fillColor;
    float alpha;
    int blendMode;
    float fill;
    int hideBase;
    int paletteMode;
    float glowIntensity;
    float4 tintColor;
    float whiteHot;
    float auraIntensity;
    float auraFalloff;
    float heatStrength;
    float heatScale;
    float edgeNoiseAmt;
    float edgeNoiseScale;
    float seed;
    float hotspotThresh;
    float hotspotGain;
};

// --- funcoes auxiliares do efeito
// ShaderToy -> Alight Motion mapping
    // iResolution.xy -> eng.acScreenSize
    // iTime -> eng.acTime
    // fragCoord -> in.acScreenNorm * eng.acScreenSize

    // Hash and value noise (for edge roughness & heat ripple)
    static float r2(float2 p){ return fract(sin(dot(p, float2(12.9898,78.233))) * 43758.5453123); }
    static float vnoise2(float2 p){
      float2 i=floor(p), f=fract(p);
      float2 u=f*f*(3.0-2.0*f);
      float n00=r2(i);
      float n10=r2(i+float2(1.0,0.0));
      float n01=r2(i+float2(0.0,1.0));
      float n11=r2(i+float2(1.0,1.0));
      float nx0=mix(n00,n10,u.x);
      float nx1=mix(n01,n11,u.x);
      return mix(nx0,nx1,u.y);
    }

    static float3 firePalette(float w){
      // w in [0..1] near ring -> hotter
      float3 c = float3(0.0);
      c += float3(1.0, 0.15, 0.05) * pow(w, 0.7);   // deep red
      c += float3(1.0, 0.55, 0.10) * pow(w, 1.2);   // orange
      c += float3(1.0, 0.95, 0.85) * pow(w, 2.2);   // white hot
      return saturate(c);
    }

    static float starShape(float2 uv, float r, float u.points, float u.inner){
      float a = __nv_atan(uv.y, uv.x);
      float d = length(uv);
      float pi = 3.141592653589793;
      float p = u.points;
      float seg = (2.0*pi/p);
      float k = cos(floor(0.5 + a/seg)*seg - a) * u.inner + 1.0;
      return d - r * k;
    }

    static float plasmaLayer(float2 uv, float scale, float speed, float shift){
      float t = eng.acTime * u.timeSpeed;
      return sin(uv.x*scale + t*speed + shift) * 0.01 +
             cos(uv.y*scale - t*speed*1.3 + shift*1.7) * 0.01;
    }

    static float3 palette(float x){
      // Rainbow cosine palette around offsets similar to the Shadertoy code
      float t = eng.acTime * u.timeSpeed;
      return 0.5 + 0.5 * cos(6.2831853 * (float3(0.25,0.4,0.6) + t + x));
    }

fragment float4 fx_toji_cosmicburn(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_cosmicburnParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> blurBuf [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& blurBuf_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 fragCoord = in.acScreenNorm * eng.acScreenSize;
      float2 iResolution = eng.acScreenSize;
      // Centered, keep aspect by dividing by height
      float2 uv = (fragCoord - 0.5*iResolution.xy) / max(iResolution.y, 1.0);

      // Base star/cosmic modulation (optional aesthetic)
      float star = starShape(uv, u.starRadius, float(u.points), u.inner);
      float distort = 0.0;
      distort += plasmaLayer(uv, u.scale1, u.speed1, 0.0);
      distort += plasmaLayer(uv, u.scale2, u.speed2, 2.0);
      distort += plasmaLayer(uv, u.scale3, u.speed3, 5.0);

      // Edge mask from blurred u.alpha like electricedges
      float2 pixelSize = float2(1.0) / max(iResolution, float2(1.0));
      float4 blurMid = blurBuf.sample(__nv_smp, in.acScreenNorm);
      float4 blurUp = blurBuf.sample(__nv_smp, in.acScreenNorm + pixelSize*float2(0.0,-4.0));
      float4 blurLeft = blurBuf.sample(__nv_smp, in.acScreenNorm + pixelSize*float2(-4.0,0.0));
      float dx = blurMid.a - blurLeft.a;
      float dy = blurMid.a - blurUp.a;
      float2 gradN = normalize(float2(dx, dy));
      float p = blurMid.a;
      // Burn progression -> drive ring iso-u.alpha position
      float prog = clamp(u.burnProgress + (u.autoAnimate ? eng.acTime * u.burnRate : 0.0), 0.0, 1.0);
      // Map progress to iso-value across u.alpha range (1.0 inside -> 0.0 outside)
      float dist = mix(0.95, 0.05, prog);
      // Add user u.distance trim (kept for finer nudge)
      dist += (0.5 - (u.distance * 0.4 + 0.5)) * 0.1;
      float ringW = max(u.burnWidth, 0.001);
      // Edge noise
      float n = vnoise2(in.acScreenNorm*u.edgeNoiseScale + float2(u.seed*7.123, u.seed*3.71 + eng.acTime*0.05));
      float distN = dist + (u.edgeNoiseAmt * (n - 0.5)) * ringW * 1.5;
      // Ring profile and hardness
      float ringWFeather = ringW * mix(0.5, 2.0, clamp(u.smoothFeather,0.0,1.0));
      float core = 1.0 - smoothstep(0.0, ringWFeather, abs(p - distN));
      float hardnessExp = mix(6.0, 1.0, clamp(u.burnHardness,0.0,1.0));
      float ringMask = pow(saturate(core), hardnessExp);
      // Edge side gating
      if(u.edgeSide==0){ // Outer
        ringMask *= (1.0 - step(distN, p));
      } else if(u.edgeSide==1){ // Inner
        ringMask *= step(distN, p);
      }

      // Heat ripple: distort sampling of input
      float heatN = (vnoise2(in.acScreenNorm*u.heatScale + float2(u.seed*1.23, 17.31 + eng.acTime*0.2)) - 0.5);
      // Robust normalize to avoid isnan on some GLES
      float2 heatDir = normalize(gradN + float2(1e-6));
      float2 sampleUV = in.acScreenNorm + heatDir * u.heatStrength * ringMask * (0.5 + heatN);

      // Sample base layer with distortion
      float4 texColor = inputImg.sample(__nv_smp, sampleUV);

      // Emission color (palette)
      float edgeProx = saturate(1.0 - abs(p - distN) / ringW);
      float3 fireCol = firePalette(edgeProx);
      float3 rainbowCol = palette(star*6.0);
      float3 emissive = (u.paletteMode==0 ? fireCol : rainbowCol);
      // Mix toward white close to the edge
      emissive = mix(emissive, float3(1.0), clamp(u.whiteHot,0.0,2.0) * pow(edgeProx, 2.0));
      // Apply user tint (for blue look)
      emissive *= u.tintColor.rgb;
      // Core glow with adjustable feather
      float dNorm = abs(p - distN) / max(ringW, 1e-4);
      float glowArg = pow(dNorm, clamp(u.glowFeather,0.5,3.0));
      float3 glow = emissive * u.glowIntensity * exp(-u.glowFalloff * glowArg);
      // Hotspot shaping for blobby bright patches
      float blobN = vnoise2(in.acScreenNorm*(u.edgeNoiseScale*0.7) + float2(u.seed*2.17, eng.acTime*0.12));
      float hot = saturate((edgeProx + (blobN-0.5)*0.6 - u.hotspotThresh) * (2.0 + u.hotspotGain));
      glow *= (1.0 + pow(hot, u.hotspotGain) * 1.5);
      // Outer aura for wide yellow halo
      float auraDist = abs(p - (distN + ringW*1.15)) / max(ringW*2.2, 1e-4);
      float3 aura = emissive * u.auraIntensity * exp(-u.auraFalloff * auraDist);
      float3 finalColor = glow + aura;

      // Ring as edgeMask for emission placement
      float edgeMask = ringMask;

      // Apply mask to effect color
      float4 masked = float4(finalColor, 1.0) * edgeMask;

      // If base is hidden, render only the generated effect
      if(u.hideBase){
        __nv_out = masked;
        return __nv_out;
      }

      // Destructive u.alpha cutout: carve behind the ring toward inside
      float cutWidth = ringW * (1.0 + clamp(u.cutFeather,0.0,1.0)*1.5);
      float cutMask = smoothstep(distN, distN + cutWidth, p) * edgeMask;
      texColor.a *= (1.0 - cutMask * u.cutAmount);

      // Compose with input
      float4 outColor;
      if(u.blendMode==1){
        outColor = float4((texColor.rgb/texColor.a) * masked.rgb, 1.0) * texColor.a;
      } else if(u.blendMode==2){
        outColor = float4(1.0 - (1.0 - (texColor.rgb/texColor.a)) * (1.0 - masked.rgb), 1.0) * texColor.a;
      } else {
        outColor = masked * texColor.a;
        outColor = texColor*(1.0 - outColor.a) + outColor;
      }

      // Preserve some original u.fill inside per user control
      __nv_out = mix(texColor * u.fill, outColor, u.alpha);
    return __nv_out;
}
