// ---------------------------------------------------------------------------
// Electric Rough
// origem : assets/effects/toji-skexnxxelectricrough.xml
// id     : com.alightcreative.effects.electricrough
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxelectricroughParams {
    float2 position;
    float progressa;
    float progressb;
    float progressd;
    float progresse;
    float scale;
    float bright;
    float alpha;
    float angle;
    float4 color1;
    float4 color2;
    float4 color3;
    float4 color4;
    int blendMode;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) {
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
   
        #define PHASE_POWER 1.0
        
        float2 hash2( float2 p )
        {
        	// texture based white noise
        	return iChannel0.sample(__nv_smp, (p+0.5)/256.0).xy;
        	
            // procedural white noise	
        	//return fract(sin(float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3))))*43758.5453);
        }
        
        float4 voronoi( in float2 x )
        {
            float2 n = floor(x);
            float2 f = fract(x);
        	float2 o;
            //----------------------------------
            // first pass: regular voronoi
            //----------------------------------
        	float2 mg, mr;
        	float oldDist;
            
            float md = 8.0;
            for( int j=-1; j<=1; j++ )
            for( int i=-1; i<=1; i++ )
            {
                float2 g = float2(float(i),float(j));
        		o = hash2( n + g );
                float2 r = g + o - f;
                float d = dot(r,r);
        
                if( d<md )
                {
                    md = d;
                    mr = r;
                    mg = g;
                }
            }
        	
            oldDist = md;
            
            //----------------------------------
            // second pass: distance to borders
            //----------------------------------
            md = 8.0;
            for( int j=-2; j<=2; j++ )
            for( int i=-2; i<=2; i++ )
            {
                float2 g = mg + float2(float(i),float(j));
        		o = hash2( n + g );
                float2 r = g + o - f;
        
                if( dot(mr-r,mr-r)>0.00001 )
                md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
            }
        
            return float4( md, mr, oldDist );
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxelectricrough(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxelectricroughParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    texture2d<float> iChannel0 [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]],
    constant NovaTexInfo& iChannel0_info [[buffer(4)]])
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
        syamjaidtz += float2((0.0+u.position.x), (250.0+u.position.y))*float2(-1.,1.)/500.;

        
        /////////////////////////
        
        // if(u.progressa <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); }
        // else if(u.progressa >= 0.0001) { 

    	float4 __nv_out;
    	
            float2 uv = syamjaidtz;
            float pauseFreq = u.progressd;
            float pauseScale = 1.0; // range 0-1
            float scaledTime = u.progressb * 0.50;
            scaledTime += 0.05*uv.x;
            float sinTime = sin(pauseFreq*scaledTime);
            float sinTimeOffset = sin(pauseFreq*scaledTime - 0.5*3.141);
            float timeStep = scaledTime + pauseScale*(sinTime/pauseFreq);
            
            float2 p = uv;
            float4 c;
            
            
            p *= 4.0;
            // p.x += - timeStep*6.0;
            // p.y += - timeStep*3.0;    
            p.x = 0.5 - timeStep*3.0;
            p.y = 0.5 - timeStep*3.0; 
            c = voronoi( p );
            
            float cellPos = (p.y+c.z)+ timeStep*3.0;
            // uv.x += 0.5*(2.0 * cellPos-1.0) * (uv.y-0.5);
            uv.x += 1.5*(2.0 * c.x-0.33) * (uv.y-0.5);
        	// __nv_out = float4(2.5*(2.0 * cellPos-1.0) * (uv.y-0.5)); return __nv_out;
            
            
            uv.x *= 0.25; 
            p = uv;
            p.y = max(p.y, 0.5); 
            p *= 12.0; // higher values zoom out further - don't go too high or the sine waves will become quite obvious...
            p.x += timeStep*16.0;
            p.y += timeStep*32.0;
            c = voronoi( p );
            // c.x = 1.0-pow(1.0-c.x, 2.0);
            
            
        	__nv_out = 0.5*float4(c.x);
            
            float d = 0.0;
            float edgeScale = 1.0-2.0*abs(u.progressa - 0.5);
            //edgeScale = fragCoord.x/iResolution.x ;
            float scaleMulti = pow(0.5*sinTime + 0.5, 2.0);
        	float dScale = 2.0 * edgeScale * (0.25+0.75*pow(0.5*sinTimeOffset + 0.5, 2.0));
            
            p.y = 0.5*12.0 + timeStep*3.0;
            c = dScale*voronoi( p );
            // float d = 1.0-abs(uv.y-c.x-0.25);
            d = (uv.y+c.x-0.75);
            
            p.x = uv.x*12.0 - timeStep*6.0;
            p.y = 4.5*12.0 - timeStep*3.0;
            c = dScale*voronoi( p );
            d = mix(d, (uv.y-c.x-0.25), 0.5);
            
            
            d = 1.0-abs(d);
            
            __nv_out = float4(d);
            //float lineWidth *= 1.0- pow(1.0-(0.5*sinTimeOffset + 0.5), 2.0);
            float lineWidth = d+u.progresse*scaleMulti *edgeScale;
        
        	__nv_out = mix(float4(u.color2), float4(u.color3), scaleMulti) * smoothstep(1.0, 1.005, lineWidth);
        	//__nv_out += edgeScale*float4(1,1,1.0,1 ) * smoothstep(1.0, 1.005, lineWidth);
            
            __nv_out += edgeScale*pow(scaleMulti*smoothstep(0.75, 1.005, lineWidth), 16.0) * 0.5*float4(u.color4) ;
            
            __nv_out += u.color1;
        
            // const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            // float4 gradmap;
            // float luminance = dot(__nv_out.rgb, luminanceWeighting);
            // gradmap = mix(u.color1,u.color2,luminance)*__nv_out.a;
        
    	// float4 factorx = mix(__nv_out,gradmap,alphab);
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
        }
            
    	float4 gfinal = mix(texColor, resultfinal, u.alpha);
    	
    	__nv_out = newLayer(texColor, gfinal) * texColor.a;
    	// }
    return __nv_out;
}
