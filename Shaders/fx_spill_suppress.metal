// ---------------------------------------------------------------------------
// Limpar derrame
// origem : assets/effects/spill-suppress.xml
// id     : nova.effect.spillsuppress
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct spill_suppressParams {
    float4 spillColor;
    float amount;
    float tolerance;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

/** A cor sem o brilho: é neste espaço que "direção da cor" faz sentido. */
float3 croma(float3 c) {
    return c - dot(c, LUMA);
}

fragment float4 fx_spill_suppress(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant spill_suppressParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 cor = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (cor.a <= 0.0) {
        __nv_out = cor;
        return __nv_out;
    }

    float3 alvo = croma(u.spillColor.rgb);
    float forcaAlvo = length(alvo);
    // Cor-chave cinza não tem direção de croma — nada a suprimir, e normalizar
    // um vetor de comprimento zero daria NaN espalhado pela tela.
    if (forcaAlvo < 1e-4 || u.amount <= 0.0) {
        __nv_out = cor;
        return __nv_out;
    }

    float3 direcao = alvo / forcaAlvo;
    float quanto = dot(croma(cor.rgb), direcao);

    // A tolerância é o quanto de cor legítima naquela direção fica de pé. Sem
    // ela, um agasalho verde perderia o verde junto com o derrame.
    float excesso = max(quanto - u.tolerance * forcaAlvo, 0.0) * u.amount;

    float3 limpa = cor.rgb - direcao * excesso;

    // Devolve o brilho perdido igualmente nos três canais: mexe no matiz, não
    // na exposição (sempre — tirar o verde não pode escurecer a pele).
    float antes = dot(cor.rgb, LUMA);
    float depois = dot(limpa, LUMA);
    limpa += (antes - depois);

    __nv_out = float4(clamp(limpa, 0.0, 1.0), cor.a);
    return __nv_out;
}
