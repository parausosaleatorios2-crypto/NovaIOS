// ---------------------------------------------------------------------------
// Dithering
// origem : assets/effects/toji-skexnxxdith.xml
// id     : com.alightcreative.effects.dithh
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxdithParams {
    int type;
    float scale;
    float amount;
    float angle;
    float satt;
    float exposure;
    float gamma;
    float brightness;
    float contrast;
    float highlights;
    float shadows;
    float offset;
    float alpha;
    int greyscale;
    int inv;
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
   
        static float greyScale(in float3 col) {
            return dot(col, float3(0.2126, 0.7152, 0.0722));
        }
        
        static float2x2 rotate2d(float u.angle){
            return float2x2(cos(u.angle), -sin(u.angle), sin(u.angle),cos(u.angle));
        }
   
   /////////////////////////

fragment float4 fx_toji_skexnxxdith(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxdithParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> noisexx [[texture(0)]],
    texture2d<float> inputImg [[texture(1)]],
    texture2d<float> xdist [[texture(2)]],
    constant NovaTexInfo& noisexx_info [[buffer(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(3)]],
    constant NovaTexInfo& xdist_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
        
        float2 image_size = __nv_getTexSize(inputImg_info.size);
        float2 iRes = float2(eng.acScreenSize.x, eng.acScreenSize.y);
        
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm.st; 
        
        /////////////////////////
        
    	float4 __nv_out;
    	
            
            float2 uv = syamjaidtz;
            // float2 uv = fragCoord.xy / iResolution.xy;
            float4 colX = xdist.sample(__nv_smp, uv); 
            // float3 col = inputImg.sample(__nv_smp, uv).rgb; 
            float4 col = colX;
            if (u.greyscale) col.rgb = float3(greyScale(col.rgb));
            if (u.greyscale) col.rgb = float3(1.0) - col.rgb;
            
            uv *= iRes.xy;
            float2 p = rotate2d(u.angle) * uv * u.scale; 
            
            float pattern;
            float3 xnxx;
            if( u.type==0 ) {
           	pattern = sin( p.x ) * u.amount;
            xnxx = col.rgb * 10. * u.satt - 5. + pattern; }
        
            else if( u.type==1 ) {
            pattern = sin( p.x ) * sin( p.y ) * u.amount;
            xnxx = col.rgb * 10. * u.satt - 5. + pattern; }
            
            else if( u.type==2 ) {
            // col.rgb = float3(greyScale(col.rgb));
            pattern = noisexx.sample(__nv_smp, fragCoord / 4. * u.scale).r*u.amount/5.;
            xnxx = step(pattern, col.rgb); }
        
            __nv_out = float4( xnxx, 1.0 );
            // __nv_out = float4( xnxx, 1.0 );
        
    	float4 factor = mix(texColorX,__nv_out,1.0);

        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (factor * 1.0) * texColor.a;
            // resultfinal = (newLayer(texColor, factor) * 1.0) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            factor *= 1.0;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            factor *= 1.0;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	// __nv_out = colX;
    	__nv_out = mix(texColor, resultfinal, u.alpha);
    	//
    return __nv_out;
}
