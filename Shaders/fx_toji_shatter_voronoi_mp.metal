// ---------------------------------------------------------------------------
// Shatter (Voronoi MP)
// origem : assets/effects/toji-shatter_voronoi_mp.xml
// id     : com.alightcreative.effects.shatter_voronoi_mp
// passes : 5
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_shatter_voronoi_mpParams {
    float progress;
    float cellScale;
    float randomness;
    float scatter;
    float rotAmount;
    float gravity;
    float edgeWidth;
    float edgeFeather;
    float4 edgeColor;
    float edgeGlow;
    int quality;
    int glowOnly;
};

// --- funcoes auxiliares do efeito
// Voronoi Shatter Multi‑Pass
    // Pass 0: compute shattered image into shatterPass (RGB) and write edge mask to alpha
    // Pass 1: extract edge mask from shatterPass.a into edgeMask (downsampled)
    // Pass 2: horizontal blur edgeMask -> hblur
    // Pass 3: vertical blur hblur -> vblur
    // Pass 4: composite shatterPass + edge glow (vblur * u.edgeColor * u.edgeGlow)

    const float PI = 3.14159265358979323846;

    // Hash helpers
    float hash11(float n){ return fract(sin(n)*43758.5453123); }
    float hash21(float2 p){ return fract(1e4*sin(17.0*p.x + 0.1*p.y)*(0.1+abs(sin(13.0*p.y+7.0*p.x)))); }

    // Rot2
    float2x2 r2(float a){ float s=sin(a), c=cos(a); return float2x2(c,-s,s,c); }

    // Voronoi: return nearest distance and ID; also second-nearest distance for edge width
    float4 voronoi(float2 uv, float u.cellScale, float randAmt){
      float2 g = uv * u.cellScale;
      float2 i = floor(g);
      float2 f = fract(g);

      float d1 = 1e9; float2 id1 = float2(0.0);
      float d2 = 1e9;

      for(int y=-1;y<=1;y++){
        for(int x=-1;x<=1;x++){
          float2 o = float2(x,y);
          float2 h = i + o;
          // jittered cell point
          float s = hash21(h);
          float2 p = fract(float2(s, hash11(s*91.7)) + randAmt*0.6);
          float2 diff = (o + p) - f;
          float d = dot(diff,diff);
          if(d < d1){ d2 = d1; d1 = d; id1 = h + p; }
          else if(d < d2){ d2 = d; }
        }
      }
      return float4(d1, d2, id1);
    }

    // Simple separable blur (incremental Gaussian) on edge mask
    float4 blurInternal(sampler2D tex, float2 texOffset, float2 st, float numBlurPixelsPerSide){
      float adjSigma = numBlurPixelsPerSide / 2.14596602;
      const float PIc = 3.14159265;
      float3 incG;
      incG.x = 1.0 / (sqrt(2.0 * PIc) * max(adjSigma,1e-4));
      incG.y = exp(-0.5 / (max(adjSigma,1e-4) * max(adjSigma,1e-4)));
      incG.z = incG.y * incG.y;
      float4 avg = tex.sample(__nv_smp, st) * incG.x; float sum = incG.x;
      for(float i=1.0;i<=128.0;i+=2.0){
        float o0=i, o1=i+1.0;
        incG.xy *= incG.yz; float w0 = incG.x;
        incG.xy *= incG.yz; float w1 = incG.x;
        float w = w0 + w1;
        float off = (o0*w0 + o1*w1) / max(w,1e-6);
        float2 o = texOffset * off;
        avg += tex.sample(__nv_smp, st - o) * w;
        avg += tex.sample(__nv_smp, st + o) * w;
        sum += 2.0*w;
        if(i>numBlurPixelsPerSide) break;
      }
      return avg / max(sum,1e-6);
    }

fragment float4 fx_toji_shatter_voronoi_mp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_shatter_voronoi_mpParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> shatterPass [[texture(1)]],
    texture2d<float> edgeMask [[texture(2)]],
    texture2d<float> hblur [[texture(3)]],
    texture2d<float> vblur [[texture(4)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& shatterPass_info [[buffer(3)]],
    constant NovaTexInfo& edgeMask_info [[buffer(4)]],
    constant NovaTexInfo& hblur_info [[buffer(5)]],
    constant NovaTexInfo& vblur_info [[buffer(6)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      int Q = int(u.quality);
      float taps = (Q==1)? 6.0 : (Q==2? 10.0 : 14.0);

      if(eng.acPass==0){
        // Shatter & edge mask in alpha
        float2 uv = in.acLayerNorm; // content UV
        // Keep isotropy
        uv.x *= eng.acLayerSize.x/eng.acLayerSize.y;

        // Voronoi sites
        float4 v = voronoi(uv, u.cellScale, u.randomness);
        float d1 = sqrt(v.x);
        float d2 = sqrt(v.y);
        float2 site = v.zw; // in cell space
        // World site position (normalize to uv space)
        float2 siteUV = site / u.cellScale;

        // Cell random direction and angle
        float sid = hash21(floor(site));
        float2 dir = normalize(float2(cos(sid*6.2831), sin(sid*6.2831)) + 1e-3);
        float ang = radians(u.rotAmount) * u.progress * (sid*2.0-1.0);

        // Gravity (down in uv-y)
        float2 grav = float2(0.0, u.gravity * u.progress * u.progress);
        float2 T = dir * u.scatter * u.progress + grav;

        // Inverse transform: map current pixel back to source space of its cell
        float2 p = uv - siteUV;
        p = r2(-ang) * p; // undo rotation
        p -= T;           // undo translation
        float2 sampleUV = p + siteUV;

        // Undo aspect for sampling
        sampleUV.x /= eng.acLayerSize.x/eng.acLayerSize.y;

        float4 src = inputImg.sample(__nv_smp, (float4(sampleUV,0.,1.)*eng.acLayerToScreen).xy);

        // Edge metric from difference of nearest and 2nd nearest distances
        float e = clamp((d2 - d1) * u.cellScale * u.edgeWidth, 0.0, 1.0);
        float edgeMask = 1.0 - smoothstep(0.0, u.edgeFeather, e);

        __nv_out = float4(src.rgb, edgeMask * src.a);
        return __nv_out;
      }

      if(eng.acPass==1){
        // Extract edge mask from shatterPass alpha and write to edgeMask
        float4 s = shatterPass.sample(__nv_smp, in.acScreenNorm);
        __nv_out = float4(s.a);
        return __nv_out;
      }

      if(eng.acPass==2){
        // Horizontal blur edge mask
        float k = (Q==1? 6.0 : Q==2? 10.0 : 14.0);
        float kernelSize = k;
        float2 texOffset = float2(1.0/edgeMask_info.size.x, 0.0);
        __nv_out = blurInternal(edgeMask, texOffset, in.acScreenNorm.st, kernelSize);
        return __nv_out;
      }

      if(eng.acPass==3){
        // Vertical blur
        float k = (Q==1? 6.0 : Q==2? 10.0 : 14.0);
        float kernelSize = k;
        float2 texOffset = float2(0.0, 1.0/hblur_info.size.y);
        __nv_out = blurInternal(hblur, texOffset, in.acScreenNorm.st, kernelSize);
        return __nv_out;
      }

      // Final composite
      float4 shattered = shatterPass.sample(__nv_smp, in.acScreenNorm);
      float3 baseRGB = shattered.rgb;
      float edgeB = vblur.sample(__nv_smp, in.acScreenNorm).r;
      float3 glowRGB = u.edgeColor.rgb * edgeB * u.edgeGlow * u.edgeColor.a;
      float3 outRGB = u.glowOnly ? glowRGB : (baseRGB + glowRGB);
      __nv_out = float4(outRGB, shattered.a);
    return __nv_out;
}
