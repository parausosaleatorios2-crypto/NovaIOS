// ---------------------------------------------------------------------------
// Lens Distortion+
// origem : assets/effects/toji-skexnxxlensd.xml
// id     : com.alightcreative.effects.lensd
// passes : 2  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxlensdParams {
    int offs;
    float amp;
    float strength;
    float blurMax;
    float aberrationMax;
    float numIters;
    float bright;
    float alpha;
    int new;
    float iter;
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
   
        // const float u.blurMax = 0.2;
        // const float u.aberrationMax = 1.2;
        // const float u.numIters = 51.0;
        
        float weightedColour(float colour, float offset, float mid) {
            
            return colour * 1.0 * (mid - abs(mid-float(offset)))/mid;
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxlensd(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxlensdParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xdist [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xdist_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float2 iRes = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        
        float maxF = max(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 texelSize = 1.0 / float2(maxF, maxF);
        
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm; 
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 scaledInput = float2(u.strength, 0.0) / iRes;    
        
            float blur = -u.blurMax * scaledInput.x;
        	float aberration = 1.0 + (u.aberrationMax * (1.0 - scaledInput.y));
        
        	int channelspread = int(float(u.numIters) / aberration);
        	float mid = float(channelspread+1)/2.0;
        
            float3 lobound = float3(int(u.numIters)-channelspread,(int(u.numIters)-channelspread)/2,0.0);
            float3 hibound = float3(int(u.numIters),(int(u.numIters)+channelspread)/2,channelspread);
        
        	float2 uv = syamjaidtz;
            
        	const float2 centre = float2(0.5,0.5);
            uv -= centre; 
        
            float4 colour = float4(0.0);
        
        	float blurPerIter = blur / float(int(u.numIters)-1); 
            for(float i = 0.0; i < u.numIters; i++) {
                float scale = 1.0 + (blurPerIter * float(i));
                float4 txColour = xdist.sample(__nv_smp, centre + (uv * scale));
               
                float3 kk = float3(i+1.0) - lobound;
                
                if (i>=lobound.x && i<hibound.x) {
                    colour.x += weightedColour(txColour.x,kk.x,mid);
                } 
                if (i>=lobound.y && i<hibound.y) {
                    colour.y += weightedColour(txColour.y,kk.y,mid);
                }
                if (i>=lobound.z && i<hibound.z) {
                    colour.z += weightedColour(txColour.z,kk.z,mid);
                }
            }
            
            
        	__nv_out = colour / (0.5*float(channelspread+1));
        
    	float4 factor = mix(texColorX,newLayer(texColorX,__nv_out),1.0);
    	factor *= u.bright;
    	
    	__nv_out = mix(texColor, factor, u.alpha) * texColor.a;
    	if(u.offs) { __nv_out = newLayer(texColorX,__nv_out) * u.bright; }
    	//
    return __nv_out;
}
