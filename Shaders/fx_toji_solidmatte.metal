// ---------------------------------------------------------------------------
// @am:string/effect_solidmatte_name
// origem : assets/effects/toji-solidmatte.xml
// id     : com.alightcreative.solidmatte
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_solidmatteParams {
    float4 color;
    float alpha;
    int punchout;
    int screenSpace;
};

fragment float4 fx_toji_solidmatte(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_solidmatteParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 frontColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float4 backColor = u.color * u.alpha;
            if( !u.screenSpace ) {
                float insideLayer = step(0.0,in.acLayerNorm.x) * step(in.acLayerNorm.x,1.0) * step(0.0,in.acLayerNorm.y) * step(in.acLayerNorm.y,1.0);
                backColor *= insideLayer;
            }
            if( u.punchout ) {
                __nv_out = backColor*(1.-frontColor.a);
            } else {
                __nv_out = backColor*(1.-frontColor.a)+frontColor;
            }
    return __nv_out;
}
