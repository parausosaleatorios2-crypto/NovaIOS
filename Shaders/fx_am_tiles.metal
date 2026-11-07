// ---------------------------------------------------------------------------
// Azulejos
// origem : assets/effects/am-tiles.xml
// id     : nova.effect.am-tiles
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_tilesParams {
    float scale;
    float phase;
    int mirror;
    int vertoffs;
    float angle;
};

// --- funcoes auxiliares do efeito
static float4 preMultiplicada(float4 c) { return float4(c.rgb * c.a, c.a); }

// O filtro linear da GPU, à mão, sobre a camada PRÉ-multiplicada (a textura do AM é assim): os 4 pixels em volta,
// presos à borda como o CLAMP_TO_EDGE.
static float4 camadaNoPonto(sampler2D img, float2 uv) {
    int2 T = int2(int(img.get_width()), int(img.get_height()));
    float2 p = uv * float2(T) - 0.5;
    float2 i = floor(p);
    float2 f = p - i;
    int2 a = int2(i);
    int2 m = T - 1;
    float4 c00 = preMultiplicada(img.read(uint2(clamp(a, int2(0), m)), uint(0)));
    float4 c10 = preMultiplicada(img.read(uint2(clamp(a + int2(1, 0), int2(0), m)), uint(0)));
    float4 c01 = preMultiplicada(img.read(uint2(clamp(a + int2(0, 1), int2(0), m)), uint(0)));
    float4 c11 = preMultiplicada(img.read(uint2(clamp(a + int2(1, 1), int2(0), m)), uint(0)));
    return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

// O mesmo filtro no buffer da camada inteira, mas fora dele é NADA (transparente), e não a borda esticada. Fora do
// buffer a camada não tem pixel: com Recortar abaixo de 1 numa camada do tamanho da tela, a busca passava da borda e
// as fileiras de cima e de baixo viravam listras (relato do Discord, 25/10/2026).
static float4 texelOuNada(sampler2D img, int2 a, int2 m) {
    if (any(lessThan(a, int2(0))) || any(greaterThan(a, m))) return float4(0.0);
    return preMultiplicada(img.read(uint2(a), uint(0)));
}
static float4 camadaSemBorda(sampler2D img, float2 uv) {
    int2 T = int2(int(img.get_width()), int(img.get_height()));
    float2 p = uv * float2(T) - 0.5;
    float2 i = floor(p);
    float2 f = p - i;
    int2 a = int2(i);
    int2 m = T - 1;
    float4 c00 = texelOuNada(img, a, m);
    float4 c10 = texelOuNada(img, a + int2(1, 0), m);
    float4 c01 = texelOuNada(img, a + int2(0, 1), m);
    float4 c11 = texelOuNada(img, a + int2(1, 1), m);
    return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

// A volta da `eng.acCamadaParaTela`: UV da tela → UV do buffer da camada.
static float2 naCamada(float2 t) {
    float3 c = __nv_inverse(eng.acCamadaParaTela) * float3(t, 1.0);
    return c.xy / c.z;
}

fragment float4 fx_am_tiles(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_tilesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> camadaInteira [[texture(1)]])
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
    // (a linha 0 é o topo): sem isto, andam as fileiras erradas e o Ângulo gira ao contrário.
    st.y = 1.0 - st.y;

    // A conta do AM, linha por linha. Os 4 pixels são da imagem renderizada (ver o topo).
    float2 pixelSize = eng.acEscalaDePixel / float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    float2 tiledCoord = st;
    if (u.vertoffs) {
        tiledCoord.y += step(1., __nv_mod(tiledCoord.x, 2.0)) * u.phase;
    } else {
        tiledCoord.x += step(1., __nv_mod(tiledCoord.y, 2.0)) * u.phase;
    }
    if (u.mirror) {
        tiledCoord = abs(__nv_mod(tiledCoord - float2(1.0, 1.0), float2(2.0, 2.0)) - float2(1.0, 1.0));
    } else {
        tiledCoord = __nv_mod(tiledCoord, float2(1.0, 1.0));
    }
    float a = u.angle * 0.0174533;
    float2x2 rot = float2x2(
        cos(a), -sin(a),
        sin(a), cos(a)
    );
    float2 scaledCoord = tiledCoord;
    scaledCoord -= float2(0.5, 0.5);
    scaledCoord *= float2(1.0) / (u.scale + pixelSize * 4.0);
    scaledCoord.x *= conteudo.x / conteudo.y;
    scaledCoord *= rot;
    scaledCoord.x *= conteudo.y / conteudo.x;
    scaledCoord += float2(0.5, 0.5);

    // De volta ao buffer da camada e à imagem de entrada: na tela (a entrada é a camada já na tela), pela
    // `eng.acCamadaParaTela` sem a divisão da perspectiva quando ela é afim (como o `eng.acLayerToScreen` do AM; o filho de
    // grupo também vem por aqui desde a 0.622.0, na tela do grupo); numa camada desenhada à parte (o mapa de outro
    // efeito), a própria UV do buffer. O Y volta para baixo.
    float2 b = 0.5 + (float2(scaledCoord.x, 1.0 - scaledCoord.y) - 0.5) * conteudo / eng.acTamanhoDaTela;
    // Na tela com a camada inteira à mão: a busca vai ao buffer DELA, e não à camada já na tela. Lá o que a camada
    // tem fora da tela não existe — arrastada para fora, a borda esticava em listras e depois sumia tudo (relato de
    // 22/10/2026). Com a camada inteira na tela, dá o mesmo que antes. Fora do buffer dela, transparente.
    if (eng.acParaTela == float3x3(1.0) && eng.acCamadaPropria == 1) {
        float2 q = 0.5 + (b - 0.5) / max(eng.acFolgaDaCamada, 1e-6);
        // Longe demais o int2 do floor estoura: fora de [-1, 2] já é nada.
        bool longe = any(isinf(q)) || any(isnan(q)) || any(lessThan(q, float2(-1.0))) || any(greaterThan(q, float2(2.0)));
        float4 d = longe ? float4(0.0) : camadaSemBorda(camadaInteira, q);
        __nv_out = d.a > 0.0 ? float4(min(d.rgb / d.a, float3(1.0)), d.a) : float4(0.0);
        return __nv_out;
    }
    float2 p = b;
    if (eng.acParaTela == float3x3(1.0)) {
        float3 c = eng.acCamadaParaTela * float3(b, 1.0);
        bool afim = eng.acCamadaParaTela[0].z == 0.0 && eng.acCamadaParaTela[1].z == 0.0 && eng.acCamadaParaTela[2].z == 1.0;
        p = afim ? c.xy : c.xy / c.z;
    }

    // Ponto infinito ou NaN (camada sem tamanho): a GPU decide, como no AM.
    bool foraDaConta = any(isinf(p)) || any(isnan(p));
    float4 c = foraDaConta ? preMultiplicada(inputImg.sample(__nv_smp, p)) : camadaNoPonto(inputImg, p);
    __nv_out = c.a > 0.0 ? float4(min(c.rgb / c.a, float3(1.0)), c.a) : float4(0.0);
    return __nv_out;
}
