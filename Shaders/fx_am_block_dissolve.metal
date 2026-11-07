// ---------------------------------------------------------------------------
// Dissolver o bloco
// origem : assets/effects/am-block-dissolve.xml
// id     : nova.effect.am-block-dissolve
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_block_dissolveParams {
    float amount;
    float size;
    float2 stretch;
    float seed;
    float fade;
    float2 offset;
};

// --- funcoes auxiliares do efeito
// O `rand` do AM, letra por letra (as constantes em variáveis, como lá).
float rand(float2 co)
{
    float a = 719.310;
    float b = 178.233;
    float c = 33758.5453;
    float dt= dot(co.xy ,float2(a,b));
    float sn= __nv_mod(dt, 3.14);
    return fract(sin(sn) * c);
}

// UV → UV da tela com Y para baixo (o do AM). Na tela (`stage="screen"`) a entrada já é a tela, de pé (t = 0
// EMBAIXO); no filho de grupo, o `eng.acTela` leva o buffer à tela do grupo. Nos dois casos, inverter o t — a mesma
// operação do AM (`1.0 - in.acScreenNorm.y`).
float2 naTela(float2 uv) {
    float2 t = eng.acEntradaDePe == 1 ? uv : __nv_acTela(uv);
    return float2(t.x, 1.0 - t.y);
}

fragment float4 fx_am_block_dissolve(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_block_dissolveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);   // alfa reto
    // Os uniforms do AM com os nomes do Nova: a tela (px da composição), o `location` da camada (px do canto, Y para
    // baixo — o MESMO float do AM: com a camada no meio de uma composição de largura ímpar ele é ,5, e o pixel menos
    // ele cai em cima do inteiro; vindo de uma UV, o último bit mudaria o `floor`) e o conteúdo sem a escala.
    float2 acScreenSize = eng.acTamanhoDaTela;
    float2 acLayerCenter = eng.acCentroDaCamadaPx;
    float2 acLayerSize = eng.acTamanhoDaCamada;

    // Daqui até o `smoothstep`, a conta do AM na mesma ordem.
    float2 st = floor((naTela(in.acScreenNorm)*acScreenSize)-acLayerCenter)/acLayerSize;
    float t = u.seed*3197.3791;
    t = __nv_mod(t, 2.8)+2.7;
    float tileSize = min(acLayerSize.x, acLayerSize.y)/u.size;
    st.x *= acLayerSize.x/acLayerSize.y;
    st -= u.offset/1000.0;
    st *= tileSize;
    st.x /= u.stretch.x;
    st.y /= u.stretch.y;
    st = floor(st);

    float r = rand( st*t );
    float adjFade = max(u.fade,0.00001);
    float adjAmount = u.amount;
    adjAmount -= 0.5;
    adjAmount *= 1.0+(adjFade*2.0);
    adjAmount += 0.5;
    r = smoothstep(adjAmount-adjFade, adjAmount+adjFade, r);

    // O AM multiplica a cor PRÉ-multiplicada por r: a cor reta fica, o alfa é que muda.
    __nv_out = float4(texColor.rgb, texColor.a * r);
    return __nv_out;
}
