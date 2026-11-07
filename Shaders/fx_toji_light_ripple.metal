// ---------------------------------------------------------------------------
// Ripple Lighting
// origem : assets/effects/toji-light_ripple.xml
// id     : com.alightcreative.effects.ripplelighting
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_light_rippleParams {
    float speed;
    float frequency;
    float waveAmp;
    float lightIntensity;
    float lightSpread;
    float lightAngle;
    int autoRotate;
    float4 tint;
};

// --- funcoes auxiliares do efeito
precision float;

    // Calculate the height of the ripple at a given point
    static float getHeight(float2 p) {
        float dist = length(p);
        // A decaying sine wave expanding from the center
        float decay = smoothstep(1.0, 0.1, dist);
        return sin(dist * u.frequency - eng.acTime * u.speed) * u.waveAmp * decay;
    }

fragment float4 fx_toji_light_ripple(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_light_rippleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        // Normalized pixel coordinates (centered)
        float2 uv = (in.acScreenNorm.st - 0.5) * float2(eng.acScreenSize.x / eng.acScreenSize.y, 1.0);

        // 1. Surface Normals
        // We calculate the slope of the wave to determine how light bounces off it
        float eps = 0.002;
        float h = getHeight(uv);
        float h_x = getHeight(uv + float2(eps, 0.0));
        float h_y = getHeight(uv + float2(0.0, eps));
        
        // Construct normal vector from height gradients
        float3 normal = normalize(float3(h - h_x, h - h_y, eps));

        // 2. Lighting Setup
        float3 viewDir = normalize(float3(0.0, 0.0, 1.0));
        float3 col = float3(0.0); // Start with black background

        // Determine Light Angle based on controls
        float currentAngle = u.lightAngle;
        if (u.autoRotate) {
            currentAngle = eng.acTime * 0.3;
        }

        // Light 1
        // Calculate position based on currentAngle
        float3 lightPos1 = float3(cos(currentAngle) * u.lightSpread, sin(currentAngle) * u.lightSpread, 1.0);
        float3 lightDir1 = normalize(lightPos1 - float3(uv, 0.0));
        float3 halfDir1 = normalize(lightDir1 + viewDir);
        float spec1 = pow(max(dot(normal, halfDir1), 0.0), 80.0); // Sharp highlight
        
        // Light 2 (Opposite side)
        float3 lightPos2 = float3(-lightPos1.x, -lightPos1.y, 1.0);
        float3 lightDir2 = normalize(lightPos2 - float3(uv, 0.0));
        float3 halfDir2 = normalize(lightDir2 + viewDir);
        float spec2 = pow(max(dot(normal, halfDir2), 0.0), 80.0);

        // Combine lights
        col += (spec1 + spec2) * u.tint.rgb * u.lightIntensity;

        // 3. Post-Processing
        // Vignette to fade out the edges completely into black
        col *= smoothstep(0.8, 0.2, length(uv));
        
        // Gamma correction for smoother light falloff
        col = pow(col, float3(0.4545));

        __nv_out = float4(col, 1.0);
    return __nv_out;
}
