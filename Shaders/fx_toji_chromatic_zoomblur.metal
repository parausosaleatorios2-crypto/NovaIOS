// ---------------------------------------------------------------------------
// @am:string/effect_chromatic_zoomblur_name
// origem : assets/effects/toji-chromatic-zoomblur.xml
// id     : com.alightcreative.effects.chromaticzoomblur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_chromatic_zoomblurParams {
    float2 centerPoint;
    float strength;
    int adaptive;
};

fragment float4 fx_toji_chromatic_zoomblur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_chromatic_zoomblurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

          float2 texelSize = 1.0 / __nv_getTexSize(inputImg_info.size);
          float2 center = float2(0.5 + u.centerPoint.x/500., 0.5 - u.centerPoint.y/500.);
          float2 v = in.acScreenNorm.st - (float4(center,0.0,1.0) * eng.acLayerToScreen).xy;
          float speed = length(u.strength / 2.0 / texelSize);
          if(u.adaptive)
              speed *= length( in.acLayerNorm.st - center );
          else
              speed *= smoothstep( 0.0, length(texelSize)*5.0, length( in.acLayerNorm.st - center ));
          int nSamples = int(clamp(speed, 7.01, 100.01));
          float4 outColor = float4(0.0);
          float2 vnorm = normalize(v)*texelSize*speed;
          float2 offsetScale = float2(1., 1.);
          if( eng.acScreenSize.y > eng.acScreenSize.x ) {
              offsetScale.x *= eng.acScreenSize.x / eng.acScreenSize.y;
          } else {
              offsetScale.y *= eng.acScreenSize.y / eng.acScreenSize.x;
          }
          
          float4 chromas[7];
          chromas[0] = float4(.2,0,0,1.0);
          chromas[1] = float4(.3,0,0,1.0);
          chromas[2] = float4(.5,.3333,0,1.0);
          chromas[3] = float4(0,.33333,0,1.0);
          chromas[4] = float4(0,.33333,.5,1.0);
          chromas[5] = float4(0,0,.3,1.0);
          chromas[6] = float4(0,0,.2,1.0);

          for(int i=0; i<nSamples; i++ ) {
              float2 offset = vnorm * (float(i) / float(nSamples) - 0.5);
              offset *= offsetScale;
              
              float c = min(float(i) * 7.0 / float(nSamples), 6.0);
              float fr = fract(c);
              int cidx = int(c);
              
              float4 chroma = mix(chromas[cidx], chromas[cidx+1], fr);

              outColor += inputImg.sample(__nv_smp, in.acScreenNorm.st-offset)*chroma;
          }
          outColor.a /= float(nSamples);
          outColor.rgb /= float(nSamples)/7.0;
          __nv_out = outColor;
    return __nv_out;
}
