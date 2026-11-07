// ---------------------------------------------------------------------------
// @am:string/effect_glowscan_name
// origem : assets/effects/toji-glowscan.xml
// id     : com.alightcreative.effects.glowscan
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_glowscanParams {
    float threshold;
    float radius;
    float power;
    float strength;
    float4 fillColor;
    float blend;
    float fill;
    float alpha;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_toji_glowscan(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_glowscanParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& hblur_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            if( eng.acPass==0 ) {

                discard_fragment();
            } else {
                float4 baseColor =  hblur.sample(__nv_smp, in.acScreenNorm.st);
                float4 mainColor = inputImg.sample(__nv_smp, in.acScreenNorm.st) * u.fill;
                float luma = dot(baseColor.rgb, luminanceWeighting);
                float adjThreshold = u.threshold * (1.0 + u.radius) - u.radius;
                if(luma >= adjThreshold && luma <= adjThreshold + u.radius)
                {
                    float halfRadius = u.radius*0.5;
                    float linearPos = abs((luma - adjThreshold - halfRadius)/halfRadius);
                    float4 glow = pow(mix(baseColor, u.fillColor*luma, u.blend*0.99), float4(u.power) * pow(linearPos, 2.0));
                    mainColor = mix(mainColor, baseColor + glow, u.alpha);
                }
                __nv_out = mainColor;
            }
    return __nv_out;
}
