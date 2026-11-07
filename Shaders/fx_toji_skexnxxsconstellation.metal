// ---------------------------------------------------------------------------
// toji-skexnxxsconstellation.xml
// origem : assets/effects/toji-skexnxxsconstellation.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e636f6e7374656c6c6174696f6e
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsconstellationParams {
    float4 color1;
    float PROGRESS;
    float scale;
    float2 position;
    float2 stretch;
    float bright;
    float alpha;
    float anglex;
    int new;
    int autop;
    int autor;
    int blendMode;
};

// --- funcoes auxiliares do efeito
//////////////////////////
    static float4 newLayer( float4 a, float4 b) {
    return a * (1. - b.a) + b;
    }
    
    static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    static float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
           
        #define s(a,b,c) smoothstep(a,b,c)
        #define S(a, b, t) smoothstep(a, b, t)
        
        static float rand(float2 co) {
            return fract(cos(__nv_mod(dot(co.xy+0.12,float2(12.9898,78.233)), 3.14))*43758.5453);
        }
        static float3 rand3(float2 co){
        	float t=rand(co);
        	float z=rand(co+t);
        	return float3(t,z,rand(co+z));
        }
        static float3 getpoint(float2 id){
                float EVO = u.autop? u.PROGRESS+(eng.acTime*1.5) : u.PROGRESS;
        	float3 r=rand3(id);
        	float3 ou=float3(
        		sin(EVO*r.x),
        		cos(EVO*r.y),
        		sin(EVO*r.z*10.)
        	);
        	return ou*0.45+0.5;
        }
        
        static float line(float2 uv, float2 p, float2 p2){
        	float2 n=uv-p;
        	float2 w=p2-p;
        	float r=clamp(dot(n,w)/dot(w,w),0.,1.);
        	r=length(n-w*r);
               return clamp(s(0.04,0.01,r)*(s(0.6,1.,1./distance(p,p2))),0.,1.);
        }
        
        //////////////////////////
        
        static float N21(float2 p)
        {
            p = fract(p*float2(651.34, 237.73));
            p += dot(p, p + 23.45);
            return fract(p.x*p.y);
        }
        
        static float2 N22(float2 p)
        {
            float n = N21(p);
            return float2(n, N21(p+n));
        }
        
        static float2 GetGridPoint(float2 id, float2 offs)
        {
            float EVOX = u.autop? u.PROGRESS+(eng.acTime*1.5) : u.PROGRESS;
            float2 n = N22(id + offs) * EVOX;
            
            return offs + sin(n) * .3;
        }
        
        static float DistToLine(float2 p, float2 a, float2 b)
        {
            float2 pa = p-a;
            float2 ba = b-a;
            float t = clamp(dot(pa, ba)/dot(ba,ba),0.,1.);
            return length(pa - ba*t);
        }
        
        static float LineX(float2 p, float2 a, float2 b)
        {
            float d = DistToLine(p, a, b);
            float m = S(.05, .005, d);
            m *= S(1.1,.6,length(a - b));
            return m;
        }
    //////////////////////////

fragment float4 fx_toji_skexnxxsconstellation(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsconstellationParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xcipher [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xcipher_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        if( eng.acPass == 0 ) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm.st); } else if( eng.acPass==1 ) {
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float2 iRes = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        
        float2 syamjaidtz;
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;

        syamjaidtz /= u.scale;
        float angle = u.autor? u.anglex+(eng.acTime*10.0) : u.anglex;
        syamjaidtz *= rot2m((0.0+angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;
        
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        syamjaidtz /= scaleVec;
        
        /////////////////////////
        
    	float4 sparkx;
    	
            float2 uv = syamjaidtz;

            if(u.new) {
            float2 id=floor(uv);
            float2 c=fract(uv);
        
            float2 p[9];
        	float col=0.;
            int i=0;
            for(float n=-1.;n<=1.;n++){
                for(float w=-1.;w<=1.;w++){
        			float2 nc=id+float2(w,n);
        			float3 point=getpoint(nc);
        			p[i]=point.xy+float2(w,n);
        			float2 a=(p[i].xy-c)*10.;
        			col+=pow(point.z/dot(a,a),2.2);
                    i++;
        		}
        	}
            
            for(int i=0;i<9;i++){
        		col+=pow(line(c,p[i].xy,p[4].xy),2.2);
        	}
        	col+=pow(line(c,p[1].xy,p[3].xy),2.2);
        	col+=pow(line(c,p[1].xy,p[5].xy),2.2);
        	col+=pow(line(c,p[7].xy,p[3].xy),2.2);
            col+=pow(line(c,p[7].xy,p[5].xy),2.2);
        	
            col=pow(col,1./2.2);
            col*=col;
            col*=0.5;
            
            float3 xnxx = float3(col);
            xnxx *= u.color1.rgb;
            
            sparkx = float4(xnxx,1.0); }
            
            //////////////////////////
            
            // float2 uv = syamjaidtz;
            else {
            float2 index = floor(uv);
        	float2 gridUv = fract(uv) - .5;
            
            float2 px[9];
            
            int i = 0;
            for(float y =-1. ;y <=1. ; y++)
            {
                for(float x =-1. ;x <=1. ; x++)
                {
                    px[i++] = GetGridPoint(index, float2(x,y));
                }
            }
            
            float result = 0.;
            for(int i=0; i< 9; i++)
            {
                result += LineX(gridUv, px[4], px[i]);
                
            }
            result += LineX(gridUv, px[1], px[3]);
            result += LineX(gridUv, px[1], px[5]);
            result += LineX(gridUv, px[3], px[7]);
            result += LineX(gridUv, px[5], px[7]);    
            
            float3 colx = float3(result);
            colx *= u.color1.rgb;
                        
            sparkx = float4(colx,1.0); }
            
    	float4 factor = mix(texColorX,sparkx,1.0);
    	// float4 factor = mix(texColorX,__nv_out,1.0);

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
          }
    return __nv_out;
}
