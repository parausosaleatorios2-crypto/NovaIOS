// ---------------------------------------------------------------------------
// Warp Waves 2
// origem : assets/effects/toji-s_warp_waves2.xml
// id     : com.alightcreative.effects.s_warp_waves2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_s_warp_waves2Params {
    float aAmplitude;
    float aFrequency;
    float aAngle;
    float aDisplaceAngle;
    float aPhaseStart;
    float aPhaseSpeed;
    float bAmplitude;
    float bFrequency;
    float bAngle;
    float bDisplaceAngle;
    float bPhaseStart;
    float bPhaseSpeed;
    float zDist;
    float wrapMode;
    int followLayer;
    float blend;
};

// --- funcoes auxiliares do efeito
// S_WarpWaves2 implementation for Alight Motion
        
        #define PI 3.14159265359

        static float2 applyWrap(float2 uv, int mode) {
            if (mode == 1) return fract(uv); 
            if (mode == 2) return abs(__nv_mod(uv - 1.0, 2.0) - 1.0); 
            return uv;
        }

        static float2 getWaveOffset(float2 p, float amp, float freq, float angle, float dispAngle, float pStart, float pSpeed, float time, float aspect) {
            float rad = angle * (PI / 180.0);
            float dispRad = dispAngle * (PI / 180.0);
            
            float2 waveDir = float2(cos(rad), sin(rad));
            float2 dispDir = float2(cos(rad + dispRad), sin(rad + dispRad));
            
            float2 pCorrected = p;
            pCorrected.x *= aspect;
            
            float phase = dot(pCorrected, waveDir) * freq + pStart + time * pSpeed;
            
            return dispDir * sin(phase) * amp;
        }

fragment float4 fx_toji_s_warp_waves2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_s_warp_waves2Params&  u    [[buffer(1)]],
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
            
            // 2. Apply Z Dist (Zoom) from center
            float2 p = (uv - 0.5) * u.zDist + 0.5;
            
            // 3. Calculate Displacement from Waves A and B
            float2 offsetA = getWaveOffset(p, u.aAmplitude, u.aFrequency, u.aAngle, u.aDisplaceAngle, u.aPhaseStart, u.aPhaseSpeed, eng.acTime, aspect.x);
            float2 offsetB = getWaveOffset(p, u.bAmplitude, u.bFrequency, u.bAngle, u.bDisplaceAngle, u.bPhaseStart, u.bPhaseSpeed, eng.acTime, aspect.x);
            
            // 4. Combine Warps
            // Offsets calculated in aspect-corrected space, divide X by aspect before adding to UV
            float2 totalOffset = offsetA + offsetB;
            totalOffset.x /= aspect.x;
            
            float2 warpedUV = p + totalOffset;
            
            // 5. Apply Wrap and Sample
            warpedUV = applyWrap(warpedUV, int(u.wrapMode));
            float4 color = inputImg.sample(__nv_smp, warpedUV);
            
            float4 base = inputImg.sample(__nv_smp, suv);
            __nv_out = mix(base, color, u.blend);
    return __nv_out;
}
