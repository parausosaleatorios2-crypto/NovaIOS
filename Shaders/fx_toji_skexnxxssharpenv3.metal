// ---------------------------------------------------------------------------
// toji-skexnxxssharpenv3.xml
// origem : assets/effects/toji-skexnxxssharpenv3.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e7368617270656e7633
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxssharpenv3Params {
    int TYPE;
    float radius;
    float sharpness;
    float alpha;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    static float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    static float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
    //////////////////////////
        const int M = 1;
        
        const float3x3 rgb2ycbcr = float3x3(
            0.299, -0.168736, 0.5,
            0.587, -0.331264, -0.418688,
            0.114, 0.5, -0.081312
        );
        
        float3 rgb2gray = float3(0.299, 0.587, 0.114);
        
        const float3x3 ycbcr2rgb = float3x3(
            1.0, 1.0, 1.0,
            0.0, -0.344136, 1.772,
            1.402, -0.714136, 0.0
        );
    //////////////////////////

fragment float4 fx_toji_skexnxxssharpenv3(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxssharpenv3Params&  u    [[buffer(1)]],
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
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 step = float2(1.)/__nv_getTexSize(inputImg_info.size) * u.radius;
            float4 srcColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            float3 color = float3(0);
        
            float p1 = dot(rgb2gray, (inputImg.sample(__nv_smp, in.acScreenNorm.st + step * float2(-1, -1)).rgb));
            float p2 = dot(rgb2gray, (inputImg.sample(__nv_smp, in.acScreenNorm.st + step * float2(0, -1)).rgb));
            float p3 = dot(rgb2gray, (inputImg.sample(__nv_smp, in.acScreenNorm.st + step * float2(1, -1)).rgb));
            float p4 = dot(rgb2gray, (inputImg.sample(__nv_smp, in.acScreenNorm.st + step * float2(-1, 0)).rgb));
            float p5 = dot(rgb2gray, (srcColor.rgb));
            float p6 = dot(rgb2gray, (inputImg.sample(__nv_smp, in.acScreenNorm.st + step * float2(1, 0)).rgb));
            float p7 = dot(rgb2gray, (inputImg.sample(__nv_smp, in.acScreenNorm.st + step * float2(-1, 1)).rgb));
            float p8 = dot(rgb2gray, (inputImg.sample(__nv_smp, in.acScreenNorm.st + step * float2(0, 1)).rgb));
            float p9 = dot(rgb2gray, (inputImg.sample(__nv_smp, in.acScreenNorm.st + step * float2(1, 1)).rgb));
        
            float f1 = 2.0 * p5 - p4 - p6;
            float f2 = 2.0 * p5 - p2 - p8;
            float f3 = 2.0 * p5 - p3 - p7;
            float f4 = 2.0 * p5 - p1 - p9;
        
            float maxf = max(max(max(abs(f1), abs(f2)), abs(f3)), abs(f4));
            float3 ycbcr = rgb2ycbcr * srcColor.rgb;
        
            float f;
            if (u.TYPE==0) {
                f = f1; }
            else if (u.TYPE==1) {
                f = f2; }
            else if (u.TYPE==2) {
                f = f3; }
            else if (u.TYPE==3) {
                f = f4; }
                
            color = ycbcr2rgb * ((ycbcr + float3(u.sharpness * f * 0.5, 0, 0)));
            __nv_out = float4(color, srcColor.a);
                    
    	__nv_out = mix(texColor, __nv_out, u.alpha) * texColor.a;
          }
    return __nv_out;
}
