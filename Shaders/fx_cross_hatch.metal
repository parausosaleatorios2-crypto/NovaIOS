// ---------------------------------------------------------------------------
// Hachura
// origem : assets/effects/cross-hatch.xml
// id     : nova.effect.cross-hatch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct cross_hatchParams {
    float4 paperColor;
    float4 inkColor;
    float density;
    float thickness;
    float strength;
};

// --- funcoes auxiliares do efeito
/** Luminância ITU-R BT.709. */
float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

/** A linha num eixo girado por `graus`: 1 na linha, 0 fora dela. */
float linhaEm(float2 p, float graus, float frequencia) {
    float a = radians(graus);
    float eixo = p.x * cos(a) - p.y * sin(a);
    // `sin(frequencia * eixo)` oscila entre -1 e 1; a linha é onde o valor passa de um limiar.
    float onda = sin(frequencia * eixo);
    return smoothstep(0.95 - 0.05 * u.thickness, 1.0, onda);
}

fragment float4 fx_cross_hatch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant cross_hatchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    float l = luma(original.rgb);

    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y);
    float freq = u.density;

    // Quatro camadas, cada uma entra num patamar de luma.
    // Luma > 0.75: só papel. 0.5-0.75: uma camada. 0.25-0.5: duas. 0.0-0.25: três. <0: quatro.
    float traco = 0.0;
    if (l < 0.75) traco = max(traco, linhaEm(p, 0.0, freq));
    if (l < 0.55) traco = max(traco, linhaEm(p, 45.0, freq));
    if (l < 0.35) traco = max(traco, linhaEm(p, 90.0, freq));
    if (l < 0.15) traco = max(traco, linhaEm(p, 135.0, freq));

    float3 desenho = mix(u.paperColor.rgb, u.inkColor.rgb, traco);

    float3 cor = mix(original.rgb, desenho, u.strength);

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
