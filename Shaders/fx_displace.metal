// ---------------------------------------------------------------------------
// Deslocar por mapa
// origem : assets/effects/displace.xml
// id     : nova.effect.displace
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct displaceParams {
    int channel;
    int viewMap;
    int invertMap;
    float mapGamma;
    float mapSoftness;
    float mapMixInput;
    float displacementOffset;
    int easing;
    int mapInterpretation;
    float translateX;
    float translateY;
    float rotate;
    int uniformScale;
    int clampNegativeScale;
    float scaleX;
    float scaleY;
    float2 anchor;
    float iterations;
    float shutterDuration;
    float caRed;
    float caGreen;
    float caBlue;
    int edgeBehavior;
};

// --- funcoes auxiliares do efeito
const int MAX_ITER = 32;

// O valor do mapa em 16 bits (dois canais de um buffer de 8): com 8 bits, um Translate de
// 50 % numa camada de 1080 px andaria em degraus de 4 px.
float2 enc16(float v) {
    float q = floor(clamp(v, 0.0, 1.0) * 65535.0 + 0.5);
    float a = floor(q / 256.0);
    return float2(a, q - a * 256.0) / 255.0;
}
float dec16(float2 c) {
    float2 b = floor(c * 255.0 + 0.5);
    return (b.x * 256.0 + b.y) / 65535.0;
}

/** O canal escolhido de uma cor (reta); os de cor leem a PRÉ-MULTIPLICADA, como o AE. */
float canalDe(float4 c) {
    if (u.channel == 3) return c.a;
    float3 p = c.rgb * c.a;
    if (u.channel == 0) return p.r;
    if (u.channel == 1) return p.g;
    if (u.channel == 2) return p.b;
    float mx = max(p.r, max(p.g, p.b));
    float mn = min(p.r, min(p.g, p.b));
    if (u.channel == 5) return mx > 0.0 ? (mx - mn) / mx : 0.0;       // Saturation (HSV)
    if (u.channel == 4) {                                             // Hue, 0..1
        float d = mx - mn;
        if (d <= 1e-6) return 0.0;
        float h = mx == p.r ? (p.g - p.b) / d : (mx == p.g ? 2.0 + (p.b - p.r) / d : 4.0 + (p.r - p.g) / d);
        return fract(h / 6.0);
    }
    return (p.r + p.g + p.b) / 3.0;                                 // Lightness: a média
}

float vaEm(int2 p) {
    return dec16(va.read(uint2(clamp(p, int2(0), int2(int(va.get_width()), int(va.get_height())) - 1)), uint(0)).rg);
}
float vbEm(int2 p) {
    return dec16(vb.read(uint2(clamp(p, int2(0), int2(int(vb.get_width()), int(vb.get_height())) - 1)), uint(0)).rg);
}

/** Um eixo do gaussiano do Map Softness (σ = Softness/4 px da camada). */
float sigmaDoMapa() { return u.mapSoftness * 0.25 * max(eng.acEscalaDePixel, 1e-3); }

float borrar(bool deVa, int2 eixo) {
    int2 p = int2(__nv_fragCoord.xy);
    float sigma = sigmaDoMapa();
    if (sigma < 0.05) return deVa ? vaEm(p) : vbEm(p);
    int2 tamanho = int2(int(va.get_width()), int(va.get_height()));
    int passo = max(1, int(ceil(3.0 * sigma / 40.0)));
    float soma = 0.0;
    float pesos = 0.0;
    for (int k = -40; k <= 40; k++) {
        float d = float(k * passo);
        if (abs(d) > 3.0 * sigma + 0.5) continue;
        float w = exp(-0.5 * d * d / (sigma * sigma));
        int2 q = p + eixo * k * passo;
        // Fora da camada o mapa vale ZERO (medido: o mapa suavizado escurece perto da borda).
        bool dentro = q.x >= 0 && q.y >= 0 && q.x < tamanho.x && q.y < tamanho.y;
        if (dentro) soma += w * (deVa ? vaEm(q) : vbEm(q));
        pesos += w;
    }
    return soma / max(pesos, 1e-6);
}

/** O alfa do mapa naquele pixel (só para a vista do mapa), guardado no azul. */
float alfaDoMapa(bool deVa) {
    int2 p = int2(__nv_fragCoord.xy);
    return deVa ? va.read(uint2(p), uint(0)).b : vb.read(uint2(p), uint(0)).b;
}

/** O valor (borrado) do mapa em `uv`, com a interpolação bilinear feita à mão (16 bits). */
float mapaEm(float2 uv) {
    float2 t = uv * float2(int2(int(va.get_width()), int(va.get_height()))) - 0.5;
    int2 i = int2(floor(t));
    float2 f = t - float2(i);
    return mix(mix(vaEm(i), vaEm(i + int2(1, 0)), f.x),
               mix(vaEm(i + int2(0, 1)), vaEm(i + int2(1, 1)), f.x), f.y);
}

float expoIn(float x) { return pow(2.0, 10.0 * x - 10.0); }
float expoOut(float x) { return 1.0 - pow(2.0, -10.0 * x); }

/** De valor do mapa (0..1) para o `m` que comanda a transformação. */
float forca(float v) {
    if (u.invertMap) v = 1.0 - v;
    v = pow(max(v, 0.0), u.mapGamma);
    float m = u.mapInterpretation == 0 ? v * 2.0 - 1.0 : v;
    m += (m < 0.0 ? -1.0 : 1.0) * u.displacementOffset;
    if (u.easing == 1) m = m < 0.5 ? 0.5 * pow(2.0, 20.0 * m - 10.0) : 0.5 * (2.0 - pow(2.0, -20.0 * m + 10.0));
    else if (u.easing == 2) m = expoIn(m);
    else if (u.easing == 3) m = expoOut(m);
    return m;
}

float4 lerFonte(float2 uv) {
    if (u.edgeBehavior == 0) {
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return float4(0.0);
    } else if (u.edgeBehavior == 1) {
        uv = fract(uv);
    } else if (u.edgeBehavior == 2) {
        uv = 1.0 - abs(1.0 - __nv_mod(uv, 2.0));
    }
    return inputImg.sample(__nv_smp, clamp(uv, 0.0, 1.0));
}

/** De onde o pixel `uv` lê, com a força `m` (ver a conta no cabeçalho). `some` = o Clamp
 *  Negative Scale apagou este pixel (a escala inverteria). */
float2 origem(float2 uv, float m, out bool some) {
    float2 res = eng.acResolution;
    float2 p = (uv - u.anchor) * res;
    float ang = radians(u.rotate) * m;
    float c = cos(ang);
    float s = sin(ang);
    float2 q = float2(c * p.x + s * p.y, -s * p.x + c * p.y) - float2(u.translateX, u.translateY) * 0.01 * res * m;
    float ex = abs(u.scaleX) < 0.01 ? (u.scaleX < 0.0 ? -0.01 : 0.01) : u.scaleX;
    float eyBruto = u.uniformScale ? u.scaleX : u.scaleY;
    float ey = abs(eyBruto) < 0.01 ? (eyBruto < 0.0 ? -0.01 : 0.01) : eyBruto;
    float2 k = float2(1.0) + (float2(100.0 / ex, 100.0 / ey) - 1.0) * m;
    // Medido: com o Clamp ligado, onde a escala passaria de zero o pixel fica transparente.
    some = u.clampNegativeScale && (k.x <= 0.0 || k.y <= 0.0);
    return u.anchor + k * q / res;
}

float4 lerCom(float2 uv, float m) {
    bool some;
    float2 o = origem(uv, m, some);
    return some ? float4(0.0) : lerFonte(o);
}

fragment float4 fx_displace(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant displaceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> mapImg [[texture(1)]],
    texture2d<float> va [[texture(2)]],
    texture2d<float> vb [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        // O valor do mapa: o canal escolhido, misturado com o da própria camada.
        float4 mapa = mapImg.sample(__nv_smp, in.acScreenNorm);
        float v = canalDe(mapa);
        if (u.mapMixInput > 0.0) v = mix(v, canalDe(inputImg.sample(__nv_smp, in.acScreenNorm)), u.mapMixInput * 0.01);
        __nv_out = float4(enc16(v), mapa.a, 1.0);
        return __nv_out;
    }
    if (eng.acPass == 1) { __nv_out = float4(enc16(borrar(true, int2(1, 0))), alfaDoMapa(true), 1.0); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = float4(enc16(borrar(false, int2(0, 1))), alfaDoMapa(false), 1.0); return __nv_out; }

    float2 uv = in.acScreenNorm;
    // Sem camada escolhida o motor entrega 1×1: a imagem passa intacta.
    if (int2(int(mapImg.get_width()), int(mapImg.get_height())).x <= 1) { __nv_out = inputImg.sample(__nv_smp, uv); return __nv_out; }

    float v = mapaEm(uv);
    // A vista mostra o valor do mapa (já suavizado, antes do invert e do gamma) × o alfa dele.
    if (u.viewMap) { __nv_out = float4(float3(v * va.sample(__nv_smp, uv).b), 1.0); return __nv_out; }
    float m = forca(v);

    int n = int(clamp(u.iterations, 1.0, float(MAX_ITER)));
    bool aberracao = u.caRed != u.caGreen || u.caGreen != u.caBlue;
    float4 soma = float4(0.0);
    for (int i = 0; i < MAX_ITER; i++) {
        if (i >= n) break;
        float mi = m * (1.0 - 0.5 * u.shutterDuration * 0.01 * float(i) / float(n));
        if (aberracao) {
            float4 r = lerCom(uv, mi * u.caRed);
            float4 g = lerCom(uv, mi * u.caGreen);
            float4 b = lerCom(uv, mi * u.caBlue);
            // Medido: o alfa NÃO segue os multiplicadores — é o da leitura com o `m` puro
            // (a borda do alfa fica a exatamente 1 deslocamento, com qualquer R/G/B). Onde
            // ele é zero não sobra cor nenhuma.
            float a = lerCom(uv, mi).a;
            soma += float4(float3(r.r * r.a, g.g * g.a, b.b * b.a) * a, a);
        } else {
            float4 c = lerCom(uv, mi * u.caGreen);
            soma += float4(c.rgb * c.a, c.a);
        }
    }
    soma /= float(n);
    __nv_out = soma.a > 1e-5 ? float4(soma.rgb / soma.a, soma.a) : float4(0.0);
    return __nv_out;
}
