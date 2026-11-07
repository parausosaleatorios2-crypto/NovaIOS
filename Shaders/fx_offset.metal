// ---------------------------------------------------------------------------
// Deslocar (Offset)
// origem : assets/effects/offset.xml
// id     : nova.effect.offset
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct offsetParams {
    float2 shiftCenterTo;
    float blendWithOriginal;
};

// --- funcoes auxiliares do efeito
// O filtro de textura da GPU (o do AE no render, medido): os pesos do bilinear andam em 1/256 de pixel.
float2 pesoDaGpu(float2 f) { return floor(f * 256.0 + 0.5) / 256.0; }

// O texel em níveis de 8 bits, inteiros.
float4 nivel(float4 c) { return floor(c * 255.0 + 0.5); }

fragment float4 fx_offset(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant offsetParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 tam = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 aqui = min(int2(floor(in.acScreenNorm * float2(tam))), tam - int2(1));
    float4 original = inputImg.read(uint2(aqui), uint(0));

    // A camada do AE dentro do buffer: L px inteiros, centrada (a foto encaixada; o resto, a composição).
    int2 L = clamp(int2(floor(eng.acCamada * float2(tam) + 0.5)), int2(1), tam);
    int2 inicio = (tam - L) / 2;
    int2 q = aqui - inicio;
    if (any(lessThan(q, int2(0))) || any(greaterThanEqual(q, L))) {
        __nv_out = original;        // fora da camada: no AE não há camada aqui
        return __nv_out;
    }
    float2 Lf = float2(L);

    // O centro da imagem vai para `u.shiftCenterTo`: o pixel q lê a camada em q − deslocamento, com a volta.
    float2 deslocamento = (u.shiftCenterTo - 0.5) * float2(tam);
    float2 X = float2(q) - __nv_mod(deslocamento, Lf);
    float2 base = floor(X);
    float2 g = pesoDaGpu(X - base);
    int2 i0 = min(int2(__nv_mod(base, Lf)), L - int2(1));
    int2 i1 = min(int2(__nv_mod(base + 1.0, Lf)), L - int2(1));

    // Bilinear da cor RETA, como o AE (a cor dos pixels transparentes entra também). Em NÍVEIS (0..255)
    // inteiros: com os pesos em 1/256, a conta sai exata em float — e o empate de meio nível (o deslocamento
    // de meio pixel) arredonda para cima, como no AE, em vez de cair para qualquer lado.
    float4 a = nivel(inputImg.read(uint2(inicio + int2(i0.x, i0.y)), uint(0)));
    float4 b = nivel(inputImg.read(uint2(inicio + int2(i1.x, i0.y)), uint(0)));
    float4 c = nivel(inputImg.read(uint2(inicio + int2(i0.x, i1.y)), uint(0)));
    float4 d = nivel(inputImg.read(uint2(inicio + int2(i1.x, i1.y)), uint(0)));
    float4 m = mix(mix(a, b, g.x), mix(c, d, g.x), g.y);

    // Blend With Original em cor pré-multiplicada, antes de arredondar.
    float r = u.blendWithOriginal;
    if (r > 0.0) {
        float4 o = nivel(original);
        float alfa = mix(m.a, o.a, r);
        float3 cor = mix(m.rgb * m.a, o.rgb * o.a, r);
        m = float4(alfa > 0.0 ? cor / alfa : float3(0.0), alfa);
    }

    // Uma vez só, no fim, em 8 bits (o AE em 8 bpc).
    __nv_out = floor(clamp(m, 0.0, 255.0) + 0.5) / 255.0;
    return __nv_out;
}
