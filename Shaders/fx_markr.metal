// ---------------------------------------------------------------------------
// MARKr
// origem : assets/effects/markr.xml
// id     : nova.effect.markr
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct markrParams {
    int style;
    float4 color;
    float thickness;
    float xPadding;
    float yOffset;
    float progress;
    int animate;
    float duration;
};

// --- funcoes auxiliares do efeito
// O ease dos dois quadros-chave do MARKr: velocidade 0, influência 80% na saída
// do primeiro e 33% na entrada do segundo = bezier (0,8; 0) (0,67; 1).
static float easeDoMarkr(float u) {
    if (u <= 0.0) return 0.0;
    if (u >= 1.0) return 1.0;
    float lo = 0.0, hi = 1.0, s = u;
    for (int i = 0; i < 24; i++) {
        s = 0.5 * (lo + hi);
        float r = 1.0 - s;
        float x = 3.0 * r * r * s * 0.8 + 3.0 * r * s * s * 0.67 + s * s * s;
        if (x < u) lo = s; else hi = s;
    }
    float r = 1.0 - s;
    return 3.0 * r * s * s + s * s * s;
}

static float caixa(float2 p, float2 a, float2 b) {
    // Distância com sinal a um retângulo [a, b] (negativa dentro).
    float2 d = max(a - p, p - b);
    return max(d.x, d.y);
}

static float cobertura(float d) { return clamp(0.5 - d, 0.0, 1.0); }

/** Distância com sinal a um triângulo (Inigo Quilez, sdTriangle). */
static float triangulo(float2 p, float2 p0, float2 p1, float2 p2) {
    float2 e0 = p1 - p0, e1 = p2 - p1, e2 = p0 - p2;
    float2 v0 = p - p0, v1 = p - p1, v2 = p - p2;
    float2 pq0 = v0 - e0 * clamp(dot(v0, e0) / max(dot(e0, e0), 1e-9), 0.0, 1.0);
    float2 pq1 = v1 - e1 * clamp(dot(v1, e1) / max(dot(e1, e1), 1e-9), 0.0, 1.0);
    float2 pq2 = v2 - e2 * clamp(dot(v2, e2) / max(dot(e2, e2), 1e-9), 0.0, 1.0);
    float s = sign(e0.x * e2.y - e0.y * e2.x);
    float2 d = min(min(float2(dot(pq0, pq0), s * (v0.x * e0.y - v0.y * e0.x)),
                     float2(dot(pq1, pq1), s * (v1.x * e1.y - v1.y * e1.x))),
                     float2(dot(pq2, pq2), s * (v2.x * e2.y - v2.y * e2.x)));
    return -sqrt(d.x) * sign(d.y);
}

// A curva do Scribble, em unidades da caixa dele (u·W, v·H).
static float2 bez(float2 a, float2 c1, float2 c2, float2 b, float t) {
    float r = 1.0 - t;
    return r * r * r * a + 3.0 * r * r * t * c1 + 3.0 * r * t * t * c2 + t * t * t * b;
}

const int N_CURVA = 24;

static float2 pontoDoRabisco(int i, float2 o, float2 sz) {
    // 0: P0, 1: P1, 2..(N_CURVA+1): o trecho curvo P1→P2, depois P3.
    float2 q;
    if (i == 0) q = float2(0.0, 0.0);
    else if (i == 1) q = float2(1.0, 0.0217);
    else if (i <= N_CURVA + 1) {
        float t = float(i - 1) / float(N_CURVA);
        q = bez(float2(1.0, 0.0217), float2(0.3786, 0.4752), float2(0.4408, 0.5218), float2(0.4408, 0.5218), t);
    } else q = float2(0.9652, 1.0);
    return o + q * sz;
}

/** Distância com sinal ao traço do Scribble (com o Trim e o Taper do MARKr). */
static float rabisco(float2 p, float2 o, float2 sz, float th, float prog) {
    const int N = N_CURVA + 3;
    float total = 0.0;
    float2 a = pontoDoRabisco(0, o, sz);
    for (int i = 1; i < N; i++) {
        float2 b = pontoDoRabisco(i, o, sz);
        total += length(b - a);
        a = b;
    }
    float visivel = total * prog;
    if (visivel <= 0.0) return 1e6;
    float d = 1e6;
    float acc = 0.0;
    float2 dirAnterior = float2(0.0);
    a = pontoDoRabisco(0, o, sz);
    for (int i = 1; i < N; i++) {
        float2 b = pontoDoRabisco(i, o, sz);
        float len = length(b - a);
        if (acc >= visivel) break;
        // O pedaço visível deste segmento.
        float fim = min(len, visivel - acc);
        if (len > 1e-5) {
            float2 dir = (b - a) / len;
            float2 nrm = float2(-dir.y, dir.x);
            float t = dot(p - a, dir);
            float s = acc + clamp(t, 0.0, fim);
            // Taper: largura cheia até 70% do comprimento visível, depois afina até 0.
            float w = th * clamp((visivel - s) / (0.3 * visivel), 0.0, 1.0);
            // Ponta reta (Line Cap = Butt) no começo do traço e dos dois lados da
            // quina P1; nas juntas suaves da curva, o segmento redondo emenda sem fresta.
            bool retoAntes = i == 1 || i == 2;
            bool retoDepois = i == 1;
            float tc = clamp(t, 0.0, fim);
            float dd = length(p - (a + dir * tc)) - 0.5 * w;
            if ((retoAntes && t < 0.0) || (retoDepois && t > fim))
                dd = max(abs(dot(p - a, nrm)) - 0.5 * w, max(-t, t - fim));
            d = min(d, dd);
            // A quina P1: chanfro (passa do limite de miter 4 do AE).
            if (i == 2) {
                float wj = th * clamp((visivel - acc) / (0.3 * visivel), 0.0, 1.0);
                float2 na = float2(-dirAnterior.y, dirAnterior.x) * 0.5 * wj;
                float2 nb = nrm * 0.5 * wj;
                d = min(d, triangulo(p, a, a + na, a + nb));
                d = min(d, triangulo(p, a, a - na, a - nb));
            }
            dirAnterior = dir;
        }
        acc += len;
        a = b;
    }
    return d;
}

fragment float4 fx_markr(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant markrParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 fonte = inputImg.sample(__nv_smp, in.acScreenNorm);
    float fs = eng.acTamanhoDoTexto;
    if (fs <= 0.0 || eng.acCaixaDoTexto.z <= 0.0) {
        __nv_out = fonte;
        return __nv_out;
    }
    float2 res = eng.acResolution;
    float2 p = in.acScreenNorm * res;
    float L = eng.acCaixaDoTexto.x * res.x;
    float T = eng.acCaixaDoTexto.y * res.y;
    float W = eng.acCaixaDoTexto.z * res.x;
    float H = eng.acCaixaDoTexto.w * res.y;

    float prog = clamp(u.progress / 100.0, 0.0, 1.0);
    if (u.animate) prog *= easeDoMarkr(eng.acTime / max(u.duration, 1e-3));

    float pad = u.xPadding / 100.0 * fs;
    float th = u.thickness / 100.0 * fs;
    float capH = 0.7 * fs;
    float extra = u.yOffset / 100.0 * fs;

    float d = 1e6;
    bool atras = u.style == 2 || u.style == 3;
    if (prog > 0.0) {
        if (u.style == 4 || u.style == 1) {
            // Line / Strike
            float yL = u.style == 4 ? T + capH + 0.06 * fs + extra : T + 0.4 * H + extra;
            float xa = L - pad;
            float xb = xa + (W + 2.0 * pad) * prog;
            d = caixa(p, float2(xa, yL - 0.5 * th), float2(xb, yL + 0.5 * th));
        } else if (u.style == 0) {
            // Scribble
            float2 o = float2(L - pad, T + capH + 0.06 * fs + extra);
            float2 sz = float2(W + 2.0 * pad, 0.55 * H);
            d = rabisco(p, o, sz, th, prog);
        } else {
            // Highlight / HalfBox
            float yPad = (u.style == 2 ? 0.12 * fs : 0.0) + extra;
            float x1 = L - pad;
            float x2 = x1 + (W + 2.0 * pad) * prog;
            float y1 = u.style == 2 ? T - yPad : T + 0.65 * H - yPad;
            float y2 = u.style == 2 ? T + H + yPad : T + H;
            d = caixa(p, float2(x1, y1), float2(x2, y2));
        }
    }

    float m = cobertura(d) * u.color.a;
    float3 c = u.color.rgb;
    float4 o;
    if (atras) {
        // A forma ATRÁS do texto (o MARKr põe a camada abaixo dele).
        float a = fonte.a + m * (1.0 - fonte.a);
        float3 rgb = (fonte.rgb * fonte.a + c * m * (1.0 - fonte.a)) / max(a, 1e-5);
        o = float4(rgb, a);
    } else {
        float a = m + fonte.a * (1.0 - m);
        float3 rgb = (c * m + fonte.rgb * fonte.a * (1.0 - m)) / max(a, 1e-5);
        o = float4(rgb, a);
    }
    __nv_out = o;
    return __nv_out;
}
