// ---------------------------------------------------------------------------
// fill
// origem : assets/effects/toji-fill.xml
// id     : com.alightcreative.effects.solid_color_wipe
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_fillParams {
    float4 fillColor;
    float alpha;
    int blendMode;
    float start;
    float end;
    float angle;
    float feather;
};

// --- funcoes auxiliares do efeito
// Solid Color Wipe
        // - Wipe in from u.start and u.end with u.feather, matching wipe2.xml math.
        // - Blend like solidcolor.xml with Normal/Multiply/Screen and opacity.

        float smoothstepRev(float edge0, float edge1, float x) {
            if(edge0 == edge1) return step(edge0, x);
            else return smoothstep(edge0, edge1, x);
        }

fragment float4 fx_toji_fill(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_fillParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm; // for sampling

            // Wipe mask following wipe2.xml conventions
            float adjStart = u.start;
            float adjEnd = u.end;
            float adjFeather = u.feather/100.0;
            float rad = u.angle * 0.0174533;
            float2 v = normalize(float2(cos(rad), -sin(rad)));
            float p = dot(in.acLayerNorm.st - float2(0.5, 0.5), v) + 0.5;
            float p0 = smoothstepRev(adjStart - adjFeather, adjStart, p);
            float p1 = 1.0 - smoothstepRev(adjEnd, adjEnd + adjFeather, p);
            float mask = clamp(p0 * p1, 0.0, 1.0);

            // Blend like solidcolor.xml
            float4 texColor = inputImg.sample(__nv_smp, uv);
            float4 result;
            if( u.blendMode==1 ) {
                result = float4((texColor.rgb/texColor.a) * u.fillColor.rgb, 1.0) * texColor.a;
            } else if( u.blendMode==2 ) {
                result = float4(1.0 - ((1.0 - (texColor.rgb/texColor.a)) * (1.0 - u.fillColor.rgb)), 1.0) * texColor.a;
            } else {
                result = float4(u.fillColor.rgb, 1.0) * texColor.a;
            }
            __nv_out = mix(texColor, result, u.alpha * mask);
    return __nv_out;
}
