// ---------------------------------------------------------------------------
// Noise Reduction
// origem : assets/effects/toji-skexnxxdenoise.xml
// id     : com.alightcreative.effects.denoise
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxdenoiseParams {
    float SAMPLES;
    float PIXEL_MULTIPLIER;
    float alpha;
    float strength;
};

// --- funcoes auxiliares do efeito
float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord
    
   /////////////////////////
   
      // #define u.SAMPLES 80  // HIGHER = NICER = SLOWER
      #define DISTRIBUTION_BIAS 0.6 // between 0. and 1.
      // #define u.PIXEL_MULTIPLIER  1.5 // between 1. and 3. (keep low)
      #define INVERSE_HUE_TOLERANCE 20.0 // (2. - 30.)
      
      #define GOLDEN_ANGLE 2.3999632 //3PI-sqrt(5)PI
      
      #define pow(a,b) pow(max(a,0.),b) // @morimea
      
      float2x2 sample2D = float2x2(cos(GOLDEN_ANGLE),sin(GOLDEN_ANGLE),-sin(GOLDEN_ANGLE),cos(GOLDEN_ANGLE));
      
      float3 sirBirdDenoise(sampler2D imageTexture, in float2 uv, in float2 imageResolution) {
          
          float3 denoisedColor           = float3(0.);
          
          float sampleRadius     = sqrt(float(u.SAMPLES));
          // const float sampleRadius     = sqrt(float(u.SAMPLES));
          float sampleTrueRadius = 0.5/(sampleRadius*sampleRadius);
          // const float sampleTrueRadius = 0.5/(sampleRadius*sampleRadius);
          float2        samplePixel      = float2(1.0/imageResolution.x,1.0/imageResolution.y); 
          float3        sampleCenter     = imageTexture.sample(__nv_smp, uv).rgb;
          float3        sampleCenterNorm = normalize(sampleCenter);
          float       sampleCenterSat  = length(sampleCenter);
          
          float  influenceSum = 0.0;
          float brightnessSum = 0.0;
          
          float2 pixelRotated = float2(0.,1.);
          
          for (float x = 0.0; x <= float(u.SAMPLES); x++) {
              
              pixelRotated *= sample2D;
              
              float2  pixelOffset    = u.PIXEL_MULTIPLIER*pixelRotated*sqrt(x)*0.5;
              float pixelInfluence = 1.0-sampleTrueRadius*pow(dot(pixelOffset,pixelOffset),DISTRIBUTION_BIAS);
              pixelOffset *= samplePixel;
                  
              float3 thisDenoisedColor = 
                  imageTexture.sample(__nv_smp, uv + pixelOffset).rgb;
      
              pixelInfluence      *= pixelInfluence*pixelInfluence;
              /*
                  HUE + SATURATION FILTER
              */
              pixelInfluence      *=   
                  pow(0.5+0.5*dot(sampleCenterNorm,normalize(thisDenoisedColor)),INVERSE_HUE_TOLERANCE)
                  * pow(1.0 - abs(length(thisDenoisedColor)-length(sampleCenterSat)),8.);
                  
              influenceSum += pixelInfluence;
              denoisedColor += thisDenoisedColor*pixelInfluence;
          }
          
          return denoisedColor/influenceSum;
          
      }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxdenoise(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxdenoiseParams&  u    [[buffer(1)]],
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
        syamjaidtz = in.acScreenNorm; 
        // }
        // else { 
        // syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        // syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
        // }

    	float4 __nv_out;
    	
          float2 uv = syamjaidtz;
          // float2 uv = fragCoord/iResolution.xy;
          
          const float2 iChannel0Resolution = float2(512, 512);
          
          float3 col = sirBirdDenoise(inputImg, uv, iChannel0Resolution).rgb;
      
          __nv_out = float4(col,1.0);
            
    	__nv_out = mix(texColor,__nv_out,u.alpha) * texColor.a;
    	//
    return __nv_out;
}
