// ---------------------------------------------------------------------------
// Chromatic Abberation
// origem : assets/effects/toji-skexnxxchromabbr.xml
// id     : com.alightcreative.effects.chromabbr
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxchromabbrParams {
    float amp;
    float rgbsplit;
    float alphaa;
    int new;
};

// --- funcoes auxiliares do efeito
static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
        
        static float2 computeUVnew( float2 uv, float k, float kcube){
    
                float2 offsetScale = float2(1., 1.);
                if( eng.acScreenSize.y > eng.acScreenSize.x ) {
                    offsetScale.x *= eng.acScreenSize.x / eng.acScreenSize.y;
                } else {
                    offsetScale.y *= eng.acScreenSize.y / eng.acScreenSize.x;
                }
        uv *= offsetScale;
    
        float2 t = uv - (offsetScale * 0.5);
        float r2 = t.x * t.x + t.y * t.y;
    	float f = 0.;
        
        if( kcube == 0.0){
            f = 1. + r2 * k;
        }else{
            f = 1. + r2 * ( k + kcube * sqrt( r2 ) );
        }
        
        float2 nUv = f * t + (offsetScale * 0.5);
        //nUv.y = nUv.y;
        return nUv/offsetScale;
    
    }
    
        static float2 computeUV( float2 uv, float k, float kcube){
    
        float2 t = uv - .5;
        float r2 = t.x * t.x + t.y * t.y;
    	float f = 0.;
        
        if( kcube == 0.0){
            f = 1. + r2 * k;
        }else{
            f = 1. + r2 * ( k + kcube * sqrt( r2 ) );
        }
        
        float2 nUv = f * t + .5;
        nUv.y = nUv.y;
     
        return nUv;
        
    }

fragment float4 fx_toji_skexnxxchromabbr(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxchromabbrParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xdist [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xdist_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    
        if( eng.acPass == 0 ) {
            __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            }
        else if( eng.acPass==1 ) {
    
        float4 result;
    	float2 uv = in.acScreenNorm;
        // uv += position*float2(-1.,1.)/500.;
        // uv *= scalex;
        // uv *= rot2m(angle*0.0174533);

    	
    	//float2 uv = float2(__nv_fragCoord.x / resolution.x, __nv_fragCoord.y / resolution.y);
        float k = 0.0;
        float kcube = u.amp;
        if (kcube < -1.0) {
        kcube = kcube * kcube *-1.;
    }
        
        float offset = u.rgbsplit;
    
        result = float4(0.0);
    if (u.new) {
        float red = (inputImg.sample(__nv_smp, computeUVnew( float2(uv.x, uv.y), k + offset, kcube )).r); 
        float green = (inputImg.sample(__nv_smp, computeUVnew( float2(uv.x, uv.y), k, kcube)).g); 
        float blue = (inputImg.sample(__nv_smp, computeUVnew( float2(uv.x, uv.y), k - offset, kcube)).b); 
        result = float4( red, green,blue, 1.);
    } else {
        float red = inputImg.sample(__nv_smp, computeUV( float2(uv.x, uv.y), k + offset, kcube )).r; 
        float green = inputImg.sample(__nv_smp, computeUV( float2(uv.x, uv.y), k, kcube)).g; 
        float blue = inputImg.sample(__nv_smp, computeUV( float2(uv.x, uv.y), k - offset, kcube)).b; 
        result = float4( red, green,blue, 1.);
    }
    
    float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
    __nv_out = mix(texColor,result,u.alphaa) * texColor.a;
      
      }
    return __nv_out;
}
