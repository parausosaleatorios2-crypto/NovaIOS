// ---------------------------------------------------------------------------
// Borda em Chamas (Ultra Motion)
// origem : assets/effects/um-fiery-border.xml
// id     : nova.effect.ultramotion.fieryborder
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_fiery_borderParams {
    float height;
    float speed;
    float intensity;
    float scale;
};

// --- funcoes auxiliares do efeito
static float hash21(float2 p) { p = fract(p * float2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
static float ruido(float2 p) {
    float2 i = floor(p), f = fract(p);
    float a = hash21(i), b = hash21(i + float2(1,0));
    float c = hash21(i + float2(0,1)), d = hash21(i + float2(1,1));
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
static float fbm(float2 p) {
    float v = 0.0; float a = 0.5;
    for (int i = 0; i < 4; i++) { v += a * ruido(p); p *= 2.0; a *= 0.5; }
    return v;
}
static float3 corDoFogo(float t) {
    float3 preto = float3(0.0);
    float3 vermelho = float3(1.0, 0.1, 0.0);
    float3 laranja = float3(1.0, 0.5, 0.0);
    float3 amarelo = float3(1.0, 0.95, 0.4);
    if (t < 0.33) return mix(preto, vermelho, t / 0.33);
    if (t < 0.66) return mix(vermelho, laranja, (t - 0.33) / 0.33);
    return mix(laranja, amarelo, clamp((t - 0.66) / 0.34, 0.0, 1.0));
}

fragment float4 fx_um_fiery_border(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_fiery_borderParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    // Distância à borda do alfa: procuramos o alfa num anel
    float dentro = orig.a;
    float fora = 0.0;
    const int R = 6;
    for (int y = -R; y <= R; y++) {
        for (int x = -R; x <= R; x++) {
            float2 off = float2(x, y) * eng.acTexelSize * 2.0;
            fora = max(fora, 1.0 - inputImg.sample(__nv_smp, in.acScreenNorm + off).a);
        }
    }
    float borda = dentro * fora;
    if (borda <= 0.0) { __nv_out = orig; return __nv_out; }

    float n = fbm(in.acScreenNorm * u.scale + float2(0.0, -eng.acTime * u.speed));
    float chama = clamp(borda * (0.3 + n), 0.0, 1.0) * u.intensity;
    chama *= smoothstep(0.0, u.height, borda);
    float3 fogo = corDoFogo(chama);
    __nv_out = float4(orig.rgb + fogo, orig.a);
    return __nv_out;
}
