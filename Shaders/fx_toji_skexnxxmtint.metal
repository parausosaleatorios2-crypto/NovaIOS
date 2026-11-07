// ---------------------------------------------------------------------------
// Magic Colortint
// origem : assets/effects/toji-skexnxxmtint.xml
// id     : com.alightcreative.effects.mtint
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxmtintParams {
    float progressa;
    float progressc;
    float progressd;
    float progresse;
    float progressf;
    float bright;
    float alpha;
    int blendMode;
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
   
   
   
   /////////////////////////

fragment float4 fx_toji_skexnxxmtint(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxmtintParams&  u    [[buffer(1)]],
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

    	float4 __nv_out;
    	
              	float2 uv = syamjaidtz;
        	
        	float3 orig = inputImg.sample(__nv_smp, uv).xyz;	// ...this is the video
        	
        	float3 col = orig * orig * u.progressa; 				// ...some contrast
        	float bri = (col.x+col.y+col.z)/2.0;		// ...it's ok it's black and white!
        	
        	float v = smoothstep(.0, u.progressc, bri);			// ...tint the dark values into cyan/teal.
        	col = mix(float3(u.progressd, u.progresse, u.progressf) * bri, col, v);
        	
        	v = smoothstep(0.2, 1.1, bri);				// ...tint the light values into orange.
        	col = mix(col, min(float3(1.0, 0.5, 0.0) * bri, 1.0), v);
        	
        	float x = 0.0; //
        	col = mix(orig, col, step(x, uv.x));		// ...mouse X to slide filter
        	__nv_out = float4(min(col, 1.0),1.0);
        
    	float4 factor = mix(texColorX,__nv_out,1.0);

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
            
    	__nv_out = mix(texColor, resultfinal, u.alpha);
    	// }
    return __nv_out;
}
