// ---------------------------------------------------------------------------
// Heatmap
// origem : assets/effects/toji-heatmap_perlin_noise.xml
// id     : com.alightcreative.effects.heatmap_perlin_noise
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_heatmap_perlin_noiseParams {
    float globalFreq;
    float speed;
    float freqRed;
    float freqGreen;
    float freqBlue;
    float phaseRed;
    float phaseGreen;
    float phaseBlue;
    float saturation;
    float brightness;
    float blend;
};

// --- funcoes auxiliares do efeito
// Hash 3D pour le bruit de Perlin 3D
        static float3 hash33(float3 p) {
            p = float3(dot(p, float3(127.1, 311.7, 74.7)),
                     dot(p, float3(269.5, 183.3, 246.1)),
                     dot(p, float3(113.5, 271.9, 124.6)));
            return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
        }

        // Bruit de Perlin 3D propre
        static float perlinNoise3D(float3 p) {
            float3 pi = floor(p);
            float3 pf = p - pi;
            
            // Gradients aux 8 coins du cube
            float3 g000 = hash33(pi + float3(0.0, 0.0, 0.0));
            float3 g100 = hash33(pi + float3(1.0, 0.0, 0.0));
            float3 g010 = hash33(pi + float3(0.0, 1.0, 0.0));
            float3 g110 = hash33(pi + float3(1.0, 1.0, 0.0));
            float3 g001 = hash33(pi + float3(0.0, 0.0, 1.0));
            float3 g101 = hash33(pi + float3(1.0, 0.0, 1.0));
            float3 g011 = hash33(pi + float3(0.0, 1.0, 1.0));
            float3 g111 = hash33(pi + float3(1.0, 1.0, 1.0));
            
            // Produits scalaires
            float n000 = dot(g000, pf);
            float n100 = dot(g100, pf - float3(1.0, 0.0, 0.0));
            float n010 = dot(g010, pf - float3(0.0, 1.0, 0.0));
            float n110 = dot(g110, pf - float3(1.0, 1.0, 0.0));
            float n001 = dot(g001, pf - float3(0.0, 0.0, 1.0));
            float n101 = dot(g101, pf - float3(1.0, 0.0, 1.0));
            float n011 = dot(g011, pf - float3(0.0, 1.0, 1.0));
            float n111 = dot(g111, pf - float3(1.0, 1.0, 1.0));
            
            // Interpolation lisse
            float3 u = pf * pf * (3.0 - 2.0 * pf);
            
            // Interpolation trilinéaire
            float nx00 = mix(n000, n100, u.x);
            float nx10 = mix(n010, n110, u.x);
            float nx01 = mix(n001, n101, u.x);
            float nx11 = mix(n011, n111, u.x);
            
            float nxy0 = mix(nx00, nx10, u.y);
            float nxy1 = mix(nx01, nx11, u.y);
            
            return mix(nxy0, nxy1, u.z);
        }

        // FBm 3D avec animation temporelle intégrée
        static float fbm3D(float3 p, int octaves) {
            float value = 0.0;
            float amplitude = 0.8;
            float frequency = 0.13;
            
            for (int i = 0; i < 4; i++) { // Constrained loop for mobile compatibility
                if (i >= octaves) break;
                value += amplitude * perlinNoise3D(p * frequency);
                amplitude *= 0.5;
                frequency *= 2.0;
            }
            
            return value;
        }

fragment float4 fx_toji_heatmap_perlin_noise(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_heatmap_perlin_noiseParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 suv = in.acScreenNorm.xy;
            float2 uv = in.acLayerNorm.xy;
            
            // Aspect ratio correction
            float aspect = eng.acLayerSize.x / eng.acLayerSize.y;
            uv = (uv - 0.5) * 2.0;
            uv.x *= aspect;
            
            // Animation : la 3ème dimension est le temps
            float3 p = float3(uv * 3.0, eng.acTime * u.speed);
            
            // Bruit de Perlin 3D (espace 2D + temps)
            float noise = fbm3D(p, 4);
            
            // Normalisation 0..1
            noise = (noise + 1.0) * 0.5;
            
            // --- LOGIQUE DE COULEUR ---
            
            // Utilisation du bruit comme "wave"
            float wave = noise * 6.28318 * u.globalFreq;

            // Calcul des canaux RVB indépendants avec Sinus
            float rC = 0.5 + 0.5 * sin(wave * u.freqRed + u.phaseRed);
            float gC = 0.5 + 0.5 * sin(wave * u.freqGreen + u.phaseGreen);
            float bC = 0.5 + 0.5 * sin(wave * u.freqBlue + u.phaseBlue);
            
            float3 col = float3(rC, gC, bC);

            // Saturation
            float gray = dot(col, float3(0.299, 0.587, 0.114));
            col = mix(float3(gray), col, clamp(u.saturation, 0.0, 2.0));

            // Luminosité
            col *= u.brightness;
            
            float4 base = inputImg.sample(__nv_smp, suv);
            float4 effectCol = float4(col * base.a, base.a);

            __nv_out = mix(base, effectCol, u.blend);
    return __nv_out;
}
