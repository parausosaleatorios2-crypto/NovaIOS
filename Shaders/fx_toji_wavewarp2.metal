// ---------------------------------------------------------------------------
// @am:string/effect_wavewarp_name
// origem : assets/effects/toji-wavewarp2.xml
// id     : com.alightcreative.effects.wavewarp2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_wavewarp2Params {
    float phase;
    float a1d;
    float m1;
    float m2;
    float a2d;
    float damping;
    float dampingSpace;
    float dampingOrigin;
    int screenSpace;
};

fragment float4 fx_toji_wavewarp2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_wavewarp2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float a1 = u.a1d * 0.0174533;
            float a2 = (u.a1d+u.a2d) * 0.0174533;

            float2 st;
            if( u.screenSpace ) {
                st = in.acScreenNorm;
            } else {
                st = in.acLayerNorm;
            }

            float2 raw_v = float2(cos(a1),-sin(a1));
            float raw_p = dot(st,raw_v);
            float space_damp = 1.0;
            if( u.dampingSpace < 0.0 ) {
                space_damp = 1.0 - ( clamp(abs(raw_p-u.dampingOrigin),0.0,1.0) * (0.0-u.dampingSpace));
            } else if( u.dampingSpace > 0.0 ) {
                space_damp = 1.0 - ( (1.0 - clamp(abs(raw_p-u.dampingOrigin),0.0,1.0) ) * u.dampingSpace);
            }

            float space = u.m1 * space_damp;

            float2 v = float2(cos(a1),-sin(a1)) * space;
            float p = dot(st,v);

            float ddist = abs(p/space);

            float damp = 1.0;
            if( u.damping < 0.0 ) {
                damp = 1.0 - ( clamp(abs(ddist-u.dampingOrigin),0.0,1.0) * (0.0-u.damping));
            } else if( u.damping > 0.0 ) {
                damp = 1.0 - ( (1.0 - clamp(abs(ddist-u.dampingOrigin),0.0,1.0) ) * u.damping);
            }

            float2 offs = float2(cos(a2),-sin(a2)) * (u.m2*damp)/100.0;
            offs *= sin(p+u.phase*6.28318);

            //if( !u.screenSpace ) {
            //    st = (float4(st,0.0,1.0) * eng.acLayerToScreen).xy;
            //}
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm+offs);
            __nv_out = texColor; //float4(ddist*texColor.a,texColor.gba);


            //float2x2 rot = float2x2(
            //    cos(a), -sin(a),
            //    sin(a), cos(a)
            //);
            //
            //float2 st = in.acLayerNorm;
            //st += sin((st*rot).y*freq+u.phase)*mag;
            //__nv_out = inputImg.sample(__nv_smp, (float4(st,0.0,1.0)*eng.acLayerToScreen).xy);
    return __nv_out;
}
