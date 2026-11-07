// ---------------------------------------------------------------------------
// Plasma Wave
// origem : assets/effects/toji-skexnxxplasmawave.xml
// id     : com.alightcreative.plasmawave
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxplasmawaveParams {
    float4 color1;
    float AMOUNT;
    float2 position;
    float progressa;
    float scalex;
    float bright;
    float alpha;
    float angle;
    int blendMode;
};

// --- funcoes auxiliares do efeito
static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    static float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord
    
   /////////////////////////
   
       /* This work is protected under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
       * more information canbe found at:
       * https://creativecommons.org/licenses/by-nc-sa/3.0/deed.en_US
       */
      
      const float overallSpeed = 0.2;
      const float gridSmoothWidth = 0.015;
      const float axisWidth = 0.05;
      const float majorLineWidth = 0.025;
      const float minorLineWidth = 0.0125;
      const float majorLineFrequency = 5.0;
      const float minorLineFrequency = 1.0;
      const float4 gridColor = float4(0.5);
      const float scale = 5.0;
      // const float4 lineColor = float4(0.25, 0.5, 1.0, 1.0);
      const float minLineWidth = 0.02;
      const float maxLineWidth = 0.5;
      const float lineSpeed = 1.0 * overallSpeed;
      const float lineAmplitude = 1.0;
      const float lineFrequency = 0.2;
      const float warpSpeed = 0.2 * overallSpeed;
      const float warpFrequency = 0.5;
      const float warpAmplitude = 1.0;
      const float offsetFrequency = 0.5;
      const float offsetSpeed = 1.33 * overallSpeed;
      const float minOffsetSpread = 0.6;
      const float maxOffsetSpread = 2.0;
      // const int u.AMOUNT = 16;
      
      // const float4 bgColors = float4(0., 0., 0., 1);
      // const float4 bgColors = float4(lineColor - float4(0., 0., 0., 1.));
          // (
              // lineColor * 0.5,
              // lineColor - float4(0., 0., 0., 1.)
              // );
      
      #define drawCircle(pos, radius, coord) smoothstep(radius + gridSmoothWidth, radius, length(coord - (pos)))
      
      #define drawSmoothLine(pos, halfWidth, t) smoothstep(halfWidth, 0.0, abs(pos - (t)))
      
      #define drawCrispLine(pos, halfWidth, t) smoothstep(halfWidth + gridSmoothWidth, halfWidth, abs(pos - (t)))
      
      #define drawPeriodicLine(freq, width, t) drawCrispLine(freq / 2.0, width, abs(__nv_mod(t, freq) - (freq) / 2.0))
      
      static float drawGridLines(float axis)   
      {
          return   drawCrispLine(0.0, axisWidth, axis)
                 + drawPeriodicLine(majorLineFrequency, majorLineWidth, axis)
                 + drawPeriodicLine(minorLineFrequency, minorLineWidth, axis);
      }
      
      static float drawGrid(float2 space)
      {
          return min(1., drawGridLines(space.x)
                        +drawGridLines(space.y));
      }
      
      // probably can optimize w/ noise, but currently using fourier transform
      static float random(float t)
      {
          return (cos(t) + cos(t * 1.3 + 1.3) + cos(t * 1.4 + 1.4)) / 3.0;   
      }
      
      static float getPlasmaY(float x, float horizontalFade, float offset)   
      {
          return random(x * lineFrequency + u.progressa * lineSpeed) * horizontalFade * lineAmplitude + offset;
      }

   
   /////////////////////////

fragment float4 fx_toji_skexnxxplasmawave(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxplasmawaveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 syamjaidtz;
        // if (adaptive) { 
        // syamjaidtz = in.acScreenNorm; 
        // }
        // else { 
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
        // }

        syamjaidtz /= u.scalex;
        syamjaidtz *= rot2m((-175.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;

        
        /////////////////////////
        
        // if(u.progressa <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); }
        // else if(u.progressa >= 0.0001) { 

    	float4 __nv_out;
    	
          float2 uv = in.acScreenNorm;
          float2 space = syamjaidtz;
          // float2 space = (fragCoord - iResolution.xy / 2.0) / iResolution.x * 2.0 * scale;
          
          float horizontalFade = 1.0 - (cos(uv.x * 6.28) * 0.5 + 0.5);
          float verticalFade = 1.0 - (cos(uv.y * 6.28) * 0.5 + 0.5);
      
          // fun with nonlinear transformations! (wind / turbulence)
          space.y += random(space.x * warpFrequency + u.progressa * warpSpeed) * warpAmplitude * (0.5 + horizontalFade);
          space.x += random(space.y * warpFrequency + u.progressa * warpSpeed + 2.0) * warpAmplitude * horizontalFade;
          
          float4 lines = float4(0);
          
          for(float l = 0.0; l < u.AMOUNT; l++)
          {
              float normalizedLineIndex = float(l) / float(u.AMOUNT);
              float offsetTime = u.progressa * offsetSpeed;
              float offsetPosition = float(l) + space.x * offsetFrequency;
              float rand = random(offsetPosition + offsetTime) * 0.5 + 0.5;
              float halfWidth = mix(minLineWidth, maxLineWidth, rand * horizontalFade) / 2.0;
              float offset = random(offsetPosition + offsetTime * (1.0 + normalizedLineIndex)) * mix(minOffsetSpread, maxOffsetSpread, horizontalFade);
              float linePosition = getPlasmaY(space.x, horizontalFade, offset);
              float line = drawSmoothLine(linePosition, halfWidth, space.y) / 2.0 + drawCrispLine(linePosition, halfWidth * 0.15, space.y);
              
              float circleX = __nv_mod(float(l) + u.progressa * lineSpeed, 25.0) - 12.0;
              float2 circlePosition = float2(circleX, getPlasmaY(circleX, horizontalFade, offset));
              float circle = drawCircle(circlePosition, 0.01, space) * 4.0;
              
              
              line = line + circle;
              lines += line * float4(u.color1.rgb, 1.0) * rand;
          }
          
          __nv_out = float4(0.,0.,0.,1.);
          // __nv_out = mix(color2, color3, uv.x);
          __nv_out *= verticalFade;
          __nv_out.a = 1.0;
          // debug grid:
          //__nv_out = mix(__nv_out, gridColor, drawGrid(space));
          __nv_out += lines;

        
         	// const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            // float4 gradmap;
            // float luminance = dot(__nv_out.rgb, luminanceWeighting);
            // gradmap = mix(u.color1,color2,luminance)*__nv_out.a;
        
    	// float4 factorx = mix(__nv_out,gradmap,alphab);
    	float4 factor = mix(texColorX,__nv_out,u.alpha);

        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (factor * u.bright) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            factor *= u.bright;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = resultfinal;
    	// }
    return __nv_out;
}
