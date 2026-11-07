// ---------------------------------------------------------------------------
// Dither Ordenado (Ultra Motion)
// origem : assets/effects/um-ordered-dither.xml
// id     : nova.effect.ultramotion.ordereddither
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_ordered_ditherParams {
    float scale;
    float brightness;
    float4 darkColor;
    float4 lightColor;
};

// --- funcoes auxiliares do efeito
const float BAYER8[64] = float[64](
     0.0, 32.0,  8.0, 40.0,  2.0, 34.0, 10.0, 42.0,
    48.0, 16.0, 56.0, 24.0, 50.0, 18.0, 58.0, 26.0,
    12.0, 44.0,  4.0, 36.0, 14.0, 46.0,  6.0, 38.0,
    60.0, 28.0, 52.0, 20.0, 62.0, 30.0, 54.0, 22.0,
     3.0, 35.0, 11.0, 43.0,  1.0, 33.0,  9.0, 41.0,
    51.0, 19.0, 59.0, 27.0, 49.0, 17.0, 57.0, 25.0,
    15.0, 47.0,  7.0, 39.0, 13.0, 45.0,  5.0, 37.0,
    63.0, 31.0, 55.0, 23.0, 61.0, 29.0, 53.0, 21.0
);
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_um_ordered_dither(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_ordered_ditherParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
    float l = clamp(dot(c.rgb, LUMA) + u.brightness, 0.0, 1.0);
    float2 p = floor(in.acScreenNorm * eng.acResolution / u.scale);
    int ix = int(__nv_mod(p.x, 8.0));
    int iy = int(__nv_mod(p.y, 8.0));
    float t = (BAYER8[iy * 8 + ix] + 0.5) / 64.0;
    float bit = step(t, l);
    float3 cor = mix(u.darkColor.rgb, u.lightColor.rgb, bit);
    __nv_out = float4(cor, c.a);
    return __nv_out;
}
