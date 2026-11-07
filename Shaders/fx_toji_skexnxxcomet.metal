// ---------------------------------------------------------------------------
// Comet
// origem : assets/effects/toji-skexnxxcomet.xml
// id     : com.alightcreative.effects.comet
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxcometParams {
    int typeComet;
    float scale;
    float progressa;
    float2 position;
    float bright;
    float alpha;
    float angle;
    float4 color1;
    float4 color2;
    float4 color3;
    int blendMode;
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
    
   #define fragCoord __nv_fragCoord
    
   /////////////////////////
   
    #define PI 3.14159
    #define	TAU 6.28318
    
    float vDrop(float2 uv,float t)
    {
        uv.x = uv.x*128.0;						// H-Count
        float dx = fract(uv.x);
        uv.x = floor(uv.x);
        uv.y *= 0.05;							// stretch
        float o=sin(uv.x*215.4);				// offset
        float s=cos(uv.x*33.1)*.3 +.7;			// speed
        float trail = mix(95.0,35.0,s);			// trail length
        float yv = fract(uv.y + t*s + o) * trail;
        yv = 1.0/yv;
        yv = smoothstep(0.0,1.0,yv*yv);
        yv = sin(yv*PI)*(s*5.0);
        float d2 = sin(dx*PI);
        return yv*(d2*d2);
    }

   /////////////////////////

fragment float4 fx_toji_skexnxxcomet(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxcometParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 syamjaidtz;
        // if (adaptive) { syamjaidtz = in.acScreenNorm; }
        // else { 
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
        // }

        // syamjaidtz /= (5.0+u.scale);
        syamjaidtz *= rot2m((0.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/250.;

        
        /////////////////////////

    	float4 __nv_out;
    	
    	float2 p = syamjaidtz;
        p /= (u.scale-0.5);
        float d = length(p)+0.1;
    	p = float2(__nv_atan(p.x, p.y) / PI, 2.5 / d);
        if (0.0>0.5)
        	p.y *= 0.5;
        float t =  u.progressa*0.4;
        float3 col = float3(u.color1.rgb) * vDrop(p,t);	// red
        col += float3(u.color2.rgb) * vDrop(p,t+0.33);	// blue
        col += float3(u.color3.rgb) * vDrop(p,t+0.66);	// green
    	__nv_out = float4(col*(d*d), 1.0);
    	
    	float4 comet;
    	float2 uvX = syamjaidtz;
        uvX /= (u.scale-0.5);
    	uvX.y = 1.-uvX.y;
    	if (0.0>0.5)
            uvX.y = 1.0-uvX.y;					// V-flip
        
        float3 colX = float3(u.color1.rgb);		// Drop Colour
        uvX.x = uvX.x*64.0;						// H-Count
        float dxX = fract(uvX.x);
        uvX.x = floor(uvX.x);
        float tX =  u.progressa*0.4;
        uvX.y *= 0.15;							// stretch
        float oX=sin(uvX.x*215.4);				// offset
        float sX=cos(uvX.x*33.1)*.3 +.7;			// speed
        float trailX = mix(95.0,35.0,sX);			// trail length
        float yvX = fract(uvX.y + tX*sX + oX) * trailX;
        yvX = 1.0/yvX;
        yvX = smoothstep(0.0,1.0,yvX*yvX);
        yvX = sin(yvX*PI)*(sX*5.0);
        float d2X = sin(dxX*PI);
        yvX *= d2X*d2X;
        colX = colX*yvX;
        comet = float4(colX,1.0);
        
        float4 factor;
    	if ( u.typeComet==0 ) { factor = mix(texColorX,__nv_out,u.alpha); }
    	else if ( u.typeComet==1 ) { factor = mix(texColorX,comet,u.alpha); }
    	
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
