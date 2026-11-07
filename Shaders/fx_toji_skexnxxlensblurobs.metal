// ---------------------------------------------------------------------------
// BCC Lensblur
// origem : assets/effects/toji-skexnxxlensblurobs.xml
// id     : com.alightcreative.effects.lensblurobs
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxlensblurobsParams {
    float ITERATIONS;
    float progressa;
    float RADIUS;
    float bright;
    float alpha;
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
   
      #define GOLDEN_ANGLE 2.3999632
      
      float2x2 rot = float2x2(cos(GOLDEN_ANGLE), sin(GOLDEN_ANGLE), -sin(GOLDEN_ANGLE), cos(GOLDEN_ANGLE));
      
      //-------------------------------------------------------------------------------------------
      static float3 Bokeh(sampler2D tex, float2 uv, float radius)
      {
          float3 acc = float3(0), div = acc;
          float r = u.RADIUS;
          float2 vangle = float2(0.0,radius*.01 / sqrt(float(u.ITERATIONS)));
          
      	for (float j = 0.0; j < u.ITERATIONS; j++)
          {  
              r += 1. / r;
      	    vangle = rot * vangle;
              float3 col = tex.sample(__nv_smp, uv + (r-1.) * vangle).xyz; /// ... Sample the image
      		float3 bokeh = pow(col, float3(4));
      		acc += col * bokeh;
      		div += bokeh;
      	}
      	return acc / div;
      }

   
   /////////////////////////

fragment float4 fx_toji_skexnxxlensblurobs(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxlensblurobsParams&  u    [[buffer(1)]],
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
        syamjaidtz = in.acScreenNorm; 

    	float4 __nv_out;
    	
          float2 uv = syamjaidtz; //... with correct aspect ratio
          
          
      	float rad = .8 - .8*((u.progressa+0.15) * 6.283);

          if (0.0 >= 1.0)
          {
          	rad = (0.0/eng.acScreenSize.x)*3.0;
      
          }
          
           __nv_out = float4(Bokeh(inputImg, uv, rad), 1.0);

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
    	//
    return __nv_out;
}
