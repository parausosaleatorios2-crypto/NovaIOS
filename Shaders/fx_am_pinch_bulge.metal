// ---------------------------------------------------------------------------
// Pinçar/saliências
// origem : assets/effects/am-pinch-bulge.xml
// id     : nova.effect.am-pinch-bulge
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_pinch_bulgeParams {
    float2 centerPoint;
    float strength;
    float radius;
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

// A volta do `eng.acTela`: UV da tela → UV do buffer (no filho de grupo; na tela, a identidade).
float2 daTela(float2 t) {
    float3 c = __nv_inverse(eng.acParaTela) * float3(t, 1.0);
    return c.xy / c.z;
}

fragment float4 fx_am_pinch_bulge(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_pinch_bulgeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // O `in.acScreenNorm` do AM: a UV da tela com t = 0 EMBAIXO. Na tela (`stage="screen"`) a entrada já é a tela, de
    // pé; no filho de grupo, o `eng.acTela` leva o buffer à tela do grupo (também de pé).
    float2 UV = eng.acEntradaDePe == 1 ? in.acScreenNorm : __nv_acTela(in.acScreenNorm);
    float2 acScreenSize = eng.acTamanhoDaTela;
    // O `eng.acLayerCenterNorm` do AM (`ssl/W.render`): o location em px da tela (Y para baixo) ÷ a tela, Y para cima.
    float2 eng.acLayerCenterNorm = float2(eng.acCentroDaCamadaPx.x / acScreenSize.x,
                                  (acScreenSize.y - eng.acCentroDaCamadaPx.y) / acScreenSize.y);

    // A conta do AM, linha por linha.
    float2 center = eng.acLayerCenterNorm-(u.centerPoint/1000. * float2(-1.,1.));

    UV -= center;
    UV.x *= acScreenSize.x / acScreenSize.y;
    float dist = length(UV);
    if ( dist < u.radius ) {
        float p = dist / u.radius;
        if(u.strength > 0.) {
            UV *= mix(1.0, smoothstep(0.0, u.radius / dist, p), u.strength * 0.75);
        } else {
            UV *= mix(1.0, pow(p, 1.0 + u.strength * 0.75) * u.radius / dist, 1.0 - p);
        }
    }
    UV.x /= acScreenSize.x / acScreenSize.y;
    UV += center;

    float2 uv = eng.acEntradaDePe == 1 ? UV : daTela(UV);
    // NaN (o pixel bem no centro, 0 × ∞): a GPU decide, como no AM.
    bool foraDaConta = any(isinf(uv)) || any(isnan(uv));
    float4 c = foraDaConta ? preMultiplicada(inputImg.sample(__nv_smp, uv)) : camadaNoPonto(uv);
    __nv_out = c.a > 0.0 ? float4(c.rgb / c.a, c.a) : float4(0.0);
    return __nv_out;
}
