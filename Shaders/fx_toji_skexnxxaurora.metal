// ---------------------------------------------------------------------------
// Aurora
// origem : assets/effects/toji-skexnxxaurora.xml
// id     : com.alightcreative.effects.aurora
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxauroraParams {
    float2 position;
    float progressa;
    float progressb;
    float progressc;
    float scale;
    float bright;
    float alpha;
    float angle;
    int adaptive;
    int blendMode;
};

// --- funcoes auxiliares do efeito
static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord
    
   /////////////////////////
    
    #define TAU 6.2831853071

fragment float4 fx_toji_skexnxxaurora(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxauroraParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texx [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& texx_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 syamjaidtz;
        if (u.adaptive) { syamjaidtz = in.acScreenNorm; }
        else { 
        syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;
        }

        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((0.0+u.angle)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;

        
        /////////////////////////

    	float4 result;
    	
    	float2 uv = syamjaidtz;
        
        float o = float4(0.,0.,0., uv * 0.25 + float2(0.0, u.progressa * 0.025)).r;
        float d = (texx.sample(__nv_smp, uv * 0.25 - float2(0.0, u.progressa * 0.02 + o * 0.02)).r * 2.0 - 1.0);
        
        float v = uv.y + d * 0.1;
        v = 1.0 - abs(v * 2.0 - 1.0);
        v = pow(v, 2.0 + sin((u.progressa * 0.2 + d * 0.25) * TAU) * 0.5);
        
        float3 color = float3(0.0);
        
        float x = (1.0 - uv.x * 0.75);
        float y = 1.0 - abs(uv.y * u.progressc - 1.0);
        color += float3(x * 0.5, y, x) * v;
        
        float2 seed = syamjaidtz;
        float2 r;
        r.x = fract(sin((seed.x * 12.9898) + (seed.y * 78.2330)) * 43758.5453);
        r.y = fract(sin((seed.x * 53.7842) + (seed.y * 47.5134)) * 43758.5453);
    
        float s = mix(r.x, (sin((u.progressa * 2.5 + 60.0) * r.y) * u.progressb + 0.5) * ((r.y * r.y) * (r.y * r.y)), 0.04); 
        color += pow(s, 70.0) * (1.0 - v);
        
        result.rgb = color;
        result.a = 1.0;
        
    	    // result
    	    // const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            // float4 gradmap;
            // float luminance = dot(result.rgb, luminanceWeighting);
            // gradmap = mix(color1,color2,luminance)*result.a;
        
    	// float4 factor = mix(texColorX,gradmap,u.alpha);
    	float4 factor = mix(texColorX,result,u.alpha);
    	
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
