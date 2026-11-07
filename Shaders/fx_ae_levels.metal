// ---------------------------------------------------------------------------
// Levels (AE)
// origem : assets/effects/ae-levels.xml
// id     : nova.effect.aelevels
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_levelsParams {
    int channel;
    float inputBlack;
    float inputWhite;
    float gamma;
    float outputBlack;
    float outputWhite;
};

// --- funcoes auxiliares do efeito
float nivel(float x) {
    float faixa = u.inputWhite - u.inputBlack;
    float t = faixa != 0.0 ? clamp((x - u.inputBlack) / faixa, 0.0, 1.0) : (x >= u.inputBlack ? 1.0 : 0.0);
    t = u.gamma > 0.0 ? pow(t, 1.0 / u.gamma) : (t >= 1.0 ? 1.0 : 0.0);
    return clamp(u.outputBlack + (u.outputWhite - u.outputBlack) * t, 0.0, 1.0);
}

fragment float4 fx_ae_levels(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_levelsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float4 c = inputImg.read(uint2(int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0))), uint(0));
    if (u.channel == 0) c.rgb = float3(nivel(c.r), nivel(c.g), nivel(c.b));
    else if (u.channel == 1) c.r = nivel(c.r);
    else if (u.channel == 2) c.g = nivel(c.g);
    else if (u.channel == 3) c.b = nivel(c.b);
    else c.a = nivel(c.a);
    __nv_out = c;
    return __nv_out;
}
