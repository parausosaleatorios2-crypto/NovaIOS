// ---------------------------------------------------------------------------
// Warp Distortion
// origem : assets/effects/toji-skexnxxwarpdist.xml
// id     : com.alightcreative.effects.warpdist
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxwarpdistParams {
    float scaleuv;
    float warpx;
    float warpy;
    float intensity;
    float amp;
    float speed;
    float2 position;
    float2 stretch;
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
   
        float2 distortUV(float2 uv, float2 nUV)
        {            
            
            nUV.x += u.warpx*u.speed;
            nUV.y += u.warpy*u.speed;
            float2 noise= noisexx.sample(__nv_smp, nUV*u.amp).xy;
            
            uv += (-1.0+noise*2.0) * u.intensity;
            
            return uv;
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxwarpdist(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxwarpdistParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> noisexx [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& noisexx_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm;
        
        syamjaidtz /= u.scaleuv;
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;
        float2 scaleVec;
        scaleVec = float2(u.scaleuv*u.stretch.x,u.scaleuv*u.stretch.y);
        syamjaidtz /= scaleVec;        
        /////////////////////////
        
    	float4 __nv_out;
    	    	
            float2 uv = syamjaidtz;
            float2 nUV = uv;
                        
            uv = distortUV(uv, float2(nUV.x,nUV.y));
            
            float4 color= inputImg.sample(__nv_smp, uv);
        
    	__nv_out = color;
    	//
    return __nv_out;
}
