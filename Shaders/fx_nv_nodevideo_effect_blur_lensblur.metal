// ---------------------------------------------------------------------------
// Desfoque de lente (NV)
// origem : assets/effects/nv-nodevideo-effect-blur-lensblur.xml
// id     : nv.effect.nodevideo-effect-blur-lensblur
// passes : 5
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_blur_lensblurParams {
    float raio;
    int forma;
    float lados;
    float raioInterno;
    float recorteInterno;
    float intensidade;
    float rotacao;
    int qualidade;
    int realces;
    float ganho;
    float saturacao;
    int fonteDoLimiar;
    float2 limiar;
};

// --- funcoes auxiliares do efeito
float3 linear(float3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c));
}
float3 srgb(float3 l) {
    l = clamp(l, 0.0, 1.0);
    return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l));
}
float4 texelDePe(sampler2D img) {
    int2 T = int2(int(img.get_width()), int(img.get_height()));
    int2 p = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
    if (eng.acEntradaDePe != 1) p.y = T.y - 1 - p.y;
    return img.read(uint2(p), uint(0));
}
// powf do C: x^0 = 1 (o pow do GLSL não define 0^0).
float potencia(float x, float e) { return e == 0.0 ? 1.0 : pow(max(x, 0.0), e); }

// ---- A pirâmide e a escolha do nível (CreatePyramid + Render) ----
const float PI = 3.14159265;
int raioNoNivel(int2 n) {
    int m = max(n.x, n.y);
    float r = clamp(u.raio, 0.0, 1.0) * 0.2 * float(m / 2);
    return min(int(r), 60);
}
// A contagem de deslocamentos de cada u.forma, pela área (o Node conta a lista).
float amostras(int R) {
    float N = float(2 * R + 1);
    int f = int(u.forma);
    float n = float(int(u.lados));
    if (f == 0) { float a = N / 4.0; return n * a * a * tan(PI / n); }
    if (f == 1) { float rc = float(int(float(R) / 1.5)); return PI * rc * rc; }
    if (f == 2) return PI * float(4 * R + 1) / sqrt(1.5);
    float ro = 0.2 * N, ri = ro * ro * clamp(u.raioInterno, 0.0, 1.0);
    return max(1.0, n * ro * ri * sin(PI / n) / 4.0);
}
int2 par(int2 v) { return v + int2(v.x % 2 == 1 ? 1 : 0, v.y % 2 == 1 ? 1 : 0); }
// O tamanho do nível escolhido; R sai junto.
int2 nivel(out int R) {
    int q = int(u.qualidade);
    int piso = q == 0 ? 128 : 256;
    int2 base = int2(eng.acTamanhoDaTela + 0.5);
    int2 n = base;
    int2 ultimo = base;
    int2 escolhido = int2(-1);
    int2 alto = base;          // Qualidade Alta: sem nenhum ≤ 640, o nível 0
    bool achouAlto = false;
    float teto = q == 0 ? 14745600.0 : 58982400.0;
    for (int k = 0; k < 12; k++) {
        if (k > 0) {
            if (min(ultimo.x, ultimo.y) <= piso) break;
            int d = 1 << k;
            int2 v = base / d;
            if (v.x < v.y) { if (v.x < piso) { v.y = int(float(v.y) / float(v.x) * float(piso)); v.x = piso; } }
            else if (v.y < piso) { v.x = int(float(v.x) / float(v.y) * float(piso)); v.y = piso; }
            n = par(v);
        }
        ultimo = n;
        if (!achouAlto && max(n.x, n.y) <= 640) { alto = n; achouAlto = true; }
        if (escolhido.x < 0 && float(n.x) * float(n.y) * amostras(raioNoNivel(n)) <= teto) escolhido = n;
    }
    int2 res = q == 2 ? alto : (escolhido.x < 0 ? ultimo : escolhido);
    R = raioNoNivel(res);
    return res;
}

// ---- As formas (GetDirs) ----
float2 girar(float2 p, float a) { float c = cos(a), s = sin(a); return float2(p.x * c - p.y * s, p.x * s + p.y * c); }
// AELensBlur.star: distância ao lado da estrela (negativa dentro), o ponto dobrado no 1º setor.
float estrela(float2 p, float r, float rf, float n) {
    float an = 2.0 * PI / n;
    float m = __nv_mod(__nv_atan(-p.x, -p.y) + PI + PI / n, 2.0 * PI);
    if (an < m) {
        float c = cos(an), s = sin(an), acc = an;
        for (int i = 0; i < 12; i++) {
            p = float2(c * p.x - s * p.y, s * p.x + c * p.y);
            acc += an;
            if (!(acc < m)) break;
        }
    }
    float h = an * 0.5;
    float2 b = float2(sin(h) * r * rf, cos(h) * r * rf - r);
    float2 a = float2(abs(p.x), p.y - r);
    float t = clamp(dot(b, a) / dot(b, b), 0.0, 1.0);
    float d = length(a - b * t);
    return b.x * a.y - b.y * a.x < 0.0 ? -d : d;
}
float coracao(float2 p, float N4) { return p.x * p.x + 1.5 * pow(p.y - 2.0 * sqrt(abs(p.x) + 1.0), 2.0) - N4; }
// O peso do deslocamento o (px do nível, Y para cima); < 0 = fora da u.forma.
float pesoDaForma(int2 o, int R) {
    int f = int(u.forma);
    float N = float(2 * R + 1);
    float corte = clamp(u.recorteInterno, 0.0, 1.0);
    float ang = u.rotacao * 0.017453292;
    if (f == 1) {
        float rc = float(int(float(R) / 1.5));
        float d2 = float(o.x * o.x + o.y * o.y);
        if (d2 > rc * rc) return -1.0;
        return potencia(sqrt(d2) / sqrt(rc * rc), corte * 10.0);
    }
    if (f == 2) {
        float N4 = float(4 * R + 1);
        float2 p = float2(o);
        float v = coracao(p, N4);
        if (v > 0.0) return -1.0;
        float2 g = 0.5 * float2(coracao(p + float2(1, 0), N4) - coracao(p - float2(1, 0), N4),
                            coracao(p + float2(0, 1), N4) - coracao(p - float2(0, 1), N4));
        float t = min(1.0 / (abs(v) / length(g)), 1.0);
        return potencia(t * t * (3.0 - 2.0 * t), corte * 5.0);
    }
    float2 p = girar(float2(o) * 2.0 - 1.0, ang);
    if (f == 0) {
        float sec = 2.0 * PI / float(int(u.lados));
        float a = __nv_atan(p.x, p.y) + PI;
        float d = floor(a / sec + 0.5) * sec - a;
        float q = 2.0 * length(p) * cos(d);
        if (q > N) return -1.0;
        return potencia(abs(q) / N, corte * 8.0);
    }
    float r = N * 0.2;
    float d = estrela(p, r, r * clamp(u.raioInterno, 0.0, 1.0), float(int(u.lados)));
    if (d > 0.0) return -1.0;
    return potencia(abs(d) / N, corte * 5.0);
}
// A caixa de cada u.forma (para não varrer a grade inteira).
int4 caixa(int R) {
    int f = int(u.forma);
    float N = float(2 * R + 1);
    if (f == 1) { int rc = int(float(R) / 1.5); return int4(-rc, -rc, rc, rc); }
    if (f == 2) {
        float N4 = float(4 * R + 1);
        int ex = int(ceil(sqrt(N4))) + 1;
        float ey = sqrt(N4 / 1.5);
        return int4(-ex, max(-2 * R, int(floor(-ey)) - 1), ex, min(2 * R, int(ceil(2.0 * sqrt(sqrt(N4) + 1.0) + ey)) + 1));
    }
    float e;
    if (f == 0) e = N / 4.0 / cos(PI / float(int(u.lados)));
    else { float r = 0.2 * N; e = max(r, r * r * clamp(u.raioInterno, 0.0, 1.0)) * 0.5; }
    int k = min(R + 1, int(ceil(e)) + 1);
    return int4(-k, -k, k, k);
}

// ---- LensBlurAccum + LensBlurAvg, juntando em vez de espalhar ----
float3 rgbParaHsv(float3 c) {
    float4 p = c.g >= c.b ? float4(c.gb, 0.0, -1.0 / 3.0) : float4(c.bg, -1.0, 0.666666687);
    float4 q = c.r >= p.x ? float4(c.r, p.yzx) : float4(p.xyw, c.r);
    float d = q.x - min(q.w, q.y);
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-4)), d / (q.x + 1e-4), q.x);
}
float3 hsvParaRgb(float3 h) {
    float3 k = clamp(abs(fract(h.x + float3(1.0, 0.666666687, 0.333333343)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
    return h.z * mix(float3(1.0), k, h.y);
}
float4 acumular() {
    int R;
    int2 n = nivel(R);
    float2 passo = 1.0 / float2(n);
    int4 bx = caixa(R);
    bool liga = u.realces;
    float2 lim = liga ? clamp(u.limiar, 0.0, 1.0) : float2(1.0);
    int fonte = int(u.fonteDoLimiar);
    float ganhoE = liga ? exp2(u.ganho) : 1.0;
    float satE = exp2(u.saturacao);
    float I = max(u.intensidade, 0.0);
    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int y = bx.y; y <= bx.w; y++) {
        for (int x = bx.x; x <= bx.z; x++) {
            int2 o = int2(x, y);
            float b = pesoDaForma(o, R);
            if (b < 0.0) continue;
            float2 s = in.acScreenNorm - float2(o) * passo;
            if (any(lessThan(s, float2(0.0))) || any(greaterThanEqual(s, float2(1.0)))) continue;
            float4 c = nivelRt.sample(__nv_smp, s);
            float4 c2 = c * c;
            float m = (c2.r + c2.g + c2.b) * 0.333333343;
            float W = (m > 0.0 ? exp2(log2(m) * I) : 0.0) * b;
            float3 hsv = rgbParaHsv(c2.rgb);
            float v = fonte == 0 ? hsv.x : (fonte == 1 ? hsv.y : hsv.z);
            if (lim.x < v && v < lim.y) c2.rgb = hsvParaRgb(float3(hsv.x, hsv.y * satE, hsv.z * ganhoE));
            soma += c2 * W;
            pesos += W;
        }
    }
    return pesos > 0.0 ? sqrt(soma / pesos) : float4(0.0);
}

fragment float4 fx_nv_nodevideo_effect_blur_lensblur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_blur_lensblurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> camadaRt [[texture(1)]],
    texture2d<float> metadeRt [[texture(2)]],
    texture2d<float> nivelRt [[texture(3)]],
    texture2d<float> acumRt [[texture(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        float4 c = texelDePe(inputImg);
        __nv_out = float4(linear(c.rgb) * c.a, c.a);
        return __nv_out;
    }
    // o Blit para o nível: o filtro linear no meio de cada 2 × 2
    if (eng.acPass == 1) { __nv_out = camadaRt.sample(__nv_smp, in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = metadeRt.sample(__nv_smp, in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = acumular(); return __nv_out; }
    // o passe do Node: o `_accumTex` pelo filtro linear (com uma amostra só, a camada como está)
    int R;
    int2 n = nivel(R);
    float2 q = eng.acEntradaDePe == 1 ? in.acScreenNorm : float2(in.acScreenNorm.x, 1.0 - in.acScreenNorm.y);
    int4 bx = caixa(R);
    bool umaSo = R == 0 || (bx.x == 0 && bx.z == 0 && bx.y == 0 && bx.w == 0);
    float4 o = umaSo ? camadaRt.sample(__nv_smp, q) : acumRt.sample(__nv_smp, q);
    o = clamp(o, 0.0, 1.0);
    __nv_out = o.a > 1e-5 ? float4(srgb(o.rgb / o.a), o.a) : float4(0.0);
    return __nv_out;
}
