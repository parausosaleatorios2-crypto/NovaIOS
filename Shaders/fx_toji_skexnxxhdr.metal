// ---------------------------------------------------------------------------
// HDR Quality CC
// origem : assets/effects/toji-skexnxxhdr.xml
// id     : com.alightcreative.effects.hdr
// passes : 2  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxhdrParams {
    float strength;
    float exposure;
    float alpha;
    float iter;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) {
    return a * (1. - b.a) + b;
    }
    
    static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    static float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
   
   
   /////////////////////////

fragment float4 fx_toji_skexnxxhdr(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxhdrParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    texture2d<float> vblur [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]],
    constant NovaTexInfo& vblur_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float maxF = max(eng.acScreenSize.x, eng.acScreenSize.y);
        float2 texelSize = 1.0 / float2(maxF, maxF);
        
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm.st;
        
        /////////////////////////
        
    	float4 __nv_out;
    	
        // float4 compCol = comp.sample(__nv_smp, in.acScreenNorm);
        float4 texColorOri = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 blurCol = vblur.sample(__nv_smp, in.acScreenNorm.st);
        
            float3x3 rgb2yuv = float3x3(
                 0.299,     0.587,    0.114,
                -0.14713,  -0.28886,  0.436,
                 0.615,    -0.51499, -0.10001
            );
            float3x3 yuv2rgb = float3x3(
                1.0,  0.0,      1.13983,
                1.0, -0.39465, -0.58060,
                1.0,  2.03211,  0.0
            );
            float4 expCol = blurCol;
            float3 rgb = expCol.rgb;
            float a = expCol.a;

            rgb = rgb + float3(0.0)*a;
            rgb = pow(rgb,float3(1.0/1.0)); //Gamma 
            rgb = rgb * pow(2.0,-u.exposure);
            float4 exp = float4(rgb,a);
            
            float4 subb = float4((texColorOri.rgb-exp.rgb), texColorOri.a);
            
            float3 bot = subb.rgb;
            float3 top = float3(1,1,1) * exp.a;

            float3 t = smoothstep(0.5,0.5,bot);
            float3 result =
                    t * (1. - (1.-2.*(bot-0.5)) * (1.-top)) +
                    (1.-t) * ((2.*bot) * top);

            __nv_out = float4(result,subb.a);

    	__nv_out = mix(texColorOri, __nv_out, u.alpha);
    	//
    return __nv_out;
}
