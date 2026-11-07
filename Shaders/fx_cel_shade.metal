// ---------------------------------------------------------------------------
// Cel-shade (anime)
// origem : assets/effects/cel-shade.xml
// id     : nova.effect.cel-shade
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct cel_shadeParams {
    float levels;
    float smoothness;
    float4 outlineColor;
    float outlineStrength;
    float outlineThreshold;
};

// --- funcoes auxiliares do efeito
/** Luminância ITU-R BT.709. */
static float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

/** RGB → HSV (padrão IQ). */
static float3 rgb2hsv(float3 c) {
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

/** HSV → RGB. */
static float3 hsv2rgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

/** Sobel: magnitude do gradiente da luma. */
static float sobelAqui(float2 uv) {
    float2 px = 1.0 / float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    float tl = luma(inputImg.sample(__nv_smp, uv + float2(-px.x,  px.y)).rgb);
    float t  = luma(inputImg.sample(__nv_smp, uv + float2( 0.0,   px.y)).rgb);
    float tr = luma(inputImg.sample(__nv_smp, uv + float2( px.x,  px.y)).rgb);
    float l  = luma(inputImg.sample(__nv_smp, uv + float2(-px.x,  0.0 )).rgb);
    float r  = luma(inputImg.sample(__nv_smp, uv + float2( px.x,  0.0 )).rgb);
    float bl = luma(inputImg.sample(__nv_smp, uv + float2(-px.x, -px.y)).rgb);
    float b  = luma(inputImg.sample(__nv_smp, uv + float2( 0.0,  -px.y)).rgb);
    float br = luma(inputImg.sample(__nv_smp, uv + float2( px.x, -px.y)).rgb);
    float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
    float gy = -tl - 2.0 * t - tr + bl + 2.0 * b + br;
    return length(float2(gx, gy));
}

/** Quantiza `v` em `n` patamares, com transição `suavidade`. */
static float patamares(float v, int n, float suavidade) {
    float escalado = v * float(n);
    float base = floor(escalado);
    float f = fract(escalado);
    float s = mix(step(0.5, f), smoothstep(0.5 - suavidade * 0.5, 0.5 + suavidade * 0.5, f), suavidade);
    return (base + s) / float(n);
}

fragment float4 fx_cel_shade(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant cel_shadeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    int n = clamp(int(u.levels + 0.5), 2, 10);

    // Quantiza em HSV (mantém matiz, chapa brilho e saturação).
    float3 hsv = rgb2hsv(original.rgb);
    hsv.y = patamares(hsv.y, n, u.smoothness);
    hsv.z = patamares(hsv.z, n, u.smoothness);
    float3 chapada = hsv2rgb(hsv);

    // Contorno: Sobel acima do limiar pinta por cima.
    float borda = sobelAqui(in.acScreenNorm) * u.outlineStrength;
    float traco = smoothstep(u.outlineThreshold, u.outlineThreshold + 0.1, borda);

    float3 cor = mix(chapada, u.outlineColor.rgb, traco * u.outlineColor.a);

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
