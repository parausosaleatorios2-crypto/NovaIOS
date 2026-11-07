// ---------------------------------------------------------------------------
// Bad Signal
// origem : assets/effects/toji-skexnxxbadsignal.xml
// id     : com.alightcreative.effects.badsignal
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxbadsignalParams {
    int typeX;
    int greyscale;
    int autop;
    int autod;
    float progressx;
    float progressd;
    float progressb;
    float progressc;
    float alpha;
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
    
        float greyScale(in float3 col) {
            return dot(col, float3(0.2126, 0.7152, 0.0722));
        }
    
   /////////////////////////
    
   float noise(float2 p)
    {
    	float s;
    	if(u.typeX == 0) { s = black.sample(__nv_smp, float2(1.,2.*cos(1.0))*0.1*8. + p*1.).x; }
    	else if (u.typeX ==1) { s = noisex.sample(__nv_smp, float2(1.,2.*cos(1.0))*0.1*8. + p*1.).x; }
    	s *= s;
    	return s;
    }
    
    float onOff(float a, float b, float c)
    {
    	float PROGO = u.autop? u.progressx + (eng.acTime*0.5) : u.progressx;
    	return step(c, sin(PROGO + a*cos(PROGO*b)));
    }
    
    float ramp(float y, float start, float end)
    {
    	float inside = step(start,y) - step(end,y);
    	float fact = (y-start)/(end-start)*inside;
    	return (1.-fact) * inside;
    	
    }
    
    float stripes(float2 uv)
    {
    	float EVO = u.autod? u.progressd + (eng.acTime*1.25) : u.progressd;
    	float noi = noise(uv*float2(0.5,1.) + float2(1.,3.));
    	return ramp(__nv_mod(uv.y*4. + EVO/2.+sin(EVO + sin(EVO*0.63)), 1.),0.5,0.6)*noi;
    }
    
    float3 getVideo(float2 uv)
    {
    	float2 look = uv;
    	float PROG = u.autop? u.progressx + (eng.acTime*0.5) : u.progressx;
    	float window = 1./(1.+20.*(look.y-__nv_mod(PROG/4., 1.))*(look.y-__nv_mod(PROG/4., 1.)));
    	look.x = look.x + sin(look.y*10. + PROG)/50.*onOff(4.,4.,.3)*(1.+cos(PROG*80.))*window;
    	float vShift = 0.4*onOff(2.,3.,.9)*(sin(PROG)*sin(PROG*20.) +  (0.5 + 0.1*sin(PROG*200.)*cos(PROG)));
    	look.y = __nv_mod(look.y + vShift, 1.);
    	float3 video = float3(inputImg.sample(__nv_smp, look));
        if (u.greyscale) video = float3(greyScale(video));
    	return video;
    }
    
    float2 screenDistort(float2 uv)
    {
    	uv -= float2(.5,.5);
    	uv = uv*1.2*(1./1.2+2.*uv.x*uv.x*uv.y*uv.y);
    	uv += float2(.5,.5);
    	return uv;
    }

fragment float4 fx_toji_skexnxxbadsignal(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxbadsignalParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> noisex [[texture(1)]],
    texture2d<float> black [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& noisex_info [[buffer(3)]],
    constant NovaTexInfo& black_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
                
        /////////////////////////
        
        
    	float4 result;
    	
    	float2 uv = in.acScreenNorm.st;
    	uv = screenDistort(uv);
    	float3 video = getVideo(uv);
    	float BLINK = u.autod? u.progressb + (eng.acTime*0.5) : u.progressb;
    	float SLINES = u.autod? u.progressc + (eng.acTime*0.5) : u.progressc;
    	float vigAmt = 3.+.3*sin(1.0 + 5.*cos(BLINK*5.));
    	float vignette = (1.-vigAmt*(uv.y-.5)*(uv.y-.5))*(1.-vigAmt*(uv.x-.5)*(uv.x-.5));
    	
    	video += stripes(uv);
    	video += noise(uv*2.)/2.;
    	video *= vignette;
    	video *= (12.+__nv_mod(uv.y*30.+SLINES, 1.))/13.;
    	
    	result = float4(video,u.alpha);
        
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
            
    	// __nv_out = resultfinal;
    	__nv_out = mix(texColor,resultfinal,1.0) * texColor.a;
    return __nv_out;
}
