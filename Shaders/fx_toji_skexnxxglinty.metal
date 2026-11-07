// ---------------------------------------------------------------------------
// Star Glint
// origem : assets/effects/toji-skexnxxglinty.xml
// id     : com.alightcreative.effects.glinty
// passes : 2  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxglintyParams {
    int type;
    float threshold;
    float strength;
    float alpha;
    int gradColor;
    float4 color1;
    float4 color2;
    float scale;
    float iter;
};

// --- funcoes auxiliares do efeito
float4 newLayer( float4 a, float4 b) {
    return a * (1. - b.a) + b;
    }
    
    float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
    }
    
    float2 l2s( float2 v ) {
        return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
    }
    
   #define fragCoord __nv_fragCoord.xy
    
   /////////////////////////
   
   
   
   /////////////////////////

fragment float4 fx_toji_skexnxxglinty(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxglintyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xdist [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xdist_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 texelSize = 1.0 / __nv_getTexSize(xdist_info.size);
            float rad = 45.0 * 0.0174533;
            float2 velocity = float2(cos(rad)*(u.strength),-sin(rad)*(u.strength));
            velocity.x *= eng.acScreenSize.y / eng.acScreenSize.x;
            float speed = length(velocity / texelSize);
            int nSamples = int(clamp(speed, 1.01, 100.01));
            float4 outColor = xdist.sample(__nv_smp, in.acScreenNorm.st);
            for(int i=1; i<nSamples; i++ ) {
                float2 offset = velocity * (float(i) / float(nSamples - 1) - 0.5);
                float2 sampleCoord = in.acScreenNorm.st-offset;
                float insideTexture = step(0.0,sampleCoord.x) * step(sampleCoord.x,1.0) * step(0.0,sampleCoord.y) * step(sampleCoord.y,1.0);
                outColor += xdist.sample(__nv_smp, sampleCoord) * insideTexture;
            }
            float4 d1 = outColor/float(nSamples);
            //////////////////////////
            float2 texelSizeb = 1.0 / __nv_getTexSize(xdist_info.size);
            float radb = 135.0 * 0.0174533;
            float2 velocityb = float2(cos(radb)*(u.strength),-sin(radb)*(u.strength));
            velocityb.x *= eng.acScreenSize.y / eng.acScreenSize.x;
            float speedb = length(velocityb / texelSizeb);
            int nSamplesb = int(clamp(speedb, 1.01, 100.01));
            float4 outColorb = xdist.sample(__nv_smp, in.acScreenNorm.st);
            for(int ib=1; ib<nSamplesb; ib++ ) {
                float2 offsetb = velocityb * (float(ib) / float(nSamplesb - 1) - 0.5);
                float2 sampleCoordb = in.acScreenNorm.st-offsetb;
                float insideTextureb = step(0.0,sampleCoordb.x) * step(sampleCoordb.x,1.0) * step(0.0,sampleCoordb.y) * step(sampleCoordb.y,1.0);
                outColorb += xdist.sample(__nv_smp, sampleCoordb) * insideTextureb;
            }
            float4 d2 = outColorb/float(nSamplesb);
            //////////////////////////
            float2 texelSizec = 1.0 / __nv_getTexSize(xdist_info.size);
            float radc = 0.0 * 0.0174533;
            float2 velocityc = float2(cos(radc)*(u.strength),-sin(radc)*(u.strength));
            velocityc.x *= eng.acScreenSize.y / eng.acScreenSize.x;
            float speedc = length(velocityc / texelSizec);
            int nSamplesc = int(clamp(speedc, 1.01, 100.01));
            float4 outColorc = xdist.sample(__nv_smp, in.acScreenNorm.st);
            for(int ic=1; ic<nSamplesc; ic++ ) {
                float2 offsetc = velocityc * (float(ic) / float(nSamplesc - 1) - 0.5);
                float2 sampleCoordc = in.acScreenNorm.st-offsetc;
                float insideTexturec = step(0.0,sampleCoordc.x) * step(sampleCoordc.x,1.0) * step(0.0,sampleCoordc.y) * step(sampleCoordc.y,1.0);
                outColorc += xdist.sample(__nv_smp, sampleCoordc) * insideTexturec;
            }
            float4 d4 = outColorc/float(nSamplesc);
            //////////////////////////
            float2 texelSized = 1.0 / __nv_getTexSize(xdist_info.size);
            float radd = 90.0 * 0.0174533;
            float2 velocityd = float2(cos(radd)*(u.strength),-sin(radd)*(u.strength));
            velocityd.x *= eng.acScreenSize.y / eng.acScreenSize.x;
            float speedd = length(velocityd / texelSized);
            int nSamplesd = int(clamp(speedd, 1.01, 100.01));
            float4 outColord = xdist.sample(__nv_smp, in.acScreenNorm.st);
            for(int id=1; id<nSamplesd; id++ ) {
                float2 offsetd = velocityd * (float(id) / float(nSamplesd - 1) - 0.5);
                float2 sampleCoordd = in.acScreenNorm.st-offsetd;
                float insideTextured = step(0.0,sampleCoordd.x) * step(sampleCoordd.x,1.0) * step(0.0,sampleCoordd.y) * step(sampleCoordd.y,1.0);
                outColord += xdist.sample(__nv_smp, sampleCoordd) * insideTextured;
            }
            float4 d5 = outColord/float(nSamplesd);
            
            // float balpha = autob ? clamp(u.alpha, 1.0, 0.0) * speed : u.alpha;
            
            // float4 d3 = max(d1,d2) * balpha;
            // float4 d6 = max(d4,d5) * balpha;
            // float4 d7 = max(d3,d6) * balpha;
            
            float4 d3 = max(d1,d2) * u.alpha;
            float4 d6 = max(d4,d5) * u.alpha;
            float4 d7 = max(d3,d6) * u.alpha;
            
            float4 d8;
            if(u.type==0) {d8 = d3;}
            else if(u.type==1) {d8 = d6;}
            else if(u.type==2) {d8 = d7;}
            
            float4 oricol = inputImg.sample(__nv_smp, in.acScreenNorm);
            // __nv_out = u.strength > 0.0011 ? (oricol+d3) * oricol.a : oricol;
            __nv_out = u.strength > 0.0011 ? (oricol+d8) * oricol.a : oricol;
    return __nv_out;
}
