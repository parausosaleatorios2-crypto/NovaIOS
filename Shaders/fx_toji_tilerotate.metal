// ---------------------------------------------------------------------------
// @am:string/effect_tilerotate_name
// origem : assets/effects/toji-tilerotate.xml
// id     : com.alightcreative.effects.tilerotate
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_tilerotateParams {
    float rotation;
    float2 position;
    float amount;
    float stretch;
    float angle;
    float strength;
    float seed;
    int screenSpace;
};

// --- funcoes auxiliares do efeito
#define l2s(v) ((float4(v,0.,1.)*eng.acLayerToScreen).xy)

        static float rand(float2 co)
        {
            float a = 719.310;
            float b = 178.233;
            float c = 33758.5453;
            float dt= dot(co.xy ,float2(a,b));
            float sn= __nv_mod(dt, 3.14);
            return fract(sin(sn) * c);
        }

fragment float4 fx_toji_tilerotate(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_tilerotateParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float offset = 0.5;
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 relPos = (u.position/1200.0);
            float layerSizeMag = length(eng.acLayerSize);
            float2 st;
            if(u.screenSpace) {
                st = in.acScreenNorm;
                st.y = 1.0  - st.y;
                st -= 0.5;
                st.x *= eng.acScreenSize.x/eng.acScreenSize.y;
                st -= relPos;
            } else {
                st = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/layerSizeMag-relPos;
            }
            
            float a = u.angle * 0.0174533;
            float ra = u.rotation * 0.0174533;
            st *= float2x2(
                cos(a), -sin(a),
                sin(a), cos(a)
            );
            float px = floor(st.x*u.amount);
            float py = floor(st.y*u.amount/u.stretch);
            float rmag = rand(float2(px,py+3937.7249*u.seed));
            ra += (rmag-0.5)*2.0*6.28318*u.strength;
            float2 pcenter = float2((px+offset)/u.amount,(py+offset)/(u.amount/u.stretch));
            pcenter *= float2x2(
                cos(-a), -sin(-a),
                sin(-a), cos(-a)
            );
            if(u.screenSpace) {
                pcenter += relPos;
                pcenter *= (eng.acScreenSize.y/eng.acScreenSize.x);
                pcenter += 0.5;
                pcenter.y = 1.0-pcenter.y;
            }
            else {
                pcenter += relPos;
                pcenter *= layerSizeMag;
                pcenter += eng.acLayerCenter;
                pcenter /= eng.acScreenSize;
                pcenter.y = 1.0-pcenter.y;
            }
            
            float2 sampCoord = in.acScreenNorm;
            sampCoord -= pcenter;
            sampCoord *= float2x2(
                cos(ra), -sin(ra),
                sin(ra), cos(ra)
            );
            sampCoord += pcenter ;
            //float dx = rand(float2(px,py+3937.7249*u.seed));
            //float dy = rand(float2(px+328.7319+432.7249*u.seed,py-971.382));
            //float2 dv = (float2(dx,dy) - 0.5)*2.0;
            //float2 sampCoord = in.acScreenNorm+dv*u.strength;
            sampCoord = abs(__nv_mod(sampCoord-1.0, 2.0)-1.0);
            float4 sampColor = inputImg.sample(__nv_smp, sampCoord);
            //sampColor.r = length(in.acScreenNorm-pcenter);
            //sampColor.g = length(in.acScreenNorm-pcenter);
            __nv_out = sampColor * texColor.a;
    return __nv_out;
}
