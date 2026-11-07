// ---------------------------------------------------------------------------
// LUT Stealer
// origem : assets/effects/toji-skexnxxlutreader.xml
// id     : com.alightcreative.effects.lutreader
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxlutreaderParams {
    int enableLut;
    int RAW;
    float lutLevel;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////

fragment float4 fx_toji_skexnxxlutreader(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxlutreaderParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> RAWT [[texture(0)]],
    texture2d<float> inputImg [[texture(1)]],
    texture2d<float> buff1 [[texture(2)]],
    texture2d<float> comp [[texture(3)]],
    constant NovaTexInfo& RAWT_info [[buffer(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(3)]],
    constant NovaTexInfo& buff1_info [[buffer(4)]],
    constant NovaTexInfo& comp_info [[buffer(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float2 iResolution = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 iMouse = float2(0.5, 0.5);
        
        float2 syamjaidtz = 1.-in.acLayerNorm.st;
        
    	float4 __nv_out;
    	
            float4 textureColor1 = comp.sample(__nv_smp, in.acScreenNorm.st);
            float4 RawText = RAWT.sample(__nv_smp, syamjaidtz);
            
            if(u.RAW) { __nv_out = RawText * texColor.a; return __nv_out; }
            if(!u.enableLut) { __nv_out = textureColor1; return __nv_out; }
            
            float4 textureColor =float4(textureColor1.rgb * pow(2.0, -0.2), textureColor1.w);
            float blueColor = textureColor.b * 63.0;
        
            float2 quad1;
            quad1.y = floor(floor(blueColor) / 8.0);
            quad1.x = floor(blueColor) - (quad1.y * 8.0);
        
            float2 quad2;
            quad2.y = floor(ceil(blueColor) / 8.0);
            quad2.x = ceil(blueColor) - (quad2.y * 8.0);
        
            float2 texPos1;
            texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
            texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
            texPos1.y = 1. - texPos1.y;
        
            float2 texPos2;
            texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
            texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
            texPos2.y = 1. - texPos2.y;
        
            float4 newColor1 = inputImg.sample(__nv_smp, texPos1);
            float4 newColor2 = inputImg.sample(__nv_smp, texPos2);
        
            float4 newColor = mix(newColor1, newColor2, fract(blueColor));
            __nv_out = mix(textureColor, float4(newColor.rgb, textureColor.w), u.lutLevel);
        
    	__nv_out = __nv_out * texColor.a;
    return __nv_out;
}
