// ---------------------------------------------------------------------------
// Hype CC 2
// origem : assets/effects/look-hype-cc-2.xml
// id     : nova.effect.look.hype-cc-2
// passes : 64
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct look_hype_cc_2Params {
    float uIntensidade;
    float uGlow;
    float uDetalhe;
};

// --- funcoes auxiliares do efeito
// u.uIntensidade, u.uGlow e u.uDetalhe vêm dos <params> (o prelúdio declara).

// Quantos níveis de pirâmide a imagem está acima ou abaixo de 1080 (o lado menor,
// em pixels da camada): o ajuste foi feito em 1080p.
float acDeltaNivel() {
    float2 tam = float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))) / max(eng.acEscalaDePixel, 0.05);
    return log2(max(min(tam.x, tam.y), 16.0) / 1080.0);
}

float3 paraLuz(float3 c) {
    float3 alto = pow(max(c + 0.055, 0.0) / 1.055, float3(2.4));
    return mix(c / 12.92, alto, step(float3(0.04045), c));
}

float3 paraTela(float3 l) {
    float3 s = max(l, 0.0);
    return mix(s * 12.92, 1.055 * pow(s, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), s));
}

// A LUT 33³ do atlas: 33 ladrilhos 33×33 lado a lado (x = b·33 + r, y = linha0 + g).
float3 lut(float3 c, float linha0) {
    float2 tam = float2(int2(int(atlas.get_width()), int(atlas.get_height())));
    float3 p = clamp(c, 0.0, 1.0) * 32.0;
    float b0 = floor(p.b);
    float b1 = min(b0 + 1.0, 32.0);
    float t = p.b - b0;
    float v = (linha0 + p.g + 0.5) / tam.y;
    float3 a = atlas.sample(__nv_smp, float2((b0 * 33.0 + p.r + 0.5) / tam.x, v)).rgb;
    float3 d = atlas.sample(__nv_smp, float2((b1 * 33.0 + p.r + 0.5) / tam.x, v)).rgb;
    return mix(a, d, t);
}

// A descida da pirâmide: tenda 4×4 (como o Deep Glow).
float3 descer(sampler2D origem) {
    int2 tamI = int2(int(origem.get_width()), int(origem.get_height()));
    float2 p = in.acScreenNorm * float2(tamI);
    float2 t0 = floor(p) - 2.0;
    float3 soma = float3(0.0);
    float pesos = 0.0;
    for (int j = 0; j < 4; j++) {
        for (int i = 0; i < 4; i++) {
            float2 t = t0 + float2(float(i), float(j));
            float2 w = max(2.0 - abs(t + 0.5 - p), 0.0);
            float peso = w.x * w.y;
            soma += origem.read(uint2(clamp(int2(t), int2(0), tamI - 1)), uint(0)).rgb * peso;
            pesos += peso;
        }
    }
    return soma / max(pesos, 0.0001);
}

// O glow guarda LUZ (linear) em 8 bits com raiz — a mesma de Deep Glow — e com ruído.
float ruidoDoPixel() {
    return fract(52.9829189 * fract(dot(__nv_fragCoord.xy, float2(0.06711056, 0.00583715)))) - 0.5;
}
float4 guardar(float3 luz) { return float4(sqrt(max(luz, 0.0)) + ruidoDoPixel() / 255.0, 1.0); }
float3 abrir(float3 g) { return g * g; }

float3 cortar(float3 c, float limiar, float joelho) {
    float vista = dot(c, float3(0.2126, 0.7152, 0.0722));
    float t = clamp((vista - limiar) / max(joelho, 0.0001), 0.0, 1.0);
    return paraLuz(c) * (t * t * (3.0 - 2.0 * t));
}

float4 descerComCorte(sampler2D origem, float limiar, float joelho) {
    int2 tamI = int2(int(origem.get_width()), int(origem.get_height()));
    float2 p = in.acScreenNorm * float2(tamI);
    float2 t0 = floor(p) - 2.0;
    float3 soma = float3(0.0);
    float pesos = 0.0;
    for (int j = 0; j < 4; j++) {
        for (int i = 0; i < 4; i++) {
            float2 t = t0 + float2(float(i), float(j));
            float2 w = max(2.0 - abs(t + 0.5 - p), 0.0);
            float peso = w.x * w.y;
            soma += cortar(origem.read(uint2(clamp(int2(t), int2(0), tamI - 1)), uint(0)).rgb, limiar, joelho) * peso;
            pesos += peso;
        }
    }
    return guardar(soma / max(pesos, 0.0001));
}

float4 descerLuz(sampler2D origem) {
    int2 tamI = int2(int(origem.get_width()), int(origem.get_height()));
    float2 p = in.acScreenNorm * float2(tamI);
    float2 t0 = floor(p) - 2.0;
    float3 soma = float3(0.0);
    float pesos = 0.0;
    for (int j = 0; j < 4; j++) {
        for (int i = 0; i < 4; i++) {
            float2 t = t0 + float2(float(i), float(j));
            float2 w = max(2.0 - abs(t + 0.5 - p), 0.0);
            float peso = w.x * w.y;
            soma += abrir(origem.read(uint2(clamp(int2(t), int2(0), tamI - 1)), uint(0)).rgb) * peso;
            pesos += peso;
        }
    }
    return guardar(soma / max(pesos, 0.0001));
}

// A subida: B-spline cúbica em quatro leituras (o `lerLiso` do Deep Glow).
float3 lerLiso(sampler2D t, float2 uv) {
    float2 tam = float2(int2(int(t.get_width()), int(t.get_height())));
    float2 p = uv * tam - 0.5;
    float2 i = floor(p);
    float2 f = p - i;
    float2 f2 = f * f;
    float2 f3 = f2 * f;
    float2 w0 = (1.0 - 3.0 * f + 3.0 * f2 - f3) / 6.0;
    float2 w1 = (4.0 - 6.0 * f2 + 3.0 * f3) / 6.0;
    float2 w2 = (1.0 + 3.0 * f + 3.0 * f2 - 3.0 * f3) / 6.0;
    float2 w3 = f3 / 6.0;
    float2 g0 = w0 + w1;
    float2 g1 = w2 + w3;
    float2 a = (i - 1.0 + w1 / max(g0, 0.0001) + 0.5) / tam;
    float2 b = (i + 1.0 + w3 / max(g1, 0.0001) + 0.5) / tam;
    return t.sample(__nv_smp, float2(a.x, a.y)).rgb * g0.x * g0.y
         + t.sample(__nv_smp, float2(b.x, a.y)).rgb * g1.x * g0.y
         + t.sample(__nv_smp, float2(a.x, b.y)).rgb * g0.x * g1.y
         + t.sample(__nv_smp, float2(b.x, b.y)).rgb * g1.x * g1.y;
}


float3 nivelF1_luz(float n, float2 uv) {
    n = clamp(n, 1.0, 8.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = abrir(lerLiso(f1_1, uv)) * (1.0 - t) + abrir(lerLiso(f1_2, uv)) * t;
    if (a == 2.0) r = abrir(lerLiso(f1_2, uv)) * (1.0 - t) + abrir(lerLiso(f1_3, uv)) * t;
    if (a == 3.0) r = abrir(lerLiso(f1_3, uv)) * (1.0 - t) + abrir(lerLiso(f1_4, uv)) * t;
    if (a == 4.0) r = abrir(lerLiso(f1_4, uv)) * (1.0 - t) + abrir(lerLiso(f1_5, uv)) * t;
    if (a == 5.0) r = abrir(lerLiso(f1_5, uv)) * (1.0 - t) + abrir(lerLiso(f1_6, uv)) * t;
    if (a == 6.0) r = abrir(lerLiso(f1_6, uv)) * (1.0 - t) + abrir(lerLiso(f1_7, uv)) * t;
    if (a == 7.0) r = abrir(lerLiso(f1_7, uv)) * (1.0 - t) + abrir(lerLiso(f1_8, uv)) * t;
    if (a == 8.0) r = abrir(lerLiso(f1_8, uv)) * (1.0 - t);
    return r;
}

float3 popDe1(float2 uv) {
    float3 x = x1.sample(__nv_smp, uv).rgb;
    float3 g = x;
    return clamp(g, 0.0, 1.0);
}

float3 saida1(float2 uv) {
    float3 lin = paraLuz(g1.sample(__nv_smp, uv).rgb);
    float3 luz = u.uGlow * (float3(0.077366, 0.000000, 0.246928) * nivelF1_luz(0.0 + 1.0 + acDeltaNivel(), uv) + float3(0.479596, 0.431177, 0.030133) * nivelF1_luz(1.0 + 1.0 + acDeltaNivel(), uv) + float3(0.482709, 0.484925, 0.545612) * nivelF1_luz(2.0 + 1.0 + acDeltaNivel(), uv) + float3(0.495168, 0.511022, 0.339306) * nivelF1_luz(4.0 + 1.0 + acDeltaNivel(), uv) + float3(0.191322, 0.204435, 0.384665) * nivelF1_luz(5.0 + 1.0 + acDeltaNivel(), uv));
    lin += luz * (1.0 - lin);
    return paraTela(lin);
}

float3 nivelX2(float n, float2 uv) {
    n = clamp(n, 1.0, 8.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = lerLiso(x2_1, uv) * (1.0 - t) + lerLiso(x2_2, uv) * t;
    if (a == 2.0) r = lerLiso(x2_2, uv) * (1.0 - t) + lerLiso(x2_3, uv) * t;
    if (a == 3.0) r = lerLiso(x2_3, uv) * (1.0 - t) + lerLiso(x2_4, uv) * t;
    if (a == 4.0) r = lerLiso(x2_4, uv) * (1.0 - t) + lerLiso(x2_5, uv) * t;
    if (a == 5.0) r = lerLiso(x2_5, uv) * (1.0 - t) + lerLiso(x2_6, uv) * t;
    if (a == 6.0) r = lerLiso(x2_6, uv) * (1.0 - t) + lerLiso(x2_7, uv) * t;
    if (a == 7.0) r = lerLiso(x2_7, uv) * (1.0 - t) + lerLiso(x2_8, uv) * t;
    if (a == 8.0) r = lerLiso(x2_8, uv) * (1.0 - t);
    return r;
}

float3 nivelF2_luz(float n, float2 uv) {
    n = clamp(n, 1.0, 8.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = abrir(lerLiso(f2_1, uv)) * (1.0 - t) + abrir(lerLiso(f2_2, uv)) * t;
    if (a == 2.0) r = abrir(lerLiso(f2_2, uv)) * (1.0 - t) + abrir(lerLiso(f2_3, uv)) * t;
    if (a == 3.0) r = abrir(lerLiso(f2_3, uv)) * (1.0 - t) + abrir(lerLiso(f2_4, uv)) * t;
    if (a == 4.0) r = abrir(lerLiso(f2_4, uv)) * (1.0 - t) + abrir(lerLiso(f2_5, uv)) * t;
    if (a == 5.0) r = abrir(lerLiso(f2_5, uv)) * (1.0 - t) + abrir(lerLiso(f2_6, uv)) * t;
    if (a == 6.0) r = abrir(lerLiso(f2_6, uv)) * (1.0 - t) + abrir(lerLiso(f2_7, uv)) * t;
    if (a == 7.0) r = abrir(lerLiso(f2_7, uv)) * (1.0 - t) + abrir(lerLiso(f2_8, uv)) * t;
    if (a == 8.0) r = abrir(lerLiso(f2_8, uv)) * (1.0 - t);
    return r;
}

float3 popDe2(float2 uv) {
    float3 x = x2.sample(__nv_smp, uv).rgb;
    float3 g = x;
    g = g + (nivelX2(float(5) + 1.0 + acDeltaNivel(), uv) - g) * atlas.sample(__nv_smp, float2((0.0 + clamp(uv.x * 16.0, 0.5, 16.0 - 0.5)) / 1089.0, (33.0 + clamp(uv.y * 9.0, 0.5, 9.0 - 0.5)) / 84.0)).rgb.r * u.uDetalhe;
    float3 n0 = nivelX2(0.0 + 1.0 + acDeltaNivel(), uv);
    float3 n1 = nivelX2(1.0 + 1.0 + acDeltaNivel(), uv);
    float3 n2 = nivelX2(2.0 + 1.0 + acDeltaNivel(), uv);
    float3 n3 = nivelX2(3.0 + 1.0 + acDeltaNivel(), uv);
    float3 n4 = nivelX2(4.0 + 1.0 + acDeltaNivel(), uv);
    float3 n5 = nivelX2(5.0 + 1.0 + acDeltaNivel(), uv);
    float3 n6 = nivelX2(6.0 + 1.0 + acDeltaNivel(), uv);
    float3 n7 = nivelX2(7.0 + 1.0 + acDeltaNivel(), uv);
    g = g + u.uDetalhe * (-0.491080 * (g - n0) + 0.281711 * n0 * (1.0 - g) + -0.081028 * (g - n1) + -0.289321 * n1 * (1.0 - g) + 0.094705 * (g - n2) + 0.270649 * n2 * (1.0 - g) + -0.116794 * (g - n3) + -0.131191 * n3 * (1.0 - g) + 0.160749 * (g - n4) + -0.234975 * n4 * (1.0 - g) + -0.125022 * (g - n5) + 0.336709 * n5 * (1.0 - g) + 0.089504 * (g - n6) + -0.020792 * n6 * (1.0 - g) + -0.112472 * (g - n7) + -0.283891 * n7 * (1.0 - g));
    return clamp(g, 0.0, 1.0);
}

float3 saida2(float2 uv) {
    float3 lin = paraLuz(g2.sample(__nv_smp, uv).rgb);
    float3 luz = u.uGlow * (float3(0.061586, 0.059513, 0.039698) * nivelF2_luz(0.0 + 1.0 + acDeltaNivel(), uv) + float3(0.058273, 0.060666, 0.103667) * nivelF2_luz(6.0 + 1.0 + acDeltaNivel(), uv) + float3(0.063450, 0.057892, 0.067370) * nivelF2_luz(7.0 + 1.0 + acDeltaNivel(), uv));
    lin += luz;
    return paraTela(lin);
}

float3 nivelX3(float n, float2 uv) {
    n = clamp(n, 1.0, 8.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = lerLiso(x3_1, uv) * (1.0 - t) + lerLiso(x3_2, uv) * t;
    if (a == 2.0) r = lerLiso(x3_2, uv) * (1.0 - t) + lerLiso(x3_3, uv) * t;
    if (a == 3.0) r = lerLiso(x3_3, uv) * (1.0 - t) + lerLiso(x3_4, uv) * t;
    if (a == 4.0) r = lerLiso(x3_4, uv) * (1.0 - t) + lerLiso(x3_5, uv) * t;
    if (a == 5.0) r = lerLiso(x3_5, uv) * (1.0 - t) + lerLiso(x3_6, uv) * t;
    if (a == 6.0) r = lerLiso(x3_6, uv) * (1.0 - t) + lerLiso(x3_7, uv) * t;
    if (a == 7.0) r = lerLiso(x3_7, uv) * (1.0 - t) + lerLiso(x3_8, uv) * t;
    if (a == 8.0) r = lerLiso(x3_8, uv) * (1.0 - t);
    return r;
}

float3 nivelF3_luz(float n, float2 uv) {
    n = clamp(n, 1.0, 8.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = abrir(lerLiso(f3_1, uv)) * (1.0 - t) + abrir(lerLiso(f3_2, uv)) * t;
    if (a == 2.0) r = abrir(lerLiso(f3_2, uv)) * (1.0 - t) + abrir(lerLiso(f3_3, uv)) * t;
    if (a == 3.0) r = abrir(lerLiso(f3_3, uv)) * (1.0 - t) + abrir(lerLiso(f3_4, uv)) * t;
    if (a == 4.0) r = abrir(lerLiso(f3_4, uv)) * (1.0 - t) + abrir(lerLiso(f3_5, uv)) * t;
    if (a == 5.0) r = abrir(lerLiso(f3_5, uv)) * (1.0 - t) + abrir(lerLiso(f3_6, uv)) * t;
    if (a == 6.0) r = abrir(lerLiso(f3_6, uv)) * (1.0 - t) + abrir(lerLiso(f3_7, uv)) * t;
    if (a == 7.0) r = abrir(lerLiso(f3_7, uv)) * (1.0 - t) + abrir(lerLiso(f3_8, uv)) * t;
    if (a == 8.0) r = abrir(lerLiso(f3_8, uv)) * (1.0 - t);
    return r;
}

float3 popDe3(float2 uv) {
    float3 x = x3.sample(__nv_smp, uv).rgb;
    float3 g = x;
    float3 n0 = nivelX3(0.0 + 1.0 + acDeltaNivel(), uv);
    float3 n1 = nivelX3(1.0 + 1.0 + acDeltaNivel(), uv);
    float3 n2 = nivelX3(2.0 + 1.0 + acDeltaNivel(), uv);
    float3 n3 = nivelX3(3.0 + 1.0 + acDeltaNivel(), uv);
    float3 n4 = nivelX3(4.0 + 1.0 + acDeltaNivel(), uv);
    float3 n5 = nivelX3(5.0 + 1.0 + acDeltaNivel(), uv);
    float3 n6 = nivelX3(6.0 + 1.0 + acDeltaNivel(), uv);
    float3 n7 = nivelX3(7.0 + 1.0 + acDeltaNivel(), uv);
    g = g + u.uDetalhe * (-0.108149 * n0 * (1.0 - g) + -0.148049 * (g - n1) + 0.125048 * n1 * (1.0 - g) + -0.015240 * (g - n2) + 0.006156 * n2 * (1.0 - g) + 0.053334 * (g - n3) + -0.047725 * n3 * (1.0 - g) + -0.036304 * (g - n4) + 0.020668 * n4 * (1.0 - g) + 0.015974 * (g - n5) + 0.002743 * n5 * (1.0 - g) + -0.005353 * (g - n6) + -0.002525 * n6 * (1.0 - g) + 0.000147 * (g - n7) + -0.000496 * n7 * (1.0 - g));
    return clamp(g, 0.0, 1.0);
}

float3 saida3(float2 uv) {
    float3 lin = paraLuz(g3.sample(__nv_smp, uv).rgb);
    float3 luz = u.uGlow * (float3(0.007404, 0.000000, 0.004741) * nivelF3_luz(0.0 + 1.0 + acDeltaNivel(), uv) + float3(0.000000, 0.013359, 0.000000) * nivelF3_luz(2.0 + 1.0 + acDeltaNivel(), uv) + float3(0.000000, 0.000172, 0.000000) * nivelF3_luz(5.0 + 1.0 + acDeltaNivel(), uv));
    lin += luz * (1.0 - lin);
    return paraTela(lin);
}

float3 nivelX5(float n, float2 uv) {
    n = clamp(n, 1.0, 8.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = lerLiso(x5_1, uv) * (1.0 - t) + lerLiso(x5_2, uv) * t;
    if (a == 2.0) r = lerLiso(x5_2, uv) * (1.0 - t) + lerLiso(x5_3, uv) * t;
    if (a == 3.0) r = lerLiso(x5_3, uv) * (1.0 - t) + lerLiso(x5_4, uv) * t;
    if (a == 4.0) r = lerLiso(x5_4, uv) * (1.0 - t) + lerLiso(x5_5, uv) * t;
    if (a == 5.0) r = lerLiso(x5_5, uv) * (1.0 - t) + lerLiso(x5_6, uv) * t;
    if (a == 6.0) r = lerLiso(x5_6, uv) * (1.0 - t) + lerLiso(x5_7, uv) * t;
    if (a == 7.0) r = lerLiso(x5_7, uv) * (1.0 - t) + lerLiso(x5_8, uv) * t;
    if (a == 8.0) r = lerLiso(x5_8, uv) * (1.0 - t);
    return r;
}

float3 nivelF5_luz(float n, float2 uv) {
    n = clamp(n, 1.0, 7.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = abrir(lerLiso(f5_1, uv)) * (1.0 - t) + abrir(lerLiso(f5_2, uv)) * t;
    if (a == 2.0) r = abrir(lerLiso(f5_2, uv)) * (1.0 - t) + abrir(lerLiso(f5_3, uv)) * t;
    if (a == 3.0) r = abrir(lerLiso(f5_3, uv)) * (1.0 - t) + abrir(lerLiso(f5_4, uv)) * t;
    if (a == 4.0) r = abrir(lerLiso(f5_4, uv)) * (1.0 - t) + abrir(lerLiso(f5_5, uv)) * t;
    if (a == 5.0) r = abrir(lerLiso(f5_5, uv)) * (1.0 - t) + abrir(lerLiso(f5_6, uv)) * t;
    if (a == 6.0) r = abrir(lerLiso(f5_6, uv)) * (1.0 - t) + abrir(lerLiso(f5_7, uv)) * t;
    if (a == 7.0) r = abrir(lerLiso(f5_7, uv)) * (1.0 - t);
    return r;
}

float3 popDe5(float2 uv) {
    float3 x = x5.sample(__nv_smp, uv).rgb;
    float3 g = x;
    g = g + (nivelX5(float(2) + 1.0 + acDeltaNivel(), uv) - g) * atlas.sample(__nv_smp, float2((0.0 + clamp(uv.x * 16.0, 0.5, 16.0 - 0.5)) / 1089.0, (75.0 + clamp(uv.y * 9.0, 0.5, 9.0 - 0.5)) / 84.0)).rgb.r * u.uDetalhe;
    float3 n0 = nivelX5(0.0 + 1.0 + acDeltaNivel(), uv);
    float3 n1 = nivelX5(1.0 + 1.0 + acDeltaNivel(), uv);
    float3 n2 = nivelX5(2.0 + 1.0 + acDeltaNivel(), uv);
    float3 n3 = nivelX5(3.0 + 1.0 + acDeltaNivel(), uv);
    float3 n4 = nivelX5(4.0 + 1.0 + acDeltaNivel(), uv);
    float3 n5 = nivelX5(5.0 + 1.0 + acDeltaNivel(), uv);
    float3 n6 = nivelX5(6.0 + 1.0 + acDeltaNivel(), uv);
    float3 n7 = nivelX5(7.0 + 1.0 + acDeltaNivel(), uv);
    g = g + u.uDetalhe * (-0.021098 * (g - n0) + -0.053571 * n0 * (1.0 - g) + -0.032640 * (g - n1) + -0.205480 * n1 * (1.0 - g) + 0.107687 * (g - n2) + 0.325533 * n2 * (1.0 - g) + -0.010054 * (g - n3) + -0.047182 * n3 * (1.0 - g) + 0.003454 * (g - n4) + 0.037880 * n4 * (1.0 - g) + -0.010003 * (g - n5) + -0.040980 * n5 * (1.0 - g) + 0.004843 * (g - n6) + 0.000712 * n6 * (1.0 - g) + -0.003670 * (g - n7) + -0.004329 * n7 * (1.0 - g));
    return clamp(g, 0.0, 1.0);
}

float3 saida5(float2 uv) {
    float3 lin = paraLuz(g5.sample(__nv_smp, uv).rgb);
    float3 luz = u.uGlow * (float3(0.000307, 0.000168, 0.001838) * nivelF5_luz(4.0 + 1.0 + acDeltaNivel(), uv));
    lin += luz;
    return paraTela(lin);
}

float3 antes1(float2 uv) {
    float3 c = clamp(inputImg.sample(__nv_smp, uv).rgb, 0.0, 1.0);
    c = lut(c, 0.0);
    return c;
}

float3 antes2(float2 uv) {
    float3 c = saida1(uv);
    return c;
}

float3 antes3(float2 uv) {
    float3 c = saida2(uv);
    return c;
}

float3 antes5(float2 uv) {
    float3 c = saida3(uv);
    c = lut(c, 42.0);
    return c;
}

float3 fim(float2 uv) {
    float3 c = saida5(uv);
    return c;
}

fragment float4 fx_look_hype_cc_2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant look_hype_cc_2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> atlas [[texture(1)]],
    texture2d<float> x1 [[texture(2)]],
    texture2d<float> g1 [[texture(3)]],
    texture2d<float> f1_1 [[texture(4)]],
    texture2d<float> f1_2 [[texture(5)]],
    texture2d<float> f1_3 [[texture(6)]],
    texture2d<float> f1_4 [[texture(7)]],
    texture2d<float> f1_5 [[texture(8)]],
    texture2d<float> f1_6 [[texture(9)]],
    texture2d<float> f1_7 [[texture(10)]],
    texture2d<float> f1_8 [[texture(11)]],
    texture2d<float> x2 [[texture(12)]],
    texture2d<float> x2_1 [[texture(13)]],
    texture2d<float> x2_2 [[texture(14)]],
    texture2d<float> x2_3 [[texture(15)]],
    texture2d<float> x2_4 [[texture(16)]],
    texture2d<float> x2_5 [[texture(17)]],
    texture2d<float> x2_6 [[texture(18)]],
    texture2d<float> x2_7 [[texture(19)]],
    texture2d<float> x2_8 [[texture(20)]],
    texture2d<float> g2 [[texture(21)]],
    texture2d<float> f2_1 [[texture(22)]],
    texture2d<float> f2_2 [[texture(23)]],
    texture2d<float> f2_3 [[texture(24)]],
    texture2d<float> f2_4 [[texture(25)]],
    texture2d<float> f2_5 [[texture(26)]],
    texture2d<float> f2_6 [[texture(27)]],
    texture2d<float> f2_7 [[texture(28)]],
    texture2d<float> f2_8 [[texture(29)]],
    texture2d<float> x3 [[texture(30)]],
    texture2d<float> x3_1 [[texture(31)]],
    texture2d<float> x3_2 [[texture(32)]],
    texture2d<float> x3_3 [[texture(33)]],
    texture2d<float> x3_4 [[texture(34)]],
    texture2d<float> x3_5 [[texture(35)]],
    texture2d<float> x3_6 [[texture(36)]],
    texture2d<float> x3_7 [[texture(37)]],
    texture2d<float> x3_8 [[texture(38)]],
    texture2d<float> g3 [[texture(39)]],
    texture2d<float> f3_1 [[texture(40)]],
    texture2d<float> f3_2 [[texture(41)]],
    texture2d<float> f3_3 [[texture(42)]],
    texture2d<float> f3_4 [[texture(43)]],
    texture2d<float> f3_5 [[texture(44)]],
    texture2d<float> f3_6 [[texture(45)]],
    texture2d<float> f3_7 [[texture(46)]],
    texture2d<float> f3_8 [[texture(47)]],
    texture2d<float> x5 [[texture(48)]],
    texture2d<float> x5_1 [[texture(49)]],
    texture2d<float> x5_2 [[texture(50)]],
    texture2d<float> x5_3 [[texture(51)]],
    texture2d<float> x5_4 [[texture(52)]],
    texture2d<float> x5_5 [[texture(53)]],
    texture2d<float> x5_6 [[texture(54)]],
    texture2d<float> x5_7 [[texture(55)]],
    texture2d<float> x5_8 [[texture(56)]],
    texture2d<float> g5 [[texture(57)]],
    texture2d<float> f5_1 [[texture(58)]],
    texture2d<float> f5_2 [[texture(59)]],
    texture2d<float> f5_3 [[texture(60)]],
    texture2d<float> f5_4 [[texture(61)]],
    texture2d<float> f5_5 [[texture(62)]],
    texture2d<float> f5_6 [[texture(63)]],
    texture2d<float> f5_7 [[texture(64)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = float4(antes1(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = float4(popDe1(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = descerComCorte(g1, 0.000000, 0.150000); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = descerLuz(f1_1); return __nv_out; }
    if (eng.acPass == 4) { __nv_out = descerLuz(f1_2); return __nv_out; }
    if (eng.acPass == 5) { __nv_out = descerLuz(f1_3); return __nv_out; }
    if (eng.acPass == 6) { __nv_out = descerLuz(f1_4); return __nv_out; }
    if (eng.acPass == 7) { __nv_out = descerLuz(f1_5); return __nv_out; }
    if (eng.acPass == 8) { __nv_out = descerLuz(f1_6); return __nv_out; }
    if (eng.acPass == 9) { __nv_out = descerLuz(f1_7); return __nv_out; }
    if (eng.acPass == 10) { __nv_out = float4(antes2(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 11) { __nv_out = float4(descer(x2), 1.0); return __nv_out; }
    if (eng.acPass == 12) { __nv_out = float4(descer(x2_1), 1.0); return __nv_out; }
    if (eng.acPass == 13) { __nv_out = float4(descer(x2_2), 1.0); return __nv_out; }
    if (eng.acPass == 14) { __nv_out = float4(descer(x2_3), 1.0); return __nv_out; }
    if (eng.acPass == 15) { __nv_out = float4(descer(x2_4), 1.0); return __nv_out; }
    if (eng.acPass == 16) { __nv_out = float4(descer(x2_5), 1.0); return __nv_out; }
    if (eng.acPass == 17) { __nv_out = float4(descer(x2_6), 1.0); return __nv_out; }
    if (eng.acPass == 18) { __nv_out = float4(descer(x2_7), 1.0); return __nv_out; }
    if (eng.acPass == 19) { __nv_out = float4(popDe2(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 20) { __nv_out = descerComCorte(g2, 0.000000, 0.150000); return __nv_out; }
    if (eng.acPass == 21) { __nv_out = descerLuz(f2_1); return __nv_out; }
    if (eng.acPass == 22) { __nv_out = descerLuz(f2_2); return __nv_out; }
    if (eng.acPass == 23) { __nv_out = descerLuz(f2_3); return __nv_out; }
    if (eng.acPass == 24) { __nv_out = descerLuz(f2_4); return __nv_out; }
    if (eng.acPass == 25) { __nv_out = descerLuz(f2_5); return __nv_out; }
    if (eng.acPass == 26) { __nv_out = descerLuz(f2_6); return __nv_out; }
    if (eng.acPass == 27) { __nv_out = descerLuz(f2_7); return __nv_out; }
    if (eng.acPass == 28) { __nv_out = float4(float3(antes3(0.5 + (in.acScreenNorm - 0.5) / 1.000000).r, antes3(in.acScreenNorm).g, antes3(0.5 + (in.acScreenNorm - 0.5) / 1.003000).b), 1.0); return __nv_out; }
    if (eng.acPass == 29) { __nv_out = float4(descer(x3), 1.0); return __nv_out; }
    if (eng.acPass == 30) { __nv_out = float4(descer(x3_1), 1.0); return __nv_out; }
    if (eng.acPass == 31) { __nv_out = float4(descer(x3_2), 1.0); return __nv_out; }
    if (eng.acPass == 32) { __nv_out = float4(descer(x3_3), 1.0); return __nv_out; }
    if (eng.acPass == 33) { __nv_out = float4(descer(x3_4), 1.0); return __nv_out; }
    if (eng.acPass == 34) { __nv_out = float4(descer(x3_5), 1.0); return __nv_out; }
    if (eng.acPass == 35) { __nv_out = float4(descer(x3_6), 1.0); return __nv_out; }
    if (eng.acPass == 36) { __nv_out = float4(descer(x3_7), 1.0); return __nv_out; }
    if (eng.acPass == 37) { __nv_out = float4(popDe3(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 38) { __nv_out = descerComCorte(g3, 0.000000, 0.150000); return __nv_out; }
    if (eng.acPass == 39) { __nv_out = descerLuz(f3_1); return __nv_out; }
    if (eng.acPass == 40) { __nv_out = descerLuz(f3_2); return __nv_out; }
    if (eng.acPass == 41) { __nv_out = descerLuz(f3_3); return __nv_out; }
    if (eng.acPass == 42) { __nv_out = descerLuz(f3_4); return __nv_out; }
    if (eng.acPass == 43) { __nv_out = descerLuz(f3_5); return __nv_out; }
    if (eng.acPass == 44) { __nv_out = descerLuz(f3_6); return __nv_out; }
    if (eng.acPass == 45) { __nv_out = descerLuz(f3_7); return __nv_out; }
    if (eng.acPass == 46) { __nv_out = float4(antes5(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 47) { __nv_out = float4(descer(x5), 1.0); return __nv_out; }
    if (eng.acPass == 48) { __nv_out = float4(descer(x5_1), 1.0); return __nv_out; }
    if (eng.acPass == 49) { __nv_out = float4(descer(x5_2), 1.0); return __nv_out; }
    if (eng.acPass == 50) { __nv_out = float4(descer(x5_3), 1.0); return __nv_out; }
    if (eng.acPass == 51) { __nv_out = float4(descer(x5_4), 1.0); return __nv_out; }
    if (eng.acPass == 52) { __nv_out = float4(descer(x5_5), 1.0); return __nv_out; }
    if (eng.acPass == 53) { __nv_out = float4(descer(x5_6), 1.0); return __nv_out; }
    if (eng.acPass == 54) { __nv_out = float4(descer(x5_7), 1.0); return __nv_out; }
    if (eng.acPass == 55) { __nv_out = float4(popDe5(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 56) { __nv_out = descerComCorte(g5, 0.600000, 0.150000); return __nv_out; }
    if (eng.acPass == 57) { __nv_out = descerLuz(f5_1); return __nv_out; }
    if (eng.acPass == 58) { __nv_out = descerLuz(f5_2); return __nv_out; }
    if (eng.acPass == 59) { __nv_out = descerLuz(f5_3); return __nv_out; }
    if (eng.acPass == 60) { __nv_out = descerLuz(f5_4); return __nv_out; }
    if (eng.acPass == 61) { __nv_out = descerLuz(f5_5); return __nv_out; }
    if (eng.acPass == 62) { __nv_out = descerLuz(f5_6); return __nv_out; }
    float4 base = inputImg.sample(__nv_smp, in.acScreenNorm);
    __nv_out = float4(mix(base.rgb, fim(in.acScreenNorm), u.uIntensidade), base.a);
    return __nv_out;
}
