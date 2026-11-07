// ---------------------------------------------------------------------------
// HDR Falso (Ultra Motion)
// origem : assets/effects/um-fake-hdr.xml
// id     : nova.effect.ultramotion.fakehdr
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_fake_hdrParams {
    float radius;
    float strength;
    float sat;
};

// --- funcoes auxiliares do efeito
const int N = 11;
const float OFF[11] = float[11](-5.0,-4.0,-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0,4.0,5.0);
const float WT[11]  = float[11](0.027,0.065,0.121,0.175,0.198,0.198,0.198,0.175,0.121,0.065,0.027);
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_um_fake_hdr(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_fake_hdrParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 d = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 passo = d * eng.acTexelSize * (u.radius * eng.acEscalaDePixel);
    float4 soma = float4(0.0);
    float pt = 0.0;
    for (int i = 0; i < N; i++) {
        float2 u = in.acScreenNorm + passo * OFF[i];
        float4 c = (eng.acPass == 0) ? inputImg.sample(__nv_smp, u) : hblur.sample(__nv_smp, u);
        soma += c * WT[i];
        pt += WT[i];
    }
    float4 base = soma / pt;
    if (eng.acPass == 0) { __nv_out = base; return __nv_out; }

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    // Divide pela "iluminação" para achatar e re-expande
    float3 lo = base.rgb + 1e-3;
    float3 detalhe = orig.rgb / lo;
    float3 reexp = pow(detalhe, float3(1.0 - 0.3 * u.strength)) * pow(lo, float3(0.7));
    reexp = mix(orig.rgb, reexp, u.strength);

    float l = dot(reexp, LUMA);
    reexp = mix(float3(l), reexp, u.sat);
    __nv_out = float4(reexp, orig.a);
    return __nv_out;
}
