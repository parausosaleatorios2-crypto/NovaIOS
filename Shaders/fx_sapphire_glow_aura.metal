// ---------------------------------------------------------------------------
// S_GlowAura
// origem : assets/effects/sapphire-glow-aura.xml
// id     : nova.effect.sglowaura
// passes : 8
// gerado por glsl2msl.py e consertado a mao no iOS (fix_msl.py): globais passados as funcoes
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
#include "NovaGLSLCompat.h"
using namespace metal;

struct sapphire_glow_auraParams {
    float brightness;
    float4 color;
    float outerBrightness;
    float glowSaturation;
    float threshold;
    float4 thresholdAddColor;
    float glowWidth;
    int subpixel;
    float frequency;
    float frequencyRed;
    float frequencyGreen;
    float frequencyBlue;
    float phase;
    float phaseSpeed;
    float phaseRed;
    float phaseGreen;
    float phaseBlue;
    float twist;
    int show;
    int combine;
    float affectAlpha;
    float glowFromAlpha;
    float glowUnderSource;
    float lightBackground;
    float sourceOpacity;
    float bgBrightness;
    int invertMatte;
    int opacity;
};

// --- funcoes auxiliares do efeito
constant float LARGURA_MAX = 720.0;     // a maior largura do desfoque, em px do buffer

// Os sliders do Sapphire chegam em ponto fixo 16.16 (medido no S_Hotspots: o 0,3 é 0,3000031 no AE).
static float fixo(float v) { return floor(v * 65536.0 + 0.5) / 65536.0; }

// ---- a camada do AE no buffer --------------------------------------------------------------
int2 gT;          // o buffer
int2 gN;          // a camada do AE dentro dele, em px
int2 gInicio;     // o canto da camada no buffer
float gEscala;     // a prévia reduzida (o Glow Width é em px da composição)

static void preparar(constant EngineUniforms& eng, texture2d<float> inputImg) {
    gT = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gN = clamp(int2(floor(max(eng.acCamada, float2(0.001)) * float2(gT) + 0.5)), int2(1), gT);
    gInicio = (gT - gN) / 2;
    gEscala = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
}

/** Espelha o índice na camada repetindo o pixel da borda (abc|cba), quantas voltas forem. */
static int espelhar(int i, int n) {
    if (i >= 0 && i < n) return i;
    int p = 2 * n;
    i = i - (i / p) * p; if (i < 0) i += p;
    return i < n ? i : p - 1 - i;
}

static int2 naCamada(int2 q) {
    return gInicio + int2(espelhar(q.x, gN.x), espelhar(q.y, gN.y));
}

// ---- um float inteiro nos 4 bytes do texel ---------------------------------------------------
static float4 guardar(float f) {
    uint b = as_type<uint>(f);
    return float4(float(b & 255u), float((b >> 8u) & 255u), float((b >> 16u) & 255u), float(b >> 24u)) / 255.0;
}

static float lido(float4 c) {
    uint4 b = uint4(floor(c * 255.0 + 0.5));
    return as_type<float>(b.r | (b.g << 8u) | (b.b << 16u) | (b.a << 24u));
}

// ---- a fonte --------------------------------------------------------------------------------
// Opacity (medido no S_Hotspots): Normal (1) trabalha na cor pré-multiplicada; All Opaque (0) e As Premult
// (2), na cor reta.
static float4 entrada(int2 p, constant sapphire_glow_auraParams& u, texture2d<float> inputImg) {
    float4 s = inputImg.read(uint2(p), uint(0));
    return u.opacity == 1 ? float4(s.rgb * s.a, s.a) : s;
}

static bool temMatte(texture2d<float> matteImg) { return int2(int(matteImg.get_width()), int(matteImg.get_height())).x > 1; }
static bool temFundo(texture2d<float> bgImg) { return int2(int(bgImg.get_width()), int(bgImg.get_height())).x > 1; }

// As camadas de entrada no lugar delas na composição, pré-multiplicadas.
static float4 camada(texture2d<float> t, int2 p, sampler __nv_smp) {
    float4 c = t.sample(__nv_smp, (float2(p) + 0.5) / float2(gT));
    return float4(c.rgb * c.a, c.a);
}

static float3 limiarTh(constant sapphire_glow_auraParams& u) { return fixo(u.threshold) + floor(u.thresholdAddColor.rgb * 255.0 + 0.5) / 255.0; }

// bw = max(0, monochrome(s − th)), na ordem do plugin
static float bw(int2 p, constant sapphire_glow_auraParams& u, sampler __nv_smp, texture2d<float> inputImg, texture2d<float> matteImg) {
    float4 e = entrada(p, u, inputImg);
    float3 s = mix(e.rgb, float3(e.a), fixo(u.glowFromAlpha));
    // a Matte (medido): a cor pré-multiplicada dela, canal a canal, multiplica a fonte antes de tudo
    if (temMatte(matteImg)) {
        float3 m = camada(matteImg, p, __nv_smp).rgb;
        s *= u.invertMatte ? 1.0 - m : m;
    }
    float3 c = s - limiarTh(u);
    return max(0.0, (0.3125 * c.r + 0.5 * c.g) + 0.1875 * c.b);
}

static float escalaK(constant sapphire_glow_auraParams& u) {
    float3 th = limiarTh(u);
    return 4.0 / max(0.01, 1.0 - min(th.r, min(th.g, th.b)));
}

// A largura do desfoque em px do buffer.
static float larguraPx(constant sapphire_glow_auraParams& u) {
    float w = fixo(u.glowWidth) * gEscala;
    if (!u.subpixel) w = floor(w + 0.5);
    return clamp(w, 0.0, LARGURA_MAX);
}

/**
 * Uma das três caixas (`qual` = 0, 1, 2) de um eixo, lendo o passe anterior. Largura inteira W -> raios
 * (W + 2 − qual) div 3, que somam W; com a largura quebrada só a caixa (⌊W⌋ mod 3) cresce, e ela leva as duas
 * pontas com o peso da fração: (1 − f)·caixa(r) + f·caixa(r + 1).
 */
static float caixa(int2 q, bool emX, int qual, bool deA, constant sapphire_glow_auraParams& u, texture2d<float> ga, texture2d<float> gb) {
    float w = larguraPx(u);
    int a = int(floor(w));
    float f = w - float(a);
    int r = (a + 2 - qual) / 3;
    bool cresce = f > 0.0 && a - (a / 3) * 3 == qual;
    float soma = 0.0;
    for (int d = -r; d <= r; d++) {
        int2 p = naCamada(q + (emX ? int2(d, 0) : int2(0, d)));
        soma += lido(deA ? ga.read(uint2(p), uint(0)) : gb.read(uint2(p), uint(0)));
    }
    float n = float(2 * r + 1);
    if (!cresce) return soma / n;
    int2 e = naCamada(q - (emX ? int2(r + 1, 0) : int2(0, r + 1)));
    int2 g = naCamada(q + (emX ? int2(r + 1, 0) : int2(0, r + 1)));
    float pontas = deA ? lido(ga.read(uint2(e), uint(0))) + lido(ga.read(uint2(g), uint(0))) : lido(gb.read(uint2(e), uint(0))) + lido(gb.read(uint2(g), uint(0)));
    return soma * ((1.0 - f) / n + f / (n + 2.0)) + pontas * (f / (n + 2.0));
}

static float picEm(int2 q, texture2d<float> ga) { return lido(ga.read(uint2(gInicio + q), uint(0))); }

// grad_direction (0x180b72be0): diferença central; na borda da camada, um lado só vezes 2.
static float direcao(int2 q, float p0, constant EngineUniforms& eng, texture2d<float> ga) {
    float gx, gy;
    if (gN.x < 2) gx = 0.0;
    else if (q.x == 0) gx = (picEm(q + int2(1, 0), ga) - p0) * 2.0;
    else if (q.x == gN.x - 1) gx = (p0 - picEm(q - int2(1, 0), ga)) * 2.0;
    else gx = picEm(q + int2(1, 0), ga) - picEm(q - int2(1, 0), ga);
    // a linha de CIMA da imagem menos a de baixo; no buffer de conteúdo a linha 0 é o topo, numa cena
    // guardada de pé (eng.acEntradaDePe) é a base
    int cima = eng.acEntradaDePe == 1 ? 1 : -1;
    int yc = q.y + cima, yb = q.y - cima;
    if (gN.y < 2) gy = 0.0;
    else if (yc < 0 || yc >= gN.y) gy = (p0 - picEm(int2(q.x, yb), ga)) * 2.0;
    else if (yb < 0 || yb >= gN.y) gy = (picEm(int2(q.x, yc), ga) - p0) * 2.0;
    else gy = picEm(int2(q.x, yc), ga) - picEm(int2(q.x, yb), ga);
    if (gx * gx + gy * gy < 1e-8) return 0.0;
    float t = __nv_atan(gy, gx) * 0.15915494;
    return t - floor(t);
}

static float4 tela(float4 a, float4 b) { return a + b - a * b; }
static float tela(float a, float b) { return a + b - a * b; }

// Combine (glow_rgba_combine; medido: o Overlay vale nos quatro canais, decidido pela base)
static float4 combinar(float4 g, float4 b, constant sapphire_glow_auraParams& u) {
    if (u.combine == 4) return mix(2.0 * g * b, 1.0 - 2.0 * (1.0 - g) * (1.0 - b), float4(greaterThanEqual(b, float4(0.5))));
    if (u.combine == 3) return float4(abs(g.rgb - b.rgb), tela(g.a, b.a));
    if (u.combine == 2) return tela(g, b);
    if (u.combine == 1) return g + b;
    return g * b;
}

fragment float4 fx_sapphire_glow_aura(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_glow_auraParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> ga [[texture(1)]],
    texture2d<float> gb [[texture(2)]],
    texture2d<float> bgImg [[texture(3)]],
    texture2d<float> matteImg [[texture(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar(eng, inputImg);
    int2 t = min(int2(floor(in.acScreenNorm * float2(gT))), gT - int2(1));
    int2 q = t - gInicio;
    bool fora = any(lessThan(q, int2(0))) || any(greaterThanEqual(q, gN));

    if (eng.acPass == 0) {
        __nv_out = fora ? float4(0.0) : guardar(bw(t, u, __nv_smp, inputImg, matteImg));
        return __nv_out;
    }
    if (eng.acPass <= 6) {
        // 1..3 em x, 4..6 em y; os passes ímpares leem ga, os pares gb
        float c = fora ? 0.0 : caixa(q, eng.acPass <= 3, (eng.acPass - 1) - ((eng.acPass - 1) / 3) * 3, (eng.acPass & 1) == 1, u, ga, gb);
        __nv_out = guardar(eng.acPass == 6 ? escalaK(u) * c : c);
        return __nv_out;
    }

    float4 s = inputImg.read(uint2(t), uint(0));
    if (fora) {
        __nv_out = s;
        return __nv_out;
    }
    float4 S = entrada(t, u, inputImg);
    float4 r;
    if (u.show == 1) {
        r = float4(float3(bw(t, u, __nv_smp, inputImg, matteImg) * escalaK(u)), 1.0);
    } else {
        float p0 = picEm(q, ga);
        // a largura interna do Sapphire (medido): px ÷ (largura da camada ÷ 8)
        float wn = fixo(u.glowWidth) / (float(gN.x) / gEscala / 8.0);
        float a = direcao(q, p0, eng, ga) + p0 * (wn * fixo(u.twist) / 4.0);
        float3 ph = fixo(u.phase) + float3(fixo(u.phaseRed), fixo(u.phaseGreen), fixo(u.phaseBlue)) + fixo(u.phaseSpeed) * eng.acTime;
        float3 fq = fixo(u.frequency) * float3(fixo(u.frequencyRed), fixo(u.frequencyGreen), fixo(u.frequencyBlue));
        float3 g = 0.5 + 0.5 * sin(6.2831853 * (a * fq - ph));
        float sat = fixo(u.glowSaturation);
        float luma = (0.3125 * g.r + 0.5 * g.g) + 0.1875 * g.b;
        g = g * sat + luma * (1.0 - sat);
        float3 luz = g * min(1.0, p0 * (4.0 * fixo(u.outerBrightness) * wn)) * (fixo(u.brightness) * u.color.rgb);

        // glow_rgba_combine (da definição; medido: um canal negativo da luz não escurece)
        float claro = fixo(u.lightBackground);
        bool fundo = temFundo(bgImg);
        float4 B = fundo ? camada(bgImg, t, __nv_smp) : float4(0.0);
        float3 glowB = max(luz, float3(0.0)) * (1.0 + (2.0 * (fundo ? B.rgb : S.rgb) - 1.0) * claro);
        float4 gl = float4(glowB, max(glowB.r, max(glowB.g, glowB.b)) * fixo(u.affectAlpha));
        float4 src = S * fixo(u.sourceOpacity);
        float4 back = float4(B.rgb * fixo(u.bgBrightness), B.a);
        float4 fonteNoFundo = src + back * (1.0 - src.a);
        float4 sobreFonte = combinar(gl, fonteNoFundo, u);
        float4 sobreFundo = combinar(gl, back, u);
        float4 x = mix(sobreFonte, fonteNoFundo + gl, claro);
        float4 y = mix(sobreFundo, back + gl, claro);
        y = src + y * (1.0 - src.a);
        r = mix(x, y, tela(fixo(u.glowUnderSource), claro));
    }
    r = clamp(r, 0.0, 1.0);
    if (u.opacity == 0) r.a = 1.0;
    // As Premult (medido): o resultado pré-multiplicado sai como cor reta
    float3 reta = u.opacity == 2 ? r.rgb : (r.a > 0.0 ? min(r.rgb / r.a, float3(1.0)) : float3(0.0));
    // a saída em níveis inteiros, arredondada como o AE de 8 bpc
    __nv_out = float4(floor(reta * 255.0 + 0.5) / 255.0, r.a);
    return __nv_out;
}
