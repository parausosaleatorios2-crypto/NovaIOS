// ---------------------------------------------------------------------------
// [X] Long Shadow+
// origem : assets/effects/toji-skexnxxlongshadow2new.xml
// id     : com.alightcreative.effects.longshadow2new
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxlongshadow2newParams {
    float size;
    float angle;
    float alpha;
    float solidity;
    float fill;
    float fade;
    int fadeType;
    float4 color1;
    float4 color2;
    int gradType;
    float2 position;
    float scale;
    float angleg;
};

// --- funcoes auxiliares do efeito
static float2x2 rot2m(float a){
        
	float s = sin(a);
	float c = cos(a);
	
	return float2x2(c, -s, s, c);
        }

        static float projectAndClampDist(float2 a, float2 b) {
            return clamp(dot(a,b)/dot(b,b),0.0,1.0);
        }

fragment float4 fx_toji_skexnxxlongshadow2new(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxlongshadow2newParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
        float2 syamjaidtz;
        syamjaidtz = in.acScreenNorm; 

        syamjaidtz /= u.scale;
        syamjaidtz *= rot2m((0.0+u.angleg)*0.0174533);
        syamjaidtz += float2((0.0+u.position.x), (0.0+u.position.y))*float2(-1.,1.)/500.;

            float t;
            if( u.gradType == 0 ) {
                t = syamjaidtz.x;
            } else if ( u.gradType == 1 ) {
                t = length( syamjaidtz - 0.5 ) * 2.0;
            } else if ( u.gradType == 2 ) {
                float2 xy = syamjaidtz - 0.5;
                float2 zw = float2(0,1.0);
                float a = __nv_atan(xy.x, xy.y);
                float b = __nv_atan(zw.x, zw.y);
                t = __nv_mod(((a-b)+6.28), 6.28)/6.28;
            } else {
                t = syamjaidtz.x;
            }

            t = clamp(t,0.0,1.0);
            float4 color = mix(u.color1, u.color2, t);
        
            float2 texelSize = 1.0 / __nv_getTexSize(inputImg_info.size);
            float rad = u.angle * 0.0174533;
            float2 velocity = float2(cos(rad)*u.size,-sin(rad)*u.size);
            //velocity *= eng.acPreviewSize*texelSize;
            if( eng.acScreenSize.y > eng.acScreenSize.x ) {
                velocity.y *= eng.acScreenSize.x / eng.acScreenSize.y;
            } else {
                velocity.x *= eng.acScreenSize.y / eng.acScreenSize.x;
            }
            float speed = length(velocity / texelSize);
            int nSamples = int(clamp(speed, 1.01, 500.01));
            float maxAlpha = 0.0;
            float accumAlpha = 0.0;
            int minDist = nSamples;
            float4 baseColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            for(int i=1; i<nSamples; i++ ) {
                float2 offset = velocity * (float(i) / float(nSamples - 1));
                float2 sampleCoord = in.acScreenNorm.st-offset;
                float insideTexture = step(0.0,sampleCoord.x) * step(sampleCoord.x,1.0) * step(0.0,sampleCoord.y) * step(sampleCoord.y,1.0);
                float sampAlpha = inputImg.sample(__nv_smp, sampleCoord).a * insideTexture;
                maxAlpha = max(maxAlpha, sampAlpha);
                if( sampAlpha > 0.5 ) {
                    minDist = min(minDist,i);
                }
                float adjAlpha = sampAlpha*u.solidity*0.25;
                accumAlpha = adjAlpha + accumAlpha*(1.0-adjAlpha);
            }
            float resultAlpha = mix(accumAlpha,maxAlpha,u.solidity);
            float dist = 0.0;
            if( u.fadeType==0 ) {
                dist = float(minDist)/float(nSamples);
            } else if( u.fadeType==1 ) {
                dist = projectAndClampDist(in.acScreenNorm-eng.acLayerCenterNorm,velocity);
            } else if( u.fadeType==2 ) {
                dist = abs((in.acScreenNorm-eng.acLayerCenterNorm).x) / abs(velocity.x);
            } else if( u.fadeType==3 ) {
                dist = abs((in.acScreenNorm-eng.acLayerCenterNorm).y) / abs(velocity.y);
            }
            //__nv_out = mix(mix(color * u.alpha * (1.0-dist*u.fade) * resultAlpha, baseColor, baseColor.a * u.fill),float4(1.0,0.0,0.0,1.0),abs(sin(dist*25.0)));
            __nv_out = mix(color * u.alpha * (1.0-dist*u.fade) * resultAlpha, baseColor, baseColor.a * u.fill);
    return __nv_out;
}
