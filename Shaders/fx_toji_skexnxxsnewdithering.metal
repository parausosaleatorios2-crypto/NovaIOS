// ---------------------------------------------------------------------------
// toji-skexnxxsnewdithering.xml
// origem : assets/effects/toji-skexnxxsnewdithering.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e6e6577646974686572696e67
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsnewditheringParams {
    float SRGB_GAMMA;
    float SRGB_INVERSE_GAMMA;
    float SRGB_ALPHA;
    float alpha;
    int blendMode;
};

// --- funcoes auxiliares do efeito
//////////////////////////
    float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
        
        // Converts a single linear channel to srgb
        float linear_to_srgb(float channel) {
            if(channel <= 0.0031308)
                return 12.92 * channel;
            else
                return (1.0 + u.SRGB_ALPHA) * pow(channel, 1.0/u.SRGB_GAMMA) - u.SRGB_ALPHA;
        }
        
        // Converts a single srgb channel to rgb
        float srgb_to_linear(float channel) {
            if (channel <= 0.04045)
                return channel / 12.92;
            else
                return pow((channel + u.SRGB_ALPHA) / (1.0 + u.SRGB_ALPHA), u.SRGB_INVERSE_GAMMA);
        }
        
        // Converts a linear rgb color to a srgb color (exact, not approximated)
        float3 rgb_to_srgb(float3 rgb) {
            return float3(
                linear_to_srgb(rgb.r),
                linear_to_srgb(rgb.g),
                linear_to_srgb(rgb.b)
            );
        }
        
        // Converts a srgb color to a linear rgb color (exact, not approximated)
        float3 srgb_to_rgb(float3 srgb) {
            return float3(
                srgb_to_linear(srgb.r),
                srgb_to_linear(srgb.g),
                srgb_to_linear(srgb.b)
            );
        }
        
        float bayer2(float2 v)
        {
            v=floor(v);
         return fract(v.y*v.y*.75+v.x*.5);   
        }
        float bayer4(float2 v)
        {
            return bayer2(.5*v)*.25+bayer2(v);
        }
        float bayer8(float2 v)
        {
            return bayer4(.5*v)*.25+bayer2(v);
        }
        float bayer16(float2 v)
        {
            return bayer8(.5*v)*.25+bayer2(v);
        }
        float bayer32(float2 v)
        {
            return bayer16(.5*v)*.25+bayer2(v);
        }
        float bayer64(float2 v)
        {
            return bayer32(.5*v)*.25+bayer2(v);
        }
        float bayer128(float2 v)
        {
            return bayer64(.5*v)*.25+bayer2(v);
        }
    //////////////////////////

fragment float4 fx_toji_skexnxxsnewdithering(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsnewditheringParams&  u    [[buffer(1)]],
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
    	
            float2 uv = in.acScreenNorm.st;
            // float2 uv = I.xy / iResolution.xy;
            float d = bayer128(fragCoord)+0.00003051757;
            #define s floor(pow(2.0, 1.9)-1.0)
            __nv_out.rgb = srgb_to_rgb(inputImg.sample(__nv_smp, uv).rgb);
            __nv_out.rgb = rgb_to_srgb(floor(__nv_out.rgb*s+d)/s);
        
    	float4 factor = mix(texColorX,__nv_out,1.0);
    	
    	float hardness = 1.0;
        float4 resultfinal;
          if( u.blendMode==0 ) {
            resultfinal = (factor * hardness) * texColor.a; }
          else if( u.blendMode==1 ) { factor *= hardness;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a; }
          else if( u.blendMode==2 ) { factor *= hardness; 
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a; }
          else if( u.blendMode==3 ) { factor *= hardness; 
            resultfinal = (newLayer(texColorX, factor) * hardness) * texColor.a; }
            
    	__nv_out = mix(texColor, resultfinal, u.alpha) * texColor.a;
          }
    return __nv_out;
}
