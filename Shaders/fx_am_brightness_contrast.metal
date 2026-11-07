// ---------------------------------------------------------------------------
// Brilho/contraste (AM)
// origem : assets/effects/am-brightness-contrast.xml
// id     : nova.effect.am-brightness-contrast
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_brightness_contrastParams {
    float brightness;
    float contrast;
};

// --- funcoes auxiliares do efeito
// k ÷ 255 com o arredondamento certo: o float EXATO que a textura de 8 bits devolve ao AM (ver `am-color-balance.xml`).
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

fragment float4 fx_am_brightness_contrast(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_brightness_contrastParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 camada = inputImg.sample(__nv_smp, in.acScreenNorm);
    float alfa = camada.a;
    // A camada do AM chega pré-multiplicada EM 8 BITS: arredondada aqui do mesmo jeito (o premul do Android). No
    // opaco a cor já é o float da textura, bit a bit.
    float3 p = camada.rgb;
    if (alfa < 1.0) {
        float3 k = floor(camada.rgb * alfa * 255.0 + 0.5);
        p = float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
    }

    // A conta do AM, na mesma forma (vetor × matriz, as matrizes dele) e na mesma precisão (`mediump`, o padrão do
    // AM para shader sem `precision`).
    float3x3 rgbParaYuv = float3x3(
         0.299,     0.587,    0.114,
        -0.14713,  -0.28886,  0.436,
         0.615,    -0.51499, -0.10001
    );
    float3x3 yuvParaRgb = float3x3(
        1.0,  0.0,      1.13983,
        1.0, -0.39465, -0.58060,
        1.0,  2.03211,  0.0
    );
    float3 rgb = p;
    float a = alfa;
    float brilho = u.brightness;
    float contraste = u.contrast;
    float3 yuv = rgb * rgbParaYuv;
    yuv.x = (yuv.x - 0.5 * a) * (contraste + 1.0) + 0.5 * a + brilho * a;
    rgb = yuv * yuvParaRgb;

    float3 saida = clamp(rgb, 0.0, 1.0);                           // o buffer de 8 bits do AM corta em 0 e 1
    __nv_out = alfa > 0.0 ? float4(min(saida / alfa, float3(1.0)), alfa) : float4(0.0);
    return __nv_out;
}
