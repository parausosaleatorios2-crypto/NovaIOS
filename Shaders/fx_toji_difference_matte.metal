// ---------------------------------------------------------------------------
// @am:string/effect_diffmatte_name
// origem : assets/effects/toji-difference-matte.xml
// id     : com.alightcreative.effects.differencematte
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_difference_matteParams {
    float threshold;
    float feather;
    float density;
    float offset;
    int mode;
    int sampling;
};

fragment float4 fx_toji_difference_matte(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_difference_matteParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 texelSize = 1.0 / __nv_getTexSize(inputImg_info.size);
            //float4 fg = inputImg.sample(__nv_smp, in.acScreenNorm);
            //float4 bg = comp.sample(__nv_smp, in.acScreenNorm);
            //float diff = length(fg.rgb - bg.rgb) * fg.a;

            float lowCutoff = u.threshold-(u.threshold*u.feather);
            float hiCutoff = u.threshold;
            float range = hiCutoff - lowCutoff;

            float pLeft = 0.0;
            float pRight = 0.0;
            float pUp = 0.0;
            float pDown = 0.0;


            float2 velocity;

            // ------- HORIZONTAL ---------------------------------------------------------------
            velocity = float2(0.1,0.0) * u.density;
            velocity *= eng.acPreviewSize*texelSize;
            velocity.x *= eng.acScreenSize.y / eng.acScreenSize.x;
            float speed = length(velocity / texelSize);
            int nSamples = int(clamp(speed, 1.01, 30.01));

            // RIGHT
            for(int i=1; i<nSamples; i++ ) {
                float2 u.offset = velocity * (float(i) / float(nSamples - 1) /*- 0.5*/ );
                float2 sampleCoord;

                sampleCoord = in.acScreenNorm.st+u.offset;
                float insideTexture = step(0.0,sampleCoord.x) * step(sampleCoord.x,1.0) * step(0.0,sampleCoord.y) * step(sampleCoord.y,1.0);
                //float4 samp = inputImg.sample(__nv_smp, sampleCoord) * insideTexture;

                float4 fg = inputImg.sample(__nv_smp, sampleCoord) * insideTexture;;
                float4 bg = comp.sample(__nv_smp, sampleCoord);
                float diff = length(fg.rgb - bg.rgb) * fg.a;

                float t;
                if( u.sampling == 0 ) {
                    t = clamp((diff - lowCutoff)/range,0.0,1.0);
                } else {
                    t = smoothstep(lowCutoff,hiCutoff,diff);
                }

                pRight = max(pRight, t);

            }


            // LEFT
            for(int i=1; i<nSamples; i++ ) {
                float2 u.offset = velocity * (float(i) / float(nSamples - 1) /*- 0.5*/ );
                float2 sampleCoord;

                sampleCoord = in.acScreenNorm.st-u.offset;
                float insideTexture = step(0.0,sampleCoord.x) * step(sampleCoord.x,1.0) * step(0.0,sampleCoord.y) * step(sampleCoord.y,1.0);
                //float4 samp = inputImg.sample(__nv_smp, sampleCoord) * insideTexture;

                float4 fg = inputImg.sample(__nv_smp, sampleCoord) * insideTexture;;
                float4 bg = comp.sample(__nv_smp, sampleCoord);
                float diff = length(fg.rgb - bg.rgb) * fg.a;

                float t;
                if( u.sampling == 0 ) {
                    t = clamp((diff - lowCutoff)/range,0.0,1.0);
                } else {
                    t = smoothstep(lowCutoff,hiCutoff,diff);
                }

                pLeft = max(pLeft, t);

            }

            // ------- VERTICAL ---------------------------------------------------------------
            velocity = float2(0.0,0.1) * u.density;
            velocity *= eng.acPreviewSize * texelSize;
            velocity.x *= eng.acScreenSize.y / eng.acScreenSize.x;
            speed = length(velocity / texelSize);
            nSamples = int(clamp(speed, 1.01, 30.01));

            // UP
            for(int i=1; i<nSamples; i++ ) {
                float2 u.offset = velocity * (float(i) / float(nSamples - 1) /*- 0.5*/ );
                float2 sampleCoord;

                sampleCoord = in.acScreenNorm.st+u.offset;
                float insideTexture = step(0.0,sampleCoord.x) * step(sampleCoord.x,1.0) * step(0.0,sampleCoord.y) * step(sampleCoord.y,1.0);
                //float4 samp = inputImg.sample(__nv_smp, sampleCoord) * insideTexture;

                float4 fg = inputImg.sample(__nv_smp, sampleCoord) * insideTexture;;
                float4 bg = comp.sample(__nv_smp, sampleCoord);
                float diff = length(fg.rgb - bg.rgb) * fg.a;

                float t;
                if( u.sampling == 0 ) {
                    t = clamp((diff - lowCutoff)/range,0.0,1.0);
                } else {
                    t = smoothstep(lowCutoff,hiCutoff,diff);
                }

                pUp = max(pUp, t);

            }


            // DOWN
            for(int i=1; i<nSamples; i++ ) {
                float2 u.offset = velocity * (float(i) / float(nSamples - 1) /*- 0.5*/ );
                float2 sampleCoord;

                sampleCoord = in.acScreenNorm.st-u.offset;
                float insideTexture = step(0.0,sampleCoord.x) * step(sampleCoord.x,1.0) * step(0.0,sampleCoord.y) * step(sampleCoord.y,1.0);
                //float4 samp = inputImg.sample(__nv_smp, sampleCoord) * insideTexture;

                float4 fg = inputImg.sample(__nv_smp, sampleCoord) * insideTexture;;
                float4 bg = comp.sample(__nv_smp, sampleCoord);
                float diff = length(fg.rgb - bg.rgb) * fg.a;

                float t;
                if( u.sampling == 0 ) {
                    t = clamp((diff - lowCutoff)/range,0.0,1.0);
                } else {
                    t = smoothstep(lowCutoff,hiCutoff,diff);
                }

                pDown = max(pDown, t);

            }

            float p = max(min(pLeft,pRight), min(pUp,pDown));

            float4 fg = inputImg.sample(__nv_smp, in.acScreenNorm);
            if( u.density < 0.0001 ) {
                float4 bg = comp.sample(__nv_smp, in.acScreenNorm);
                float diff = length(fg.rgb - bg.rgb) * fg.a;
                if( u.sampling == 0 ) {
                    p = clamp((diff - lowCutoff)/range,0.0,1.0);
                } else {
                    p = smoothstep(lowCutoff,hiCutoff,diff);
                }
            }

            if( p < u.offset ) p = 0.0;

            if( u.mode==0 ) {
                __nv_out = fg * p;
            } else if( u.mode==1 ) {
                __nv_out = float4(p,p,p,1.0) * fg.a;
            } else if( u.mode==2 ) {
                __nv_out = float4(pLeft,pUp,pRight,1.0) * fg.a;
            } else {
                __nv_out = float4(p,p,p,1.0) * fg.a;
            }
    return __nv_out;
}
