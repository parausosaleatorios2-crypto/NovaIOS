// ---------------------------------------------------------------------------
// toji-skexnxxsbubble.xml
// origem : assets/effects/toji-skexnxxsbubble.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e627562626c65
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsbubbleParams {
    int autop;
    float PROGRESS;
    float SPEED;
    int B1;
    int B2;
    int B3;
    int B4;
    int B5;
    int B6;
    float scale;
    float angle;
    float2 position;
    float2 stretch;
    float alpha;
    float hardness;
    int blendMode;
};

// --- funcoes auxiliares do efeito
//////////////////////////
    static float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    static float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    static float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        float2 uv;
        
        static float2 hash2a(float2 x,float anim)
        {
        	float r = 523.0*sin(dot(x, float2(53.3158, 43.6143)));
            float xa1=fract(anim);
            float xb1=anim-xa1;
            anim+=0.5;
            float xa2=fract(anim);
            float xb2=anim-xa2;
            
            float2 z1=float2(fract(15.32354 * (r+xb1)), fract(17.25865 * (r+xb1)));
            r=r+1.0;
            float2 z2=float2(fract(15.32354 * (r+xb1)), fract(17.25865 * (r+xb1)));
            r=r+1.0;
            float2 z3=float2(fract(15.32354 * (r+xb2)), fract(17.25865 * (r+xb2)));
            r=r+1.0;
            float2 z4=float2(fract(15.32354 * (r+xb2)), fract(17.25865 * (r+xb2)));
        	return (mix(z1,z2,xa1)+mix(z3,z4,xa2))*0.5;
        }
        
        static float hashNull(float2 x)
        {
            float r = fract(523.0*sin(dot(x, float2(53.3158, 43.6143))));
            return r;
        }
        
        float4 NC0=float4(0.0,157.0,113.0,270.0);
        float4 NC1=float4(1.0,158.0,114.0,271.0);
        
        static float4 hash4( float4 n ) { return fract(sin(n)*753.5453123); }
        static float2 hash2( float2 n ) { return fract(sin(n)*753.5453123); }
        static float noise2( float2 x )
        {
            float2 p = floor(x);
            float2 f = fract(x);
            f = f*f*(3.0-2.0*f);
        	
            float n = p.x + p.y*157.0;
            float2 s1=mix(hash2(float2(n)+NC0.xy),hash2(float2(n)+NC1.xy),float2(f.x));
            return mix(s1.x,s1.y,f.y);
        }
        
        static float noise3( float3 x )
        {
            float3 p = floor(x);
            float3 f = fract(x);
            f = f*f*(3.0-2.0*f);
        	
            float n = p.x + dot(p.yz,float2(157.0,113.0));
            float4 s1=mix(hash4(float4(n)+NC0),hash4(float4(n)+NC1),float4(f.x));
            return mix(mix(s1.x,s1.y,f.y),mix(s1.z,s1.w,f.y),f.z);
        }
        
        static float4 booble(float2 te,float2 pos,float numCells)
        {
            float d=dot(te, te);
        
            float2 te1=te+(pos-float2(0.5,0.5))*0.4/numCells;
            float2 te2=-te1;
            float zb1=max(pow(noise2(te2*1000.11*d),10.0),0.01);
            float zb2=noise2(te1*1000.11*d);
            float zb3=noise2(te1*200.11*d);
            float zb4=noise2(te1*200.11*d+float2(20.0));
            
            float4 colorb=float4(1.0);
            colorb.xyz=colorb.xyz*(0.7+noise2(te1*1000.11*d)*0.3);
            
            zb2=max(pow(zb2,20.1),0.01);
            colorb.xyz=colorb.xyz*(zb2*1.9);
            
            float4 color=float4(noise2(te2*10.8),noise2(te2*9.5+float2(15.0,15.0)),noise2(te2*11.2+float2(12.0,12.0)),1.0);
            color=mix(color,float4(1.0),noise2(te2*20.5+float2(200.0,200.0)));
            color.xyz=color.xyz*(0.7+noise2(te2*1000.11*d)*0.3);
            color.xyz=color.xyz*(0.2+zb1*1.9);
            
            float r1=max(min((0.033-min(0.04,d))*100.0/sqrt(numCells),1.0),-1.6);
            float d2=(0.06-min(0.06,d))*10.0;
            d=(0.04-min(0.04,d))*10.0;
        	color.xyz=color.xyz+colorb.xyz*d*1.5;
            
            float f1=min(d*10.0,0.5-d)*2.2;
            f1=pow(f1,4.0);
            float f2=min(min(d*4.1,0.9-d)*2.0*r1,1.0);
        
            float f3=min(d2*2.0,0.7-d2)*2.2;
            f3=pow(f3,4.0);
            
        	return float4(color*max(min(f1+f2,1.0),-0.5)+float4(zb3)*f3-float4(zb4)*(f2*0.5+f1)*0.5);
        }
        
        static float4 Cells(float2 p,float2 move, in float numCells,in float count,float blur)
        {
            float2 inp=p+move;
        	inp *= numCells;
        	float d = 1.0;
            float2 te;
            float2 pos;
        	for (int xo = -1; xo <= 1; xo++)
        	{
        		for (int yo = -1; yo <= 1; yo++)
        		{
        			float2 tp = floor(inp) + float2(xo, yo);
                    float2 rr=__nv_mod(tp, numCells);
                    float iTimee = u.autop? u.PROGRESS + (eng.acTime*u.SPEED) : u.PROGRESS;
                    tp=tp + (hash2a(rr,iTimee*0.1)+hash2a(rr,iTimee*0.1+0.25))*0.5;
        			float2 l = inp - tp;
                    float dr=dot(l, l);
                    if (hashNull(rr)>count)
                        if (d>dr) {
        					d = dr;
                            pos=tp;
                        }
        		}
        	}
            if (d>=0.06) return float4(0.0);
            te=inp-pos;
            
             
            if (d<0.04) uv=uv+te*(d)*2.0;
            if (blur>0.0001) {
                float4 c=float4(0.0);
                for (float x=-1.0;x<1.0;x+=0.5) {
                    for (float y=-1.0;y<1.0;y+=0.5) {
                        c+=booble(te+float2(x,y)*blur,p,numCells);
                    }
                }
                return c*0.05;
            }
        
            return booble(te,p,numCells);
        }
    //////////////////////////

fragment float4 fx_toji_skexnxxsbubble(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsbubbleParams&  u    [[buffer(1)]],
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
        float2 iResolution = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 iMouse = float2(0.5, 0.5);
        
        float2 syamjaidtz;
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
    	
            uv = syamjaidtz;
            float iTime = u.autop? u.PROGRESS + (eng.acTime*u.SPEED) : u.PROGRESS;
            
            float2 l1=float2(iTime*0.02,iTime*0.02);
            float2 l2=float2(-iTime*0.01,iTime*0.007);
            float2 l3=float2(0.0,iTime*0.01);
            
            float4 e= float4(0.0);
            
            float4 cr1; float4 cr2; float4 cr3; float4 cr4; float4 cr5; float4 cr6;
            
            if(u.B1) {
            cr1=Cells(uv,float2(20.2449,93.78)+l1,2.0,0.5,0.005); }
            if(u.B2) {
            cr2=Cells(uv,float2(0.0,0.0),3.0,0.5,0.003); }
            if(u.B3) {
            cr3=Cells(uv,float2(230.79,193.2)+l2,4.0,0.5,0.0); }
            if(u.B4) {
            cr4=Cells(uv,float2(200.19,393.2)+l3,7.0,0.8,0.01); }
            if(u.B5) {
            cr5=Cells(uv,float2(10.3245,233.645)+l3,9.2,0.9,0.02); }
            if(u.B6) {
            cr6=Cells(uv,float2(10.3245,233.645)+l3,14.2,0.95,0.05); }
            
            if(u.B1) {
            e=max(e-float4(dot(cr1,cr1))*0.1,0.0)+cr1*1.8; }
            if(u.B2) {
            e=max(e-float4(dot(cr2,cr2))*0.1,0.0)+cr2*1.4; }
            if(u.B3) {
            e=max(e-float4(dot(cr3,cr3))*0.1,0.0)+cr3*1.1; }
            if(u.B4) {
            e=max(e-float4(dot(cr4,cr4))*0.1,0.0)+cr4*1.3; }
            if(u.B5) {
            e=max(e-float4(dot(cr5,cr5))*0.1,0.0)+cr5*1.6; }
            if(u.B6) {
            e=max(e-float4(dot(cr6,cr6))*0.1,0.0)+cr6*1.6; }
            
            __nv_out= e;
        
    	float4 factor = mix(texColorX,__nv_out,1.0);
    	
        float4 resultfinal;
          if( u.blendMode==0 ) {
            resultfinal = (factor * u.hardness) * texColor.a; }
          else if( u.blendMode==1 ) { factor *= u.hardness; 
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a; }
            
    	__nv_out = mix(texColor, resultfinal, u.alpha) * texColor.a;
          }
    return __nv_out;
}
