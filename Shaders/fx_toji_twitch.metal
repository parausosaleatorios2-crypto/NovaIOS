// ---------------------------------------------------------------------------
// Twitch
// origem : assets/effects/toji-twitch.xml
// id     : com.alightcreative.effects.smartMotionBlurShake
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_twitchParams {
    float amplitude;
    float shakeInterval;
    float samples;
    float angle;
};

// --- funcoes auxiliares do efeito
float rand(float2 co) {
        return fract(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
    }

fragment float4 fx_toji_twitch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_twitchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        float2 uv = in.acScreenNorm;
        float t = floor(eng.acTime / u.shakeInterval);

        // Convert u.angle to radians and get direction
        float rad = radians(u.angle);
        float2 dir = float2(cos(rad), sin(rad));

        // Jitter magnitude (modulated by random)
        float jitter = (rand(float2(t, 0.0)) - 0.5) * 2.0;

        // Final shake offset vector
        float2 shakeVec = dir * jitter * u.amplitude;

        const int MAX_SAMPLES = 32;
        int N = int(clamp(float(u.samples), 1.0, float(MAX_SAMPLES)));

        float3 blurColor = float3(0.0);
        for (int i = 0; i < MAX_SAMPLES; i++) {
            if (i >= N) break;
            float factor = float(i) / float(N - 1);
            float2 sampleUV = uv + shakeVec * factor;
            sampleUV = clamp(sampleUV, 0.0, 1.0);
            blurColor += inputImg.sample(__nv_smp, sampleUV).rgb;
        }
        blurColor /= float(N);
        __nv_out = float4(blurColor, 1.0);
    return __nv_out;
}
