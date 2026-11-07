// ---------------------------------------------------------------------------
// Desfoque Glitch (Blurrr)
// origem : assets/effects/nv-blurrr-glitch.xml
// id     : nova.effect.blurrr.glitch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_glitchParams {
    float sliceAmount;
    float sliceCount;
    float rgbSplit;
    float blurAmount;
    float samples;
    float seed;
};

// --- funcoes auxiliares do efeito
static float ruido(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

static float canalComRastro(float2 uv, float2 dir, float raio, int canal, int n) {
    float soma = 0.0;
    for (int i = 0; i <= 24; i++) {
        if (i > n) break;
        float t = float(i) / float(n) - 0.5;
        soma += inputImg.sample(__nv_smp, uv + dir * raio * t)[canal];
    }
    return soma / float(n + 1);
}

fragment float4 fx_nv_blurrr_glitch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_glitchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float linha = floor(in.acScreenNorm.y * u.sliceCount);
    float deslocamento = (ruido(float2(linha, u.seed + floor(eng.acTime * 8.0))) - 0.5) * 2.0 * u.sliceAmount;

    float2 uv = in.acScreenNorm + float2(deslocamento, 0.0);
    float2 dirRastro = float2(sign(deslocamento + 1e-5), 0.0);
    int n = clamp(int(u.samples), 2, 24);

    float r = canalComRastro(uv + float2( u.rgbSplit, 0.0), dirRastro, u.blurAmount, 0, n);
    float g = canalComRastro(uv,                           dirRastro, u.blurAmount, 1, n);
    float b = canalComRastro(uv + float2(-u.rgbSplit, 0.0), dirRastro, u.blurAmount, 2, n);

    __nv_out = float4(r, g, b, original.a);
    return __nv_out;
}
