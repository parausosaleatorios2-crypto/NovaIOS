// ---------------------------------------------------------------------------
// Apertar (AM)
// origem : assets/effects/am-squeeze.xml
// id     : nova.effect.am-squeeze
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_squeezeParams {
    float strength;
};

// --- funcoes auxiliares do efeito
static float4 preMultiplicada(float4 c) { return float4(c.rgb * c.a, c.a); }

// O filtro linear da GPU, à mão, sobre a camada PRÉ-multiplicada (a textura do AM é assim): os 4 pixels em volta,
// presos à borda como o CLAMP_TO_EDGE.
static float4 camadaNoPonto(float2 uv) {
    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float2 p = uv * float2(T) - 0.5;
    float2 i = floor(p);
    float2 f = p - i;
    int2 a = int2(i);
    int2 m = T - 1;
    float4 c00 = preMultiplicada(inputImg.read(uint2(clamp(a, int2(0), m)), uint(0)));
    float4 c10 = preMultiplicada(inputImg.read(uint2(clamp(a + int2(1, 0), int2(0), m)), uint(0)));
    float4 c01 = preMultiplicada(inputImg.read(uint2(clamp(a + int2(0, 1), int2(0), m)), uint(0)));
    float4 c11 = preMultiplicada(inputImg.read(uint2(clamp(a + int2(1, 1), int2(0), m)), uint(0)));
    return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

// A volta da `eng.acCamadaParaTela`: UV da tela → UV do buffer da camada.
static float2 naCamada(float2 t) {
    float3 c = __nv_inverse(eng.acCamadaParaTela) * float3(t, 1.0);
    return c.xy / c.z;
}

fragment float4 fx_am_squeeze(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_squeezeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // O pixel na tela (na tela, a identidade; no filho de grupo, o buffer dele levado à tela do grupo) e, de lá, a
    // coordenada da camada do AM: o retângulo do conteúdo de 0 a 1, com o meio no meio do buffer (o buffer cobre a
    // composição, `eng.acTamanhoDaTela`).
    float2 conteudo = max(eng.acTamanhoDaCamada, float2(1e-6));
    float2 st = 0.5 + (naCamada(__nv_acTela(in.acScreenNorm)) - 0.5) * eng.acTamanhoDaTela / conteudo;

    // A conta do AM, linha por linha.
    float str = u.strength / 2.0;
    st -= 0.5;
    st *= 2.0;
    float xdiv = 1. + (1. - pow(abs(st.y), 2.0)) * -str;
    float ydiv = 1. + (1. - pow(abs(st.x), 2.0)) * str;
    xdiv = clamp(xdiv, 0., 2.);
    ydiv = clamp(ydiv, 0., 2.);
    st.x /= xdiv;
    st.y /= ydiv;
    st /= 2.0;
    st += 0.5;

    // De volta ao buffer da camada e à imagem de entrada: na tela (a entrada é a camada já na tela), pela
    // `eng.acCamadaParaTela` sem a divisão da perspectiva quando ela é afim (como o `eng.acLayerToScreen` do AM: o ponto
    // infinito segue infinito, e não vira NaN na divisão); no filho de grupo, a própria UV do buffer.
    float2 b = 0.5 + (st - 0.5) * conteudo / eng.acTamanhoDaTela;
    float2 uv = b;
    if (eng.acParaTela == float3x3(1.0)) {
        float3 c = eng.acCamadaParaTela * float3(b, 1.0);
        bool afim = eng.acCamadaParaTela[0].z == 0.0 && eng.acCamadaParaTela[1].z == 0.0 && eng.acCamadaParaTela[2].z == 1.0;
        uv = afim ? c.xy : c.xy / c.z;
    }

    // Ponto infinito ou NaN (longe da caixa, a divisão chegou a 0): a GPU decide, como no AM.
    bool foraDaConta = any(isinf(uv)) || any(isnan(uv));
    float4 c = foraDaConta ? preMultiplicada(inputImg.sample(__nv_smp, uv)) : camadaNoPonto(uv);
    __nv_out = c.a > 0.0 ? float4(c.rgb / c.a, c.a) : float4(0.0);
    return __nv_out;
}
