// ---------------------------------------------------------------------------
// T_sharpen
// origem : assets/effects/toji-T_sharpen.xml
// id     : com.alightcreative.effects.moblurplus_swirlsharp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_T_sharpenParams {
    float tune;
    float samples;
    float shutter;
    float phase;
    float2 PANGLE;
    float swirlStrength;
    int useAngle;
    int usePos;
    int useScale;
};

fragment float4 fx_toji_T_sharpen(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_T_sharpenParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);
  
        // Static angle based on u.tune and u.shutter settings
        float angle = 0.3 * u.tune * (u.shutter / 360.0);
        float rad = radians(angle);  
        float2 imageSize = __nv_getTexSize(inputImg_info.size);  
        float maxF = max(eng.acScreenSize.x, eng.acScreenSize.y);  
        float2 texelSize = 1.0 / float2(maxF, maxF);  
        float2 center = (float4(u.PANGLE.x, u.PANGLE.y, 0.0, 1.0) * eng.acLayerToScreen).xy;  

        float2 uv = in.acScreenNorm.st;  
        float2 diff = uv - center;  
        diff.y *= imageSize.y / imageSize.x;  

        int nSamples = int(clamp(float(u.samples), 4.0, 512.0));  
        float4 accum = float4(0.0);  
        float wsum = 0.0;  

        for (int i = 0; i < nSamples; i++) {  
            float t = (float(i) + 0.5) / float(nSamples);  
            float bias = pow(t, 0.85);  
            float theta = bias * rad * (1.0 + u.swirlStrength * length(diff));  
            float s = sin(theta);  
            float c = cos(theta);  
            float2x2 rot = float2x2(c, -s, s, c);  
            float2 offset = rot * diff * (1.0 + u.swirlStrength * 0.15 * bias);  
            offset.y *= imageSize.x / imageSize.y;  

            float4 col = inputImg.sample(__nv_smp, center + offset);  
            float w = 1.0 - pow(abs(t - 0.5) * 2.0, 1.5);  
            accum += col * w;  
            wsum += w;  
        }  

        float4 base = inputImg.sample(__nv_smp, uv);  
        float4 result = mix(base, accum / wsum, clamp(angle * 0.03, 0.0, 1.0));  
        __nv_out = result;
    return __nv_out;
}
