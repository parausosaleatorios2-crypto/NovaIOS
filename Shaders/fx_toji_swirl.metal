// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-swirl.xml
// id     : com.alightcreative.effects.swirl
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_swirlParams {
    float strength;
    float radius;
};

fragment float4 fx_toji_swirl(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_swirlParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            // -- layer coordinates boilerplate --
            // This get 0.0~1.0 coordinates inside layer (if layer is not square, one axis will be 1.0 and one will be larger)
            //float2 st = (in.acScreenNorm.xy*eng.acScreenSize-eng.acLayerCenter)/eng.acLayerSize;
            //float2 ctr = eng.acLayerCenter/eng.acScreenSize;
            //float2 st = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
            //st.y*=eng.acLayerSize.y/eng.acLayerSize.x;
            // -- end boilerplate --

            float Radius = u.radius;
            float T = u.strength;

            float2 UV = in.acScreenNorm; //-eng.acLayerCenterNorm; //in.acScreenNorm.xy;

            //UV /= 2.0;

            UV -= eng.acLayerCenterNorm;

            //UV.y /= (eng.acScreenSize.y/eng.acScreenSize.x);

            float Dist = length(UV);

            if ( Dist < Radius )
            {
                float Percent = (Radius - Dist) / Radius;
                float A = ( T <= 0.5 ) ? mix( 0.0, 1.0, T/0.5 ) : mix( 1.0, 0.0, (T-0.5)/0.5 );
                float Theta = Percent * Percent * A * 8.0 * 3.14159;
                float S = sin( Theta );
                float C = cos( Theta );
                UV = float2( dot(UV, float2(C, -S)), dot(UV, float2(S, C)) );
            }
            UV += eng.acLayerCenterNorm;

            float2 p = (eng.acLayerCenterNorm-in.acScreenNorm)/eng.acLayerSizeNorm;
            __nv_out = inputImg.sample(__nv_smp, UV);
    return __nv_out;
}
