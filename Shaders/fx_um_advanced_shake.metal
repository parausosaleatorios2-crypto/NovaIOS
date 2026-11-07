// ---------------------------------------------------------------------------
// Tremor Avançado (Ultra Motion)
// origem : assets/effects/um-advanced-shake.xml
// id     : nova.effect.ultramotion.advancedshake
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_advanced_shakeParams {
    float amount;
    float rate1;
    float rate2;
    float rot;
    float seed;
};

// --- funcoes auxiliares do efeito
float hash11(float x) { return fract(sin(x * 127.1) * 43758.5453); }

fragment float4 fx_um_advanced_shake(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_advanced_shakeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float t = eng.acTime + u.seed * 11.0;
    float a1 = hash11(floor(t * u.rate1)) * 2.0 - 1.0;
    float b1 = hash11(floor(t * u.rate1) + 7.3) * 2.0 - 1.0;
    float a2 = hash11(floor(t * u.rate2) + 3.1) * 2.0 - 1.0;
    float b2 = hash11(floor(t * u.rate2) + 9.7) * 2.0 - 1.0;

    float2 shift = float2(a1 + 0.4 * a2, b1 + 0.4 * b2) * u.amount;
    float ang = radians((a1 - b2) * u.rot);

    float2 p = in.acScreenNorm - float2(0.5);
    p.x *= eng.acAspect;
    float c = cos(ang), s = sin(ang);
    p = float2(p.x * c - p.y * s, p.x * s + p.y * c);
    p.x /= eng.acAspect;
    __nv_out = inputImg.sample(__nv_smp, p + float2(0.5) + shift);
    return __nv_out;
}
