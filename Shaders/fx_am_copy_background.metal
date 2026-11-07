// ---------------------------------------------------------------------------
// Copiar fundo
// origem : assets/effects/am-copy-background.xml
// id     : nova.effect.am-copy-background
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_copy_backgroundParams {
    float fill;
};

// --- funcoes auxiliares do efeito
// k ÷ 255 com o arredondamento certo: o float EXATO que a textura de 8 bits devolve ao AM (ver `am-color-balance.xml`).
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

// A cor reta do Nova pré-multiplicada EM 8 BITS, pelo mais perto (o premul do Android): o que a textura do AM guarda.
// No opaco a cor já é o float da textura, bit a bit.
float4 doAm(float4 c) {
    if (c.a >= 1.0) return c;
    float3 k = floor(c.rgb * c.a * 255.0 + 0.5);
    return float4(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b), c.a);
}

fragment float4 fx_am_copy_background(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_copy_backgroundParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    texture2d<float> copia [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 1) {
        // A pré-multiplicada do AM, já em 8 bits, de volta para a cor reta do Nova.
        float4 q = copia.sample(__nv_smp, in.acScreenNorm);
        __nv_out = q.a > 0.0 ? float4(clamp(q.rgb / q.a, 0.0, 1.0), q.a) : float4(0.0);
        return __nv_out;
    }
    // O fundo no pixel da tela (na tela, o `eng.acTela` é a identidade).
    int2 T = int2(int(comp.get_width()), int(comp.get_height()));
    int2 px = clamp(int2(floor(__nv_acTela(in.acScreenNorm) * float2(T))), int2(0), T - 1);
    float4 fundo = doAm(comp.read(uint2(px), uint(0)));

    // O shader do AM: `mix(comp × texColor.a, texColor, u.fill)`, na pré-multiplicada.
    float4 texColor = doAm(inputImg.sample(__nv_smp, in.acScreenNorm));
    // O corte em 0..1 é o do alvo de 8 bits do AM; escrito aqui para o projeto de 32 bits sair igual.
    __nv_out = clamp(mix(fundo * texColor.a, texColor, u.fill), 0.0, 1.0);
    return __nv_out;
}
