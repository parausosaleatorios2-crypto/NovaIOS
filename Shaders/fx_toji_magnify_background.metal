// ---------------------------------------------------------------------------
// @am:string/effect_magnify_background_name
// origem : assets/effects/toji-magnify-background.xml
// id     : com.alightcreative.effects.magnifybg
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_magnify_backgroundParams {
    float scale;
    int scaleMask;
    int sample;
};

// --- funcoes auxiliares do efeito
static float2x2 rot2(float a) {
            float c = cos(a);
            float s = sin(a);
            return float2x2(c, -s, s, c);
        }
        
        static float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }

fragment float4 fx_toji_magnify_background(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_magnify_backgroundParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
            float2 st = in.acLayerNorm;
            st -= 0.5;
            st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            st /= u.scale;
            st.x /= eng.acLayerSize.x/eng.acLayerSize.y;
            st += 0.5;

            float2 sampleCoord = l2s(st);

            if( u.sample == 0 ) {
                sampleCoord *= eng.acScreenSize;
                sampleCoord = floor(sampleCoord) + 0.5;
                sampleCoord /= eng.acScreenSize;
            }

            float4 scaledTexColor = comp.sample(__nv_smp, sampleCoord);
            if( u.scaleMask ) {
                float4 baseColor = inputImg.sample(__nv_smp, sampleCoord);
                __nv_out = scaledTexColor*baseColor.a;
            } else {
                float4 baseColor = inputImg.sample(__nv_smp, in.acScreenNorm);
                __nv_out = scaledTexColor*baseColor.a;
            }
    return __nv_out;
}
