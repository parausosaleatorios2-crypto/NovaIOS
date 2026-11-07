// ---------------------------------------------------------------------------
// @am:string/effect_halftonedotscmyk_name
// origem : assets/effects/toji-halftonecmyk.xml
// id     : com.alightcreative.effects.halftonedotscmyk
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_halftonecmykParams {
    float amount;
    float strength;
    float blackWeight;
    float angle;
    float phase;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

        static float halftone(float a, float4 mask) {

            float rad = a * 0.0174533;
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

            // CMYK

            float k = min(1.-samp.r, min(1.-samp.g, 1.-samp.b)) * u.blackWeight;
            float c = k>=1.0 ? 0.0 : ((1.0 - samp.r) - k) / (1.0-k);
            float m = k>=1.0 ? 0.0 : ((1.0 - samp.g) - k) / (1.0-k);
            float y = k>=1.0 ? 0.0 : ((1.0 - samp.b) - k) / (1.0-k);

            float4 cmyk = float4(c,m,y,k);

            float lum = length(cmyk*mask) / length(mask);

            float dist = length(float2(absDistX,absDistY));
            float radius = u.strength*2.0;

            float mag = max(0., radius-dist);

            float p = smoothstep( 0.4,0.6, mag*lum) * samp.a;

            return p;
        }

fragment float4 fx_toji_halftonecmyk(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_halftonecmykParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float c = halftone(u.angle+15., float4(1., 0., 0., 0.));
            float m = halftone(u.angle+75., float4(0., 1., 0., 0.));
            float y = halftone(u.angle+0., float4(0., 0., 1., 0.));
            float k = halftone(u.angle+45., float4(0., 0., 0., 1.));

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);

            float4 outColor = float4(1.-c-k, 1.-m-k, 1.-y-k, 1.) * texColor.a;

            __nv_out = outColor;
    return __nv_out;
}
