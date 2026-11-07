// ---------------------------------------------------------------------------
// Polytrace Sampler
// origem : assets/effects/toji-polytrace.xml
// id     : com.alightcreative.effects.polytrace_sampler
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_polytraceParams {
    float cellSize;
    float neighborRange;
    int safeMode;
    float gradPull;
    float jitter;
    float seed;
    float alpha;
};

// --- funcoes auxiliares do efeito
// Polytrace Sampler (original, no Shadertoy code)
    // Two modes:
    //  - Safe Mode: 3 fixed neighbor cells, centroid sample
    //  - Standard: Gradient-pulled jittered points; choose triangle containing the pixel

    // Limits
    const int MaxNeighbor = 2;  // compile-time bound; gated by u.neighborRange
    const int MaxPoints   = 12; // candidate set size (keep small for mobile)

    // Lightweight hash
    static float hash21(float2 p){ return fract(sin(dot(p, float2(127.1,311.7)) + u.seed*53.0) * 43758.5453); }
    static float2 hash22(float2 p){ return float2(hash21(p), hash21(p*1.37+19.7)); }

    // Pixel->UV mapping (normalized by screen size)
    static float4 fetchColorPx(float2 posPx){
      float2 uv = clamp(posPx / max(eng.acScreenSize, float2(1.0)), 0.0, 1.0);
      return inputImg.sample(__nv_smp, uv);
    }

    // Value used for gradient (simple modified luminance for contrast guidance)
    static float computeValue(float2 posPx){
      float4 c = fetchColorPx(posPx);
      // Slight non-linear mix to enhance midtones without copying any external code
      float lum = dot(c.rgb, float3(0.2126, 0.7152, 0.0722));
      float e = dot(c, float4(-1.0, 2.0, -1.0, 0.0));
      float m = clamp(0.5 + 0.5 * e, 0.0, 1.0);
      return mix(lum, lum * (0.8 + 0.4*m), 0.6);
    }

    // Central-difference gradient in pixel space
    static float2 computeGradientPx(float2 posPx, float eps){
      float he = max(eps*0.5, 0.5);
      float2 dx = float2(he, 0.0);
      float2 dy = float2(0.0, he);
      float gx = computeValue(posPx + dx) - computeValue(posPx - dx);
      float gy = computeValue(posPx + dy) - computeValue(posPx - dy);
      return float2(gx, gy) / max(eps, 1.0);
    }

    // Generate one candidate point for a given grid cell (x,y)
    static float2 generatePoint(int2 cell, float tileSize){
      float2 cellF = float2(cell);
      float2 rnd = hash22(cellF);
      // Hex-like offset pattern, plus u.jitter
      float2 base = cellF + float2(1.0, 0.0) * (__nv_mod(float(cell.y), 2.0) - 0.5) * 0.5
                        + (rnd - 0.5) * u.jitter;
      float2 p = base * tileSize;
      // Gradient pullback to align with local structure
      if(u.gradPull > 0.0){
        float2 g = computeGradientPx(p, tileSize);
        float gl = length(g);
        float2 ng = (gl < 1e-4) ? (rnd - 0.5) * 0.1 : normalize(g);
        float lenPx = min(0.005 / max(gl, 1e-4), 1.0) * tileSize * u.gradPull;
        p -= ng * lenPx;
      }
      return p;
    }

    // Helpers for triangle selection (kept local/global for GLES friendliness)
    static bool pointInTri(float2 p, float2 a, float2 b, float2 c){
      float2 v0=b-a, v1=c-a, v2=p-a;
      float d00=dot(v0,v0), d01=dot(v0,v1), d02=dot(v0,v2);
      float d11=dot(v1,v1), d12=dot(v1,v2);
      float inv=1.0/max(d00*d11 - d01*d01, 1e-6);
      float u=(d11*d02 - d01*d12)*inv;
      float v=(d00*d12 - d01*d02)*inv;
      return (u>=0.0)&&(v>=0.0)&&((u+v)<1.0);
    }

    static float2 isectLines(float2 p1, float2 d1, float2 p2, float2 d2){
      float det = d1.x*d2.y - d1.y*d2.x;
      float2 df = p2 - p1;
      float t = (df.x*d2.y - df.y*d2.x) / max(abs(det), 1e-6);
      return p1 + d1 * t;
    }

    float2 gPts[MaxPoints];
    float gDist[MaxPoints];
    static bool circumEmpty(int i1,int i2,int i3){
      float2 c = isectLines((gPts[i1]+gPts[i2])*0.5, (gPts[i2]-gPts[i1]).yx*float2(1.0,-1.0),
                          (gPts[i1]+gPts[i3])*0.5, (gPts[i3]-gPts[i1]).yx*float2(1.0,-1.0));
      float r = length(gPts[i1]-c);
      for(int i=0;i<MaxPoints;i++){
        if(i==i1||i==i2||i==i3) continue;
        if(length(gPts[i]-c) < r) return false;
      }
      return true;
    }

fragment float4 fx_toji_polytrace(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_polytraceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      // Pixel and grid setup
      float2 fragPx = in.acScreenNorm * eng.acScreenSize; // convert UV to pixel coords
      float tileSize = max(u.cellSize, 1.0);
      float2 gpos = floor(fragPx / tileSize + 0.5);

      float2 centroid;
      if(u.safeMode){
        // Minimal path: evaluate only 3 fixed neighboring cells
        int2 c0 = int2(int(gpos.x), int(gpos.y));
        float2 pt0 = generatePoint(c0, tileSize);
        float2 pt1 = generatePoint(c0 + int2(1,0), tileSize);
        float2 pt2 = generatePoint(c0 + int2(0,1), tileSize);
        centroid = (pt0 + pt1 + pt2) / 3.0;
      } else {
        // Build candidate set of nearest points
        for(int i=0;i<MaxPoints;i++){ gDist[i]=1e9; gPts[i]=float2(0.0); }
        int r = int(clamp(float(u.neighborRange), 1.0, float(MaxNeighbor)));
        for(int dy=-MaxNeighbor; dy<=MaxNeighbor; dy++){
          for(int dx=-MaxNeighbor; dx<=MaxNeighbor; dx++){
            if(abs(dx)>r || abs(dy)>r) continue;
            int2 cell = int2(int(gpos.x) + dx, int(gpos.y) + dy);
            float2 pt = generatePoint(cell, tileSize);
            float d = length(fragPx - pt);
            // insertion into sorted arrays
            for(int k=0;k<MaxPoints;k++){
              if(d < gDist[k]){
                float td=gDist[k]; gDist[k]=d; d=td;
                float2 tp=gPts[k]; gPts[k]=pt; pt=tp;
              }
            }
          }
        }
        // Try to find a triangle around the fragment with empty circumcircle
        bool found=false; int i1=0,i2=1,i3=2; int N=8;
        for(int a=0; a<MaxPoints; a++){
          if(a>=N) break;
          for(int b=0; b<MaxPoints; b++){
            if(b>=N) break;
            if(b==a) continue;
            for(int c=0; c<MaxPoints; c++){
              if(c>=N) break;
              if(c==a || c==b) continue;
              if(pointInTri(fragPx, gPts[a], gPts[b], gPts[c]) && circumEmpty(a,b,c)){
                i1=a; i2=b; i3=c; found=true; break;
              }
            }
            if(found) break;
          }
          if(found) break;
        }
        if(found){
          centroid = (gPts[i1] + gPts[i2] + gPts[i3]) / 3.0;
        } else {
          // Fallback: average the 3 nearest
          centroid = (gPts[0] + gPts[1] + gPts[2]) / 3.0;
        }
      }
      float4 col = fetchColorPx(centroid);

      // Preserve original u.alpha and apply control
      float aSrc = inputImg.sample(__nv_smp, in.acScreenNorm).a;
      __nv_out = float4(col.rgb, 1.0) * aSrc * u.alpha;
    return __nv_out;
}
