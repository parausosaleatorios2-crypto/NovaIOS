// ---------------------------------------------------------------------------
// Pixel Polly
// origem : assets/effects/toji-pixel_polly.xml
// id     : com.alightcreative.effects.pixel_polly
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_pixel_pollyParams {
    float force;
    float gravity;
    float spinRate;
    float2 forceCenter;
    float dirRand;
    float speedRand;
    float grid;
    int objectType;
    float startTime;
    float depthAmount;
    float searchMax;
    float seed;
};

// --- funcoes auxiliares do efeito
// Pixel Polly style triangle shatter with hard shards (no dissolve).
    // We test nearby candidate pieces and use the one whose inverse mapping
    // yields a valid original-triangle membership.

    static float hash12(float2 p){
      float3 p3 = fract(float3(p.xyx) * 0.1031);
      p3 += dot(p3, p3.yzx + 33.33);
      return fract((p3.x + p3.y) * p3.z);
    }

    static float2x2 r2(float a){ float s = sin(a), c = cos(a); return float2x2(c,-s,s,c); }

    // Decide triangle inside mask for a square cell, local coord q in [0,1)
    static bool triMask(float2 q, bool diag){
      // Small epsilon to avoid edge flicker differences across backends
      float e = 1e-5;
      if(!diag){
        return (q.x + q.y) <= 1.0 - e;
      } else {
        return (q.x - q.y) >= e;
      }
    }

    static float2 toPx(float2 uv){ return uv * __nv_getTexSize(inputImg_info.size); }
    static float2 toUv(float2 px){ float2 s = __nv_getTexSize(inputImg_info.size); return px / max(s, float2(1.0)); }

    static float4 sampleSafe(float2 uv){
      return inputImg.sample(__nv_smp, clamp(uv, 0.0, 1.0));
    }

    struct PieceParams { float2 disp; float rot; float2 pivotUv; bool diag; float scale; float depth; };

    static PieceParams getPiece(float2 cid, float t, float g){
      PieceParams P;
      float2 texSize = __nv_getTexSize(inputImg_info.size);
      float rnd1 = hash12(cid + float(u.seed));
      float rnd2 = hash12(cid.yx + float(u.seed)*1.113);
      bool diag = __nv_mod(cid.x + cid.y, 2.0) < 0.5; P.diag = diag;

      // cell center and triangle pivot
      float2 cellOriginPx = (cid + 0.5) * g;
      float2 triPivotOff = (diag ? float2(0.25, 0.75) : float2(0.75, 0.25)) - float2(0.5);
      float2 pivotPx = cellOriginPx + triPivotOff * g * 0.5;
      P.pivotUv = toUv(pivotPx);

      // direction with randomness
      float2 fc = u.forceCenter;
      float2 dir = normalize((toUv(cellOriginPx) - fc));
      float angleJitter = (rnd1 - 0.5) * 6.28318530718 * u.dirRand;
      dir = r2(angleJitter) * dir;
      float speedMul = 1.0 + (rnd2 - 0.5) * 2.0 * u.speedRand;

      float F = u.force / max(texSize.x, texSize.y);
      float2 v0 = dir * F * speedMul;
      float2 gy = float2(0.0, -u.gravity / max(texSize.y, 1.0));
      P.disp = v0 * t + 0.5 * gy * (t*t);
      P.rot = radians(u.spinRate) * t * (0.5 + rnd1);
      // Pseudo depth: farther shards shrink more; depth randomized per shard
      P.depth = u.depthAmount * t * (0.25 + rnd2); // grows over time
      P.scale = 1.0 / (1.0 + max(P.depth, 0.0));
      return P;
    }

    // Try inverse for a candidate cell id; return color.rgb and encoded depth in alpha; ok flag
    static float4 tryCandidate(float2 cidC, float t, float g, float2 uvNow, out bool ok){
      PieceParams P = getPiece(cidC, t, g);
      // inverse transform: current -> original uv0
      float2 uv0 = uvNow - P.disp;
      // apply inverse of scale and rotation around pivot
      uv0 = (r2(-P.rot) * ((uv0 - P.pivotUv) / max(P.scale, 1e-4))) + P.pivotUv;
      // check original membership is within this candidate triangle
      float2 pxy0 = toPx(uv0);
      float2 cid0 = floor(pxy0 / g);
      float2 q0 = fract(pxy0 / g);
      bool diag0 = __nv_mod(cid0.x + cid0.y, 2.0) < 0.5;
      bool inside0 = triMask(q0, diag0);
      // Avoid strict float equality; tolerate tiny differences
      bool sameCell = all(lessThan(abs(cid0 - cidC), float2(0.25)));
      ok = sameCell && inside0;
      float4 s = ok ? sampleSafe(uv0) : float4(0.0);
      // Pack depth in alpha for frontmost selection (smaller depth => front)
      s.a = ok ? P.depth : 1e9;
      return s;
    }

fragment float4 fx_toji_pixel_polly(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_pixel_pollyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      // If we're before the start time, render the original image (no break)
      if (eng.acTime < u.startTime) {
        float4 src0 = inputImg.sample(__nv_smp, in.acScreenNorm);
        __nv_out = src0;
        return __nv_out;
      }
      float t = max(0.0, eng.acTime - u.startTime);
      float g = max(u.grid, 2.0);
      float2 uvNow = in.acScreenNorm;

      // Base guess cell from current pixel
      float2 pxy = toPx(uvNow);
      float2 baseCid = floor(pxy / g);

      // Adaptive search radius in cells based on estimated displacement
      float texMax = max(__nv_getTexSize(inputImg_info.size).x, __nv_getTexSize(inputImg_info.size).y);
      float estDisp = (u.force / max(texMax, 1.0)) * t + 0.5 * abs(u.gravity / max(texMax, 1.0)) * t*t; // uv
      float cells = estDisp * (texMax / g); // approximate cells traveled
      int Rcap = int(clamp(u.searchMax, 1.0, 12.0));
      int R = int(clamp(ceil(cells) + 1.0, 1.0, float(Rcap))); // adaptive, capped by control

      float4 col = float4(0.0);
      bool found = false;
      float bestDepth = 1e9;
      for(int dy=-4; dy<=4 && !found; ++dy){
        if(dy < -R || dy > R) continue;
        for(int dx=-4; dx<=4 && !found; ++dx){
          if(dx < -R || dx > R) continue;
          float2 cidC = baseCid + float2(float(dx), float(dy));
          bool ok; float4 c = tryCandidate(cidC, t, g, uvNow, ok);
          if(ok){
            // choose shard with smallest depth (closest)
            if(c.a < bestDepth){ bestDepth = c.a; col = float4(c.rgb, 1.0); }
            found = true;
          }
        }
      }

      __nv_out = found ? col : float4(0.0);
    return __nv_out;
}
