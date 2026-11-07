// ---------------------------------------------------------------------------
// Raios divinos
// origem : assets/effects/raios-divinos.xml
// id     : nova.effect.raiosdivinos
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct raios_divinosParams {
    int mode;
    float2 position;
    int thresholdMode;
    float threshold;
    float thresholdSmooth;
    float rayLength;
    float amount;
    float exposure;
    float decay;
    int direction;
    float4 rayColor;
    float caAmount;
    int caChannels;
    int repeatEdges;
    float inputOpacity;
    int rayBlend;
    int unmult;
    int view;
};

// --- funcoes auxiliares do efeito
const int N = 64;

// Buffers de 8 bits: a raiz quadrada dá precisão ao escuro (a ponta do raio).
float4 guardar(float4 v) { return float4(sqrt(clamp(v.rgb, 0.0, 1.0)), clamp(v.a, 0.0, 1.0)); }
float4 abrir(float4 g) { return float4(g.rgb * g.rgb, g.a); }

/** A fonte de um pixel da camada: limiar, tinta, oclusão, pré-multiplicada; alfa 1 dentro do quadro. */
float4 fonteEm(float2 uv) {
    float4 c = inputImg.sample(__nv_smp, uv);
    float t = u.threshold * 0.01;
    if (t > 0.0) {
        float s = u.thresholdSmooth * 0.01;
        if (u.thresholdMode == 0) {
            float g = (c.r + c.g + c.b) * 0.333;
            c.rgb *= smoothstep(t - s, t + s, g);
        } else {
            c.rgb *= smoothstep(float3(t - s), float3(t + s), c.rgb);
        }
    }
    float3 luz = c.rgb * u.rayColor.rgb * c.a;
    // Sem camada escolhida o motor entrega 1×1 (empty="transparent").
    if (int2(int(occluderImg.get_width()), int(occluderImg.get_height())).x > 1) luz *= 1.0 - occluderImg.sample(__nv_smp, uv).a;
    return float4(luz, 1.0);
}

/** A fonte (passe 0) lida em qualquer uv: espelhada além da borda, ou nada (Repeat Edges). */
float4 fonteLida(float2 uv) {
    if (u.repeatEdges) return abrir(a.sample(__nv_smp, 1.0 - abs(__nv_mod(uv, 2.0) - 1.0)));
    if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return float4(0.0);
    return abrir(a.sample(__nv_smp, uv));
}

/** O raio Zoom de um canal: densidade `d`, os sentidos pela Direction. */
float4 zoom(float2 uv, float2 pos, float d, float jit) {
    float2 passo = (uv - pos) * d / float(N);
    float queda = 1.0 - 2.0 * u.decay / float(N);
    float4 soma = float4(0.0);
    if (u.direction == 0 || u.direction == 2) {
        float2 p = uv - passo * (1.0 - jit);
        float w = u.exposure / float(N);
        for (int i = 0; i < N; i++) { soma += fonteLida(p) * w; w *= queda; p -= passo; }
    }
    if (u.direction == 1 || u.direction == 2) {
        float2 p = uv - passo * (1.0 - jit);
        if (u.direction == 2) p += passo;
        float w = u.exposure / float(N);
        for (int i = 0; i < N; i++) { soma += fonteLida(p) * w; w *= queda; p += passo; }
    }
    return soma;
}

/** O giro em volta da Position (x corrigido por altura/largura, como o Crate's). */
float2 girar(float2 uv, float2 pos, float ang) {
    float asp = eng.acResolution.y / eng.acResolution.x;
    float2 r = uv - pos;
    r.x /= asp;
    float c = cos(ang);
    float s = sin(ang);
    r = float2(r.x * c + r.y * s, -r.x * s + r.y * c);
    r.x *= asp;
    return r + pos;
}

float4 spin(float2 uv, float2 pos, float incr) {
    float queda = 1.0 - 0.5 * u.decay / float(N);
    float w = u.exposure / float(N);
    float ang = 0.0;
    float4 soma = float4(0.0);
    for (int i = 0; i < N; i++) {
        soma += (fonteLida(girar(uv, pos, ang)) + fonteLida(girar(uv, pos, -ang))) * w;
        ang += incr;
        w *= queda;
    }
    return soma;
}

float4 oRaio() {
    float2 uv = in.acScreenNorm;
    // Ruído intercalado: desloca o começo de cada pixel numa fração do passo (some na tenda).
    float jit = fract(52.9829189 * fract(dot(__nv_fragCoord.xy, float2(0.06711056, 0.00583715))));
    float ca = u.caAmount * 0.01;
    if (u.mode == 1) {
        float incr = u.amount * 0.01 / float(N);
        if (ca == 0.0) return spin(uv, u.position, incr);
        float3 k = u.caChannels == 0 ? float3(1.0 + ca, 1.0, 1.0 - ca)
               : (u.caChannels == 1 ? float3(1.0 + ca, 1.0 - ca, 1.0) : float3(1.0, 1.0 + ca, 1.0 - ca));
        float4 r = spin(uv, u.position, incr * k.r);
        float4 g = spin(uv, u.position, incr * k.g);
        float4 b = spin(uv, u.position, incr * k.b);
        return float4(r.r, g.g, b.b, (r.a + g.a + b.a) * 0.333);
    }
    // Length em pixels da camada (o buffer está em escala de prévia: volta pela eng.acEscalaDePixel).
    float largura = float(int2(int(inputImg.get_width()), int(inputImg.get_height())).x) / max(eng.acEscalaDePixel, 1e-4);
    float d = min(u.rayLength / largura, 1.0);
    if (ca == 0.0) return zoom(uv, u.position, d, jit);
    float m = ca * 0.1;
    float3 dd = u.caChannels == 0 ? float3(d + m, d, d - m) : (u.caChannels == 1 ? float3(d + m, d - m, d) : float3(d, d + m, d - m));
    float4 r = zoom(uv, u.position, dd.r, jit);
    float4 g = zoom(uv, u.position, dd.g, jit);
    float4 b = zoom(uv, u.position, dd.b, jit);
    return float4(r.r, g.g, b.b, (r.a + g.a + b.a) * 0.333);
}

/** O raio pronto, lido com uma tenda de quatro leituras (sobe de 1/2 sem degrau). */
float4 raioPronto(float2 uv) {
    float2 t = 0.5 / float2(int2(int(b.get_width()), int(b.get_height())));
    return 0.25 * (abrir(b.sample(__nv_smp, uv + float2(-t.x, -t.y))) + abrir(b.sample(__nv_smp, uv + float2(t.x, -t.y)))
        + abrir(b.sample(__nv_smp, uv + float2(-t.x, t.y))) + abrir(b.sample(__nv_smp, uv + float2(t.x, t.y))));
}

fragment float4 fx_raios_divinos(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant raios_divinosParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> a [[texture(1)]],
    texture2d<float> b [[texture(2)]],
    texture2d<float> occluderImg [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        // Média dos 4 pixels cheios do bloco: o limiar vale por pixel, antes da média.
        float2 px = 1.0 / float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
        float2 uv = in.acScreenNorm;
        float4 f = 0.25 * (fonteEm(uv + float2(-0.5, -0.5) * px) + fonteEm(uv + float2(0.5, -0.5) * px)
            + fonteEm(uv + float2(-0.5, 0.5) * px) + fonteEm(uv + float2(0.5, 0.5) * px));
        __nv_out = guardar(f);
        return __nv_out;
    }
    if (eng.acPass == 1) { __nv_out = guardar(oRaio()); return __nv_out; }

    float2 uv = in.acScreenNorm;
    if (u.view == 2) {
        __nv_out = float4(clamp(fonteEm(uv).rgb, 0.0, 1.0), 1.0);
        return __nv_out;
    }
    float4 r = raioPronto(uv);
    float3 rgb = clamp(r.rgb, 0.0, 1.0);
    float aR;
    float3 cor;
    if (u.unmult) {
        aR = min(max(rgb.r, max(rgb.g, rgb.b)), 1.0);
        cor = aR > 0.0 ? rgb / aR : float3(0.0);
    } else {
        aR = min(r.a, 1.0);
        cor = aR > 0.0 ? rgb / aR : float3(0.0);
    }
    if (u.view == 1) {
        __nv_out = float4(clamp(cor, 0.0, 1.0), aR);
        return __nv_out;
    }
    float4 base = inputImg.sample(__nv_smp, uv);
    float aB = base.a * u.inputOpacity * 0.01;
    float3 bp = base.rgb * aB;
    float3 rp = cor * aR;
    float3 p = u.rayBlend == 0 ? bp + rp - bp * rp : bp + rp;
    float alfa = aB + aR - aB * aR;
    __nv_out = float4(alfa > 0.0001 ? clamp(p / alfa, 0.0, 1.0) : float3(0.0), clamp(alfa, 0.0, 1.0));
    return __nv_out;
}
