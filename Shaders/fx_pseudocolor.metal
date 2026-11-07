// ---------------------------------------------------------------------------
// PseudoColor
// origem : assets/effects/pseudocolor.xml
// id     : nova.effect.pseudocolor
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct pseudocolorParams {
    float frequency;
    float hueShift;
    float saturation;
    float brightness;
    float scaleBySource;
    float scaleBySrcAmp;
    float mixWithSource;
};

fragment float4 fx_pseudocolor(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant pseudocolorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 fonte = inputImg.sample(__nv_smp, in.acScreenNorm);
    float v = dot(fonte.rgb, float3(0.3125, 0.5, 0.1875));
    float matiz = fract(u.frequency * v - u.hueShift);
    float3 p = clamp(abs(__nv_mod(matiz * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    float3 cor = u.saturation >= 0.0 ? 1.0 - u.saturation * (1.0 - p) : 1.0 + u.saturation * p;
    // Nada é cortado no caminho (medido com casos combinados): só o brilho da fonte e a saída.
    cor *= u.brightness * mix(1.0, clamp(v * u.scaleBySrcAmp, 0.0, 1.0), u.scaleBySource);
    __nv_out = float4(clamp(mix(cor, fonte.rgb, u.mixWithSource), 0.0, 1.0), fonte.a);
    return __nv_out;
}
