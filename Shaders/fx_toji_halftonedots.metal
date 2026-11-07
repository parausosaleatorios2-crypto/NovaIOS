// ---------------------------------------------------------------------------
// @am:string/effect_halftonedots_name
// origem : assets/effects/toji-halftonedots.xml
// id     : com.alightcreative.effects.halftonedots
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_halftonedotsParams {
    float amount;
    float strength;
    float angle;
    float phase;
    float4 color1;
    float4 color2;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_toji_halftonedots(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_halftonedotsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float rad = u.angle * 0.0174533;
            float2x2 rot = float2x2(cos(rad),-sin(rad),sin(rad),cos(rad));
            float2x2 invrot = float2x2(cos(-rad),-sin(-rad),sin(-rad),cos(-rad));

            float2 st = in.acScreenNorm;

            st -= eng.acLayerCenterNorm;
            st.y *= (eng.acScreenSize.y/eng.acScreenSize.x);
            st *= rot;

            // Y Distance

            float distY = __nv_mod(st.y*u.amount, 1.);

            if( distY < 0.5 ) {
                distY = -distY;
            } else {
                distY = 1.0-distY;
            }

            float absDistY = abs(distY);

            distY /= u.amount;

            // X Distance

            float xoffs = step(1.,__nv_mod(st.y*u.amount+0.5, 2.)) * u.phase;

            float distX = __nv_mod(st.x*u.amount+xoffs, 1.);

            if( distX < 0.5 ) {
                distX = -distX;
            } else {
                distX = 1.0-distX;
            }

            float absDistX = abs(distX);

            distX /= u.amount;

            // Sampling

            st.y += distY;
            st.x += distX;

            st *= invrot;
            st.y /= (eng.acScreenSize.y/eng.acScreenSize.x);
            st += eng.acLayerCenterNorm;

            float4 samp = inputImg.sample(__nv_smp, st);
            float lum = dot( samp.rgb, luminanceWeighting );

            float p = smoothstep( 0.4,0.6, lum + (1.-samp.a) + length(float2(absDistX,absDistY)) + u.strength - 0.5);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);

            //float4 u.color1 = float4(0., 0., 0., 1.);
            //float4 u.color2 = float4(1., 1., 1., 1.);

            float4 outColor = mix( u.color1, u.color2, p ) * texColor.a;

            __nv_out = outColor;
    return __nv_out;
}
