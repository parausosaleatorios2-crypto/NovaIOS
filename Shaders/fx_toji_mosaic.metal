// ---------------------------------------------------------------------------
// @am:string/effect_mosaic_name
// origem : assets/effects/toji-mosaic.xml
// id     : com.alightcreative.effects.mosaic
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_mosaicParams {
    float size;
    float2 phase;
};

fragment float4 fx_toji_mosaic(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_mosaicParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& hblur_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 tileSize = float2(u.size)/eng.acLayerSize;
            float2 adjPhase = float2(-u.phase.x,u.phase.y);

            if( eng.acPass==0 ) {

                float2 st = in.acLayerNorm.st;
                float2 texelSize = 1.0 / eng.acLayerSize.xy;

                st -= float2(.5,.5);
                st.x -= __nv_mod(st.x+adjPhase.x/eng.acLayerSize.x, tileSize.x);
                st += float2(.5,.5);
                //st.x += tileSize.x / 2.;

                float blur = (tileSize.x/texelSize.x)/2.;
                int nSamples = int(clamp(blur, 1.01, 100.01));

                float4 outColor = inputImg.sample(__nv_smp, (float4(st,0.,1.)*eng.acLayerToScreen).st);
                for(int i=1; i<nSamples; i++ ) {
                    float2 offset = float2(tileSize.x,0.) * (float(i) / float(nSamples - 1) - 0.5);
                    outColor += inputImg.sample(__nv_smp, (float4(st-offset,0.,1.)*eng.acLayerToScreen).st);
                }
                __nv_out = outColor/float(nSamples);

            } else {

                float2 st = in.acLayerNorm.st;
                float2 texelSize = 1.0 / eng.acLayerSize.xy;

                st -= float2(.5,.5);
                st.y -= __nv_mod(st.y+adjPhase.y/eng.acLayerSize.y, tileSize.y);
                st += float2(.5,.5);
                //st.y += tileSize.y / 2.;

                float blur = tileSize.y/texelSize.y;
                int nSamples = int(clamp(blur, 1.01, 100.01));

                float4 outColor = inputImg.sample(__nv_smp, (float4(st,0.,1.)*eng.acLayerToScreen).st);
                for(int i=1; i<nSamples; i++ ) {
                    float2 offset = float2(0.,tileSize.y) * (float(i) / float(nSamples - 1) - 0.5);
                    outColor += hblur.sample(__nv_smp, (float4(st-offset,0.,1.)*eng.acLayerToScreen).st);
                }
                __nv_out = outColor/float(nSamples);

            }
    return __nv_out;
}
