// ---------------------------------------------------------------------------
// Eclipse
// origem : assets/effects/toji-skexnxxeclipse.xml
// id     : com.alightcreative.effects.eclipse
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxeclipseParams {
    float4 color1;
    float4 color2;
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
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) { return a * (1.0 - b.a) + b;  }
    float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    float2 l2s( float2 v ) { return (float4(v,0.0,1.0)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        #define PI 3.14159265
        
        float circle(float2 uv, float blur) {
            return smoothstep(0.0, blur, 1.0 - length(uv));
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxeclipse(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxeclipseParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xDistBuf [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xDistBuf_info [[buffer(3)]])
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
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((0.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.0,1.0)/500.0;
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        syamjaidtz /= scaleVec;
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 uv = syamjaidtz;
            
            if(eng.acPass==0) {
            
            float circleWhite = circle(uv * 2.45, 1.0);
            float circleBlack = circle(uv * 2.86, 0.7);
            float c = circleWhite - circleBlack;
            c *= 6.0;
            
            float t = iTime * 5.0;
            c -= circle(float2(uv.x - sin(t) * 0.85, 1.8*uv.y - cos(t) * 0.65) * 0.8, 1.0); 
            
            float3 col = float3(c) * float3(1.0, 0.0, 0.5);
            col += float3(smoothstep(0.2, 0.7, c)) * float3(1.0, 1.0, 0.0);
            col += float3(smoothstep(0.4, 0.55, c));
            
            __nv_out = float4(col,1.0); 
            } else {
        
    	    float4 xbuffer = xDistBuf.sample(__nv_smp, in.acScreenNorm.st);
    	
    	    const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float4 gradmap;
            float luminance = dot(xbuffer.rgb, luminanceWeighting);
            gradmap = mix(u.color1,u.color2,luminance)*xbuffer.a;
    	    float4 factor = mix(texColorX,gradmap,1.0);

        float4 resultfinal;
          if( u.blendMode==0 ) {
            resultfinal = (factor * u.hardness) * texColor.a; }
          else if( u.blendMode==1 ) { factor *= u.hardness;
            float4 c = factor + float4(1.0)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a; }
          else if( u.blendMode==2 ) { factor *= u.hardness; 
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a; }
          else if( u.blendMode==3 ) { factor *= u.hardness; 
            resultfinal = (newLayer(texColor, factor) * u.hardness) * texColor.a; }
            
    	__nv_out = mix(texColor, resultfinal, u.alpha) * texColor.a;
    	}
    return __nv_out;
}
