// ---------------------------------------------------------------------------
// Chromatic VortexBlur
// origem : assets/effects/toji-chromatic-vortexblur.xml
// id     : com.alightcreative.effects.chromaticvortexblur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_chromatic_vortexblurParams {
    float2 centerPoint;
    float strength;
    float radius;
    float colorAberration;
    int centerChannel;
    int mode;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
      
        static float4 getBlurred(float channelStrength) {
          float2 texelSize = 1.0 / __nv_getTexSize(inputImg_info.size);
          float Radius = u.radius;
          float T = channelStrength;

          float2 UV = in.acScreenNorm;

          float2 CENTER = u.centerPoint*float2(-1,-1);

          float2 diff1 = eng.acLayerCenter-CENTER;
          diff1.y = eng.acScreenSize.y - diff1.y;
          float2 diff = diff1 /eng.acScreenSize;

          UV -= diff;
          float2 convRate = float2(1,1);
          if(eng.acScreenSize.y > eng.acScreenSize.x)
              convRate.y=(eng.acScreenSize.y/eng.acScreenSize.x);
          else
              convRate.x=(eng.acScreenSize.x/eng.acScreenSize.y);
          UV *= convRate;

          float Dist = length(UV);

          float4 color = float4(0.0);
          
          if ( Dist < Radius )
          {
              float speed = 0.0;
              float localPower = (Radius - Dist) / Radius;
              {
                float A = ( T <= 0.5 ) ? mix( 0.0, 1.0, T/0.5 ) : mix( 1.0, 0.0, (T-0.5)/0.5 );
                float Theta = localPower * localPower * A * 8.0 * 3.14159;
                float l = Dist * Theta;
                speed = abs(l/texelSize.x*10.0);
              }
              float nSamples = float(clamp(speed, 1.01, 2000.01));
              
              float2 v = UV/nSamples;
              float2 c = float2(0.0);
              float count = 0.0;
              for(float d = max(Radius - abs(u.strength)*localPower, Dist); d <= Radius; d += 1.0/nSamples) {
                  float Percent = (Radius - d) / Radius;
                  float2 cc = UV - c;
                  c += v;
                  float A = ( T <= 0.5 ) ? mix( 0.0, 1.0, T/0.5 ) : mix( 1.0, 0.0, (T-0.5)/0.5 );
                  float Theta = Percent * Percent * A * 8.0 * 3.14159;
                  float S = sin( Theta );
                  float C = cos( Theta );
                  float2 res = float2( dot(cc, float2(C, -S)), dot(cc, float2(S, C)) );
                  res /= convRate;
                  res += diff;
                  color += inputImg.sample(__nv_smp, res);
                  count += 1.0;
              }
              color /= count;
          }
          else {
              UV /= convRate;
              UV += diff;
              color = inputImg.sample(__nv_smp, UV);
          }
          return color;
        }

fragment float4 fx_toji_chromatic_vortexblur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_chromatic_vortexblurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

          
          float3 offset = float3(0.0);
          if( u.centerChannel==0 ) {
              offset = float3(0.0, -1.0, 1.0);
          } else if( u.centerChannel==1 ) {
              offset = float3(-1.0, 0.0, 1.0);
          } else {
              offset = float3(-1.0, 1.0, 0.0);
          }
          offset *= u.colorAberration;
          float4 redBlurred = getBlurred((1.0+offset.r)*u.strength);
          float4 greenBlurred = getBlurred((1.0+offset.g)*u.strength);
          float4 blueBlurred = getBlurred((1.0+offset.b)*u.strength);
          float4 outColor = float4(redBlurred.r,
                              greenBlurred.g,
                              blueBlurred.b,
                              (redBlurred.a+greenBlurred.a+blueBlurred.a)/3.0);
          float4 colorMid, colorLow, colorHigh;
          if( u.centerChannel==0 ) {
              colorMid = redBlurred;
              colorLow = greenBlurred;
              colorHigh = blueBlurred;
          } else if( u.centerChannel==1 ) {
              colorMid = greenBlurred;
              colorLow = redBlurred;
              colorHigh = blueBlurred;
          } else {
              colorMid = blueBlurred;
              colorLow = redBlurred;
              colorHigh = greenBlurred;
              offset = float3(-1.0, 1.0, 0.0);
          }
          if( u.mode==0 ) {
              __nv_out = outColor * colorMid.a;
          } else if( u.mode==1 ) {
              float4 r = float4(outColor.r, 0.0, 0.0, outColor.r);
              float4 g = float4(0.0, outColor.g, 0.0, outColor.g);
              float4 b = float4(0.0, 0.0, outColor.b, outColor.b);
              float4 m = (r + g + b) / 3.;
              float4 c = float4(0.0,0.0,0.0,0.0);
              float4 l = float4(dot(luminanceWeighting * colorMid.rgb, float3(1.0)));
              c = m + (c*(1.0-m.a));
              c = l + (c*(1.0-l.a));
              __nv_out = c;
          } else if( u.mode==2 ) {
              __nv_out = float4(outColor.rgb,colorMid.a);
          } else {
              __nv_out = outColor*((colorLow.a + colorMid.a + colorHigh.a)/3.);
          }
    return __nv_out;
}
