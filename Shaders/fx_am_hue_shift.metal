// ---------------------------------------------------------------------------
// Deslocar matiz
// origem : assets/effects/am-hue-shift.xml
// id     : nova.effect.am-hue-shift
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_hue_shiftParams {
    float hue;
};

// --- funcoes auxiliares do efeito
// k ÷ 255 com o arredondamento certo: o float EXATO que a textura de 8 bits devolve (o AM lê a camada assim). A
// divisão do shader vai pelo recíproco e erra o último bit em metade dos k — e o giro leva esse bit até o meio nível
// da saída (300 pixels opacos com 1 nível de diferença, medidos). n·2^e ÷ 255 pelo mais perto, em 24 bits, montado
// direto nos bits do float (o mesmo do Equilíbrio de cor).
float oitoBits(float k) {
    uint n = uint(k);
    if (n == 0u) return 0.0;
    if (n == 255u) return 1.0;
    int j = 0;                                                    // o bit mais alto de n
    for (int i = 1; i < 8; i++) if (n >= (1u << uint(i))) j = i;
    int e = 31 - j;
    uint q = ((n << uint(e)) + 127u) / 255u;                      // entre 2^23 e 2^24
    return as_type<float>((uint(150 - e) << 23) + (q - 0x800000u));
}

fragment float4 fx_am_hue_shift(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_hue_shiftParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 camada = inputImg.sample(__nv_smp, in.acScreenNorm);
    float a = camada.a;
    // O AM trabalha pré-multiplicado, e a camada dele chega pré-multiplicada EM 8 BITS: arredondada aqui do mesmo
    // jeito (o premul do Android, pelo mais perto). No opaco a cor já é o float da textura, bit a bit.
    //
    // As PRECISÕES são as do AM, uma por uma: o shader dele não pede `precision`, e o AM então compila com
    // `precision float` (`ssl/BI`, lido do bytecode). A cor lida, o ângulo, o radiano e o seno/cosseno
    // ficam no padrão dele, mediump; a cor que entra na conta, as matrizes e o YUV, highp, como ele escreve. No PC
    // isso não muda nada (a GPU de mesa ignora mediump); numa GPU de celular que faz o em 16 bits, o AM
    // arredonda o ângulo e o seno/cosseno nesses 16 bits — e aqui também, nos mesmos lugares.
    float3 cor = camada.rgb;
    if (a < 1.0) {
        float3 k = floor(camada.rgb * a * 255.0 + 0.5);
        cor = float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
    }
    float3 pre = cor;

    // RGB → YUV, nos números do BT.601 (os mesmos do AM).
    float y = dot(pre, float3(0.299, 0.587, 0.114));
    float u = dot(pre, float3(-0.14713, -0.28886, 0.436));
    float v = dot(pre, float3(0.615, -0.51499, -0.10001));

    // O croma gira; o brilho fica. O radiano pelo número do AM.
    float graus = u.hue;
    float giro = graus * 0.0174533;
    float co = cos(giro);
    float se = sin(giro);
    float u2 = u * co + v * se;
    float v2 = v * co - u * se;

    float3 rgb = float3(y + 1.13983 * v2,
                    y - 0.39465 * u2 - 0.58060 * v2,
                    y + 2.03211 * u2);
    float3 saida = clamp(rgb, 0.0, 1.0);                           // o buffer de 8 bits do AM corta em 0 e 1
    __nv_out = a > 0.0 ? float4(min(saida / a, float3(1.0)), a) : float4(0.0);
    return __nv_out;
}
