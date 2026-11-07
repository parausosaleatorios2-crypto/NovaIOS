// ---------------------------------------------------------------------------
// Motion Blur+
// origem : assets/effects/toji-skexnxxmoblurplus.xml
// id     : com.alightcreative.effects.moblurplus
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxmoblurplusParams {
    float tune;
    float2 PANGLE;
    float2 PSCALE;
    float samples;
    float shutter;
    float phase;
    int useHybrid;
    float hybridMix;
    float zoomMix;
    int usePos;
    int useScale;
    int useAngle;
};

fragment float4 fx_toji_skexnxxmoblurplus(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxmoblurplusParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Rotational blur length driven by angular velocity and u.shutter angle (AE-like)
            float angle = abs(eng.acAngularVelocity) * (u.shutter/360.0) * u.tune; // degrees
            float cx = u.PANGLE.x + eng.acLayerPivot.x/eng.acLayerSize.x;
            float cy = u.PANGLE.y - eng.acLayerPivot.y/eng.acLayerSize.y;
            float2 image_size = __nv_getTexSize(inputImg_info.size);
            float maxF = max(eng.acScreenSize.x, eng.acScreenSize.y);
            float2 texelSize = 1.0 / float2(maxF, maxF);
            float2 center = (float4(cx,cy,0.0,1.0) * eng.acLayerToScreen).xy;
            float2 v = in.acScreenNorm.st - center;
            v.y *= image_size.y / image_size.x;
            float r = length(v);
            float d = 6.283185*r;
            float l = d*angle/360.0;
            float a = angle * 0.0174533; // radians total
            float speed = l/texelSize.x;
            int nMax = int(u.samples + 1.5);
            int nSamples = int(clamp(speed, 1.01, float(nMax)+0.01));
            float4 accum = float4(0.0);
            float wsum = 0.0;
            for (int i = 0; i < nSamples; i++) {
                float t = (float(i)+0.5)/float(nSamples) - 0.5 + u.phase; // [-0.5..0.5] with u.phase bias
                t = clamp(t, -0.5, 0.5);
                float sampleAngle = t * a;
                float s = sin(sampleAngle);
                float c = cos(sampleAngle);
                float2x2 rot = float2x2(c, -s, s, c);
                float2 temp = v*rot;
                temp.y = temp.y * image_size.x / image_size.y;
                float w = 1.0 - abs(t*2.0); // tent weight for smoother average
                float4 col = inputImg.sample(__nv_smp, center + temp);
                accum += col * w;
                wsum += w;
            }
            float4 base = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            __nv_out = (accum + base) / (wsum + 1.0);
    return __nv_out;
}
