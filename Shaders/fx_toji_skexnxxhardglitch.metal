// ---------------------------------------------------------------------------
// Glitch Offset
// origem : assets/effects/toji-skexnxxhardglitch.xml
// id     : com.alightcreative.effects.hardglitch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxhardglitchParams {
    int type;
    float lowThreshold;
    float highThreshold;
    float feather;
    float progress;
    float glitchAmplitude;
    float seed;
    float glitchNarrowness;
    float glitchBlockiness;
    float glitchMinimizer;
    float alpha;
    int rcolor;
    int gcolor;
    int bcolor;
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
    
   /////////////////////////
    
   static float rand(float2 p)
    {
        float t = floor(u.progress * 20.) / 10.;
        return fract(sin(dot(p, float2(t * 12.9898, t * 78.233))) * 43758.5453);
    }
    
    static float noise(float2 uv, float blockiness)
    {   
        float2 lv = fract(uv);
        float2 id = floor(uv);
        
        float n1 = rand(id);
        float n2 = rand(id+float2(1,0));
        float n3 = rand(id+float2(0,1));
        float n4 = rand(id+float2(1,1));
        
        float2 u = smoothstep(0.0, 1.0 + blockiness, lv);
    
        return mix(mix(n1, n2, u.x), mix(n3, n4, u.x), u.y);
    }
    
    static float fbm(float2 uv, int count, float blockiness, float complexity)
    {
        float val = 0.0;
        float amp = 0.5;
        
        while(count != 0)
        {
        	val += amp * noise(uv, blockiness);
            amp *= 0.5;
            uv *= complexity;    
            count--;
        }
        
        return val;
    }

fragment float4 fx_toji_skexnxxhardglitch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxhardglitchParams&  u    [[buffer(1)]],
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
        

        /////////////////////////
        
    	float4 result;
    	
    	float2 uv = in.acScreenNorm;
        float aspect = eng.acScreenSize.x / eng.acScreenSize.y;
        float2 a = float2(uv.x * aspect , uv.y);
        float2 uv2 = float2(a.x / eng.acScreenSize.x, exp(a.y));
        uv2 *= rot2m(u.seed*0.0174533);
        
        float shift = u.glitchAmplitude * pow(fbm(uv2, 4, u.glitchBlockiness, u.glitchNarrowness), u.glitchMinimizer);
        
        float colR;
        if (u.rcolor) { colR = inputImg.sample(__nv_smp, float2(uv.x + shift, uv.y)).r * (1. - shift); }
        else { colR = inputImg.sample(__nv_smp, float2(uv.x - shift, uv.y)).r * (1. - shift); }
        
        float colG;
        if (u.gcolor) { colG = inputImg.sample(__nv_smp, float2(uv.x + shift, uv.y)).g * (1. - shift); }
        else { colG = inputImg.sample(__nv_smp, float2(uv.x - shift, uv.y)).g * (1. - shift); }
        
        float colB;
        if (u.bcolor) { colB = inputImg.sample(__nv_smp, float2(uv.x + shift, uv.y)).b * (1. - shift); }
        else { colB = inputImg.sample(__nv_smp, float2(uv.x - shift, uv.y)).b * (1. - shift); }

        
        float3 f = float3(colR, colG, colB);
        
        result = float4(f, 1.0);
        
    	float4 factor = result * u.alpha;
        factor *= texColor.a;
        float4 resultfinal = factor + (texColor*(1.0-factor.a));
        
            float4 targetLuma = resultfinal;
            const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
            float luma = dot(targetLuma.rgb, luminanceWeighting);
            float lowThresholdB = (u.lowThreshold*(1.0+u.feather))-0.001;
            float lowThresholdA = lowThresholdB-max(u.feather,0.00001);
            float highThresholdA = (u.highThreshold*(1.0+u.feather)-u.feather)+0.001;
            float highThresholdB = highThresholdA+max(u.feather,0.00001);
            float lowBlend = smoothstep( lowThresholdA, lowThresholdB, luma );
            float highBlend = 1. - smoothstep( highThresholdA, highThresholdB, luma );
            float lumafx = min(lowBlend,highBlend);
            float4 fxLuma = targetLuma*lumafx;
            
        float4 rfinal;
        if(u.type==0) { rfinal = resultfinal * texColor.a; }
        else if(u.type==1) { rfinal = fxLuma; }
        else if(u.type==2) { rfinal = newLayer(texColor,fxLuma); }

    	__nv_out = rfinal;
    	// __nv_out = layerM? newLayer(texColor,fxLuma) : fxLuma;
    return __nv_out;
}
