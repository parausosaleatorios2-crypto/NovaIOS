// ---------------------------------------------------------------------------
// @am:string/effect_longshadow_name
// origem : assets/effects/toji-longshadow2.xml
// id     : com.alightcreative.effects.longshadow2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_longshadow2Params {
    float size;
    float angle;
    float4 color;
    float alpha;
    float solidity;
    float fill;
    float fade;
    int fadeType;
};

// --- funcoes auxiliares do efeito
static float projectAndClampDist(float2 a, float2 b) {
            return clamp(dot(a,b)/dot(b,b),0.0,1.0);
        }

fragment float4 fx_toji_longshadow2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_longshadow2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 texelSize = 1.0 / __nv_getTexSize(inputImg_info.size);
            float rad = u.angle * 0.0174533;
            float2 velocity = float2(cos(rad)*u.size,-sin(rad)*u.size);
            //velocity *= eng.acPreviewSize*texelSize;
            if( eng.acScreenSize.y > eng.acScreenSize.x ) {
                velocity.y *= eng.acScreenSize.x / eng.acScreenSize.y;
            } else {
                velocity.x *= eng.acScreenSize.y / eng.acScreenSize.x;
            }
            float speed = length(velocity / texelSize);
            int nSamples = int(clamp(speed, 1.01, 500.01));
            float maxAlpha = 0.0;
            float accumAlpha = 0.0;
            int minDist = nSamples;
            float4 baseColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            for(int i=1; i<nSamples; i++ ) {
                float2 offset = velocity * (float(i) / float(nSamples - 1));
                float2 sampleCoord = in.acScreenNorm.st-offset;
                float insideTexture = step(0.0,sampleCoord.x) * step(sampleCoord.x,1.0) * step(0.0,sampleCoord.y) * step(sampleCoord.y,1.0);
                float sampAlpha = inputImg.sample(__nv_smp, sampleCoord).a * insideTexture;
                maxAlpha = max(maxAlpha, sampAlpha);
                if( sampAlpha > 0.5 ) {
                    minDist = min(minDist,i);
                }
                float adjAlpha = sampAlpha*u.solidity*0.25;
                accumAlpha = adjAlpha + accumAlpha*(1.0-adjAlpha);
            }
            float resultAlpha = mix(accumAlpha,maxAlpha,u.solidity);
            float dist = 0.0;
            if( u.fadeType==0 ) {
                dist = float(minDist)/float(nSamples);
            } else if( u.fadeType==1 ) {
                dist = projectAndClampDist(in.acScreenNorm-eng.acLayerCenterNorm,velocity);
            } else if( u.fadeType==2 ) {
                dist = abs((in.acScreenNorm-eng.acLayerCenterNorm).x) / abs(velocity.x);
            } else if( u.fadeType==3 ) {
                dist = abs((in.acScreenNorm-eng.acLayerCenterNorm).y) / abs(velocity.y);
            }
            //__nv_out = mix(mix(u.color * u.alpha * (1.0-dist*u.fade) * resultAlpha, baseColor, baseColor.a * u.fill),float4(1.0,0.0,0.0,1.0),abs(sin(dist*25.0)));
            __nv_out = mix(u.color * u.alpha * (1.0-dist*u.fade) * resultAlpha, baseColor, baseColor.a * u.fill);
    return __nv_out;
}
