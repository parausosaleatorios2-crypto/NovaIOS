// ---------------------------------------------------------------------------
// @am:string/effect_mirror_name
// origem : assets/effects/toji-mirror.xml
// id     : com.alightcreative.effects.mirror
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_mirrorParams {
    int type;
    int blendMode;
    float alpha;
    float offset;
};

// --- funcoes auxiliares do efeito
static float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }

fragment float4 fx_toji_mirror(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_mirrorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 st = in.acLayerNorm;

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);

            if( u.type==1 ) {
                st.y = 1.-st.y;
                st.y += u.offset;
            } else {
                st.x = 1.-st.x;
                st.x += u.offset;
            }

            float4 color = inputImg.sample(__nv_smp, l2s(st));

            float4 result;
            if( u.blendMode==1 ) {
                result = float4((texColor.rgb/texColor.a)*color.rgb,1.0) * texColor.a;
            } else if( u.blendMode==2 ) {
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-color.rgb)),1.0) * texColor.a;
            } else if( u.blendMode==3 ) {
                result = texColor * (1.-color.a) + color;
            } else if( u.blendMode==4 ) {
                result = color * (1.-texColor.a) + texColor;
            } else {
                result = color;
            }

            __nv_out = mix(texColor,result,u.alpha);
    return __nv_out;
}
