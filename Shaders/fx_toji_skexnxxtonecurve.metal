// ---------------------------------------------------------------------------
// Tone Curve
// origem : assets/effects/toji-skexnxxtonecurve.xml
// id     : com.alightcreative.effects.tonecurve
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxtonecurveParams {
    float highlights;
    float lights;
    float shadows;
    float darks;
    float alpha;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    static float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    static float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
   
   
   /////////////////////////

fragment float4 fx_toji_skexnxxtonecurve(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxtonecurveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float2 iResolution = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 iMouse = float2(0.5, 0.5);
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm; 
                
        /////////////////////////
        
    	float4 __nv_out;
    	
	float4 col = inputImg.sample(__nv_smp, in.acScreenNorm.st);
	float4 lightValues;
	float4 paramWeights;
	
	float lum = (col.r + col.g + col.b) / 3.0;
	
	lightValues.x = lum;
	lightValues.y = lum;
	lightValues.z = 1.0 - lum;
	lightValues.w = 1.0 - lum;
	lightValues.xz = (lightValues.xz - 0.25)*1.3333334;
	lightValues.yw = 2.0*(lightValues.yw - 0.5);
	
	lightValues = max(lightValues,0.0)*1.5;
	lightValues = (3.0 - 2.0*lightValues)*lightValues*lightValues;
	
	paramWeights.x = u.lights*u.lights*sign(u.lights);
	paramWeights.y = u.highlights*u.highlights*sign(u.highlights);
	paramWeights.z = u.shadows*u.shadows*sign(u.shadows);
	paramWeights.w = u.darks*u.darks*sign(u.darks);

	float sum = abs(paramWeights.x) + abs(paramWeights.y) + abs(paramWeights.z) + abs(paramWeights.w) + 1.0;

	col.rgb += dot(lightValues,paramWeights)/sum;

	__nv_out.rgb = min(col.rgb,col.a);
	__nv_out.a = col.a;
        
    	float4 factor = mix(texColorX,__nv_out,1.0);
    	
        float4 resultfinal;
        resultfinal = factor * texColor.a;
            
    	__nv_out = mix(texColor, resultfinal, u.alpha) * texColor.a;
    	//
    return __nv_out;
}
