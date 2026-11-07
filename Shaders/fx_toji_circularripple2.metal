// ---------------------------------------------------------------------------
// @am:string/effect_circularripple_name
// origem : assets/effects/toji-circularripple2.xml
// id     : com.alightcreative.effects.circularripple2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_circularripple2Params {
    float2 centerPoint;
    float frequency;
    float strength;
    float phase;
    float radius;
    float feather;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159;

fragment float4 fx_toji_circularripple2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_circularripple2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st = in.acScreenNorm;
            float2 center = u.centerPoint/1000. * float2(-1.,1.);

            float featherSize = u.radius*0.5*u.feather;
            float innerRadius = max(0.0,u.radius-featherSize);
            float outerRadius = max(innerRadius+0.00001,u.radius+featherSize);

            st -= eng.acLayerCenterNorm-center;

            st.y *= (eng.acScreenSize.y/eng.acScreenSize.x);

            float dist = length(st);

            float damping = smoothstep(outerRadius,innerRadius,dist);

            float2 offset = sin((dist*u.frequency*PI*2.0)+(u.phase*PI*2.0))*u.strength/2.0 * normalize(st) * damping;

            st += offset;

            st.y /= (eng.acScreenSize.y/eng.acScreenSize.x);

            st += eng.acLayerCenterNorm-center;

            __nv_out = inputImg.sample(__nv_smp, st);
    return __nv_out;
}
