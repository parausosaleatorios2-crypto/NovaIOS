// ---------------------------------------------------------------------------
// Light Particle
// origem : assets/effects/toji-skexnxxpartx.xml
// id     : com.alightcreative.effects.partx
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxpartxParams {
    float4 colorfg;
    float4 colorbg;
    int autop;
    float EVO;
    float kStarDensity;
    float kMotionBlur;
    float kNumAngles;
    float scale;
    float2 positionn;
    float2 stretch;
    float bright;
    float alpha;
    float angle;
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
   
        float getBeat()
        {
            return 1.0;
        }
        
        #define k2PI (2.*3.14159265359)
   
   /////////////////////////

fragment float4 fx_toji_skexnxxpartx(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxpartxParams&  u    [[buffer(1)]],
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
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;

        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((0.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0+u.positionn.x), (0.0+u.positionn.y))*float2(-1.,1.)/500.;
        
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        syamjaidtz /= scaleVec;
        
        /////////////////////////
        
    	// float4 __nv_out;
    	
            float ff = getBeat();
            float2 resolution = iRes;
            float time = u.autop? u.EVO+(eng.acTime*0.5) : u.EVO;
              float2 p = syamjaidtz;
            p.x = p.x  * eng.acScreenSize.x/ eng.acScreenSize.y;
            float2 position = p;
            
            
            float speed = 5.2 + smoothstep(0.8,12.0,ff) ;
        
           
              //position += mouse - 0.5; // use this for mouse panning
        
              float A = __nv_atan(position.y, position.x);
              float angle0 = A / k2PI;
              float u.angle = fract(angle0 + .0002*time);
              float rad = .4*length(position);
              float angleFract = fract(u.angle*u.kNumAngles);
              float angleStep = floor(u.angle*u.kNumAngles);
              float angleToRandZ = 10.*fract(angleStep*fract(angleStep*.7535)*45.1);
              float angleSquareDist = fract(angleStep*fract(angleStep*.82657)*13.724);
              float t = speed * time - angleToRandZ;
              float angleDist = (angleSquareDist+0.1);
              float adist = angleDist/rad*u.kStarDensity;
              float dist = abs(fract((t*.1+adist))-.5);
              float white1 = max(0.,1.0 - dist * 100.0 / (u.kMotionBlur*speed+adist));
              float white2 = max(0.,(.5-.5*cos(k2PI * angleFract))*1./max(0.6,2.*adist*angleDist));
              float white = white1*white2;
              float4 __nv_out = mix(u.colorbg, u.colorfg, white);
              // float3 color;
              // color.r = .03*white1 + white*(0.3 + 5.0*angleDist);
              // color.b = white*(0.1 + .5*angleToRandZ);
              // color.g = 1.5*white;
              
              // __nv_out = float4( color, 0.0);
        
    	float4 factor = mix(texColorX,__nv_out,1.0);

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
        } else if( u.blendMode==3 ) {         // screen
            factor *= u.bright;
            resultfinal = (newLayer(texColor, factor) * u.bright) * texColor.a; }
            
    	__nv_out = mix(texColor, resultfinal, u.alpha);
    	//
    return __nv_out;
}
