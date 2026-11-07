// ---------------------------------------------------------------------------
// @am:string/effect_wipe_name
// origem : assets/effects/toji-wipe.xml
// id     : com.alightcreative.effects.wipe
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_wipeParams {
    float start;
    float end;
    float angle;
    float feather;
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

fragment float4 fx_toji_wipe(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_wipeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float adjStart = u.start/100.0;
            float adjEnd = u.end/100.0;
            float adjFeather = u.feather/100.0;
            float rad = u.angle * 0.0174533;
            float2 v = normalize(float2(cos(rad),-sin(rad)));
            //float2 v = (float4(normalize(float2(cos(rad),-sin(rad))),0.0,1.0) * eng.acLayerToScreen).xy;
            //float p = length(projectAndClamp(in.acLayerNorm.st-float2(0.5,0.5), v))/length(v)+0.5;
            float p = dot(in.acLayerNorm.st-float2(0.5,0.5), v)+0.5;
            float p0 = smoothstepRev(adjStart-adjFeather,adjStart,p);
            float p1 = 1. - smoothstepRev(adjEnd,adjEnd+adjFeather,p);
            __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm.st)*p0*p1;
    return __nv_out;
}
