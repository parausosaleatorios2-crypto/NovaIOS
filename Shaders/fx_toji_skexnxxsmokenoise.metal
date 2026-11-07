// ---------------------------------------------------------------------------
// Smoke Noise
// origem : assets/effects/toji-skexnxxsmokenoise.xml
// id     : com.alightcreative.effects.smokenoise
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxsmokenoiseParams {
    float4 color;
    float2 position;
    float lowThreshold;
    float progressd;
    float thick;
    float alpha;
    float angle;
    int blendMode;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) {
    return a * (1. - b.a) + b;
    }
    
    float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
   /////////////////////////
    
   float random(float x) {
     
        return fract(sin(x) * 10000.);
        
    }
    
    float noise(float2 p) {
        
     	return random(p.x + p.y * 10000.);
        
    }
    
    float2 sw(float2 p) { return float2(floor(p.x), floor(p.y)); }
    float2 se(float2 p) { return float2(ceil(p.x), floor(p.y)); }
    float2 nw(float2 p) { return float2(floor(p.x), ceil(p.y)); }
    float2 ne(float2 p) { return float2(ceil(p.x), ceil(p.y)); }
    
    float smoothNoise(float2 p) {
     
        float2 interp = smoothstep(0., 1., fract(p));
        float s = mix(noise(sw(p)), noise(se(p)), interp.x);
        float n = mix(noise(nw(p)), noise(ne(p)), interp.x);
        return mix(s, n, interp.y);
        
    }
    
    float fractalNoise(float2 p) {
     
        float n = 0.;
        n += smoothNoise(p);
        n += smoothNoise(p * 2.) / 2.;
        n += smoothNoise(p * 4.) / 4.;
        n += smoothNoise(p * 8.) / 8.;
        n += smoothNoise(p * 16.) / 16.;
        n /= 1. + 1./2. + 1./4. + 1./8. + 1./16.;
        return n;
        
    }

fragment float4 fx_toji_skexnxxsmokenoise(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxsmokenoiseParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> black [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& black_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
        float4 blackTex = black.sample(__nv_smp, in.acScreenNorm);
     
        float2 syamjaidtz = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
        syamjaidtz.y*=eng.acLayerSize.y/eng.acLayerSize.x;

        syamjaidtz /= 1.0;
        syamjaidtz *= rot2m(u.angle*0.0174533);
        // syamjaidtz += u.position*float2(-1.,1.)/500.;
        syamjaidtz += float2((0.0+u.position.x), (-350.0+u.position.y))*float2(-1.,1.)/500.;
                        
        /////////////////////////
        
        
    	float4 result;
    	
    	// float2 uv = fragCoord.xy / iResolution.xy;
    	float2 uv = syamjaidtz;
        float2 nuv = float2(uv.x - 1.0 / 6., uv.y);
        uv *= float2(1., -1.);
        
    	float x = fractalNoise(nuv * u.progressd);
    	// float4 coloring = float4(u.color.rgb,1.0) * texColor.a;
        float3 final = mix(float3(x), black.sample(__nv_smp, uv).xyz, pow(abs(uv.y), 4.0));
        
        result = float4(final, 1.) * float4(u.color.rgb,1.0);
        
   	float4 factorr = (result + (result*u.thick)) * u.alpha;
        
            float4 targetLuma = factorr;
            const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float luma = dot(targetLuma.rgb, luminanceWeighting);
            float lowThresholdB = (u.lowThreshold*(1.0+1.0))-0.001;
            float lowThresholdA = lowThresholdB-max(1.0, 0.00001);
            float highThresholdA = (1.0*(1.0+1.0)-1.0)+0.001;
            float highThresholdB = highThresholdA+max(1.0, 0.00001);
            float lowBlend = smoothstep( lowThresholdA, lowThresholdB, luma );
            float highBlend = 1. - smoothstep( highThresholdA, highThresholdB, luma );
            float lumafx = min(lowBlend,highBlend);
            float4 factor = targetLuma*lumafx;
            	
        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            factor *= texColor.a;
            resultfinal = newLayer(texColor, factor) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = mix(texColor,resultfinal,1.0) * texColor.a;
    return __nv_out;
}
