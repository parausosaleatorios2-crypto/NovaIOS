// ---------------------------------------------------------------------------
// @am:string/effect_vignette_name
// origem : assets/effects/toji-vignette.xml
// id     : com.alightcreative.effects.vignette
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_vignetteParams {
    float scale;
    float roundness;
    float feather;
    float strength;
    float tint;
    float4 overlaycolor;
    int punchout;
};

fragment float4 fx_toji_vignette(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_vignetteParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st = in.acLayerNorm;
            st -= float2(0.5,0.5);
            st *= 2.;
            st /= (u.scale+(u.feather/4.0));

            float n = u.roundness+1.;
            float d = pow(abs(st.x),n)+pow(abs(st.y),n);
            float p = smoothstep(1.-u.feather,1.,d);

            float4 color = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            float4 darkColor = color;
            darkColor.rgb *= darkColor.rgb;
            darkColor.rgb = mix(darkColor.rgb,u.overlaycolor.rgb*color.a,u.tint);
            if(u.punchout) {
                __nv_out = mix(color,float4(0.),p*u.strength);
            } else {
                __nv_out = mix(color,darkColor,p*u.strength);
            }
    return __nv_out;
}
