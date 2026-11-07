// ---------------------------------------------------------------------------
// toji-skexnxxsplexusparticle.xml
// origem : assets/effects/toji-skexnxxsplexusparticle.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e706c657875737061727469636c65
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsplexusparticleParams {
    float ITER;
    int autop;
    int autob;
    float progressb;
    float progressc;
    int autor;
    int autos;
    float progressa;
    float scale;
    float angle;
    float2 position;
    float2 stretch;
    float bright;
    float alpha;
    float4 color1;
    float4 color2;
    int blendMode;
};

// --- funcoes auxiliares do efeito
//////////////////////////
    static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    static float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   /////////////////////////
    
   #define S(a,b,t) smoothstep(a,b,t)
    
    static float DistLine(float2 p, float2 a, float2 b) {
        float2 pa = p-a;
        float2 ba = b-a;
        float t = clamp(dot(pa, ba)/dot(ba, ba), 0., 1.);
        return length(pa-ba*t);
    }
    
    static float N21(float2 p) {
        p = fract(p*float2(233.34, 851.73));
        p += dot(p, p+23.45);
        return fract(p.x*p.y);
    }
    
    static float2 N22(float2 p) {
        float n = N21(p);
        return float2(n, N21(p+n));
    }
    
    static float2 GetPos (float2 id, float2 offs) {
        float xnxx = u.autop? u.progressb + (eng.acTime*2.0) : u.progressb;
        float2 n = N22(id+offs) * xnxx;
        // float2 n = N22(id+offs)* u.progressb;
        
        return offs+sin(n)*.4;
    }
    
    static float Line(float2 p, float2 a, float2 b) {
        float d = DistLine(p,a,b); // distance to the line segment
        float m = S(.03,.01,d); // cut out the line
        float d2 = length(a-b);
        m *= S(1.2, .8, d2)*.5+S(.05,.03, abs(d2-.75)); // make them not all visible
        return m;
    }
    
    static float Layer (float2 uv) {
        float m = 0.0;
        float2 gv = fract(uv)-.5;
        float2 id = floor(uv);
        
        float2 p[9];
        int i = 0;
        
    
        
        for (float y=-1.0; y<=1.0;y++) {
            for (float x=-1.0;x<=1.0;x++) {
                p[i++] = GetPos(id, float2(x,y));
            }
        }
        
        float t = u.autob? (u.progressc+(eng.acTime*0.5))*10.0 : u.progressc*10.0;
        // float t = u.progressc*20.0;
        for(int i=0; i<9; i++) {
            m += Line(gv, p[4], p[i]);
            
            float2 j = (p[i]-gv)*15.0;
            float sparkle = 1./dot(j, j);
            
            m += sparkle*(sin(t+fract(p[i].x)*10.)*.5+.5);
        }
        m += Line(gv, p[1], p[3]);
        m += Line(gv, p[1], p[5]);
        m += Line(gv, p[5], p[7]);
        m += Line(gv, p[7], p[3]);
        
        return m;
    }
    //////////////////////////

fragment float4 fx_toji_skexnxxsplexusparticle(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsplexusparticleParams&  u    [[buffer(1)]],
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

        syamjaidtz /= (2.0*u.scale);
        syamjaidtz *= rot2m((u.autor? u.angle+(eng.acTime*1.25) : u.angle)*0.0174533);
        syamjaidtz += u.position*float2(-1.,1.)/500.0;
        
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        syamjaidtz /= scaleVec;
        
        /////////////////////////

    	float4 result;
    	
    	float2 uv = syamjaidtz;
        float2 mouse = (float2(0,0)/uv)-.5;
        float m = 0.0;
        float t = u.autos? (u.progressa+(eng.acTime*0.5))*0.1 : u.progressa*0.1;
        
        float s = sin(t);
        float c = cos(t);
        float2x2 rot = float2x2(c,-s,s,c);
        
        if(u.autor) { uv *= rot; }
        
        for (float i=0.0; i<1.0;i+= (21.0 - u.ITER) ){
            float z = fract(i+t);
            float size = mix(10.,.5,z);
            float fade = S(0.,.5,z)*S(1.,.8,z);
            m += Layer(uv*size+i*20.-mouse)*fade;
        }
        
        float3 col = float3(m);
            
        result = float4(col,1.0);
        
            const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float4 gradmap;
            float luminance = dot(result.rgb, luminanceWeighting);
            gradmap = mix(u.color1,u.color2,luminance)*result.a;
        
    	// float4 factor = gradmap * u.alpha;
    	float4 factor = mix(texColorX,gradmap,1.0);
    	
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
            
    	__nv_out = mix(texColor, resultfinal, u.alpha) * texColor.a;
          }
    return __nv_out;
}
