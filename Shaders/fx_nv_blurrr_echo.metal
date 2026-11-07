// ---------------------------------------------------------------------------
// Eco (Blurrr)
// origem : assets/effects/nv-blurrr-echo.xml
// id     : nova.effect.blurrr.echo
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_echoParams {
    float count;
    float deslocamento;
    float angle;
    float decay;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

fragment float4 fx_nv_blurrr_echo(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_echoParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 o = inputImg.sample(__nv_smp, in.acScreenNorm);
    int n = clamp(int(u.count), 1, 20);
    float a = u.angle * PI / 180.0;
    float2 d = float2(cos(a), sin(a));
    d.x /= max(eng.acAspect, 1e-4);

    float4 soma = o;
    float peso = 1.0;
    float w = 1.0;
    for (int i = 1; i <= 20; i++) {
        if (i > n) break;
        w *= u.decay;
        float2 uv = in.acScreenNorm - d * u.deslocamento * float(i);
        soma += inputImg.sample(__nv_smp, uv) * w;
        peso += w;
    }
    __nv_out = soma / peso;
    return __nv_out;
}
