// ---------------------------------------------------------------------------
// CC Jaws
// origem : assets/effects/cc-jaws.xml
// id     : nova.effect.ccjaws
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct cc_jawsParams {
    float completion;
    float2 center;
    float direction;
    float height;
    float width;
    int shape;
};

// --- funcoes auxiliares do efeito
// 0.915.0: as PowerVR (GE8320/GE8322) recusavam este shader ("Compile failed.", 11 aparelhos na 0.894.0) e o
// `inversesqrt` era a única coisa dele que nenhum efeito que roda nelas usa: agora 1/sqrt, e o pow(x, 2) virou x·x.

const float PI = 3.14159265;

fragment float4 fx_cc_jaws(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant cc_jawsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 cor = inputImg.sample(__nv_smp, in.acScreenNorm);
    float c = u.completion * 0.01;
    // O AE devolve a camada intacta no 0% (conferido: igual à fonte).
    if (c <= 0.0) {
        __nv_out = cor;
        return __nv_out;
    }

    float2 res = eng.acResolution;
    float2 centro = u.center * res;
    // Coordenada inteira do pixel, relativa ao Centro (ver o cabeçalho).
    float2 p = in.acScreenNorm * res - 0.5 - centro;

    float th = radians(u.direction);
    float2 t = float2(cos(th), sin(th));   // ao longo da fileira de dentes
    float2 n = float2(-t.y, t.x);          // para onde a boca abre

    float W = res.x;
    float per = max(u.width / 50.0 * W, 1e-3);
    float A = u.height * 0.01 * W;

    // O canto mais longe do Centro ao longo da normal.
    float2 a = -centro;
    float2 b = res - centro;
    float alcance = max(
        max(abs(dot(a, n)), abs(dot(float2(b.x, a.y), n))),
        max(abs(dot(float2(a.x, b.y), n)), abs(dot(b, n))));
    float base = alcance + 0.5 * A;

    float st = dot(p, t);
    float v = dot(p, n);
    float u = st / per;
    float d = abs(u - floor(u + 0.5));   // 0 no meio do dente, 0.5 entre dois

    // dT/dB: quanto o pixel está DENTRO da metade de cima/de baixo, já na
    // escala da suavização (>= 1 inteiro visível, <= 0 dentro da boca).
    float dT;
    float dB;
    if (u.shape == 3) {
        // ---- Ondas ----
        float incl = PI * A / per;   // a inclinação máxima da onda
        float e = 0.5 * (1.0 + incl);
        float G = -1.11246 * e + c * 1.00013 * (base + 1.08721 * e);
        float f = 0.5 * A * cos(2.0 * PI * u);
        float den = 1.0 + 0.98438 * incl * abs(sin(2.0 * PI * u));
        dT = (f - G - v) / den - 0.01222;
        dB = (v - G - f) / den - 0.01222;
    } else {
        float G = base * (1.00225 * c - 0.00067);
        if (u.shape == 0) {
            // ---- Dentes (triângulos) ----
            float f = A * (2.0 * d - 0.5);
            float k = 1.0 / sqrt(1.0 + (2.0 * A / per) * (2.0 * A / per));
            dT = (f - G - v) * k + 0.35;
            dB = (v - G - f) * k + 0.35;
        } else if (u.shape == 1) {
            // ---- Mandíbula robô (trapézios: 1/3 em cima, 1/6 de rampa) ----
            float f = A * (clamp((d - 1.0 / 6.0) * 6.0, 0.0, 1.0) - 0.5);
            bool rampa = d > 1.0 / 6.0 && d < 1.0 / 3.0;
            float k = rampa ? 1.0 / sqrt(1.0 + (6.12 * A / per) * (6.12 * A / per)) : 0.665;
            float o = rampa ? 0.036 : 0.352;
            dT = (f - G - v) * k + o;
            dB = (v - G - f) * k + o;
        } else {
            // ---- Blocos ----
            // A metade de cima avança onde a fase está em (0, 1/2]; a de baixo,
            // no resto. `h` = distância até o degrau, positiva dentro desse trecho.
            float w = __nv_mod(st - 0.75, per);
            float h = w <= 0.5 * per ? min(w, 0.5 * per - w) : -min(w - 0.5 * per, per - w);
            dT = max((-G - 0.5 * A - v) * 0.672 + 0.355,
                     min((-G + 0.5 * A - v) * 0.672 + 0.355, h * 0.668 + 0.5));
            dB = max((v - G - 0.5 * A) * 0.672 + 0.355,
                     min((v - G + 0.5 * A) * 0.672 + 0.355, -h * 0.668 + 0.5));
        }
    }

    float visivel = min(clamp(dT, 0.0, 1.0) + clamp(dB, 0.0, 1.0), 1.0);
    __nv_out = float4(cor.rgb, cor.a * visivel);
    return __nv_out;
}
