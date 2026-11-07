// ---------------------------------------------------------------------------
// @am:string/effect_highlightShadow_name
// origem : assets/effects/toji-highlight-shadow.xml
// id     : com.alightcreative.effects.highlightshadow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_highlight_shadowParams {
    float highlights;
    float shadows;
};

// --- funcoes auxiliares do efeito
//const float3 luminanceWeighting = float3(0.3, 0.3, 0.3);
        const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_toji_highlight_shadow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_highlight_shadowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 source = inputImg.sample(__nv_smp, in.acScreenNorm);
            float luminance = dot(source.rgb, luminanceWeighting);

            //(u.shadows+1.0) changed to just u.shadows:
            float clampedShadows = clamp(u.shadows,1.0,2.0);
            float shadow = clamp((pow(luminance, 1.0/clampedShadows) + (-0.76)*pow(luminance, 2.0/clampedShadows)) - luminance, 0.0, 1.0);
            float highlight = clamp((1.0 - (pow(1.0-luminance, 1.0/(2.0-u.highlights)) + (-0.8)*pow(1.0-luminance, 2.0/(2.0-u.highlights)))) - luminance, -1.0, 0.0);
            float3 result = float3(0.0, 0.0, 0.0) + ((luminance + shadow + highlight) - 0.0) * ((source.rgb - float3(0.0, 0.0, 0.0))/(luminance - 0.0));

            // blend toward white if u.highlights is more than 1
            float contrastedLuminance = ((luminance - 0.5) * 1.5) + 0.5;
            float whiteInterp = contrastedLuminance*contrastedLuminance*contrastedLuminance;
            float whiteTarget = clamp(u.highlights, 1.0, 2.0) - 1.0;
            result = mix(result, float3(1.0), whiteInterp*whiteTarget);

            // blend toward black if u.shadows is less than 1
            float invContrastedLuminance = 1.0 - contrastedLuminance;
            float blackInterp = invContrastedLuminance*invContrastedLuminance*invContrastedLuminance;
            float blackTarget = 1.0 - clamp(u.shadows, 0.0, 1.0);
            result = mix(result, float3(0.0), blackInterp*blackTarget);

            __nv_out = float4(result.rgb, source.a);


            //float luminance = dot(source.rgb, luminanceWeighting);
            //
            //float shadow = clamp((pow(luminance, 1.0/(u.shadows+1.0)) + (-0.76)*pow(luminance, 2.0/(u.shadows+1.0))) - luminance, 0.0, 1.0);
            //float highlight = clamp((1.0 - (pow(1.0-luminance, 1.0/(2.0-u.highlights)) + (-0.8)*pow(1.0-luminance, 2.0/(2.0-u.highlights)))) - luminance, -1.0, 0.0);
            //float3 result = float3(0.0, 0.0, 0.0) + ((luminance + shadow + highlight) - 0.0) * ((source.rgb - float3(0.0, 0.0, 0.0))/(luminance - 0.0));
            //
            //__nv_out = float4(result.rgb, source.a);
    return __nv_out;
}
