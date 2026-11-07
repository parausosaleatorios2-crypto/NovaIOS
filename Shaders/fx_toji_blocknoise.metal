// ---------------------------------------------------------------------------
// @am:string/effect_blocknoise_name
// origem : assets/effects/toji-blocknoise.xml
// id     : com.alightcreative.effects.blocknoise
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_blocknoiseParams {
    float size;
    float stretch;
    float amount;
    int mono;
    int freeze;
    int extremes;
    float2 position;
    float overshoot;
};

// --- funcoes auxiliares do efeito
float rand(float2 co)
        {
            float a = 719.310;
            float b = 178.233;
            float c = 33758.5453;
            float dt= dot(co.xy ,float2(a,b));
            float sn= __nv_mod(dt, 3.14);
            return fract(sin(sn) * c);
        }

fragment float4 fx_toji_blocknoise(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_blocknoiseParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st = floor((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter-u.position+float2(1234.23,5678.56))/eng.acLayerSize;
            float2 actualSize;
            if( u.stretch < 0.0 ) {
                actualSize = float2(u.size-u.stretch,u.size);
            } else {
                actualSize = float2(u.size,u.size+u.stretch);
            }
            actualSize = float2(150.)/actualSize;
            st = floor(st*actualSize)/actualSize;
            float c = u.overshoot; //clampRange? 1.0 : 2.0;
            float t = u.freeze ? 1.0 : eng.acTime;
            if( u.mono ) {
                float t = __nv_mod(t, 2.8)+2.7;
                float r = rand( st*t );
                if( u.extremes ) r = step(0.5,r);
                r = (r * u.amount * c) + 1.0 - u.amount;
                __nv_out = float4(float3(r),1.0)*texColor;
            } else {
                float tr = __nv_mod(t, 4.7)+2.87;
                float tg = __nv_mod(t, 2.8)+1.55;
                float tb = __nv_mod(t, 3.25)+6.271;
                float r = rand( st*tr );
                float g = rand( st*tg );
                float b = rand( st*tb );
                if( u.extremes ) r = step(0.5,r);
                if( u.extremes ) g = step(0.5,g);
                if( u.extremes ) b = step(0.5,b);
                r = (r * u.amount * c) + 1.0 - u.amount;
                g = (g * u.amount * c) + 1.0 - u.amount;
                b = (b * u.amount * c) + 1.0 - u.amount;
                __nv_out = float4(float3(r,g,b),1.0)*texColor;
            }
    return __nv_out;
}
