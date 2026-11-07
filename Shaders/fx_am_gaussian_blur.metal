// ---------------------------------------------------------------------------
// Desfoque gaussiano (AM)
// origem : assets/effects/am-gaussian-blur.xml
// id     : nova.effect.am-gaussian-blur
// passes : 5
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_gaussian_blurParams {
    float strength;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

// A gaussiana de meio-lado `lado` (em pixels de `img`) no eixo `passo`, na mesma ordem de contas do AM: os pesos
// tirados um do outro por multiplicação e duas amostras juntas numa leitura (a posição entre elas pelo peso).
static float4 desfocar(sampler2D img, float2 passo, float2 st, float lado) {
    if (u.strength <= 0.0) return float4(0.0);
    float sigma = lado / 2.14596602;
    float3 g;
    g.x = 1.0 / (sqrt(2.0 * PI) * sigma);
    g.y = exp(-0.5 / (sigma * sigma));
    g.z = g.y * g.y;
    float4 soma = float4(0.0);
    float total = 0.0;
    soma += img.sample(__nv_smp, st) * g.x;
    total += g.x;
    for (float i = 1.0; i <= lado; i += 2.0) {
        float d0 = i;
        float d1 = i + 1.0;
        g.xy *= g.yz;
        total += 2.0 * g.x;
        float p0 = g.x;
        g.xy *= g.yz;
        total += 2.0 * g.x;
        float p1 = g.x;
        float par = p0 + p1;
        float d = (d0 * p0 + d1 * p1) / par;
        float2 stL = st - d * passo;
        float2 stR = st + d * passo;
        soma += img.sample(__nv_smp, stL) * par;
        soma += img.sample(__nv_smp, stR) * par;
    }
    return soma / total;
}

// O meio-lado: Intensidade ÷ 2 × 1,14 ÷ 4 ÷ 3 da diagonal da imagem CHEIA (o `eng.acPreviewSize` do AM).
static float ladoDoDesfoque() {
    return u.strength / 2.0 * 1.14 / 4.0 / 3.0 * length(float2(int2(int(pre.get_width()), int(pre.get_height()))));
}

fragment float4 fx_am_gaussian_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_gaussian_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pre [[texture(1)]],
    texture2d<float> downImg [[texture(2)]],
    texture2d<float> hblur [[texture(3)]],
    texture2d<float> vblur [[texture(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
        __nv_out = float4(c.rgb * c.a, c.a);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        __nv_out = pre.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }
    if (eng.acPass == 2) {
        float2 passo = float2(1.0 / float2(int2(int(downImg.get_width()), int(downImg.get_height()))).x, 0.0);
        __nv_out = desfocar(downImg, passo, in.acScreenNorm, ladoDoDesfoque());
        return __nv_out;
    }
    if (eng.acPass == 3) {
        // Na tela a entrada chega de pé (t = 0 embaixo, como no AM): o passo aponta para CIMA e a soma do par fica na
        // mesma ordem da dele (o de baixo primeiro). Invertida, a soma em float mudaria o último bit.
        float cima = eng.acEntradaDePe == 1 ? 1.0 : -1.0;
        float2 passo = float2(0.0, cima / float2(int2(int(hblur.get_width()), int(hblur.get_height()))).y);
        float4 r = desfocar(hblur, passo, in.acScreenNorm, ladoDoDesfoque());
        __nv_out = u.strength <= 0.0 ? pre.sample(__nv_smp, in.acScreenNorm) : r;
        return __nv_out;
    }

    // Até 0,0001 o AM tira o efeito da lista (o script dele não liga o grupo de shader): a camada como está.
    if (!(u.strength > 0.0001)) {
        __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }
    float4 c = vblur.sample(__nv_smp, in.acScreenNorm);
    __nv_out = c.a > 0.0 ? float4(c.rgb / c.a, c.a) : float4(0.0);
    return __nv_out;
}
