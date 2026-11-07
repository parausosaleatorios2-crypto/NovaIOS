// ---------------------------------------------------------------------------
// Puddle
// origem : assets/effects/toji-skexnxxpuddle.xml
// id     : com.alightcreative.effects.puddle
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxpuddleParams {
    int autop;
    int lowh;
    float EVO;
    float scale;
    float2 position;
    float angle;
    float NUM_DRIPS;
    float alpha;
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
   
        // #define u.NUM_DRIPS 20
        
        float Seed;
        
        void srand (float t)
        {
            Seed = 0.5 + (sin (t*59.0) + sin (t*73.0) + sin (t*97.0))/6.0;
        }
            
        float rand()
        {
            Seed = 0.25 + 0.5*Seed + 0.25*sin (12345.0 * Seed);
            return Seed;
        }
        
        float2 dripPos (float fTime, out float fAge)
        {
            float t = floor (fTime*0.1);
            srand (t);
            fAge = fTime*0.1 - t;
            return float2 (rand(), rand());
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxpuddle(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxpuddleParams&  u    [[buffer(1)]],
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
        float2 iRes = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm; 
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 vRel = syamjaidtz;
        
            float t = u.autop? u.EVO+(eng.acTime*0.5) : u.EVO;
            float fStep = 123.456;
            float fHeight = 0.0;
            
            for (int i = 0; i < int(u.NUM_DRIPS); i++)
            {
                float fAge;
                float2 vRnd = dripPos (t, fAge); //
                vRnd /= u.scale;
                vRnd *= rot2m((0.0+u.angle)*0.0174533);
                vRnd += float2((0.0-u.position.x), (0.0-u.position.y))*float2(-1.,1.)/500.;
        
                float2 vD = float2 (vRel - vRnd);
                float fD = sqrt (dot (vD, vD));
        
                float fDa = 10.0 * (fD - fAge + 0.6);
        
                fHeight += (1.0 - fAge) 
                    * max (0.0, 1.0 - (fDa*fDa))
                    * sin (fD*150.0 - fAge*80.0);
                
                t += fStep;
            }
        
            vRel.y -= sign (fHeight) * fHeight*fHeight;
            float4 vTex = inputImg.sample(__nv_smp, vRel);
        
            if (u.lowh)
            // if (fHeight < 0.0)
            {
                float p = -fHeight*0.8;
                float q = 1.0 - p;
                vTex.b = p + q*vTex.b;
                p = -fHeight*0.3;
                q = 1.0 - p;
                vTex.g = p + q*vTex.g;
            }
            
            __nv_out = vTex; 
        
    	float4 factor = mix(texColorX,__nv_out,1.0);

        float4 resultfinal;
            resultfinal = (factor * 1.0) * texColor.a;
            
    	__nv_out = mix(texColor, resultfinal, u.alpha);
    	//
    return __nv_out;
}
