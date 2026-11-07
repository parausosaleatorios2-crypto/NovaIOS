// ---------------------------------------------------------------------------
// Pena
// origem : assets/effects/am-feather.xml
// id     : nova.effect.am-feather
// passes : 4  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_featherParams {
    float strength;
    float iter;
};

// --- funcoes auxiliares do efeito
// Uma caixa do AM no alfa de `fonte`: o centro e n amostras de cada lado até ±alcance, com o filtro linear. As contas
// são escritas como as do AM (o ângulo em graus × 0,0174533, a velocidade ÷ o texel) para dar o mesmo n.
float caixa(sampler2D fonte, float graus, float alcance) {
    float2 texel = 1.0 / float2(int2(int(fonte.get_width()), int(fonte.get_height())));
    float rad = graus * 0.0174533;
    float2 velocidade = float2(cos(rad) * alcance, -sin(rad) * alcance);
    int n = int(clamp(length(velocidade / texel), 2.01, 100.01));
    float soma = fonte.sample(__nv_smp, in.acScreenNorm).a;
    for (int i = 1; i < n; i++) {
        float2 d = velocidade * (float(i) / float(n - 1));
        soma += fonte.sample(__nv_smp, in.acScreenNorm + d).a;
        soma += fonte.sample(__nv_smp, in.acScreenNorm - d).a;
    }
    return soma / float(n * 2 - 1);
}

fragment float4 fx_am_feather(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_featherParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> ds1 [[texture(1)]],
    texture2d<float> ds2 [[texture(2)]],
    texture2d<float> hblur [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 camada = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (u.strength <= 0.005) {
        __nv_out = camada;
        return __nv_out;
    }
    float alcance = u.strength / 4.0 / u.iter;
    // Um ramo por passe, cada um terminando em `return`: é o formato que a poda do motor (`PodaDoPasse`)
    // corta por passe — um `else if` encadeado deixaria `else` solto no programa do último.
    if (eng.acPass == 0) {
        __nv_out = float4(camada.a);                         // a metade: só o alfa interessa daqui em diante
        return __nv_out;
    }
    if (eng.acPass == 1) {
        __nv_out = float4(ds1.sample(__nv_smp, in.acScreenNorm).a);     // a quarta parte
        return __nv_out;
    }
    if (eng.acPass == 2) {
        __nv_out = float4(caixa(ds2, 0.0, alcance));         // a caixa na horizontal
        return __nv_out;
    }
    float a = caixa(hblur, 90.0, alcance);                  // na vertical, já subindo para a resolução cheia
    __nv_out = float4(camada.rgb, camada.a * a * a);         // reta: a cor fica, o alfa afina
    return __nv_out;
}
