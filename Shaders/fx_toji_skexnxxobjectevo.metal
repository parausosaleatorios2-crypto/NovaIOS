// ---------------------------------------------------------------------------
// Object Evolution
// origem : assets/effects/toji-skexnxxobjectevo.xml
// id     : com.alightcreative.effects.objectevo
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxobjectevoParams {
    float posx;
    float posy;
    float posz;
    float angle;
    float alpha;
    float scale;
    float anglea;
    int pinch;
    float2 centerPoint;
    float strength;
    float radius;
    int syamjaidtz;
    float start;
    float end;
    float angleb;
    float feather;
    float4 color;
    float alphaa;
    int blendMode;
    int zinv;
    int xinv;
    int yinv;
    int ainv;
};

// --- funcoes auxiliares do efeito
//static float2 projectAndClamp(float2 a, float2 b) {
        //    return clamp(dot(a,b)/dot(b,b),0.0,1.0) * b;
        //}
        float2 project(float2 a, float2 b) {
            return (dot(a,b)/dot(b,b)) * b;
        }

        static float smoothstepRev(float edge0, float edge1, float x) {
            if(edge0 == edge1) return step(edge0, x);
            else return smoothstep(edge0, edge1, x);
        }

fragment float4 fx_toji_skexnxxobjectevo(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxobjectevoParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float adjStart = u.start;
            float adjEnd = u.end;
            float adjFeather = u.feather/100.0;
            float radwipe = u.angleb * 0.0174533;
            float2 v = normalize(float2(cos(radwipe),-sin(radwipe)));
            //float2 v = (float4(normalize(float2(cos(radwipe),-sin(radwipe))),0.0,1.0) * eng.acLayerToScreen).xy;
            //float p = length(projectAndClamp(in.acLayerNorm.st-float2(0.5,0.5), v))/length(v)+0.5;
            float p = dot(in.acLayerNorm.st-float2(0.5,0.5), v)+0.5;

            float p0 = smoothstepRev(adjStart-adjFeather,adjStart,p);
            float p1 = 1. - smoothstepRev(adjEnd,adjEnd+adjFeather,p);
            
            float rad = u.anglea* 0.0174533;
            float2x2 rot = float2x2(cos(rad),-sin(rad),sin(rad),cos(rad));
            float2x2 invrot = float2x2(cos(-rad),-sin(-rad),sin(-rad),cos(-rad));
            
            float2 sampleCoord = ((((in.acLayerNorm - 0.5) * rot) * float2((1.0/u.scale), 1.0)) * invrot) + 0.5;
            sampleCoord = (float4(sampleCoord,0.0,1.0) * eng.acLayerToScreen).xy;
            
            //////////////////////////
            if ( u.pinch ) {
            float2 center = eng.acLayerCenterNorm-(u.centerPoint/1000. * float2(-1.,1.));

            sampleCoord -= center;
            sampleCoord.x *= eng.acScreenSize.x / eng.acScreenSize.y;
            float dist = length(sampleCoord);
            if ( dist < u.radius ) {
                float p = dist / u.radius;
                if(u.strength > 0.) {
                    sampleCoord *= mix(1.0, smoothstep(0.0, u.radius / dist, p), u.strength * 0.75);
                } else {
                    sampleCoord *= mix(1.0, pow(p, 1.0 + u.strength * 0.75) * u.radius / dist, 1.0 - p);
                }
            }
            sampleCoord.x /= eng.acScreenSize.x / eng.acScreenSize.y;
            sampleCoord += center;
            }
            //////////////////////////
            
            float4 texColor;
            if( u.syamjaidtz ) {
            texColor = inputImg.sample(__nv_smp, sampleCoord) *p0*p1*u.alpha;
            } else {
            texColor = inputImg.sample(__nv_smp, sampleCoord) * u.alpha;
            }
            
            float4 result;
            if( u.blendMode==1 ) {
                result = float4((texColor.rgb/texColor.a)*u.color.rgb,1.0) * texColor.a;
            } else if( u.blendMode==2 ) {
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-u.color.rgb)),1.0) * texColor.a;
            } else {
                result = float4(u.color.rgb,1.0)*texColor.a;
            }
            __nv_out = mix(texColor,result,u.alphaa);
    return __nv_out;
}
