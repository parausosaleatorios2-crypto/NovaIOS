// ---------------------------------------------------------------------------
// Optics Compensation (AE)
// origem : assets/effects/ae-optics-compensation.xml
// id     : nova.effect.aeoptics
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_optics_compensationParams {
    float fov;
    int reverse;
    int fovOrientation;
    float2 viewCenter;
};

// --- funcoes auxiliares do efeito
/** Um ponto da camada, pré-multiplicado; fora dela, transparente. */
static float4 ponto(int2 p, int2 T) {
    if (p.x < 0 || p.y < 0 || p.x >= T.x || p.y >= T.y) return float4(0.0);
    float4 c = inputImg.read(uint2(p), uint(0));
    return float4(c.rgb * c.a, c.a);
}

fragment float4 fx_ae_optics_compensation(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_optics_compensationParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float2 tam = float2(T);
    float2 pos = floor(min(in.acScreenNorm * tam, tam - 1.0)) + 0.5;
    float2 centro = u.viewCenter * tam;
    float2 d = pos - centro;

    float2 lido = pos;
    bool existe = true;
    float a = radians(clamp(u.fov, 0.0, 179.99));
    if (a > 0.0) {
        float meia = u.fovOrientation == 0 ? 0.5 * tam.x : (u.fovOrientation == 1 ? 0.5 * tam.y : 0.5 * length(tam));
        float f = meia / tan(0.5 * a);
        float u2 = dot(d, d) / (f * f);
        if (u.reverse) lido = centro + d / sqrt(1.0 + u2);
        else if (u2 < 1.0) lido = centro + d / sqrt(1.0 - u2);
        else existe = false;
    }
    if (!existe) { __nv_out = float4(0.0); return __nv_out; }

    // Bilinear na cor pré-multiplicada (medido: é como o AE lê).
    float2 q = lido - 0.5;
    int2 b = int2(floor(q));
    float2 t = q - float2(b);
    float4 c = mix(mix(ponto(b, T), ponto(b + int2(1, 0), T), t.x), mix(ponto(b + int2(0, 1), T), ponto(b + int2(1, 1), T), t.x), t.y);
    __nv_out = c.a > 0.0 ? float4(min(c.rgb / c.a, float3(1.0)), c.a) : float4(0.0);
    return __nv_out;
}
