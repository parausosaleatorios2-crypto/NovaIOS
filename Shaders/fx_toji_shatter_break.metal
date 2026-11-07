// ---------------------------------------------------------------------------
// Shatter Break
// origem : assets/effects/toji-shatter_break.xml
// id     : com.alightcreative.effects.shatter_break
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_shatter_breakParams {
    float progress;
    int style;
    float grid;
    float2 origin;
    float strength;
    float gravity;
    float rotation;
    float3 sceneRotation;
    float randomness;
    float seed;
};

// --- funcoes auxiliares do efeito
// Hash function
    float hash(float2 p) {
        float3 p3  = fract(float3(p.xyx) * .1031);
        p3 += dot(p3, p3.yzx + 33.33);
        return fract((p3.x + p3.y) * p3.z);
    }
    
    float2x2 rot2(float a){ float s = sin(a), c = cos(a); return float2x2(c,-s,s,c); }
    
    // 3D Rotations
    float3x3 rotX(float a) { float c=cos(a), s=sin(a); return float3x3(1,0,0, 0,c,-s, 0,s,c); }
    float3x3 rotY(float a) { float c=cos(a), s=sin(a); return float3x3(c,0,s, 0,1,0, -s,0,c); }
    float3x3 rotZ(float a) { float c=cos(a), s=sin(a); return float3x3(c,-s,0, s,c,0, 0,0,1); }
    
    float3x3 transpose3(float3x3 m) {
        return float3x3(
            m[0][0], m[1][0], m[2][0],
            m[0][1], m[1][1], m[2][1],
            m[0][2], m[1][2], m[2][2]
        );
    }
    
    float3x3 getRot3D(float3 r) {
        float3 rad = radians(r);
        return rotY(rad.y) * rotX(rad.x) * rotZ(rad.z);
    }

    // Ray intersections
    float iSphere(float3 ro, float3 rd, float r) {
        float b = dot(ro, rd);
        float c = dot(ro, ro) - r*r;
        float h = b*b - c;
        if(h < 0.0) return -1.0;
        return -b - sqrt(h);
    }

    float2 iBox(float3 ro, float3 rd, float3 boxSize, out float3 outNormal) {
        float3 m = 1.0 / rd;
        float3 n = m * ro;
        float3 k = abs(m) * boxSize;
        float3 t1 = -n - k;
        float3 t2 = -n + k;
        float tN = max(max(t1.x, t1.y), t1.z);
        float tF = min(min(t2.x, t2.y), t2.z);
        if(tN > tF || tF < 0.0) return float2(-1.0);
        outNormal = -sign(rd) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
        return float2(tN, tF);
    }

    // Physics parameters for a piece
    struct Shard {
        float2 disp;
        float rot;
        float2 pivot;
        float depth;
        float scale;
        float3x3 rot3d; // Rotation for the piece itself
        float2 uvOffset; // Jitter for sampling
    };
    
    // Generate shard physics
    // cid: Cell ID
    // k: Sub-piece index (0 or 1)
    Shard getShard(float2 cid, int k, float t, float g) {
        Shard S;
        
        float2 cellCenter = (cid + 0.5) * g;
        
        // Random u.seed unique to this piece
        float rnd = hash(cid + float2(float(k)*1.23, float(u.seed)));
        S.uvOffset = float2(hash(cid + rnd), hash(cid - rnd)) - 0.5; // Jitter for sampling
        
        // Pivot point
        S.pivot = cellCenter / eng.acScreenSize; // UV space pivot
        
        // Explosion Direction
        float2 centerPx = u.origin * eng.acScreenSize;
        float2 dir = cellCenter - centerPx;
        float d = length(dir);
        float2 normDir = dir / max(d, 1.0);
        
        // Randomize direction
        float angleVar = (rnd - 0.5) * u.randomness * 2.0; 
        normDir = rot2(angleVar) * normDir;
        
        // Force calculation
        float forceMag = u.strength * 500.0 * (1.0 + (rnd - 0.5) * u.randomness);
        
        float2 vel = normDir * forceMag;
        float2 grav = float2(0.0, -u.gravity * 1000.0);
        
        // Physics equation
        float time = t * 2.0;
        
        S.disp = (vel * time + 0.5 * grav * time * time) / eng.acScreenSize; // Convert px displacement to UV
        
        // Rotation
        S.rot = radians(u.rotation) * time * (rnd - 0.5) * 2.0;
        
        // Depth/Scale (2D fallback and 3D Z-displacement)
        float bZ = (u.style == 5) ? -3.0 : 1.0; // Window breaks forward (negative Z)
        S.depth = time * (rnd + 0.5) * bZ;
        S.scale = 1.0 / (1.0 + max(S.depth, -0.9) * 0.5);
        
        // 3D Scene Rotation + Shard Rotation
        float3 worldRot = float3(0.0, 0.0, degrees(S.rot)) + u.sceneRotation;
        S.rot3d = getRot3D(worldRot);
        
        return S;
    }
    
    // Inverse check
    // Returns color if uv0 maps to this piece
    float4 checkPiece(float2 cidC, int k, float t, float g, float2 uvNow, out bool found, out float dOut) {
        Shard S = getShard(cidC, k, t, g);
        float aspect = eng.acScreenSize.x / eng.acScreenSize.y;
        
        if (u.style <= 1 || u.style == 5) {
            // 2D Logic (Blocks, Glass, or Window)
            float2 uv0 = uvNow - S.disp;
            float2 pRel = uv0 - S.pivot;
            pRel.x *= aspect;
            pRel /= S.scale;
            pRel = rot2(-S.rot) * pRel;
            pRel.x /= aspect;
            uv0 = pRel + S.pivot;
            
            float2 px0 = uv0 * eng.acScreenSize;
            float2 cid0 = floor(px0 / g);
            float2 q = fract(px0 / g);
            
            bool matchCell = length(cid0 - cidC) < 0.1;
            // Shard shape: u.style 1 and 5 use triangle split (Glass)
            bool isGlass = (u.style == 1 || u.style == 5);
            bool insideShape = (!isGlass) ? true : ((k == 0) ? (q.x + q.y < 1.0) : (q.x + q.y >= 1.0));
            
            found = matchCell && insideShape;
            if (found) {
                float4 col = inputImg.sample(__nv_smp, clamp(uv0, 0.0, 1.0));
                if (col.a < 0.01) { found = false; return float4(0.0); }
                dOut = S.depth;
                return col;
            }
            return float4(0.0);
        } else {
            // 3D Logic
            // Ray setup
            // Camera at Z = -1.0, looking at Z = 0.0
            // Shards are centered at Z = 0 + S.depth
            float3 ro = float3((uvNow - S.pivot), -1.0);
            ro.x *= aspect;
            ro.xy -= S.disp * float2(aspect, 1.0);
            ro.z -= S.depth; // Shift ray u.origin relative to relocated shard
            
            float3 rd = normalize(float3(0.0, 0.0, 1.0)); // Orthographic or weak perspective?
            // Let's do simple orthographic ray for "flat" logic but with 3D volume
            // Transform ro/rd into shard local space
            float3x3 invRot = transpose3(S.rot3d);
            float3 roL = invRot * ro;
            float3 rdL = invRot * rd;
            
            float dHit = -1.0;
            float3 normal = float3(0.0, 0.0, -1.0);
            float shardSize = (g / eng.acScreenSize.y) * 0.5; // Half size in relative units
            
            if (u.style == 2 || u.style == 4) {
                // Cube or Thick Glass
                float zThick = (u.style == 4) ? shardSize * 0.2 : shardSize;
                float3 bSize = (u.style == 4) ? float3(shardSize, shardSize, zThick) : float3(shardSize);
                float2 res = iBox(roL, rdL, bSize, normal);
                if (res.x > 0.0) dHit = res.x;
            } else if (u.style == 3) {
                // Sphere
                dHit = iSphere(roL, rdL, shardSize);
                normal = normalize(roL + rdL * dHit);
            }
            
            if (dHit > 0.0) {
                float3 pHit = roL + rdL * dHit;
                float3 worldNormal = S.rot3d * normal;
                
                // Texture sampling UV (Projected from front face)
                float2 uv0 = (pHit.xy / (shardSize * 2.0)) + 0.5;
                
                // Add jitter/offset from shard u.origin
                float2 sampleUV = S.pivot + (uv0 - 0.5) * (g / eng.acScreenSize);
                
                float4 col = inputImg.sample(__nv_smp, clamp(sampleUV, 0.0, 1.0));
                if (col.a < 0.01) { found = false; return float4(0.0); }
                
                // Lighting
                float3 lightDir = normalize(float3(0.5, 0.5, -1.0));
                float diff = max(dot(worldNormal, lightDir), 0.0);
                float ambient = 0.4;
                col.rgb *= (ambient + (1.0 - ambient) * diff);
                
                found = true;
                dOut = S.depth + dHit * 0.1; // Return local depth
                return col;
            }
        }
        
        found = false;
        return float4(0.0);
    }

fragment float4 fx_toji_shatter_break(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_shatter_breakParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        if (u.progress <= 0.001) {
             __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
             return __nv_out;
        }
    
        float2 uv = in.acScreenNorm;
        float g = max(u.grid, 5.0);
        
        float2 px = uv * eng.acScreenSize;
        float2 baseCid = floor(px / g);
        
        float t = u.progress; 
        
        // Search Radius
        // As pieces fly further, we need to search wider.
        // Adaptive: proportional to u.strength * t
        // Cap it reasonable to preserve perf.
        int R = int(min(2.0 + u.strength * t * 20.0, 10.0));
        
        float4 bestCol = float4(0.0);
        float minDepth = 10000.0;
        bool hit = false;
        
        // Store winner parameters to re-sample with correct alpha
        float2 winnerCid = float2(0.0);
        int winnerK = 0;
        
        // Sub-piece count
        int kMax = (u.style == 1 || u.style == 5) ? 2 : 1; 

        for (int y = -R; y <= R; y++) {
            for (int x = -R; x <= R; x++) {
                 float2 cidC = baseCid + float2(float(x), float(y));
                 
                 for (int k = 0; k < kMax; k++) {
                     bool found;
                     float dHit;
                     float4 res = checkPiece(cidC, k, t, g, uv, found, dHit);
                     if (found) {
                         if (dHit < minDepth) {
                             minDepth = dHit;
                             hit = true;
                             bestCol = res;
                         }
                     }
                 }
            }
        }
        
        if (hit) {
            __nv_out = bestCol;
        } else {
            __nv_out = float4(0.0);
        }
    return __nv_out;
}
