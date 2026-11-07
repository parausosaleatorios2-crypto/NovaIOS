// ---------------------------------------------------------------------------
// S_dissolveshake
// origem : assets/effects/toji-s_dissolveshake.xml
// id     : com.alightcreative.effects.s_dissolveshake
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_s_dissolveshakeParams {
    float dissolvePercent;
    float dissolveSpeed;
    float amplitude;
    float frequency;
    float seed;
    int motionBlur;
    float mbLength;
    int wrapX;
    int wrapY;
    float xRandAmp;
    float xRandFreq;
    float xWaveAmp;
    float xWaveFreq;
    float xPhase;
    float yRandAmp;
    float yRandFreq;
    float yWaveAmp;
    float yWaveFreq;
    float yPhase;
    float zRandAmp;
    float zRandFreq;
    float zWaveAmp;
    float zWaveFreq;
    float zPhase;
    float tRandAmp;
    float tRandFreq;
    float tWaveAmp;
    float tWaveFreq;
    float tPhase;
};

// --- funcoes auxiliares do efeito
float rand(float2 co) {
        return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
    }

fragment float4 fx_toji_s_dissolveshake(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_s_dissolveshakeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        
        // Use floor(in.acScreenNorm * eng.acScreenSize) for per-pixel noise unaffected by zoom if needed, 
        // or just in.acScreenNorm for relative grain.
        float2 st = in.acScreenNorm;
        
        // Animate dissolve u.seed over time using u.dissolveSpeed
        float t = u.seed + eng.acTime * u.dissolveSpeed;
        
        // Large scale multiplier for noise to avoid patterns
        float r = rand(st * (1.0 + t * 0.1) + float2(t * 1.33, t * 0.77));
        
        // Dissolve alpha cutout
        float alpha = step(u.dissolvePercent, r);
        
        __nv_out = texColor * alpha;
    return __nv_out;
}
