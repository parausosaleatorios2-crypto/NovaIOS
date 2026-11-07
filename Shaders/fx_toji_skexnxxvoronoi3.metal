// ---------------------------------------------------------------------------
// Shape Voronoi
// origem : assets/effects/toji-skexnxxvoronoi3.xml
// id     : com.alightcreative.effects.voronoi3
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxvoronoi3Params {
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
float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        float max_abs(float2 p)
        {
            return max(abs(p.x), abs(p.y));
        }
        
        
        float2 voronoi_noise_randomVector(float2 UV, float2 offset)
        {
        	float2x2 m = 	float2x2(15.27, 47.63, 99.41, 89.98);
        	UV = fract(sin(UV* m) * 46839.32);
        float iTime = u.autop? u.PROGRESS + (eng.acTime*u.SPEED) : u.PROGRESS;
        	return float2(sin(UV.y * +offset.x*cos(iTime/3.)) * 0.5 + 0.5, cos(UV.x * offset.y*sin(iTime/20.)) * 0.5 + 0.5);
        }
        
        void ChebychevVoronoi(float2 UV, float2 AngleOffset, float2 CellDensity, out float Out, out float Cells, out float Lines,out float Points)
        {
        	float2 g = floor(UV * CellDensity);
        	float2 f = fract(UV * CellDensity);
        	
        	float res = 8.0;
        	float md=8.0;
            float2 mr;
        	for (int y = -1; y <= 1; y++)
         	{
        	    for (int x = -1; x <= 1; x++)
        		{
        		    float2 lattice = float2(x, y);
                    float2 offset = voronoi_noise_randomVector(lattice + g, AngleOffset);
                    float2 r = lattice +offset -f;
                    float d = max_abs(r);
        			if (d < res)
        			{
        			    res = d;
                        mr=r;
        			}
        		}
        	}
            res = 8.0;
        	for (int y = -1; y <= 1; y++)
         	{
        	    for (int x = -1; x <= 1; x++)
        		{
        		    float2 lattice = float2(x, y);
                    float2 offset = voronoi_noise_randomVector(lattice + g, AngleOffset);
                    float2 r = lattice +offset -f;
                   	float d = max_abs(r);
        			if (d < res)
        			{
        			    res = d;
        			    Out = res;
        			    Cells = offset.x;
        			}
        			if( dot(mr-r,mr-r)>0.00001)
        			{
                        md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
        			}
        		}
        	}
        	Lines = mix(1.0, 0.0, smoothstep( 0.03, 0.06, md ));
        	Points =1.0-smoothstep( 0.0, 0.3, res );
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxvoronoi3(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxvoronoi3Params&  u    [[buffer(1)]],
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
        // float iTime = u.autop? u.PROGRESS + (eng.acTime*u.SPEED) : u.PROGRESS;
        
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
    	
            float2 p = syamjaidtz;
            float3 col;
            float a,b,c,d;
            ChebychevVoronoi(p,float2(7.0),float2(5.0,5.0),a,b,c,d);
            col=float3(b);
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
