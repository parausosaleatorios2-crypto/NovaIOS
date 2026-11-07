// ---------------------------------------------------------------------------
// Contorno neon
// origem : assets/effects/neon-outline.xml
// id     : nova.effect.neon-outline
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct neon_outlineParams {
    float4 tubeColor;
    float edgeStrength;
    float haloRadius;
    float haloStrength;
    float darken;
};

// --- funcoes auxiliares do efeito
const float TAU = 6.2831853;

/** Luminância ITU-R BT.709. */
float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

/** Sobel: magnitude do gradiente da luma com um kernel 3×3. */
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

fragment float4 fx_neon_outline(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant neon_outlineParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float borda = sobelAqui(in.acScreenNorm) * u.edgeStrength;
    borda = clamp(borda, 0.0, 1.0);

    // Halo: média do sobel em volta, num círculo de 8 amostras.
    float halo = 0.0;
    float2 px = 1.0 / float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    for (int i = 0; i < 8; i++) {
        float a = TAU * float(i) / 8.0;
        float2 d = float2(cos(a), sin(a)) * u.haloRadius * px;
        halo += sobelAqui(in.acScreenNorm + d) * u.edgeStrength;
    }
    halo = clamp(halo / 8.0, 0.0, 1.0) * u.haloStrength;

    float3 fundo = mix(original.rgb, float3(0.0), u.darken);
    float3 cor = fundo + u.tubeColor.rgb * (borda + halo);
    cor = clamp(cor, 0.0, 1.0);

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
