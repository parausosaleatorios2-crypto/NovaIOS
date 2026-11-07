// ---------------------------------------------------------------------------
// Scanline VHS (Ultra Motion)
// origem : assets/effects/um-vhs-scanline.xml
// id     : nova.effect.ultramotion.vhsscanline
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_vhs_scanlineParams {
    float lineDensity;
    float lineStrength;
    float rollSpeed;
    float chroma;
};

fragment float4 fx_um_vhs_scanline(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_vhs_scanlineParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float r = inputImg.sample(__nv_smp, in.acScreenNorm + float2(u.chroma, 0.0)).r;
    float g = inputImg.sample(__nv_smp, in.acScreenNorm).g;
    float b = inputImg.sample(__nv_smp, in.acScreenNorm - float2(u.chroma, 0.0)).b;
    float a = inputImg.sample(__nv_smp, in.acScreenNorm).a;
    float3 cor = float3(r, g, b);

    float linha = 0.5 + 0.5 * sin(in.acScreenNorm.y * u.lineDensity * 3.14159);
    cor *= 1.0 - u.lineStrength * (1.0 - linha);

    float barra = fract(in.acScreenNorm.y + eng.acTime * u.rollSpeed);
    float ganho = smoothstep(0.02, 0.0, abs(barra - 0.5) - 0.48);
    cor += ganho * 0.08;

    __nv_out = float4(cor, a);
    return __nv_out;
}
