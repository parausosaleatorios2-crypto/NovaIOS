// ---------------------------------------------------------------------------
// Sharpen
// origem : assets/effects/am-sharpen.xml
// id     : nova.effect.am-sharpen
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_sharpenParams {
    float strength;
    float radius;
};

// --- funcoes auxiliares do efeito
// O fundo (a cena montada atrás da camada) no pixel da tela, pré-multiplicado (o do Anel).
static float3 fundoNoPixel() {
    int2 T = int2(int(comp.get_width()), int(comp.get_height()));
    int2 px = clamp(int2(floor(__nv_acTela(in.acScreenNorm) * float2(T))), int2(0), T - 1);
    float4 f = comp.read(uint2(px), uint(0));
    return f.rgb * f.a;
}

// A saída pré-multiplicada do AM (`q`, já em 8 bits) em cor reta. O comum (cor ≤ alfa) é só dividir — no opaco, a
// própria cor. Onde a cor passa do alfa (a luz que a composição do AM SOMA ao que está atrás, `p + fundo·(1 − op·alfa)`),
// o pixel leva junto o fundo dele: com o menor alfa `a` em que a cor reta `s = fundo + (q − fundo·alfa)/a` cabe entre 0
// e 1, a composição Normal do Nova, `s·a·op + fundo·(1 − a·op)`, dá o mesmo do AM com QUALQUER opacidade da camada. Não
// cabe só quando a soma passa de 1: com a opacidade cheia ela vira 1 lá e aqui; com menos, aqui sai um pouco mais escuro.
static float4 paraReta(float4 q) {
    if (all(lessThanEqual(q.rgb, float3(q.a)))) return q.a > 0.0 ? float4(q.rgb / q.a, q.a) : float4(0.0);
    float3 d = fundoNoPixel();
    float3 sobra = q.rgb - d * q.a;
    float3 folga = 1.0 - d;
    float a = q.a;
    for (int i = 0; i < 3; i++) {
        // Canal com o fundo cheio (1): lá e aqui a soma fica em 1 com qualquer alfa, então ele não pede nada.
        if (sobra[i] > 0.0 && folga[i] > 0.0) a = max(a, sobra[i] / folga[i]);
    }
    a = min(a, 1.0);
    return a > 0.0 ? float4(clamp(d + sobra / a, 0.0, 1.0), a) : float4(0.0);
}

// O float que a textura de 8 bits devolve para o nível k (k/255 arredondado como o hardware), montado pelos bits: gravado
// num alvo de 8 bits volta a ser k em qualquer GPU (o `oitoBits` do Equilíbrio de cor).
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

fragment float4 fx_am_sharpen(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_sharpenParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    texture2d<float> pre [[texture(2)]],
    texture2d<float> nitido [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        // A camada do AM chega pré-multiplicada EM 8 BITS, pelo mais perto (o premul do Android). O Sharpen multiplica
        // a diferença de um nível por até 81 (1 + 4 × 20): o arredondamento é o da conta, e não o da GPU que grava (a
        // AMD do PC grava com viés). No opaco a cor já é o float da textura, bit a bit.
        float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
        float3 p = c.rgb;
        if (c.a < 1.0) {
            float3 k = floor(c.rgb * c.a * 255.0 + 0.5);
            p = float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
        }
        __nv_out = float4(p, c.a);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        // A conta do AM, na mesma ordem. "Cima" é o +t do AM: na tela a entrada chega de pé (t = 0 embaixo, como
        // lá); deitada, o vizinho de cima é o −t. Assim o norte e o sul entram na soma na mesma ordem que no AM.
        float cima = eng.acEntradaDePe == 1 ? 1.0 : -1.0;
        float2 fragSize = float2(1.) / float2(int2(int(pre.get_width()), int(pre.get_height()))) * u.radius;
        float4 w  = pre.sample(__nv_smp, float2(in.acScreenNorm.x - fragSize.x, in.acScreenNorm.y));
        float4 e  = pre.sample(__nv_smp, float2(in.acScreenNorm.x + fragSize.x, in.acScreenNorm.y));
        float4 n  = pre.sample(__nv_smp, float2(in.acScreenNorm.x, in.acScreenNorm.y + cima * fragSize.y));
        float4 s  = pre.sample(__nv_smp, float2(in.acScreenNorm.x, in.acScreenNorm.y - cima * fragSize.y));
        float4 texColor = pre.sample(__nv_smp, in.acScreenNorm);

        float centerWeight = 1. + u.strength*4.;
        float sideWeight = -u.strength;

        // O corte em 0..1 é o do alvo de 8 bits do AM; escrito aqui para o projeto de 32 bits sair igual.
        __nv_out = clamp(n*sideWeight + s*sideWeight + e*sideWeight + w*sideWeight + texColor*centerWeight, 0.0, 1.0);
        return __nv_out;
    }

    // Intensidade 0: o AM devolve a própria camada (centro × 1, vizinhos × 0).
    if (u.strength == 0.0) {
        __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }
    __nv_out = paraReta(nitido.sample(__nv_smp, in.acScreenNorm));
    return __nv_out;
}
