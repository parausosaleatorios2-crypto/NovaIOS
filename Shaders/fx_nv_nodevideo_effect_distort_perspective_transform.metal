// ---------------------------------------------------------------------------
// Transformação de perspectiva (NV)
// origem : assets/effects/nv-nodevideo-effect-distort-perspective-transform.xml
// id     : nv.effect.nodevideo-effect-distort-perspective-transform
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_distort_perspective_transformParams {
    float2 point0;
    float2 point1;
    float2 point2;
    float2 point3;
};

// --- funcoes auxiliares do efeito
static float3 linear(float3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c));
}
static float3 srgb(float3 l) {
    l = clamp(l, 0.0, 1.0);
    return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l));
}
// O filtro linear do RT do Node: os 4 texels em luz linear, pré-multiplicados (Clamp nas bordas).
static float4 lerComoONode(sampler2D t, float2 uv) {
    int2 T = int2(int(t.get_width()), int(t.get_height()));
    float2 p = uv * float2(T) - 0.5;
    int2 i = int2(floor(p));
    float2 f = p - floor(p);
    float4 s = float4(0.0);
    for (int k = 0; k < 4; k++) {
        int2 o = int2(k & 1, k >> 1);
        float4 c = t.read(uint2(clamp(i + o, int2(0), T - 1)), uint(0));
        float w = (o.x == 1 ? f.x : 1.0 - f.x) * (o.y == 1 ? f.y : 1.0 - f.y);
        s += w * float4(linear(c.rgb) * c.a, c.a);
    }
    return s;
}
// Ponto do Nova → UV do Node (Y para cima).
static float2 doNode(float2 p) { return eng.acEntradaDePe == 1 ? p : float2(p.x, 1.0 - p.y); }

fragment float4 fx_nv_nodevideo_effect_distort_perspective_transform(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_distort_perspective_transformParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 p0 = doNode(u.point0), p1 = doNode(u.point1), p2 = doNode(u.point2), p3 = doNode(u.point3);
    // CalcHomographyMatrix, conta por conta.
    float sx = p0.x - p1.x - p2.x + p3.x;
    float sy = p0.y - p1.y - p2.y + p3.y;
    float a = (p1.x - p3.x) * (p2.y - p3.y);
    float b = (p2.x - p3.x) * (p1.y - p3.y);
    float g = (sx * (p1.y - p3.y) - (p1.x - p3.x) * sy) / (b - a);
    float h = (sx * (p2.y - p3.y) - (p2.x - p3.x) * sy) / (a - b);
    float3x3 H = float3x3(p2.x - p0.x + p2.x * g, p2.y - p0.y + p2.y * g, g,
                  p1.x - p0.x + p1.x * h, p1.y - p0.y + p1.y * h, h,
                  p0.x, p0.y, 1.0);
    if (abs(determinant(H)) < 1e-12) { __nv_out = float4(0.0); return __nv_out; }
    // O UV da tela no Node (Y para cima) e o lugar da camada nele.
    float2 q = eng.acEntradaDePe == 1 ? in.acScreenNorm : float2(in.acScreenNorm.x, 1.0 - in.acScreenNorm.y);
    float3 s = __nv_inverse(H) * float3(q, 1.0);
    float2 uv = s.xy / s.z;
    if (any(lessThan(uv, float2(0.0))) || any(greaterThan(uv, float2(1.0)))) { __nv_out = float4(0.0); return __nv_out; }
    if (eng.acEntradaDePe != 1) uv.y = 1.0 - uv.y;
    float4 c = lerComoONode(inputImg, uv);
    __nv_out = c.a > 1e-5 ? float4(srgb(c.rgb / c.a), c.a) : float4(0.0);
    return __nv_out;
}
