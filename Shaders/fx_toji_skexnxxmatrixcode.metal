// ---------------------------------------------------------------------------
// Matrix Code
// origem : assets/effects/toji-skexnxxmatrixcode.xml
// id     : com.alightcreative.effects.matrixcode
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxmatrixcodeParams {
    int typeC;
    float2 position;
    float progressa;
    float scale;
    float bright;
    float alpha;
    float angle;
    float4 color1;
    float4 color2;
    int blendMode;
};

// --- funcoes auxiliares do efeito
float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   /////////////////////////
    
    #define CELLS float2(64.0,30.0)
    #define FALLERS 14.0
    #define FALLERHEIGHT 12.0
    
    float2 rand(float2 uv) {
        return floor(abs(__nv_mod(cos(
            uv * 652.6345 + uv.yx * 534.375 +
            0.5 * 0.0000005 * dot(uv, float2(0.364, 0.934))), 0.001)) * 16000.0);
    }
    
    float fallerSpeed(float col, float faller) {
        return __nv_mod(cos(col * 363.435  + faller * 234.323), 0.1) * 1.0 + 0.3;
    }

fragment float4 fx_toji_skexnxxmatrixcode(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxmatrixcodeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> codex [[texture(1)]],
    texture2d<float> codex2 [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& codex_info [[buffer(3)]],
    constant NovaTexInfo& codex2_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 syamjaidtz;
        // if (adaptive) { syamjaidtz = in.acScreenNorm; }
        // else { 
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
        // }

        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((180.0+u.angle)*0.0174533);
        syamjaidtz += u.position*float2(-1.,1.)/500.;
        
        /////////////////////////

    	float4 result;
    	
    	float2 uv = syamjaidtz;
    	uv.y = 1.-uv.y;
        
        float2 pix = __nv_mod(uv, 1.0/CELLS);
        float2 cell = (uv - pix) * CELLS;
        pix *= CELLS * float2(0.8, 1.0) + float2(0.1, 0.0);
       
        float c;
        if (u.typeC==0) { c = codex.sample(__nv_smp, (rand(cell) + pix) / 16.0).x; }
        else if (u.typeC==1) { c = codex2.sample(__nv_smp, (rand(cell) + pix) / 16.0).x; }
        
        float b = 0.0;
        for (float i = 0.0; i < FALLERS; ++i) {
            float f = 3.0 - cell.y * 0.05 -
                __nv_mod((u.progressa + i * 3534.34) * fallerSpeed(cell.x, i), FALLERHEIGHT);
            if (f > 0.0 && f < 1.0)
                b += f;
        }
        
        result = float4(0.0, c * b, 0.0, 1.0);
        
    	const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float4 gradmap;
            float luminance = dot(result.rgb, luminanceWeighting);
            gradmap = mix(u.color1,u.color2,luminance)*result.a;
        
    	float4 factor = mix(texColorX,gradmap,u.alpha);
    	// float4 factor = mix(texColorX,result,u.alpha);
    	
        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (factor * u.bright) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            factor *= u.bright;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = resultfinal;
    return __nv_out;
}
