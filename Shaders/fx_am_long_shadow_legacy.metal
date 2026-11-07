// ---------------------------------------------------------------------------
// Sombra longa (AM, versão 1)
// origem : assets/effects/am-long-shadow-legacy.xml
// id     : nova.effect.am-long-shadow-legacy
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_long_shadow_legacyParams {
    float size;
    float angle;
    float4 color;
    float alpha;
    float solidity;
    float fill;
    float fade;
    int fadeType;
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

// A volta do `eng.acTela`: UV da tela → UV do buffer (no filho de grupo; na tela, a identidade).
static float2 daTela(float2 t) {
    float3 c = __nv_inverse(eng.acParaTela) * float3(t, 1.0);
    return c.xy / c.z;
}

// O alfa da camada num ponto da tela do AM. Na tela o buffer É a tela; no filho de grupo, fora do buffer não há
// camada (o AM a desenha na tela do grupo).
static float alfaNaTela(float2 t) {
    if (eng.acEntradaDePe == 1) return inputImg.sample(__nv_smp, t).a;
    float2 uv = daTela(t);
    if (any(lessThan(uv, float2(0.0))) || any(greaterThan(uv, float2(1.0)))) return 0.0;
    return inputImg.sample(__nv_smp, uv).a;
}

// O fundo (a cena montada atrás da camada) no pixel da tela, pré-multiplicado.
static float3 fundoNoPixel() {
    int2 T = int2(int(comp.get_width()), int(comp.get_height()));
    int2 px = clamp(int2(floor(__nv_acTela(in.acScreenNorm) * float2(T))), int2(0), T - 1);
    float4 f = comp.read(uint2(px), uint(0));
    return f.rgb * f.a;
}

// A saída pré-multiplicada do AM em cor reta (a do Anel (AM)). O alvo de 8 bits do AM corta abaixo de 0 e acima de
// 1. O comum (cor ≤ alfa) é só dividir. Com a cor acima do alfa (uma Cor com alfa abaixo de 1), a composição do AM
// SOMA a luz ao fundo (`p + fundo·(1 − op·alfa)`): este pixel leva junto o fundo dele, com o menor alfa `a` em que
// a cor reta `s = fundo + (p − fundo·alfa)/a` cabe entre 0 e 1 — a composição Normal do Nova dá o mesmo com
// qualquer opacidade da camada, até a soma passar de 1.
static float4 paraReta(float4 p) {
    p = clamp(p, 0.0, 1.0);
    // Quem decide se a cor passou do alfa é o alvo de 8 bits do AM (um resto de conta abaixo de meio nível some lá).
    float4 q = floor(p * 255.0 + 0.5) / 255.0;
    if (all(lessThanEqual(q.rgb, float3(q.a)))) return p.a > 0.0 ? float4(min(p.rgb / p.a, float3(1.0)), p.a) : float4(0.0);
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

static float projectAndClampDist(float2 a, float2 b) {
    return clamp(dot(a,b)/dot(b,b),0.0,1.0);
}

fragment float4 fx_am_long_shadow_legacy(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_long_shadow_legacyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // O `in.acScreenNorm` do AM: a UV da tela com t = 0 EMBAIXO. Na tela (`stage="screen"`) a entrada já é a tela, de
    // pé; no filho de grupo, o `eng.acTela` leva o buffer à tela do grupo (também de pé).
    float2 tela = eng.acEntradaDePe == 1 ? in.acScreenNorm : __nv_acTela(in.acScreenNorm);
    float2 acScreenSize = eng.acTamanhoDaTela;
    // O `eng.acLayerCenterNorm` do AM (`ssl/W.render`): o location em px da tela (Y para baixo) ÷ a tela, Y para cima.
    float2 eng.acLayerCenterNorm = float2(eng.acCentroDaCamadaPx.x / acScreenSize.x,
                                  (acScreenSize.y - eng.acCentroDaCamadaPx.y) / acScreenSize.y);

    // A conta do AM, linha por linha. O `__nv_getTexSize(inputImg_info.size)` é o tamanho da camada na tela, em pixels da
    // renderização (a prévia reduzida inclusive).
    float2 imgSize = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    // O `acPreviewSize` do AM: o tamanho da renderização (o do buffer da tela, a prévia reduzida inclusive).
    float2 acPreviewSize = imgSize;
    float2 texelSize = 1.0 / imgSize;
    float rad = u.angle * 0.0174533;
    float2 velocity = float2(cos(rad)*u.size,-sin(rad)*u.size);
    velocity *= acPreviewSize/imgSize;
    velocity.x *= acScreenSize.y / acScreenSize.x;
    float speed = length(velocity / texelSize);
    int nSamples = int(clamp(speed, 1.01, 500.01));
    float maxAlpha = 0.0;
    float accumAlpha = 0.0;
    int minDist = nSamples;
    float4 baseColor = camadaNoPonto(eng.acEntradaDePe == 1 ? tela : daTela(tela));
    for(int i=1; i<nSamples; i++ ) {
        float2 offset = velocity * (float(i) / float(nSamples - 1));
        float2 sampleCoord = tela-offset;
        float insideTexture = step(0.0,sampleCoord.x) * step(sampleCoord.x,1.0) * step(0.0,sampleCoord.y) * step(sampleCoord.y,1.0);
        // (desempenho, 0.805.0) A amostra anda em linha reta: saiu da tela, não volta, e cada passo dali em
        // diante soma zero (o max, o minDist e o acúmulo ficam iguais) — o resto do laço não muda nada.
        if (insideTexture == 0.0) break;
        float sampAlpha = alfaNaTela(sampleCoord) * insideTexture;
        maxAlpha = max(maxAlpha, sampAlpha);
        if( sampAlpha > 0.5 ) {
            minDist = min(minDist,i);
        }
        float adjAlpha = sampAlpha*u.solidity*0.25;
        accumAlpha = adjAlpha + accumAlpha*(1.0-adjAlpha);
        // Com Solidez 1 (o padrão) o resultado é o maxAlpha, e o minDist já é o da 1ª amostra acima de 0,5:
        // chegou a 1, nada mais muda.
        if (u.solidity == 1.0 && maxAlpha >= 1.0) break;
    }
    float resultAlpha = mix(accumAlpha,maxAlpha,u.solidity);
    float dist = 0.0;
    if( u.fadeType==0 ) {
        dist = float(minDist)/float(nSamples);
    } else if( u.fadeType==1 ) {
        dist = projectAndClampDist(tela-eng.acLayerCenterNorm,velocity);
    } else if( u.fadeType==2 ) {
        dist = abs((tela-eng.acLayerCenterNorm).x) / abs(velocity.x);
    } else if( u.fadeType==3 ) {
        dist = abs((tela-eng.acLayerCenterNorm).y) / abs(velocity.y);
    }
    __nv_out = paraReta(mix(u.color * u.alpha * (1.0-dist*u.fade) * resultAlpha, baseColor, baseColor.a * u.fill));
    return __nv_out;
}
