// ---------------------------------------------------------------------------
// toji-skexnxxswaterwave.xml
// origem : assets/effects/toji-skexnxxswaterwave.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e776174657277617665
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxswaterwaveParams {
    float4 water_color;
    int autop;
    float PROGRESS;
    float SPEED;
    float HEI;
    float STR;
    float FREQ;
    float TRP;
    float ANG;
    float alpha;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    static float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    static float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
    //////////////////////////
        
    //////////////////////////

fragment float4 fx_toji_skexnxxswaterwave(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxswaterwaveParams&  u    [[buffer(1)]],
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
        float iTime = u.autop? u.PROGRESS + (eng.acTime*u.SPEED) : u.PROGRESS;
        
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm; 
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 uv = syamjaidtz;
            
            float height = u.HEI;
            float wave_strength = u.STR;
            float wave_frequency = u.FREQ;
            float transparency = u.TRP;
            float angle = u.ANG;
            
            angle *= uv.y/height+angle/1.5; //3D effect
            wave_strength /= 1000.0;
            float wave = sin(10.0*uv.y+10.0*uv.x+wave_frequency*iTime)*wave_strength;
            wave += sin(20.0*-uv.y+20.0*uv.x+wave_frequency*1.0*iTime)*wave_strength*0.5;
            wave += sin(15.0*-uv.y+15.0*-uv.x+wave_frequency*0.6*iTime)*wave_strength*1.3;
            wave += sin(3.0*-uv.y+3.0*-uv.x+wave_frequency*0.3*iTime)*wave_strength*10.0;
            
            __nv_out = inputImg.sample(__nv_smp, float2(uv.x, uv.y));
            
            if(uv.y - wave <= height) {
                __nv_out = mix(
                mix(
                    inputImg.sample(__nv_smp, float2(uv.x, ((1.0 + angle)*(height + wave) - angle*uv.y + wave))),
                    u.water_color,
                    0.6-(0.3-(0.3*uv.y/height))),
                inputImg.sample(__nv_smp, float2(uv.x + wave, uv.y - wave)),
                transparency-(transparency*uv.y/height)); }
        
    	__nv_out = mix(texColor, __nv_out, u.alpha) * texColor.a;
          }
    return __nv_out;
}
