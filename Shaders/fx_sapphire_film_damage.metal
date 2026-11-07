// ---------------------------------------------------------------------------
// S_FilmDamage
// origem : assets/effects/sapphire-film-damage.xml
// id     : nova.effect.sfilmdamage
// passes : 10
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_film_damageParams {
    float grainAmp;
    float grainAmpRed;
    float grainAmpGreen;
    float grainAmpBlue;
    float grainAmpDarks;
    float grainAmpBrights;
    int grainMono;
    int grainHold;
    float saturation;
    float scaleLights;
    float offsetDarks;
    float4 tintLights;
    float4 tintDarks;
    float shakeAmplitude;
    float shakeFrequency;
    float shakeJumpiness;
    float shakeRandom;
    float shakeAlways;
    float interframeBorder;
    float shakeTimeOffset;
    float shakeMotionBlur;
    float vignetteDarkness;
    float vignetteRadius;
    float vignetteSoftness;
    float vignetteRelHeight;
    float flicker;
    float flickerRandAmp;
    float flickerRandFreq;
    float flickerWaveAmp;
    float flickerWaveFreq;
    float defocus;
    float defocusRandAmp;
    float defocusRandFreq;
    float defocusWaveAmp;
    float defocusWaveFreq;
    float seed;
};

// --- funcoes auxiliares do efeito
const float RAIO_MAX = 240.0;

// O AE guarda os controles do Sapphire em passos de 1/65536 (truncados): 0,123 -> 0,1229858.
static float q16(float v) { return floor(v * 65536.0) / 65536.0; }

// ---------------------------------------------------------------------------------------------------------
// As tabelas fixas (assets/filmdamage/tabelas.png, gerada por tools/filmdamage/benchmark/gerar.py): cada
// número de 32 bits em dois texels da mesma coluna (bytes 0-2 em RGB, byte 3 no R da linha de baixo).
// ---------------------------------------------------------------------------------------------------------
static uint ler32(int x, int linha) {
    uint3 a = uint3(floor(tabelas.read(uint2(int2(x, linha)), uint(0)).rgb * 255.0 + 0.5));
    uint b = uint(floor(tabelas.read(uint2(int2(x, linha + 1)), uint(0)).r * 255.0 + 0.5));
    return a.x | (a.y << 8) | (a.z << 16) | (b << 24);
}

/** O hash do Sapphire: 4 rodadas de c = (c >> 8) + T[c & 255]. */
static uint rodadas(uint c) {
    for (int i = 0; i < 4; i++) c = (c >> 8) + ler32(int(c & 255u), 6);
    return c;
}
static uint hash2(uint a, uint b) { return rodadas(rodadas(a) + b); }

// ---------------------------------------------------------------------------------------------------------
// warp_noise de uma oitava em (X, 0): 9 células, núcleo radial (t = d/1,5: 1 − 2t² até 0,5, depois 2(1 − t)²,
// em passos de 1/4096 — o inicializador do plugin), valor ((h & 0x1fff) − 4096)/4096.
// ---------------------------------------------------------------------------------------------------------
static float nucleo(float d2) {
    int i = int(d2 * 4096.0) >> 1;
    float x = float(i) / 4608.0;
    float t = sqrt(x);
    float v = t < 0.5 ? 1.0 - 2.0 * x : 2.0 * (t - 1.0) * (t - 1.0);
    return floor(v * 4096.0 + 0.5) / 4096.0;
}

static float ruido1(float X, uint semente) {
    float ix = rint(X);
    float fx = X - ix;
    int iix = int(ix);
    float soma = 0.0, pesos = 0.0;
    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            float ddx = dx == -1 ? 1.0 + 2.0 * fx + fx * fx : (dx == 0 ? fx * fx : 1.0 - 2.0 * fx + fx * fx);
            float d2 = ddx + float(dy * dy);
            if (!(d2 < 2.249755859375)) continue;
            float p = nucleo(d2);
            uint h = hash2(uint(dy * 16) ^ semente, uint(iix + dx));
            soma += (float(h & 0x1fffu) - 4096.0) * (1.0 / 4096.0) * p;
            pesos += p;
        }
    }
    return 0.5 + 0.5 * (soma * (1.0 / pesos));
}

/** warp_noise(t, freq, 1, u.seed) do efeito: x = t · 2 · freq, semente = int(4096 · u.seed). */
static float warpNoise(float t, float freq, float sd) {
    return ruido1(t * freq * 2.0, uint(int(4096.0 * sd)));
}

// ---------------------------------------------------------------------------------------------------------
// sawtooth_plus_noise (0x180d05650 na DLL): uma serra de intervalos sorteados + ruído de 6 oitavas.
// ---------------------------------------------------------------------------------------------------------
const float M30F = 9.313226e-10;   // 2^-30

static float umLado(int sem, float u, float un, float aleat, float pulo, float morta) {
    int bloco = int(floor(u * 0.0009765625));
    float v = u - float(bloco * 1024);
    int lo = 0, hi = 1024, k = -1;
    for (int it = 0; it < 12; it++) {
        if (lo >= hi) break;
        int m = (lo + hi) >> 1;
        float ini = as_type<float>(ler32(m, 2));
        float comp = as_type<float>(ler32(m, 4));
        if (v >= ini && comp + ini > v) { k = m; break; }
        if (ini >= v) hi = m; else lo = m + 1;
    }
    if (k < 0) k = lo;
    float ini = as_type<float>(ler32(k, 2));
    uint h = hash2(uint(sem), uint(bloco) + ler32(k, 0));
    float s = float(rodadas(h) & 0x3fffffffu) * M30F;
    float inc = s > 0.15 ? s - 0.15 : 0.0;
    float nivel = float(h & 0x3fffffffu) * (2.0 * 9.313225746e-10) - 1.0;
    inc = inc * 2.0 - 1.0;
    float serra = (nivel + (v - ini) * inc) * pulo;
    float acc = 0.0, mult = 1.0, amp = 1.0;
    for (int b = 0; b < 6; b++) {
        float r = float(rodadas(uint(sem + 0x2bd + b)) & 0x3fffffffu) * 4.656612873e-10 - 0.25;
        float x = r + un * mult;
        int i = int(floor(x));
        float a = float(hash2(uint(sem + i), uint(b)) & 0x3fffffffu) * M30F;
        float c = float(hash2(uint(sem + i + 1), uint(b)) & 0x3fffffffu) * M30F;
        float val = a + (x - float(i)) * (c - a);
        float peso = amp + amp;
        mult += mult; amp *= 0.5;
        acc += peso * (val - 0.5);
    }
    float x = serra + acc * (aleat * 0.5079);
    if (!(abs(x) > morta)) return 0.0;
    return x - morta * sign(x);
}

/** film_damage_yshift: (yshift, |yslope|) em unidades do Sapphire (altura = 2 · H/W). */
static float2 tremor(float quadro, float fps, float a) {
    float sempre = q16(u.shakeAlways);
    if (!(sempre > 0.0)) return float2(0.0);
    float f = q16(u.shakeFrequency) / 4.0;
    float yt = (quadro - q16(u.shakeTimeOffset)) * (30.0 / fps);
    float morta = 1.2 / (sempre + 0.2) - 1.0;
    int sem = int(4096.0 * (q16(u.seed) + 0.3));
    float r0 = float(rodadas(uint(sem + 0x3fd)) & 0x3fffffffu) * 9.313225746e-08;
    float t7 = r0 + yt, t14 = t7 - 1.0;
    float aleat = q16(u.shakeRandom), pulo = q16(u.shakeJumpiness);
    float ant = umLado(sem, t14 * f + r0, 5.0 * f * t14, aleat, pulo, morta);
    float ag = umLado(sem, t7 * f + r0, 5.0 * f * t7, aleat, pulo, morta);
    float k = q16(u.shakeAmplitude) * 2.0 * a;
    return float2(ag * k, abs((ag - ant) * k));
}

// Um float de 32 bits num texel RGBA8 (o buffer `tempo`).
static float4 guardar(float v) {
    uint u = as_type<uint>(v);
    return float4(float(u & 255u), float((u >> 8) & 255u), float((u >> 16) & 255u), float(u >> 24)) / 255.0;
}
static float lerTempo(int i) {
    uint4 b = uint4(floor(tempo.read(uint2(int2(i, 0)), uint(0)) * 255.0 + 0.5));
    return as_type<float>(b.x | (b.y << 8) | (b.z << 16) | (b.w << 24));
}

// ---------------------------------------------------------------------------------------------------------
// O grão (lambda 0x180ad74f0): por canal, contador = int(4096 · (Seed + 0,123)) + 10001 · canal +
// campo · (W·H + 7) + y · W + (x com os 2 bits de baixo zerados); o byte (x & 3) do hash.
// ---------------------------------------------------------------------------------------------------------
static int2 campos(int quadro, int modo) {
    if (modo == 0) return int2(2 * quadro, 2 * quadro + 1);
    if (modo == 1) return int2(2 * quadro);
    int r = 2 * (quadro - (modo - 2)) + 14;
    int r1 = r + 1;
    int a = 2 * (r / 5) + ((r - 5 * (r / 5)) >= 2 ? 1 : 0);
    int b = 2 * (r1 / 5) + ((r1 - 5 * (r1 / 5)) >= 2 ? 1 : 0);
    return int2(b, a);   // medido: no pulldown as linhas pares ficam com o segundo campo
}

static float amplitudeDoGrao(float v, float darks, float brights) {
    int idx = clamp(int(floor(v * 4096.0)) >> 6, 0, 64);
    float i = float(idx) / 32.0;
    float u = min(i, 2.0 - i);
    float f = u + u * u - u * u * u;
    return i <= 1.0 ? darks + (1.0 - darks) * f : brights + (1.0 - brights) * f;
}

static float3 grao(float3 v, int2 p, int2 T, int quadro) {
    float amp = q16(u.grainAmp);
    if (amp <= 0.0) return v;
    int2 cs = campos(quadro, u.grainHold);
    int campo = (p.y & 1) == 0 ? cs.x : cs.y;
    uint base0 = uint(int(4096.0 * (q16(u.seed) + 0.123)));
    uint n0 = base0 + uint(campo) * uint(T.x * T.y + 7) + uint(p.y * T.x + (p.x & ~3));
    uint desl = uint(8 * (p.x & 3));
    float3 ampC = float3(q16(u.grainAmpRed), q16(u.grainAmpGreen), q16(u.grainAmpBlue));
    float darks = q16(u.grainAmpDarks), brights = q16(u.grainAmpBrights);
    float3 o;
    for (int c = 0; c < 3; c++) {
        uint n = n0 + uint(10001 * (u.grainMono ? 1 : c));
        float b = float((rodadas(n) >> desl) & 255u);
        o[c] = v[c] + amp * ampC[c] * amplitudeDoGrao(v[c], darks, brights) * (b - 128.0) / 256.0;
    }
    return o;
}

static float3 corrigir(float3 c) {
    float y = dot(c, float3(5.0, 8.0, 3.0) / 16.0);
    c = y + (c - y) * q16(u.saturation);
    float3 L = floor(clamp(u.tintLights.rgb, 0.0, 1.0) * 255.0 + 0.5) / 255.0 * q16(u.scaleLights);
    float3 D = floor(clamp(u.tintDarks.rgb, 0.0, 1.0) * 255.0 + 0.5) / 255.0 + q16(u.offsetDarks);
    return c * sign(L) * max(abs(L) - D, 0.0) + D;
}

// ---------------------------------------------------------------------------------------------------------
// O desfoque: três caixas por eixo (a mesma conta do S_Glow), largura em px = quantidade · W/8.
// ---------------------------------------------------------------------------------------------------------
static int espelhar(int i, int n) {
    // Dentro do quadro o espelho é o próprio índice: sem a divisão inteira, que em todo tap custava caro (0.569.0)
    if (i >= 0 && i < n) return i;
    int p = 2 * n;
    i = i - (i / p) * p; if (i < 0) i += p;
    return i < n ? i : p - 1 - i;
}

static float4 lerCaixa(int passo, int2 p, int2 T) {
    p = int2(espelhar(p.x, T.x), espelhar(p.y, T.y));
    if (passo == 3) return q16(u.shakeAmplitude) > 0.0 ? imgB.read(uint2(p), uint(0)) : imgA.read(uint2(p), uint(0));
    if ((passo & 1) == 0) return ga.read(uint2(p), uint(0));
    return gb.read(uint2(p), uint(0));
}

static float4 caixa(int passo, int2 p, int2 T, bool vertical, int qual, float w) {
    w = clamp(w, 0.0, 3.0 * RAIO_MAX);
    float a = floor(w);
    float f = w - a;
    float r = floor((a + float(2 - qual)) / 3.0 + 1e-4);
    float cresce = abs(a - 3.0 * floor(a / 3.0 + 1e-4) - float(qual)) < 0.5 ? 1.0 : 0.0;
    f *= cresce;
    float dentro = (1.0 - f) / (2.0 * r + 1.0) + f / (2.0 * r + 3.0);
    float ponta = f / (2.0 * r + 3.0);
    int alcance = int(r) + (f > 0.0 ? 1 : 0);
    float4 soma = float4(0.0);
    for (int i = -alcance; i <= alcance; i++) {
        float d = abs(float(i));
        float peso = d <= r + 0.5 ? dentro : ponta;
        soma += peso * lerCaixa(passo, p + (vertical ? int2(0, i) : int2(i, 0)), T);
    }
    return soma;
}

// ---------------------------------------------------------------------------------------------------------
// A vinheta (simple_vignette) com o `static`: (hash4(y·W + x + quadro·W·H) & 0xfff)/4096.
// ---------------------------------------------------------------------------------------------------------
static float vinheta(int2 p, int2 T, int quadro) {
    float dark = q16(u.vignetteDarkness);
    if (dark <= 0.0) return 1.0;
    float W = float(T.x), H = float(T.y), a = H / W;
    float X = (float(p.x) + 0.5) / W * 2.0 - 1.0;
    float Y = ((float(p.y) + 0.5) / H * 2.0 - 1.0) * a;
    float soft = q16(u.vignetteSoftness);
    float mn = q16(u.vignetteRadius) - soft * 0.5;
    float lin = (length(float2(X, Y / q16(u.vignetteRelHeight))) - mn) / max(0.001, soft);
    float sm = (1.0 - cos(3.14159265 * clamp(lin, 0.0, 1.0))) * 0.5;
    float esc = lin > 0.5 ? max(lin, sm) : min(lin, sm);
    float g = lin + (esc - lin) * 0.4;
    uint n = uint(p.y * T.x + p.x) + uint(quadro) * uint(T.x * T.y);
    float st = float(rodadas(n) & 0xfffu) / 4096.0;
    float tex = clamp(1.0 - (g + (st - 0.5) / 256.0), 0.0, 1.0);
    return 1.0 + (tex - 1.0) * dark;
}

fragment float4 fx_sapphire_film_damage(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_film_damageParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> tabelas [[texture(1)]],
    texture2d<float> tempo [[texture(2)]],
    texture2d<float> imgA [[texture(3)]],
    texture2d<float> imgB [[texture(4)]],
    texture2d<float> ga [[texture(5)]],
    texture2d<float> gb [[texture(6)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 p = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
    float fps = eng.acFrameDuration > 0.0 ? 1.0 / eng.acFrameDuration : 30.0;
    int quadro = int(floor(eng.acTime * fps + 0.5));
    float a = float(T.y) / float(T.x);

    // ---- 0: os números do quadro ----
    if (eng.acPass == 0) {
        int i = int(__nv_fragCoord.x);
        if (i > 3 || __nv_fragCoord.y >= 1.0) { __nv_out = float4(0.0); return __nv_out; }   // só a linha 0, texels 0..3
        float v = 0.0;
        float sd = q16(u.seed);
        if (i == 0) {
            float r = q16(u.flickerRandAmp) * (warpNoise(eng.acTime, q16(u.flickerRandFreq), sd) - 0.5) * 2.0;
            float o = sin(6.28318531 * (eng.acTime * q16(u.flickerWaveFreq) - 0.25)) * q16(u.flickerWaveAmp);
            v = 1.0 + q16(u.flicker) * (r + o);
        } else if (i == 1 || i == 2) {
            float2 t = q16(u.shakeAmplitude) > 0.0 ? tremor(float(quadro), fps, a) : float2(0.0);
            v = i == 1 ? t.x : t.y;
        } else if (i == 3) {
            float r = q16(u.defocusRandAmp) * (warpNoise(eng.acTime, q16(u.defocusRandFreq), sd + 0.2) - 0.5) * 2.0;
            float o = sin(6.28318531 * (eng.acTime * q16(u.defocusWaveFreq) - 0.75)) * q16(u.defocusWaveAmp);
            v = q16(u.defocus) * (r + o);
        }
        __nv_out = guardar(v);
        return __nv_out;
    }

    // ---- 1: grão, saturação, tint (e o u.flicker, que é uma escala só) ----
    if (eng.acPass == 1) {
        float4 s = inputImg.read(uint2(p), uint(0));
        float3 c = corrigir(grao(s.rgb, p, T, quadro)) * lerTempo(0);
        __nv_out = float4(clamp(c, 0.0, 1.0) * s.a, s.a);
        return __nv_out;
    }

    // ---- 2: o tremor — y do Sapphire para cima, a faixa entre quadros preta e opaca ----
    if (eng.acPass == 2) {
        float ys = lerTempo(1);
        float Ys = a - (float(p.y) + 0.5) / float(T.y) * 2.0 * a;
        float wrap = (1.0 + q16(u.interframeBorder)) * 2.0 * a;
        float Yl = __nv_mod(Ys + ys + a, wrap) - a;
        float yl = (a - Yl) / (2.0 * a) * float(T.y) - 0.5;
        float y0 = floor(yl), f = yl - y0;
        int i0 = int(y0);
        float4 preto = float4(0.0, 0.0, 0.0, 1.0);
        float4 c0 = (i0 >= 0 && i0 < T.y) ? imgA.read(uint2(int2(p.x, i0)), uint(0)) : preto;
        float4 c1 = (i0 + 1 >= 0 && i0 + 1 < T.y) ? imgA.read(uint2(int2(p.x, i0 + 1)), uint(0)) : preto;
        __nv_out = mix(c0, c1, f);
        return __nv_out;
    }

    // ---- 3..8: o desfoque ----
    if (eng.acPass < 9) {
        float d = lerTempo(3);
        float px = float(T.x) / 8.0;
        bool vertical = eng.acPass >= 6;
        float w = vertical ? max(d + q16(u.shakeMotionBlur) * lerTempo(2), 0.0) * px : max(d, 0.0) * px;
        __nv_out = caixa(eng.acPass, p, T, vertical, vertical ? eng.acPass - 6 : eng.acPass - 3, w);
        return __nv_out;
    }

    // ---- 9: a vinheta e a saída ----
    bool desfocou = q16(u.defocus) > 0.0 || q16(u.shakeAmplitude) > 0.0;
    float4 c = desfocou ? gb.read(uint2(p), uint(0)) : imgA.read(uint2(p), uint(0));
    float3 rgb = clamp(c.rgb * vinheta(p, T, quadro), 0.0, 1.0);
    __nv_out = c.a > 0.0 ? float4(min(rgb / c.a, float3(1.0)), c.a) : float4(0.0);
    return __nv_out;
}
