// ---------------------------------------------------------------------------
// @am:string/effect_streak_strips_name
// origem : assets/effects/toji-streakstrips.xml
// id     : com.alightcreative.effects.streakstrips
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_streakstripsParams {
    float amount;
    float angle;
    float phase;
    int maskToLayer;
    float alpha;
};

// --- funcoes auxiliares do efeito
static float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }
        
        float2x2 rot2d( float a ) {
            return float2x2(
                cos(a), -sin(a),
                sin(a), cos(a)
            );
        }

fragment float4 fx_toji_streakstrips(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_streakstripsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
            float2 st = in.acLayerNorm;
            
            float a = u.angle * 0.0174533;
            
            st -= 0.5;
            st *= rot2d(a);
            st += 0.5;
            
            st.y = floor((st.y + u.phase / 10.) * u.amount) / u.amount - u.phase / 10.;
            
            st -= 0.5;
            st *= rot2d(-a);
            st += 0.5;
            
            //st = __nv_mod(st + 1000., 1.);

            float4 baseColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float4 texColor = inputImg.sample(__nv_smp, l2s(st));
            
            float4 c = mix(baseColor,texColor,u.alpha);

            if(u.maskToLayer) {
                c *= baseColor.a;
                __nv_out = baseColor * (1.-c.a) + c;
            } else {
                __nv_out = c;
            }
    return __nv_out;
}
