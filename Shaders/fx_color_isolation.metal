// ---------------------------------------------------------------------------
// Isolar uma cor
// origem : assets/effects/color-isolation.xml
// id     : nova.effect.color-isolation
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct color_isolationParams {
    float4 targetColor;
    float tolerance;
    float softness;
    float minSat;
    float strength;
};

// --- funcoes auxiliares do efeito
/** RGB → H em [0, 360). Retorna 0 para cinza (não aparece). */
float matiz(float3 c) {
    float mx = max(c.r, max(c.g, c.b));
    float mn = min(c.r, min(c.g, c.b));
    float delta = mx - mn;
    if (delta < 1e-5) return 0.0;
    float h;
    if (mx == c.r)      h = __nv_mod((c.g - c.b) / delta, 6.0);
    else if (mx == c.g) h = (c.b - c.r) / delta + 2.0;
    else                h = (c.r - c.g) / delta + 4.0;
    return h * 60.0;
}

/** RGB → S (do HSV): 0 = cinza, 1 = saturado. */
float saturacao(float3 c) {
    float mx = max(c.r, max(c.g, c.b));
    float mn = min(c.r, min(c.g, c.b));
    return mx < 1e-5 ? 0.0 : (mx - mn) / mx;
}

/** Luminância ITU-R BT.709 — o cinza perceptual. */
float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

/** Distância angular na roda de matiz: 170°→190° é 20°, não 340°. */
float distanciaDeMatiz(float a, float b) {
    float d = abs(a - b);
    return min(d, 360.0 - d);
}

fragment float4 fx_color_isolation(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant color_isolationParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float hDoPixel = matiz(original.rgb);
    float hAlvo = matiz(u.targetColor.rgb);
    float d = distanciaDeMatiz(hDoPixel, hAlvo);

    // Pixel dentro da tolerância = 1 (mantém); fora = 0 (dessatura); zona = smoothstep.
    float dentro = 1.0 - smoothstep(u.tolerance, u.tolerance + max(u.softness, 1e-4), d);

    // Pixel pouco saturado (cinza quase) não se "isola" — vira cinza direto.
    float temCor = smoothstep(u.minSat, u.minSat + 0.1, saturacao(original.rgb));
    dentro *= temCor;

    float3 cinza = float3(luma(original.rgb));
    float3 pintado = mix(cinza, original.rgb, dentro);

    float3 cor = mix(original.rgb, pintado, u.strength);

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
