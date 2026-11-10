// ---------------------------------------------------------------------------
// Nebulosidade
// origem : assets/effects/nebulosity.xml
// id     : nova.effect.nebulosity
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nebulosityParams {
    int shape;
    float density;
    float coverage;
    float size;
    float noiseScale;
    float octaves;
    float warp;
    float evolution;
    float seed;
    float rotation;
    float tilt;
    float spin;
    float zoom;
    float2 center;
    float lightAngle;
    float lightIntensity;
    float absorption;
    float emission;
    float4 colorThin;
    float4 colorMid;
    float4 colorCore;
    float stars;
    int overInput;
    float quality;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

float hash3(float3 p) {
    p = fract(p * float3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.x + p.y) * p.z);
}

/** Ruído de valor 3D com interpolação suave. */
float ruido3(float3 p) {
    float3 i = floor(p);
    float3 f = fract(p);
    float3 s = f * f * (3.0 - 2.0 * f);
    float a = hash3(i);
    float b = hash3(i + float3(1.0, 0.0, 0.0));
    float c = hash3(i + float3(0.0, 1.0, 0.0));
    float d = hash3(i + float3(1.0, 1.0, 0.0));
    float e = hash3(i + float3(0.0, 0.0, 1.0));
    float g = hash3(i + float3(1.0, 0.0, 1.0));
    float h = hash3(i + float3(0.0, 1.0, 1.0));
    float k = hash3(i + float3(1.0, 1.0, 1.0));
    return mix(mix(mix(a, b, s.x), mix(c, d, s.x), s.y),
               mix(mix(e, g, s.x), mix(h, k, s.x), s.y), s.z);
}

float fbm3(float3 p, int n) {
    float soma = 0.0;
    float peso = 0.0;
    float amp = 1.0;
    for (int i = 0; i < 7; i++) {
        if (i >= n) break;
        soma += ruido3(p) * amp;
        peso += amp;
        amp *= 0.5;
        p = p * 2.03 + float3(1.7, 9.2, 4.1);
    }
    return soma / max(peso, 1e-4);
}

float3 girarY(float3 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return float3(c * p.x + s * p.z, p.y, -s * p.x + c * p.z);
}

float3 girarX(float3 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return float3(p.x, c * p.y - s * p.z, s * p.y + c * p.z);
}

/** Forma que recorta o ruído: 1 dentro, 0 fora, macia na borda. */
float forma(float3 p) {
    int f = int(u.shape + 0.5);
    if (f == 1) {
        float r = length(p.xz);
        float braco = 0.5 + 0.5 * sin(__nv_atan(p.z, p.x) * 2.0 - r * 6.0);
        float disco = exp(-abs(p.y) * 7.0 / max(u.size, 0.05)) * smoothstep(u.size * 1.1, 0.0, r);
        return disco * mix(0.55, 1.0, braco);
    }
    if (f == 2) {
        return smoothstep(1.0, 0.2, abs(p.y));
    }
    return smoothstep(u.size, u.size * 0.35, length(p));
}

float densidade(float3 p, float t, int n) {
    float3 q = p * u.noiseScale + float3(u.seed * 7.13, u.seed * 3.71, u.seed * 5.37);
    float3 torto = float3(fbm3(q + float3(0.0, t, 0.0), 3),
                      fbm3(q + float3(5.2, 1.3, t), 3),
                      fbm3(q + float3(t, 2.8, 9.1), 3));
    float v = fbm3(q + (torto - 0.5) * u.warp * 2.0 + float3(0.0, 0.0, t * 0.5), n);
    v = (v - u.coverage) / max(1.0 - u.coverage, 1e-3);
    return max(v, 0.0) * forma(p) * u.density;
}

float3 rampa(float d) {
    float3 a = u.colorThin.rgb;
    float3 b = u.colorMid.rgb;
    float3 c = u.colorCore.rgb;
    float x = clamp(d, 0.0, 1.0);
    return x < 0.5 ? mix(a, b, x * 2.0) : mix(b, c, (x - 0.5) * 2.0);
}

float estrelas(float2 p) {
    float2 g = floor(p);
    float2 f = fract(p) - 0.5;
    float h = hash3(float3(g, 7.0));
    float2 o = float2(hash3(float3(g, 1.0)), hash3(float3(g, 2.0))) - 0.5;
    float d = length(f - o * 0.7);
    float liga = step(0.92, h);
    return liga * smoothstep(0.06, 0.0, d) * (0.5 + 0.5 * hash3(float3(g, 3.0)));
}

fragment float4 fx_nebulosity(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nebulosityParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 uv = (in.acScreenNorm - u.center) * 2.0;
    uv.x *= eng.acAspect;

    float t = eng.acTime * u.evolution;
    int n = clamp(int(u.octaves + 0.5), 1, 7);
    int passos = clamp(int(u.quality + 0.5), 16, 96);

    // Câmera olhando para a origem; o volume gira, a câmera fica.
    float3 ro = float3(0.0, 0.0, -2.6 * u.zoom);
    float3 rd = normalize(float3(uv, 1.6));
    float giro = (u.rotation + u.spin * eng.acTime) * PI / 180.0;
    float incl = u.tilt * PI / 180.0;

    float la = u.lightAngle * PI / 180.0;
    float3 luz = normalize(float3(cos(la), sin(la), -0.6));

    // Faixa do raio que atravessa a caixa |p| < 1.6.
    float perto = max(0.0, 2.6 * u.zoom - 1.6 * u.size - 0.2);
    float longe = 2.6 * u.zoom + 1.6 * u.size + 0.2;
    float dt = (longe - perto) / float(passos);
    // Começo do passo embaralhado por pixel: tira as faixas do raymarching.
    float s0 = hash3(float3(in.acScreenNorm * 913.0, 1.0)) * dt;

    float3 cor = float3(0.0);
    float transm = 1.0;
    for (int i = 0; i < 96; i++) {
        if (i >= passos || transm < 0.01) break;
        float s = perto + s0 + float(i) * dt;
        float3 p = girarY(girarX(ro + rd * s, incl), giro);
        float d = densidade(p, t, n);
        if (d > 0.002) {
            // sombra própria: uma amostra na direção da luz
            float3 pl = p + girarY(girarX(luz, incl), giro) * 0.18;
            float dl = densidade(pl, t, max(n - 2, 1));
            float sombra = exp(-dl * u.absorption * 2.0);
            float3 c = rampa(d * 0.6);
            float3 brilho = c * (0.25 + u.lightIntensity * sombra) + u.colorCore.rgb * u.emission * d * d * 0.35;
            float a = 1.0 - exp(-d * u.absorption * dt * 3.0);
            cor += transm * a * brilho;
            transm *= 1.0 - a;
        }
    }

    float alfa = 1.0 - transm;
    float st = estrelas(in.acScreenNorm * float2(eng.acAspect, 1.0) * 160.0) * u.stars * transm;
    cor += float3(st);
    alfa = max(alfa, min(st, 1.0));

    float4 neb = float4(cor, alfa);
    if (u.overInput > 0.5) {
        __nv_out = float4(neb.rgb + original.rgb * (1.0 - neb.a), neb.a + original.a * (1.0 - neb.a));
    } else {
        __nv_out = neb;
    }
    return __nv_out;
}
