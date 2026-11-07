// ---------------------------------------------------------------------------
// Filters
// origem : assets/effects/toji-filters.xml
// id     : com.alightcreative.effects.advanced_filters
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_filtersParams {
    int filterMode;
    float intensity;
    float overlayStrength;
    float vhsMode;
    float bloomStrength;
    float vignette;
    float brightness;
    float contrast;
    float saturation;
    float blend;
};

// --- funcoes auxiliares do efeito
// Advanced CC Filters - Hand-crafted cinematic looks

        static float3 saturateCol(float3 col, float sat) {
            float grey = dot(col, float3(0.2126, 0.7152, 0.0722));
            return mix(float3(grey), col, sat);
        }

        static float3 applyContrast(float3 col, float con) {
            return (col - 0.5) * con + 0.5;
        }

        // --- Procedural Textures ---
        static float hash(float2 p) {
            return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
        }

        static float noise(float2 p) {
            float2 i = floor(p); float2 f = fract(p);
            f = f * f * (3.0 - 2.0 * f);
            return mix(mix(hash(i), hash(i + float2(1,0)), f.x),
                       mix(hash(i + float2(0,1)), hash(i + float2(1,1)), f.x), f.y);
        }

        static float getGrain(float2 uv, float t) {
            return hash(uv + t);
        }

        static float getScratches(float2 uv, float t) {
            float x = uv.x * 200.0;
            float r = hash(float2(floor(x), floor(t * 10.0)));
            if (r > 0.99) return smoothstep(0.1, 0.0, abs(fract(x) - 0.5));
            return 0.0;
        }

        static float getDust(float2 uv, float t) {
            float2 p = uv * 50.0;
            float n = noise(p + t * 5.0);
            return step(0.98, n) * hash(uv + t);
        }

        static float3 getLightLeaks(float2 uv, float t) {
            float2 p = uv + float2(t * 0.1, sin(t * 0.5) * 0.2);
            float n = noise(p * 2.0);
            float3 c1 = float4(1.0, 0.4, 0.2, 1.0).rgb * smoothstep(0.4, 0.8, n);
            float3 c2 = float4(0.2, 0.4, 1.0, 1.0).rgb * smoothstep(0.4, 0.8, noise(p * 3.0 + 10.0));
            return (c1 + c2) * 0.5;
        }

        static float3 applyBloom(float3 col, float str) {
            float luma = dot(col, float3(0.2126, 0.7152, 0.0722));
            float3 highlight = col * smoothstep(0.6, 1.0, luma);
            return col + highlight * str * 2.0;
        }

        static float3 applyVignette(float3 col, float2 uv, float str) {
            float d = distance(uv, float2(0.5));
            return col * smoothstep(0.8, 0.4 + (1.0 - str) * 0.4, d);
        }

        static float3 getGlitch(float2 uv, float t, float str) {
            float2 gUv = uv;
            float gNoise = hash(float2(floor(t * 10.0), floor(uv.y * 10.0)));
            if (gNoise > 0.98) gUv.x += (hash(float2(t)) - 0.5) * 0.05 * str;
            return inputImg.sample(__nv_smp, gUv).rgb;
        }

        static float getLensDirt(float2 uv, float t) {
            float dirt = noise(uv * 10.0 + t * 0.05);
            return smoothstep(0.7, 1.0, dirt) * 0.1;
        }

        static float3 applyLetterbox(float3 col, float2 uv, float str) {
            float mask = step(0.1 * str, uv.y) * step(uv.y, 1.0 - 0.1 * str);
            return col * mask;
        }

        static float getStatic(float2 uv, float t) {
            return hash(uv + t * 20.0);
        }

fragment float4 fx_toji_filters(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_filtersParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm;
            float t = eng.acTime;

            // Chromatic Aberration (RGB Split)
            float ca = u.vhsMode * 0.005;
            float4 srcR = inputImg.sample(__nv_smp, uv + float2(ca, 0));
            float4 srcG = inputImg.sample(__nv_smp, uv);
            float4 srcB = inputImg.sample(__nv_smp, uv - float2(ca, 0));
            float3 col = float3(srcR.r, srcG.g, srcB.b);
            float alpha = srcG.a;

            // VHS Jitter/Tracking
            if (u.vhsMode > 0.1) {
                float jitter = (hash(float2(t, uv.y)) - 0.5) * 0.01 * u.vhsMode;
                if (hash(float2(t * 0.5)) > 0.98) uv.x += jitter;
                col = inputImg.sample(__nv_smp, uv).rgb;
            }

            // --- Filter Algorithms ---
            float3 filterCol = col;

            if (u.filterMode == 0) { // Teal & Orange
                float luma = dot(col, float3(0.2126, 0.7152, 0.0722));
                filterCol.r = pow(col.r, 0.8) * 1.25;
                filterCol.g = col.g;
                filterCol.b = pow(col.b, 1.2) * 0.85;
                filterCol = mix(filterCol, float3(luma * 1.5, luma * 1.0, luma * 0.8), 0.15); // Tint
            } 
            else if (u.filterMode == 1) { // Moody Blue
                filterCol = col * float3(0.8, 0.9, 1.1);
                filterCol = applyContrast(filterCol, 1.2);
                filterCol = mix(filterCol, float3(dot(filterCol, float3(0.3, 0.59, 0.11))), 0.2); // Desaturate
            }
            else if (u.filterMode == 2) { // Autumn Gold
                filterCol = col * float3(1.15, 0.95, 0.8);
                filterCol.r = smoothstep(0.0, 1.0, filterCol.r * 1.1);
                filterCol.b = pow(filterCol.b, 1.3);
            }
            else if (u.filterMode == 3) { // Bleach Bypass
                float luma = dot(col, float3(0.2126, 0.7152, 0.0722));
                float3 overlay = (luma < 0.5) ? (2.0 * col * luma) : (1.0 - 2.0 * (1.0 - col) * (1.0 - luma));
                filterCol = mix(col, overlay, 0.6);
                filterCol = saturateCol(filterCol, 0.4);
            }
            else if (u.filterMode == 4) { // Urban Cyber
                filterCol = col * float3(1.1, 0.8, 1.2); // Magenta tint
                filterCol.r = pow(filterCol.r, 0.9);
                filterCol.b = pow(filterCol.b, 0.85);
                filterCol = applyContrast(filterCol, 1.1);
            }
            else if (u.filterMode == 5) { // Vintage 70s
                filterCol = col * float3(1.1, 1.05, 0.85);
                filterCol = mix(filterCol, float3(0.2, 0.15, 0.1), 0.1); // Faded blacks
                filterCol = saturateCol(filterCol, 0.8);
            }
            else if (u.filterMode == 6) { // Cold Winter
                filterCol = col * float3(0.9, 1.1, 1.25);
                filterCol += 0.05; // Brighten
                filterCol = applyContrast(filterCol, 0.95);
            }
            else if (u.filterMode == 7) { // Pastel Soft
                filterCol = pow(col, float3(0.8)); // Gamma up
                filterCol = saturateCol(filterCol, 1.1);
                filterCol = mix(filterCol, float3(1.0), 0.1); // Fog/Milk
            }
            else if (u.filterMode == 8) { // Dramatic B&W
                float luma = dot(col, float3(0.2126, 0.7152, 0.0722));
                filterCol = float3(pow(luma, 1.4) * 1.2);
                filterCol = applyContrast(filterCol, 1.3);
            }
            else if (u.filterMode == 9) { // Noir
                float luma = dot(col, float3(0.299, 0.587, 0.114));
                filterCol = float3(smoothstep(0.1, 0.9, luma));
                filterCol *= 0.9; // Lower max whites
            }
            else if (u.filterMode == 10) { // Sunset Glow
                filterCol = col * float3(1.3, 0.9, 0.7);
                filterCol.g = pow(filterCol.g, 1.1);
                filterCol.b = pow(filterCol.b, 1.4);
            }
            else if (u.filterMode == 11) { // Deep Forest
                filterCol = col * float3(0.9, 1.15, 0.95);
                filterCol.rb = pow(filterCol.rb, float2(1.2));
                filterCol = mix(filterCol, float3(0.0, 0.1, 0.05), 0.1);
            }
            else if (u.filterMode == 12) { // Polaroid
                filterCol = col * float3(1.0, 1.0, 0.9);
                filterCol = applyContrast(filterCol, 1.15);
                filterCol = mix(filterCol, float3(0.1, 0.1, 0.2), 0.1); // Blue shadows
                filterCol = saturateCol(filterCol, 0.9);
            }
            else if (u.filterMode == 13) { // Infrared
                float luma = dot(col, float3(0.21, 0.72, 0.07));
                filterCol = float3(luma * 1.2, luma * 0.5, luma * 0.9);
                filterCol.r = smoothstep(0.1, 0.9, filterCol.r);
            }
            else if (u.filterMode == 14) { // Kodak Gold
                filterCol = col * float3(1.1, 1.0, 0.8);
                filterCol = saturateCol(filterCol, 1.25);
                filterCol = applyContrast(filterCol, 1.1);
            }
            else if (u.filterMode == 15) { // Night Vision
                float luma = dot(col, float3(0.21, 0.72, 0.07));
                filterCol = float3(luma * 0.2, luma * 1.5, luma * 0.2);
            }
            else if (u.filterMode == 16) { // Sepia Modern
                float luma = dot(col, float3(0.21, 0.72, 0.07));
                filterCol = float3(luma) * float3(1.2, 1.0, 0.8);
                filterCol = applyContrast(filterCol, 1.1);
            }
            else if (u.filterMode == 17) { // Technicolor
                filterCol = pow(col, float3(0.8));
                filterCol = saturateCol(filterCol, 1.5);
                filterCol = applyContrast(filterCol, 1.2);
            }
            else if (u.filterMode == 18) { // Hollywood Gold
                filterCol = col * float3(1.15, 1.05, 0.9);
                filterCol = mix(filterCol, float3(1.0, 0.8, 0.5), 0.05);
            }
            else if (u.filterMode == 19) { // Lomo
                filterCol = applyContrast(col, 1.3);
                filterCol.r = pow(filterCol.r, 0.9);
                float luma = dot(col, float3(0.299, 0.587, 0.114));
                filterCol = float3(smoothstep(0.1, 0.9, luma));
                filterCol *= 0.9;
            }
            else if (u.filterMode == 20) { // 8mm Film
                filterCol = col * float3(1.1, 0.95, 0.8);
                filterCol = applyContrast(filterCol, 1.2);
                filterCol += getLightLeaks(uv, t) * 0.3;
            }
            else if (u.filterMode == 21) { // Bleach Bypass II
                float luma = dot(col, float3(0.2126, 0.7152, 0.0722));
                filterCol = mix(col, float3(luma), 0.7);
                filterCol = applyContrast(filterCol, 1.5);
            }
            else if (u.filterMode == 22) { // Cool Night Shift
                filterCol = col * float3(0.7, 0.85, 1.2);
                filterCol.r = pow(filterCol.r, 1.3);
            }
            else if (u.filterMode == 23) { // Warm Retro
                filterCol = col * float3(1.2, 1.1, 0.9);
                filterCol = mix(filterCol, float3(1.0, 0.9, 0.7), 0.1);
            }
            else if (u.filterMode == 24) { // Cyberpunk Red
                filterCol = col * float3(1.4, 0.5, 1.2);
                filterCol = applyContrast(filterCol, 1.2);
            }
            else if (u.filterMode == 25) { // Matrix
                filterCol = col * float3(0.5, 1.4, 0.5);
                filterCol = applyContrast(filterCol, 1.3);
            }
            else if (u.filterMode == 26) { // Washed Out
                filterCol = col * 0.8 + 0.2;
                filterCol = saturateCol(filterCol, 0.6);
            }
            else if (u.filterMode == 27) { // High Key
                filterCol = pow(col, float3(0.7)) * 1.1;
                filterCol = saturateCol(filterCol, 0.8);
            }
            else if (u.filterMode == 28) { // Low Key
                filterCol = pow(col, float3(1.8));
                filterCol = applyContrast(filterCol, 1.1);
            }
            else if (u.filterMode == 29) { // Dreamy Mist
                filterCol = applyBloom(col, 0.5);
                filterCol = saturateCol(filterCol, 1.1);
            }

            // --- Apply Overlays ---
            float grain = getGrain(uv, t) * 0.15;
            float scratches = getScratches(uv, t) * 0.5;
            float dust = getDust(uv, t) * 0.8;
            float scanline = sin(uv.y * 800.0) * 0.04;
            float3 leaks = getLightLeaks(uv, t) * 0.6;

            // Master Overlay Integration
            if (u.overlayStrength > 0.01) {
                // Mapping by Filter Personality - ALL 30 Filters covered
                bool isVintage = (u.filterMode == 5 || u.filterMode == 12 || u.filterMode == 14 || u.filterMode == 16 || u.filterMode == 17 || u.filterMode == 19 || u.filterMode == 20 || u.filterMode == 23 || u.filterMode == 26);
                bool isDigital = (u.filterMode == 4 || u.filterMode == 13 || u.filterMode == 15 || u.filterMode == 24 || u.filterMode == 25);
                bool isBright = (u.filterMode == 2 || u.filterMode == 6 || u.filterMode == 7 || u.filterMode == 10 || u.filterMode == 27 || u.filterMode == 29);
                bool isCinematic = (u.filterMode == 0 || u.filterMode == 1 || u.filterMode == 3 || u.filterMode == 8 || u.filterMode == 9 || u.filterMode == 11 || u.filterMode == 18 || u.filterMode == 21 || u.filterMode == 22 || u.filterMode == 28);

                if (isVintage) {
                    filterCol += (grain + scratches + dust) * u.overlayStrength;
                    filterCol += leaks * u.overlayStrength * 0.5;
                    filterCol *= 1.0 + (sin(t * 12.0) * 0.02 * u.overlayStrength); // Flicker
                }
                if (isDigital) {
                    filterCol -= scanline * u.overlayStrength;
                    filterCol += getStatic(uv, t) * 0.05 * u.overlayStrength;
                    if (hash(float2(t)) > 0.98) filterCol = getGlitch(uv, t, u.overlayStrength);
                }
                if (isBright) {
                    filterCol += getLensDirt(uv, t) * u.overlayStrength;
                    filterCol += leaks * 0.3 * u.overlayStrength;
                    filterCol = applyBloom(filterCol, 0.2 * u.overlayStrength);
                }
                if (isCinematic) {
                    filterCol = applyVignette(filterCol, uv, 0.6 * u.overlayStrength);
                    filterCol = applyLetterbox(filterCol, uv, 0.5 * u.overlayStrength);
                    filterCol += grain * 0.1 * u.overlayStrength;
                }
            }

            // Apply u.intensity
            col = mix(col, filterCol, u.intensity);

            // --- Global Adjustments ---
            col += u.brightness;
            col = applyContrast(col, u.contrast);
            col = saturateCol(col, u.saturation);
            
            // Pro Overlays
            col = applyBloom(col, u.bloomStrength);
            col = applyVignette(col, uv, u.vignette);

            __nv_out = float4(col, alpha) * u.blend + (1.0 - u.blend) * srcG;
    return __nv_out;
}
