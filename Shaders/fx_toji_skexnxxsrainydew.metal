// ---------------------------------------------------------------------------
// toji-skexnxxsrainydew.xml
// origem : assets/effects/toji-skexnxxsrainydew.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e7261696e79646577
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsrainydewParams {
    int xnxx;
    float progress;
    float scaleuv;
    float alpha;
    float angle;
    float2 position;
    float2 space;
    float scalex;
    float scaley;
    float scalez;
    float alpx;
    float alpy;
    int xxx;
    int lightfx;
    float aai;
};

// --- funcoes auxiliares do efeito
//////////////////////////
    static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    static float2 l2s( float2 v ) {
        return (float4(v,0.0,1.0)*eng.acLayerToScreen).xy;
    }
    
    #define fragCoord __nv_fragCoord
    #define S(a, b, t) smoothstep(a, b, t)
    
   /////////////////////////
       
    static float3 N13(float p) {
        //  from DAVE HOSKINS
       float3 p3 = fract(float3(p) * float3(0.1031,.11369,.13787));
       p3 += dot(p3, p3.yzx + 19.19);
       return fract(float3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
    }
    
    static float4 N14(float t) {
    	return fract(sin(t*float4(123.0, 1024.0, 1456.0, 264.0))*float4(6547.0, 345.0, 8799.0, 1564.0));
    }
    static float N(float t) {
        return fract(sin(t*12345.564)*7658.76);
    }
    
    static float Saw(float b, float t) {
    	return S(0.0, b, t)*S(1.0, b, t);
    }
    
    
    static float2 DropLayer2(float2 uv, float t) {
        float2 UV = uv;
        
        uv.y += t*0.75;
        float2 a = float2(u.space.x, 1.0);
        float2 grid = a*2.0;
        float2 id = floor(uv*grid);
        
        float colShift = N(id.x); 
        uv.y += colShift;
        
        id = floor(uv*grid);
        float3 n = N13(id.x*35.2+id.y*2376.1);
        float2 st = fract(uv*grid)-float2(0.5, 0);
        
        float x = n.x-0.5;
        
        float y = UV.y*20.0;
        float wiggle = sin(y+sin(y));
        x += wiggle*(0.5-abs(x))*(n.z-0.5);
        x *= 0.7;
        float ti = fract(t+n.z);
        y = (Saw(0.85, ti)-0.5)*0.9+0.5;
        float2 p = float2(x, y);
        
        float d = length((st-p)*a.yx);
        
        float mainDrop = S(0.4, 0.0, d);
        
        float r = sqrt(S(1.0, y, st.y));
        float cd = abs(st.x-x);
        float trail = S(0.23*r, 0.15*r*r, cd);
        float trailFront = S(-0.02, 0.02, st.y-y);
        trail *= trailFront*r*r;
        
        y = UV.y;
        float trail2 = S(0.2*r, .0, cd);
        float droplets = max(0.0, (sin(y*(1.-y)*120.0)-st.y))*trail2*trailFront*n.z;
        y = fract(y*u.space.y)+(st.y-0.5);
        // y = fract(y*10.0)+(st.y-0.5);
        float dd = length(st-float2(x, y));
        droplets = S(0.3, 0.0, dd);
        float m = (mainDrop+droplets*r*trailFront)*u.alpy;
        
        //m += st.x>a.y*.45 || st.y>a.x*.165 ? 1.2 : 0.0;
        return float2(m, trail);
    }
    
    static float StaticDrops(float2 uv, float t) {
    	uv *= 40.0;
        
        float2 id = floor(uv);
        uv = fract(uv)-0.5;
        float3 n = N13(id.x*107.45+id.y*3543.654);
        float2 p = (n.xy-0.5)*.7;
        float d = length(uv-p);
        
        float fade = Saw(0.025, fract(t+n.z));
        float c = (S(0.3, 0.0, d)*fract(n.z*10.0)*fade)*u.alpx;
        // float c = S(0.3, 0.0, d)*fract(n.z*10.0)*fade;
        return c;
    }
    
    static float2 Drops(float2 uv, float t, float l0, float l1, float l2) {
        float s = StaticDrops(uv*u.scalex, t)*l0; 
        float2 m1 = DropLayer2(uv*u.scaley, t)*l1;
        float2 m2 = DropLayer2(uv*u.scalez, t)*l2;
        
        float c = s+m1.x+m2.x;
        c = S(0.3, 1.0, c);
        
        return float2(c, max(m1.y*l0, m2.y*l1));
    }
    //////////////////////////

fragment float4 fx_toji_skexnxxsrainydew(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsrainydewParams&  u    [[buffer(1)]],
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
        
        float2 syamjaidtz;
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;

        if(u.xnxx) {
        syamjaidtz /= (u.scaleuv+1.5); }
        else { syamjaidtz /= u.scaleuv; }
        
        syamjaidtz *= rot2m((-180.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.0,1.0)/500.0;

        
        /////////////////////////

    	float4 __nv_out;
    	
    	float2 uv = syamjaidtz;
        float2 UV = in.acScreenNorm;
        
        float3 M = float3(0.0,0.0,0.0);
        float T = u.progress+M.x*2.0;
        
                /// HEART
                if(u.xnxx) {
                T = __nv_mod(u.progress, 102.0);
                T = mix(T, M.x*102.0, M.z>0.?1.:0.0); }
        
        
        float t = T*0.2;
        
        float rainAmount = 0.0>0. ? M.y : sin(T*.05)*.3+.7;
        
        float maxBlur = mix(3.0, 6.0, rainAmount);
        float minBlur = 2.0;
        
        float story = 0.0;
        float heart = 0.0;
        
                /// HEART
                if(u.xnxx) {
                story = S(0.0, 70.0, T);
                
                t = min(1.0, T/70.0);						// remap drop time so it goes slower when it freezes
                t = 1.-t;
                t = (1.-t*t)*70.0;
                
                minBlur = 4.0+S(0.5, 1.0, story)*3.0;		// more opaque glass towards the end
                maxBlur = 6.0+S(0.5, 1.0, story)*1.5;
                
                float2 hv = uv-float2(0.0, -0.1);				// build heart
                hv.x *= 0.5;
                float s = S(110.0, 70.0, T);				// heart gets smaller and fades towards the end
                hv.y-=sqrt(abs(hv.x))*0.5*s;
                heart = length(hv);
                heart = S(0.4*s, 0.2*s, heart)*s;
                rainAmount = heart;						// the rain is where the heart is
                
                maxBlur-=heart;							// inside the heart slighly less foggy
                uv *= 1.5;								// zoom out a bit more
                t *= 0.25; }
        
        float staticDrops = S(-0.5, 1.0, rainAmount)*2.0;
        float layer1 = S(0.25, 0.75, rainAmount);
        float layer2 = S(0.0, 0.5, rainAmount);
        
        
        float2 c = Drops(uv, t, staticDrops, layer1, layer2);
	float2 e = float2(0.001, 0.0);
	float cx = Drops(uv+e, t, staticDrops, layer1, layer2).x;
	float cy = Drops(uv+e.yx, t, staticDrops, layer1, layer2).x;
	float2 n = float2(cx-c.x, cy-c.x);		// expensive normals
        
        
                /// HEART
                if(u.xnxx) {
                n *= 1.0-S(60.0, 85.0, T);
                c.y *= 1.0-S(80.0, 100.0, T)*0.8; }
        
                        float focus = mix(maxBlur-c.y, minBlur, S(0.1, 0.2, c.x));
                        float4 col = inputImg.sample(__nv_smp, UV+n);
                        if(u.xxx) { col.a *= focus; }
                        else { col.a = focus; }
        
        if(u.lightfx) {
        t = (T+3.0)*0.5;										// make time sync with first lightnoing
        float colFade = (sin(t*0.2)*u.aai+0.5+story*1.0);
        col.rgb *= (mix(float3(1.0), float3(0.8, 0.9, 1.3), colFade)*1.0);	// subtle color shift
        float fade = S(0.0, 10.0, T);							// fade in at the start
        float lightning = sin(t*sin(t*10.0));				// lighting flicker
        lightning *= pow(max(0.0, sin(t+sin(t))), 10.0);		// lightning flash
        col.rgb *= (1.0+lightning*fade*mix(1.0, 0.1, story*story)*0.5);	// composite lightning
        col.rgb *= (1.0-dot(UV-=0.5, UV)*1.0);	// vignette
        											
                /// HEART
                if(u.xnxx) {
        	col.rgb = (mix(pow(col.rgb, float3(1.2)), col.rgb, heart)*1.0);
        	fade *= S(102.0, 97.0, T); }

        col.rgb *= fade; }							// composite start and end fade

        __nv_out = col;
                    
    	__nv_out = mix(texColor, __nv_out, u.alpha) * texColor.a;
          }
    return __nv_out;
}
