// ---------------------------------------------------------------------------
// New Lensflare
// origem : assets/effects/toji-skexnxxnewlensflare.xml
// id     : com.alightcreative.effects.newlensflare
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxnewlensflareParams {
    float3 position;
    float progressc;
    float progressd;
    float progresse;
    float progressa;
    float progressb;
    float alpha;
    float4 color1;
    float4 color3;
    float4 color4;
    int blendMode;
};

// --- funcoes auxiliares do efeito
static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord
    
   /////////////////////////
   
        float rnd(float2 p)
      {
          float f = fract(sin(dot(p, float2(12.1234, 72.8392) )*45123.2));
       return f;   
      }
      
      float rnd(float w)
      {
          float f = fract(sin(w)*1000.);
       return f;   
      }
      
      float regShape(float2 p, int N)
      {
       float f;
          
          
      float a=__nv_atan(p.x, p.y)+.2;
      float b=6.28319/float(N);
      f=smoothstep(.5,.51, cos(floor(.5+a/b)*b-a)*length(p.xy));
          
          
          return f;
      }
      float3 circle(float2 p, float size, float decay, float3 color,float3 color2, float dist, float2 mouse)
      {
       	 
          
          //l is used for making rings.I get the length and pass it through a sinwave
          //but I also use a pow function. pow function + sin function , from 0 and up, = a pulse, at least
          //if you return the max of that and 0.0.
          
          float l = length(p + mouse*(dist*4.))+size/2.;
          
          //l2 is used in the rings as well...somehow...
          float l2 = length(p + mouse*(dist*4.))+size/3.;
          
          ///these are circles, big, rings, and  tiny respectively
          float c = max(00.01-pow(length(p + mouse*dist), size*1.4), 0.0)*50.;
          float c1 = max(0.001-pow(l-0.3, 1./40.)+sin(l*30.), 0.0)*3.;
          float c2 =  max(0.04/pow(length(p-mouse*dist/2. + 0.09)*1., 1.), 0.0)/20.;
          float s = max(00.01-pow(regShape(p*5. + mouse*dist*5. + 0.9, 6) , 1.), 0.0)*5.;
          
         	color = 0.5+0.5*sin(color);
          color = cos(float3(u.color1.rgb)*8. + dist*4.)*0.5+.5;
          // color = cos(float3(0.44, .24, .2)*8. + dist*4.)*0.5+.5;
       	float3 f = c*color ;
          f += c1*color;
          
          f += c2*color;  
          f +=  s*color;
          return f-0.01;
      }
      
      float sun(float2 p, float2 mouse)
      {
       float f;
          
          float2 sunp = p+mouse;
          float sun = 1.0-length(sunp)*0.0;
          return f;
      }

   
   /////////////////////////

fragment float4 fx_toji_skexnxxnewlensflare(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxnewlensflareParams&  u    [[buffer(1)]],
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

        syamjaidtz /= (u.position.z/100.0);
        // syamjaidtz *= rot2m((0.0+angle)*0.0174533);
        syamjaidtz += float2((230.0+u.position.x), (-130.0+u.position.y))*float2(-1.,1.)/500.;

        
        /////////////////////////
        
        // if(u.progressa <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); }
        // else if(u.progressa >= 0.0001) { 

    	float4 __nv_out;
    	
          float2 uv = syamjaidtz;
          //uv=uv*2.-1.0;
          uv.x*=eng.acScreenSize.x/eng.acScreenSize.y;
          
          float2 mm = uv;
          // float2 mm = mousee/syamjaidtz - 0.5;
          // mm.x *= mousee/syamjaidtz.y;
          
          // if(u.progressa<1.0)
          // {
           mm = float2(sin(u.progressc/6.)/1., cos(u.progressd/4.0)/2. )/2.;   
          // }
          float3 circColor = float3(0.9, 0.2, 0.1);
          float3 circColor2 = float3(0.3, 0.1, 0.9); //05
          
          //now to make the sky not black
          float3 color = mix(float3(u.color3.rgb)/0.9, float3(u.color4.rgb), uv.y)*u.progressb;
          // float3 color = mix(float3(0.3, 0.2, 0.02)/0.9, float3(0.2, 0.5, 0.8), uv.y)*u.progressb;
          // float3 color = mix(float3(0.3, 0.2, 0.02)/0.9, float3(0.2, 0.5, 0.8), uv.y)*3.-0.52*sin(u.progressb);
          
          //this calls the function which adds three circle types every time through the loop based on parameters I
          //got by trying things out. rnd i*2000. and rnd i*20 are just to help randomize things more
          for(float i=0.;i<10.;i++){
              color += circle(uv, pow(rnd(i*2000.)*u.progressa, 2.)+1.41, 0.0, circColor+i , circColor2+i, rnd(i*20.)*3.+0.2-.5, mm);
          }
          //get angle and length of the sun (uv - mouse)
            float a = __nv_atan(uv.y-mm.y, uv.x-mm.x); //19
          	float l = max(1.0-length(uv-mm)-0.84, 0.0);

          float bright = u.progresse;//+0.1/abs(sin(iTime/3.))/3.;//add 1.0ness based on how the sun moves so that it is 1.0est
          //when it is lined up with the center
          
          //add the sun with the frill things
          color += max(0.1/pow(length(uv-mm)*5., 5.), 0.0)*abs(sin(a*5.+cos(a*9.)))/20.;
          color += max(0.1/pow(length(uv-mm)*10., 1./20.), .0)+abs(sin(a*3.+cos(a*9.)))/8.*(abs(sin(a*9.)))/1.;
          //add another sun in the middle (to make it 1.0er)  with the20color I want, and 1.0 as the numerator.
          color += (max(bright/pow(length(uv-mm)*4., 1./2.), 0.0)*4.)*float3(0.2, 0.21, 0.3)*4.;
          // color += (max(bright/pow(length(uv-mm)*4., 1./2.), 0.0)*4.)*float3(color2.rgb)*4.;
             // * (0.5+.5*sin(float3(0.4, 0.2, 0.1) + float3(a*2., 00., a*3.)+1.3));
          	
          //multiply by the exponetial e^x ? of 1.0-length which kind of masks the 1.0ness more so that
          //there is a sharper roll of of the light decay from the sun. 
            color*= exp(1.0-length(uv-mm))/5.;
      	__nv_out = float4(color,1.0);

        
         	// const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            // float4 gradmap;
            // float luminance = dot(__nv_out.rgb, luminanceWeighting);
            // gradmap = mix(u.color1,color2,luminance)*__nv_out.a;
        
    	// float4 factorx = mix(__nv_out,gradmap,alphab);
    	float4 factor = mix(texColorX,__nv_out,u.alpha);

        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (factor * 1.0) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            factor *= 1.0;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            factor *= 1.0;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = resultfinal;
    	// }
    return __nv_out;
}
