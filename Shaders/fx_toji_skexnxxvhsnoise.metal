// ---------------------------------------------------------------------------
// VHS Noise
// origem : assets/effects/toji-skexnxxvhsnoise.xml
// id     : com.alightcreative.effects.vhsnoise
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxvhsnoiseParams {
    float progress;
    float scale;
    float2 position;
    float2 stretch;
    float bright;
    float alpha;
    float4 color1;
    float4 color2;
    int blendMode;
};

// --- funcoes auxiliares do efeito
float4 newLayer( float4 a, float4 b) {
    return a * (1. - b.a) + b;
    }
    
    float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
          float hash11(float a)
        {
            return fract(53.156*sin(a*45.45))-.5;
        }
        float dispnoise(float a)
        {
            float a1 = hash11(floor(a)),a2=hash11(ceil(a));
            return .03*mix(a1,a2,pow(fract(a),8.));
        }
        float noise(float a)
        {
            float a1 = hash11(floor(a)),a2=hash11(ceil(a));
            return mix(a1+.5,a2+.5,pow(fract(a),50.));
        }
        
        float hash21(float2 a)
        {
            return fract(sin(dot(a,float2(12.9898,78.233))+u.progress)*43758.5453);
        }
        float perlin(float2 a)
        {
            a*=float2(100.,500.);
            float a1 = hash21(floor(a));
            float a2 = hash21(floor(a)+float2(1,0));
            float a3 = hash21(floor(a)+float2(0,1));
        	float a4 = hash21(ceil(a));
         	return pow(mix(mix(a1,a2,fract(a.x)),mix(a3,a4,fract(a.x)),fract(a.y)),2.);  
        }
        
        
        float4 grade(float4 color)
        {
         	color = pow(color,float4(2.2));
            color*= float4(1.3,.7,.89,1);
            
            color = pow(color,float4(.4));
            return 1.3*color;
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxvhsnoise(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxvhsnoiseParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> noisexx [[texture(0)]],
    texture2d<float> inputImg [[texture(1)]],
    constant NovaTexInfo& noisexx_info [[buffer(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float maxF = max(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 texelSize = 1.0 / float2(maxF, maxF);
        
        // float2 syamjaidtz;
        // syamjaidtz = in.acScreenNorm; 
        
        float2 syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y *=eng.acLayerSize.y/eng.acLayerSize.x;

        // syamjaidtz /= u.scale;
        // syamjaidtz *= rot2m((0.0+angle)*0.0174533);
        
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        syamjaidtz /= scaleVec;
        
        syamjaidtz += float2((-375.0+u.position.x), ((u.progress*50.0)+u.position.y))*float2(-1.,1.)/500.;
        
        // float cx = 0.5 + eng.acLayerPivot.x/eng.acLayerSize.x;
        // float cy = 0.5 - eng.acLayerPivot.y/eng.acLayerSize.y;
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 uv = syamjaidtz;
            // float2 uv = fragCoord.xy / iResolution.xy;
            float disp = dispnoise(.7*uv.y+__nv_mod(u.progress, 200.)*.2);
            uv.x+=disp;
            	if(hash11(floor(u.progress*4.)/4.)>.47)
        		uv.y+=.5*hash11(floor(u.progress*8.)/4.);
            uv =fract(uv);
            
            float4 color  = float4(0,0,0,1);
            // float4 color  = inputImg.sample(__nv_smp, uv);
        	
            color = grade(color);
             if(hash11(uv.y+floor((u.progress+uv.y)*16.)/16.)>.497)
                 color+=hash11(floor(100.*(uv.x-u.progress)))+.5;
         	color = mix(color,float4(.3),max(0.,sin(uv.y*20.)*perlin(.3*uv)*.5));
            
          
             __nv_out = color;
             if(abs(syamjaidtz.y)>eng.acScreenSize.y-50.*noise(5.*u.progress+(uv.y>.5?0.:10.)))
             // if(abs(2.*fragCoord.y-eng.acScreenSize.y)>eng.acScreenSize.y-50.*noise(5.*u.progress+(uv.y>.5?0.:10.)))
             __nv_out=float4(perlin(uv)+.5);
             
            const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float4 gradmap;
            float luminance = dot(__nv_out.rgb, luminanceWeighting);
            gradmap = mix(u.color1,u.color2,luminance)*__nv_out.a;

    	float4 factor = mix(texColorX,gradmap,1.0);

        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (factor * u.bright) * texColor.a;
            // resultfinal = (newLayer(texColor, factor) * u.bright) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            factor *= u.bright;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = mix(texColor, resultfinal, u.alpha);
    	//
    return __nv_out;
}
