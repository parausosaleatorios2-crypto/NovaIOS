// ---------------------------------------------------------------------------
// Cor seletiva
// origem : assets/effects/selective-color.xml
// id     : nova.effect.selectivecolor
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct selective_colorParams {
    float hue;
    float hueRange;
    float softness;
    float amount;
    int invert;
};

// --- funcoes auxiliares do efeito
// A mesma conversão RGB→HSV de `replace-color.xml`/`hsl-range-selection.xml`
// — provada ali, repetida aqui porque cada efeito deste catálogo é
// autocontido (sem import entre arquivos de shader).
float3 paraHsv(float3 c) {
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

fragment float4 fx_selective_color(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant selective_colorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 cor = inputImg.sample(__nv_smp, in.acScreenNorm);
    float3 hsv = paraHsv(clamp(cor.rgb, 0.0, 1.0));

    float alvoHue = u.hue / 360.0;
    float dh = abs(hsv.x - alvoHue);
    dh = min(dh, 1.0 - dh); // distância circular: 350° e 10° são vizinhos

    float faixaNorm = clamp(u.hueRange, 0.0, 180.0) / 360.0;
    float suave = max(u.softness, 0.001) * 0.5;
    float selecionado = 1.0 - smoothstep(faixaNorm - suave, faixaNorm + suave, dh);

    // Pixel quase sem saturação não tem matiz de verdade — sem isto, cinzas
    // e brancos cairiam pra fora da seleção por um motivo que o olho não
    // enxerga, e ficariam dessaturados por cima de algo que já é neutro.
    selecionado = mix(1.0, selecionado, smoothstep(0.0, 0.15, hsv.y));

    if (u.invert) selecionado = 1.0 - selecionado;

    float luma = dot(cor.rgb, float3(0.299, 0.587, 0.114));
    float3 dessaturado = mix(cor.rgb, float3(luma), u.amount);

    __nv_out = float4(mix(dessaturado, cor.rgb, selecionado), cor.a);
    return __nv_out;
}
