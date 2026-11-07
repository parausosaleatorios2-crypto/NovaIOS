// ---------------------------------------------------------------------------
// Sway
// origem : assets/effects/toji-sway.xml
// id     : com.creative.sway_custom
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_swayParams {
    float speed;
    float frequency;
    float amplitude;
    float falloff;
    float angle;
};

// --- funcoes auxiliares do efeito
precision float;

fragment float4 fx_toji_sway(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_swayParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputLayer [[texture(0)]],
    constant NovaTexInfo& inputLayer_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acLayerNorm;
            
            // Calculate the intensity mask (stronger at bottom, 0 at top)
            float mask = pow(max(0.0, 1.0 - uv.y), u.falloff);
            
            // Generate wave offset
            float wave = sin(uv.y * u.frequency - eng.acTime * u.speed) * u.amplitude * mask;
            
            // Handle Angle (Directional offset)
            float rad = radians(u.angle);
            float2 direction = float2(cos(rad), sin(rad));
            
            float2 offset = direction * wave;
            
            float2 distortedUV = uv + offset;
            
            // Sample the input channel using the declared texture parameter
            __nv_out = inputLayer.sample(__nv_smp, distortedUV);
    return __nv_out;
}
