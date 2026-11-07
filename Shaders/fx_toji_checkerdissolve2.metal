// ---------------------------------------------------------------------------
// @am:string/effect_blockdissolve_name
// origem : assets/effects/toji-checkerdissolve2.xml
// id     : com.alightcreative.effects.checkerdissolve2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_checkerdissolve2Params {
    float amount;
    float size;
    float2 stretch;
    float seed;
    float fade;
    float2 offset;
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

fragment float4 fx_toji_checkerdissolve2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_checkerdissolve2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st = floor((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
            float t = u.seed*3197.3791;
            t = __nv_mod(t, 2.8)+2.7;
            float tileSize = min(eng.acLayerSize.x, eng.acLayerSize.y)/u.size;
            st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            st -= u.offset/1000.0;
            st *= tileSize;
            float2 scaleVec;
            st.x /= u.stretch.x;
            st.y /= u.stretch.y;
            st = floor(st);

            // st.x /= u.stretch;
            // st /= tileSize;
            // st += u.offset/1000.0;
            // st.x /= eng.acLayerSize.x/eng.acLayerSize.y;

            float r = rand( st*t );
            //r = step(u.amount,r);
            //float scale = 1.0/(1.0+u.fade);
            //r = smoothstep(u.amount*scale, (u.amount+u.fade)*scale, r);
            float adjFade = max(u.fade,0.00001);
            float adjAmount = u.amount;
            adjAmount -= 0.5;
            adjAmount *= 1.0+(adjFade*2.0);
            adjAmount += 0.5;
            r = smoothstep(adjAmount-adjFade, adjAmount+adjFade, r);
            __nv_out = texColor*r;
    return __nv_out;
}
