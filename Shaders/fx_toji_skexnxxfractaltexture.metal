// ---------------------------------------------------------------------------
// Fractal Texture
// origem : assets/effects/toji-skexnxxfractaltexture.xml
// id     : com.alightcreative.effects.fractaltexture
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxfractaltextureParams {
    float2 offset;
    float scale;
    float alpha;
    float angle;
    int blendMode;
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

fragment float4 fx_toji_skexnxxfractaltexture(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxfractaltextureParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
        // float2 st = in.acLayerNorm;
        // st -= 0.5;
        // st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
        // st /= 1.0;
        // st.x /= eng.acLayerSize.x/eng.acLayerSize.y;
        // st += 0.5;
    
        // float2 sampleCoord = l2s(st);
    
        // float4 texColor = inputImg.sample(__nv_smp, sampleCoord);
                
        /////////////////////////
        
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        
        float2 uv = in.acLayerNorm;
        uv -= 0.5;
        uv /= u.scale;
        uv.x *= eng.acLayerSize.x/eng.acLayerSize.y;
        uv *= rot2m(u.angle*0.0174533);
                
    	float4 result;
    	
     	float2 m = u.offset.xy / eng.acScreenSize.xy;
        float3 p = float3(uv, 0.5-m.x+0.02*sin(0.1));
        for (int i = 0; i < 128; i++)
        p.xzy = float3(1.3, 0.999, 0.777) * abs(p/dot(p,p)-float3(1.0,1.0,m.y*0.3));
        result = float4(p, 1.0);
        result *= u.alpha;
        
    	// __nv_out = result * texColor.a * u.alpha;
    	
    	float4 factor = result;
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
