// ---------------------------------------------------------------------------
// Faixas Lineares
// origem : assets/effects/am-linear-streaks.xml
// id     : nova.effect.am-linear-streaks
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_linear_streaksParams {
    float strength;
    float angle;
    float alpha;
    float bias;
    int rmode;
    int gmode;
    int bmode;
    int amode;
};

// --- funcoes auxiliares do efeito
// Pré-calculado uma vez por pixel no passe 1 para não chamar inverse() em cada amostra do laço.
float3x3 g_invParaTela;

// A volta do `eng.acTela`: UV da tela → UV do buffer (no filho de grupo; na tela, a identidade).
static float2 daTela(float2 t) {
    float3 c = g_invParaTela * float3(t, 1.0);
    return c.xy / c.z;
}

// O `inputImg.sample(__nv_smp, t)` do AM: a camada pré-multiplicada num ponto da tela, com o filtro da GPU. Na
// tela o buffer É a tela; no filho de grupo, fora do buffer não há camada (o AM a desenha na tela do grupo).
static float4 camadaNaTela(float2 t) {
    if (eng.acEntradaDePe == 1) return pre.sample(__nv_smp, t);
    float2 uv = daTela(t);
    if (any(lessThan(uv, float2(0.0))) || any(greaterThan(uv, float2(1.0)))) return float4(0.0);
    return pre.sample(__nv_smp, uv);
}

fragment float4 fx_am_linear_streaks(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_linear_streaksParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pre [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& pre_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
        __nv_out = float4(c.rgb * c.a, c.a);
        return __nv_out;
    }
    g_invParaTela = __nv_inverse(eng.acParaTela);

    // O `in.acScreenNorm` do AM: a UV da tela com t = 0 EMBAIXO. Na tela (`stage="screen"`) a entrada já é a tela, de
    // pé; no filho de grupo, o `eng.acTela` leva o buffer à tela do grupo (também de pé).
    float2 tela = eng.acEntradaDePe == 1 ? in.acScreenNorm : __nv_acTela(in.acScreenNorm);
    float2 acScreenSize = eng.acTamanhoDaTela;

    // A conta do AM, linha por linha. O `__nv_getTexSize(inputImg_info.size)` é o tamanho da camada na tela, em pixels da
    // renderização (a prévia reduzida inclusive).
    float2 texelSize = 1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())));
    float rad = u.angle * 0.0174533;
    float2 velocity = float2(cos(rad)*u.strength,-sin(rad)*u.strength);
    velocity.x *= acScreenSize.y / acScreenSize.x;
    float speed = length(velocity / texelSize);
    int nSamples = int(clamp(speed, 1.01, 100.01));
    float4 originalColor = camadaNaTela(tela);
    float4 outColor = originalColor;
    outColor.rgb = outColor.a > 0.0 ? outColor.rgb/outColor.a : outColor.rgb;
    for(int i=1; i<nSamples; i++ ) {
        float2 offset = velocity * (float(i) / float(nSamples - 1) - (0.5+u.bias/2.0));
        float2 sampleCoord = tela-offset;
        float insideTexture = step(0.0,sampleCoord.x) * step(sampleCoord.x,1.0) * step(0.0,sampleCoord.y) * step(sampleCoord.y,1.0);
        float4 c = camadaNaTela(sampleCoord) * insideTexture;
        float r;
        float g;
        float b;
        float a;
        if( u.rmode == 0 ) {
            r = min(outColor.r,c.r);
        } else if( u.rmode == 1 ) {
            r = max(outColor.r,c.r);
        } else if( u.rmode == 3 ) {
            r = outColor.r + c.r;
        } else {
            r = outColor.r;
        }
        if( u.gmode == 0 ) {
            g = min(outColor.g,c.g);
        } else if( u.gmode == 1 ) {
            g = max(outColor.g,c.g);
        } else if( u.gmode == 3 ) {
            g = outColor.g + c.g;
        } else {
            g = outColor.g;
        }
        if( u.bmode == 0 ) {
            b = min(outColor.b,c.b);
        } else if( u.bmode == 1 ) {
            b = max(outColor.b,c.b);
        } else if( u.bmode == 3 ) {
            b = outColor.b + c.b;
        } else {
            b = outColor.b;
        }
        if( u.amode == 0 ) {
            a = min(outColor.a,c.a);
        } else if( u.amode == 1 ) {
            a = max(outColor.a,c.a);
        } else if( u.amode == 3 ) {
            a = outColor.a + c.a;
        } else {
            a = outColor.a;
        }
        outColor = float4(r,g,b,a);
    }
    outColor = outColor / float4(
        u.rmode == 3 ? float(nSamples) : 1.0,
        u.gmode == 3 ? float(nSamples) : 1.0,
        u.bmode == 3 ? float(nSamples) : 1.0,
        u.amode == 3 ? float(nSamples) : 1.0
    );
    outColor.rgb *= outColor.a;
    float4 p = mix(originalColor,outColor,u.alpha);

    // A saída pré-multiplicada do AM (o alvo de 8 bits dele corta em 0..1) em cor reta.
    p = clamp(p, 0.0, 1.0);
    __nv_out = p.a > 0.0 ? float4(min(p.rgb / p.a, float3(1.0)), p.a) : float4(0.0);
    return __nv_out;
}
