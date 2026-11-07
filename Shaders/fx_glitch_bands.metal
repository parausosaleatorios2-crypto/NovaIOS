// ---------------------------------------------------------------------------
// Glitch em faixas
// origem : assets/effects/glitch-bands.xml
// id     : nova.effect.glitch-bands
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct glitch_bandsParams {
    float bandCount;
    float jumpAmount;
    float chance;
    float rgbSplit;
    float rate;
    float seed;
};

// --- funcoes auxiliares do efeito
float hash2(float2 c) {
    c += float2(float(u.seed) * 13.7);
    return fract(sin(dot(c, float2(127.1, 311.7))) * 43758.5453);
}

fragment float4 fx_glitch_bands(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant glitch_bandsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // Quadro rítmico: congela o glitch por 1/u.rate segundos; muda só nas trocas.
    float quadro = floor(eng.acTime * u.rate);

    // Índice da faixa deste pixel.
    float n = max(float(int(u.bandCount + 0.5)), 1.0);
    float faixa = floor(in.acScreenNorm.y * n);

    // Essa faixa, nesse quadro, está glitchando?
    float sorteia = hash2(float2(faixa, quadro));
    float deslocamento = 0.0;
    if (sorteia < u.chance) {
        // Sim: pula; a direção e a força vêm de outro hash.
        float quanto = (hash2(float2(faixa, quadro + 7.0)) * 2.0 - 1.0) * u.jumpAmount;
        deslocamento = quanto;
    }

    float2 uv = in.acScreenNorm + float2(deslocamento, 0.0);

    // Separação RGB: cada canal lê em UV ligeiramente diferente.
    float sep = u.rgbSplit * 0.003 * abs(deslocamento) * 20.0;  // split maior onde o glitch é maior
    float r = inputImg.sample(__nv_smp, uv + float2(sep, 0.0)).r;
    float g = inputImg.sample(__nv_smp, uv).g;
    float b = inputImg.sample(__nv_smp, uv - float2(sep, 0.0)).b;
    float a = inputImg.sample(__nv_smp, uv).a;

    __nv_out = float4(r, g, b, a);
    return __nv_out;
}
