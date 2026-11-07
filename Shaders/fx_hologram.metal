// ---------------------------------------------------------------------------
// Holograma
// origem : assets/effects/hologram.xml
// id     : nova.effect.hologram
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct hologramParams {
    float4 hologramColor;
    float scanlineDensity;
    float scanlineStrength;
    float flickerStrength;
    float interferenceSpeed;
    float edgeStrength;
    float darken;
    float seed;
};

// --- funcoes auxiliares do efeito
float hash1(float x) {
    return fract(sin(x * 127.1 + float(u.seed) * 13.7) * 43758.5453);
}

/** Luminância ITU-R BT.709. */
float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

/** Sobel: magnitude do gradiente da luma. */
float sobelAqui(float2 uv) {
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

fragment float4 fx_hologram(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant hologramParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Monocromatiza o original pela luma e tinge na cor do holograma.
    float L = luma(original.rgb);
    float3 monocromado = u.hologramColor.rgb * L;

    // 1. Scanlines: linhas finas horizontais pela densidade.
    float scanline = 0.5 + 0.5 * sin(in.acScreenNorm.y * u.scanlineDensity);
    scanline = mix(1.0, scanline, u.scanlineStrength);
    monocromado *= scanline;

    // 2. Flicker: brilho global oscila.
    float quadro = floor(eng.acTime * 15.0);
    float pisca = 1.0 + (hash1(quadro) - 0.5) * u.flickerStrength * 2.0;
    monocromado *= pisca;

    // 3. Interferência: faixas horizontais largas correndo.
    float faixa = sin(in.acScreenNorm.y * 8.0 - eng.acTime * u.interferenceSpeed * 6.0);
    float peso = smoothstep(0.7, 1.0, faixa);
    monocromado *= mix(1.0, 1.4, peso);

    // 4. Borda viva: Sobel acrescenta brilho na silhueta.
    float borda = sobelAqui(in.acScreenNorm) * u.edgeStrength;
    monocromado += u.hologramColor.rgb * borda;

    // Fundo: o original escurecido (u.darken); soma com o holograma por cima.
    float3 fundo = mix(original.rgb, float3(0.0), u.darken);
    float3 cor = fundo + monocromado * u.hologramColor.a;
    cor = clamp(cor, 0.0, 1.0);

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
