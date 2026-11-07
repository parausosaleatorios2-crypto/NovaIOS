// ---------------------------------------------------------------------------
// Dark CC
// origem : assets/effects/look-dark-cc.xml
// id     : nova.effect.look.dark-cc
// passes : 77
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct look_dark_ccParams {
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


float3 nivelX0(float n, float2 uv) {
    n = clamp(n, 1.0, 8.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = lerLiso(x0_1, uv) * (1.0 - t) + lerLiso(x0_2, uv) * t;
    if (a == 2.0) r = lerLiso(x0_2, uv) * (1.0 - t) + lerLiso(x0_3, uv) * t;
    if (a == 3.0) r = lerLiso(x0_3, uv) * (1.0 - t) + lerLiso(x0_4, uv) * t;
    if (a == 4.0) r = lerLiso(x0_4, uv) * (1.0 - t) + lerLiso(x0_5, uv) * t;
    if (a == 5.0) r = lerLiso(x0_5, uv) * (1.0 - t) + lerLiso(x0_6, uv) * t;
    if (a == 6.0) r = lerLiso(x0_6, uv) * (1.0 - t) + lerLiso(x0_7, uv) * t;
    if (a == 7.0) r = lerLiso(x0_7, uv) * (1.0 - t) + lerLiso(x0_8, uv) * t;
    if (a == 8.0) r = lerLiso(x0_8, uv) * (1.0 - t);
    return r;
}

float3 nivelF0_luz(float n, float2 uv) {
    n = clamp(n, 1.0, 3.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = abrir(lerLiso(f0_1, uv)) * (1.0 - t) + abrir(lerLiso(f0_2, uv)) * t;
    if (a == 2.0) r = abrir(lerLiso(f0_2, uv)) * (1.0 - t) + abrir(lerLiso(f0_3, uv)) * t;
    if (a == 3.0) r = abrir(lerLiso(f0_3, uv)) * (1.0 - t);
    return r;
}

float3 popDe0(float2 uv) {
    float3 x = x0.sample(__nv_smp, uv).rgb;
    float3 g = x;
    float3 n0 = nivelX0(0.0 + 1.0 + acDeltaNivel(), uv);
    float3 n1 = nivelX0(1.0 + 1.0 + acDeltaNivel(), uv);
    float3 n2 = nivelX0(2.0 + 1.0 + acDeltaNivel(), uv);
    float3 n3 = nivelX0(3.0 + 1.0 + acDeltaNivel(), uv);
    float3 n4 = nivelX0(4.0 + 1.0 + acDeltaNivel(), uv);
    float3 n5 = nivelX0(5.0 + 1.0 + acDeltaNivel(), uv);
    float3 n6 = nivelX0(6.0 + 1.0 + acDeltaNivel(), uv);
    float3 n7 = nivelX0(7.0 + 1.0 + acDeltaNivel(), uv);
    g = g + u.uDetalhe * (0.052102 * n0 * (1.0 - g) + -0.152609 * (g - n1) + -0.120057 * n1 * (1.0 - g) + 0.140737 * (g - n2) + 0.040876 * n2 * (1.0 - g) + 0.015603 * (g - n3) + 0.013757 * n3 * (1.0 - g) + 0.134463 * (g - n4) + -0.054201 * n4 * (1.0 - g) + 0.024100 * (g - n5) + 0.096080 * n5 * (1.0 - g) + 0.013085 * (g - n6) + 0.042139 * n6 * (1.0 - g) + -0.075572 * (g - n7) + -0.086193 * n7 * (1.0 - g));
    return clamp(g, 0.0, 1.0);
}

float3 saida0(float2 uv) {
    float3 lin = paraLuz(g0.sample(__nv_smp, uv).rgb);
    float3 luz = u.uGlow * (float3(0.139319, 0.127649, 0.116201) * nivelF0_luz(0.0 + 1.0 + acDeltaNivel(), uv));
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
    float3 n0 = nivelX2(0.0 + 1.0 + acDeltaNivel(), uv);
    float3 n1 = nivelX2(1.0 + 1.0 + acDeltaNivel(), uv);
    float3 n2 = nivelX2(2.0 + 1.0 + acDeltaNivel(), uv);
    float3 n3 = nivelX2(3.0 + 1.0 + acDeltaNivel(), uv);
    float3 n4 = nivelX2(4.0 + 1.0 + acDeltaNivel(), uv);
    float3 n5 = nivelX2(5.0 + 1.0 + acDeltaNivel(), uv);
    float3 n6 = nivelX2(6.0 + 1.0 + acDeltaNivel(), uv);
    float3 n7 = nivelX2(7.0 + 1.0 + acDeltaNivel(), uv);
    g = g + u.uDetalhe * (0.155821 * n0 * (1.0 - g) + -0.098110 * (g - n1) + -0.109734 * n1 * (1.0 - g) + 0.061981 * (g - n2) + -0.025722 * n2 * (1.0 - g) + -0.043041 * (g - n3) + 0.104610 * n3 * (1.0 - g) + 0.061840 * (g - n4) + -0.249780 * n4 * (1.0 - g) + -0.125756 * (g - n5) + 0.162315 * n5 * (1.0 - g) + 0.272083 * (g - n6) + 0.070805 * n6 * (1.0 - g) + -0.241274 * (g - n7) + -0.110441 * n7 * (1.0 - g));
    return clamp(g, 0.0, 1.0);
}

float3 saida2(float2 uv) {
    float3 lin = paraLuz(g2.sample(__nv_smp, uv).rgb);
    float3 luz = u.uGlow * (float3(0.055321, 0.000000, 0.000000) * nivelF2_luz(6.0 + 1.0 + acDeltaNivel(), uv) + float3(0.004111, 0.233958, 0.391568) * nivelF2_luz(7.0 + 1.0 + acDeltaNivel(), uv));
    lin += luz;
    return paraTela(lin);
}

float3 nivelX6(float n, float2 uv) {
    n = clamp(n, 1.0, 8.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = lerLiso(x6_1, uv) * (1.0 - t) + lerLiso(x6_2, uv) * t;
    if (a == 2.0) r = lerLiso(x6_2, uv) * (1.0 - t) + lerLiso(x6_3, uv) * t;
    if (a == 3.0) r = lerLiso(x6_3, uv) * (1.0 - t) + lerLiso(x6_4, uv) * t;
    if (a == 4.0) r = lerLiso(x6_4, uv) * (1.0 - t) + lerLiso(x6_5, uv) * t;
    if (a == 5.0) r = lerLiso(x6_5, uv) * (1.0 - t) + lerLiso(x6_6, uv) * t;
    if (a == 6.0) r = lerLiso(x6_6, uv) * (1.0 - t) + lerLiso(x6_7, uv) * t;
    if (a == 7.0) r = lerLiso(x6_7, uv) * (1.0 - t) + lerLiso(x6_8, uv) * t;
    if (a == 8.0) r = lerLiso(x6_8, uv) * (1.0 - t);
    return r;
}

float3 nivelF6_luz(float n, float2 uv) {
    n = clamp(n, 1.0, 8.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = abrir(lerLiso(f6_1, uv)) * (1.0 - t) + abrir(lerLiso(f6_2, uv)) * t;
    if (a == 2.0) r = abrir(lerLiso(f6_2, uv)) * (1.0 - t) + abrir(lerLiso(f6_3, uv)) * t;
    if (a == 3.0) r = abrir(lerLiso(f6_3, uv)) * (1.0 - t) + abrir(lerLiso(f6_4, uv)) * t;
    if (a == 4.0) r = abrir(lerLiso(f6_4, uv)) * (1.0 - t) + abrir(lerLiso(f6_5, uv)) * t;
    if (a == 5.0) r = abrir(lerLiso(f6_5, uv)) * (1.0 - t) + abrir(lerLiso(f6_6, uv)) * t;
    if (a == 6.0) r = abrir(lerLiso(f6_6, uv)) * (1.0 - t) + abrir(lerLiso(f6_7, uv)) * t;
    if (a == 7.0) r = abrir(lerLiso(f6_7, uv)) * (1.0 - t) + abrir(lerLiso(f6_8, uv)) * t;
    if (a == 8.0) r = abrir(lerLiso(f6_8, uv)) * (1.0 - t);
    return r;
}

float3 popDe6(float2 uv) {
    float3 x = x6.sample(__nv_smp, uv).rgb;
    float3 g = x;
    g = g + (nivelX6(float(2) + 1.0 + acDeltaNivel(), uv) - g) * atlas.sample(__nv_smp, float2((0.0 + clamp(uv.x * 16.0, 0.5, 16.0 - 0.5)) / 1089.0, (141.0 + clamp(uv.y * 9.0, 0.5, 9.0 - 0.5)) / 183.0)).rgb.r * u.uDetalhe;
    float3 n0 = nivelX6(0.0 + 1.0 + acDeltaNivel(), uv);
    float3 n1 = nivelX6(1.0 + 1.0 + acDeltaNivel(), uv);
    float3 n2 = nivelX6(2.0 + 1.0 + acDeltaNivel(), uv);
    float3 n3 = nivelX6(3.0 + 1.0 + acDeltaNivel(), uv);
    float3 n4 = nivelX6(4.0 + 1.0 + acDeltaNivel(), uv);
    float3 n5 = nivelX6(5.0 + 1.0 + acDeltaNivel(), uv);
    float3 n6 = nivelX6(6.0 + 1.0 + acDeltaNivel(), uv);
    float3 n7 = nivelX6(7.0 + 1.0 + acDeltaNivel(), uv);
    g = g + u.uDetalhe * (0.016789 * (g - n0) + -0.403643 * n0 * (1.0 - g) + -0.005925 * (g - n1) + 0.537337 * n1 * (1.0 - g) + 0.090423 * (g - n2) + -0.077374 * n2 * (1.0 - g) + -0.001135 * (g - n3) + -0.029036 * n3 * (1.0 - g) + -0.021589 * (g - n4) + -0.036136 * n4 * (1.0 - g) + 0.037461 * (g - n5) + 0.053876 * n5 * (1.0 - g) + -0.032690 * (g - n6) + -0.054894 * n6 * (1.0 - g) + 0.007692 * (g - n7) + 0.008146 * n7 * (1.0 - g));
    return clamp(g, 0.0, 1.0);
}

float3 saida6(float2 uv) {
    float3 lin = paraLuz(g6.sample(__nv_smp, uv).rgb);
    float3 luz = u.uGlow * (float3(0.000000, 0.000000, 0.007118) * nivelF6_luz(2.0 + 1.0 + acDeltaNivel(), uv) + float3(0.000000, 0.011227, 0.009213) * nivelF6_luz(3.0 + 1.0 + acDeltaNivel(), uv) + float3(0.004733, 0.000000, 0.000000) * nivelF6_luz(4.0 + 1.0 + acDeltaNivel(), uv) + float3(0.000000, 0.001924, 0.000000) * nivelF6_luz(6.0 + 1.0 + acDeltaNivel(), uv) + float3(0.003192, 0.000000, 0.000000) * nivelF6_luz(7.0 + 1.0 + acDeltaNivel(), uv));
    lin += luz * (1.0 - lin);
    return paraTela(lin);
}

float3 nivelX8(float n, float2 uv) {
    n = clamp(n, 1.0, 8.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = lerLiso(x8_1, uv) * (1.0 - t) + lerLiso(x8_2, uv) * t;
    if (a == 2.0) r = lerLiso(x8_2, uv) * (1.0 - t) + lerLiso(x8_3, uv) * t;
    if (a == 3.0) r = lerLiso(x8_3, uv) * (1.0 - t) + lerLiso(x8_4, uv) * t;
    if (a == 4.0) r = lerLiso(x8_4, uv) * (1.0 - t) + lerLiso(x8_5, uv) * t;
    if (a == 5.0) r = lerLiso(x8_5, uv) * (1.0 - t) + lerLiso(x8_6, uv) * t;
    if (a == 6.0) r = lerLiso(x8_6, uv) * (1.0 - t) + lerLiso(x8_7, uv) * t;
    if (a == 7.0) r = lerLiso(x8_7, uv) * (1.0 - t) + lerLiso(x8_8, uv) * t;
    if (a == 8.0) r = lerLiso(x8_8, uv) * (1.0 - t);
    return r;
}

float3 nivelF8_luz(float n, float2 uv) {
    n = clamp(n, 1.0, 3.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = abrir(lerLiso(f8_1, uv)) * (1.0 - t) + abrir(lerLiso(f8_2, uv)) * t;
    if (a == 2.0) r = abrir(lerLiso(f8_2, uv)) * (1.0 - t) + abrir(lerLiso(f8_3, uv)) * t;
    if (a == 3.0) r = abrir(lerLiso(f8_3, uv)) * (1.0 - t);
    return r;
}

float3 popDe8(float2 uv) {
    float3 x = x8.sample(__nv_smp, uv).rgb;
    float3 g = x;
    float3 n0 = nivelX8(0.0 + 1.0 + acDeltaNivel(), uv);
    float3 n1 = nivelX8(1.0 + 1.0 + acDeltaNivel(), uv);
    float3 n2 = nivelX8(2.0 + 1.0 + acDeltaNivel(), uv);
    float3 n3 = nivelX8(3.0 + 1.0 + acDeltaNivel(), uv);
    float3 n4 = nivelX8(4.0 + 1.0 + acDeltaNivel(), uv);
    float3 n5 = nivelX8(5.0 + 1.0 + acDeltaNivel(), uv);
    float3 n6 = nivelX8(6.0 + 1.0 + acDeltaNivel(), uv);
    float3 n7 = nivelX8(7.0 + 1.0 + acDeltaNivel(), uv);
    g = g + u.uDetalhe * (0.030405 * n0 * (1.0 - g) + 0.220795 * (g - n1) + -0.032516 * n1 * (1.0 - g) + -0.075622 * (g - n2) + -0.004508 * n2 * (1.0 - g) + 0.013900 * (g - n3) + 0.007269 * n3 * (1.0 - g) + -0.001355 * (g - n4) + -0.003055 * n4 * (1.0 - g) + 0.003488 * (g - n5) + 0.004457 * n5 * (1.0 - g) + -0.001002 * (g - n6) + -0.000705 * n6 * (1.0 - g) + -0.002415 * (g - n7) + -0.002625 * n7 * (1.0 - g));
    return clamp(g, 0.0, 1.0);
}

float3 saida8(float2 uv) {
    float3 lin = paraLuz(g8.sample(__nv_smp, uv).rgb);
    float3 luz = u.uGlow * (float3(0.007366, 0.007186, 0.006731) * nivelF8_luz(0.0 + 1.0 + acDeltaNivel(), uv));
    lin += luz * (1.0 - lin);
    return paraTela(lin);
}

float3 nivelX9(float n, float2 uv) {
    n = clamp(n, 1.0, 8.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = lerLiso(x9_1, uv) * (1.0 - t) + lerLiso(x9_2, uv) * t;
    if (a == 2.0) r = lerLiso(x9_2, uv) * (1.0 - t) + lerLiso(x9_3, uv) * t;
    if (a == 3.0) r = lerLiso(x9_3, uv) * (1.0 - t) + lerLiso(x9_4, uv) * t;
    if (a == 4.0) r = lerLiso(x9_4, uv) * (1.0 - t) + lerLiso(x9_5, uv) * t;
    if (a == 5.0) r = lerLiso(x9_5, uv) * (1.0 - t) + lerLiso(x9_6, uv) * t;
    if (a == 6.0) r = lerLiso(x9_6, uv) * (1.0 - t) + lerLiso(x9_7, uv) * t;
    if (a == 7.0) r = lerLiso(x9_7, uv) * (1.0 - t) + lerLiso(x9_8, uv) * t;
    if (a == 8.0) r = lerLiso(x9_8, uv) * (1.0 - t);
    return r;
}

float3 nivelF9_luz(float n, float2 uv) {
    n = clamp(n, 1.0, 4.0);
    float a = floor(n);
    float t = n - a;
    float3 r = float3(0.0);
    if (a == 1.0) r = abrir(lerLiso(f9_1, uv)) * (1.0 - t) + abrir(lerLiso(f9_2, uv)) * t;
    if (a == 2.0) r = abrir(lerLiso(f9_2, uv)) * (1.0 - t) + abrir(lerLiso(f9_3, uv)) * t;
    if (a == 3.0) r = abrir(lerLiso(f9_3, uv)) * (1.0 - t) + abrir(lerLiso(f9_4, uv)) * t;
    if (a == 4.0) r = abrir(lerLiso(f9_4, uv)) * (1.0 - t);
    return r;
}

float3 popDe9(float2 uv) {
    float3 x = x9.sample(__nv_smp, uv).rgb;
    float3 g = x;
    float3 n0 = nivelX9(0.0 + 1.0 + acDeltaNivel(), uv);
    float3 n1 = nivelX9(1.0 + 1.0 + acDeltaNivel(), uv);
    float3 n2 = nivelX9(2.0 + 1.0 + acDeltaNivel(), uv);
    float3 n3 = nivelX9(3.0 + 1.0 + acDeltaNivel(), uv);
    float3 n4 = nivelX9(4.0 + 1.0 + acDeltaNivel(), uv);
    float3 n5 = nivelX9(5.0 + 1.0 + acDeltaNivel(), uv);
    float3 n6 = nivelX9(6.0 + 1.0 + acDeltaNivel(), uv);
    float3 n7 = nivelX9(7.0 + 1.0 + acDeltaNivel(), uv);
    g = g + u.uDetalhe * (-0.031978 * n0 * (1.0 - g) + -0.007332 * (g - n1) + 0.054348 * n1 * (1.0 - g) + 0.026289 * (g - n2) + -0.034626 * n2 * (1.0 - g) + 0.017424 * (g - n3) + 0.017212 * n3 * (1.0 - g) + 0.006292 * (g - n4) + -0.014118 * n4 * (1.0 - g) + 0.002615 * (g - n5) + 0.022293 * n5 * (1.0 - g) + -0.007645 * (g - n6) + -0.011532 * n6 * (1.0 - g) + -0.003421 * (g - n7) + -0.003032 * n7 * (1.0 - g));
    return clamp(g, 0.0, 1.0);
}

float3 saida9(float2 uv) {
    float3 lin = paraLuz(g9.sample(__nv_smp, uv).rgb);
    float3 luz = u.uGlow * (float3(0.012014, 0.013864, 0.006517) * nivelF9_luz(0.0 + 1.0 + acDeltaNivel(), uv) + float3(0.000000, 0.000000, 0.001688) * nivelF9_luz(1.0 + 1.0 + acDeltaNivel(), uv));
    lin += luz * (1.0 - lin);
    return paraTela(lin);
}

float3 antes0(float2 uv) {
    float3 c = clamp(inputImg.sample(__nv_smp, uv).rgb, 0.0, 1.0);
    return c;
}

float3 antes2(float2 uv) {
    float3 c = saida0(uv);
    c = paraTela(clamp(paraLuz(c) * (atlas.sample(__nv_smp, float2((0.0 + clamp(uv.x * 64.0, 0.5, 64.0 - 0.5)) / 1089.0, (0.0 + clamp(uv.y * 36.0, 0.5, 36.0 - 0.5)) / 183.0)).rgb * 4.0), 0.0, 1.0));
    return c;
}

float3 antes6(float2 uv) {
    float3 c = saida2(uv);
    c = clamp(c * (atlas.sample(__nv_smp, float2((0.0 + clamp(uv.x * 64.0, 0.5, 64.0 - 0.5)) / 1089.0, (36.0 + clamp(uv.y * 36.0, 0.5, 36.0 - 0.5)) / 183.0)).rgb * 2.0) + (atlas.sample(__nv_smp, float2((64.0 + clamp(uv.x * 64.0, 0.5, 64.0 - 0.5)) / 1089.0, (36.0 + clamp(uv.y * 36.0, 0.5, 36.0 - 0.5)) / 183.0)).rgb - 0.5), 0.0, 1.0);
    c = lut(c, 72.0);
    c = clamp(c * (atlas.sample(__nv_smp, float2((0.0 + clamp(uv.x * 64.0, 0.5, 64.0 - 0.5)) / 1089.0, (105.0 + clamp(uv.y * 36.0, 0.5, 36.0 - 0.5)) / 183.0)).rgb * 2.0) + (atlas.sample(__nv_smp, float2((64.0 + clamp(uv.x * 64.0, 0.5, 64.0 - 0.5)) / 1089.0, (105.0 + clamp(uv.y * 36.0, 0.5, 36.0 - 0.5)) / 183.0)).rgb - 0.5), 0.0, 1.0);
    return c;
}

float3 antes8(float2 uv) {
    float3 c = saida6(uv);
    c = lut(c, 150.0);
    return c;
}

float3 antes9(float2 uv) {
    float3 c = saida8(uv);
    return c;
}

float3 fim(float2 uv) {
    float3 c = saida9(uv);
    return c;
}

fragment float4 fx_look_dark_cc(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant look_dark_ccParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> atlas [[texture(1)]],
    texture2d<float> x0 [[texture(2)]],
    texture2d<float> x0_1 [[texture(3)]],
    texture2d<float> x0_2 [[texture(4)]],
    texture2d<float> x0_3 [[texture(5)]],
    texture2d<float> x0_4 [[texture(6)]],
    texture2d<float> x0_5 [[texture(7)]],
    texture2d<float> x0_6 [[texture(8)]],
    texture2d<float> x0_7 [[texture(9)]],
    texture2d<float> x0_8 [[texture(10)]],
    texture2d<float> g0 [[texture(11)]],
    texture2d<float> f0_1 [[texture(12)]],
    texture2d<float> f0_2 [[texture(13)]],
    texture2d<float> f0_3 [[texture(14)]],
    texture2d<float> x2 [[texture(15)]],
    texture2d<float> x2_1 [[texture(16)]],
    texture2d<float> x2_2 [[texture(17)]],
    texture2d<float> x2_3 [[texture(18)]],
    texture2d<float> x2_4 [[texture(19)]],
    texture2d<float> x2_5 [[texture(20)]],
    texture2d<float> x2_6 [[texture(21)]],
    texture2d<float> x2_7 [[texture(22)]],
    texture2d<float> x2_8 [[texture(23)]],
    texture2d<float> g2 [[texture(24)]],
    texture2d<float> f2_1 [[texture(25)]],
    texture2d<float> f2_2 [[texture(26)]],
    texture2d<float> f2_3 [[texture(27)]],
    texture2d<float> f2_4 [[texture(28)]],
    texture2d<float> f2_5 [[texture(29)]],
    texture2d<float> f2_6 [[texture(30)]],
    texture2d<float> f2_7 [[texture(31)]],
    texture2d<float> f2_8 [[texture(32)]],
    texture2d<float> x6 [[texture(33)]],
    texture2d<float> x6_1 [[texture(34)]],
    texture2d<float> x6_2 [[texture(35)]],
    texture2d<float> x6_3 [[texture(36)]],
    texture2d<float> x6_4 [[texture(37)]],
    texture2d<float> x6_5 [[texture(38)]],
    texture2d<float> x6_6 [[texture(39)]],
    texture2d<float> x6_7 [[texture(40)]],
    texture2d<float> x6_8 [[texture(41)]],
    texture2d<float> g6 [[texture(42)]],
    texture2d<float> f6_1 [[texture(43)]],
    texture2d<float> f6_2 [[texture(44)]],
    texture2d<float> f6_3 [[texture(45)]],
    texture2d<float> f6_4 [[texture(46)]],
    texture2d<float> f6_5 [[texture(47)]],
    texture2d<float> f6_6 [[texture(48)]],
    texture2d<float> f6_7 [[texture(49)]],
    texture2d<float> f6_8 [[texture(50)]],
    texture2d<float> x8 [[texture(51)]],
    texture2d<float> x8_1 [[texture(52)]],
    texture2d<float> x8_2 [[texture(53)]],
    texture2d<float> x8_3 [[texture(54)]],
    texture2d<float> x8_4 [[texture(55)]],
    texture2d<float> x8_5 [[texture(56)]],
    texture2d<float> x8_6 [[texture(57)]],
    texture2d<float> x8_7 [[texture(58)]],
    texture2d<float> x8_8 [[texture(59)]],
    texture2d<float> g8 [[texture(60)]],
    texture2d<float> f8_1 [[texture(61)]],
    texture2d<float> f8_2 [[texture(62)]],
    texture2d<float> f8_3 [[texture(63)]],
    texture2d<float> x9 [[texture(64)]],
    texture2d<float> x9_1 [[texture(65)]],
    texture2d<float> x9_2 [[texture(66)]],
    texture2d<float> x9_3 [[texture(67)]],
    texture2d<float> x9_4 [[texture(68)]],
    texture2d<float> x9_5 [[texture(69)]],
    texture2d<float> x9_6 [[texture(70)]],
    texture2d<float> x9_7 [[texture(71)]],
    texture2d<float> x9_8 [[texture(72)]],
    texture2d<float> g9 [[texture(73)]],
    texture2d<float> f9_1 [[texture(74)]],
    texture2d<float> f9_2 [[texture(75)]],
    texture2d<float> f9_3 [[texture(76)]],
    texture2d<float> f9_4 [[texture(77)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = float4(antes0(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = float4(descer(x0), 1.0); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = float4(descer(x0_1), 1.0); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = float4(descer(x0_2), 1.0); return __nv_out; }
    if (eng.acPass == 4) { __nv_out = float4(descer(x0_3), 1.0); return __nv_out; }
    if (eng.acPass == 5) { __nv_out = float4(descer(x0_4), 1.0); return __nv_out; }
    if (eng.acPass == 6) { __nv_out = float4(descer(x0_5), 1.0); return __nv_out; }
    if (eng.acPass == 7) { __nv_out = float4(descer(x0_6), 1.0); return __nv_out; }
    if (eng.acPass == 8) { __nv_out = float4(descer(x0_7), 1.0); return __nv_out; }
    if (eng.acPass == 9) { __nv_out = float4(popDe0(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 10) { __nv_out = descerComCorte(g0, 0.300000, 0.150000); return __nv_out; }
    if (eng.acPass == 11) { __nv_out = descerLuz(f0_1); return __nv_out; }
    if (eng.acPass == 12) { __nv_out = descerLuz(f0_2); return __nv_out; }
    if (eng.acPass == 13) { __nv_out = float4(antes2(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 14) { __nv_out = float4(descer(x2), 1.0); return __nv_out; }
    if (eng.acPass == 15) { __nv_out = float4(descer(x2_1), 1.0); return __nv_out; }
    if (eng.acPass == 16) { __nv_out = float4(descer(x2_2), 1.0); return __nv_out; }
    if (eng.acPass == 17) { __nv_out = float4(descer(x2_3), 1.0); return __nv_out; }
    if (eng.acPass == 18) { __nv_out = float4(descer(x2_4), 1.0); return __nv_out; }
    if (eng.acPass == 19) { __nv_out = float4(descer(x2_5), 1.0); return __nv_out; }
    if (eng.acPass == 20) { __nv_out = float4(descer(x2_6), 1.0); return __nv_out; }
    if (eng.acPass == 21) { __nv_out = float4(descer(x2_7), 1.0); return __nv_out; }
    if (eng.acPass == 22) { __nv_out = float4(popDe2(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 23) { __nv_out = descerComCorte(g2, 0.300000, 0.450000); return __nv_out; }
    if (eng.acPass == 24) { __nv_out = descerLuz(f2_1); return __nv_out; }
    if (eng.acPass == 25) { __nv_out = descerLuz(f2_2); return __nv_out; }
    if (eng.acPass == 26) { __nv_out = descerLuz(f2_3); return __nv_out; }
    if (eng.acPass == 27) { __nv_out = descerLuz(f2_4); return __nv_out; }
    if (eng.acPass == 28) { __nv_out = descerLuz(f2_5); return __nv_out; }
    if (eng.acPass == 29) { __nv_out = descerLuz(f2_6); return __nv_out; }
    if (eng.acPass == 30) { __nv_out = descerLuz(f2_7); return __nv_out; }
    if (eng.acPass == 31) { __nv_out = float4(antes6(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 32) { __nv_out = float4(descer(x6), 1.0); return __nv_out; }
    if (eng.acPass == 33) { __nv_out = float4(descer(x6_1), 1.0); return __nv_out; }
    if (eng.acPass == 34) { __nv_out = float4(descer(x6_2), 1.0); return __nv_out; }
    if (eng.acPass == 35) { __nv_out = float4(descer(x6_3), 1.0); return __nv_out; }
    if (eng.acPass == 36) { __nv_out = float4(descer(x6_4), 1.0); return __nv_out; }
    if (eng.acPass == 37) { __nv_out = float4(descer(x6_5), 1.0); return __nv_out; }
    if (eng.acPass == 38) { __nv_out = float4(descer(x6_6), 1.0); return __nv_out; }
    if (eng.acPass == 39) { __nv_out = float4(descer(x6_7), 1.0); return __nv_out; }
    if (eng.acPass == 40) { __nv_out = float4(popDe6(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 41) { __nv_out = descerComCorte(g6, 0.000000, 0.150000); return __nv_out; }
    if (eng.acPass == 42) { __nv_out = descerLuz(f6_1); return __nv_out; }
    if (eng.acPass == 43) { __nv_out = descerLuz(f6_2); return __nv_out; }
    if (eng.acPass == 44) { __nv_out = descerLuz(f6_3); return __nv_out; }
    if (eng.acPass == 45) { __nv_out = descerLuz(f6_4); return __nv_out; }
    if (eng.acPass == 46) { __nv_out = descerLuz(f6_5); return __nv_out; }
    if (eng.acPass == 47) { __nv_out = descerLuz(f6_6); return __nv_out; }
    if (eng.acPass == 48) { __nv_out = descerLuz(f6_7); return __nv_out; }
    if (eng.acPass == 49) { __nv_out = float4(antes8(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 50) { __nv_out = float4(descer(x8), 1.0); return __nv_out; }
    if (eng.acPass == 51) { __nv_out = float4(descer(x8_1), 1.0); return __nv_out; }
    if (eng.acPass == 52) { __nv_out = float4(descer(x8_2), 1.0); return __nv_out; }
    if (eng.acPass == 53) { __nv_out = float4(descer(x8_3), 1.0); return __nv_out; }
    if (eng.acPass == 54) { __nv_out = float4(descer(x8_4), 1.0); return __nv_out; }
    if (eng.acPass == 55) { __nv_out = float4(descer(x8_5), 1.0); return __nv_out; }
    if (eng.acPass == 56) { __nv_out = float4(descer(x8_6), 1.0); return __nv_out; }
    if (eng.acPass == 57) { __nv_out = float4(descer(x8_7), 1.0); return __nv_out; }
    if (eng.acPass == 58) { __nv_out = float4(popDe8(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 59) { __nv_out = descerComCorte(g8, 0.300000, 0.450000); return __nv_out; }
    if (eng.acPass == 60) { __nv_out = descerLuz(f8_1); return __nv_out; }
    if (eng.acPass == 61) { __nv_out = descerLuz(f8_2); return __nv_out; }
    if (eng.acPass == 62) { __nv_out = float4(antes9(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 63) { __nv_out = float4(descer(x9), 1.0); return __nv_out; }
    if (eng.acPass == 64) { __nv_out = float4(descer(x9_1), 1.0); return __nv_out; }
    if (eng.acPass == 65) { __nv_out = float4(descer(x9_2), 1.0); return __nv_out; }
    if (eng.acPass == 66) { __nv_out = float4(descer(x9_3), 1.0); return __nv_out; }
    if (eng.acPass == 67) { __nv_out = float4(descer(x9_4), 1.0); return __nv_out; }
    if (eng.acPass == 68) { __nv_out = float4(descer(x9_5), 1.0); return __nv_out; }
    if (eng.acPass == 69) { __nv_out = float4(descer(x9_6), 1.0); return __nv_out; }
    if (eng.acPass == 70) { __nv_out = float4(descer(x9_7), 1.0); return __nv_out; }
    if (eng.acPass == 71) { __nv_out = float4(popDe9(in.acScreenNorm), 1.0); return __nv_out; }
    if (eng.acPass == 72) { __nv_out = descerComCorte(g9, 0.300000, 0.450000); return __nv_out; }
    if (eng.acPass == 73) { __nv_out = descerLuz(f9_1); return __nv_out; }
    if (eng.acPass == 74) { __nv_out = descerLuz(f9_2); return __nv_out; }
    if (eng.acPass == 75) { __nv_out = descerLuz(f9_3); return __nv_out; }
    float4 base = inputImg.sample(__nv_smp, in.acScreenNorm);
    __nv_out = float4(mix(base.rgb, fim(in.acScreenNorm), u.uIntensidade), base.a);
    return __nv_out;
}
