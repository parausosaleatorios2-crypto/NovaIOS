// ---------------------------------------------------------------------------
// Glitch RGB
// origem : assets/effects/toji-skexnxxrgbglitch.xml
// id     : com.alightcreative.effects.rgbglitch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxrgbglitchParams {
    float progressd;
    float progressb;
    float progressa;
    float progressc;
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
    
   /////////////////////////
    
   static float random2d(float2 n) { 
        return fract(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
    }
    
    static float randomRange (in float2 seed, in float min, in float max) {
    		return min + random2d(seed) * (max - min);
    }
    
    // return 1 if v inside 1d range
    static float insideRange(float v, float bottom, float top) {
       return step(bottom, v) - step(top, v);
    }
    
    //inputs
    // float AMT = u.progressb; //0 - 1 glitch amount
    // float SPEED = 0.6; //0 - 1 speed

fragment float4 fx_toji_skexnxxrgbglitch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxrgbglitchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> black [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& black_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        // float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        if(u.progressb <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); }
        else if(u.progressb >= 0.0001) { 
        
        float2 syamjaidtz = in.acLayerNorm;
    	
        syamjaidtz -= 0.5;
        syamjaidtz += 0.5;
        syamjaidtz.x *= eng.acLayerSize.x/eng.acLayerSize.y;
        syamjaidtz.x /= eng.acLayerSize.x/eng.acLayerSize.y;
        syamjaidtz /= 1.0;
        // syamjaidtz *= rot2m(angle*0.0174533);
        // syamjaidtz += position*float2(-1.,1.)/500.;
        
        float2 sampleCoord = l2s(syamjaidtz);
    
        float4 texColor = inputImg.sample(__nv_smp, sampleCoord);
                        
        /////////////////////////
        
        
    	float4 result;
    	    	
    	float time = floor(u.progressa * 0.6 * 60.0);    
    	float2 uv = sampleCoord;
        
        //copy orig
        float3 outCol = inputImg.sample(__nv_smp, uv).rgb;
        
        //randomly offset slices horizontally
        float maxOffset = u.progressb/2.0;
        for (float i = 0.0; i < 10.0 * u.progressb; i += 1.0) {
            float sliceY = random2d(float2(time , 2345.0 + float(i)));
            float sliceH = random2d(float2(time , 9035.0 + float(i))) * u.progressd;
            float hOffset = randomRange(float2(time , 9625.0 + float(i)), -maxOffset, maxOffset);
            float2 uvOff = uv;
            uvOff.x += hOffset;
            if (insideRange(uv.y, sliceY, fract(sliceY+sliceH)) == 1.0 ){
            	outCol = inputImg.sample(__nv_smp, uvOff).rgb;
            }
        }
        
        //do slight offset on one entire channel
        float maxColOffset = u.progressc/6.0;
        float rnd = random2d(float2(time , 9545.0));
        float2 colOffset = float2(randomRange(float2(time , 9545.0),-maxColOffset,maxColOffset), 
                           randomRange(float2(time , 7205.0),-maxColOffset,maxColOffset));
        if (rnd < 0.33){
            outCol.r = inputImg.sample(__nv_smp, uv + colOffset).r;
            
        }else if (rnd < 0.66){
            outCol.g = inputImg.sample(__nv_smp, uv + colOffset).g;
            
        } else{
            outCol.b = inputImg.sample(__nv_smp, uv + colOffset).b;  
        }
           
    	result = float4(outCol,1.0);
        
    	float4 factor = result * texColor.a;
    	__nv_out = mix(texColor,factor,1.0);
       }
    return __nv_out;
}
