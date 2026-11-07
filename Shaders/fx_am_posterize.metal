// ---------------------------------------------------------------------------
// Posterizar (AM)
// origem : assets/effects/am-posterize.xml
// id     : nova.effect.am-posterize
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_posterizeParams {
    float stepCount;
    float offset;
};

// --- funcoes auxiliares do efeito
// k ÷ 255 com o arredondamento certo: o float EXATO que a textura de 8 bits devolve (o AM lê a camada assim). A
// divisão do shader vai pelo recíproco e erra o último bit em metade dos k, e o último bit decide o degrau quando
// cor × Passos + d cai em cima de um inteiro. Aqui: n·2^e ÷ 255 pelo mais perto, em 24 bits, montado nos bits do float.
static float oitoBits(float k) {
    uint n = uint(k);
    if (n == 0u) return 0.0;
    if (n == 255u) return 1.0;
    int j = 0;                                                    // o bit mais alto de n
    for (int i = 1; i < 8; i++) if (n >= (1u << uint(i))) j = i;
    int e = 31 - j;
    uint q = ((n << uint(e)) + 127u) / 255u;                      // entre 2^23 e 2^24
    return as_type<float>((uint(150 - e) << 23) + (q - 0x800000u));
}

fragment float4 fx_am_posterize(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_posterizeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 camada = inputImg.sample(__nv_smp, in.acScreenNorm);
    float a = camada.a;
    // A camada do AM chega pré-multiplicada EM 8 BITS: arredondada aqui do mesmo jeito (o premul do Android). No
    // opaco a cor já é o float da textura, bit a bit.
    float3 p = camada.rgb;
    if (a < 1.0) {
        float3 k = floor(camada.rgb * a * 255.0 + 0.5);
        p = float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
    }
    // A conta do AM, na ordem dele (o mesmo float em cada passo).
    float actualOffset = u.offset + 0.05;
    float3 c = p * u.stepCount;
    c += actualOffset;
    c = floor(c);
    c -= actualOffset;
    c /= u.stepCount;
    float3 saida = clamp(c, 0.0, 1.0);                              // o buffer de 8 bits do AM corta em 0 e 1
    __nv_out = a > 0.0 ? float4(min(saida / a, float3(1.0)), a) : float4(0.0);
    return __nv_out;
}
