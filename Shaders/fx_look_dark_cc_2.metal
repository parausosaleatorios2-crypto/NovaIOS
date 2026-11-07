// ---------------------------------------------------------------------------
// Dark CC 2
// origem : assets/effects/look-dark-cc-2.xml
// id     : nova.effect.look.dark-cc-2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct look_dark_cc_2Params {
    float uIntensidade;
};

// --- funcoes auxiliares do efeito
const float uDetalhe = 1.0;
const float uGlow = 1.0;

// u.uIntensidade, uGlow e uDetalhe vêm dos <params> (o prelúdio declara).

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


float3 fim(float2 uv) {
    float3 c = clamp(inputImg.sample(__nv_smp, uv).rgb, 0.0, 1.0);
    c = lut(c, 0.0);
    return c;
}

fragment float4 fx_look_dark_cc_2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant look_dark_cc_2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> atlas [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 base = inputImg.sample(__nv_smp, in.acScreenNorm);
    __nv_out = float4(mix(base.rgb, fim(in.acScreenNorm), u.uIntensidade), base.a);
    return __nv_out;
}
