// ---------------------------------------------------------------------------
// @am:string/effect_lensflare_name
// origem : assets/effects/toji-lensflare.xml
// id     : com.alightcreative.effects.lensflare
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_lensflareParams {
    float2 position;
    float radius;
    float brightness;
    float shine;
    float4 color;
    float pointCount;
    float alpha;
    int blendMode;
};

// --- funcoes auxiliares do efeito
static float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }

        float circle(float2 st, float2 center, float r) {
            return smoothstep(r,r-.001,length(st-center));
        }

        float smoothCircle(float2 st, float2 center, float r, float innerRad) {
            return smoothstep(r,innerRad,length(st-center));
        }

        float bokeh(float2 st, float2 center, float r, float feather) {
            return smoothstep(r,r*(1.-feather),length(st-center)) - smoothstep(r*(1.-feather),r*(1.-feather*2.),length(st-center)) + smoothstep(r,r*(1.-feather*2.),length(st-center))*1.608;
        }

        float ring(float2 st, float2 center, float r, float feather) {
            float dist = length(st-center);
            return smoothstep(r,r*(1.-feather),length(st-center)) - smoothstep(r*(1.-feather),r*(1.-feather*2.),dist) + smoothstep(0.,r,dist)*0.880*smoothstep(r+feather/2.,r,dist);
        }


        float star(float2 st, float2 center, float r, float insideRadiusScale, float points) {
            float2 dc = st-center;
            float ir = r*insideRadiusScale;
            float a = (__nv_atan(dc.x, dc.y)+3.14159)/2.;
            float p = smoothstep(r,ir,length(dc));

            a = smoothstep(p,ir,abs(sin(a*points)));
            return clamp((p*1.264+a)*p*p,0.,1.);
        }

        float combine(float p, float q) {
            return p+q;
        }

        float lensFlare(float2 st, float2 center, float2 offset, float r, float u.shine, float points) {
            float2 pos = offset;
            float2 offs = pos-center;
            float2 opp = center-offs;
            float dist = length(pos-center);
            float exposure = (1.-dist)+.5 * u.shine;
            exposure = 0.2 + (exposure*0.8);

            float p = 0.;

            p = combine(p,bokeh(st,mix(pos,opp,1.102),0.121*r,0.258)*0.116);

            p = combine(p,bokeh(st,opp,0.092*r,0.268)*0.116);

            p = combine(p,bokeh(st,mix(pos,opp,0.892),0.132*r,0.268)*0.116);

            p = combine(p,bokeh(st,mix(pos,opp,0.740),0.076*r,0.148)*0.116);

            p = combine(p,star(st,mix(pos,opp,0.820),0.164*r,-0.620+exposure*0.1,points)*1.000*exposure);
            p = combine(p,star(st,mix(pos,opp,0.820),0.164*r,-0.620+exposure*0.1,points*2.)*0.440*exposure);

            p = combine(p,bokeh(st,mix(pos,opp,0.428),0.044*r,0.148)*0.116);
            p = combine(p,bokeh(st,mix(pos,opp,0.484),0.028*r,0.268)*0.116);
            p = combine(p,bokeh(st,mix(pos,opp,0.564),0.020*r,0.268)*0.116);

            p = combine(p,bokeh(st,mix(pos,opp,0.276),0.020*r,0.268)*0.116);
            p = combine(p,bokeh(st,mix(pos,opp,0.204),0.076*r,0.228)*0.116);

            p = combine(p,star(st,pos,0.468*r,-0.236+exposure*0.1,points)*5.032*exposure);
            p = combine(p,ring(st,pos+float2(0.000,0.000),0.534*exposure*r,0.052)*0.296);
            p = combine(p,smoothCircle(st,pos,0.12*r,0.05*r)*max(0.2,0.1+exposure));

            return p;
        }

fragment float4 fx_toji_lensflare(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_lensflareParams&  u    [[buffer(1)]],
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

            float p = lensFlare(st,float2(0.,0.),u.position/1000.0,u.radius,u.shine*0.995,u.pointCount);

            float4 adjColor = clamp(float4(mix(u.color.rgb+float3(0.15,0.15,0.15),float3(1.),0.05)*p*u.brightness,1.),0.,1.)*p;

            float4 result;
            if( u.blendMode==1 ) {
                result = float4((texColor.rgb/texColor.a)*adjColor.rgb,1.0) * texColor.a;
            } else if( u.blendMode==2 ) {
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-adjColor.rgb)),1.0) * texColor.a;
            } else {
                result = adjColor*texColor.a;
                result = texColor*(1.-result.a) + result;
            }
            __nv_out = mix(texColor,clamp(result,0.,1.),u.alpha);
    return __nv_out;
}
