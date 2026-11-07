// ---------------------------------------------------------------------------
// Brilho e contraste
// origem : assets/effects/brightness-contrast.xml
// id     : nova.effect.brightcontrast
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct brightness_contrastParams {
    float brightness;
    float contrast;
};

fragment float4 fx_brightness_contrast(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant brightness_contrastParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Contraste é uma escala em torno do cinza médio (0.5). Escalar em torno do
    // zero clarearia a imagem em vez de aumentar contraste — erro clássico.
    float3 rgb = (color.rgb - 0.5) * (u.contrast + 1.0) + 0.5;

    rgb += u.brightness;

    // O clamp evita que valores estourados virem NaN mais adiante na cadeia.
    __nv_out = float4(clamp(rgb, 0.0, 1.0), color.a);
    return __nv_out;
}
