// ---------------------------------------------------------------------------
// Auto Paint
// origem : assets/effects/toji-paint_brush_stylizer.xml
// id     : com.alightcreative.effects.paint_brush_stylizer
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_paint_brush_stylizerParams {
    float frequency;
    float strokeLength;
    float jitter;
    float strokeWidth;
};

// --- funcoes auxiliares do efeito
// Random hash function
        float hash12(float2 p) {
            float3 p3  = fract(float3(p.xyx) * .1031);
            p3 += dot(p3, p3.yzx + 33.33);
            return fract((p3.x + p3.y) * p3.z);
        }

        // Sample texture
        float3 getSource(float2 uv) {
            return inputImg.sample(__nv_smp, uv).rgb;
        }

        // Get intensity/luma for gradient calculation
        float getGray(float3 c) {
            return dot(c, float3(0.299, 0.587, 0.114));
        }

fragment float4 fx_toji_paint_brush_stylizer(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_paint_brush_stylizerParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm;
            
            // 1. Grid setup
            // Scale UV by u.frequency to create a grid
            // Aspect correction ensures square grid cells
            float aspect = eng.acScreenSize.x / eng.acScreenSize.y;
            float2 scale = float2(u.frequency * aspect, u.frequency);
            float2 gridUV = uv * scale;
            float2 gridId = floor(gridUV);
            
            // 2. Accumulators for painting
            float3 pixelColor = getSource(uv); // Background base
            float bestPriority = -1.0;
            
            // 3. Neighbor Loop
            // Check neighboring cells to allow strokes to overlap
            for (float y = -2.0; y <= 2.0; y++) {
                for (float x = -2.0; x <= 2.0; x++) {
                    float2 neighbor = float2(x, y);
                    float2 id = gridId + neighbor;
                    
                    // Randomness Logic
                    // If u.jitter is on (>0.5), we change the seed over time.
                    float timeOffset = (u.jitter > 0.5) ? floor(eng.acTime * 12.0) : 0.0;
                    float2 seed = id + float2(timeOffset * 0.1, timeOffset * 1.618);
                    
                    // Random numbers for this stroke
                    float2 rand = float2(hash12(seed), hash12(seed + 4.13));
                    
                    // Stroke Center (jittered within its grid cell)
                    float2 centerGrid = neighbor + rand; 
                    
                    // Sample the source image at the stroke's center position
                    float2 centerUV = (id + rand) / scale;
                    
                    // Bounds check for UV sampling
                    if (centerUV.x < 0.0 || centerUV.x > 1.0 || centerUV.y < 0.0 || centerUV.y > 1.0) continue;
                    
                    float3 col = getSource(centerUV);
                    
                    // Compute Gradient / Orientation at stroke center
                    float2 eps = float2(2.0 / eng.acScreenSize.x, 2.0 / eng.acScreenSize.y);
                    float gC = getGray(col);
                    float gH = getGray(getSource(centerUV + float2(eps.x, 0.0)));
                    float gV = getGray(getSource(centerUV + float2(0.0, eps.y)));
                    float dX = gH - gC;
                    float dY = gV - gC;
                    
                    // Orientation: Perpendicular to gradient (tangent to edges)
                    float angle = __nv_atan(dY, dX) + 1.5708; // +90 degrees
                    
                    // Current pixel position relative to current cell grid (fractional part)
                    float2 p = fract(gridUV); 
                    // Vector from stroke center to current pixel
                    float2 delta = p - centerGrid;
                    
                    // Rotate delta to align with the stroke direction
                    float cs = cos(-angle);
                    float sn = sin(-angle);
                    float2 rotP = float2(delta.x * cs - delta.y * sn, delta.x * sn + delta.y * cs);
                    
                    // Stroke SDF (Capsule/Ellipse approximation)
                    float len = u.strokeLength * 0.8; 
                    float wid = u.strokeWidth * 0.3;
                    
                    // Distance to line segment
                    float dx = max(abs(rotP.x) - len, 0.0);
                    float dy = abs(rotP.y);
                    
                    // Elliptical distance approx
                    float dist = length(float2(dx, dy));
                    
                    // Create Mask (Alpha)
                    float mask = 1.0 - smoothstep(wid - 0.1, wid + 0.1, dist);
                    
                    // Texture the brush stroke
                    float brushNoise = hash12(rotP * 10.0 + seed);
                    mask *= 0.8 + 0.2 * brushNoise;
                    
                    // Compositing
                    if (mask > 0.01) {
                        float depth = rand.x; // Random depth 0..1
                        float priority = depth * mask; // Weight by opacity
                        
                        if (priority > bestPriority) {
                            bestPriority = priority;
                            pixelColor = col;
                            // Slight shading for depth perception
                            pixelColor *= 0.95 + 0.05 * mask;
                        }
                    }
                }
            }
            
            __nv_out = float4(pixelColor, 1.0);
    return __nv_out;
}
