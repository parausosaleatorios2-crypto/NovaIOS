// ---------------------------------------------------------------------------
// Pixel Sorter
// origem : assets/effects/toji-skexnxxpixelsorter.xml
// id     : com.alightcreative.effects.pixelsorter
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxpixelsorterParams {
    float progressx;
    float progressb;
    float deltax;
    float pixel;
    float angle;
    float alpha;
    float maxoffset;
    int offside;
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

    
   /////////////////////////
    
    #define MAX_OFFSET u.maxoffset
    #define vertoffs false
    #define mirror true
    #define phase 0.0
    #define progress (1.57 * u.progressx)
    
     float rand(float co) { return fract(sin(co*(91.3458+u.deltax)) * 47453.5453); }

fragment float4 fx_toji_skexnxxpixelsorter(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxpixelsorterParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
                        
        /////////////////////////
        
    	float4 result;
    	        
    	//////////////////////////
    	
    	float2 uv = in.acScreenNorm;
    	
        float2 texel = 1. / in.acScreenNorm;
        texel *= rot2m(u.angle*0.0174533);
        texel += (0.0,u.progressb)*float2(-1.,1.)/500.;
        
        float4 img = texColor;
        
        // float step_y;
        // if( stepy ) { step_y = texel.y*(rand(uv.x)*100.0); }
        // else { step_y = texel.y*(rand(uv.x)*MAX_OFFSET) * (sin(sin(-1.57*0.5))*2.0+1.3); }
        
        float step_y = texel.y*(rand(uv.x)*MAX_OFFSET) * (sin(sin(-1.57*0.5))*2.0+1.3);
        step_y += rand(uv.x*uv.y*1.0)*u.pixel*sin(1.0);								// shake offset and modulate it
        step_y = mix(step_y, step_y*rand(uv.x*0.0)*0.5, sin(progress)); 					// more noisy spikes
        
        if ( dot(img,  float4(0.299, 0.587, 0.114, 0.0) ) > 1.2*(sin(1.0)*0.325+0.50)){
        	uv.y+=step_y;
        } else{
        	uv.y-=step_y;
        }
        
        img = inputImg.sample(__nv_smp, uv);
        
        //////////////////////////
        
        result = mix(texColor,img,1.0) * texColor.a;
        if ( u.offside) { result = mix(texColor,img,1.0); }
        
        __nv_out = newLayer(texColor,result);
    return __nv_out;
}
