// ---------------------------------------------------------------------------
// Split Cubes Raymarch
// origem : assets/effects/toji-split-cubes-raymarch.xml
// id     : com.alightcreative.effects.split_cubes_raymarch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_split_cubes_raymarchParams {
    float BPM;
    float STEPS;
    float EPS;
    float MAX_DIST;
    float SPIN_SCALE;
};

// --- funcoes auxiliares do efeito
// Split Cubes Raymarch - GLES-friendly single pass

#define PI 3.14159265359
#define HALFPI (PI*0.5)

float2 rot2(float2 a, float b){
    float c = cos(b), s = sin(b);
    return float2(a.x*c - a.y*s, a.x*s + a.y*c);
}

float sdBox(float3 p, float3 r){
    float3 d = abs(p) - r;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdRoundBox(float3 p, float3 r, float rr){
    return sdBox(p, r - float3(rr)) - rr;
}

float tick(float t){
    t = smoothstep(0.0, 1.0, t);
    t = smoothstep(0.0, 1.0, t);
    return t;
}

float noise1(float a){
    return fract(a * 123.4762831);
}

float hash2(float2 a){
    return fract(sin(dot(a, float2(4.43243, 12.4762)) * 13.43762));
}

float2 splitScene(float3 p, float spinScale, float SPEED){
    float time = eng.acTime * SPEED;
    float t = tick(fract(time));
    float mode = noise1(floor(time)) * 3.0;

    float axisDirection = (fract(mode) < 0.5) ? -1.0 : 1.0;
    float spinDirection = (__nv_mod(mode, 0.5) < 0.25) ? -1.0 : 1.0;
    t *= spinDirection;

    float clipDist = 0.0;
    if (mode < 1.0){
        p.yz = rot2(p.yz, t * HALFPI * spinScale);
        clipDist = p.x * axisDirection - 0.5;
    } else if (mode < 2.0){
        p.xz = rot2(p.xz, t * HALFPI * spinScale);
        clipDist = p.y * axisDirection - 0.5;
    } else {
        p.xy = rot2(p.xy, t * HALFPI * spinScale);
        clipDist = p.z * axisDirection - 0.5;
    }
    clipDist *= (1.0 - spinScale * 2.0);

    float3 lp = __nv_mod(p + 0.5, 1.0) - 0.5;
    float distCubes = max(
        sdBox(p, float3(1.5)),
        sdRoundBox(lp, float3(0.48), 0.04)
    );

    float3 stickerSize = float3(0.4, 0.4, 1.0);
    float stickerRadius = 0.05;
    float distStickers = min(
        min(
            sdRoundBox(lp, stickerSize.xyz, stickerRadius),
            sdRoundBox(lp, stickerSize.yzx, stickerRadius)
        ),
        sdRoundBox(lp, stickerSize.zxy, stickerRadius)
    );
    distStickers = max(distStickers, -sdBox(p, float3(1.4)));

    distCubes = max(distCubes, clipDist);

    float color = 0.0;
    color += floor(p.x + 1.5) * 3.0;
    color += floor(p.y + 1.5) * 7.0;
    color += floor(p.z + 1.5) * 11.0;
    color += mode;

    return float2(distCubes, (distStickers < 0.0) ? (1.0 + color) : 0.0);
}

float2 sceneSDF(float3 p, float SPEED){
    float2 a = splitScene(p, 0.0, SPEED);
    float2 b = splitScene(p, u.SPIN_SCALE, SPEED);
    return (a.x < b.x) ? float2(a.x, a.y) : float2(b.x, b.y);
}

float3 colorForIndex(int idx){
    // Map 0..5 to fixed palette without dynamic array indexing
    if (idx == 0) return float3(1.0, 0.0, 0.0);
    if (idx == 1) return float3(1.0, 1.0, 0.0);
    if (idx == 2) return float3(0.0, 1.0, 0.0);
    if (idx == 3) return float3(1.0, 1.0, 1.0);
    if (idx == 4) return float3(0.0, 0.0, 1.0);
    return float3(1.0, 0.5, 0.0);
}

fragment float4 fx_toji_split_cubes_raymarch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_split_cubes_raymarchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 R = eng.acScreenSize;
    float2 uv = in.acScreenNorm - 0.5;
    uv.x *= R.x / max(R.y, 1.0);

    float SPEED = max(u.BPM, 1.0) / 60.0;

    float3 cam = float3(0.0, 0.0, -10.0);
    float3 dir = normalize(float3(uv, 1.5));

    float angYZ = sin(eng.acTime) * 0.3 + 0.3;
    cam.yz = rot2(cam.yz, angYZ);
    dir.yz = rot2(dir.yz, angYZ);

    float angXZ = eng.acTime * 0.5;
    cam.xz = rot2(cam.xz, angXZ);
    dir.xz = rot2(dir.xz, angXZ);

    float t = 0.0;
    float2 k = float2(0.0);

    int maxSteps = int(clamp(u.STEPS, 1.0, 200.0));
    const int MAX_IT = 200;
    for (int i = 0; i < MAX_IT; ++i){
        if (i >= maxSteps) break;
        k = sceneSDF(cam + dir * t, SPEED);
        t += k.x;
        if (k.x < u.EPS) break;
        if (t > u.MAX_DIST){
            k.y = -1.0;
            break;
        }
    }

    float3 h = cam + dir * t;
    float2 o = float2(0.001, 0.0);
    float3 n = normalize(float3(
        sceneSDF(h + float3(o.x, o.y, o.y), SPEED).x - sceneSDF(h - float3(o.x, o.y, o.y), SPEED).x,
        sceneSDF(h + float3(o.y, o.x, o.y), SPEED).x - sceneSDF(h - float3(o.y, o.x, o.y), SPEED).x,
        sceneSDF(h + float3(o.y, o.y, o.x), SPEED).x - sceneSDF(h - float3(o.y, o.y, o.x), SPEED).x
    ));
    float mat = k.y;

    float3 outc;
    if (abs(mat) < 1e-6){
        float fresnel = pow(1.0 - dot(-dir, n), 5.0);
        fresnel = mix(0.0016, 0.1, fresnel);
        outc = float3(fresnel);
    } else if (mat < -0.5){
        float2 luv = uv * (1.0 - length(uv) * 0.2);
        float2 c = floor(luv * 10.0 + eng.acTime);
        float2 u = fract(luv * 10.0 + eng.acTime) - 0.5;
        int colorIndex = int(floor(hash2(c + 0.1 * floor(eng.acTime * SPEED)) * 6.0 + 1e-4));
        colorIndex = clamp(colorIndex, 0, 5);
        float d = sdRoundBox(float3(u, 0.0), float3(0.46), 0.05);
        float mask = smoothstep(0.0, 0.01, -d);
        float vignette = smoothstep(1.0, 0.3, length(luv)) * 0.7;
        outc = colorForIndex(colorIndex) * mask * vignette;
    } else {
        float m = __nv_mod(mat, 6.0);
        // Determine face influence
        m += (step(0.1, n.x) + 0.0) * float(abs(n.x) > 0.1);
        m += (step(0.1, n.y) + 2.0) * float(abs(n.y) > 0.1);
        m += (step(0.1, n.z) + 4.0) * float(abs(n.z) > 0.1);
        int idx = int(__nv_mod(m, 6.0));
        outc = colorForIndex(idx);
    }

    outc = pow(max(outc, 0.0), float3(0.4545));
    outc = pow(outc, float3(1.2, 1.1, 1.0));

    __nv_out = float4(outc, 1.0);
    return __nv_out;
}
