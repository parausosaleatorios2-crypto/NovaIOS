// ---------------------------------------------------------------------------
// Balanço de cor
// origem : assets/effects/color-balance.xml
// id     : nova.effect.color-balance
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct color_balanceParams {
    float temperature;
    float tint;
    float lift;
    float gammaValue;
    float gain;
};

fragment float4 fx_color_balance(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant color_balanceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);
    float3 col = color.rgb;

    // Temperatura empurra vermelho e azul em sentidos opostos: é assim que a
    // imagem "esquenta" sem virar simplesmente mais clara.
    //
    // Era 0,12/0,10 — no máximo do controle (±100%) isso somava só ±0,12 num
    // canal de 0 a 1, quase imperceptível. Relato do snow (25/09/2026): "isso
    // acontece com basicamente todos os efeitos" — este e o "Temperatura de
    // cor" tinham o mesmo problema, cada um com seu próprio multiplicador
    // fraco. Com 0,5/0,4 o máximo empurra de verdade (e o `clamp` final
    // continua garantindo que não estoura nem inverte).
    col.r += u.temperature * 0.5;
    col.b -= u.temperature * 0.5;
    col.g += u.tint * 0.4;

    col = col + u.lift * 0.2 * (1.0 - col);
    col = pow(max(col, 0.0), float3(1.0 / max(u.gammaValue, 0.05)));
    col = col * u.gain;

    __nv_out = float4(clamp(col, 0.0, 1.0), color.a);
    return __nv_out;
}
