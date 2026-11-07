// ---------------------------------------------------------------------------
// Glow Ribbon+
// origem : assets/effects/toji-skexnxxglowribbon.xml
// id     : com.alightcreative.effects.glowribbon
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxglowribbonParams {
    float4 colorkey;
    float AMOUNT;
    float progressa;
    float progressb;
    float scale;
    float luminance;
    float2 position;
    float2 stretch;
    float angle;
    float alpha;
    float hue;
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
    
            
   /////////////////////////
    
    float squared(float value) { return value * value; }
    
    float getAmp(float frequency) { return black.sample(__nv_smp, float2(frequency / 512.0, 0)).x; }
    
    float getWeight(float f) {
        return (+ getAmp(f-2.0) + getAmp(f-1.0) + getAmp(f+2.0) + getAmp(f+1.0) + getAmp(f)) / 5.0; }

fragment float4 fx_toji_skexnxxglowribbon(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxglowribbonParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> black [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& black_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            
        float3x3 rgb2yuv = float3x3(
                 0.299,     0.587,    0.114,
                -0.14713,  -0.28886,  0.436,
                 0.615,    -0.51499, -0.10001
            );
            float3x3 yuv2rgb = float3x3(
                1.0,  0.0,      1.13983,
                1.0, -0.39465, -0.58060,
                1.0,  2.03211,  0.0
            );
            float rad = u.hue * 0.0174533;
            float3x3 huemat = float3x3(
                1.0,  0.0,       0.0,
                0.0,  cos(rad),  sin(rad),
                0.0,  -sin(rad), cos(rad)
            );
                
        /////////////////////////
        
    	float4 result;
    	
    	// float2 uvTrue = sampleCoord;
    	
    	float2 uvTrue;
        uvTrue = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        uvTrue.y *=eng.acLayerSize.y/eng.acLayerSize.x;
    	
        float2 uv = uvTrue;
        // float2 uv = -1.0 + 2.0 * uvTrue;
        uv /= u.scale;
        uv += u.position*float2(-1.,1.)/500.;
        uv.x *= eng.acLayerSize.x/eng.acLayerSize.y;
        uv *= rot2m(u.angle*0.0174533);
        
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        uv /= scaleVec;
        
    	float lineIntensity;
        float glowWidth;
        float3 color = float3(0.0);
        
    	for(float i = 0.0; i < u.AMOUNT; i++) {
            
    		uv.y += (0.2 * sin(uv.x + i/7.0 - u.progressa * 0.6));
            float Y = uv.y + getWeight(squared(i) * 20.0) *
                (black.sample(__nv_smp, float2(uvTrue.x, 1)).x - 0.5);
            // lineIntensity = 0.4 + squared(1.6 * abs(mod(uvTrue.x + i / 1.3 + u.progressb + 2.0) - 1.0)) + (offset * float2(-1.,1.))/1000.0;
            lineIntensity = 0.4 + squared(1.6 * abs(__nv_mod(uvTrue.x + i / 1.3 + u.progressb, 2.0) - 1.0));
    		glowWidth = abs(lineIntensity / (150.0 * Y));
    		color += float3(glowWidth * (u.luminance + sin(2.0 * 1.0)), glowWidth * (u.luminance - sin(0.0 * 0.6)), glowWidth * (u.luminance - cos(0.0 * 1.0)));
    	}	
    	
    	result = float4(color, 1.0);
    	result *= 1.0;
    	                	
            float4 huecolor;
    	    float3 rgb = result.rgb;
            float a = result.a;
            float3 yuv = rgb * rgb2yuv;
            
            float origSat = min(1.0,length(yuv.yz)*2.5); //
            float2 satUV = yuv.yz * 1.0;
            yuv.yz = mix(satUV,yuv.yz,origSat);
            
            yuv.yz = yuv.yz * 0.0;
            rgb = yuv * yuv2rgb;
            huecolor = float4(rgb,a);
            
    	    huecolor.rgb *= u.colorkey.rgb;
    	    huecolor.rgb *= huemat;
            // yuv = yuv * huemat;

    	
        float4 factor = mix(texColor,huecolor, u.alpha);
        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            factor *= texColor.a;
            resultfinal = factor + (texColor*(1.0-factor.a));
        } else if( u.blendMode==1 ) {         // multiply
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = resultfinal;
    return __nv_out;
}
