// ---------------------------------------------------------------------------
// Substituir Cor
// origem : assets/effects/am-replace-color.xml
// id     : nova.effect.am-replace-color
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_replace_colorParams {
    float4 oldcolor;
    float4 newcolor;
    float threshold;
    float feather;
    float alpha;
    int lockLuminance;
};

// --- funcoes auxiliares do efeito
// k ÷ 255 com o arredondamento certo: o float EXATO que a textura de 8 bits devolve (o AM lê a camada assim). A
// divisão do shader vai pelo recíproco e erra o último bit em metade dos k — e a distância à cor procurada decide
// "troca ou não" num degrau de 0,001. n·2^e ÷ 255 pelo mais perto, em 24 bits, montado direto nos bits do float (o
// mesmo do Equilíbrio de cor e do Deslocar matiz).
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

fragment float4 fx_am_replace_color(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_replace_colorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // As matrizes do AM (BT.601), escritas como ele escreve: vetor × matriz.
    float3x3 rgb2yuv = float3x3(
         0.299,     0.587,    0.114,
        -0.14713,  -0.28886,  0.436,
         0.615,    -0.51499, -0.10001
    );
    float3x3 yuv2rgb = float3x3(
        1.0,  0.0,      1.13983,
        1.0, -0.39465, -0.58060,
        1.0,  2.03211,  0.0
    );

    float4 camada = inputImg.sample(__nv_smp, in.acScreenNorm);
    float a = camada.a;
    // Transparente: no AM, 0 ÷ 0 e a saída vazia.
    if (a <= 0.0) { __nv_out = float4(0.0); return __nv_out; }
    // A camada do AM chega pré-multiplicada EM 8 BITS: arredondada aqui do mesmo jeito (o premul do Android, pelo
    // mais perto). No opaco a cor já é o float da textura, bit a bit.
    float3 pre = camada.rgb;
    if (a < 1.0) {
        float3 k = floor(camada.rgb * a * 255.0 + 0.5);
        pre = float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
    }
    float4 texColor = float4(pre, a);

    // Daqui até a mistura, a conta do AM na mesma ordem.
    float3 srcColor = texColor.rgb / texColor.a;
    float3 oldColorYUV = u.oldcolor.rgb * rgb2yuv;
    float3 srcColorYUV = srcColor * rgb2yuv;
    float3 diffYUV = abs(oldColorYUV - srcColorYUV);
    diffYUV.yz *= 4.0;
    diffYUV.x *= 0.5;
    float diff = length(diffYUV);
    float b = max(u.threshold - max(u.feather, 0.0005), 0.);
    float a2 = min(u.threshold + max(u.feather, 0.0005), 4.);
    float p = smoothstep(a2, min(b, a2 - 0.0005), diff);
    float3 newColorAdjRGB = u.newcolor.rgb / u.newcolor.a;
    if (u.lockLuminance) {
        float3 newColorAdjYUV = newColorAdjRGB * rgb2yuv;
        newColorAdjYUV.x = srcColorYUV.x;
        newColorAdjRGB = newColorAdjYUV * yuv2rgb;
    } else {
        newColorAdjRGB = srcColor - (u.oldcolor.rgb / u.oldcolor.a) + newColorAdjRGB;
    }
    float4 res = mix(texColor, float4(mix(srcColor, newColorAdjRGB, p), 1.0) * texColor.a, u.newcolor.a * u.alpha);

    float3 saida = clamp(res.rgb, 0.0, 1.0);                       // o buffer de 8 bits do AM corta em 0 e 1
    __nv_out = float4(min(saida / a, float3(1.0)), a);
    return __nv_out;
}
