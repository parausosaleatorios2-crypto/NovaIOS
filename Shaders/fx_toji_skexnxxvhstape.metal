// ---------------------------------------------------------------------------
// VHS Tape
// origem : assets/effects/toji-skexnxxvhstape.xml
// id     : com.alightcreative.effects.vhstape
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxvhstapeParams {
    float progressa;
    float progressc;
    float scale;
    float2 position;
    float2 stretch;
    float bright;
    float alpha;
    float angle;
    float4 color1;
    float4 color2;
    int blendMode;
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
   
          #define t u.progressa
        
        //random hash
        float4 hash42(float2 p){
            
        	float4 p4 = fract(float4(p.xyxy) * float4(443.8975,397.2973, 491.1871, 470.7827));
            p4 += dot(p4.wzxy, p4+19.19);
            return fract(float4(p4.x * p4.y, p4.x*p4.z, p4.y*p4.w, p4.x*p4.w));
        }
        
        
        float hash( float n ){
            return fract(sin(n)*43758.5453123);
        }
        
 
        float n( in float3 x ){
            float3 p = floor(x);
            float3 f = fract(x);
            f = f*f*(3.0-2.0*f);
            float n = p.x + p.y*57.0 + 113.0*p.z;
            float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                                mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                            mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                                mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
            return res;
        }
        
        //tape noise
        float nn(float2 p){
        
        
            float y = p.y;
            float s = t*2.;
            
            float v = (n( float3(y*.01 +s, 			1., 1.0) ) + .0)
                  	 *(n( float3(y*.011+1000.0+s, 	1., 1.0) ) + .0) 
                  	 *(n( float3(y*.51+421.0+s, 	1., 1.0) ) + .0)   
                ;
            //v*= n( float3( (fragCoord.xy + float2(s,0.))*100.,1.0) );
           	v*= hash42(   float2(p.x +t*0.01, p.y) ).x +.3 ;
        
            
            v = pow(v+.3, 1.);
        	if(v<.7) v = 0.;  //threshold
            return v;
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxvhstape(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxvhstapeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 syamjaidtz;
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;

        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((0.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;
        
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        syamjaidtz /= scaleVec;
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 uv = syamjaidtz;
        
            float linesN = u.progressc; //fields per seconds
            float one_y = eng.acScreenSize.y / linesN; //field line
            uv = floor(uv*(float2(eng.acScreenSize.x, eng.acScreenSize.y))/one_y)*one_y;
        
            float col =  nn(uv);
            
            float4 bcol = mix(u.color1, u.color2, col);
                        
            __nv_out = bcol;
                    
    	float4 factor = mix(texColorX,__nv_out,1.0);

        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (newLayer(texColor, factor) * u.bright) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            factor *= u.bright;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = mix(texColor, resultfinal, u.alpha);
    	//
    return __nv_out;
}
