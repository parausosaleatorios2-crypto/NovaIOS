// ---------------------------------------------------------------------------
// Snow Falling
// origem : assets/effects/toji-skexnxxsnowreal.xml
// id     : com.alightcreative.effects.snowreal
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsnowrealParams {
    int autop;
    float4 color1;
    float LAYERS;
    float EVO;
    float scale;
    float angle;
    float2 position;
    float2 stretch;
    float bright;
    float alpha;
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
   
   
   
   /////////////////////////

fragment float4 fx_toji_skexnxxsnowreal(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsnowrealParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 iRes = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float maxF = max(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 texelSize = 1.0 / float2(maxF, maxF);
        
        float2 syamjaidtz;
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;

        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((-180.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;
        
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        syamjaidtz /= scaleVec;
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            const float3x3 p = float3x3(13.323122,23.5112,21.71123,21.1212,28.7312,11.9312,21.8112,14.7212,61.3934);
            float2 MOUSE = float2(0.0);
        
            float2 uv = syamjaidtz;
            float PROGRESS = u.autop ? u.EVO * (eng.acTime*0.1) : u.EVO;
            // float2 uv = MOUSE.xy/u_resolution.xy + float2(1.,u_resolution.y/u_resolution.x)*fragCoord.xy / u_resolution.xy;
            float3 acc = float3(0.0);
            float dof = 5.*sin(PROGRESS*.1);
            for (float i=0.0;i<u.LAYERS;i++) {
                float fi = float(i);
                float2 q = uv*(1.+fi*0.2);
                q += float2(q.y*((PROGRESS/10.0)*__nv_mod(fi*7.238917, 1.)-(PROGRESS/10.0)*.5),0.8*PROGRESS/(1.+fi*0.2*.03));
                float3 n = float3(floor(q),31.189+fi);
                float3 m = floor(n)*.00001 + fract(n);
                float3 mp = (31415.9+m)/fract(p*m);
                float3 r = fract(mp);
                float2 s = abs(__nv_mod(q, 1.)-.5+.9*r.xy-.45);
                s += .01*abs(2.*fract(10.*q.yx)-1.); 
                float d = .6*max(s.x-s.y,s.x+s.y)+max(s.x,s.y)-.01;
                float edge = .005+.05*min(.5*abs(fi-5.-dof),1.);
                acc += float3(smoothstep(edge,-edge,d)*(r.x/(1.+.02*fi*0.2)));
            }
            acc.rgb *= u.color1.rgb;
            __nv_out = float4(float3(acc),1.0);
        
    	float4 factor = mix(texColorX,__nv_out,1.0);

        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (factor * u.bright) * texColor.a;
            // resultfinal = (newLayer(texColor, factor) * u.bright) * texColor.a;
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
