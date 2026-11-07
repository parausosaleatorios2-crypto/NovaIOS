// ---------------------------------------------------------------------------
// Frosted Blur
// origem : assets/effects/toji-skexnxxfrostednew.xml
// id     : com.alightcreative.effects.sfrostednew
// passes : 1  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxfrostednewParams {
    int type;
    float iter;
    float alpha;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) {
    return a * (1. - b.a) + b;
    }
    
    static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    static float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        static float random2 (in float2 st) {
            return fract(sin(dot(st.xy,float2(12.9898,78.233)))* 43758.5453123);
        }
        
        // static float2 myPatternx(in float2 uvx){
            // float2 uv2x = uvx;
            // uv2x.x = uv2x.x + 0.1 * (random2(uvx));
            // return uv2x - uvx;
        // }
        
        // float2 myPatterny(in float2 uvy){
            // float2 uv2y = uvy;
            // uv2y.y = uv2y.y + 0.1 * (random2(uvy));
            // return uv2y - uvy;
        // }
        
        float2 myPattern(in float2 uv){
        	float2 uv2 = uv;
            if(u.type == 0) { uv2.x = uv2.x + 0.1 * (random2(uv)); }
            else if(u.type == 1) { uv2.y = uv2.y + 0.1 * (random2(uv)); }
            else if(u.type == 2) { 
            uv2.x = uv2.x + 0.1 * (random2(uv)); 
            uv2.y = uv2.y + 0.1 * (random2(uv));
            }
            return uv2 - uv;
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxfrostednew(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxfrostednewParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        // float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        // float2 xxx;
        // xxx = in.acScreenNorm; 
        // xxx += float2((-25.0), (0.0))*float2(-1.,1.)/500.;
        
        // float2 yyy;
        // yyy = in.acScreenNorm; 
        // yyy += float2((0.0), (25.0))*float2(-1.,1.)/500.;
        
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm; 
        
            if(u.type == 0) { syamjaidtz += float2((-25.0), (0.0))*float2(-1.,1.)/500.; }
            else if(u.type == 1) { syamjaidtz += float2((0.0), (25.0))*float2(-1.,1.)/500.; }
            else if(u.type == 2) { syamjaidtz += float2((-25.0), (25.0))*float2(-1.,1.)/500.; }
        
        /////////////////////////
        
    	float4 __nv_out;
    	
          float2 uv = syamjaidtz;
          float2 p = uv;
          for (int i = 0; i < 10; i ++) p -= myPattern(p) * 0.1;
          float3 col = inputImg.sample(__nv_smp, p).rgb;
                    
          __nv_out = float4(col, 1.0);
                    
    	__nv_out = mix(texColor, __nv_out, u.alpha) * texColor.a;
    	//
    return __nv_out;
}
