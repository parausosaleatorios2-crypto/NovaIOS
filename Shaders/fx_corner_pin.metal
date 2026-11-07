// ---------------------------------------------------------------------------
// Fixar cantos
// origem : assets/effects/corner-pin.xml
// id     : nova.effect.cornerpin
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct corner_pinParams {
    float2 topLeft;
    float2 topRight;
    float2 bottomRight;
    float2 bottomLeft;
    int showOutside;
};

// --- funcoes auxiliares do efeito
const int STEPS = 6;

/** Onde o ponto (u,v) do quadrado unitário cai, depois de pregar os cantos. */
static float2 mapForward(float2 uv) {
    float2 top = mix(u.topLeft, u.topRight, uv.x);
    float2 bottom = mix(u.bottomLeft, u.bottomRight, uv.x);
    return mix(top, bottom, uv.y);
}

fragment float4 fx_corner_pin(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant corner_pinParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // Palpite inicial: o próprio ponto. Para quadriláteros próximos de um
    // retângulo isso já está quase certo, e as iterações fecham a conta.
    float2 guess = in.acScreenNorm;

    for (int i = 0; i < STEPS; i++) {
        float2 landed = mapForward(guess);
        float2 error = landed - in.acScreenNorm;

        // Jacobiano por diferença finita: como o ponto de chegada se move quando
        // se mexe em u e em v. Duas colunas, medidas na hora.
        float2 dU = mapForward(guess + float2(0.001, 0.0)) - landed;
        float2 dV = mapForward(guess + float2(0.0, 0.001)) - landed;
        dU /= 0.001;
        dV /= 0.001;

        float det = dU.x * dV.y - dU.y * dV.x;
        if (abs(det) < 1e-7) break;

        // Passo de Newton: corrige o palpite pelo inverso do Jacobiano.
        guess -= float2(
            (dV.y * error.x - dV.x * error.y) / det,
            (-dU.y * error.x + dU.x * error.y) / det
        );
    }

    bool outside = guess.x < 0.0 || guess.x > 1.0 || guess.y < 0.0 || guess.y > 1.0;
    if (outside && !u.showOutside) {
        __nv_out = float4(0.0);
        return __nv_out;
    }

    __nv_out = inputImg.sample(__nv_smp, clamp(guess, 0.0, 1.0));
    return __nv_out;
}
