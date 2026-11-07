// ---------------------------------------------------------------------------
// @am:string/effect_dissolve_name
// origem : assets/effects/toji-dissolve.xml
// id     : com.alightcreative.effects.dissolve
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_dissolveParams {
    float amount;
    float seed;
};

// --- funcoes auxiliares do efeito
static float rand(float2 co)
        {
            float a = 719.310;
            float b = 178.233;
            float c = 33758.5453;
            float dt= dot(co.xy ,float2(a,b));
            float sn= __nv_mod(dt, 3.14);
            return fract(sin(sn) * c);
        }

fragment float4 fx_toji_dissolve(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_dissolveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st = floor((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
            //float c = overshoot; //clampRange? 1.0 : 2.0;
            float t = u.seed*3197.3791;
            t = __nv_mod(t, 2.8)+2.7;
            float r = rand( st*t );
            r = step(u.amount,r);
            __nv_out = texColor*r;
    return __nv_out;
}
