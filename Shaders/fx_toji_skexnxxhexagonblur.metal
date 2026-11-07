// ---------------------------------------------------------------------------
// Hexagon Blur
// origem : assets/effects/toji-skexnxxhexagonblur.xml
// id     : com.alightcreative.effects.hexagonblur
// passes : 2  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxhexagonblurParams {
    float NUM_SAMPLES;
    float STRENGTH;
    float hardness;
    float alpha;
    float iter;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        // const int u.NUM_SAMPLES = 16;
        float3 srgb2lin(float3 c) { return c*c; }
        float3 lin2srgb(float3 c) { return sqrt(c); }
        
        float hash12n(float2 p)
        {
        	p  = fract(p * float2(5.3987, 5.4421));
            p += dot(p.yx, p.xy + float2(21.5351, 14.3137));
        	return fract(p.x * p.y * 95.4307);
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxhexagonblur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxhexagonblurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xdist [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xdist_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float2 iResolution = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm; 
                
        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 uv = syamjaidtz;
        
           	float3 sumcol0 = float3(0.0);
            {
                float2 blurdir = float2( 1.0, 0.577350269189626 );
            	float2 blurvec = normalize(blurdir) / iResolution.xy;
                float2 p0 = uv - 0.5 * u.STRENGTH * blurvec;
            	float2 p1 = uv + 0.5 * u.STRENGTH * blurvec;
            	float2 stepvec = (p1-p0) / u.NUM_SAMPLES;
            	float2 p = p0;
            
                for (int i=0;i<int(u.NUM_SAMPLES);++i)
                {
                    sumcol0 += srgb2lin( inputImg.sample(__nv_smp, p).rgb);
                    p += stepvec;
                }
                sumcol0 /= float(u.NUM_SAMPLES);
            }
            
            float3 sumcol1 = float3(0.0);
            {
                float2 blurdir = float2( -1.0, 0.577350269189626 );
                float2 blurvec = normalize(blurdir) / iResolution.xy;
                float2 p0 = uv - 0.5 * u.STRENGTH * blurvec;
                float2 p1 = uv + 0.5 * u.STRENGTH * blurvec;
                float2 stepvec = (p1-p0) / u.NUM_SAMPLES;
                float2 p = p0;
        
                for (int i=0;i<int(u.NUM_SAMPLES);++i)
                {
                    sumcol1 += srgb2lin( inputImg.sample(__nv_smp, p).rgb);
                    p += stepvec;
                }
                sumcol1 /= u.NUM_SAMPLES;
            }
        
            float3 sumcol = min( sumcol0, sumcol1 );
            
            __nv_out = float4( lin2srgb(sumcol), 1.0 );
        
    	float4 factor = mix(texColorX,__nv_out,1.0);

        float4 resultfinal;
        resultfinal = (factor * u.hardness) * texColor.a;
            
    	__nv_out = mix(texColor, resultfinal, u.alpha);
    	//
    return __nv_out;
}
