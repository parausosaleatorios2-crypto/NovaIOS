// ---------------------------------------------------------------------------
// Desfoque Bokeh (Ultra Motion)
// origem : assets/effects/um-bokeh-blur.xml
// id     : nova.effect.ultramotion.bokeh
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_bokeh_blurParams {
    float radius;
    float samples;
    float highlight;
    float threshold;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

// "fibonacci spiral" — amostras bem distribuídas num disco.

fragment float4 fx_um_bokeh_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_bokeh_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (u.radius <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); return __nv_out; }
    int n = clamp(int(u.samples), 6, 64);
    float phi = 2.39996323;

    float4 soma = float4(0.0);
    float pesoTot = 0.0;
    for (int i = 0; i <= 64; i++) {
        if (i > n) break;
        float t = float(i) / float(n);
        float r = sqrt(t) * u.radius;
        float a = float(i) * phi;
        float2 off = float2(cos(a), sin(a)) * r;
        off.x /= eng.acAspect;
        float4 c = inputImg.sample(__nv_smp, in.acScreenNorm + off);
        float luz = dot(c.rgb, LUMA);
        float k = smoothstep(u.threshold, u.threshold + 0.2, luz);
        c.rgb *= (1.0 + u.highlight * k);
        soma += c;
        pesoTot += 1.0;
    }
    __nv_out = soma / pesoTot;
    return __nv_out;
}
