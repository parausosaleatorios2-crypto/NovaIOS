// ---------------------------------------------------------------------------
// Escrita à mão
// origem : assets/effects/handwriting-reveal.xml
// id     : nova.effect.handwriting
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct handwriting_revealParams {
    float duration;
    float startDelay;
    float angle;
    int invert;
    float feather;
    float wobble;
    float wobbleFreq;
    int showTip;
    float4 tipColor;
    float tipSize;
    float tipIntensity;
};

// --- funcoes auxiliares do efeito
static float hash21(float2 p) {
    p = fract(p * float2(127.1, 311.7));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

static float valueNoise(float2 p) {
    float2 cell = floor(p);
    float2 f = fract(p);
    float2 w = f * f * (3.0 - 2.0 * f);
    float a = hash21(cell);
    float b = hash21(cell + float2(1.0, 0.0));
    float c = hash21(cell + float2(0.0, 1.0));
    float d = hash21(cell + float2(1.0, 1.0));
    return mix(mix(a, b, w.x), mix(c, d, w.x), w.y);
}

static float fbm(float2 p) {
    float soma = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 3; i++) {
        soma += amplitude * valueNoise(p);
        p *= 2.07;
        amplitude *= 0.5;
    }
    return soma;
}

fragment float4 fx_handwriting_reveal(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant handwriting_revealParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 source = inputImg.sample(__nv_smp, in.acScreenNorm);

    float rad = radians(u.angle);
    float2 axis = float2(cos(rad), sin(rad));
    float2 perp = float2(-axis.y, axis.x);
    float2 centred = (in.acScreenNorm - 0.5) * float2(eng.acAspect, 1.0);

    // Mesma normalização de `linear-wipe.xml`: sem isso, a mesma duração
    // revelaria mais rápido na diagonal do que na horizontal.
    float support = max(0.5 * (eng.acAspect * abs(axis.x) + abs(axis.y)), 0.0001);

    float progress = clamp((eng.acTime - u.startDelay) / max(u.duration, 0.001), 0.0, 1.0);
    if (u.invert) progress = 1.0 - progress;

    // A borda ondula por RUÍDO FRACTAL, não por seno — ruído não repete a
    // própria forma, que é o que denunciava "cortina" na primeira versão. A
    // segunda dimensão do ruído é o PROGRESSO: a forma muda enquanto a
    // escrita anda, em vez de ser uma onda parada que só desliza de lugar.
    float perpCoord = dot(centred, perp);
    float ruido = fbm(float2(perpCoord * u.wobbleFreq, progress * 2.2)) * 2.0 - 1.0;

    float along = dot(centred, axis) + ruido * u.wobble;
    float position = (along + support) / (2.0 * support);

    // Grão fino por pixel: quebra a aresta perfeitamente anti-serrilhada do
    // `smoothstep` — tinta de verdade não tem borda de vetor.
    float grao = (hash21(in.acScreenNorm * eng.acResolution / eng.acEscalaDePixel * 0.5) - 0.5) * u.feather * 0.8;

    // Ao contrário de `linear-wipe`, aqui não é a pessoa que anima "quanto
    // esconder": é "quanto já foi escrito". Pixel revelado quando a escrita
    // (progress) já passou da posição dele.
    float soft = max(u.feather, 0.0005);
    float mask = smoothstep(position - soft, position + soft, progress + grao);

    float3 rgb = source.rgb;
    float alpha = source.a * mask;

    if (u.showTip) {
        // Onde a borda de revelação cruza o CENTRO da camada (perpCoord=0,
        // sem a ondulação) — o lugar mais estável para a ponta seguir, sem
        // ela mesma ondular feito a borda.
        float tipAlong = support * (2.0 * progress - 1.0);
        float2 tip = axis * tipAlong;
        float2 delta = centred - tip;
        float dist = length(delta);
        float glow = exp(-dist * dist / max(u.tipSize * u.tipSize, 0.0001));

        // Nasce com a escrita, some quando ela termina — sem isso, a ponta
        // ficaria brilhando parada antes de começar e depois de acabar.
        float fadeIn = smoothstep(0.0, 0.04, progress);
        float fadeOut = 1.0 - smoothstep(0.94, 1.0, progress);
        float tipVisible = fadeIn * fadeOut * u.tipColor.a;

        rgb += u.tipColor.rgb * glow * tipVisible * u.tipIntensity;
        alpha = max(alpha, glow * tipVisible);
    }

    __nv_out = float4(rgb, alpha);
    return __nv_out;
}
