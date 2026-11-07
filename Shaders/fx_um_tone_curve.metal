// ---------------------------------------------------------------------------
// Curva de Tons (Ultra Motion)
// origem : assets/effects/um-tone-curve.xml
// id     : nova.effect.ultramotion.tonecurve
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_tone_curveParams {
    float blackLift;
    float whiteHold;
    float midShift;
    float contrast;
};

// --- funcoes auxiliares do efeito
float curva(float x) {
    float bk = u.blackLift;
    float wh = 1.0 + u.whiteHold;
    float y = (x - bk) / max(wh - bk, 1e-4);
    y = clamp(y, 0.0, 1.0);
    // Deslocamento dos médios em torno de 0.5
    y = pow(y, 1.0 - u.midShift);
    // Contraste em torno de 0.5
    y = clamp((y - 0.5) * u.contrast + 0.5, 0.0, 1.0);
    return y;
}

fragment float4 fx_um_tone_curve(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_tone_curveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
    __nv_out = float4(curva(c.r), curva(c.g), curva(c.b), c.a);
    return __nv_out;
}
