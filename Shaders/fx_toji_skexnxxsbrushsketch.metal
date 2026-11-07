// ---------------------------------------------------------------------------
// toji-skexnxxsbrushsketch.xml
// origem : assets/effects/toji-skexnxxsbrushsketch.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e6272757368736b65746368
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsbrushsketchParams {
    float RADIUSS;
    float alpha;
};

// --- funcoes auxiliares do efeito
//////////////////////////
    static float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    static float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    static float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    //////////////////////////

fragment float4 fx_toji_skexnxxsbrushsketch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsbrushsketchParams&  u    [[buffer(1)]],
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
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm.st; 
        
        /////////////////////////
        
         int radius = int(u.RADIUSS);
        
    	float4 __nv_out;
    	
        	 float2 src_size = float2 (1.0 / iResolution.x, 1.0 / iResolution.y);
             float2 uv = syamjaidtz;
             float n = float((radius + 1) * (radius + 1));
             int i; 
        	 int j;
             float3 m0 = float3(0.0); float3 m1 = float3(0.0); float3 m2 = float3(0.0); float3 m3 = float3(0.0);
             float3 s0 = float3(0.0); float3 s1 = float3(0.0); float3 s2 = float3(0.0); float3 s3 = float3(0.0);
             float3 c;
        
             for (int j = -radius; j <= 0; ++j)  {
                 for (int i = -radius; i <= 0; ++i)  {
                     c = inputImg.sample(__nv_smp, uv + float2(i,j) * src_size).rgb;
                     m0 += c;
                     s0 += c * c;
                 }
             }
        
             for (int j = -radius; j <= 0; ++j)  {
                 for (int i = 0; i <= radius; ++i)  {
                     c = inputImg.sample(__nv_smp, uv + float2(i,j) * src_size).rgb;
                     m1 += c;
                     s1 += c * c;
                 }
             }
        
             for (int j = 0; j <= radius; ++j)  {
                 for (int i = 0; i <= radius; ++i)  {
                     c = inputImg.sample(__nv_smp, uv + float2(i,j) * src_size).rgb;
                     m2 += c;
                     s2 += c * c;
                 }
             }
        
             for (int j = 0; j <= radius; ++j)  {
                 for (int i = -radius; i <= 0; ++i)  {
                     c = inputImg.sample(__nv_smp, uv + float2(i,j) * src_size).rgb;
                     m3 += c;
                     s3 += c * c;
                 }
             }
        
        
             float min_sigma2 = 1e+2;
             m0 /= n;
             s0 = abs(s0 / n - m0 * m0);
        
             float sigma2 = s0.r + s0.g + s0.b;
             if (sigma2 < min_sigma2) {
                 min_sigma2 = sigma2;
                 __nv_out = float4(m0, 1.0);
             }
        
             m1 /= n;
             s1 = abs(s1 / n - m1 * m1);
        
             sigma2 = s1.r + s1.g + s1.b;
             if (sigma2 < min_sigma2) {
                 min_sigma2 = sigma2;
                 __nv_out = float4(m1, 1.0);
             }
        
             m2 /= n;
             s2 = abs(s2 / n - m2 * m2);
        
             sigma2 = s2.r + s2.g + s2.b;
             if (sigma2 < min_sigma2) {
                 min_sigma2 = sigma2;
                 __nv_out = float4(m2, 1.0);
             }
        
             m3 /= n;
             s3 = abs(s3 / n - m3 * m3);
        
             sigma2 = s3.r + s3.g + s3.b;
             if (sigma2 < min_sigma2) {
                 min_sigma2 = sigma2;
                 __nv_out = float4(m3, 1.0);
             }
        
    	float4 factor = mix(texColorX,__nv_out,1.0);

    	__nv_out = mix(texColor, factor, u.alpha) * texColor.a;
          }
    return __nv_out;
}
