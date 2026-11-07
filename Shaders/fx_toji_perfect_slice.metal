// ---------------------------------------------------------------------------
// Perfect Slice
// origem : assets/effects/toji-perfect_slice.xml
// id     : com.alightcreative.effects.perfect_slice
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_perfect_sliceParams {
    float progress;
    float sliceCount;
    float sliceRadius;
    float explosionSpeed;
    float glowIntensity;
    float4 glowColor;
    int flashEnabled;
    float seed;
};

// --- funcoes auxiliares do efeito
#define PI 3.14159265359
    
    // --- Helper Functions ---
    static float hash(float n) { 
        return fract(sin(n) * 43758.5453123); 
    }
    
    // Rotation Matrix
    static float2x2 rot(float a) {
        float s = sin(a), c = cos(a);
        return float2x2(c, -s, s, c);
    }
    
    // Struct to hold Shard Data
    struct ShardInfo {
        float id;       // Unique ID for the shard
        float2 moveDir;   // Direction this shard will fly
        float distToCut;// Distance to the nearest cut line (for glow)
    };
    
    // CORE FUNCTION: Defines the geometry of the cuts
    // This is used for both drawing the lines AND calculating physics.
    static ShardInfo getShardInfo(float2 p, float numCuts, float cutRadius) {
        float id = 0.0;
        float2 moveAcc = float2(0.0);
        float minDist = 100.0;
        
        int NUM_CUTS = int(numCuts);
        
        for(int i = 0; i < 30; i++) {
            if(i >= NUM_CUTS) break;
            
            float fi = float(i);
            
            // Randomize Cut Geometry based on fixed u.seed
            float h1 = hash(fi + u.seed);
            float h2 = hash(fi + u.seed * 5.0 + 99.0);
            
            float angle = h1 * PI * 2.0;
            float2 n = float2(cos(angle), sin(angle));
            float off = (h2 - 0.5) * cutRadius; // Radius control
            
            // Distance from point p to the line
            float d = dot(p, n) - off;
            
            // Track closest cut for visual glow
            minDist = min(minDist, abs(d));
            
            // Determine side (Physics)
            float side = sign(d);
            
            // Accumulate ID (Binary composition)
            // If we are on positive side, add value. 
            if(side > 0.0) {
                id += pow(1.5, fi); // Use 1.5 to create unique float ID
            }
            
            // Accumulate Movement Direction
            // The shard moves away from the cut plane
            moveAcc += n * side;
        }
        
        // Randomize movement slightly per ID so they don't slide uniformly
        float2 randomDir = float2(hash(id) - 0.5, hash(id + 1.0) - 0.5);
        moveAcc += randomDir * 1.5;
        
        return ShardInfo(id, normalize(moveAcc), minDist);
    }
    
    // Function to visualize the swipe animation of the sword
    static float drawSwipe(float2 p, float2 n, float off, float t, float hashSeed) {
        float2 tangent = float2(-n.y, n.x);
        float posAlongLine = dot(p, tangent);
        float dir = step(0.5, hash(hashSeed)) * 2.0 - 1.0; 
        float swipe = (t * 12.0 - 6.0) * dir;
        return smoothstep(-0.2, 0.2, (swipe - posAlongLine) * dir);
    }

fragment float4 fx_toji_perfect_slice(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_perfect_sliceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        // --- 1. Setup ---
        float2 texSize = __nv_getTexSize(inputImg_info.size);
        float2 uv = in.acScreenNorm;
        
        // Aspect-corrected space for physics
        float2 p = (in.acScreenNorm - 0.5) * float2(texSize.x / texSize.y, 1.0);
        
        // Time control based on u.progress
        float t = u.progress * 4.0; // 0 to 4 seconds range
        float slashEnd = 1.2;
        float explodeStart = 1.4;
        
        // Early exit - show original image
        if (u.progress <= 0.001) {
            __nv_out = inputImg.sample(__nv_smp, uv);
            return __nv_out;
        }
        
        // Explosion Physics
        float force = 0.0;
        if(t > explodeStart) {
            float et = t - explodeStart;
            // Acceleration: t^2 for violent explosion
            force = et * et * u.explosionSpeed + et * 0.2; 
        }
        
        int NUM_CUTS = int(u.sliceCount);
        
        // --- 2. Calculate Destination Pixel Info ---
        // Who is occupying the current pixel on screen?
        ShardInfo destInfo = getShardInfo(p, u.sliceCount, u.sliceRadius);
        
        // --- 3. Inverse Mapping (Trace Back) ---
        // If the shard moved by (dir * force), then the texture pixel 
        // we want to see is at (p - dir * force).
        
        // Apply Z-depth zoom effect (scaling)
        // Randomize scale per shard
        float zScale = 1.0;
        if(force > 0.0) {
             zScale = 1.0 + (hash(destInfo.id) - 0.5) * force;
             zScale = max(0.1, zScale); // Safety
        }
        
        float2 offset = destInfo.moveDir * force;
        
        // Calculate the coordinate where this pixel CAME FROM
        float2 srcP = (p - offset) / zScale;
        
        // --- 4. Verify Integrity (The Void Check) ---
        // Critical Step: Check if the source pixel actually belongs to the same shard.
        // If we trace back and land in a different shard's territory, it means
        // there is a gap (void) here.
        
        ShardInfo srcInfo = getShardInfo(srcP, u.sliceCount, u.sliceRadius);
        
        // Tolerance for float comparison
        bool isSameShard = abs(destInfo.id - srcInfo.id) < 0.1;
        
        // --- 5. Render Texture ---
        float3 col = float3(0.0);
        float alpha = 0.0;
        
        // Only draw image if:
        // a. We are on the same shard (no gap)
        // b. We are within the texture bounds
        if (isSameShard) {
            // Convert srcP (centered aspect coords) back to UV (0-1)
            float2 srcUV = srcP / float2(texSize.x / texSize.y, 1.0) + 0.5;
            
            if(srcUV.x >= 0.0 && srcUV.x <= 1.0 && srcUV.y >= 0.0 && srcUV.y <= 1.0) {
                float4 texCol = inputImg.sample(__nv_smp, srcUV);
                col = texCol.rgb;
                alpha = texCol.a;
                if(force > 0.0) {
                    float dim = 1.0 / (1.0 + force * 0.5);
                    float glint = sin(force * 5.0 + hash(destInfo.id)*10.0) * 0.5 + 0.5;
                    col *= dim * (0.8 + 0.4*glint);
                }
            }
        }
        
        // --- 6. Draw Glowing Cut Lines ---
        // We draw these ON TOP of everything, but only before/during the start of explosion
        if (t < explodeStart + 0.5) {
            float accumulatedGlow = 0.0;
            
            // Re-run loop just for the visual lines so we can animate them sequentially
            for(int i = 0; i < 30; i++) {
                if(i >= NUM_CUTS) break;
                
                float fi = float(i);
                // Re-calc specific cut geometry
                float h1 = hash(fi + u.seed);
                float h2 = hash(fi + u.seed * 5.0 + 99.0);
                float angle = h1 * PI * 2.0;
                float2 n = float2(cos(angle), sin(angle));
                float off = (h2 - 0.5) * u.sliceRadius;
                
                float d = abs(dot(p, n) - off);
                
                // Timing
                float myStart = (fi / float(NUM_CUTS)) * slashEnd;
                if(t > myStart) {
                    float locT = t - myStart;
                    
                    // Line width
                    float line = 0.0015 / (d + 0.0001);
                    
                    // Swipe mask
                    float swipe = drawSwipe(p, n, off, locT, h1);
                    
                    // Fade out
                    float fade = exp(-locT * 4.0);
                    
                    accumulatedGlow += line * swipe * fade * 2.0;
                }
            }
            
            col += u.glowColor.rgb * accumulatedGlow * u.glowIntensity;
            alpha = max(alpha, accumulatedGlow * u.glowIntensity);
        }
        
        // --- 7. Impact Flash ---
        // White flash when explosion triggers
        float flash = smoothstep(explodeStart, explodeStart + 0.05, t) * 
                      (1.0 - smoothstep(explodeStart + 0.05, explodeStart + 0.4, t));
        if (u.flashEnabled) {
            col += float3(1.0) * flash;
            alpha = max(alpha, flash);
        }

        __nv_out = float4(col, alpha);
    return __nv_out;
}
