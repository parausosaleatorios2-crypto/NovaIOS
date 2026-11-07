// ---------------------------------------------------------------------------
// Warped Grid
// origem : assets/effects/toji-warpgeid.xml
// id     : com.alightcreative.effects.warpedGrid
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_warpgeidParams {
    float gridSize;
    float rotationSpeed;
    float zoomSpeed;
    float warpAmount;
    float warpFrequency;
    float4 gridColor;
    float4 bgColor;
};

// --- funcoes auxiliares do efeito
// Helper function for 2D rotation
    float2x2 rotate2d(float angle){
        return float2x2(cos(angle), -sin(angle),
                    sin(angle), cos(angle));
    }

fragment float4 fx_toji_warpgeid(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_warpgeidParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        float2 uv = in.acLayerNorm;
        uv -= 0.5; // Center UVs to -0.5 to 0.5
        uv.x *= eng.acLayerSize.x / eng.acLayerSize.y; // Maintain aspect ratio

        float time = eng.acTime;

        // --- Rotozoom ---
        float zoom = exp(time * u.zoomSpeed); // Exponential zoom for smoother effect
        float angle = time * u.rotationSpeed;

        uv = rotate2d(angle) * uv; // Apply rotation
        uv *= zoom; // Apply zoom

        // --- Warp Effect (using sine waves) ---
        // This adds a subtle, wave-like distortion
        uv.x += sin(uv.y * u.warpFrequency + time * 0.5) * u.warpAmount;
        uv.y += cos(uv.x * u.warpFrequency - time * 0.3) * u.warpAmount;


        // --- Create the Grid ---
        // Take the fractional part of UVs multiplied by u.gridSize.
        // This creates a repeating pattern where each cell goes from 0 to 1.
        float2 grid = fract(uv * u.gridSize);

        // Calculate the thickness of the grid lines
        float lineWidth = 0.05; // 5% of the cell size

        // Check if the pixel is near the edge of a grid cell
        // We're looking for values close to 0 or 1 for both x and y.
        float lineX = step(1.0 - lineWidth, grid.x) + step(lineWidth, grid.x) * step(grid.x, lineWidth);
        float lineY = step(1.0 - lineWidth, grid.y) + step(lineWidth, grid.y) * step(grid.y, lineWidth);

        // Combine X and Y lines (if either is a line, it's a grid line)
        float isGridLine = min(lineX + lineY, 1.0); // Clamp to 1.0 for clean white lines

        // Interpolate between background and grid color
        float3 finalColor = mix(u.bgColor.rgb, u.gridColor.rgb, isGridLine);

        __nv_out = float4(finalColor, 1.0);
    return __nv_out;
}
