// ---------------------------------------------------------------------------
// Cosmic Nebula
// origem : assets/effects/toji-cosmic-nebula.xml
// id     : com.alightcreative.effects.cosmic_nebula
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_cosmic_nebulaParams {
    float SPEED;
    float4 COL1;
    float4 COL2;
    float4 COL3;
    float STAR_FLARE;
    float STARS_VERY_DIST;
    float STARS_DIST;
    float STARS_MED;
    float STARS_CLOSE;
    float GAMMA;
    float NOISE_OVERLAY;
};

// --- funcoes auxiliares do efeito
// Cosmic Nebula port

float hash(float2 p){
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise2d(float2 p){
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float3 nebula(float2 uv){
    float t = eng.acTime * u.SPEED;
    float3 col1 = u.COL1.rgb;
    float3 col2 = u.COL2.rgb;
    float3 col3 = u.COL3.rgb;

    float2 uv1 = uv * 2.0 + t;
    float2 uv2 = uv * 4.0 - t * 1.5;

    float n1 = noise2d(uv1);
    float n2 = noise2d(uv2);
    float finalNoise = n1 * 0.6 + n2 * 0.4;

    float3 color = mix(col1, col2, finalNoise);
    color = mix(color, col3, noise2d(uv * 3.0 + t * 0.7));
    return color;
}

float starCore(float2 uv, float flare, float depth){
    float d = max(abs(uv.x), abs(uv.y));
    float m = (0.02 * depth) / max(d, 1e-4);

    float rayScale = min(eng.acScreenSize.x, eng.acScreenSize.y) / 1000.0;
    float rayDensity = mix(200.0, 400.0, clamp(rayScale, 0.0, 1.0));

    float rays = max(0.0, 1.0 - abs(uv.x * uv.y * rayDensity));
    rays = smoothstep(0.0, 1.0, rays);
    m += rays * flare * depth * 1.5;
    return m;
}

fragment float4 fx_toji_cosmic_nebula(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_cosmic_nebulaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 R = eng.acScreenSize;
    float2 frag = in.acScreenNorm * R;
    float2 uv = (frag - 0.5 * R) / max(R.y, 1.0);

    float3 color = nebula(uv);

    float time = eng.acTime * 0.2;
    float timeSlowA = time * 0.02;
    float timeSlowB = time * 0.05;
    float timeSlowC = time * 0.1;
    float timeSlowD = time * 0.15;

    int vcnt = int(clamp(u.STARS_VERY_DIST, 0.0, 32.0));
    int dcnt = int(clamp(u.STARS_DIST, 0.0, 32.0));
    int mcnt = int(clamp(u.STARS_MED, 0.0, 32.0));
    int ccnt = int(clamp(u.STARS_CLOSE, 0.0, 32.0));
    float flare = u.STAR_FLARE;

    // Very distant tiny stars
    for (int i = 0; i < 32; i++){
        if (i >= vcnt) break;
        float ii = float(i) * 0.3;
        float2 starPos = float2(
            noise2d(float2(ii, timeSlowA)),
            noise2d(float2(ii + 42.0, timeSlowA))
        ) * 2.0 - 1.0;
        float depth = 0.1 + hash(float2(float(i) * 2.0, 0.0)) * 0.1;
        color += float3(0.6, 0.6, 0.7) * starCore(uv - starPos, 0.5 * flare, depth) * (0.2 + 0.2 * sin(time + float(i)));
    }

    // Distant stars
    for (int i = 0; i < 32; i++){
        if (i >= dcnt) break;
        float ii = float(i) * 0.5;
        float2 starPos = float2(
            noise2d(float2(ii, timeSlowB)),
            noise2d(float2(ii + 42.0, timeSlowB))
        ) * 2.0 - 1.0;
        float depth = 0.3 + hash(float2(float(i) * 2.0, 0.0)) * 0.2;
        color += float3(0.8, 0.7, 0.6) * starCore(uv - starPos, 0.8 * flare, depth) * (0.3 + 0.3 * sin(time + float(i)));
    }

    // Medium distance stars
    for (int i = 0; i < 32; i++){
        if (i >= mcnt) break;
        float ii = (float(i) + 5.0) * 0.7;
        float2 starPos = float2(
            noise2d(float2(ii, timeSlowC)),
            noise2d(float2(ii + 42.0, timeSlowC))
        ) * 2.0 - 1.0;
        float depth = 0.6 + hash(float2((float(i) + 5.0) * 2.0, 0.0)) * 0.2;
        color += float3(0.9, 0.8, 0.7) * starCore(uv - starPos, 1.0 * flare, depth) * (0.4 + 0.4 * sin(time + float(i)));
    }

    // Close stars
    for (int i = 0; i < 32; i++){
        if (i >= ccnt) break;
        float idx = float(i) + 8.0;
        float2 starPos = float2(
            noise2d(float2(idx, timeSlowD)),
            noise2d(float2(idx + 42.0, timeSlowD))
        ) * 2.0 - 1.0;
        float depth = 0.9 + hash(float2(idx * 2.0, 0.0)) * 0.2;
        color += float3(1.0, 0.9, 0.8) * starCore(uv - starPos, 1.2 * flare, depth) * (0.5 + 0.5 * sin(time + idx));
    }

    color += float3(hash(uv * 50.0 + time)) * u.NOISE_OVERLAY;

    color = pow(max(color, 0.0), float3(u.GAMMA));
    color = clamp(color, 0.0, 1.0);

    __nv_out = float4(color, 1.0);
    return __nv_out;
}
