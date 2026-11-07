// ---------------------------------------------------------------------------
// @am:string/effect_radialrays_name
// origem : assets/effects/toji-radial_rays.xml
// id     : com.alightcreative.effects.radialrays
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_radial_raysParams {
    float2 position;
    float pointCount;
    float rayWidth;
    float angle;
    float4 color;
    float alpha;
    int blendMode;
    float innerRadius;
    float outerRadius;
    float feather;
    float radialFeather;
    float bendStrength;
    float bendFrequency;
    float bendPhase;
};

// --- funcoes auxiliares do efeito
#define PI 3.1415926536

        float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }

        float rays(float2 st, float pixelSize, float u.feather, float width, float count, float u.innerRadius, float u.outerRadius, float u.radialFeather, float u.bendStrength, float u.bendFrequency, float u.bendPhase, float u.angle) {
            float r = length(st);
            float theta = (__nv_atan(st.x, st.y)+u.angle)/(2.0*PI);
            theta += sin(r*u.bendFrequency+u.bendPhase)*u.bendStrength;
            float sweep = 1./count;
            float t = __nv_mod(theta, sweep)/sweep;
            float h = u.feather/2. * pixelSize/r;
            float halfWidth = width/2.;
            float low = smoothstep(0.5-halfWidth-h,0.5-halfWidth+h,t);
            float high = smoothstep(0.5+halfWidth+h,0.5+halfWidth-h,t);
            float rf = u.radialFeather/2. * pixelSize;
            //float rt0 = abs(t-0.5)/halfWidth;
            //float rt1 = 1.-clamp((u.outerRadius-r)/halfWidth,0.,1.);
            //float rt = rt0*rt1;
            float orad = u.outerRadius; //-((cos(rt))*rounding);
            float ir = u.innerRadius;
            float inside = smoothstep(ir-rf, ir+rf, r);
            float outside = smoothstep(orad+rf, orad-rf, r);

            //float insideRound = smoothstep(ir-rounding, ir+rounding, r);
            //float outsideRound = smoothstep(or+rounding, or-rounding, r);
            //float lowRound = smoothstep(0.5-halfWidth-rounding,0.5-halfWidth+rounding,t);
            //float highRound = smoothstep(0.5+halfWidth+rounding,0.5+halfWidth-rounding,t);
            //
            //float roundLimit = smoothstep(0.5,0.501,insideRound * outsideRound * lowRound * highRound);

            return low*high*inside*outside;
        }

fragment float4 fx_toji_radial_rays(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_radial_raysParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st = in.acLayerNorm;
            st.y = 1. - st.y;
            st -= 0.5;
            st.x *= eng.acLayerSize.x/eng.acLayerSize.y;
            float pixelSize = 1./length(__nv_getTexSize(inputImg_info.size));

            float p = rays(st-u.position/1000.0, pixelSize, u.feather, u.rayWidth, u.pointCount, u.innerRadius, u.outerRadius, u.radialFeather, u.bendStrength/10., u.bendFrequency, u.bendPhase, u.angle/57.2958);

            float4 adjColor = u.color * p;

            float4 result;
            if( u.blendMode==1 ) {
                result = float4((texColor.rgb/texColor.a)*adjColor.rgb,1.0) * texColor.a;
            } else if( u.blendMode==2 ) {
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-adjColor.rgb)),1.0) * texColor.a;
            } else {
                result = adjColor*texColor.a;
                result = texColor*(1.-result.a) + result;
            }
            __nv_out = mix(texColor,result,u.alpha);
    return __nv_out;
}
