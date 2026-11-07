// ---------------------------------------------------------------------------
// BlackBar Maker+
// origem : assets/effects/toji-skexnxxbbmaker.xml
// id     : com.alightcreative.effects.bbmaker
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxbbmakerParams {
    float start;
    float angle;
    float4 colorbg;
    float startA;
    float endA;
    float angleA;
    float featherA;
};

// --- funcoes auxiliares do efeito
//static float2 projectAndClamp(float2 a, float2 b) {
        //    return clamp(dot(a,b)/dot(b,b),0.0,1.0) * b;
        //}
        float2 project(float2 a, float2 b) {
            return (dot(a,b)/dot(b,b)) * b;
        }
        
         static float4 newLayer( float4 a, float4 b) {
         return a * (1. - b.a) + b;
         }
         
            static float smoothstepRev(float edge0, float edge1, float x) {
            if(edge0 == edge1) return step(edge0, x);
            else return smoothstep(edge0, edge1, x);
        }

fragment float4 fx_toji_skexnxxbbmaker(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxbbmakerParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            float adjStartA = u.startA;
            float adjEndA = u.endA;
            float adjFeatherA = u.featherA/100.0;
            float radA = u.angleA * 0.0174533;
            float2 vA = normalize(float2(cos(radA),-sin(radA)));
            float pA = dot(in.acLayerNorm.st-float2(0.5,0.5), vA)+0.5;

            float p0A = smoothstepRev(adjStartA-adjFeatherA,adjStartA,pA);
            float p1A = 1. - smoothstepRev(adjEndA,adjEndA+adjFeatherA,pA);
            float4 wipebb = (u.colorbg * texColor.a)*p0A*p1A;

            //////////////////////////

            float adjStart = (0.0+u.start)/100.0;
            float adjEnd = (100.0-u.start)/100.0;
            float adjFeather = 0.0/100.0;
            float rad = u.angle * 0.0174533;
            adjStart = (-20.0+u.start)/100.0;
            adjEnd = (120.0-u.start)/100.0;
            float2 v = normalize(float2(cos(rad),-sin(rad)));
            float p = dot(in.acLayerNorm.st-float2(0.5,0.5), v)+0.5;
            float p0 = smoothstep(adjStart-adjFeather,adjStart,p);
            float p1 = 1. - smoothstep(adjEnd,adjEnd+adjFeather,p);
            float4 bbmaker = inputImg.sample(__nv_smp, in.acScreenNorm.st)*p0*p1;
            
            __nv_out = newLayer(wipebb, bbmaker) * texColor.a;
    return __nv_out;
}
