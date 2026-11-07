// ---------------------------------------------------------------------------
// TV Damage + Scanlines
// origem : assets/effects/toji-skexnxxtvdamage.xml
// id     : com.alightcreative.effects.tvdamage
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxtvdamageParams {
    float alpha;
    float scalinesOpt;
    float scalinesOpta;
    float scalinesOptb;
    float bottomStaticOpt;
    float rgbOffsetOpt;
    float horzFuzzOpt;
    float seed;
    float ggg;
    float wave;
    float hardoff;
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
    
   /////////////////////////
   
    
    // Noise generation functions borrowed from: 
    // https://github.com/ashima/webgl-noise/blob/master/src/noise2D.glsl
    
    float3 mod289(float3 x) {
      return x - floor(x * (1.0 / 289.0)) * 289.0;
    }
    
    float2 mod289(float2 x) {
      return x - floor(x * (1.0 / 289.0)) * 289.0;
    }
    
    float3 permute(float3 x) {
      return mod289(((x*34.0)+1.0)*x);
    }
    
    float snoise(float2 v)
      {
      const float4 C = float4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                          0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                         -0.577350269189626,  // -1.0 + 2.0 * C.x
                          0.024390243902439); // 1.0 / 41.0
    // First corner
      float2 i  = floor(v + dot(v, C.yy) );
      float2 x0 = v -   i + dot(i, C.xx);
    
    // Other corners
      float2 i1;
      //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
      //i1.y = 1.0 - i1.x;
      i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
      // x0 = x0 - 0.0 + 0.0 * C.xx ;
      // x1 = x0 - i1 + 1.0 * C.xx ;
      // x2 = x0 - 1.0 + 2.0 * C.xx ;
      float4 x12 = x0.xyxy + C.xxzz;
      x12.xy -= i1;
    
    // Permutations
      i = mod289(i); // Avoid truncation effects in permutation
      float3 p = permute( permute( i.y + float3(0.0, i1.y, 1.0 ))
    		+ i.x + float3(0.0, i1.x, 1.0 ));
    
      float3 m = max(0.5 - float3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
      m = m*m ;
      m = m*m ;
    
    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
    
      float3 x = 2.0 * fract(p * C.www) - 1.0;
      float3 h = abs(x) - 0.5;
      float3 ox = floor(x + 0.5);
      float3 a0 = x - ox;
    
    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= rsqrt( a0*a0 + h*h );
      m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    
    // Compute final noise value at P
      float3 g;
      g.x  = a0.x  * x0.x  + h.x  * x0.y;
      g.yz = a0.yz * x12.xz + h.yz * x12.yw;
      return 130.0 * dot(m, g);
    }
    
    float staticV(float2 syamjaidtz) {
        float staticHeight = snoise(float2(9.0,1.0*1.2+3.0))*0.3+5.0;
        float staticAmount = snoise(float2(1.0,1.0*1.2-6.0))*0.1+0.3;
        float staticStrength = snoise(float2(-9.75,1.0*0.6-3.0))*2.0+2.0;
    	return (1.0-step(snoise(float2(5.0*pow(1.0,2.0)+pow(syamjaidtz.x*7.0,1.2),pow((__nv_mod(1.0, 100.0)+100.0)*syamjaidtz.y*0.3+3.0,staticHeight))),staticAmount))*staticStrength;
    }

fragment float4 fx_toji_skexnxxtvdamage(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxtvdamageParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        
        float2 syamjaidtz = in.acScreenNorm;
        syamjaidtz -= 0.5;
        syamjaidtz.x *= eng.acScreenSize.x/eng.acScreenSize.y;
        syamjaidtz /= 1.0;
        syamjaidtz.x /= eng.acScreenSize.x/eng.acScreenSize.y;
        syamjaidtz += 0.5;
        // syamjaidtz *= rot2m(angle*0.0174533);
                
        // float2 syamjaidtz = l2s(st);
            
        float rad = 0.0 * 0.0174533;
        float2 v = normalize(float2(cos(rad),-sin(rad)));
        
        /////////////////////////
        
    	float4 result;
    	
    	// float2 syamjaidtz =  in.acScreenNorm;
    	
    	float jerkOffset = (1.0-step(snoise(float2(1.0*1.3,5.0)),0.8))*0.05;
    	
    	// float fuzzOffset = snoise(float2(u.seed*15.0,syamjaidtz.y*80.0))*0.003;
    	float fuzzOffset = snoise(float2(u.seed*15.0,syamjaidtz.y*80.0))*0.1;
    	
    	// float largeFuzzOffset = snoise(float2(u.wave*1.0,syamjaidtz.y*25.0))*0.004;
    	float largeFuzzOffset = snoise(float2(u.wave*1.0,syamjaidtz.y*25.0))*u.ggg;
        
        /// DONT TOUCH
        float vertMovementOn = (1.0-step(snoise(float2(1.0*0.2,8.0)),0.4))*1.0;
        float vertJerk = (1.0-step(snoise(float2(1.0*1.5,5.0)),0.6))*1.0;
        float vertJerk2 = (1.0-step(snoise(float2(1.0*5.5,5.0)),0.2))*1.0;
        float yOffset = abs(sin(1.0)*4.0)*vertMovementOn+vertJerk*vertJerk2*0.3;
        float y = __nv_mod(syamjaidtz.y+yOffset, u.hardoff);
        /// ---------------
    	
    	float xOffset = (fuzzOffset + largeFuzzOffset) * u.horzFuzzOpt;
        
        float staticVal = 0.0;
       
        for (float y = -1.0; y <= 1.0; y += 1.0) {
            float maxDist = 5.0/200.0;
            float dist = y/200.0;
        	staticVal += staticV(float2(syamjaidtz.x,syamjaidtz.y+dist))*(maxDist-abs(dist))*1.7;
        }
            
        staticVal *= u.bottomStaticOpt;
    	
    	float red 	=   inputImg.sample(__nv_smp, float2(syamjaidtz.x + xOffset -0.01*u.rgbOffsetOpt,y)).r+staticVal;
    	float green = 	inputImg.sample(__nv_smp, float2(syamjaidtz.x + xOffset,	  y)).g+staticVal;
    	float blue 	=	inputImg.sample(__nv_smp, float2(syamjaidtz.x + xOffset +0.01*u.rgbOffsetOpt,y)).b+staticVal;
    	
    	float3 color = float3(red,green,blue);
    	// float scanline = sin(syamjaidtz.y*800.0)*0.04*u.scalinesOpt;
    	float scanline = sin(syamjaidtz.y*u.scalinesOptb)*u.scalinesOpta*u.scalinesOpt;
    	color -= scanline;
    	////////////////////////
    	result = float4(color,1.0);
    	///////////////////////
    	float4 texColorOri = inputImg.sample(__nv_smp, in.acScreenNorm);
    	// float4 texColorOri = inputImg.sample(__nv_smp, syamjaidtz);

    	float4 final = result * texColor.a;
    	    	
    	__nv_out = mix(texColor,final,u.alpha);
    return __nv_out;
}
