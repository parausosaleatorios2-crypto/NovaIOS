// ---------------------------------------------------------------------------
// toji-skexnxxsraindropsfloor.xml
// origem : assets/effects/toji-skexnxxsraindropsfloor.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e7261696e64726f7073666c6f6f72
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsraindropsfloorParams {
    int autop;
    float MAX_RADIUS;
    float PROGRESS;
    float RAINSPEED;
    float RANSIZE;
    float2 position;
    float2 stretch;
    float alpha;
};

// --- funcoes auxiliares do efeito
//////////////////////////
    float4 newLayer( float4 a, float4 b) { return a * (1.0 - b.a) + b;  }
    float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    float2 l2s( float2 v ) { return (float4(v,0.0,1.0)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        #define HASHSCALE1 .1031
        #define HASHSCALE3 float3(.1031, .1030, .0973)
   
        // #define u.MAX_RADIUS 2
        #define DOUBLE_HASH 0
        // #define u.RANSIZE 0.7
        // #define u.RAINSPEED 0.3
        
        float hash12(float2 p)
        {
        	float3 p3  = fract(float3(p.xyx) * HASHSCALE1);
            p3 += dot(p3, p3.yzx + 19.19);
            return fract((p3.x + p3.y) * p3.z);
        }
        
        float2 hash22(float2 p)
        {
        	float3 p3 = fract(float3(p.xyx) * HASHSCALE3);
            p3 += dot(p3, p3.yzx+19.19);
            return fract((p3.xx+p3.yz)*p3.zy);
        
        }
    //////////////////////////

fragment float4 fx_toji_skexnxxsraindropsfloor(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsraindropsfloorParams&  u    [[buffer(1)]],
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
        float iTime = u.autop? u.PROGRESS + (eng.acTime*0.5) : u.PROGRESS;
        
        /////////////////////////
       
    	float4 __nv_out;
    	
            float resolution = 10.0 * exp2(-3.0*u.RANSIZE);
            
        	float2 uv = in.acScreenNorm * resolution;
                uv += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;
                float2 scaleVec;
                scaleVec = float2(1.0*u.stretch.x,1.0*u.stretch.y);
                uv /= scaleVec;
        	
                float2 uv2 = in.acScreenNorm * resolution;
                
            float2 p0 = floor(uv);
        
            float2 circles = float2(0.0);
            for (int j = -int(u.MAX_RADIUS); j <= int(u.MAX_RADIUS); ++j)
            {
                for (int i = -int(u.MAX_RADIUS); i <= int(u.MAX_RADIUS); ++i)
                {
        			float2 pi = p0 + float2(i, j);
                    #if DOUBLE_HASH
                    float2 hsh = hash22(pi);
                    #else
                    float2 hsh = pi;
                    #endif
                    float2 p = pi + hash22(hsh);
        
                    float t = fract(u.RAINSPEED*iTime + hash12(hsh));
                    float2 v = p - uv;
                    float d = length(v) - (u.MAX_RADIUS + 1.0)*t;
        
                    float h = 1e-3;
                    float d1 = d - h;
                    float d2 = d + h;
                    float p1 = sin(31.0*d1) * smoothstep(-0.6, -0.3, d1) * smoothstep(0.0, -0.3, d1);
                    float p2 = sin(31.0*d2) * smoothstep(-0.6, -0.3, d2) * smoothstep(0.0, -0.3, d2);
                    circles += u.alpha * normalize(v) * ((p2 - p1) / (2.0 * h) * (1.0 - t) * (1.0 - t));
                    // circles += 0.5 * normalize(v) * ((p2 - p1) / (2.0 * h) * (1.0 - t) * (1.0 - t));
                }
            }
            circles /= float((int(u.MAX_RADIUS)*2+1)*(int(u.MAX_RADIUS)*2+1));
        
            float intensity = mix(0.01, 0.15, smoothstep(0.1, 0.6, abs(fract(0.05*iTime + 0.5)*2.-1.0)));
            
            float3 n = float3(circles, sqrt(1.0 - dot(circles, circles)));
        	float3 color = inputImg.sample(__nv_smp, uv2/resolution - intensity*n.xy).rgb 
        	+ 5.0*pow(clamp(dot(n, 
        	normalize(float3(1.0, 0.7, 0.5))), 0.0, 1.0), 6.0);
        	
            __nv_out = float4(color, 1.0);
        
    	__nv_out = mix(texColor, __nv_out, 1.0) * texColor.a;
          }
    return __nv_out;
}
