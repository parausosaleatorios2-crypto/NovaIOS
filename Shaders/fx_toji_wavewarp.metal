// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-wavewarp.xml
// id     : com.alightcreative.effects.wavewarp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_wavewarpParams {
    float yspace;
    float yamp;
    float xspace;
    float xamp;
    float phase;
};

fragment float4 fx_toji_wavewarp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_wavewarpParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st = in.acScreenNorm.xy*eng.acScreenSize;
            float2 offs = float2(
                sin((st.y+u.phase)/u.yspace)*u.yamp,
                sin((st.x+u.phase)/u.xspace)*u.xamp
            );
            __nv_out = inputImg.sample(__nv_smp, (st+offs)/eng.acScreenSize);
    return __nv_out;
}
