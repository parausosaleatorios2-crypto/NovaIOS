// ---------------------------------------------------------------------------
// VCR Distortion+
// origem : assets/effects/toji-skexnxxvcr.xml
// id     : com.alightcreative.effects.vcr
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxvcrParams {
    float4 color2;
    float progressa;
    float progressb;
    float lowThreshold;
    float scale;
    float alpha;
    float angle;
    int mode;
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
    
   #define fragCoord __nv_fragCoord
    
   /////////////////////////
   
   float3 mod289(float3 x) {
      return x - floor(x * (1.0 / 289.0)) * 289.0;
    }
    
    float2 mod289(float2 x) {
      return x - floor(x * (1.0 / 289.0)) * 289.0;
    }
    
    float3 permute(float3 x) {
      return mod289(((x*34.0)+1.0)*x);
    }
    
    float snoise(float2 v)
      {
      const float4 C = float4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                          0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                         -0.577350269189626,  // -1.0 + 2.0 * C.x
                          0.024390243902439); // 1.0 / 41.0
    // First corner
      float2 i  = floor(v + dot(v, C.yy) );
      float2 x0 = v -   i + dot(i, C.xx);
    
      float2 i1;
      i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
      float4 x12 = x0.xyxy + C.xxzz;
      x12.xy -= i1;
    
      i = mod289(i); // Avoid truncation effects in permutation
      float3 p = permute( permute( i.y + float3(0.0, i1.y, 1.0 ))
    		+ i.x + float3(0.0, i1.x, 1.0 ));
    
      float3 m = max(0.5 - float3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
      m = m*m ;
      m = m*m ;
    
      float3 x = 2.0 * fract(p * C.www) - 1.0;
      float3 h = abs(x) - 0.5;
      float3 ox = floor(x + 0.5);
      float3 a0 = x - ox;
    
      m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    
      float3 g;
      g.x  = a0.x  * x0.x  + h.x  * x0.y;
      g.yz = a0.yz * x12.xz + h.yz * x12.yw;
      return 130.0 * dot(m, g);
    }
    
    float rand(float2 co)
    {
       return fract(sin(dot(co.xy,float2(12.9898,78.233))) * 43758.5453);
    }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxvcr(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxvcrParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> black [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& black_info [[buffer(3)]])
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

        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((0.0+u.angle)*0.0174533);
        // syamjaidtz += float2((0.0+position.x), (0.0+position.y))*float2(-1.,1.)/500.;

        
        /////////////////////////
    	
        float4 __nv_out;
        float2 uv = syamjaidtz;
        float time = u.progressa * 2.0;
        
        // Create large, incidental noise waves
        float noise = max(0.0, snoise(float2(time, uv.y * 0.3)) - 0.3) * (1.0 / 0.7);
        
        // Offset by smaller, constant noise waves
        noise = noise + (snoise(float2(time*10.0, uv.y * 2.4)) - 0.5) * 0.15;
        
        // Apply the noise as x displacement for every line
        float xpos = uv.x - noise * noise * 0.25;
    	__nv_out = black.sample(__nv_smp, float2(xpos, uv.y));
        
        // Mix in some random interference for lines
        __nv_out.rgb = mix(__nv_out.rgb, float3(rand(float2(uv.y * time))), noise * u.progressb).rgb;
        
        // Apply a line pattern every 4 pixels
        if (floor(__nv_mod(fragCoord.y * 0.25, 2.0)) == 0.0)
        {
            __nv_out.rgb *= 1.0 - (0.15 * noise);
        }
        
        // Shift green/blue channels (using the red channel)
        __nv_out.g = mix(__nv_out.r, black.sample(__nv_smp, float2(xpos + noise * 0.05, uv.y)).g, 0.25);
        __nv_out.b = mix(__nv_out.r, black.sample(__nv_smp, float2(xpos - noise * 0.05, uv.y)).b, 0.25);
        
            const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float4 gradmap;
            float luminance = dot(__nv_out.rgb, luminanceWeighting);
            gradmap = mix(float4(0.05,0.05,0.05,1.0),u.color2,luminance)*__nv_out.a;
        
    	
            float4 targetLuma = gradmap;
            float luma = dot(targetLuma.rgb, luminanceWeighting);
            float lowThresholdB = (u.lowThreshold*(1.0+1.0))-0.001;
            float lowThresholdA = lowThresholdB-max(1.0, 0.00001);
            float highThresholdA = (1.0*(1.0+1.0)-1.0)+0.001;
            float highThresholdB = highThresholdA+max(1.0, 0.00001);
            float lowBlend = smoothstep( lowThresholdA, lowThresholdB, luma );
            float highBlend = 1. - smoothstep( highThresholdA, highThresholdB, luma );
            float lumafx = min(lowBlend,highBlend);
            float4 fxLuma = targetLuma*lumafx;
            
    	// __nv_out = gradmap * texColor.a;
    	__nv_out = (u.mode? max(texColor, fxLuma) : newLayer(texColor, fxLuma)) * texColor.a;
    	// __nv_out = resultfinal;
    return __nv_out;
}
