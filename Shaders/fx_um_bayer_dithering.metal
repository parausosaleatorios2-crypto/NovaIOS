// ---------------------------------------------------------------------------
// Dither Bayer (Ultra Motion)
// origem : assets/effects/um-bayer-dithering.xml
// id     : nova.effect.ultramotion.bayerdither
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_bayer_ditheringParams {
    float levels;
    float scale;
    float strength;
};

// --- funcoes auxiliares do efeito
const float BAYER4[16] = float[16](
     0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
    12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0,
     3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
    15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0
);

fragment float4 fx_um_bayer_dithering(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_bayer_ditheringParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 p = floor(in.acScreenNorm * eng.acResolution / u.scale);
    int ix = int(__nv_mod(p.x, 4.0));
    int iy = int(__nv_mod(p.y, 4.0));
    float t = BAYER4[iy * 4 + ix] - 0.5;
    float n = max(float(int(u.levels)) - 1.0, 1.0);
    float3 q = floor(c.rgb * n + t * u.strength + 0.5) / n;
    __nv_out = float4(q, c.a);
    return __nv_out;
}
