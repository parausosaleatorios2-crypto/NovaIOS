// ---------------------------------------------------------------------------
// TV Analogue
// origem : assets/effects/toji-skexnxxtvanalogue.xml
// id     : com.alightcreative.effects.tvanalogue
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxtvanalogueParams {
    float2 position;
    float progressa;
    float scale;
    float bright;
    float alpha;
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
   
           float hash( float2 p )
        {
        	float h = dot(p + u.progressa * 0.0001,float2(127.1,311.7));
            return fract(sin(h)*43758.5453123);
        }
        float hash2( float2 p )
        {
        	float h = dot(p ,float2(127.1,311.7));
            return fract(sin(h)*43758.5453123);
        }
        
        float noise( in float2 p )
        {
            float2 i = floor( p );
            float2 f = fract( p );
            	
        	float2 u = f*f*(3.0-2.0*f);
        
            return mix( mix( hash( i + float2(0.0,0.0) ), 
                             hash( i + float2(1.0,0.0) ), u.x),
                        mix( hash( i + float2(0.0,1.0) ), 
                             hash( i + float2(1.0,1.0) ), u.x), u.y);
        }

   
   /////////////////////////

fragment float4 fx_toji_skexnxxtvanalogue(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxtvanalogueParams&  u    [[buffer(1)]],
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

        syamjaidtz /= u.scale;
        // syamjaidtz *= rot2m((0.0+angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;

        
        /////////////////////////
        
        if(u.progressa <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); }
        else if(u.progressa >= 0.0001) { 

    	float4 __nv_out;
    	
    	      float2 uv = syamjaidtz;
            
            float glitch = hash2(floor(u.progressa * 4.0 - uv * 20.0) / 20.0);
            uv += pow(fract(glitch + u.progressa * 0.1), 30.0);
            
            float n = pow((noise(uv * 150.0) + noise(uv * 350.0)) * 0.5, 3.0);
            n *= abs(sin(uv.y * 250.0 + u.progressa * 2.0));
            float offset = sign(sin(uv.x * 6.0 + u.progressa * 3.0)) * 0.1;
            offset += sign(sin(uv.y * 10.0 + uv.x * 14.5 + u.progressa * 20.0)) * 0.1;
            offset += sign(sin(sin(u.progressa) * uv.y * 12.0 - uv.x * 22.0 - u.progressa * 40.0)) * 0.2;
            offset = pow(offset - 0.5, 4.0);
                
            n *= min(1.0, floor((1.5 - uv.y + offset) * 3.0) / 3.0);
            
            float waver = abs(noise(float2(u.progressa * 3.7)) * 2.0);
            n *= pow(fract(floor(uv.y * 15.0) / 15.0 + u.progressa * 0.3) * waver * 0.4 + 0.4, 0.65);
            n *= 0.75 + waver * 0.125;
            n = clamp(n, 0.0, 1.0);
            
        	__nv_out = float4(n);

        
         	// const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            // float4 gradmap;
            // float luminance = dot(__nv_out.rgb, luminanceWeighting);
            // gradmap = mix(color1,color2,luminance)*__nv_out.a;
        
    	// float4 factorx = mix(__nv_out,gradmap,alphab);
    	float4 factor = mix(texColorX,__nv_out,u.alpha);

        float4 resultfinal;
        // if( blendMode==0 ) {                // normal
            // resultfinal = (factor * u.bright) * texColor.a;
        // } else if( blendMode==1 ) {         // multiply
            // factor *= u.bright;
            // float4 c = factor + float4(1.)*(1.-factor.a);
            // resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        // } else if( blendMode==2 ) {         // screen
            factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        // }
            
    	__nv_out = resultfinal;
    	}
    return __nv_out;
}
