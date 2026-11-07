// ---------------------------------------------------------------------------
// S_Invert
// origem : assets/effects/sapphire-invert.xml
// id     : nova.effect.sinvert
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_invertParams {
    int invertLuma;
    int invertChroma;
    int invertRed;
    int invertGreen;
    int invertBlue;
    int invertAlpha;
    int remultByAlpha;
    float scaleLights;
    float4 tintLights;
    float4 tintDarks;
    float offsetDarks;
    float saturation;
};

// --- funcoes auxiliares do efeito
/** O croma de `x` em volta da luma do Sapphire, vezes `k` (medido: luma = (5 R + 8 G + 3 B) / 16). */
float3 croma(float3 x, float k) {
    float y = dot(x, float3(0.3125, 0.5, 0.1875));
    return y + (x - y) * k;
}

fragment float4 fx_sapphire_invert(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_invertParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float4 c = inputImg.read(uint2(int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0))), uint(0));
    float a = u.invertAlpha ? 1.0 - c.a : c.a;
    // Remult sem inverter o alfa: o "branco" de onde se subtrai é o alfa da fonte.
    float um = (u.remultByAlpha && !u.invertAlpha) ? c.a : 1.0;

    float3 x = croma(u.invertLuma ? um - c.rgb : c.rgb, u.invertChroma == u.invertLuma ? 1.0 : -1.0);
    if (u.invertRed) x.r = um - x.r;
    if (u.invertGreen) x.g = um - x.g;
    if (u.invertBlue) x.b = um - x.b;

    float3 claros = floor(u.tintLights.rgb * 255.0 + 0.5) / 255.0 * u.scaleLights;
    float3 escuros = floor(u.tintDarks.rgb * 255.0 + 0.5) / 255.0 + u.offsetDarks;
    float3 d = escuros + croma(x, u.saturation) * max(claros - escuros, float3(0.0));
    if (u.remultByAlpha && u.invertAlpha) d *= a;
    __nv_out = float4(clamp(d, 0.0, 1.0), a);
    return __nv_out;
}
