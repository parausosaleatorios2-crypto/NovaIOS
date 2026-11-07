// ---------------------------------------------------------------------------
// Distorção de Calor (Blurrr)
// origem : assets/effects/nv-blurrr-heat.xml
// id     : nova.effect.blurrr.heat
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_heatParams {
    float amp;
    float freq;
    float speed;
    float blur;
};

// --- funcoes auxiliares do efeito
float hash(float2 p) { return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453); }
float noise(float2 p) {
    float2 i = floor(p); float2 f = fract(p);
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    float2 u = f*f*(3.0-2.0*f);
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

fragment float4 fx_nv_blurrr_heat(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_heatParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float t = eng.acTime * u.speed;
    float2 off = float2(
        noise(in.acScreenNorm * u.freq + float2(t, 0.0)) - 0.5,
        noise(in.acScreenNorm * u.freq + float2(0.0, t * 1.3)) - 0.5
    ) * 2.0 * u.amp;

    float2 uv = in.acScreenNorm + off;
    float4 s = float4(0.0);
    for (int i = -2; i <= 2; i++)
        s += inputImg.sample(__nv_smp, uv + float2(float(i), 0.0) * u.blur * 0.5);
    for (int i = -2; i <= 2; i++)
        s += inputImg.sample(__nv_smp, uv + float2(0.0, float(i)) * u.blur * 0.5);
    __nv_out = s / 10.0;
    return __nv_out;
}
