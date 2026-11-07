// ---------------------------------------------------------------------------
// Scanlines (Blurrr)
// origem : assets/effects/nv-blurrr-scanlines.xml
// id     : nova.effect.blurrr.scanlines
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_scanlinesParams {
    float count;
    float depth;
    float softness;
};

fragment float4 fx_nv_blurrr_scanlines(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_scanlinesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (u.softness > 0.0) {
        float4 s = float4(0.0);
        for (int i = -2; i <= 2; i++) {
            s += inputImg.sample(__nv_smp, in.acScreenNorm + float2(0.0, float(i)) * u.softness * 0.5);
        }
        c = s * 0.2;
    }
    float linha = sin(in.acScreenNorm.y * u.count * 3.14159);
    float mdl = mix(1.0 - u.depth, 1.0, 0.5 + 0.5 * linha);
    __nv_out = float4(c.rgb * mdl, c.a);
    return __nv_out;
}
