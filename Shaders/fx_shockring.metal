// ---------------------------------------------------------------------------
// YY ShockRing
// origem : assets/effects/shockring.xml
// id     : nova.effect.shockring
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct shockringParams {
    float2 center;
    float radius;
    float feather;
    float expansion;
    float opacity;
    float scatter;
    float4 color1;
    float4 color2;
    int suave;
    int blend;
};

// --- funcoes auxiliares do efeito
/** O ruído do Scatter, com o hash inteiro do plugin (0x45d9f3b) e o resto em C. */
float ruido(int x, int y, float semente) {
    uint s = uint(int(semente));
    uint h = uint(y) * uint(y) + s + uint(x);
    h = ((h >> 16u) ^ h) * 0x45d9f3bu;
    h = ((h >> 16u) ^ h) * 0x45d9f3bu;
    h = (h >> 16u) ^ h;
    // h % 512 com o sinal de int32 (truncado para zero, como em C).
    bool negativo = (h >> 31u) != 0u;
    uint modulo = (negativo ? (~h + 1u) : h) & 511u;
    int r = negativo ? -int(modulo) : int(modulo);
    return float(r - 256);
}

fragment float4 fx_shockring(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant shockringParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 fonte = inputImg.sample(__nv_smp, in.acScreenNorm);
    float esc = max(eng.acEscalaDePixel, 1e-4);
    int2 p = int2(floor(in.acScreenNorm * eng.acResolution));
    float2 c = u.center * eng.acResolution;
    float d = length(float2(p) - c);
    float R = u.radius * esc;
    float F = u.feather * esc;
    float ex = u.expansion / 100.0;

    float v = -2.0;
    if (R > d) {
        if (ex > 0.0) v = d / (ex * R) + 1.0 - 1.0 / ex;
    } else if (F > 0.0) {
        v = 1.0 - (d - R) / F;
    }
    if (u.scatter > 0.0) {
        v += ruido(p.x, p.y, u.scatter * u.scatter * 256.0) * u.scatter * 1e-6;
    }
    v = clamp(v, 0.0, 1.0);
    if (u.suave) v = (1.0 - cos(v * 3.14159265359)) * 0.5;
    float m = v * (u.opacity / 100.0);
    float3 cor = u.color2.rgb + (u.color1.rgb - u.color2.rgb) * m;

    float A = fonte.a;
    float4 o;
    if (u.blend == 0) {
        o = float4(cor, m);
    } else if (u.blend == 1 || u.blend == 2) {
        float a = 1.0 - (1.0 - m) * (1.0 - A);
        float k = a != 0.0 ? m / a : 0.0;
        float3 rgb = u.blend == 1
            ? cor * k + fonte.rgb * (1.0 - k)
            : min(k * (cor + A * fonte.rgb) + (1.0 - k) * fonte.rgb, float3(1.0));
        o = float4(rgb, a);
    } else {
        float3 t = fonte.rgb * A * cor * m;
        if (u.blend == 3) {
            o = float4(t, 1.0);
        } else {
            float a = max(t.r, max(t.g, t.b));
            o = a > 0.0 ? float4(t / a, a) : float4(0.0);
        }
    }
    __nv_out = o;
    return __nv_out;
}
