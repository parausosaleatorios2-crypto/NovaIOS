// ---------------------------------------------------------------------------
// Pro Lens Flare
// origem : assets/effects/toji-pro_lens_flare.xml
// id     : com.alightcreative.effects.pro_lens_flare
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_pro_lens_flareParams {
    float posX;
    float posY;
    float intensity;
    float flareHue;
    float flareType;
    float glowSize;
    float ghostStr;
    float streakStr;
    float starburstStr;
};

// --- funcoes auxiliares do efeito
// Utility: Rotate Hue of a color
        float3 hueShift(float3 col, float shift) {
            float3 P = float3(0.55735) * dot(float3(0.55735), col);
            float3 U = col - P;
            float3 V = cross(float3(0.55735), U);
            col = U * cos(shift * 6.2832) + V * sin(shift * 6.2832) + P;
            return max(float3(0.0), col);
        }

        // Utility: Noise for pseudo-randomness
        float hash(float n) { return fract(sin(n) * 43758.5453123); }

        // Procedural Lens Flare
        float3 lensFlare(float2 uv, float2 pos) {
            float2 main = uv - pos;
            float dist = length(main);
            float ang = __nv_atan(main.y, main.x);
            
            float3 f = float3(0.0);
            
            // Base Palette
            float3 colCore = hueShift(float3(1.0, 0.9, 0.8), u.flareHue);
            float3 colStreak = hueShift(float3(0.8, 0.5, 0.2), u.flareHue);
            float3 colGhost = hueShift(float3(0.9, 0.8, 1.0), u.flareHue);
            
            // Determine Active Features based on Type
            int type = int(floor(u.flareType + 0.5));
            
            float activeStreak = 0.0;
            float activeStar = 0.0;
            float activeGhosts = 0.0;
            
            if (type == 0) {
                // Type 0: Clean Glow
                activeStreak = 0.0;
                activeStar = 0.0;
                activeGhosts = 0.0;
            } else if (type == 1) {
                // Type 1: Anamorphic
                activeStreak = 1.0;
                activeStar = 0.0;
                activeGhosts = 0.2;
            } else if (type == 2) {
                // Type 2: Starburst
                activeStreak = 0.0;
                activeStar = 1.0;
                activeGhosts = 0.1;
            } else {
                // Type 3: Sci-Fi / Complex
                activeStreak = 0.3;
                activeStar = 0.2;
                activeGhosts = 1.0;
            }
            
            // Combine with manual sliders
            float sStr = u.streakStr * activeStreak;
            float stStr = u.starburstStr * activeStar;
            float gStr = u.ghostStr * activeGhosts;

            // 1. SOFT CORE GLOW
            float core = 1.0 / (dist * (20.0 / u.glowSize) + 0.5);
            core = pow(core, 2.0);
            f += colCore * core * 2.0;
            
            // 2. STARBURST
            if (stStr > 0.01) {
                float rays = abs(cos(ang * 3.0)) * 0.5 + abs(cos(ang * 12.0)) * 0.2;
                rays += smoothstep(0.0, 1.0, abs(sin(ang * 100.0))) * 0.1;
                rays *= 0.2 / (dist + 0.1);
                f += colCore * rays * stStr;
            }

            // 3. ANAMORPHIC STREAK
            if (sStr > 0.01) {
                float vDist = abs(main.y);
                float streak = exp(-vDist * 40.0);
                streak *= smoothstep(1.5, 0.1, abs(main.x));
                f += colStreak * streak * sStr;
            }

            // 4. LENS GHOSTS
            if (gStr > 0.01) {
                float2 ghostVec = -pos * 0.5;
                for (float i = 0.0; i < 5.0; i++) {
                    float t = fract(i * 0.35 + 0.3);
                    float2 gPos = pos + ghostVec * (t * 4.0);
                    float size = 0.05 + 0.15 * hash(i * 12.3);
                    float chr = 0.02 * dist;
                    
                    float3 ghostCol = float3(0.0);
                    float d = length(uv - gPos);
                    
                    ghostCol.r = smoothstep(size + chr, size - 0.01 + chr, d);
                    ghostCol.g = smoothstep(size,       size - 0.01,       d);
                    ghostCol.b = smoothstep(size - chr, size - 0.01 - chr, d);
                    
                    float hollow = smoothstep(0.0, size * 0.8, d);
                    ghostCol *= 0.5 + 0.5 * hollow;
                    
                    float alpha = 0.1 * gStr * (1.0 - t * 0.5);
                    f += ghostCol * alpha * colGhost;
                }
            }

            return f * u.intensity;
        }

fragment float4 fx_toji_pro_lens_flare(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_pro_lens_flareParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm;
            float2 aspectVec = float2(eng.acLayerSize.x / eng.acLayerSize.y, 1.0);
            
            // Center UVs
            float2 cUV = (uv - 0.5) * aspectVec;
            
            // Light position
            float2 lightPos = (float2(u.posX, 1.0 - u.posY) - 0.5) * aspectVec;

            // Background
            float3 col = inputImg.sample(__nv_smp, uv).rgb;
            
            // Add Flare
            float3 flare = lensFlare(cUV, lightPos);
            col += flare;

            // Tone Mapping (ACES-like)
            col = col * 0.8;
            const float a = 2.51;
            const float b = 0.03;
            const float c = 2.43;
            const float d = 0.59;
            const float e = 0.14;
            col = clamp((col*(a*col+b))/(col*(c*col+d)+e), 0.0, 1.0);
            
            // Gamma
            col = pow(col, float3(1.0/2.2));

            __nv_out = float4(col, 1.0);
    return __nv_out;
}
