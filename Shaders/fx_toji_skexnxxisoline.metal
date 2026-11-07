// ---------------------------------------------------------------------------
// Isoline
// origem : assets/effects/toji-skexnxxisoline.xml
// id     : com.alightcreative.effects.isoline
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxisolineParams {
    float2 position;
    float progressa;
    float progressb;
    float progressc;
    float scale;
    float bright;
    float alpha;
    float angle;
    float4 color1;
    float4 color2;
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
   
   static float wave(float x, float y) 
    {
        return sin(10.0*x+10.0*y) / 5.0 +
               sin(20.0*x+15.0*y) / 3.0 +
               sin(4.0*x+10.0*y) / -4.0 +
               sin(y) / 2.0 +
               sin(x*x*y*20.0) + 
               sin(x * 20.0 + 4.0) / 5.0 +
               sin(y * 30.0) / 5.0 + 
        	   sin(x) / 4.0; 
        
    }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxisoline(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxisolineParams&  u    [[buffer(1)]],
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
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;

        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((-180.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;

        
        /////////////////////////

    	float4 __nv_out;
    	
    	float2 uv = syamjaidtz;
    
        float z = wave(uv.x, uv.y) + 2.0;
        
        
        z *= u.progressc * sin(1.57 + u.progressa / 5.0);
        float d = fract(z);
        if(__nv_mod(z, 2.0) > 1.) d = 1.-d;
         
    
        d = d/(u.progressb*z);
        __nv_out = float4(1.,1.,1.,1.) + ((1.-float4(d)) + float4(1.,1.,1.,1.));
        
    	    const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float4 gradmap;
            float luminance = dot(__nv_out.rgb, luminanceWeighting);
            gradmap = mix(u.color1,u.color2,luminance)*__nv_out.a;
    	    float4 factor = mix(texColorX,gradmap,1.0);
    	// float4 factor = mix(texColorX,__nv_out,u.alpha);
    	
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
            
    	__nv_out = mix(texColor,resultfinal,u.alpha);
    return __nv_out;
}
