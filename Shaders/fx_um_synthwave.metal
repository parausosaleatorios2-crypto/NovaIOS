// ---------------------------------------------------------------------------
// Retrô Synthwave (Ultra Motion)
// origem : assets/effects/um-synthwave.xml
// id     : nova.effect.ultramotion.synthwave
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_synthwaveParams {
    float density;
    float speed;
    float horizon;
    float intensity;
    float4 lineColor;
    float4 skyColor;
};

fragment float4 fx_um_synthwave(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_synthwaveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float3 fundo = orig.rgb;

    float y = in.acScreenNorm.y;
    float x = in.acScreenNorm.x;

    if (y < u.horizon) {
        // céu
        float grad = smoothstep(0.0, u.horizon, y);
        float3 ceu = mix(u.skyColor.rgb * 0.5, u.skyColor.rgb, grad);
        fundo = mix(fundo, ceu, (1.0 - orig.a) * u.skyColor.a);
    } else {
        // chão em perspectiva
        float z = (y - u.horizon) / (1.0 - u.horizon);
        float profundidade = 1.0 / max(z, 1e-3);
        float linhaY = fract((profundidade * 0.5) - eng.acTime * u.speed * 2.0);
        float lY = smoothstep(0.03, 0.0, abs(linhaY - 0.5) - 0.48);
        float linhaX = fract((x - 0.5) * u.density * profundidade * 0.25);
        float lX = smoothstep(0.03, 0.0, abs(linhaX - 0.5) - 0.48);
        float grid = max(lX, lY);
        float3 grade = mix(u.skyColor.rgb * 0.3, u.lineColor.rgb, grid * u.lineColor.a);
        fundo = mix(fundo, grade, (1.0 - orig.a) * u.intensity);
    }
    __nv_out = float4(fundo * (1.0 - orig.a) + orig.rgb * orig.a, max(orig.a, u.intensity * 0.5));
    return __nv_out;
}
