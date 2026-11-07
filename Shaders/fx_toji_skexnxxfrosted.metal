// ---------------------------------------------------------------------------
// Frosted
// origem : assets/effects/toji-skexnxxfrosted.xml
// id     : com.alightcreative.effects.frosted
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxfrostedParams {
    float progressa;
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
   
        // float dist = 4.0; // how far to sample from
        // float u.progressa = 6.; // how many times to sample, more = smoother
        
        float rand(float2 uv){
         return fract(sin(dot(uv, float2(12.9898,78.233)))*43578.5453);   
        }

   
   /////////////////////////

fragment float4 fx_toji_skexnxxfrosted(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxfrostedParams&  u    [[buffer(1)]],
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
    	
            float2 uv = syamjaidtz;
            // float2 uv = fragCoord/iResolution.xy;
            float4 t = float4(0.0);
            
            float2 texel = 1.0 / inputImg_info.size;
            float2 d = texel * u.progressa;
            
            for(float i = 0.0; i < 3.0; i++){
            	
        	float r1 = clamp(rand(uv * float(i))*2.0-1.0, -d.x, d.x);
            	float r2 = clamp(rand(uv * float(i+3.0))*2.0-1.0, -d.y, d.y);
            
            	t += inputImg.sample(__nv_smp, uv + float2(r1 , r2));
            }
            
            t /= float(3.0);
        
            __nv_out = t;
            
    	__nv_out = mix(texColor, __nv_out, u.alpha) * texColor.a;
    	//
    return __nv_out;
}
