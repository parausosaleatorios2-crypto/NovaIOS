// ---------------------------------------------------------------------------
// @am:string/effect_displacemap_name
// origem : assets/effects/toji-displacemap.xml
// id     : com.alightcreative.effects.displacemap
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_displacemapParams {
    float2 offs;
    int type;
    int edges;
    int fromctr;
    int invert;
};

fragment float4 fx_toji_displacemap(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_displacemapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 adjOffs = u.offs / 1000.0;
            adjOffs.x *= eng.acLayerSize.x/eng.acLayerSize.y * -1.0;
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float p;
            if( u.type==0 ) {
                p = texColor.r*0.2126 + texColor.g*0.7152 + texColor.b*0.0722;
            } else if( u.type == 1 ) {
                p = texColor.r;
            } else if( u.type == 2 ) {
                p = texColor.g;
            } else if( u.type == 3 ) {
                p = texColor.b;
            } else {
                adjOffs *= 0.0;
            }
            if( u.fromctr ) {
                p = (p-0.5)*2.0;
            }
            if( u.invert ) {
                adjOffs *= (1.0-p) * texColor.a;
            } else {
                adjOffs *= p * texColor.a;
            }
            float2 sample = in.acScreenNorm + adjOffs;
            if(u.edges==0) {
                __nv_out = comp.sample(__nv_smp, sample);
            } else if(u.edges==1) {
                sample = float2(1.0,1.0) - abs(__nv_mod(sample, float2(2.0,2.0))-float2(1.0,1.0));
                __nv_out = comp.sample(__nv_smp, sample) * texColor.a;
            } else if(u.edges==2) {
                if( sample.x < 0.0 || sample.x > 1.0 || sample.y < 0.0 || sample.y > 1.0 ) {
                    __nv_out = float4(0.0,0.0,0.0,0.0);
                } else {
                    __nv_out = comp.sample(__nv_smp, sample) * texColor.a;
                }
            } else if(u.edges==3) {
                sample = __nv_mod(sample, float2(1.0,1.0));
                __nv_out = comp.sample(__nv_smp, sample) * texColor.a;
            } else {
                __nv_out = comp.sample(__nv_smp, sample) * texColor.a;
            }
    return __nv_out;
}
