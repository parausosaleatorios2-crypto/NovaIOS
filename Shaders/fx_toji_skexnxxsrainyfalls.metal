// ---------------------------------------------------------------------------
// toji-skexnxxsrainyfalls.xml
// origem : assets/effects/toji-skexnxxsrainyfalls.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e7261696e7966616c6c73
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsrainyfallsParams {
    int autop;
    float PROGRESS;
    float SPEED;
    float xscale;
    float yscale;
    float xdistort;
    float ydistort;
    float alpha;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    static float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    static float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
    //////////////////////////
        
    //////////////////////////

fragment float4 fx_toji_skexnxxsrainyfalls(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsrainyfallsParams&  u    [[buffer(1)]],
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
        float speed  = 0.08;
            
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
        float2 uv_warp = float2(uv.x/u.xscale,uv.y/u.yscale + iTime*speed);
    	float2 uv_samp = float2(noisexx.sample(__nv_smp, uv_warp).r,noisexx.sample(__nv_smp, float2(uv_warp.x,uv_warp.y + speed)).r);
    	__nv_out = inputImg.sample(__nv_smp, float2(uv.x+(uv_samp.x-uv_samp.y)*u.xdistort,uv.y + uv_samp.y*u.ydistort));
        
    	__nv_out = mix(texColor, __nv_out, u.alpha) * texColor.a;
          }
    return __nv_out;
}
