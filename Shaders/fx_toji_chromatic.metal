// ---------------------------------------------------------------------------
// Chromatic Displacement
// origem : assets/effects/toji-chromatic.xml
// id     : com.alightcreative.effects.chromaticdisplacementsearch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_chromaticParams {
    float2 beamCenter;
    float beamWidth;
    float beamFeather;
    float dispDist;
    float angle;
    float beamIntensity;
};

// --- funcoes auxiliares do efeito
// Chromatic Displacement Search
        // Single-pass RGB displacement with soft-edged scanning beam

fragment float4 fx_toji_chromatic(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_chromaticParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm;

            // Beam mask (horizontal band by default)
            float2 d = uv - u.beamCenter;
            float halfW = u.beamWidth * 0.5;
            float mask = smoothstep(halfW + u.beamFeather, halfW - u.beamFeather, abs(d.x));
            float weight = mask * u.beamIntensity;

            // Displacement vector
            float2 offset = float2(cos(u.angle), sin(u.angle)) * u.dispDist * weight;

            // Sample shifted channels
            float4 colR = inputImg.sample(__nv_smp, uv + offset);
            float4 colG = inputImg.sample(__nv_smp, uv);
            float4 colB = inputImg.sample(__nv_smp, uv - offset);

            // Assemble RGB from displaced samples
            float4 displaced = float4(colR.r, colG.g, colB.b, colG.a);

            // Original sample
            float4 original = inputImg.sample(__nv_smp, uv);

            // Blend original and displaced inside the beam
            __nv_out = mix(original, displaced, weight);
    return __nv_out;
}
