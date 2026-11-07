// ---------------------------------------------------------------------------
// Distorção de lente
// origem : assets/effects/lens-distortion.xml
// id     : nova.effect.lens-distortion
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct lens_distortionParams {
    float strength;
    float fine;
    float zoom;
    float4 edgeColor;
};

fragment float4 fx_lens_distortion(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant lens_distortionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 offset = (in.acScreenNorm - 0.5) * float2(eng.acAspect, 1.0) / max(u.zoom, 0.01);
    float radius2 = dot(offset, offset);

    float2 warped = offset * (1.0 + u.strength * radius2 + u.fine * radius2 * radius2);
    warped /= float2(eng.acAspect, 1.0);
    float2 sampleUv = warped + 0.5;

    // Sem esta verificação, o `clamp` esticaria o pixel da borda por toda a área
    // que sobrou — o que parece um borrão sujo em vez de uma imagem que acabou.
    if (sampleUv.x < 0.0 || sampleUv.x > 1.0 || sampleUv.y < 0.0 || sampleUv.y > 1.0) {
        __nv_out = u.edgeColor;
        return __nv_out;
    }

    __nv_out = inputImg.sample(__nv_smp, sampleUv);
    return __nv_out;
}
