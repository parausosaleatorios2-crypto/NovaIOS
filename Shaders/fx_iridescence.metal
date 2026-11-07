// ---------------------------------------------------------------------------
// Iridescência
// origem : assets/effects/iridescence.xml
// id     : nova.effect.iridescence
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct iridescenceParams {
    float strength;
    float bands;
    float phaseOffset;
    float angleDeg;
    float angleMix;
    float speed;
    float saturation;
};

// --- funcoes auxiliares do efeito
/**
 * O arco-íris sem tabela: três cossenos defasados de 120° dão R, G e B periódicos
 * em `fase`. É o mesmo truque do `hsv2rgb` do IQ — um HSV sem a conta das faixas,
 * com a vantagem de ser suave de verdade (nada de discontinuidade no limite dos 6
 * setores do HSV).
 */
float3 arcoIris(float fase) {
    const float3 defasagem = float3(0.0, 2.094395, 4.188790); // 0°, 120°, 240°
    return 0.5 + 0.5 * cos(6.2831853 * fase + defasagem);
}

/** A luminância ITU-R BT.709 — mesmo peso que o resto do app usa. */
float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

fragment float4 fx_iridescence(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant iridescenceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    // A fase tem duas entradas: a LUMA da imagem (por isso o arco-íris segue o relevo
    // do que está pintado) e a projeção do pixel num eixo (as faixas atravessando a
    // camada). O slider de ângulo mistura entre os dois.
    float lumaDaImagem = luma(original.rgb);
    float2 direcao = float2(cos(radians(u.angleDeg)), sin(radians(u.angleDeg)));
    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y);
    float projecao = dot(p, direcao);

    float fase = mix(lumaDaImagem, projecao, u.angleMix) * u.bands
               + u.phaseOffset
               + eng.acTime * u.speed;

    float3 iris = arcoIris(fase);

    // A saturação muda o alcance do arco-íris em volta do cinza médio: 1 mantém o
    // clássico, 0 vira cinza (iridescência "só brilho"), 2 estoura as cores.
    float3 cinza = float3(luma(iris));
    iris = mix(cinza, iris, u.saturation);

    // A MISTURA é por LUMINOSIDADE: o arco-íris pinta multiplicativo, e o pixel mantém
    // a sua luminância original. É assim que óleo numa superfície escura não acende a
    // tela toda — só muda a cor.
    float lumaDoIris = max(luma(iris), 1e-4);
    float3 pintado = iris * (lumaDaImagem / lumaDoIris);

    float3 cor = mix(original.rgb, pintado, u.strength);

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
