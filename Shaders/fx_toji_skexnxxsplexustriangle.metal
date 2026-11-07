// ---------------------------------------------------------------------------
// toji-skexnxxsplexustriangle.xml
// origem : assets/effects/toji-skexnxxsplexustriangle.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e706c65787573747269616e676c65
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsplexustriangleParams {
    float4 color1;
    float4 color2;
    int autoe;
    int autob;
    int autor;
    float XXA;
    float XXB;
    float scale;
    float angle;
    float2 position;
    float2 stretch;
    float alpha;
    float hardness;
    int blendMode;
    int invert;
    int autos;
    int autop;
    float XXC;
};

// --- funcoes auxiliares do efeito
//////////////////////////
    float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        #define S(a, b, t) smoothstep(a, b, t)
        
        float distLine(float2 p, float2 a, float2 b){
        	float2 pa = p - a;
            float2 ba = b - a;
            float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
            return length(pa - ba*t);
        }
        
        float line(float2 p, float2 a, float2 b){
        	float d = distLine(p, a, b);
            float m = S(0.03, 0.01, d);
            float d2 =  length(a - b);
            m *= S(1.2, 0.8, d2) * 0.5 + S(0.05, 0.03, abs(d2 - 0.75));
            return m;
        }
        
        float distTriangle(in float2 p, in float2 p0, in float2 p1, in float2 p2 )
        {
        	float2 e0 = p1 - p0;
        	float2 e1 = p2 - p1;
        	float2 e2 = p0 - p2;
        
        	float2 v0 = p - p0;
        	float2 v1 = p - p1;
        	float2 v2 = p - p2;
        
        	float2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
        	float2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
        	float2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
            
            float s = sign( e0.x*e2.y - e0.y*e2.x );
            float2 d = min( min( float2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
                               float2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
                               float2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) ));
        
        	return -sqrt(d.x)*sign(d.y);
        }
        
        float triangle(float2 p, float2 a, float2 b, float2 c){
        	float d = distTriangle(p, a, b, c);
            float m = S(0.03, 0.01, d);
            float d2 =  length(a - b);
            m *= S(1.2, 0.8, d2) * 0.5 + S(0.05, 0.03, abs(d2 - 0.75));
            return m;
        }
        
        float N21(float2 p){
        	p = fract(p * float2(233.34, 851.73));
            p += dot(p, p + 23.45);
            return fract(p.x * p.y);
        }
        
        float2 N22(float2 p){
        	float n = N21(p);
            return float2(n, N21(p + n));
        }
        
        float2 getPos(float2 id, float2 offset){
            float FEVO = u.autoe? u.XXA+(eng.acTime*0.5) : u.XXA;
            float2 n = N22(id + offset) * FEVO;
            return offset + sin(n) * 0.4;
        }
        
        float layer(float2 uv){
        	float2 gv = fract(uv) - 0.5;
            float2 id = floor(uv);
        
            float2 p[9];
            int i = 0;
            for(float y = -1.0; y <= 1.0; y++){
            	for(float x = -1.0; x <= 1.0; x++){
                	p[i++] = getPos(id, float2(x, y));
            	}    
            }
            
            
            float t = u.autob? (u.XXB+eng.acTime*0.5) * 10.0 : u.XXB * 10.0;
            float m = 0.0;
            for(int i = 0; i < 9; i++){
            	m += line(gv, p[4], p[i]);
                
                float2 j = (p[i] - gv) * 20.0;
                float sparkle = 1.0 / dot(j, j);
                
                m += sparkle * (sin(t + fract(p[i].x) * 10.0) * 0.5 + 0.5);
                
                for(int yi= i + 1; yi < 9; yi++){
            		for(int zi= yi + 1; zi < 9; zi++){
                        
                        float len1 = abs(length(p[i] - p[yi]));
                        float len2 = abs(length(p[yi] - p[zi]));
                        float len3 = abs(length(p[i] - p[zi]));
                        
                        if((len1 + len2 + len3) < 2.8){
                        	m += triangle(gv, p[i], p[yi], p[zi]) * 0.8;
                        }
            		}
            	}
            }
            m += line(gv, p[1], p[3]);
            m += line(gv, p[1], p[5]);
            m += line(gv, p[7], p[3]);
            m += line(gv, p[7], p[5]);
        
            return m;
        }
    //////////////////////////

fragment float4 fx_toji_skexnxxsplexustriangle(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsplexustriangleParams&  u    [[buffer(1)]],
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
        // float2 syamjaidtz;
        // syamjaidtz = in.acScreenNorm; 
        
        float2 syamjaidtz;
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
        syamjaidtz /= u.scale;
        float ROTATE = u.autor? u.angle+(eng.acTime*2.5) : u.angle;
        syamjaidtz *= rot2m((0.0+ROTATE)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        syamjaidtz /= scaleVec;
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 uv = syamjaidtz;
            // float2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
            
            float m = 0.0;
            float mm = 0.0;
            float t = u.autop? (u.XXC+eng.acTime*0.5) * 0.1 : u.XXC * 0.1;
                        
            float s = sin(t);
            float c = cos(t);
            float2x2 rot = float2x2(c, -s, s, c);
            // uv *= rot;
            
            for(float i = 0.0; i < 1.0; i += 16.0){
            // for(float i = 0.0; i < 1.0; i += 1.0 / 4.0){
                float z = fract(i + t);
                float size = mix(10.0, 0.5, z);
                float fade = S(0.0, 0.5, z) * S(1.0, 0.8, z);
                
                m += layer(uv * size + i * 20.0) * fade;
                mm += layer(uv * size + i * 20.0);
            }
            
            
            float3 base = sin(t * 5.0 * float3(0.345, 0.456, 0.567)) * 0.4 + 0.6;
            // float3 bases = float3(1.0, 1.0, 1.0);
            float3 col = u.autos?m * base : mm * u.color2.rgb;
            // float3 col = u.autos?m * base : mm * bases;
            // col *= u.color2.rgb;
                        
            __nv_out = float4(col,0.0);
            if(u.invert) { __nv_out = 1.-__nv_out; }
        
    	float4 factor = newLayer(u.color1,__nv_out);
    	// float4 factorx = newLayer(u.color1,__nv_out*(u.hardness-0.4));
    	
        float4 resultfinal;
          if( u.blendMode==0 ) {
            resultfinal = (factor * u.hardness) * texColor.a; }
          else if( u.blendMode==1 ) { factor *= 1.0;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a; }
          else if( u.blendMode==2 ) { factor *= u.hardness; 
            // resultfinal = max(factor, texColor) * texColor.a; }
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a; }
          // else if( u.blendMode==3 ) { factorx *= 1.0; 
            // resultfinal = (newLayer(texColor, factorx) * 1.0) * texColor.a; }
            
    	__nv_out = mix(texColor, resultfinal, u.alpha) * texColor.a;
          }
    return __nv_out;
}
