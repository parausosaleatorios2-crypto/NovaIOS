// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-testblur.xml
// id     : com.alightcreative.effects.testblur
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_testblurParams {
    float strength;
};

fragment float4 fx_toji_testblur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_testblurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& hblur_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            int from = -max(1,int(u.strength));
            int to = max(1,int(u.strength));
            float4 outColor = float4(0.0);
            if( eng.acPass==0 ) {
                for(int i=from; i<to; i++ ) {
                    outColor += inputImg.sample(__nv_smp, float2(in.acScreenNorm.s + float(i)*(1.0/1280.0),in.acScreenNorm.t));
                }
            } else {
                for(int i=from; i<to; i++ ) {
                    outColor += hblur.sample(__nv_smp, float2(in.acScreenNorm.s,in.acScreenNorm.t + float(i)*(1.0/720.0)));
                }
            }
            __nv_out = outColor/(float(to)*2.0);
    return __nv_out;
}
