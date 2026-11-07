// ---------------------------------------------------------------------------
// Paper Burn
// origem : assets/effects/toji-skexnxxpaperburn.xml
// id     : com.alightcreative.effects.paperburn
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxpaperburnParams {
    float4 color;
    float progressa;
    float feather;
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
    
   /////////////////////////
    
   float Hash( float2 p)
    {
    	float3 p2 = float3(p.xy,1.0);
        return fract(sin(dot(p2,float3(37.1,61.7, 12.4)))*3758.5453123);
    }
    
    float noise(in float2 p)
    {
        float2 i = floor(p);
    	float2 f = fract(p);
    	f *= f * (3.0-2.0*f);
    
        return mix(mix(Hash(i + float2(0.,0.)), Hash(i + float2(1.,0.)),f.x),
    		mix(Hash(i + float2(0.,1.)), Hash(i + float2(1.,1.)),f.x),
    		f.y);
    }
    
    float fbm(float2 p) 
    {
    	float v = 0.0;
    	v += noise(p*1.)*.5;
    	v += noise(p*2.)*.25;
    	v += noise(p*4.)*.125;
    	v += noise(p*8.)*.0625;
    	v += noise(p*16.)*.03125;
    	return v;
    }

fragment float4 fx_toji_skexnxxpaperburn(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxpaperburnParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> gs [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& gs_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        // float4 glow = edge.texture.sample(__nv_smp, in.acScreenNorm);
        /////////////////////////
        
        
    	float4 result;
    	
    	float2 uv = in.acScreenNorm;
        float2 uvDisplace = uv;
        
        bool apply = true;
    	
    	float factor = (1.-(0.14+u.progressa));
        if(!apply)
            factor = 0.0;
        
        float factorInv = 1.0 - factor;
        
    	
    	// burn
        float2 p = uv * 10.;
        //float noiseBurn = noise(uv + noise(uv * 2. +  fbm(uv * 40.)));
        
        float noiseControl = noise(uv * 3. + 2.5)*1.3;
        
        float noiseBurn = fbm(uv * 15. );
        //noiseBurn *= noiseControl;
        
    	float burn = (noiseBurn + factor);
        if(apply)
        	burn = pow(burn, u.feather);
        burn = clamp(burn, 0.0, 1.0);
        
        
        float displace = -mix(0.0, burn * 0.03, factor);
        uvDisplace += displace;
        
        float3 src = float3(u.color.rgb);
    	float3 tgt = inputImg.sample(__nv_smp, uv).rgb;
    	float3 col = src;
        
        
        col = float3(burn);
        if(apply)
        col = mix(src, tgt, burn);
    	result = float4(col, 1.0);
        
    	float4 factorx = result * u.alpha;
        factorx *= texColor.a;
        float4 resultfinal = factorx + (texColor*(1.0-factorx.a));
        
    	__nv_out = resultfinal;
    	// __nv_out = mix(resultfinal,chromakey,1.0) * texColor.a;
    return __nv_out;
}
