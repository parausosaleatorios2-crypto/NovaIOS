// ---------------------------------------------------------------------------
// Xadrez
// origem : assets/effects/checkerboard.xml
// id     : nova.effect.checkerboard
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct checkerboardParams {
    float2 origin;
    float cells;
    float angle;
    float softness;
    float4 colorA;
    float4 colorB;
};

fragment float4 fx_checkerboard(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant checkerboardParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 uv = (in.acScreenNorm - u.origin) * float2(eng.acAspect, 1.0) * max(u.cells, 1.0);

    float rad = radians(u.angle);
    float co = cos(rad);
    float si = sin(rad);
    uv = float2(uv.x * co - uv.y * si, uv.x * si + uv.y * co);

    // Onda triangular em cada eixo, multiplicadas: o produto troca de sinal a
    // cada célula em X e a cada célula em Y, que é exatamente um xadrez.
    float2 wave = abs(fract(uv * 0.5) * 2.0 - 1.0) * 2.0 - 1.0;
    float board = wave.x * wave.y;

    float soft = max(u.softness, 0.0005);
    float mask = smoothstep(-soft, soft, board);

    float4 pattern = mix(u.colorB, u.colorA, mask);
    __nv_out = float4(pattern.rgb, pattern.a * original.a);
    return __nv_out;
}
