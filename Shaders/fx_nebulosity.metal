// ---------------------------------------------------------------------------
// Nebulosity
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
    float width;
    float height;
    float depth;
    float diameter;
    float featherStart;
    float featherEnd;
    float rotX;
    float rotY;
    float rotZ;
    float2 position;
    float positionZ;
    float scale;
    float density;
    float4 absorption;
    int emissionSource;
    float emissionMul;
    float4 emissionColor;
    float4 gradA;
    float4 gradB;
    int gradBase;
    float gradScale;
    float emNoiseAmp;
    float emNoiseScale;
    float emNoiseEvo;
    int n1On;
    int n1Type;
    float n1Cx;
    float n1Off;
    float n1Con;
    float n1Sc;
    float n1SX;
    float n1SY;
    float n1SZ;
    float n1OX;
    float n1OY;
    float n1OZ;
    float n1Evo;
    int n1Lim;
    int n1Op;
    int n2On;
    int n2Type;
    float n2Cx;
    float n2Off;
    float n2Con;
    float n2Sc;
    float n2SX;
    float n2SY;
    float n2SZ;
    float n2OX;
    float n2OY;
    float n2OZ;
    float n2Evo;
    int n2Lim;
    int n2Op;
    int n3On;
    int n3Type;
    float n3Cx;
    float n3Off;
    float n3Con;
    float n3Sc;
    float n3SX;
    float n3SY;
    float n3SZ;
    float n3OX;
    float n3OY;
    float n3OZ;
    float n3Evo;
    int n3Lim;
    int n3Op;
    int negLight;
    float starsCount;
    float starsIntensity;
    float starsFalloff;
    float4 starsColor;
    float starsSeed;
    int fastOn;
    float fastVis;
    float fastScale;
    float fastIntensity;
    float fastRand;
    float4 fastColor;
    int mosaicOn;
    float mosaicSize;
    float mosaicBlend;
    float densFactor;
    float alphaFactor;
    float spiralX;
    float spiralY;
    float spiralZ;
    float spiralExp;
    float maxSteps;
    int jitter;
    int densPreview;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

float hash3(float3 p) {
    p = fract(p * float3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.x + p.y) * p.z);
}

float vnoise(float3 p) {
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

float worley(float3 p) {
    float3 i = floor(p);
    float3 f = fract(p);
    float m = 1.0;
    for (int z = -1; z <= 1; z++) {
        for (int y = -1; y <= 1; y++) {
            for (int x = -1; x <= 1; x++) {
                float3 c = float3(float(x), float(y), float(z));
                float3 o = float3(hash3(i + c), hash3(i + c + 17.1), hash3(i + c + 31.7));
                m = min(m, length(c + o - f));
            }
        }
    }
    return 1.0 - clamp(m, 0.0, 1.0);
}

float3 girar(float3 p, float3 a) {
    float cx = cos(a.x); float sx = sin(a.x);
    float cy = cos(a.y); float sy = sin(a.y);
    float cz = cos(a.z); float sz = sin(a.z);
    p = float3(p.x, cx * p.y - sx * p.z, sx * p.y + cx * p.z);
    p = float3(cy * p.x + sy * p.z, p.y, -sy * p.x + cy * p.z);
    p = float3(cz * p.x - sz * p.y, sz * p.x + cz * p.y, p.z);
    return p;
}

/** Um noise do painel: tipo, complexidade (oitavas) e evolucao (anda no 4o eixo). */
float noiseTipo(float3 p, float tipo, float cx, float evo) {
    int t = int(tipo + 0.5);
    int n = clamp(int(cx + 0.5), 1, 8);
    if (t == 1) {
        // Spiral: o espaco gira em torno de Y conforme o raio
        float r = length(p.xz);
        float ang = r * 0.7 + evo * 0.15;
        p.xz = float2(cos(ang) * p.x - sin(ang) * p.z, sin(ang) * p.x + cos(ang) * p.z);
    }
    float soma = 0.0;
    float peso = 0.0;
    float amp = 1.0;
    float3 q = p + float3(evo * 0.11, evo * 0.07, evo * 0.13);
    for (int i = 0; i < 8; i++) {
        if (i >= n) break;
        float v;
        if (t == 2) v = worley(q);
        else if (t == 3) v = 1.0 - abs(vnoise(q) * 2.0 - 1.0);
        else v = vnoise(q);
        soma += v * amp;
        peso += amp;
        amp *= 0.5;
        q = q * 2.02 + float3(3.1, 7.7, 1.3);
    }
    float r = soma / max(peso, 1e-4);
    if (t == 3) r = r * r;
    return r;
}

/** Densidade do noise i com Offset/Contrast/Scale/Evolution/Limit como no painel. */
float umNoise(float3 p, float tipo, float cx, float off, float con, float sc, float3 sxyz, float3 o, float evo, float lim) {
    float3 q = (p + o) / (max(sc, 1.0) * 0.01 * max(sxyz * 0.01, float3(0.01)) * 300.0);
    float v = noiseTipo(q, tipo, cx, evo);
    v = (v - 0.5) * (con * 0.01) + 0.5 + off * 0.1;
    if (lim > 0.5) v = min(v, 1.0);
    return v;
}

float aplica(float d, float v, float op) {
    int o = int(op + 0.5);
    if (o == 1) return d - v;
    if (o == 2) return d * v;
    return d + v;
}

/** Rampa de feather: 1 dentro, cai ate 0 na borda (Density Feather Ramp). */
float pena(float x) {
    return 1.0 - smoothstep(u.featherStart, max(u.featherEnd, u.featherStart + 1e-3), x);
}

float densidade(float3 p, float3 lp) {
    float borda;
    if (int(u.shape + 0.5) == 1) {
        borda = length(lp) / max(u.diameter * 0.5, 1.0);
    } else {
        float3 h = float3(u.width, u.height, u.depth) * 0.5;
        float3 a = abs(lp) / max(h, float3(1.0));
        borda = max(a.x, max(a.y, a.z));
    }
    if (borda >= 1.0) return 0.0;
    float d = u.density * 0.05;
    if (u.n1On > 0.5) d = aplica(d, umNoise(lp, u.n1Type, u.n1Cx, u.n1Off, u.n1Con, u.n1Sc, float3(u.n1SX, u.n1SY, u.n1SZ), float3(u.n1OX, u.n1OY, u.n1OZ), u.n1Evo, u.n1Lim), u.n1Op);
    if (u.n2On > 0.5) d = aplica(d, umNoise(lp, u.n2Type, u.n2Cx, u.n2Off, u.n2Con, u.n2Sc, float3(u.n2SX, u.n2SY, u.n2SZ), float3(u.n2OX, u.n2OY, u.n2OZ), u.n2Evo, u.n2Lim), u.n2Op);
    if (u.n3On > 0.5) d = aplica(d, umNoise(lp, u.n3Type, u.n3Cx, u.n3Off, u.n3Con, u.n3Sc, float3(u.n3SX, u.n3SY, u.n3SZ), float3(u.n3OX, u.n3OY, u.n3OZ), u.n3Evo, u.n3Lim), u.n3Op);
    d = max(d, 0.0) * pena(borda);
    return d * u.densFactor;
}

float3 posEstrela(int i) {
    float s = float(i) * 13.17 + u.starsSeed * 3.71;
    float3 r = float3(hash3(float3(s, 1.0, 2.0)), hash3(float3(3.0, s, 4.0)), hash3(float3(5.0, 6.0, s))) - 0.5;
    if (int(u.shape + 0.5) == 1) return r * u.diameter * 0.8;
    return r * float3(u.width, u.height, u.depth) * 0.8;
}

float3 emissao(float d, float3 lp, float2 uv) {
    int src = int(u.emissionSource + 0.5);
    float3 c = u.emissionColor.rgb;
    if (src == 1) {
        float x;
        int b = int(u.gradBase + 0.5);
        float esc = max(u.gradScale, 1.0) * 0.01;
        if (b == 1) {
            float raio = int(u.shape + 0.5) == 1 ? u.diameter * 0.5 : max(u.width, max(u.height, u.depth)) * 0.5;
            x = length(lp) / max(raio * esc, 1.0);
        } else if (b == 2) {
            x = vnoise(lp / (300.0 * esc) + float3(0.0, 0.0, u.emNoiseEvo * 0.1));
        } else {
            x = d / esc;
        }
        if (u.emNoiseAmp > 0.0) {
            x += (vnoise(lp / (3.0 * max(u.emNoiseScale, 1.0)) + float3(u.emNoiseEvo * 0.1)) - 0.5) * u.emNoiseAmp;
        }
        c = mix(u.gradA.rgb, u.gradB.rgb, clamp(x, 0.0, 1.0));
    } else if (src == 2) {
        c = inputImg.sample(__nv_smp, uv).rgb;
    }
    return c * u.emissionMul;
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

    float2 tam = eng.acResolution;
    float4 fundo = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 px = float2(in.acScreenNorm.x * tam.x, (1.0 - in.acScreenNorm.y) * tam.y);

    // Camera padrao do AE (50 mm): no centro, olhando para +Z, zoom = 1,389 x largura.
    float zoom = tam.x * 1.38889;
    float3 ro = float3(tam * 0.5, -zoom);
    float3 rd = normalize(float3(px, 0.0) - ro);

    float3 centro = float3(u.position.x * tam.x, (1.0 - u.position.y) * tam.y, u.positionZ);
    float esc = max(u.scale, 1.0) * 0.01;
    float3 ang = float3(u.rotX, u.rotY, u.rotZ) * (PI / 180.0);

    // Distorcao Spiral: torce o espaco local em torno de cada eixo, mais forte longe do centro.
    float raioForma = int(u.shape + 0.5) == 1 ? u.diameter * 0.5 : length(float3(u.width, u.height, u.depth)) * 0.5;

    // Faixa do raio dentro da esfera que envolve a forma.
    float3 oc = ro - centro;
    float R = raioForma * esc * 1.05;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - R * R;
    float h = b * b - c;
    float3 cor = float3(0.0);
    float3 trans = float3(1.0);
    float dens = 0.0;
    if (h > 0.0) {
        float t0 = max(-b - sqrt(h), 0.0);
        float t1 = -b + sqrt(h);
        int passos = clamp(int(u.maxSteps + 0.5), 8, 256);
        float dt = (t1 - t0) / float(passos);
        float jit = u.jitter > 0.5 ? hash3(float3(in.acScreenNorm * 911.0, eng.acTime)) : 0.5;
        float3 absorve = float3(1.0) - u.absorption.rgb;
        int nEst = clamp(int(u.starsCount + 0.5), 0, 16);
        for (int i = 0; i < 256; i++) {
            if (i >= passos) break;
            float t = t0 + (float(i) + jit) * dt;
            float3 p = ro + rd * t;
            float3 lp = girar((p - centro) / esc, -ang);
            if (u.spiralX != 0.0 || u.spiralY != 0.0 || u.spiralZ != 0.0) {
                float k = pow(clamp(length(lp) / max(raioForma, 1.0), 0.0, 1.0), u.spiralExp);
                lp = girar(lp, float3(u.spiralX, u.spiralY, u.spiralZ) * (PI / 180.0) * k);
            }
            if (u.mosaicOn > 0.5) {
                float3 m = floor(lp / max(u.mosaicSize, 1.0) + 0.5) * max(u.mosaicSize, 1.0);
                lp = mix(lp, m, u.mosaicBlend);
            }
            float d = densidade(p, lp);
            if (d <= 0.0005) continue;
            float passo = d * dt * 0.004;
            dens += passo;
            float3 e = emissao(d, lp, in.acScreenNorm);
            // estrelas: pontos de luz no volume que acendem a nuvem perto delas
            float3 luz = float3(0.0);
            for (int k = 0; k < 16; k++) {
                if (k >= nEst) break;
                float dist = length(lp - posEstrela(k));
                float f = u.starsIntensity * 0.01 / (1.0 + pow(dist / max(u.starsFalloff, 1.0), 2.0));
                if (u.negLight < 0.5) f = max(f, 0.0);
                luz += u.starsColor.rgb * f;
            }
            cor += trans * (e + luz) * passo;
            trans *= exp(-absorve * passo * 4.0);
            if (max(trans.r, max(trans.g, trans.b)) < 0.005) break;
        }
        // as estrelas aparecem como pontos brilhantes
        for (int k = 0; k < 16; k++) {
            if (k >= nEst) break;
            float3 sp = centro + girar(posEstrela(k), ang) * esc;
            float3 v = sp - ro;
            float tp = dot(v, rd);
            float dl = length(v - rd * tp);
            cor += u.starsColor.rgb * u.starsIntensity * 0.01 * exp(-dl * dl / 18.0) * trans;
        }
    }

    // Fast Stars: campo de estrelas pequenas no fundo, sem custo de raymarching
    if (u.fastOn > 0.5) {
        float2 g = px / (6.0 * max(u.fastScale, 1.0) * 0.01);
        float2 cel = floor(g);
        float2 f = fract(g) - 0.5;
        float hh = hash3(float3(cel, 7.0 + u.starsSeed));
        float vis = step(1.0 - u.fastVis * 0.01 * 0.06, hh);
        float2 o = float2(hash3(float3(cel, 1.0)), hash3(float3(cel, 2.0))) - 0.5;
        float s = smoothstep(0.12, 0.0, length(f - o * 0.6));
        float it = u.fastIntensity * 0.01 * mix(1.0, hash3(float3(cel, 3.0)), u.fastRand * 0.01);
        cor += u.fastColor.rgb * s * vis * it * trans;
    }

    float alfa = clamp((1.0 - (trans.r + trans.g + trans.b) / 3.0) * u.alphaFactor, 0.0, 1.0);
    if (u.densPreview > 0.5) {
        __nv_out = float4(float3(clamp(dens, 0.0, 1.0)), 1.0);
        return __nv_out;
    }
    float3 atras = fundo.rgb * trans;
    __nv_out = float4(cor + atras, max(fundo.a, alfa));
    return __nv_out;
}
