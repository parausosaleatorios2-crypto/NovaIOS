// ---------------------------------------------------------------------------
// Glitchify (iOS, GPU)
// origem : Resources/effects/glitchify.xml   id: nova.effect.glitchify
//
// No Android o Glitchify roda na CPU (model/Glitchify.kt, porte bit a bit do
// plugin). Aqui e um shader proprio com os MESMOS controles e grupos: motor de
// ruido (fbm com Octaves/Lacunarity/Gain, quantizado em degraus, corte e
// agrupamento), Transform Glitch (posicao/escala/crop que tremem), Channel Glitch
// (split de canais e escala de um canal), Color Glitch, Image Glitch (blocos
// deslocados e pixel streak), Compression Glitch (blocos 8x8 e dither) e a
// Transition (Completion/Softness por canal). Escrito a mao; gerado o struct.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct glitchifyParams {
    float amount;
    float speed;
    float seed;
    float completion;
    float softness;
    int transitionChannel;
    float transformSpeed;
    float2 position;
    float positionWiggle;
    float scale;
    float scaleWiggle;
    float2 cropTopLeft;
    float2 cropBottomRight;
    float cropWiggle;
    float opacity;
    int transferMode;
    int compositeOver;
    int channelEnable;
    int splitChannel;
    float splitH;
    float splitV;
    float splitSpeed;
    float scaleAmount;
    int scaleChannel;
    int scaleVertical;
    float scaleOffset;
    float scaleSpeed;
    int fillGaps;
    int channelMode;
    int colorEnable;
    float colorOffset;
    float colorAmount;
    float colorOpacity;
    int colorMode;
    int imageEnable;
    float streak;
    int verticalSort;
    float blockAmount;
    float blockSpeed;
    float blockWidth;
    float blockHeight;
    int blockDirection;
    int blockMode;
    int compressionEnable;
    float compressionMultiplier;
    float ditherAmount;
    float jpegAmount;
    int showNoise;
    float gain;
    float lacunarity;
    float octaves;
    int repeatEdge;
    int sigmoid;
    float quantization;
    int useNoise;
    float noiseCutoff;
    float grouping;
    float wiggleSteps;
    float sliceAmount;
};

static float gl_hash(float2 p, float s) {
    p = fract(p * float2(123.34, 456.21) + s * 0.1234);
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
static float gl_hash1(float n) { return fract(sin(n * 12.9898 + 4.1414) * 43758.5453); }

static float gl_valor(float2 p, float s) {
    float2 i = floor(p), f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = gl_hash(i, s), b = gl_hash(i + float2(1, 0), s);
    float c = gl_hash(i + float2(0, 1), s), d = gl_hash(i + float2(1, 1), s);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

/** O motor de ruido do Glitchify: fbm quantizado (degraus, opcionalmente sigmoides). */
static float gl_ruido(float2 p, float t, constant glitchifyParams& u) {
    int oit = clamp(int(u.octaves + 0.5), 1, 6);
    float lac = max(u.lacunarity * 0.2, 1.01);
    float amp = 1.0, soma = 0.0, norma = 0.0, fr = 1.0;
    for (int i = 0; i < 6; i++) {
        if (i >= oit) break;
        soma += amp * gl_valor(p * fr + float2(t * 0.37 * fr, -t * 0.23), u.seed + float(i) * 17.0);
        norma += amp;
        amp /= max(u.gain, 0.01);
        fr *= lac;
    }
    float n = soma / max(norma, 1e-4);
    float deg = max(u.quantization, 1.0);
    float q = floor(n * deg) / deg;
    if (u.sigmoid != 0) {
        float f = fract(n * deg);
        q += smoothstep(0.35, 0.65, f) / deg;
    }
    return clamp(q, 0.0, 1.0);
}

static float gl_lum(float3 c) { return dot(c, float3(0.299, 0.587, 0.114)); }
static float3 gl_clip(float3 c) {
    float l = gl_lum(c), n = min(c.r, min(c.g, c.b)), x = max(c.r, max(c.g, c.b));
    if (n < 0.0) c = l + (c - l) * l / max(l - n, 1e-6);
    if (x > 1.0) c = l + (c - l) * (1.0 - l) / max(x - l, 1e-6);
    return c;
}
static float3 gl_comLum(float3 c, float l) { return gl_clip(c + (l - gl_lum(c))); }
static float gl_sat(float3 c) { return max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b)); }
static float3 gl_comSat(float3 c, float s) {
    float n = min(c.r, min(c.g, c.b)), x = max(c.r, max(c.g, c.b));
    return x > n ? (c - n) * s / (x - n) : float3(0.0);
}

/** Os Transfer Modes do AE (indices do menu do efeito). b = fundo, s = camada do glitch. */
static float4 gl_misturar(int m, float4 B, float4 S, float op) {
    float3 b = B.rgb, s = S.rgb, r;
    switch (m) {
    case 1: return mix(B, S, op);                                  // Copy
    case 2: return mix(B, B.a > 0.5 ? B : S, op);                  // Behind
    case 3: return mix(B, S.a > 0.0 ? S : B, op);                  // In Front
    case 4: r = min(b, s); break;
    case 5: r = b * s; break;
    case 6: case 7: r = select(1.0 - min(1.0, (1.0 - b) / max(s, 1e-5)), float3(0.0), s <= 0.0); break;
    case 8: r = max(b + s - 1.0, 0.0); break;
    case 9: r = gl_lum(s) < gl_lum(b) ? s : b; break;
    case 10: case 15: r = min(b + s, 1.0); break;
    case 11: r = max(b, s); break;
    case 12: r = 1.0 - (1.0 - b) * (1.0 - s); break;
    case 13: case 14: r = select(min(1.0, b / max(1.0 - s, 1e-5)), float3(1.0), s >= 1.0); break;
    case 16: r = gl_lum(s) > gl_lum(b) ? s : b; break;
    case 17: r = select(1.0 - 2.0 * (1.0 - b) * (1.0 - s), 2.0 * b * s, b < 0.5); break;
    case 18: {
        float3 d = select(sqrt(b), ((16.0 * b - 12.0) * b + 4.0) * b, b <= 0.25);
        r = select(b + (2.0 * s - 1.0) * (d - b), b - (1.0 - 2.0 * s) * b * (1.0 - b), s <= 0.5);
        break;
    }
    case 19: r = select(1.0 - 2.0 * (1.0 - b) * (1.0 - s), 2.0 * b * s, s < 0.5); break;
    case 20: r = clamp(b + 2.0 * s - 1.0, 0.0, 1.0); break;
    case 21: r = select(min(1.0, b / max(2.0 * (1.0 - s), 1e-5)), 1.0 - min(1.0, (1.0 - b) / max(2.0 * s, 1e-5)), s < 0.5); break;
    case 22: r = select(max(b, 2.0 * s - 1.0), min(b, 2.0 * s), s < 0.5); break;
    case 23: r = step(float3(1.0), b + s); break;
    case 24: case 25: r = abs(b - s); break;
    case 26: r = b + s - 2.0 * b * s; break;
    case 27: r = max(b - s, 0.0); break;
    case 28: r = min(b / max(s, 1e-5), 1.0); break;
    case 29: r = gl_comLum(gl_comSat(s, gl_sat(b)), gl_lum(b)); break;
    case 30: r = gl_comLum(gl_comSat(b, gl_sat(s)), gl_lum(b)); break;
    case 31: r = gl_comLum(s, gl_lum(b)); break;
    case 32: r = gl_comLum(b, gl_lum(s)); break;
    default: r = s; break;                                         // Normal
    }
    float a = S.a * op;
    return float4(mix(b, r, a), max(B.a, a));
}

static float4 gl_amostra(texture2d<float> t, sampler sm, float2 uv, bool repete) {
    if (!repete && (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0)) return float4(0.0);
    return t.sample(sm, clamp(uv, 0.0, 1.0));
}

static float gl_canal(float4 c, int k, float ruido) {
    float mx = max(c.r, max(c.g, c.b)), mn = min(c.r, min(c.g, c.b));
    switch (k) {
    case 0: return c.r;
    case 1: return c.g;
    case 2: return c.b;
    case 3: return c.a;
    case 4: return gl_lum(c.rgb);
    case 5: return (mx + mn) * 0.5;
    case 6: {
        float d = mx - mn;
        if (d < 1e-5) return 0.0;
        float h = mx == c.r ? (c.g - c.b) / d : (mx == c.g ? 2.0 + (c.b - c.r) / d : 4.0 + (c.r - c.g) / d);
        return fract(h / 6.0);
    }
    case 7: return mx > 0.0 ? (mx - mn) / mx : 0.0;
    default: return ruido;
    }
}

fragment float4 fx_glitchify(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant glitchifyParams&  u    [[buffer(1)]],
    sampler             smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float2 res = max(eng.acResolution, float2(1.0));
    float4 original = inputImg.sample(smp, uv);
    bool repete = u.repeatEdge != 0;

    float A = clamp(u.amount / 100.0, 0.0, 2.0);
    float t = eng.acTime * (u.speed / 50.0) * 4.0;
    float tq = floor(t * max(u.wiggleSteps, 1.0)) / max(u.wiggleSteps, 1.0);

    // motor de ruido, em celulas agrupadas (Grouping Factor)
    float cel = max(u.grouping, 1.0) * 8.0;
    float2 pc = uv * res / cel;
    float n = gl_ruido(pc * float2(0.25, 1.0), t, u);
    float corte = clamp(u.noiseCutoff / 100.0, 0.0, 1.0);
    float ativo = u.useNoise != 0 ? smoothstep(corte, corte + 0.02, n) * A : A;
    if (u.showNoise != 0) return float4(float3(n), 1.0);

    float4 cor = original;

    // ---- Transform Glitch: posicao, escala e crop que tremem ----
    {
        float ts = tq * max(u.transformSpeed, 0.0);
        float2 rnd = float2(gl_hash1(floor(ts) + u.seed), gl_hash1(floor(ts) + u.seed + 7.0)) - 0.5;
        float2 desloc = (u.position - 0.5) + rnd * (u.positionWiggle / res);
        float esc = max((u.scale + (gl_hash1(floor(ts) + u.seed + 3.0) - 0.5) * u.scaleWiggle) / 100.0, 0.001);
        float2 q = (uv - 0.5 - desloc) / esc + 0.5;
        float2 cw = (float2(gl_hash1(floor(ts) + 11.0), gl_hash1(floor(ts) + 13.0)) - 0.5) * (u.cropWiggle / res);
        float2 tl = u.cropTopLeft + cw, br = u.cropBottomRight - cw;
        float4 tr = (q.x < tl.x || q.y < tl.y || q.x > br.x || q.y > br.y) ? float4(0.0) : gl_amostra(inputImg, smp, q, repete);
        bool mexeu = any(abs(desloc) > 1e-5) || abs(esc - 1.0) > 1e-4 || any(tl > 1e-4) || any(br < 0.9999);
        if (mexeu) {
            float4 tm = gl_misturar(u.transferMode, cor, tr, clamp(u.opacity / 100.0, 0.0, 1.0));
            cor = u.compositeOver != 0 ? gl_misturar(0, cor, tm, 1.0) : tm;
        }
    }

    // ---- Image Glitch: blocos deslocados e pixel streak ----
    if (u.imageEnable != 0 && ativo > 0.0) {
        float2 bloco = max(float2(u.blockWidth, u.blockHeight), float2(2.0));
        float tb = tq * max(u.blockSpeed / 50.0, 0.0);
        float2 id = floor(uv * res / bloco);
        float r = gl_hash(id + floor(tb), u.seed);
        float liga = step(1.0 - clamp(u.blockAmount / 100.0, 0.0, 1.0) * ativo, r);
        if (liga > 0.0) {
            float2 d = float2(0.0);
            float k = (gl_hash(id * 1.7 + floor(tb), u.seed + 5.0) - 0.5) * 0.25 * A;
            if (u.blockDirection == 0 || u.blockDirection == 2) d.x = k;
            if (u.blockDirection == 1 || u.blockDirection == 2) d.y = k * 0.5;
            float4 b = gl_amostra(inputImg, smp, uv + d, repete);
            cor = gl_misturar(u.blockMode, cor, b, 1.0);
        }
        // pixel streak: nas linhas sorteadas, o pixel vira o do comeco do trecho
        float sk = clamp(u.streak / 100.0, 0.0, 1.0) * ativo;
        if (sk > 0.0) {
            float eixo = u.verticalSort != 0 ? uv.x : uv.y;
            float linha = floor(eixo * (u.verticalSort != 0 ? res.x : res.y) / 2.0);
            float rl = gl_hash(float2(linha, floor(tb)), u.seed + 9.0);
            if (rl < sk * 0.35) {
                float ini = gl_hash(float2(linha, floor(tb) + 1.0), u.seed + 2.0);
                float2 q = uv;
                if (u.verticalSort != 0) q.y = min(q.y, ini); else q.x = min(q.x, ini);
                cor = mix(cor, gl_amostra(inputImg, smp, q, true), 0.85);
            }
        }
    }

    // ---- Channel Glitch: split dos canais e escala de um canal ----
    if (u.channelEnable != 0 && ativo > 0.0) {
        float vel = 1.0 + u.splitSpeed * 0.5;
        float jit = (gl_hash1(floor(tq * vel) + u.seed + 21.0) - 0.5) * 2.0;
        float2 d = float2(u.splitH, u.splitV) / 100.0 * 0.03 * A * (0.6 + 0.4 * jit);
        float4 a = gl_amostra(inputImg, smp, uv + d, repete);
        float4 b = gl_amostra(inputImg, smp, uv - d, repete);
        float4 sp = cor;
        switch (u.splitChannel) {
        case 0: sp.r = a.r; sp.gb = b.gb; break;                   // Red-Cyan
        case 1: sp.g = a.g; sp.rb = b.rb; break;                   // Green-Magenta
        case 2: sp.b = a.b; sp.rg = b.rg; break;                   // Blue-Yellow
        default: { float l = gl_lum(a.rgb) - gl_lum(cor.rgb); sp.rgb = cor.rgb + l; break; }
        }
        // escala de um canal ao longo do eixo (com offset)
        float sa = u.scaleAmount / 100.0 * A;
        if (sa > 0.0) {
            float off = u.scaleOffset / 100.0;
            float ts = 1.0 + sa * 0.3 * sin(tq * u.scaleSpeed + u.seed);
            float2 q = uv;
            if (u.scaleVertical != 0) q.y = (q.y - off) / ts + off; else q.x = (q.x - off) / ts + off;
            float4 c2 = gl_amostra(inputImg, smp, q, repete || u.fillGaps != 0);
            float v = gl_canal(c2, u.scaleChannel == 0 ? 4 : (u.scaleChannel == 1 ? 5 : (u.scaleChannel == 2 ? 6 : (u.scaleChannel == 3 ? 7 : u.scaleChannel - 4))), n);
            if (u.scaleChannel >= 4 && u.scaleChannel <= 6) sp[u.scaleChannel - 4] = v;
            else sp.rgb = gl_comLum(sp.rgb, v);
        }
        cor = gl_misturar(u.channelMode, cor, sp, 1.0);
    }

    // ---- Color Glitch: cores deslocadas em celulas ----
    if (u.colorEnable != 0 && ativo > 0.0) {
        float2 id = floor(uv * res / (cel * 2.0));
        float r = gl_hash(id + floor(tq * 2.0), u.seed + 31.0);
        if (r < clamp(u.colorAmount / 100.0, 0.0, 1.0) * ativo) {
            float h = u.colorOffset / 100.0 + r;
            float3 alt = fract(cor.rgb + float3(h, h * 1.7, h * 2.3));
            cor = gl_misturar(u.colorMode, cor, float4(alt, cor.a), clamp(u.colorOpacity / 100.0, 0.0, 1.0));
        }
    }

    // ---- Compression Glitch: blocos 8x8 e dither ----
    if (u.compressionEnable != 0 && ativo > 0.0) {
        float m = max(u.compressionMultiplier / 50.0, 0.01);
        float bl = 8.0 * m;
        float2 id = floor(uv * res / bl);
        if (gl_hash(id + floor(tq), u.seed + 41.0) < clamp(u.jpegAmount / 100.0, 0.0, 1.0) * ativo) {
            float2 c = (id + 0.5) * bl / res;
            float4 media = gl_amostra(inputImg, smp, c, true);
            float niveis = mix(32.0, 4.0, clamp(u.jpegAmount / 100.0, 0.0, 1.0));
            cor.rgb = mix(cor.rgb, floor(media.rgb * niveis + 0.5) / niveis, 0.8);
        }
        float dz = clamp(u.ditherAmount / 100.0, 0.0, 1.0) * ativo;
        if (dz > 0.0) {
            float d = gl_hash(floor(uv * res), u.seed + floor(tq * 8.0)) - 0.5;
            float niveis = mix(64.0, 6.0, dz);
            cor.rgb = floor(cor.rgb * niveis + d) / niveis;
        }
    }

    cor = clamp(cor, 0.0, 1.0);

    // ---- Transition: Completion e Softness pelo canal escolhido ----
    float comp = clamp(u.completion / 100.0, 0.0, 1.0);
    if (comp > 0.0) {
        float v = gl_canal(original, u.transitionChannel, n);
        float s = max(u.softness / 100.0, 0.001);
        float m = smoothstep(comp - s, comp + s * 0.01, v + s * (1.0 - comp));
        cor = mix(cor, original, 1.0 - m);
    }
    return cor;
}
