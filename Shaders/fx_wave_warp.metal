// ---------------------------------------------------------------------------
// Onda
// origem : assets/effects/wave-warp.xml
// id     : nova.effect.wavewarp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct wave_warpParams {
    float amplitude;
    float frequency;
    float speed;
    float phase;
    int direction;
};

fragment float4 fx_wave_warp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant wave_warpParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // A fase total soma a parte que anda sozinha (eng.acTime * u.speed) com a parte
    // que o usuário controla por keyframe. Zerar `u.speed` deixa a fase 100% nas
    // mãos de quem edita.
    float t = eng.acTime * u.speed + radians(u.phase);

    // Amplitude vem em pixels e precisa virar coordenada de textura, senão o
    // efeito ficaria mais forte em projeto pequeno e fraco em 4K.
    float2 amp = u.amplitude * eng.acEscalaDePixel * eng.acTexelSize;

    float2 offset = float2(0.0);

    if (u.direction == 0 || u.direction == 2) {
        offset.x = sin(in.acScreenNorm.y * u.frequency * 6.28318 + t) * amp.x;
    }
    if (u.direction == 1 || u.direction == 2) {
        // O deslocamento em 1.7 tira as duas ondas de sincronia. Se as duas
        // usassem a mesma fase, o resultado seria um movimento diagonal
        // engessado em vez de algo que parece líquido.
        offset.y = sin(in.acScreenNorm.x * u.frequency * 6.28318 + t * 1.7) * amp.y;
    }

    float2 uv = in.acScreenNorm + offset;

    // Fora dos limites da camada não existe conteúdo. Devolver transparente é
    // mais honesto que deixar o CLAMP_TO_EDGE esticar a borda em faixas.
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        __nv_out = float4(0.0);
        return __nv_out;
    }

    __nv_out = inputImg.sample(__nv_smp, uv);
    return __nv_out;
}
