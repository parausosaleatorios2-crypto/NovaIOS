// ---------------------------------------------------------------------------
// Glitch Pixel
// origem : assets/effects/toji-skexnxxglitchpixel.xml
// id     : com.alightcreative.effects.glitchpixel
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxglitchpixelParams {
    int repeat;
    float progressa;
    float progress;
    float scale;
    float angle;
    float progressr;
    float progressg;
    float progressb;
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
    
   float hash(float2 p) {
    	float h = dot(p,float2(127.1,311.7));
    	return -1.0 + 2.0*fract(sin(h)*43758.5453123);
    }
    
    float noise(float2 p) {
    	float2 i = floor(p);
    	float2 f = fract(p);
    
    	float2 u = f*f*(3.0-2.0*f);
    
    	return mix(mix(hash( i + float2(0.0,0.0) ), 
    		hash( i + float2(1.0,0.0) ), u.x),
    	mix( hash( i + float2(0.0,1.0) ), 
    		hash( i + float2(1.0,1.0) ), u.x), u.y);
    }
    
    float noise(float2 p, int oct) {
    	float2x2 m = float2x2( 1.6,  1.2, -1.2,  1.6 );
    	float f  = 0.0;
    
    	for(int i = 1; i < 3; i++){
    		float mul = 1.0/pow(2.0, float(i));
    		f += mul*noise(p); 
    		p = m*p;
    	}
    
    	return f;
    }

fragment float4 fx_toji_skexnxxglitchpixel(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxglitchpixelParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
        // float4 texColor = inputImg.sample(__nv_smp, sampleCoord);
                        
        /////////////////////////
        
        
    	float4 result;
    	
    	// float2 uvv = sampleCoord;
    	float2 uvv = in.acScreenNorm.st;
        
        float glitch = u.repeat? pow(cos((u.progressa+7.5)*0.5)*1.2+1.0, 1.2) : u.progressa;
        
        
        if(noise(0.5+float2(0, 0))*glitch > 0.62){
    		uvv.y = __nv_mod(uvv.y+noise(float2(1.0*4.0, 0)), 1.2);
    	}
    
        float2 syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;

    	float2 hp = float2(u.progress, uvv.y);
        hp /= u.scale;
        hp *= rot2m((0.0+u.angle)*0.0174533);
        // hp += float2((0.0+position.x), (0.0+position.y))*float2(-1.,1.)/500.;
    	
    	float nh = noise(hp*7.0+u.progress*10.0, 3) * (noise(hp+3.0*0.3)*0.8);
    	nh += noise(hp*100.0+10.0*10.0, 3)*0.02;
    	float rnd = 0.0;
    	if(glitch > 0.0){
    		rnd = hash(uvv);
    		if(glitch < 1.0){
    			rnd *= glitch;
    		}
    	}
    	nh *= glitch + rnd;
    	float r = inputImg.sample(__nv_smp, uvv+float2(nh, u.progressr)*nh).r;
    	float g = inputImg.sample(__nv_smp, uvv+float2(nh-u.progressg, 0.0)*nh).g;
    	float b = inputImg.sample(__nv_smp, uvv+float2(nh, u.progressb)*nh).b;
    
    	float3 col = float3(r, g, b);
    	result = float4(col.rgb, 1.0);
    	
            float4 targetLuma = result;
            const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float luma = dot(targetLuma.rgb, luminanceWeighting);
            float lowThresholdB = (0.06*(1.0+0.05))-0.001;
            float lowThresholdA = lowThresholdB-max(0.05,0.00001);
            float highThresholdA = (1.0*(1.0+0.05)-0.05)+0.001;
            float highThresholdB = highThresholdA+max(0.05,0.00001);
            float lowBlend = smoothstep( lowThresholdA, lowThresholdB, luma );
            float highBlend = 1. - smoothstep( highThresholdA, highThresholdB, luma );
            float lumafx = min(lowBlend,highBlend);
            float4 fxLuma = targetLuma*lumafx;
        
    	__nv_out = newLayer(texColor, fxLuma) * texColor.a;
    return __nv_out;
}
