// ---------------------------------------------------------------------------
// Firework Particle
// origem : assets/effects/toji-skexnxxfworks.xml
// id     : com.alightcreative.effects.fireworks
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxfworksParams {
    int blendMode;
    float2 position;
    float progress;
    float orientX;
    float orientY;
    float scale;
    float bright;
    float alpha;
    float AMOUNT;
    float SPARKS;
    int onecolor;
    float4 color1;
    float4 color2;
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
            
    // #define FIREWORKS u.AMOUNT
    // #define BASE_PAUSE FIREWORKS / 60.
    #define PI 3.14
    #define PI2 6.28
    
    // int u.SPARKS = int(SPARKSS);
    
    float n21(float2 n) {
        return fract(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
    }
    
    float2 randomSpark(float noise) {
        float2 v0 = float2((noise - .5) * 13., (fract(noise * 123.) - .5) * 15.);
        return v0;
    }
    
    float2 circularSpark(float i, float noiseId, float noiseSpark) {
        noiseId = fract(noiseId * 7897654.45);
        float a = (PI2 / u.SPARKS) * i;
        float speed = 10.*clamp(noiseId, .7, 1.);
        float x = sin(a + u.orientX*((noiseId-.5)*3.));
        float y = cos(a + u.orientY*(fract(noiseId*4567.332) - .5)*2.);
        float2 v0 = float2(x, y) * speed;
        return v0;
    }
    
    
    float2 rocket(float2 start, float t) {
        float y = t;
        float x = sin(y*10.+cos(t*3.))*.1;
        float2 p = start + float2(x, y * 8.);
        return p;
    }
    
    float3 firework(float2 uv, float index, float pauseTime) {
        float3 col = float3(0.);
    
    
        float timeScale = 1.;
        float2 gravity = float2(0., -9.8);
    
        float explodeTime = .9;
        float rocketTime = 1.1;
        float episodeTime = rocketTime + explodeTime + pauseTime;
    
        float ratio = eng.acScreenSize.x / eng.acScreenSize.y;
    
        float timeScaled = (u.progress - pauseTime) / timeScale;
    
        float id = floor(timeScaled / episodeTime);
        float et = __nv_mod(timeScaled, episodeTime);
    
        float noiseId = n21(float2(id+1., index+1.));
    
        float u.scale = clamp(fract(noiseId*567.53)*30., 10., 30.);
        uv *= u.scale;
    
        rocketTime -= (fract(noiseId*1234.543) * .5);
    
        float2 pRocket = rocket(float2(0. + ((noiseId - .5)*u.scale*ratio), 0. - u.scale/2.), clamp(et, 0., rocketTime));
    
        if (et < rocketTime) {
            float rd = length(uv - pRocket);
            col += pow(.05/rd , 1.9) * float3(0.9, .3, .0);
        }
    
    
        if (et > rocketTime && et < (rocketTime + explodeTime)) {
            float burst = sign(fract(noiseId*44432.22) - .6);
            for(int i = 0 ; i < int(u.SPARKS) ; i++) {
                    float2 center = pRocket;
                    float fi = float(i);
                    float noiseSpark = fract(n21(float2(id*10.+index*20., float(i+1))) * 332.44);
                    float t = et - rocketTime;
                    float2 v0;
    
                    if (fract(noiseId*3532.33) > .5) {
                        v0 = randomSpark(noiseSpark);
                        t -= noiseSpark * (fract(noiseId*543.) * .2);
                    } else {
                        v0 = circularSpark(fi, noiseId, noiseSpark);
    
                        if ( (fract(noiseId*973.22) - .5) > 0.) {
                            float re = __nv_mod(fi, 4. + 10. * noiseId);
                            t -= floor(re/2.) * burst * .1;
                        } else {
                            t -= __nv_mod(fi, 2.) == 0. ? 0. : burst * .5*clamp(noiseId, .3, 1.);
                        }
                    }
    
                    float2 s = v0*t + (gravity * t * t) / 2.;
    
                    float2 p = center + s;
    
                    float d = length(uv - p);
    
                    if (t > 0.) {
                        float fade = clamp((1. - t/explodeTime), 0., 1.);
                        float3 sparkColor = float3(noiseId*.9, .5*fract(noiseId *456.33), .5*fract(noiseId *1456.33));
                        float3 c = (.05 / d) * sparkColor;
                        col += c * fade;
                    }
                }
        }
    
    
        return col;
    }

fragment float4 fx_toji_skexnxxfworks(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxfworksParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> black [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& black_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            
        float4 texColorX = black.sample(__nv_smp, in.acScreenNorm);
        float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
                        
        /////////////////////////
        
        
    	float4 result;
    	
    	float2 uv = in.acScreenNorm;
    	uv /= u.scale;
        uv += u.position*float2(-1.,1.)/500.;
    	
        uv -= 0.5;
        uv.x *= eng.acScreenSize.x / eng.acScreenSize.y;
    
        float3 col = float3(0.);
    
        for (float i = 0. ; i < u.AMOUNT ; i += 1.) {
            col += firework(uv, i + 1., (i * (u.AMOUNT/60.0)));
        }
    
        result = float4(col, 1.);
        
            const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float4 gradmap;
            float luminance = dot(result.rgb, luminanceWeighting);
            gradmap = mix(u.color1,u.color2,luminance)*result.a;

        float4 factor;
        if ( u.onecolor ) { factor = mix(texColorX,gradmap,u.alpha); }
    	else { factor = mix(texColorX,result,u.alpha); }
    	
        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (factor * u.bright) * texColor.a;
        } else if( u.blendMode==1 ) {         // screen
            factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        }
            
    	__nv_out = mix(texColor,resultfinal, u.alpha) * texColor.a;
    return __nv_out;
}
