// ---------------------------------------------------------------------------
// Forma
// origem : assets/effects/shape-generator.xml
// id     : nova.effect.shape
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct shape_generatorParams {
    int kind;
    float2 center;
    float sizeX;
    float sizeY;
    float cornerRadius;
    float softness;
    float4 fillColor;
    float4 outlineColor;
    float outlineWidth;
    int invert;
};

// --- funcoes auxiliares do efeito
/** SDF do retângulo arredondado (Inigo Quilez): negativo dentro, positivo fora. */
float sdfRetangulo(float2 p, float2 metade, float raio) {
    float2 q = abs(p) - metade + float2(raio);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - raio;
}

/** SDF da elipse por fórmula aproximada (precisa o bastante para pintar com AA). */
float sdfElipse(float2 p, float2 raio) {
    float2 r = max(raio, float2(1e-5));
    float d = length(p / r);
    // Projeta para pseudo-distância em unidades da menor dimensão: isso dá uma
    // gradiente aproveitável para o smoothstep da borda.
    return (d - 1.0) * min(r.x, r.y);
}

fragment float4 fx_shape_generator(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant shape_generatorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 p = (in.acScreenNorm - u.center) * float2(eng.acAspect, 1.0);
    float2 metade = float2(u.sizeX, u.sizeY) * 0.5;

    float d;
    if (u.kind == 1) {
        // elipse: raios independentes em x e y
        d = sdfElipse(p, metade);
    } else if (u.kind == 2) {
        // retângulo: canto arredondado opcional
        d = sdfRetangulo(p, metade, min(u.cornerRadius, min(metade.x, metade.y)));
    } else {
        // círculo: distância ao centro menos o raio
        d = length(p) - min(metade.x, metade.y);
    }

    float suave = max(u.softness, 1e-4);

    // Dentro da forma = 1, fora = 0, transição no raio `u.softness`.
    float dentro = 1.0 - smoothstep(-suave, suave, d);

    // Anel da borda: um smoothstep sobre a distância assinada entre -w e 0.
    float anel = smoothstep(u.outlineWidth + suave, u.outlineWidth - suave, d)
               - smoothstep(0.0 + suave, 0.0 - suave, d);
    anel = clamp(anel, 0.0, 1.0);

    float dentroPintado = dentro;
    if (u.invert) dentroPintado = 1.0 - dentro;

    // A forma pinta sobre a imagem; a borda por cima da forma.
    float4 comPreench = mix(original, float4(u.fillColor.rgb, u.fillColor.a), dentroPintado * u.fillColor.a);
    float4 final_ = mix(comPreench, float4(u.outlineColor.rgb, u.outlineColor.a), anel * u.outlineColor.a);

    __nv_out = final_;
    return __nv_out;
}
