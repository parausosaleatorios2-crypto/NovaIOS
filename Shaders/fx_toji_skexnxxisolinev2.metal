// ---------------------------------------------------------------------------
// Fractal Isoline
// origem : assets/effects/toji-skexnxxisolinev2.xml
// id     : com.alightcreative.effects.isolinev2
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxisolinev2Params {
    int autop;
    float PROGRESS;
    float SPEED;
    float scale;
    float angle;
    float2 position;
    float2 stretch;
    float alpha;
    float hardness;
    int blendMode;
    int GRADMAP;
    float4 color1;
    float4 color2;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        float2 hash( float2 p ) // replace this by something better
        {
        	p = float2( dot(p,float2(127.1,311.7)), dot(p,float2(269.5,183.3)) );
        	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
        }
        
        float noise( in float2 p )
        {
            const float K1 = 0.366025404; // (sqrt(3)-1)/2;
            const float K2 = 0.211324865; // (3-sqrt(3))/6;
        
        	float2  i = floor( p + (p.x+p.y)*K1 );
            float2  a = p - i + (i.x+i.y)*K2;
            float m = step(a.y,a.x); 
            float2  o = float2(m,1.0-m);
            float2  b = a - o + K2;
        	float2  c = a - 1.0 + 2.0*K2;
            float3  h = max( 0.5-float3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
        	float3  n = h*h*h*h*float3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
            return dot( n, float3(70.0) );
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxisolinev2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxisolinev2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> buff1 [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& buff1_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float2 iResolution = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 iMouse = float2(0.5, 0.5);
        float iTime = u.autop? u.PROGRESS + (eng.acTime*u.SPEED) : u.PROGRESS;
        
        float2 syamjaidtz;
        // syamjaidtz = in.acScreenNorm; 
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
            // ( fragCoord - 0.5*iResolution.xy ) / iResolution.y;
        	
            //uv = noised(uv*1.5 + iTime).rg;
            uv = float2(noise(uv+iTime*0.1), noise(uv+10.));
            //uv += iTime;
            float d = uv.x - uv.y;
            d *= 20.;
            d = sin(d);
            d = d * 0.5 + 0.5;
            d = 1.0 - d;
            
            d = smoothstep(0.1, 0.1, d);
            
            float3 col = float3(mix(float3(1.0, 1.0, 1.0), float3(0.0), d));
            // float3 col = float3(mix(float3(u.color1.rgb), float3(u.color2.rgb), d));
            // float3 col = float3(mix(float3(0.1), float3(0.2, 0.2, 0.6), d));
            //col = float3(noised(uv*10.)*0.5+0.5);
        
            __nv_out = float4(col,1.0);
        
    	    float4 factor = mix(texColorX,__nv_out,1.0);
    	    const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float luminance = dot(__nv_out.rgb, luminanceWeighting);
            float4 gradmap = mix(u.color1,u.color2,luminance)*__nv_out.a;
    	    if(u.GRADMAP) { factor = mix(texColorX,gradmap,1.0); }
    	    
    	    // float4 xbuffer = buff1.sample(__nv_smp, in.acScreenNorm.st);

        float4 resultfinal;
          if( u.blendMode==0 ) { resultfinal = (factor * u.hardness) * texColor.a; }
          else if( u.blendMode==1 ) { factor *= u.hardness;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a; }
            // resultfinal = min(factor, texColor) * texColor.a;
    return __nv_out;
}
