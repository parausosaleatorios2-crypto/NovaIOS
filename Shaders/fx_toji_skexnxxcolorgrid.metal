// ---------------------------------------------------------------------------
// Color Grid
// origem : assets/effects/toji-skexnxxcolorgrid.xml
// id     : com.alightcreative.effects.colorgrid
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxcolorgridParams {
    float progressa;
    float progressb;
    float scale;
    float bright;
    float alpha;
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
    
   #define FragCoord __nv_fragCoord
    
   /////////////////////////

fragment float4 fx_toji_skexnxxcolorgrid(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxcolorgridParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        // float2 syamjaidtz;
        // if (adaptive) { syamjaidtz = in.acScreenNorm; }
        // else { 
        // syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        // syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
        // }

        // syamjaidtz /= 1.0;
        // syamjaidtz *= rot2m(0.0*0.0174533);
        // syamjaidtz += float2((0.0+position.x), (0.0+position.y))*float2(-1.,1.)/500.;

        
        /////////////////////////

    	float4 result;
    	
    	// float2  px = 4.0*(-in.acScreenNorm + u.scale*in.acLayerNorm.xy) / eng.acScreenSize.y;
    	float2  px = 4.0*(-in.acScreenNorm + u.scale*FragCoord.xy) / eng.acScreenSize.y;
        
        float id = 0.5 + 0.5*cos(u.progressa + sin(dot(floor(px+0.5),float2(113.1,17.81)))*43758.545);
        
        float3  co = 0.5 + 0.5*cos(u.progressb + 2.0*id + float3(0.0,1.0,2.0) );
        
        float2  pa = smoothstep( 0.0, 0.2, id*(0.5 + 0.5*cos(6.2831*px)) );
        
        result = float4( co*pa.x*pa.y, 1.0 );
        
    	    // result
    	    // const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            // float4 gradmap;
            // float luminance = dot(result.rgb, luminanceWeighting);
            // gradmap = mix(color1,color2,luminance)*result.a;
        
    	// float4 factor = mix(texColorX,gradmap,u.alpha);
    	float4 factor = mix(texColorX,result,u.alpha);
    	
        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (factor * u.bright) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            factor *= u.bright;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = resultfinal;
    return __nv_out;
}
