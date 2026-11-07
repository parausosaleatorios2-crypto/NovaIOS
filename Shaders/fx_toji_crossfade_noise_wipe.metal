// ---------------------------------------------------------------------------
// Crossfade Noise Wipe
// origem : assets/effects/toji-crossfade_noise_wipe.xml
// id     : com.alightcreative.effects.crossfade_noise_wipe
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_crossfade_noise_wipeParams {
    float progress;
    float crossfadeLength;
    float textureZoom;
    int invert;
    float4 bgColor;
    float bgStrength;
};

// --- funcoes auxiliares do efeito
// Crossfade Noise Wipe (manual u.progress, no auto time)
        // Procedural version: single input and procedural noise

fragment float4 fx_toji_crossfade_noise_wipe(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_crossfade_noise_wipeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 res = eng.acScreenSize;
            float2 fragCoord = in.acScreenNorm * res;
            float2 uv = fragCoord / res;

            // Progress with crossfade window
            float pr = u.progress * (1.0 + u.crossfadeLength) - u.crossfadeLength;

            // Optionally u.invert
            if (u.invert) {
                pr = 1.0 - (u.progress * (1.0 + u.crossfadeLength) - u.crossfadeLength);
            }

            // Mask along X
            float mask = smoothstep(uv.x - u.crossfadeLength, uv.x, pr);

            // Procedural value noise (cheap hash-based)
            float n = fract(sin(dot(floor(uv * u.textureZoom * 1024.0), float2(12.9898,78.233))) * 43758.5453);
            float m = clamp(n * mask + mask, 0.0, 1.0);

            // Input and background color
            float3 a = inputImg.sample(__nv_smp, uv).rgb;
            float3 b = u.bgColor.rgb;

            float3 col = mix(a, b, m * u.bgStrength);
            __nv_out = float4(col, 1.0);
    return __nv_out;
}
