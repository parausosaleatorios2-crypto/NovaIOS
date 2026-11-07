// ---------------------------------------------------------------------------
// SpeedLines+
// origem : assets/effects/toji-skexnxxspeedlines.xml
// id     : com.alightcreative.effects.speedlines
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxspeedlinesParams {
    int blendMode;
    float4 color;
    float progressa;
    float density;
    float highlight;
    float feather;
    float scalex;
    float2 position;
    float angle;
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
    
   /////////////////////////
    
    #define scale 1.7 * u.scalex
    
    float hash( float2 p ) {return fract(sin(dot(p,float2(127.1,311.7)))*43758.5453123);} //Pseudo-random
    float smoothNoise( in float2 p) { //Bilinearly interpolated noise (4 samples)
        float2 i = floor( p ); float2 f = fract( p );	
    	float2 u = f*f*(3.0-2.0*f);
        float a = hash( i + float2(0.0,0.0) );
    	float b = hash( i + float2(1.0,0.0) );
    	float c = hash( i + float2(0.0,1.0) );
    	float d = hash( i + float2(1.0,1.0) );
        return float(a+(b-a)*u.x+(c-a)*u.y+(a-b-c+d)*u.x*u.y)/4.;
    }
    //Funciton to make the noise continuous while wrapping around u.angle 
    float rotatedMirror(float t, float r){
        //t : 0->1
        t = fract(t+r);
        return 2.*abs(t-0.5);
    }
    //Some continous radial perlin noise
    const float2x2 m2 = float2x2(0.90,0.44,-0.44,0.90);
    float radialPerlinNoise(float t, float d){
        const float BUMP_MAP_UV_SCALE = 44.2;
        d = pow(d,0.01); //Impression of speed : stretch noise as the distance increases.
        float dOffset = -floor(u.progressa*10.)*0.1; //Time drift (animation)
        float2 p = float2(rotatedMirror(t,0.1),d+dOffset);
        float f1 = smoothNoise(p*BUMP_MAP_UV_SCALE);
        p = 2.1*float2(rotatedMirror(t,0.4),d+dOffset);
        float f2 = smoothNoise(p*BUMP_MAP_UV_SCALE);
        p = 3.7*float2(rotatedMirror(t,0.8),d+dOffset);
        float f3 = smoothNoise(p*BUMP_MAP_UV_SCALE);
        p = 5.8*float2(rotatedMirror(t,0.0),d+dOffset);
        float f4 = smoothNoise(p*BUMP_MAP_UV_SCALE);
        return (f1+0.5*f2+0.25*f3+0.125*f4)*3.;
    }
    //Colorize function (transforms BW Intensity to u.color)
    float3 colorize(float f){
        f = clamp(f*.95,0.0,1.0);
        float3 c = mix(float3(0,0,0), float3(u.color.rgb), f); //Red-Yellow Gradient
             c = mix(c, float3(1,1,1), f*4.-3.0);      //While highlights
        float3 cAttenuated = mix(float3(0), c, f+0.1);       //Intensity ramp
        return cAttenuated;
    }

fragment float4 fx_toji_skexnxxspeedlines(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxspeedlinesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> black [[texture(1)]],
    texture2d<float> white [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& black_info [[buffer(3)]],
    constant NovaTexInfo& white_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
                        
        /////////////////////////
        
    	float4 result;
    	
    	float2 uv = in.acScreenNorm;
        uv += float2((250.0+u.position.x), (-250.0+u.position.y))*float2(-1.,1.)/500.;
        uv *= scale;
        uv *= rot2m(u.angle*0.0174533);

        
    	// float2 uv = 2.2*(fragCoord-0.5*float2(iResolution.xy))/iResolution.xx;
        float d = dot(uv,uv); //Squared distance
        float t = 0.5+__nv_atan(uv.y, uv.x)/u.density; //Normalized Angle
        float v = radialPerlinNoise(t,d);
        //Saturate and offset values
        v = -2.38+v*u.highlight;
        //Intersity ramp from center
        v = mix(0.0,v, 0.5*smoothstep(0.3, (0.35+u.feather), d));
        //Colorize (palette remap )
        
        result.rgb = colorize(v);
        
        float4 nx = mix(float4(0), u.color, v) * texColor.a;
        float4 nxx = mix(float4(1), u.color, v) * texColor.a;
        
    	// float4 factor = float4(0.30,0.30,0.30,1.0) + gradmap;
    	float4 factora = float4(0.30,0.30,0.30,1.0) + result;
    	
    	    const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float4 gradmap;
            float luminance = dot(factora.rgb, luminanceWeighting);
                
        // gradmap = mix(colorbg,u.color,luminance)*factora.a;
        // float4 factor = gradmap;
        float4 resultfinal;
        if( u.blendMode==0 ) {                // SOLID
            
           float4 rrr = newLayer(float4(0,0,0,1), nx) * texColor.a;
           
            float4 targetLuma = rrr;
            const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float luma = dot(targetLuma.rgb, luminanceWeighting);
            float lowThresholdB = (0.4*(1.0+0.05))-0.001;
            float lowThresholdA = lowThresholdB-max(0.05,0.00001);
            float highThresholdA = (1.0*(1.0+0.05)-0.05)+0.001;
            float highThresholdB = highThresholdA+max(0.05,0.00001);
            float lowBlend = smoothstep( lowThresholdA, lowThresholdB, luma );
            float highBlend = 1. - smoothstep( highThresholdA, highThresholdB, luma );
            float lumafx = min(lowBlend,highBlend);
            float4 fxLuma = targetLuma*lumafx;
            
           resultfinal = newLayer(texColor, fxLuma) * texColor.a;
           // resultfinal = newLayer(texColor, nx) * texColor.a;
            
        }
         else if( u.blendMode==1 ) {         // MASK
            gradmap = mix(float4(1.0),u.color,luminance)*nxx.a;
            float4 factor = gradmap;
            
            float3 top = texColor.rgb;
            float3 bot = nxx.rgb * texColor.a;

            float3 mx = min(top,bot);
            resultfinal = float4(mx,texColor.a);
            // float4 c = (factora + float4(1.)*(1.-factora.a));
            // resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        }
         else if( u.blendMode==2 ) {         // OUTLINE
            gradmap = mix(float4(0.,0.,0.,1.0),u.color,luminance)*factora.a;
            float4 factor = gradmap;
            
            float3 top = texColor.rgb;
            float3 bot = result.rgb * texColor.a;

            float3 mx = max(top,bot);
            resultfinal = float4(mx,texColor.a);
            // resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = mix(texColor,resultfinal,u.alpha) * texColor.a;
    return __nv_out;
}
