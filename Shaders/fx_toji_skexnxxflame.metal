// ---------------------------------------------------------------------------
// Flame
// origem : assets/effects/toji-skexnxxflame.xml
// id     : com.alightcreative.effects.flame
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxflameParams {
    float2 position;
    float progress;
    float scale;
    float bright;
    float alpha;
    float angle;
    float4 color1;
    float4 color2;
    float alphab;
    int blendMode;
};

// --- funcoes auxiliares do efeito
static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    static float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   /////////////////////////
    
   static float rand(float2 n) {
        return fract(sin(cos(dot(n, float2(12.9898,12.1414)))) * 83758.5453);
    }
    
    static float noise(float2 n) {
        const float2 d = float2(0.0, 1.0);
        float2 b = floor(n), f = smoothstep(float2(0.0), float2(1.0), fract(n));
        return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
    }
    
    static float fbm(float2 n) {
        float total = 0.0, amplitude = 1.0;
        for (int i = 0; i <5; i++) {
            total += noise(n) * amplitude;
            n += n*1.7;
            amplitude *= 0.47;
        }
        return total;
    }

fragment float4 fx_toji_skexnxxflame(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxflameParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
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
        syamjaidtz.x = 1.-syamjaidtz.x;

        // }

        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((180.0+u.angle)*0.0174533);
        syamjaidtz += float2(u.position.x, (180.0+u.position.y))*float2(-1.,1.)/500.;
        
        /////////////////////////

    	float4 result;
    	
    	const float3 c1 = float3(0.5, 0.0, 0.1);
        const float3 c2 = float3(0.9, 0.1, 0.0);
        const float3 c3 = float3(0.2, 0.1, 0.7);
        const float3 c4 = float3(1.0, 0.9, 0.1);
        const float3 c5 = float3(0.1);
        const float3 c6 = float3(0.9);
    
        float2 speed = float2(0.1, 0.9);
        float shift = 1.327+sin(u.progress*2.0)/2.4;        
    	float dist = 3.5-sin(u.progress*0.4)/1.89;
        
        float2 uv = syamjaidtz;
        float2 p = syamjaidtz * dist;
        // float2 p = syamjaidtz * dist / eng.acScreenSize.xx;
        p += sin(p.yx*4.0+float2(.2,-.3)*u.progress)*0.04;
        p += sin(p.yx*8.0+float2(.6,+.1)*u.progress)*0.01;
        
        p.x -= u.progress/1.1;
        float q = fbm(p - u.progress * 0.3+1.0*sin(u.progress+0.5)/2.0);
        float qb = fbm(p - u.progress * 0.4+0.1*cos(u.progress)/2.0);
        float q2 = fbm(p - u.progress * 0.44 - 5.0*cos(u.progress)/2.0) - 6.0;
        float q3 = fbm(p - u.progress * 0.9 - 10.0*cos(u.progress)/15.0)-4.0;
        float q4 = fbm(p - u.progress * 1.4 - 20.0*sin(u.progress)/14.0)+2.0;
        q = (q + qb - .4 * q2 -2.0*q3  + .6*q4)/3.8;
        float2 r = float2(fbm(p + q /2.0 + u.progress * speed.x - p.x - p.y), fbm(p + q - u.progress * speed.y));
        float3 c = mix(c1, c2, fbm(p + r)) + mix(c3, c4, r.x) - mix(c5, c6, r.y);
        float3 color = float3(1.0/(pow(c+1.61,float3(4.0))) * cos(shift * eng.acScreenSize.y));
        
        color=float3(1.0,.2,.05)/(pow((r.y+r.y)* max(.0,p.y)+0.1, 4.0));;
        color += (float4(0.,0.,0.,uv*0.6+float2(.5,.1)).xyz*0.01*pow((r.y+r.y)*.65,5.0)+0.055)*mix( float3(.9,.4,.3),float3(.7,.5,.2), uv.y);
        color = color/(1.0+max(float3(0),color));
        result = float4(color.x, color.y, color.z, 1.0);
        
    	    const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float4 gradmap;
            float luminance = dot(result.rgb, luminanceWeighting);
            gradmap = mix(u.color1,u.color2,luminance)*result.a;
        
    	// float4 factor = mix(texColorX,gradmap,u.alpha);
    	float4 factorx = mix(result,gradmap,u.alphab);
    	float4 factor = mix(texColorX,factorx,u.alpha);
    	
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
