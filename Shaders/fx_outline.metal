// ---------------------------------------------------------------------------
// Contorno
// origem : assets/effects/outline.xml
// id     : nova.effect.outline
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct outlineParams {
    float thickness;
    float4 color;
    int mode;
    int hideSource;
};

// --- funcoes auxiliares do efeito
const int RINGS = 12;
const float TAU = 6.28318530718;

fragment float4 fx_outline(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant outlineParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 base = inputImg.sample(__nv_smp, in.acScreenNorm);

    if (u.mode == 1) {
        // Sobel: detecta variação de brilho, revelando bordas DENTRO da imagem.
        // (em pixels da composição: ver o `radius` abaixo)
        float2 o = eng.acTexelSize * (u.thickness * eng.acEscalaDePixel) * 0.25;
        float tl = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2(-o.x,  o.y)).rgb, float3(0.333));
        float tm = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2( 0.0,  o.y)).rgb, float3(0.333));
        float tr = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2( o.x,  o.y)).rgb, float3(0.333));
        float ml = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2(-o.x,  0.0)).rgb, float3(0.333));
        float mr = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2( o.x,  0.0)).rgb, float3(0.333));
        float bl = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2(-o.x, -o.y)).rgb, float3(0.333));
        float bm = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2( 0.0, -o.y)).rgb, float3(0.333));
        float br = dot(inputImg.sample(__nv_smp, in.acScreenNorm + float2( o.x, -o.y)).rgb, float3(0.333));

        float gx = -tl - 2.0 * ml - bl + tr + 2.0 * mr + br;
        float gy =  tl + 2.0 * tm + tr - bl - 2.0 * bm - br;
        float edge = clamp(length(float2(gx, gy)), 0.0, 1.0);

        if (u.hideSource) {
            __nv_out = float4(u.color.rgb, edge * u.color.a);
        } else {
            __nv_out = float4(mix(base.rgb, u.color.rgb, edge * u.color.a), max(base.a, edge * u.color.a));
        }
        return __nv_out;
    }

    // Contorno externo: procura em volta, num anel, se existe pixel opaco. Se
    // existir e ESTE pixel for transparente, aqui é borda.
    //
    // Amostrar em anel (e não num quadrado) é o que faz o contorno ficar
    // arredondado e uniforme; um quadrado deixaria "orelhas" nos cantos.
    float maxAlpha = 0.0;
    // Em pixels da COMPOSIÇÃO: `eng.acEscalaDePixel` converte para o buffer, e a prévia
    // reduzida (o Auto da tela, o play) fica do tamanho da exportação (0.516.0).
    float2 radius = eng.acTexelSize * (u.thickness * eng.acEscalaDePixel);
    for (int i = 0; i < RINGS; i++) {
        float angle = TAU * float(i) / float(RINGS);
        float2 offset = float2(cos(angle), sin(angle)) * radius;
        maxAlpha = max(maxAlpha, inputImg.sample(__nv_smp, in.acScreenNorm + offset).a);
    }

    float ring = clamp(maxAlpha - base.a, 0.0, 1.0) * u.color.a;

    if (u.hideSource) {
        __nv_out = float4(u.color.rgb, ring);
        return __nv_out;
    }

    float outAlpha = base.a + ring * (1.0 - base.a);
    float3 outRgb = outAlpha > 0.0
        ? (base.rgb * base.a + u.color.rgb * ring * (1.0 - base.a)) / outAlpha
        : float3(0.0);

    __nv_out = float4(outRgb, outAlpha);
    return __nv_out;
}
