// ---------------------------------------------------------------------------
// toji-skexnxxsseascape.xml
// origem : assets/effects/toji-skexnxxsseascape.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e7365617363617065
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsseascapeParams {
    int nmode;
    float camprog;
    float camx;
    float camy;
    float progressa;
    float SEA_HEIGHT;
    float SEA_CHOPPY;
    float SEA_FREQ;
    float4 SEA_BASE;
    float4 SEA_WATER_COLOR;
    float4 CSKY;
    float4 SKYCOLOR;
    float NUM_STEPS;
    float ITER_FRAGMENT;
    float scale;
    float progressc;
    float2 position;
    float alpha;
    int adaptive;
};

// --- funcoes auxiliares do efeito
//////////////////////////
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
   
        // A documented, altered, recolored version of "Seascape".
        // The famous original at:
        // https://www.shadertoy.com/view/Ms2SD1
        
        // "Seascape" by Alexander Alekseev aka TDM - 2014
        
        const float PI	 	= 3.14159265358;
        const float EPSILON	= 1e-3;
        #define  EPSILON_NRM	(0.5 / eng.acScreenSize.x)
        
        // const int u.NUM_STEPS = 6;
        // const int ITER_GEOMETRY = 2;
        // const int u.ITER_FRAGMENT =5;
        
        // const float u.SEA_HEIGHT = 0.5;
        // const float u.SEA_CHOPPY = 3.0;
        // const float u.SEA_FREQ = 0.24;
        
        // const float3 u.SEA_BASE = float3(0.11,0.19,0.22);
        // const float3 u.SEA_WATER_COLOR = float3(0.55,0.9,0.7);
        
        #define SEA_TIME (u.progressa * 2.0)
        const float KEY_SP    = 32.5/256.0;
        
        float2x2 octave_m = float2x2(1.7,1.2,-1.2,1.4);
        
        float3 rgb2hsv(float3 c)
        {
            float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
            float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
        
            float d = q.x - min(q.w, q.y);
            float e = 1.0e-10;
            return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }
        
        float3 hsv2rgb(float3 c)
        {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }
        
        float3x3 fromEuler(float3 ang) {
        	float2 a1 = float2(sin(ang.x),cos(ang.x));
            float2 a2 = float2(sin(ang.y),cos(ang.y));
            float2 a3 = float2(sin(ang.z),cos(ang.z));
            float3x3 m;
            m[0] = float3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
        	m[1] = float3(-a2.y*a1.x,a1.y*a2.y,a2.x);
        	m[2] = float3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
        	return m;
        }
        
        float hash( float2 p ) {
            float h = dot(p,float2(127.1,311.7));	
            return fract(sin(h)*83758.5453123);
        }
        
        float noise( in float2 p ) {
            float2 i = floor( p );
            float2 f = fract( p );	
        
            float2 u = f*f*(3.0-2.0*f);
        
            return -1.0+2.0*mix( 
                        mix( hash( i + float2(0.0,0.0) ), 
                             hash( i + float2(1.0,0.0) ), 
                                u.x),
                        mix( hash( i + float2(0.0,1.0) ), 
                             hash( i + float2(1.0,1.0) ), 
                                u.x), 
                        u.y);
        }
        
        float diffuse(float3 n,float3 l,float p) {
            return pow(dot(n,l) * 0.4 + 0.6,p);
        }
        
        float specular(float3 n,float3 l,float3 e,float s) {    
            float nrm = (s + 8.0) / (3.1415 * 8.0);
            return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
        }
        
        float3 getSkyColor(float3 e) {
            e.y = max(e.y,0.0);
            float3 ret;
            ret.x = pow(1.0-e.y,2.0);
            ret.y = 1.0-e.y;
            ret.z = 0.6+(1.0-e.y)*0.4;
            ret *= u.SKYCOLOR.rgb;
            return ret;
        }
        
        float sea_octave(float2 uv, float choppy) {
            uv += noise(uv);
            float2 wv = 1.0-abs(sin(uv)); 
            float2 swv = abs(cos(uv));  
            wv = mix(wv,swv,wv);
            return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
        }
        
        float map(float3 p) {
            float freq = u.SEA_FREQ;
            float amp = u.SEA_HEIGHT;
            float choppy = u.SEA_CHOPPY;
            float2 uv = p.xz; uv.x *= 0.75;
            
            float d, h = 0.0;    
            for(int i = 0; i < 2; i++) {
            // for(int i = 0; i < int(ITER_GEOMETRY); i++) {
            	d = sea_octave((uv+SEA_TIME)*freq,choppy);
                h += d * amp; 
            	uv *=  octave_m;
                
                freq *= 1.9; 
                amp *= 0.22;
                choppy = mix(choppy,1.0,0.2);
            }
            return p.y - h;
        }
        
        float map_detailed(float3 p) {
            float freq = u.SEA_FREQ;
            float amp = u.SEA_HEIGHT;
            float choppy = u.SEA_CHOPPY;
            float2 uv = p.xz; uv.x *= 0.75;
            
            float d, h = 0.0;    
            for(int i = 0; i < int(u.ITER_FRAGMENT); i++) {
            	d = sea_octave((uv+SEA_TIME)*freq,choppy);
            	d += sea_octave((uv-SEA_TIME)*freq,choppy);
                
                h += d * amp;
                
            	uv *= octave_m/1.2;
                
                freq *= 1.9; 
                amp *= 0.22; 
                choppy = mix(choppy,1.0,0.2);
            }
            return p.y - h;
        }
        float3 getSeaColor(float3 p, float3 n, float3 l, float3 eye, float3 dist) {  
            float fresnel = 1.0 - max(dot(n,-eye),0.0);
            fresnel = pow(fresnel,3.0) * 0.45;
                
            float3 reflected = getSkyColor(reflect(eye,n))*0.99;
                  reflected *= u.CSKY.rgb;
            
            float3 refracted = u.SEA_BASE.rgb + diffuse(n,l,80.0) * u.SEA_WATER_COLOR.rgb * 0.27; 
            
            float3 color = mix(refracted,reflected,fresnel);
            
            float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
            color += u.SEA_WATER_COLOR.rgb * (p.y - u.SEA_HEIGHT) * 0.15 * atten;
            
            color += float3(specular(n,l,eye,90.0))*0.5;
            
            return color;
        }
        
        float3 getNormal(float3 p, float eps) {
            float3 n;
            n.y = map_detailed(p); // bteitler: Detailed height relative to surface, temporarily here to save a variable?
            n.x = map_detailed(float3(p.x+eps,p.y,p.z)) - n.y; // bteitler approximate X gradient as change in height along X axis delta
            n.z = map_detailed(float3(p.x,p.y,p.z+eps)) - n.y; // bteitler approximate Z gradient as change in height along Z axis delta
            n.y = eps; 
            return normalize(n);
        
        }
        
        
        float isKeyPressed(float key)
        {
        	return inputImg.sample(__nv_smp, float2(key, 1.0)).x;
        }
        
        float heightMapTracing(float3 ori, float3 dir, out float3 p) {  
            float tm = 0.0;
            float tx = 500.0; // bteitler: a really far distance, this could likely be tweaked a bit as desired
        
            float hx = map(ori + dir * tx);
            
            if(hx > 0.0) return tx;   
        
            float hm = map(ori + dir * tm); 
           
            float tmid = 0.0;
            for(int i = 0; i < int(u.NUM_STEPS); i++) { // bteitler: Constant number of ray marches per ray that hits the water
                tmid = mix(tm,tx, hm/(hm-hx));
                p = ori + dir * tmid; 
                          
            	float hmid = map(p); // bteitler: Re-evaluate height relative to ocean surface in Y axis
        
                if(hmid < 0.0) { // bteitler: We went through the ocean surface if we are negative relative to surface now
                    tx = tmid;
                    hx = hmid;
                } else {
                    tm = tmid;
                    hm = hmid;
                }
            }
        
            return tmid;
        }
    //////////////////////////

fragment float4 fx_toji_skexnxxsseascape(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsseascapeParams&  u    [[buffer(1)]],
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
        float2 syamjaidtz;
        if (u.adaptive) { 
        syamjaidtz = in.acScreenNorm; 
        }
        else { 
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
        }

        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((0.0)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 uv = syamjaidtz;
        
            uv = uv * 2.0 - 1.0; //  bteitler: Shift pixel coordinates from 0 to 1 to between -1 and 1
            uv.x *= eng.acScreenSize.x / eng.acScreenSize.y; // bteitler: Aspect ratio correction - if you don't do this your rays will be distorted
            float time = u.camprog * 2.7; // bteitler: Animation is based on time, but allows you to scrub the animation based on mouse movement
                
            float roll = PI + u.progressc ;
            // float roll = PI + sin(u.progressc)/14.0 + cos(u.progressc/2.0)/14.0 ;
            float pitch = PI*1.021 + (sin(1.0/2.0)+ cos(1.0))/40.0 
                + ((200.+u.camy)/eng.acScreenSize.y - .8)*PI/3.0  ;
            float yaw = u.camx/eng.acScreenSize.x * PI * 4.0;
            float3 ang = float3(roll,pitch,yaw);
            
            float3 ori = float3(0.0,3.5,time*3.0);
           
            float3 dir = normalize(float3(uv.xy,-1.6)); 
        
            dir = normalize(dir) * fromEuler(ang);
            
            float3 p;
            heightMapTracing(ori,dir,p);
        
            float3 dist = p - ori; // bteitler: distance vector to ocean surface for this pixel's ray
        
            float3 n = getNormal(p, 
                     dot(dist,dist)   // bteitler: Think of this as inverse resolution, so far distances get bigger at an expnential rate
                        * EPSILON_NRM // bteitler: Just a resolution constant.. could easily be tweaked to artistic content
                   );
        
            float3 light = normalize(float3(0.0,1.0,0.8)); 
                     
        	float3 skyColor = getSkyColor(dir);
            float3 seaColor = getSeaColor(p,n,light,dir,dist);
            
            seaColor /= sqrt(sqrt(length(dist))) ;
            
            
            bool night; 	 
            if( u.nmode )    //night mode!
            // if( isKeyPressed(KEY_SP) > 0.0 )    //night mode!
            {
            	seaColor *= seaColor * 8.5;
                
            	skyColor /= 1.69;
                
                night = true;
            }
            else  //day mode!
            {
            	seaColor *= sqrt(sqrt(seaColor)) * 4.0;
                skyColor *= 1.05;
                skyColor -= 0.03;
                night = false;
            }
        
            
            skyColor *= skyColor;
            
            
            float3 seaHsv = rgb2hsv(seaColor);
            if (seaHsv.z > .75 && length(dist) < 50.0)
               seaHsv.z -= (0.9 - seaHsv.z) * 1.3;
            seaColor = hsv2rgb(seaHsv);
            
            float3 color = mix(
                skyColor,
                seaColor,
            	pow(smoothstep(0.0,-0.05,dir.y), 0.3) // bteitler: Can be thought of as "fog" that gets thicker in the distance
            );
                
            __nv_out = float4(pow(color,float3(0.75)), 1.0);
            
            float3 hsv = rgb2hsv(__nv_out.xyz);    
            hsv.y += 0.131;
            hsv.z *= sqrt(hsv.z) * 1.1; 
            
            if (night)    
            {
                hsv.z -= 0.045;
                hsv*=0.8;
                hsv.x += 0.12 + hsv.z/100.0;
                hsv.y *= 2.87;
            }
            else
            {
                hsv.z *= 0.9;
                
                hsv.x -= hsv.z/10.0;
                hsv.x += 0.02 + hsv.z/50.0;
                hsv.z *= 1.01;
                hsv.y += 0.07;
            }
            
            __nv_out.xyz = hsv2rgb(hsv);
                    
    	__nv_out = mix(texColor, __nv_out, u.alpha) * texColor.a;
          }
    return __nv_out;
}
