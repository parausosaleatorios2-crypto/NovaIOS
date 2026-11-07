// ---------------------------------------------------------------------------
// @am:string/effect_channelmap_name
// origem : assets/effects/toji-channelmap.xml
// id     : com.alightcreative.effects.channelmap
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_channelmapParams {
    int red;
    int green;
    int blue;
    int alpha;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_toji_channelmap(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_channelmapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);

            float luminance = dot(texColor.rgb, luminanceWeighting);

            float2 s = step(float2(0.,0.), in.acLayerNorm) - step(float2(1.,1.), in.acLayerNorm);
            float maskFactor = s.x * s.y;

            float4 outColor = float4(0.0);

            if( texColor.a > 0.0 )
                texColor.rgb /= texColor.a;

            if( u.red==0 ) {
                outColor.r = texColor.r;
            } else if( u.red==1 ) {
                outColor.r = texColor.g;
            } else if( u.red==2 ) {
                outColor.r = texColor.b;
            } else if( u.red==3 ) {
                outColor.r = texColor.a;
            } else if( u.red==4 ) {
                outColor.r = luminance;
            } else if( u.red==5 ) {
                outColor.r = 0.0;
            } else {
                outColor.r = 1.0;
            }

            if( u.green==0 ) {
                outColor.g = texColor.r;
            } else if( u.green==1 ) {
                outColor.g = texColor.g;
            } else if( u.green==2 ) {
                outColor.g = texColor.b;
            } else if( u.green==3 ) {
                outColor.g = texColor.a;
            } else if( u.green==4 ) {
                outColor.g = luminance;
            } else if( u.green==5 ) {
                outColor.g = 0.0;
            } else {
                outColor.g = 1.0;
            }

            if( u.blue==0 ) {
                outColor.b = texColor.r;
            } else if( u.blue==1 ) {
                outColor.b = texColor.g;
            } else if( u.blue==2 ) {
                outColor.b = texColor.b;
            } else if( u.blue==3 ) {
                outColor.b = texColor.a;
            } else if( u.blue==4 ) {
                outColor.b = luminance;
            } else if( u.blue==5 ) {
                outColor.b = 0.0;
            } else {
                outColor.b = 1.0;
            }

            if( u.alpha==0 ) {
                outColor.a = texColor.r;
            } else if( u.alpha==1 ) {
                outColor.a = texColor.g;
            } else if( u.alpha==2 ) {
                outColor.a = texColor.b;
            } else if( u.alpha==3 ) {
                outColor.a = texColor.a;
            } else if( u.alpha==4 ) {
                outColor.a = luminance;
            } else if( u.alpha==5 ) {
                outColor.a = 0.0;
            } else {
                outColor.a = 1.0;
            }

            outColor.rgb *= outColor.a;

            __nv_out = outColor * maskFactor;
    return __nv_out;
}
