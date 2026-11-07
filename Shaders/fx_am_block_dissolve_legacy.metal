// ---------------------------------------------------------------------------
// Dissolver o bloco (antigo)
// origem : assets/effects/am-block-dissolve-legacy.xml
// id     : nova.effect.am-block-dissolve-legacy
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_block_dissolve_legacyParams {
    float amount;
    float size;
    float stretch;
    float seed;
    float fade;
    float2 offset;
};

// --- funcoes auxiliares do efeito
// O `rand` do AM, letra por letra.
float rand(float2 co)
{
    float a = 719.310;
    float b = 178.233;
    float c = 33758.5453;
    float dt= dot(co.xy ,float2(a,b));
    float sn= __nv_mod(dt, 3.14);
    return fract(sin(sn) * c);
}

// Ver `am-block-dissolve.xml`.
float2 naTela(float2 uv) {
    float2 t = eng.acEntradaDePe == 1 ? uv : __nv_acTela(uv);
    return float2(t.x, 1.0 - t.y);
}

fragment float4 fx_am_block_dissolve_legacy(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_block_dissolve_legacyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);   // alfa reto
    float2 acScreenSize = eng.acTamanhoDaTela;
    float2 acLayerCenter = eng.acCentroDaCamadaPx;
    float2 acLayerSize = eng.acTamanhoDaCamada;

    float2 st = floor((naTela(in.acScreenNorm)*acScreenSize)-acLayerCenter)/acLayerSize;
    float t = u.seed*3197.3791;
    t = __nv_mod(t, 2.8)+2.7;
    float tileSize = min(acLayerSize.x, acLayerSize.y)/u.size;
    st.x *= acLayerSize.x/acLayerSize.y;
    st -= u.offset/1000.0;
    st *= tileSize;
    if( u.stretch < 0.0 ) {
        st.x /= 1.0-u.stretch;
    } else {
        st.y /= 1.0+u.stretch;
    }
    st = floor(st);

    float r = rand( st*t );
    float adjFade = max(u.fade,0.00001);
    float adjAmount = u.amount;
    adjAmount -= 0.5;
    adjAmount *= 1.0+(adjFade*2.0);
    adjAmount += 0.5;
    r = smoothstep(adjAmount-adjFade, adjAmount+adjFade, r);

    __nv_out = float4(texColor.rgb, texColor.a * r);
    return __nv_out;
}
