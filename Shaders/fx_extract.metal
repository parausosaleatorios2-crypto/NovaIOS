// ---------------------------------------------------------------------------
// Extrair
// origem : assets/effects/extract.xml
// id     : nova.effect.extract
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct extractParams {
    float blackPoint;
    float whitePoint;
    float blackSoftness;
    float whiteSoftness;
    int invert;
    int showMask;
};

// --- funcoes auxiliares do efeito
// Rec.709 — os mesmos pesos de `luma-key.xml`.
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_extract(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant extractParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 cor = inputImg.sample(__nv_smp, in.acScreenNorm);
    float luz = dot(cor.rgb, LUMA);

    // A rampa nunca é zero: suavidade 0 viraria um degrau de um tom só, e
    // degrau em máscara é serrilhado na borda.
    float rampaPreto = max(u.blackSoftness, 0.004);
    float rampaBranco = max(u.whiteSoftness, 0.004);

    // Sobe de 0 pra 1 cruzando o ponto de preto, desce de 1 pra 0 cruzando o
    // ponto de branco — o produto dos dois é 1 só DENTRO da faixa.
    float acimaDoPreto = smoothstep(u.blackPoint - rampaPreto, u.blackPoint + rampaPreto, luz);
    float abaixoDoBranco = 1.0 - smoothstep(u.whitePoint - rampaBranco, u.whitePoint + rampaBranco, luz);
    float alfa = clamp(acimaDoPreto * abaixoDoBranco, 0.0, 1.0);

    if (u.invert) alfa = 1.0 - alfa;

    if (u.showMask) {
        __nv_out = float4(float3(alfa), 1.0);
        return __nv_out;
    }

    __nv_out = float4(cor.rgb, cor.a * alfa);
    return __nv_out;
}
