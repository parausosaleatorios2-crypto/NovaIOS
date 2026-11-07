// ---------------------------------------------------------------------------
// Listras
// origem : assets/effects/am-stripes.xml
// id     : nova.effect.am-stripes
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_stripesParams {
    float amount;
    float width;
    float angle;
    float phase;
    float4 color;
    int punchout;
    float smoothing;
    int screenSpace;
};

// --- funcoes auxiliares do efeito
// O smoothstep do AM com as pontas em qualquer ordem (o GLSL não garante o resultado com e0 > e1). Com as
// pontas iguais o AM divide por zero: ±infinito, preso em 0 ou 1 — o degrau x > e0 (a GPU do PC; no ponto
// exato ela dá NaN e o pixel some, aqui fica 0).
static float degrau(float e0, float e1, float x) {
    if (e1 == e0) return x > e0 ? 1.0 : 0.0;
    float t = clamp((x - e0) / (e1 - e0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

// UV do buffer → UV da tela, com Y para baixo (o do AM). O `eng.acTela` devolve a UV da cena guardada de pé, a do GL
// (t = 0 EMBAIXO: é com ela que o Copiar fundo amostra o fundo), e a cena de pé (grupo solto, modelo 3D, ajuste) já
// é essa tela. Nos dois casos, inverter o t.
static float2 naTela(float2 uv) {
    float2 t = eng.acEntradaDePe == 1 ? uv : __nv_acTela(uv);
    return float2(t.x, 1.0 - t.y);
}

fragment float4 fx_am_stripes(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_stripesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 base = inputImg.sample(__nv_smp, in.acScreenNorm);   // alfa reto
    float2 tela = naTela(in.acScreenNorm);

    // A conta na MESMA ordem do AM (em px da tela, a matriz por fora): na borda dura (Suavização 0) um pixel
    // que cai em cima da borda vira para um lado ou o outro pelo arredondamento do float.
    float2 st;
    if (u.screenSpace) {
        st = tela;
        st -= 0.5;
        st.x *= eng.acTamanhoDaTela.x / eng.acTamanhoDaTela.y;
    } else {
        st = ((tela * eng.acTamanhoDaTela) - naTela(eng.acCentroDaCamada) * eng.acTamanhoDaTela) / length(eng.acTamanhoDaCamada);
    }
    float a = u.angle * 0.0174533;
    st *= float2x2(
        sin(a), -cos(a),
        cos(a), sin(a)
    );
    float p = __nv_mod(st.x * u.amount + u.phase, 1.0);
    p = degrau(u.width, u.width - u.smoothing, p) * degrau(0.0, u.smoothing, p);

    float4 camada = float4(base.rgb * base.a, base.a);   // pré-multiplicada, como o AM
    float4 saida;
    if (u.punchout) {
        saida = camada * (1.0 - p);
    } else {
        float4 c = float4(u.color.rgb * u.color.a, u.color.a) * (p * base.a);
        saida = c + camada * (1.0 - c.a);
    }
    __nv_out = saida.a > 0.0 ? float4(saida.rgb / saida.a, saida.a) : float4(0.0);
    return __nv_out;
}
