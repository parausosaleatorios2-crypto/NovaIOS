// ---------------------------------------------------------------------------
// Wobble Rail Streaks
// origem : assets/effects/toji-wobble-rail-streaks.xml
// id     : com.alightcreative.effects.wobble_rail_streaks
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_wobble_rail_streaksParams {
    float SPEED;
    float UV_SCALE;
    float STEPS;
    float DENOM_BIAS;
    float GAIN;
    float WOBBLE_FREQ;
    float WOBBLE_AMP;
    float PULL_MIN;
    float PULL_ADD;
    float DOT_MIN;
    float DOT_ADD;
    float PAT_MIN;
    float PAT_ADD;
    float PAT_BASE;
    float PAT_GAIN;
    float THRESH_1;
    float THRESH_2;
    float BRIGHT_1;
    float BRIGHT_2;
    float SHADOW_DECAY;
    float SHADOW_GAIN;
    float R_MIN;
    float R_ADD;
    float G_MIN;
    float G_ADD;
    float B_MIN;
    float B_ADD;
    float GAMMA;
};

// --- funcoes auxiliares do efeito
// Wobble Rail Streaks - AM single pass, GLES-safe

static float rand21(float2 c){ return fract(sin(dot(c, float2(12.9898,78.233))) * 43758.5453); }

fragment float4 fx_toji_wobble_rail_streaks(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_wobble_rail_streaksParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 R = eng.acScreenSize;
    float2 frag = in.acScreenNorm * R;
    float2 p = (2.0 * frag - R) / min(R.x, R.y) * u.UV_SCALE;

    float z0 = eng.acTime * u.SPEED;
    float i = floor(z0);
    float offs = fract(z0);
    float shadow = 1.0;

    float3 outc = float3(0.0);

    int maxSteps = int(clamp(u.STEPS, 1.0, 300.0));
    const int MAX_IT = 300;
    for (int zi = 1; zi < MAX_IT; zi++){
        if (zi >= maxSteps) break;
        float z = float(zi);
        float z2 = z - offs;
        float randz = z + i;

        float dadt = (rand21(float2(randz, 1.0)) * 2.0 - 1.0) * 0.5;
        float a = rand21(float2(randz, 1.0)) * 2.0 * 3.14159265 + dadt * eng.acTime;
        float pullback = rand21(float2(randz, 3.0)) * u.PULL_ADD + u.PULL_MIN;
        float r = rand21(float2(randz, 4.0)) * u.R_ADD + u.R_MIN;
        float g = rand21(float2(randz, 5.0)) * u.G_ADD + u.G_MIN;
        float b = rand21(float2(randz, 6.0)) * u.B_ADD + u.B_MIN;

        float2 origin = float2(sin(randz*0.005)+sin(randz*0.002), cos(randz*0.005)+cos(randz*0.002)) * z2 * 0.002;
        float2 dir = float2(cos(a), sin(a));
        float dist = dot(dir, p - origin) * z2;
        float xdist = dot(float2(-dir.y, dir.x), p - origin) * z2;
        float wobble = dist - pullback + sin(xdist * u.WOBBLE_FREQ) * u.WOBBLE_AMP;

        if (wobble > 0.0){
            float dotsize = rand21(float2(randz, 7.0)) * u.DOT_ADD + u.DOT_MIN;
            float patternsize = rand21(float2(randz, 8.0)) * u.PAT_ADD + u.PAT_MIN;
            float pattern = step(dotsize, length(fract(float2(dist, xdist) * patternsize) - 0.5)) * u.PAT_GAIN + u.PAT_BASE;

            float bright = 1.0;
            if (wobble < u.THRESH_1) bright = u.BRIGHT_1;
            else if (wobble < u.THRESH_2) bright = u.BRIGHT_2;
            else bright = pattern;

            float3 col = float3(r, g, b);
            float3 cacc = u.GAIN * col * shadow / (z2 + u.DENOM_BIAS) * bright;
            outc = cacc;
            outc = pow(max(outc, 0.0), float3(u.GAMMA));
            __nv_out = float4(outc, 1.0);
            return __nv_out;
        } else {
            shadow *= 1.0 - exp((dist - pullback) * u.SHADOW_DECAY) * u.SHADOW_GAIN;
        }
    }

    __nv_out = float4(0.0, 0.0, 0.0, 1.0);
    return __nv_out;
}
