// ---------------------------------------------------------------------------
// Detectar bordas
// origem : assets/effects/edge-detect.xml
// id     : nova.effect.edge-detect
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct edge_detectParams {
    float thickness;
    float gain;
    float4 lineColor;
    float4 fillColor;
};

// --- funcoes auxiliares do efeito
static float lumaAt(float2 uv) {
    return dot(inputImg.sample(__nv_smp, clamp(uv, 0.0, 1.0)).rgb, float3(0.299, 0.587, 0.114));
}

fragment float4 fx_edge_detect(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant edge_detectParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 texel = eng.acTexelSize * u.thickness * eng.acEscalaDePixel;

    float tl = lumaAt(in.acScreenNorm + float2(-texel.x, -texel.y));
    float tc = lumaAt(in.acScreenNorm + float2(     0.0, -texel.y));
    float tr = lumaAt(in.acScreenNorm + float2( texel.x, -texel.y));
    float ml = lumaAt(in.acScreenNorm + float2(-texel.x,      0.0));
    float mr = lumaAt(in.acScreenNorm + float2( texel.x,      0.0));
    float bl = lumaAt(in.acScreenNorm + float2(-texel.x,  texel.y));
    float bc = lumaAt(in.acScreenNorm + float2(     0.0,  texel.y));
    float br = lumaAt(in.acScreenNorm + float2( texel.x,  texel.y));

    float gx = (tr + 2.0 * mr + br) - (tl + 2.0 * ml + bl);
    float gy = (bl + 2.0 * bc + br) - (tl + 2.0 * tc + tr);

    float edge = clamp(sqrt(gx * gx + gy * gy) * u.gain, 0.0, 1.0);
    float3 drawn = mix(u.fillColor.rgb, u.lineColor.rgb, edge);

    __nv_out = float4(drawn, original.a);
    return __nv_out;
}
