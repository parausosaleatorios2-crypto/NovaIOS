// ---------------------------------------------------------------------------
// Desfoque nas Bordas (Ultra Motion)
// origem : assets/effects/um-edge-blur.xml
// id     : nova.effect.ultramotion.edgeblur
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_edge_blurParams {
    float radius;
    float sens;
};

// --- funcoes auxiliares do efeito
const int N = 9;
const float OFF[9] = float[9](-4.0,-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0,4.0);
const float WT[9]  = float[9](0.028,0.070,0.133,0.196,0.228,0.196,0.133,0.070,0.028);
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

float sobel(sampler2D s, float2 uv, float2 tex) {
    float tl = dot(s.sample(__nv_smp, uv + float2(-tex.x,-tex.y)).rgb, LUMA);
    float t  = dot(s.sample(__nv_smp, uv + float2( 0.0, -tex.y)).rgb, LUMA);
    float tr = dot(s.sample(__nv_smp, uv + float2( tex.x,-tex.y)).rgb, LUMA);
    float l  = dot(s.sample(__nv_smp, uv + float2(-tex.x, 0.0 )).rgb, LUMA);
    float r  = dot(s.sample(__nv_smp, uv + float2( tex.x, 0.0 )).rgb, LUMA);
    float bl = dot(s.sample(__nv_smp, uv + float2(-tex.x, tex.y)).rgb, LUMA);
    float b  = dot(s.sample(__nv_smp, uv + float2( 0.0,  tex.y)).rgb, LUMA);
    float br = dot(s.sample(__nv_smp, uv + float2( tex.x, tex.y)).rgb, LUMA);
    float gx = -tl - 2.0*l - bl + tr + 2.0*r + br;
    float gy = -tl - 2.0*t - tr + bl + 2.0*b + br;
    return clamp(sqrt(gx*gx + gy*gy) * u.sens, 0.0, 1.0);
}

fragment float4 fx_um_edge_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_edge_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float edge = sobel(inputImg, in.acScreenNorm, eng.acTexelSize);
    if (u.radius <= 0.0 || edge <= 0.01) {
        __nv_out = (eng.acPass == 0) ? inputImg.sample(__nv_smp, in.acScreenNorm) : hblur.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }
    float2 d = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 passo = d * eng.acTexelSize * (u.radius * edge * eng.acEscalaDePixel);
    float4 soma = float4(0.0);
    float pesoTot = 0.0;
    for (int i = 0; i < N; i++) {
        float2 u = in.acScreenNorm + passo * OFF[i];
        float4 c = (eng.acPass == 0) ? inputImg.sample(__nv_smp, u) : hblur.sample(__nv_smp, u);
        soma += c * WT[i];
        pesoTot += WT[i];
    }
    __nv_out = soma / pesoTot;
    return __nv_out;
}
