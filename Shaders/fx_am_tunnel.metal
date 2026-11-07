// ---------------------------------------------------------------------------
// Túnel (AM)
// origem : assets/effects/am-tunnel.xml
// id     : nova.effect.am-tunnel
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_tunnelParams {
    float phase;
    float4 fogColor;
    float fog;
    float depth;
    float twirl;
    float wrap;
    float crop;
    int mirror;
};

// --- funcoes auxiliares do efeito
float4 preMultiplicada(float4 c) { return float4(c.rgb * c.a, c.a); }

// O filtro linear da GPU, à mão, sobre a camada PRÉ-multiplicada (a textura do AM é assim): os 4 pixels em volta,
// presos à borda como o CLAMP_TO_EDGE.
float4 camadaNoPonto(float2 uv) {
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
float2 naCamada(float2 t) {
    float3 c = __nv_inverse(eng.acCamadaParaTela) * float3(t, 1.0);
    return c.xy / c.z;
}

fragment float4 fx_am_tunnel(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_tunnelParams&  u    [[buffer(1)]],
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
    // O Y do AM cresce para CIMA (a matriz dele inverte o Y da tela) e o do buffer de camada do Nova para baixo
    // (a linha 0 é o topo): sem isto, o túnel sai espelhado de cima para baixo (o Giro gira ao contrário).
    st.y = 1.0 - st.y;

    // A conta do AM, linha por linha.
    st -= float2(0.5, 0.5);
    float tr = u.twirl * 0.0174533;
    float angle = __nv_atan(st.x, st.y);
    float radius = length(st);
    angle += tr * radius;
    float2 uv = float2(u.depth / radius + u.phase, angle / (3.1415927 * 2. / u.wrap));
    if (u.mirror) {
        uv = abs(__nv_mod(uv, 2.0) - 1.0);
    } else {
        uv = __nv_mod(uv, 1.0);
    }
    uv -= 0.5;
    uv *= u.crop;
    uv += 0.5;

    // De volta ao buffer da camada e à imagem de entrada: na tela (a entrada é a camada já na tela), pela
    // `eng.acCamadaParaTela` sem a divisão da perspectiva quando ela é afim (como o `eng.acLayerToScreen` do AM); no filho
    // de grupo, a própria UV do buffer. O Y volta para baixo.
    float2 b = 0.5 + (float2(uv.x, 1.0 - uv.y) - 0.5) * conteudo / eng.acTamanhoDaTela;
    float2 p = b;
    if (eng.acParaTela == float3x3(1.0)) {
        float3 c = eng.acCamadaParaTela * float3(b, 1.0);
        bool afim = eng.acCamadaParaTela[0].z == 0.0 && eng.acCamadaParaTela[1].z == 0.0 && eng.acCamadaParaTela[2].z == 1.0;
        p = afim ? c.xy : c.xy / c.z;
    }

    // Ponto infinito ou NaN (bem no meio, r = 0): a GPU decide, como no AM.
    bool foraDaConta = any(isinf(p)) || any(isnan(p));
    float4 texColor = foraDaConta ? preMultiplicada(inputImg.sample(__nv_smp, p)) : camadaNoPonto(p);
    float4 nevoa = preMultiplicada(u.fogColor);
    float4 c = radius > 0.5 ? float4(0.) : mix(texColor, nevoa, clamp((1. - radius * 2.) * u.fog, 0., 1.));
    __nv_out = c.a > 0.0 ? float4(min(c.rgb / c.a, float3(1.0)), c.a) : float4(0.0);
    return __nv_out;
}
