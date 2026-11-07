// ---------------------------------------------------------------------------
// Looks: HSL Colors
// origem : assets/effects/mblooks-hsl-colors.xml
// id     : nova.effect.mblooks.hslcolors
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct mblooks_hsl_colorsParams {
    float masterHue;
    float masterSat;
    float masterLum;
    float hueRed;
    float hueOrange;
    float hueYellow;
    float hueGreen;
    float hueCyan;
    float hueBlue;
    float huePurple;
    float hueMagenta;
    float satRed;
    float satOrange;
    float satYellow;
    float satGreen;
    float satCyan;
    float satBlue;
    float satPurple;
    float satMagenta;
    float lumRed;
    float lumOrange;
    float lumYellow;
    float lumGreen;
    float lumCyan;
    float lumBlue;
    float lumPurple;
    float lumMagenta;
};

fragment float4 fx_mblooks_hsl_colors(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant mblooks_hsl_colorsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
