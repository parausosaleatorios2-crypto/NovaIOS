// ---------------------------------------------------------------------------
// Equilíbrio de cor
// origem : assets/effects/am-color-balance.xml
// id     : nova.effect.am-color-balance
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_color_balanceParams {
    float crLow;
    float mgLow;
    float ybLow;
    float crMid;
    float mgMid;
    float ybMid;
    float crHigh;
    float mgHigh;
    float ybHigh;
    int fixLum;
};

// --- funcoes auxiliares do efeito
// k ÷ 255 com o arredondamento certo: o float EXATO que a textura de 8 bits devolve (o AM lê a camada assim). A
// divisão do shader vai pelo recíproco e erra o último bit em metade dos k (130 de 256 na AMD do PC), e o último
// bit decide a costura em Y = 0,555. Aqui: n·2^e ÷ 255 pelo mais perto, em 24 bits, montado direto nos bits do float.
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

fragment float4 fx_am_color_balance(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_color_balanceParams&  u    [[buffer(1)]],
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

    // Y'UV BT.601 com os coeficientes do AM (colunas do float3x3; `rgb * m` = uma linha por coluna). A ida para Y'UV é a
    // mesma expressão do AM, no mesmo float3: na costura em 0,555 o Y tem de sair do mesmo jeito, até o último bit.
    float3x3 rgbParaYuv = float3x3(
         0.299,    0.587,    0.114,
        -0.14713, -0.28886,  0.436,
         0.615,   -0.51499, -0.10001);
    float3x3 yuvParaRgb = float3x3(
        1.0,  0.0,      1.13983,
        1.0, -0.39465, -0.58060,
        1.0,  2.03211,  0.0);
    float3 yuvDeAntes = p * rgbParaYuv;
    float luz = yuvDeAntes.x;

    // O peso de cada faixa. Os dois pedaços dos meios-tons se encostam em 0,555 (ali os dois valem 1, como no AM).
    float sombras = 1.0 - smoothstep(0.222, 0.444, luz);
    float medios = smoothstep(0.222, 0.444, luz) * step(luz, 0.555)
                 + (1.0 - smoothstep(0.555, 0.777, luz)) * step(0.555, luz) * step(luz, 0.777);
    float realces = smoothstep(0.555, 0.777, luz);
    float3 desvio = float3(u.crLow, u.mgLow, u.ybLow) * sombras
                + float3(u.crMid, u.mgMid, u.ybMid) * medios
                + float3(u.crHigh, u.mgHigh, u.ybHigh) * realces;
    float3 ganho = (clamp(desvio, -100.0, 100.0) + float3(100.0)) / 100.0;

    float3 yuv = (p * ganho) * rgbParaYuv;
    if (u.fixLum) yuv.x = luz;
    float3 saida = clamp(yuv * yuvParaRgb, 0.0, 1.0);               // o buffer de 8 bits do AM corta em 0 e 1
    __nv_out = a > 0.0 ? float4(min(saida / a, float3(1.0)), a) : float4(0.0);
    return __nv_out;
}
