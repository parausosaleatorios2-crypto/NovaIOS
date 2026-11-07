// ---------------------------------------------------------------------------
// Ampliar o fundo
// origem : assets/effects/am-magnify-background.xml
// id     : nova.effect.am-magnify-background
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_magnify_backgroundParams {
    float scale;
    int scaleMask;
    int sampling;
};

// --- funcoes auxiliares do efeito
static float4 preMultiplicada(float4 c) { return float4(c.rgb * c.a, c.a); }

// O filtro linear da GPU, à mão, sobre o fundo PRÉ-multiplicado (a textura do AM é assim): os 4 pixels em
// volta, presos à borda como o CLAMP_TO_EDGE.
static float4 fundoNoPonto(float2 uv) {
    int2 T = int2(int(comp.get_width()), int(comp.get_height()));
    float2 p = uv * float2(T) - 0.5;
    float2 i = floor(p);
    float2 f = p - i;
    int2 a = int2(i);
    int2 m = T - 1;
    float4 c00 = preMultiplicada(comp.read(uint2(clamp(a, int2(0), m)), uint(0)));
    float4 c10 = preMultiplicada(comp.read(uint2(clamp(a + int2(1, 0), int2(0), m)), uint(0)));
    float4 c01 = preMultiplicada(comp.read(uint2(clamp(a + int2(0, 1), int2(0), m)), uint(0)));
    float4 c11 = preMultiplicada(comp.read(uint2(clamp(a + int2(1, 1), int2(0), m)), uint(0)));
    return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

// A volta do `eng.acTela`: UV da tela → UV do buffer da camada (a homografia inversa).
static float2 daTela(float2 t) {
    float3 c = __nv_inverse(eng.acParaTela) * float3(t, 1.0);
    return c.xy / c.z;
}

// O alfa da camada num pixel da TELA, como o compositor o pinta: o buffer lido no meio do pixel; fora do
// buffer, nada. O pixel fora da tela vira o da borda (o CLAMP_TO_EDGE da textura do AM).
static float alfaDoPixel(int2 px, int2 T) {
    px = clamp(px, int2(0), T - 1);
    float2 uv = daTela((float2(px) + 0.5) / float2(T));
    if (any(lessThan(uv, float2(0.0))) || any(greaterThan(uv, float2(1.0)))) return 0.0;
    return inputImg.sample(__nv_smp, uv).a;
}

// A camada já na tela, filtrada de novo no ponto ampliado: a leitura do `inputImg` do AM com Camada ampliada.
static float alfaNoPonto(float2 uv) {
    int2 T = int2(int(comp.get_width()), int(comp.get_height()));
    float2 p = uv * float2(T) - 0.5;
    float2 i = floor(p);
    float2 f = p - i;
    int2 a = int2(i);
    return mix(
        mix(alfaDoPixel(a, T), alfaDoPixel(a + int2(1, 0), T), f.x),
        mix(alfaDoPixel(a + int2(0, 1), T), alfaDoPixel(a + int2(1, 1), T), f.x),
        f.y
    );
}

fragment float4 fx_am_magnify_background(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_magnify_backgroundParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // Tudo no espaço da tela do `eng.acTela` (o mesmo do fundo): o centro e o ponto andam juntos, em qualquer
    // orientação. O meio do conteúdo é o meio do buffer da camada, levado à tela pela `eng.acCamadaParaTela` — que
    // vale também quando a cadeia já roda na tela (`stage="screen"`: aí o `eng.acTela` é a identidade).
    float2 tela = __nv_acTela(in.acScreenNorm);
    float2 centro = eng.acCamadaNaTela(float2(0.5));

    // O ponto da camada aproximado do meio dela ÷ Escala, de volta na tela (a conta do AM, sem a ida e volta
    // pela coordenada da camada, que é afim).
    float2 ponto = centro + (tela - centro) / u.scale;
    if (u.sampling == 0) {
        // Mais próximo: o meio do pixel da composição.
        ponto *= eng.acTamanhoDaTela;
        ponto = floor(ponto) + 0.5;
        ponto /= eng.acTamanhoDaTela;
    }

    float4 fundo = fundoNoPonto(ponto);
    float alfa = u.scaleMask ? alfaNoPonto(ponto) : inputImg.sample(__nv_smp, in.acScreenNorm).a;

    float4 saida = fundo * alfa;   // pré-multiplicada, como o AM
    __nv_out = saida.a > 0.0 ? float4(saida.rgb / saida.a, saida.a) : float4(0.0);
    return __nv_out;
}
