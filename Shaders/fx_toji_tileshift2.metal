// ---------------------------------------------------------------------------
// @am:string/effect_tileshift_name
// origem : assets/effects/toji-tileshift2.xml
// id     : com.alightcreative.effects.tileshift2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_tileshift2Params {
    float strength;
    float2 position;
    float amount;
    float2 stretch;
    float angle;
    float seed;
    int screenSpace;
};

// --- funcoes auxiliares do efeito
#define l2s(v) ((float4(v,0.,1.)*eng.acLayerToScreen).xy)

        float rand(float2 co)
        {
            float a = 719.310;
            float b = 178.233;
            float c = 33758.5453;
            float dt= dot(co.xy ,float2(a,b));
            float sn= __nv_mod(dt, 3.14);
            return fract(sin(sn) * c);
        }

fragment float4 fx_toji_tileshift2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_tileshift2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st;
            if(u.screenSpace) {
                st = in.acScreenNorm;
                st.y = 1.0  - st.y;
                st -= 0.5;
                st.x *= eng.acScreenSize.x/eng.acScreenSize.y;
                st -= (u.position/1200.0);
            } else {
                st = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/length(eng.acLayerSize)-(u.position/1200.0);
            }
            float a = u.angle * 0.0174533;
            st *= float2x2(
                sin(a), -cos(a),
                cos(a), sin(a)
            );
            float px = floor(st.x*u.amount/u.stretch.y);
            float py = floor(st.y*u.amount/u.stretch.x);
            float dx = rand(float2(px,py+3937.7249*u.seed));
            float dy = rand(float2(px+328.7319+432.7249*u.seed,py-971.382));
            float2 dv = (float2(dx,dy) - 0.5)*2.0;
            float2 sampCoord = in.acScreenNorm+dv*u.strength;
            sampCoord = abs(__nv_mod(sampCoord-1.0, 2.0)-1.0);
            float4 sampColor = inputImg.sample(__nv_smp, sampCoord);
            __nv_out = sampColor * texColor.a;
    return __nv_out;
}
