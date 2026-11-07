// ---------------------------------------------------------------------------
// toji-skexnxxsnewoffsetglitch.xml
// origem : assets/effects/toji-skexnxxsnewoffsetglitch.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e6e65776f6666736574676c69746368
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsnewoffsetglitchParams {
    int autop;
    int OFFSIDE;
    float PROGRESS;
    float SPEED;
    float glitchAmplitude;
    float AMOUNT;
    float scale;
    float2 stretch;
    float DISTORT;
    float STEP;
    float glitchNarrowness;
    float glitchBlockiness;
    float glitchMinimizer;
    float alpha;
    int rcolor;
    int gcolor;
    int bcolor;
};

// --- funcoes auxiliares do efeito
//////////////////////////
    static float4 newLayer( float4 a, float4 b) { return a * (1.0 - b.a) + b;  }
    static float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    static float2 l2s( float2 v ) { return (float4(v,0.,1.0)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        static float rand(float2 p)
        {
            float EVO = u.autop? u.PROGRESS + (eng.acTime*u.SPEED) : u.PROGRESS;
            float t = floor(EVO*10.0) / 10.0;
            return fract(sin(dot(p, float2(t * 12.9898, t * 78.233))) * 43758.5453);
        }
        
        static float noise(float2 uv, float blockiness)
        {   
            float2 lv = fract(uv);
            float2 id = floor(uv);
            
            float n1 = rand(id);
            float n2 = rand(id+float2(1,0));
            float n3 = rand(id+float2(0,1));
            float n4 = rand(id+float2(1,1));
            
            float2 u = smoothstep(0.0, 1.0 + blockiness, lv);
        
            return mix(mix(n1, n2, u.x), mix(n3, n4, u.x), u.y);
        }
        
        static float fbm(float2 uv, int count, float blockiness, float complexity)
        {
            float val = 0.0;
            float amp = 0.5;
            
            while(count != 0)
            {
            	val += amp * noise(uv, blockiness);
                amp *= 0.5;
                uv *= complexity;    
                count--;
            }
            
            return val;
        }
    //////////////////////////

fragment float4 fx_toji_skexnxxsnewoffsetglitch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsnewoffsetglitchParams&  u    [[buffer(1)]],
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
        syamjaidtz = in.acScreenNorm.st; 
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 uv = syamjaidtz;
            
            float2 a = float2(uv.x * (iResolution.x / iResolution.y), uv.y);
            float2 uv2 = float2(a.x / iResolution.x, exp(a.y));
            float2 id = floor(uv * u.AMOUNT);
            // if(L2S) { id = l2s(id); }
            
                float2 scaleVec;
                scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
                uv2 /= scaleVec;
             
            float shift = u.glitchAmplitude * pow(fbm(uv2, int(rand(id) * u.DISTORT), 
                          u.glitchBlockiness, u.glitchNarrowness), u.glitchMinimizer);
            float scanline = abs(cos(uv.y * 400.0));
            scanline = smoothstep(0.0, 2.0, scanline);
            shift = smoothstep(0.00001, u.STEP, shift);
            
                float colR;
                if (u.rcolor) { colR = inputImg.sample(__nv_smp, float2(uv.x + shift, uv.y)).r * (1. - shift); }
                else { colR = inputImg.sample(__nv_smp, float2(uv.x - shift, uv.y)).r * (1. - shift); }
                
                float colG;
                if (u.gcolor) { colG = inputImg.sample(__nv_smp, float2(uv.x + shift, uv.y)).g * (1. - shift); }
                else { colG = inputImg.sample(__nv_smp, float2(uv.x - shift, uv.y)).g * (1. - shift); }
                
                float colB;
                if (u.bcolor) { colB = inputImg.sample(__nv_smp, float2(uv.x + shift, uv.y)).b * (1. - shift); }
                else { colB = inputImg.sample(__nv_smp, float2(uv.x - shift, uv.y)).b * (1. - shift); }
            
        float3 f = float3(colR, colG, colB);
        float4 factor = float4(f, texColor.a) * u.alpha;
        if(u.OFFSIDE) { factor *= texColor.a; }
        
        float4 resultfinal = newLayer(texColor*texColor.a,factor);
        
    	__nv_out = resultfinal;
          }
    return __nv_out;
}
