// ---------------------------------------------------------------------------
// @am:string/effect_tunnel_name
// origem : assets/effects/toji-tunnel.xml
// id     : com.alightcreative.effects.tunnel
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_tunnelParams {
    float phase;
    float4 fogColor;
    float fog;
    float depth;
    float twirl;
    float wrap;
    float crop;
    int mirror;
};

fragment float4 fx_toji_tunnel(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_tunnelParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st = in.acLayerNorm;
            //st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            st -= float2(0.5,0.5); //+(center/1200.0*float2(1.,-1.));
            float tr = u.twirl * 0.0174533;
            float angle = __nv_atan(st.x, st.y);
            float radius = length(st);
            angle += tr*radius;
            float2 uv = float2( u.depth/radius + u.phase, angle/(3.1415927*2./u.wrap));
            if( u.mirror ) {
                uv = abs(__nv_mod(uv, 2.0)-1.0);
            } else {
                uv = __nv_mod(uv, 1.0);
            }
            uv -= 0.5;
            uv *= u.crop;
            uv += 0.5;
            float4 texColor = inputImg.sample(__nv_smp, (float4(uv,0.,1.)*eng.acLayerToScreen).xy);

            __nv_out = radius > 0.5 ? float4(0.) : mix(texColor,u.fogColor,clamp((1.-radius*2.)*u.fog,0.,1.));
    return __nv_out;
}
