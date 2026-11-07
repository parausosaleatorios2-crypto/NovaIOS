// ---------------------------------------------------------------------------
// 2D Tunnel
// origem : assets/effects/toji-skexnxx2dtuunnell.xml
// id     : com.alightcreative.effects.2dtuunnell
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxx2dtuunnellParams {
    float4 color1;
    float4 color2;
    int scalex;
    float scale;
    float progressa;
    float progressb;
    float progressc;
    float2 position;
    float2 stretch;
    float bright;
    float alpha;
    float angle;
    int blendMode;
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
   
   #define PI 3.14159
   
   /////////////////////////

fragment float4 fx_toji_skexnxx2dtuunnell(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxx2dtuunnellParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 syamjaidtz;
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;

        syamjaidtz /= u.scalex? (u.scale+0.7) : (u.scale-0.82);
        syamjaidtz *= rot2m((0.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;
        
        float2 scaleVec;
        scaleVec = float2(u.scale*u.stretch.x,u.scale*u.stretch.y);
        syamjaidtz /= scaleVec;
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            float2 center = syamjaidtz;
            center.x *= eng.acScreenSize.x / eng.acScreenSize.x;
                       
            float4 lineT;
            float a = 1. / length(center) + __nv_atan(center.x, center.y) / PI * u.progressb + u.progressa;
            float b = sin(a * PI * 8.) * dot(center, center) * eng.acScreenSize.y / (u.progressc + 300.0) - 0.3;
            float c = b * sin(length(center) - .1);

            lineT = mix(u.color1, u.color2, c);
            
            __nv_out = lineT;
            // __nv_out = newLayer(color3, lineT) * texColor.a;
        
    	float4 factor = mix(texColorX,__nv_out,1.0);

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
            
    	__nv_out = mix(texColor, resultfinal, u.alpha);
    	//
    return __nv_out;
}
