// ---------------------------------------------------------------------------
// S_GlowAura
// origem : assets/effects/toji-s_glow_aura.xml
// id     : com.alightcreative.effects.s_glow_aura
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_s_glow_auraParams {
    float brightness;
    float threshold;
    float glowWidth;
    float frequency;
    float phaseSpeed;
    float twist;
    int followLayer;
    float blend;
};

// --- funcoes auxiliares do efeito
// S_GlowAura implementation for Alight Motion
        
        #define PI 3.14159265359

        float getLuma(float3 rgb) {
            return dot(rgb, float3(0.2126, 0.7152, 0.0722));
        }

        float3 auraPalette(float t) {
            // Base cycling colors
            float3 col = 0.5 + 0.5 * cos(6.28318 * (t + float3(0.0, 0.33, 0.67)));
            
            // Sharp interference bands
            float bands = sin(t * 15.0);
            col *= 0.8 + 0.4 * smoothstep(-0.2, 0.2, bands);
            
            return col;
        }

fragment float4 fx_toji_s_glow_aura(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_s_glow_auraParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 luv = in.acLayerNorm.xy;
            float2 suv = in.acScreenNorm.xy;
            
            float2 uv;
            float2 aspect;
            if(u.followLayer) {
                uv = luv;
                aspect = float2(eng.acLayerSize.x / eng.acLayerSize.y, 1.0);
            } else {
                uv = suv;
                aspect = float2(eng.acScreenSize.x / eng.acScreenSize.y, 1.0);
            }
            
            float2 p = (uv - 0.5) * aspect;
            
            float4 source = inputImg.sample(__nv_smp, uv);
            
            // 2. Generate Distance Influence
            float dist = 0.0;
            const int SAMPLES = 16;
            
            for(int i = 0; i < SAMPLES; i++) {
                float sampleAngle = float(i) * (2.0 * PI / float(SAMPLES));
                float2 sampleDir = float2(cos(sampleAngle), sin(sampleAngle));
                
                // Sampling offset corrected by aspect to keep it circular
                float2 offset = sampleDir * u.glowWidth * 0.1;
                offset.x /= aspect.x;
                
                float2 sampleUV = uv + offset;
                float sampleLuma = getLuma(inputImg.sample(__nv_smp, sampleUV).rgb);
                
                dist += smoothstep(u.threshold, 1.0, sampleLuma);
            }
            dist /= float(SAMPLES);

            // 3. Twist & Phase Calculation
            float angle = __nv_atan(p.y, p.x);
            float timePhase = eng.acTime * u.phaseSpeed;
            float auraMap = dist * u.frequency + (angle / PI) * u.twist + timePhase;
            
            // 4. Color Generation
            const float3 phaseRGB = float3(0.2, 0.1, 0.0);
            float3 auraCol = float3(
                auraPalette(auraMap + phaseRGB.r).r,
                auraPalette(auraMap + phaseRGB.g).g,
                auraPalette(auraMap + phaseRGB.b).b
            );
            
            // Fade aura based on distance
            float mask = smoothstep(0.0, 0.5, dist) * (1.0 - smoothstep(0.5, 1.2, dist));
            auraCol *= mask * u.brightness;

            // 5. Composite (Screen Blend)
            float3 result = 1.0 - (1.0 - source.rgb) * (1.0 - auraCol);
            
            // Keep text interior bright
            if(getLuma(source.rgb) > 0.8) result = source.rgb;

            float4 finalColor = float4(result, source.a);
            
            // Mixing based on u.blend parameter
            __nv_out = mix(source, finalColor, u.blend);
    return __nv_out;
}
