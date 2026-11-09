// ---------------------------------------------------------------------------
// Optical Flares (motor da GPU do iOS)
// origem : assets/effects/ae-optical-flares.xml
// id     : nova.effect.aeopticalflares
//
// No APK o flare e desenhado na CPU por com.novaeditor.model.opticalflares
// (MotorDoOf, porte bit a bit do plugin da Video Copilot). No iOS o flare e
// desenhado aqui, com os controles do efeito do AE (posicao da luz, centro,
// brilho, escala, rotacao, cor, modo de cor, evolucao, Render Mode) e mais as
// opcoes do iOS: o tipo de flare (preset) e cada elemento a parte — Glow,
// Streak, Spike Ball (raios), Shimmer, Ring, Hoop, Multi Iris (ghosts, com a
// forma da iris), Chromatic Aberration, Flicker, Saturacao e Fade Off Edges.
// Escrito a mao (nao e saida do glsl2msl.py). A ordem dos campos e a do XML.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_optical_flaresParams {
    float2 positionXY;
    float2 centerPosition;
    float brightness;
    float scale;
    float rotationOffset;
    float4 color;
    int colorMode;
    float animationEvolution;
    int renderMode;
    float4 flare;
    int preset;
    float glowIntensity;
    float glowSize;
    float streakIntensity;
    float streakLength;
    float streakAngle;
    float raysIntensity;
    float rayCount;
    float raysLength;
    float shimmerIntensity;
    float ringIntensity;
    float hoopIntensity;
    float ghostsIntensity;
    float ghostCount;
    float ghostSize;
    int irisShape;
    float chromatic;
    float flicker;
    float flickerSpeed;
    float saturation;
    int fadeOffEdges;
};

// Perfil de cada preset: tons e pesos de cada elemento.
struct OfPerfil {
    float3 nucleo, halo, streak, raio, anel, hoop;
    float3 g0, g1, g2;
    float kGlow, kStreak, kStreakLen, kRaios, kShimmer, kAnel, kHoop, kGhost;
};

static OfPerfil of_perfil(int p) {
    OfPerfil f;
    f.nucleo = float3(1.00, 0.92, 0.82); f.halo = float3(1.00, 0.70, 0.40);
    f.streak = float3(0.55, 0.72, 1.00); f.raio = float3(1.00, 0.85, 0.70);
    f.anel = float3(0.40, 0.85, 0.75);   f.hoop = float3(0.50, 0.70, 1.00);
    f.g0 = float3(0.9, 0.6, 0.3); f.g1 = float3(0.3, 0.8, 0.6); f.g2 = float3(0.6, 0.5, 1.0);
    f.kGlow = 1; f.kStreak = 1; f.kStreakLen = 1; f.kRaios = 1; f.kShimmer = 1; f.kAnel = 1; f.kHoop = 1; f.kGhost = 1;
    switch (p) {
    case 1: // Anamorfico Azul
        f.nucleo = float3(0.85, 0.92, 1.0); f.halo = float3(0.30, 0.55, 1.0); f.streak = float3(0.25, 0.55, 1.0);
        f.g0 = float3(0.3, 0.5, 1.0); f.g1 = float3(0.2, 0.7, 1.0); f.g2 = float3(0.5, 0.4, 1.0);
        f.kStreak = 2.2; f.kStreakLen = 2.5; f.kRaios = 0.25; f.kShimmer = 0.4; f.kAnel = 0.5; f.kGhost = 0.8; break;
    case 2: // Sol Quente
        f.nucleo = float3(1.0, 0.95, 0.75); f.halo = float3(1.0, 0.55, 0.15); f.raio = float3(1.0, 0.75, 0.35);
        f.streak = float3(1.0, 0.65, 0.3); f.anel = float3(1.0, 0.6, 0.3);
        f.kGlow = 1.8; f.kRaios = 1.5; f.kStreak = 0.5; f.kGhost = 0.7; break;
    case 3: // Estrela (Spike Ball)
        f.kRaios = 2.6; f.kStreak = 0.6; f.kShimmer = 1.6; f.kGhost = 0.4; f.kAnel = 0.3; break;
    case 4: // Ficcao Cientifica
        f.nucleo = float3(0.8, 1.0, 1.0); f.halo = float3(0.1, 0.8, 1.0); f.streak = float3(0.1, 0.9, 1.0);
        f.anel = float3(0.2, 1.0, 0.9); f.hoop = float3(0.3, 0.9, 1.0);
        f.g0 = float3(0.1, 0.9, 1.0); f.g1 = float3(0.6, 0.3, 1.0); f.g2 = float3(0.2, 1.0, 0.6);
        f.kStreak = 1.8; f.kStreakLen = 1.6; f.kAnel = 2.5; f.kHoop = 2.0; f.kGhost = 1.8; f.kRaios = 0.5; break;
    case 5: // Sutil
        f.kGlow = 0.6; f.kStreak = 0.35; f.kRaios = 0.3; f.kShimmer = 0.3; f.kAnel = 0.3; f.kHoop = 0.3; f.kGhost = 0.5; break;
    case 6: // Neon Verde
        f.nucleo = float3(0.85, 1.0, 0.9); f.halo = float3(0.0, 1.0, 0.55); f.streak = float3(0.1, 1.0, 0.6);
        f.raio = float3(0.5, 1.0, 0.7); f.anel = float3(0.0, 1.0, 0.55); f.hoop = float3(0.2, 1.0, 0.5);
        f.g0 = float3(0.0, 1.0, 0.5); f.g1 = float3(0.4, 1.0, 0.3); f.g2 = float3(0.0, 0.8, 0.8);
        f.kStreak = 1.4; f.kAnel = 1.6; break;
    case 7: // Arco-iris
        f.anel = float3(1.0); f.g0 = float3(1.0, 0.3, 0.3); f.g1 = float3(0.3, 1.0, 0.3); f.g2 = float3(0.3, 0.4, 1.0);
        f.kAnel = 2.2; f.kGhost = 1.6; f.kHoop = 1.5; break;
    case 8: // Lente Vintage
        f.nucleo = float3(1.0, 0.9, 0.7); f.halo = float3(0.9, 0.6, 0.35); f.streak = float3(0.9, 0.7, 0.5);
        f.g0 = float3(0.9, 0.5, 0.3); f.g1 = float3(0.7, 0.6, 0.3); f.g2 = float3(0.8, 0.4, 0.5);
        f.kGhost = 2.2; f.kHoop = 1.8; f.kStreak = 0.4; f.kRaios = 0.4; break;
    case 9: // Por do Sol
        f.nucleo = float3(1.0, 0.85, 0.6); f.halo = float3(1.0, 0.35, 0.15); f.streak = float3(1.0, 0.45, 0.25);
        f.raio = float3(1.0, 0.5, 0.25); f.anel = float3(1.0, 0.4, 0.5);
        f.g0 = float3(1.0, 0.4, 0.2); f.g1 = float3(0.9, 0.3, 0.5); f.g2 = float3(1.0, 0.6, 0.2);
        f.kGlow = 2.0; f.kStreak = 1.2; f.kStreakLen = 1.4; break;
    default: break;
    }
    return f;
}

static float2 of_rot(float2 p, float a) {
    float c = cos(a), s = sin(a);
    return float2(c * p.x - s * p.y, s * p.x + c * p.y);
}

// Poligono regular de n lados (iris), distancia com sinal aproximada.
static float of_poly(float2 p, float r, int forma) {
    if (forma == 1) return length(p) - r;                       // circulo
    float n = forma == 2 ? 8.0 : (forma == 3 ? 5.0 : 6.0);       // octogono / pentagono / hexagono
    float a = atan2(p.y, p.x);
    float setor = 6.2831853 / n;
    float m = fmod(a + 6.2831853 * 4.0 + setor * 0.5, setor) - setor * 0.5;
    return length(p) * cos(m) - r * cos(setor * 0.5);
}

static float3 of_arcoiris(float t) {
    return clamp(abs(fmod(t * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

static float of_hash(float n) { return fract(sin(n) * 43758.5453); }

// O flare inteiro num ponto. `k` desloca levemente os ghosts (aberracao cromatica).
static float3 of_flare(float2 uv, float2 asp, constant ae_optical_flaresParams& u, OfPerfil f, float k) {
    float2 L = u.positionXY;
    float2 C = u.centerPosition;
    float sc = max(u.scale, 0.0) / 100.0 + 1e-4;
    float rot = u.rotationOffset * 0.0174533;
    float evo = u.animationEvolution * 0.0174533;

    float2 p = (uv - L) * asp;
    float d = length(p);
    float2 q = of_rot(p, -rot);
    float ang = atan2(q.y, q.x);

    float3 col = float3(0.0);

    // Glow
    float gI = max(u.glowIntensity, 0.0) / 100.0 * f.kGlow;
    float gS = sc * max(u.glowSize, 1.0) / 100.0;
    col += f.nucleo * exp(-(d * d) / (0.0009 * gS * gS)) * 1.6 * gI;
    col += f.halo * exp(-d / (0.10 * gS)) * 0.55 * gI;
    col += f.halo * float3(0.6, 0.65, 1.6) * exp(-d / (0.35 * gS)) * 0.12 * gI;

    // Streak (anamorfico)
    float sI = max(u.streakIntensity, 0.0) / 100.0 * f.kStreak;
    float sL = max(u.streakLength, 1.0) / 100.0 * f.kStreakLen;
    float2 qs = of_rot(q, -u.streakAngle * 0.0174533);
    float strk = exp(-abs(qs.y) / (0.0035 * sc)) * exp(-abs(qs.x) / (0.75 * sc * sL));
    float strk2 = exp(-abs(qs.y) / (0.012 * sc)) * exp(-abs(qs.x) / (0.30 * sc * sL));
    col += f.streak * (strk * 0.9 + strk2 * 0.25) * sI;

    // Spike Ball (raios)
    float rI = max(u.raysIntensity, 0.0) / 100.0 * f.kRaios;
    float nR = max(floor(u.rayCount + 0.5), 2.0) * 0.5;
    float rL = max(u.raysLength, 1.0) / 100.0;
    float raios = pow(abs(cos(ang * nR + evo)), 60.0)
                + 0.6 * pow(abs(cos(ang * nR + 3.14159 / (2.0 * nR) + evo * 1.7)), 120.0);
    col += f.raio * raios * exp(-d / (0.16 * sc * rL)) * 0.7 * rI;

    // Shimmer
    float shI = max(u.shimmerIntensity, 0.0) / 100.0 * f.kShimmer;
    float shim = 0.5 + 0.5 * sin(ang * 37.0 + evo * 3.0) * sin(ang * 23.0 - evo * 2.0);
    col += float3(0.9, 0.8, 1.0) * shim * exp(-d / (0.06 * sc)) * 0.25 * shI;

    // Ring
    float rgI = max(u.ringIntensity, 0.0) / 100.0 * f.kAnel;
    float ring = exp(-pow((d - 0.22 * sc) / (0.010 * sc), 2.0));
    float3 anelCor = (u.preset == 7) ? of_arcoiris((d - 0.21 * sc) / (0.02 * sc) * 0.5) : f.anel;
    col += anelCor * ring * 0.18 * rgI;

    // Multi Iris (ghosts no eixo luz -> centro)
    float2 axis = C - L;
    float lenAxis = length(axis * asp);
    float vis = clamp(1.0 - lenAxis * 0.35, 0.35, 1.0);
    float ghI = max(u.ghostsIntensity, 0.0) / 100.0 * f.kGhost;
    float gSz = max(u.ghostSize, 1.0) / 100.0;
    int N = clamp(int(u.ghostCount + 0.5), 0, 16);
    for (int i = 0; i < N; i++) {
        float fi = float(i);
        float tPos = 0.35 + fi * 0.27 + of_hash(fi * 7.13) * 0.2;
        tPos *= k;
        float r = (0.015 + of_hash(fi * 3.71) * 0.10) * sc * gSz;
        float2 g = L + axis * tPos;
        float2 gp = of_rot((uv - g) * asp, evo * 0.15 + fi);
        float sd = of_poly(gp, r, u.irisShape);
        float disco = 1.0 - smoothstep(-r * 0.12, r * 0.04, sd);
        float borda = exp(-pow(sd / (r * 0.08 + 1e-4), 2.0));
        float3 tint = (i % 3 == 0) ? f.g0 : ((i % 3 == 1) ? f.g1 : f.g2);
        if (u.preset == 7) tint = of_arcoiris(fi / max(float(N), 1.0));
        col += tint * (disco * 0.07 + borda * 0.10) * vis * ghI;
    }

    // Hoop
    float hI = max(u.hoopIntensity, 0.0) / 100.0 * f.kHoop;
    float2 hp = (uv - (C + (C - L) * 0.9 * k)) * asp;
    float hoop = exp(-pow((length(hp) - 0.30 * sc) / (0.012 * sc), 2.0));
    col += f.hoop * hoop * 0.10 * vis * hI;

    return col;
}

fragment float4 fx_ae_optical_flares(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_optical_flaresParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float4 src = inputImg.sample(__nv_smp, uv);

    float2 res = max(eng.acScreenSize, float2(1.0));
    float2 asp = float2(res.x / res.y, 1.0);
    OfPerfil f = of_perfil(u.preset);

    // Chromatic Aberration: cada canal com os ghosts um pouco deslocados.
    float ca = clamp(u.chromatic, 0.0, 100.0) / 100.0 * 0.08;
    float3 col;
    if (ca > 0.0001) {
        col.r = of_flare(uv, asp, u, f, 1.0 + ca).r;
        col.g = of_flare(uv, asp, u, f, 1.0).g;
        col.b = of_flare(uv, asp, u, f, 1.0 - ca).b;
    } else {
        col = of_flare(uv, asp, u, f, 1.0);
    }

    // Cor: Tint (mistura) ou Multiply.
    float3 c = u.color.rgb;
    col = (u.colorMode == 1) ? col * c : mix(col, col * c * 1.4, 0.65);

    // Saturacao.
    float lum = dot(col, float3(0.2126, 0.7152, 0.0722));
    col = max(mix(float3(lum), col, max(u.saturation, 0.0) / 100.0), 0.0);

    // Brilho, Flicker e Fade Off Edges.
    float bright = max(u.brightness, 0.0) / 100.0;
    float fl = clamp(u.flicker, 0.0, 100.0) / 100.0;
    if (fl > 0.0) {
        float t = eng.acTime * (0.5 + u.flickerSpeed * 0.25);
        float n = 0.5 * (sin(t * 6.1) + sin(t * 13.7 + 1.3)) * 0.5 + 0.5;
        float r = of_hash(floor(t * 3.0));
        bright *= 1.0 - fl * (0.6 * n + 0.4 * r);
    }
    if (u.fadeOffEdges != 0) {
        float2 L = u.positionXY;
        float fora = max(max(-L.x, L.x - 1.0), max(-L.y, L.y - 1.0));
        bright *= clamp(1.0 - fora * 4.0, 0.0, 1.0);
    }
    col *= bright;

    float4 outc;
    if (u.renderMode == 0) {            // On Black
        outc = float4(col, 1.0);
    } else if (u.renderMode == 1) {     // On Transparent
        float a = clamp(max(col.r, max(col.g, col.b)), 0.0, 1.0);
        outc = float4(col, a);
    } else {                            // Over Original (Screen)
        float3 base = src.rgb;
        outc = float4(1.0 - (1.0 - base) * (1.0 - clamp(col, 0.0, 1.0)) + max(col - 1.0, 0.0),
                      max(src.a, clamp(max(col.r, max(col.g, col.b)), 0.0, 1.0)));
    }
    return outc;
}
