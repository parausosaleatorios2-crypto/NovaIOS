// ---------------------------------------------------------------------------
// Bordas lisas
// origem : assets/effects/am-smooth-edges.xml
// id     : nova.effect.am-smooth-edges
// passes : 8
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_smooth_edgesParams {
    float strength;
    int maskToLayer;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

// A gaussiana de meio-lado `lado` (em pixels de `img`), com os pesos tirados um do outro por
// multiplicação e duas amostras juntas numa leitura (a posição entre elas pelo peso), como no AM:
// sigma = lado ÷ 2,146 (a ponta fica em 10 % do centro).
float4 desfocar(sampler2D img, float2 passo, float lado) {
    if (u.strength <= 0.0) return float4(0.0);
    float sigma = lado / 2.14596602;
    float3 g;
    g.x = 1.0 / (sqrt(2.0 * PI) * sigma);
    g.y = exp(-0.5 / (sigma * sigma));
    g.z = g.y * g.y;
    float4 soma = img.sample(__nv_smp, in.acScreenNorm) * g.x;
    float total = g.x;
    for (float i = 1.0; i <= lado; i += 2.0) {
        g.xy *= g.yz;
        total += 2.0 * g.x;
        float p0 = g.x;
        g.xy *= g.yz;
        total += 2.0 * g.x;
        float p1 = g.x;
        float par = p0 + p1;
        float d = (i * p0 + (i + 1.0) * p1) / par;
        soma += img.sample(__nv_smp, in.acScreenNorm - d * passo) * par;
        soma += img.sample(__nv_smp, in.acScreenNorm + d * passo) * par;
    }
    return soma / total;
}

// O meio-lado do desfoque de dentro: Intensidade · 1,14 / 24 da diagonal da imagem cheia.
float ladoDoDesfoque() {
    return u.strength / 2.0 * 1.14 / 4.0 / 3.0 * length(float2(int2(int(pre.get_width()), int(pre.get_height()))));
}

// Um rastro num eixo: de −dist/2 a +dist/2 em fração da imagem (sem a primeira ponta), cada amostra
// por baixo das que estão mais perto do centro. `projeto` = o lado da composição neste eixo.
float4 rastro(sampler2D img, float2 eixo, float projeto) {
    float texel = 1.0 / projeto;
    float dist = u.strength * 0.05;
    int n = int(clamp(dist / texel, 1.01, 100.01));
    float4 c = float4(0.0);
    for (int i = 1; i < n; i++) {
        float d = dist * (float(i) / float(n - 1) - 0.5);
        float4 a = img.sample(__nv_smp, in.acScreenNorm + eixo * d);
        if (d < 0.0) {
            c = c * (1.0 - a.a) + a;
        } else {
            c = a * (1.0 - c.a) + c;
        }
    }
    return c;
}

float4 sobre(float4 baixo, float4 cima) {
    return baixo * (1.0 - cima.a) + cima;
}

// Uma passada: o rastro horizontal e o vertical de `img`, por baixo da camada.
float4 rastros(sampler2D img) {
    // O tamanho da composição (o `eng.acScreenSize` do AM): o buffer na escala da exportação.
    float2 projeto = eng.acResolution / eng.acEscalaDePixel;
    float cima = eng.acEntradaDePe == 1 ? 1.0 : -1.0;
    float4 cx = rastro(img, float2(1.0, 0.0), projeto.x);
    float4 cy = rastro(img, float2(0.0, cima), projeto.y);
    return sobre(sobre(cx, cy), pre.sample(__nv_smp, in.acScreenNorm));
}

fragment float4 fx_am_smooth_edges(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_smooth_edgesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pre [[texture(1)]],
    texture2d<float> downImg [[texture(2)]],
    texture2d<float> blurH [[texture(3)]],
    texture2d<float> blurV [[texture(4)]],
    texture2d<float> hblur [[texture(5)]],
    texture2d<float> hstreak [[texture(6)]],
    texture2d<float> vstreak [[texture(7)]])
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
        __nv_out = desfocar(downImg, passo, ladoDoDesfoque());
        return __nv_out;
    }
    if (eng.acPass == 3) {
        // O passo aponta para CIMA na tela, como o +t do AM: a soma do par (o de baixo primeiro) fica na mesma
        // ordem do AM com a entrada de qualquer lado. Invertida, a soma em float muda 1 nível no alfa desfocado,
        // e o degrau estreito da Intensidade alta faz disso até 129 níveis num pixel.
        float cima = eng.acEntradaDePe == 1 ? 1.0 : -1.0;
        float2 passo = float2(0.0, cima / float2(int2(int(blurH.get_width()), int(blurH.get_height()))).y);
        float4 r = desfocar(blurH, passo, ladoDoDesfoque());
        __nv_out = u.strength <= 0.0 ? pre.sample(__nv_smp, in.acScreenNorm) : r;
        return __nv_out;
    }
    if (eng.acPass == 4) {
        __nv_out = blurV.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }
    // "Máscara para camada": sem rastro (a saída não lê estes dois).
    if (eng.acPass == 5) {
        if (u.maskToLayer) __nv_out = float4(0.0);
        else __nv_out = rastros(pre);
        return __nv_out;
    }
    if (eng.acPass == 6) {
        if (u.maskToLayer) __nv_out = float4(0.0);
        else __nv_out = rastros(hstreak);
        return __nv_out;
    }

    float alfa = hblur.sample(__nv_smp, in.acScreenNorm).a;
    float4 base = u.maskToLayer ? pre.sample(__nv_smp, in.acScreenNorm) : vstreak.sample(__nv_smp, in.acScreenNorm);
    float d = 0.05 / ((1.0 + u.strength) * (1.0 + u.strength));
    float4 saida = base * smoothstep(0.5 - d, 0.5 + d, alfa);
    __nv_out = saida.a > 0.0 ? float4(saida.rgb / saida.a, saida.a) : float4(0.0);
    return __nv_out;
}
