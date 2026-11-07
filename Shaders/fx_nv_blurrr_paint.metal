// ---------------------------------------------------------------------------
// Pintura (Blurrr)
// origem : assets/effects/nv-blurrr-paint.xml
// id     : nova.effect.blurrr.paint
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_paintParams {
    float radius;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_nv_blurrr_paint(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_paintParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int R = int(clamp(u.radius, 1.0, 12.0));
    float2 texel = eng.acTexelSize;

    float3 melhorCor = inputImg.sample(__nv_smp, in.acScreenNorm).rgb;
    float menorVar = 1e9;

    // Quatro quadrantes relativos ao pixel atual, estilo Kuwahara simplificado.
    for (int q = 0; q < 4; q++) {
        int sx = (q == 0 || q == 2) ? -1 : 0;
        int sy = (q == 0 || q == 1) ? -1 : 0;

        float3 soma = float3(0.0);
        float3 soma2 = float3(0.0);
        float conta = 0.0;

        for (int y = 0; y <= 12; y++) {
            if (y > R) break;
            for (int x = 0; x <= 12; x++) {
                if (x > R) break;
                float2 off = float2(float(sx * x), float(sy * y)) * texel;
                float3 c = inputImg.sample(__nv_smp, in.acScreenNorm + off).rgb;
                soma += c;
                soma2 += c * c;
                conta += 1.0;
            }
        }
        float3 media = soma / conta;
        float3 varc  = (soma2 / conta) - media * media;
        float v = dot(varc, LUMA);
        if (v < menorVar) {
            menorVar = v;
            melhorCor = media;
        }
    }

    float a = inputImg.sample(__nv_smp, in.acScreenNorm).a;
    __nv_out = float4(melhorCor, a);
    return __nv_out;
}
