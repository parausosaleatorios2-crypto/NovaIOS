// ---------------------------------------------------------------------------
// Turbulent Pro
// origem : assets/effects/toji-turbulent_displace.xml
// id     : com.alightcreative.effects.turbulent_displace
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_turbulent_displaceParams {
    float amount;
    float scale;
    float octaves;
    float lacunarity;
    float gain;
    float xStrength;
    float yStrength;
    float warpAmount;
    float evolution;
    float evolutionSpeed;
    float seed;
    int mode;
    int wrapMode;
    float alpha;
};

// --- funcoes auxiliares do efeito
// Utility random and value noise
        static float random(float2 st) {
            return fract(sin(dot(st.xy, float2(12.9898,78.233))) * 43758.5453123);
        }

        static float valueNoise(float2 st) {
            float2 i = floor(st);
            float2 f = fract(st);
            float a = random(i);
            float b = random(i + float2(1.0, 0.0));
            float c = random(i + float2(0.0, 1.0));
            float d = random(i + float2(1.0, 1.0));
            float2 u = f * f * (3.0 - 2.0 * f);
            return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
        }

        // Fractal Brownian Motion (FBM)
        static float fbm(float2 p, float oct, float lac, float g) {
            float sum = 0.0;
            float amp = 0.5;
            float freq = 1.0;
            for (float i = 0.0; i < 8.0; i += 1.0) {
                if (i >= oct) break;
                sum += amp * valueNoise(p * freq);
                freq *= lac;
                amp *= g;
            }
            return sum;
        }

        // Curl noise from fbm via finite differences
        static float2 curl(float2 p, float oct, float lac, float g) {
            float eps = 0.001;
            float n1 = fbm(p + float2(0.0, eps), oct, lac, g);
            float n2 = fbm(p - float2(0.0, eps), oct, lac, g);
            float n3 = fbm(p + float2(eps, 0.0), oct, lac, g);
            float n4 = fbm(p - float2(eps, 0.0), oct, lac, g);
            float dx = (n3 - n4) / (2.0 * eps);
            float dy = (n1 - n2) / (2.0 * eps);
            return float2(dy, -dx); // 2D curl
        }

        static float2 wrapUV(float2 uv) {
            if (u.wrapMode == 1) {
                // Repeat
                return fract(uv);
            } else if (u.wrapMode == 2) {
                // Mirror
                float2 wrapped = fract(uv);
                float2 mirror = step(0.5, fract(uv * 0.5));
                return mix(wrapped, 1.0 - wrapped, mirror);
            } else {
                // Clamp
                return clamp(uv, float2(0.0), float2(1.0));
            }
        }

fragment float4 fx_toji_turbulent_displace(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_turbulent_displaceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm.xy;

            // Time-evolved coordinate
            float t = u.evolution + eng.acTime * u.evolutionSpeed + u.seed * 0.1234;
            float2 baseP = uv * u.scale + float2(t);

            // Domain warp for richer structures
            float2 warpVec;
            float nA = fbm(baseP + float2(13.1, 7.3), u.octaves, u.lacunarity, u.gain);
            float nB = fbm(baseP + float2(-9.7, 2.6), u.octaves, u.lacunarity, u.gain);
            warpVec = float2(nA, nB) * u.warpAmount;

            float2 p = baseP + warpVec * 2.0;
            float2 disp;
            if (u.mode == 0) {
                // FBM vector displacement using two uncorrelated fields
                float nx = fbm(p + float2(5.2, 1.3), u.octaves, u.lacunarity, u.gain);
                float ny = fbm(p + float2(-3.1, 9.9), u.octaves, u.lacunarity, u.gain);
                disp = float2(nx, ny) - 0.5; // Center around 0
            } else {
                // Flow-like curl noise field
                disp = curl(p, u.octaves, u.lacunarity, u.gain);
                // Curl is already centered around 0
            }

            // Apply axis strength and u.amount
            float2 offset = disp * u.amount * float2(u.xStrength, u.yStrength);
            float2 sampleUV = wrapUV(uv + offset);

            float4 color = inputImg.sample(__nv_smp, sampleUV);
            color.a *= u.alpha;
            __nv_out = color;
    return __nv_out;
}
