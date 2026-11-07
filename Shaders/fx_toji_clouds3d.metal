// ---------------------------------------------------------------------------
// 3D Volumetric Clouds
// origem : assets/effects/toji-clouds3d.xml
// id     : com.alightcreative.effects.clouds3d
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_clouds3dParams {
    int nmode;
    float camprog;
    float camx;
    float camy;
    float progressa;
    float CLOUD_HEIGHT;
    float CLOUD_DENSITY;
    float CLOUD_FREQ;
    float4 CLOUD_BASE;
    float4 CLOUD_COLOR;
    float4 CSKY;
    float4 SKYCOLOR;
    float NUM_STEPS;
    float ITER_FRAGMENT;
    float scale;
    float progressc;
    float alpha;
    int adaptive;
};

// --- funcoes auxiliares do efeito
// Adapted from https://www.shadertoy.com/view/4sXGRM
    // Uses AfterMotion seascape-style parameters and conventions only

    #define fragCoord __nv_fragCoord.xy

    static float hash(float n) { return fract(cos(n) * 114514.1919); }
    static float noise(in float3 x) {
        float3 p = floor(x);
        float3 f = smoothstep(0.0, 1.0, fract(x));
        float n = p.x + p.y * 10.0 + p.z * 100.0;
        return mix(
            mix(mix(hash(n + 0.0), hash(n + 1.0), f.x), mix(hash(n + 10.0), hash(n + 11.0), f.x), f.y),
            mix(mix(hash(n + 100.0), hash(n + 101.0), f.x), mix(hash(n + 110.0), hash(n + 111.0), f.x), f.y), f.z);
    }
    static float fbm(float3 p) {
        float f = 0.5000 * noise(p);
        p = float3x3(0.00, 1.60, 1.20, -1.60, 0.72, -0.96, -1.20, -0.96, 1.28) * p;
        f += 0.2500 * noise(p);
        p = float3x3(0.00, 1.60, 1.20, -1.60, 0.72, -0.96, -1.20, -0.96, 1.28) * p;
        f += 0.1666 * noise(p);
        p = float3x3(0.00, 1.60, 1.20, -1.60, 0.72, -0.96, -1.20, -0.96, 1.28) * p;
        f += 0.0834 * noise(p);
        return f;
    }

fragment float4 fx_toji_clouds3d(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_clouds3dParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xcipher [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        // AfterMotion patch: use in.acScreenNorm and eng.acScreenSize for coordinates
        float2 uv = in.acScreenNorm * 2.0 - 1.0;
        uv.x *= eng.acScreenSize.x / eng.acScreenSize.y;
        float t = (u.progressa + 13.5 + 44.) * 1.0;
        float3 campos = float3(5000.0 * sin(1.0 * t + u.camx), 5000. + 1500. * sin(0.5 * t + u.camy), 6000.0 * t + u.camprog);
        float3 camtar = float3(5000.0 * sin(1.0 * (t + 0.4) + u.camx), 5000. + 1500. * sin(0.5 * (t + 0.4) + u.camy), 6000.0 * (t + 0.4) + u.camprog);
        float3 front = normalize(camtar - campos);
        float3 right = normalize(cross(front, float3(0.0, 1.0, 0.0)));
        float3 up = normalize(cross(right, front));
        float3 fragAt = normalize(uv.x * right + uv.y * up + front);
        float4 sum = float4(0, 0, 0, 0);
        for (float depth = 0.0; depth < 100000.0; depth += 200.0) {
            float3 ray = campos + fragAt * depth;
            if (0.0 < ray.y && ray.y < 10000.0) {
                float a = smoothstep(0.5, 1.0, fbm(ray * 0.00025 * u.CLOUD_DENSITY));
                float3 localcolor = mix(float3(1.1, 1.05, 1.0), float3(0.3, 0.3, 0.2), a);
                a = (1.0 - sum.a) * a;
                sum += float4(localcolor * a, a);
            }
        }
        float a = smoothstep(0.7, 1.0, sum.a);
        sum.rgb /= sum.a + 0.0001;
        float sundot = clamp(dot(fragAt, normalize(float3(0.1, 0.25, 0.9))), 0.0, 1.0);
        float3 col = 0.8 * (u.SKYCOLOR.rgb);
        col += 0.47 * float3(1.6, 1.4, 1.0) * pow(sundot, 350.0);
        col += 0.4 * float3(0.8, 0.9, 1.0) * pow(sundot, 2.0);
        sum.rgb -= 0.6 * float3(0.8, 0.75, 0.7) * pow(sundot, 13.0) * a;
        sum.rgb += 0.2 * float3(1.3, 1.2, 1.0) * pow(sundot, 5.0) * (1.0 - a);
        col = mix(col, sum.rgb, sum.a);
        if (u.nmode) col *= 0.2;
        __nv_out = float4(col, u.alpha);
    return __nv_out;
}
