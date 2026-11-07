// ---------------------------------------------------------------------------
// @am:string/effect_raster_transform_name
// origem : assets/effects/toji-transform.xml
// id     : com.alightcreative.effects.transform
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_transformParams {
    float scale;
    float angle;
    float2 offset;
    int maskToLayer;
    float alpha;
    float fill;
    int sample;
};

// --- funcoes auxiliares do efeito
static float2x2 rot2(float a) {
            float c = cos(a);
            float s = sin(a);
            return float2x2(c, -s, s, c);
        }
        
        float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }

        float4 composite( float4 a, float4 b) {
            return a * (1. - b.a) + b;
        }

fragment float4 fx_toji_transform(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_transformParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
            float2 st = in.acLayerNorm;
            st -= u.offset/500.*float2(1.,-1.);
            st -= 0.5;
            st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            st *= rot2( -u.angle * 0.0174533 );
            st /= u.scale;
            st.x /= eng.acLayerSize.x/eng.acLayerSize.y;
            st += 0.5;

            float2 sampleCoord = l2s(st);
            if( u.sample == 0 ) {
                sampleCoord *= eng.acScreenSize;
                sampleCoord = floor(sampleCoord) + 0.5;
                sampleCoord /= eng.acScreenSize;
            }

            float4 scaledTexColor = inputImg.sample(__nv_smp, sampleCoord);
            if( u.maskToLayer ) {
                float4 baseColor = inputImg.sample(__nv_smp, in.acScreenNorm);
                __nv_out = composite(baseColor*u.fill, scaledTexColor*baseColor.a*u.alpha);
            } else if( u.fill > 0.0001 ) {
                float4 baseColor = inputImg.sample(__nv_smp, in.acScreenNorm);
                __nv_out = composite(baseColor*u.fill, scaledTexColor*u.alpha);
            } else {
                __nv_out = scaledTexColor * u.alpha;
            }
    return __nv_out;
}
