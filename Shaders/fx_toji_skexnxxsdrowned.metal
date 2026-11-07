// ---------------------------------------------------------------------------
// toji-skexnxxsdrowned.xml
// origem : assets/effects/toji-skexnxxsdrowned.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e64726f776e6564
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsdrownedParams {
    int autop;
    float SPEED;
    float2 position;
    float3 xxx;
    float2 rrr;
    float scale;
    float angle;
    float2 stretch;
    float PROGRESS;
    float bgalpha;
    float salpha;
    float alpha;
};

// --- funcoes auxiliares do efeito
//////////////////////////
    static float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    static float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    static float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        #define PI 		3.14159265359
        #define FOV 		60.0
        #define EPSILON		0.001
        #define MAX_STEPS	1000
        #define MAX_DIST	1000.0
        #define PLANE		float4 (0.0, 1.0, 0.0, 1.0)
        #define BOTTOM		float4 (0.0, 1.0, 0.0, 4.0)
        
        static float4 texture3D (sampler2D tex, float3 pt, float3 pn, float u.scale) {
        	return 
        		tex.sample(__nv_smp, pt.xy/u.scale) * abs (pn.z) +
        		tex.sample(__nv_smp, pt.xz/u.scale) * abs (pn.y) +
        		tex.sample(__nv_smp, pt.zy/u.scale) * abs (pn.x);
        }
        
        static float3x3 rotate_x (float fi) {
        	float cfi = cos (fi);
        	float sfi = sin (fi);
        	return float3x3 (
        		1.0, 0.0, 0.0,
        		0.0, cfi, -sfi,
        		0.0, sfi, cfi);
        }
        
        static float3x3 rotate_y (float fi) {
        	float cfi = cos (fi);
        	float sfi = sin (fi);
        	return float3x3 (
        		cfi, 0.0, sfi,
        		0.0, 1.0, 0.0,
        		-sfi, 0.0, cfi);
        }
        
        static float3x3 rotate_z (float fi) {
        	float cfi = cos (fi);
        	float sfi = sin (fi);
        	return float3x3 (
        		cfi, -sfi, 0.0,
        		sfi, cfi, 0.0,
        		0.0, 0.0, 1.0);
        }
        
        static float4 noise3v (float2 p) {
        	return noisexx.sample(__nv_smp, p);
        }
        
        static float4 fbm3v (float2 p) {
        	float4 f = float4 (0.0);
        	f += (float4 (0.5000) * noise3v (p)); p *= float2 (2.01);
        	f += (float4 (0.2500) * noise3v (p)); p *= float2 (2.02);
        	f += (float4 (0.1250) * noise3v (p)); p *= float2 (2.03);
        	f += (float4 (0.0625) * noise3v (p)); p *= float2 (2.04);
        	f /= float4 (0.9375);
        	return f;
        }
        
        static float dplane (float3 pt, float4 pl) {
        	return dot (pl.xyz, pt) + pl.w;
        }	
        
        static float map (float3 pt) {
        	return dplane (pt, PLANE);
        }
        
        static float map2 (float3 pt) {
        	return dplane (pt, BOTTOM);
        }
        
        static float march (float3 ro, float3 rd) {
        	float t = 0.0;
        	float d = 0.0;
        	float3 pt = float3 (0.0);
        	for (int i = 0; i < MAX_STEPS; ++i) {
        		pt = ro + rd * t;
        		d = map (pt); 
        		if (d < EPSILON || t + d >= MAX_DIST) {			
        			break;
        		}
        		t += d;
        	}
        	
        	return d <= EPSILON ? t : MAX_DIST;
        }
        
        static float march2 (float3 ro, float3 rd) {
        	float t = 0.0;
        	float d = 0.0;
        	float3 pt = float3 (0.0);
        	for (int i = 0; i < MAX_STEPS; ++i) {
        		pt = ro + rd * t;
        		d = map2 (pt); 
        		if (d < EPSILON || t + d >= MAX_DIST) {			
        			break;
        		}
        		t += d;
        	}
        	
        	return d <= EPSILON ? t : MAX_DIST;
        }
        
        static float fresnel_step (float3 I, float3 N, float3 f) {
        	return clamp(f.x + f.y * pow (1.0 + dot (I, N), f.z), 0.0, 1.0);
        }
    //////////////////////////

fragment float4 fx_toji_skexnxxsdrowned(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsdrownedParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> noisexx [[texture(0)]],
    texture2d<float> inputImg [[texture(1)]],
    texture2d<float> xcipher [[texture(2)]],
    constant NovaTexInfo& noisexx_info [[buffer(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(3)]],
    constant NovaTexInfo& xcipher_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        if( eng.acPass == 0 ) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm.st); } else if( eng.acPass==1 ) {
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float2 iResolution = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 iMouse = float2(0.5, 0.5);
        float iTime = eng.acTime;
        
        float2 syamjaidtz;
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
        
        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((-180.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0-u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        syamjaidtz /= scaleVec;
        
        /////////////////////////
        
    	float4 __nv_out;
    	
                float2 UVX = in.acScreenNorm;
        	float2 uv = syamjaidtz
        	            * tan (radians (FOV)/2.0)
        	            ;
        	float2 mo = PI * iMouse.xy / iResolution.xy;
        	
        	float3x3 rt = rotate_y (mo.x * PI);
        	
        	float3 up = float3 (0.0, (u.xxx.y*0.01)+2.8, 0.0) ;			// up 
        	float3 fw = float3 (0.65, (u.xxx.z*0.01)+0.1, (u.xxx.x*0.01)+0.4) *rt;			// forward
        	float3 lf = cross (up, fw); 					// left
        	
        	float3 ro = -fw * 5.0 + float3 (0.0, 5.0, 0.0); // ray origin
        	float3 rd = normalize (uv.x * lf + uv.y * up + fw) ; 		// ray direction
        	
        	float t = march (ro, rd);
        	float4 cm = inputImg.sample(__nv_smp, UVX)*u.bgalpha;
        	float3 pt = rd*t + ro;
        	
        	float3 pn = float3(u.rrr.x+0.45, 0.6, u.rrr.y);
        	// float3 pn = float3(zzz.x*0.01,zzz.y*0.01,zzz.z*0.01);
        	
        	float EVO = u.autop? (u.PROGRESS*3.5)+(iTime*u.SPEED) : u.PROGRESS*3.5;
        	float3 dv = fbm3v (pt.xz/512.0+EVO/512.0).xyz-0.5;
        	// float3 dv = fbm3v (pt.xz/512.0+iTime/512.0).xyz-0.5;
        	pn = normalize (pn + dv*0.2);
        	
        	float3 rfl = reflect (rd, pn);
        	// if(MIRROR) { 
        	rfl.y = 1.-rfl.y; 
        	// }
        	
        	float fs = fresnel_step (rd, pn, float3 (0.0, 3.0, 6.0));
        	float4 c0 = inputImg.sample(__nv_smp, rfl.zx);
        	float4 c1 = inputImg.sample(__nv_smp, UVX)*u.bgalpha;
        
        	__nv_out = mix(mix(c0, c1, 1.0 - fs), cm, smoothstep(80.0, 160.0, t));
        
    	float4 factor = mix(texColor, __nv_out, u.salpha);
            
    	__nv_out = (factor*u.alpha) * texColor.a;
          }
    return __nv_out;
}
