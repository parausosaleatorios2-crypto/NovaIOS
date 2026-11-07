// ---------------------------------------------------------------------------
// @am:string/effect_page_curl_name
// origem : assets/effects/toji-pagecurl.xml
// id     : com.alightcreative.effects.pagecurl
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_pagecurlParams {
    float progress;
    float radius;
    float angle;
    float alpha;
    float strength;
    float4 backColor;
    float backAlpha;
    int backBlendMode;
    float4 shineColor;
    float shineAlpha;
    float shineSpec;
    int shineBlendMode;
    float4 dropShadowColor;
    float dropShadowAlpha;
    int softDropShadow;
    float4 frontShadowColor;
    float frontShadowAlpha;
    int frontShadowBlendMode;
};

// --- funcoes auxiliares do efeito
static float2x2 rot2(float a) {
            float c = cos(a);
            float s = sin(a);
            return float2x2(c,s,-s,c);
        }

        float2 l2s( float2 v ) {
            return (float4(v,0.,1.)*eng.acLayerToScreen).xy;
        }
        
        float4 composite(float4 a, float4 b) {
            return a * (1.-b.a) + b;
        }


        // Created by Eduardo Castineyra - casty/2015
        // Creative Commons Attribution 4.0 International License
        // https://www.shadertoy.com/view/MtBSzR

        #define M_PI 3.141592
        #define CYL_DIST (cyl.z)

        /// 1D function x: cylFun(t); y: normal at that point.
        float2 curlFun(float t, float maxt, float3 cyl) {
            float2 ret = float2(t, 1.0);
            if (t < CYL_DIST - u.radius)
                return ret;                    /// Before the curl
            if (t > CYL_DIST + u.radius)
                return float2(-1.0);            /// After the curl
            
            /// Inside the curl
            float a = asin((t - CYL_DIST) / u.radius);
            float ca = -a + M_PI;
            ret.x = CYL_DIST + ca * u.radius;
            ret.y = cos(ca);
            
            if (ret.x < maxt)
                return ret;                    /// We see the back face

            if (t < CYL_DIST)
                return float2(t, 1.0);        /// Front face before the curve starts
            ret.y = cos(a);
            ret.x = CYL_DIST + a * u.radius;
            return ret.x < maxt ? ret : float2(-1.0);  /// Front face curve
        }

        float2 curlFunFront(float t, float maxt, float3 cyl) {
            float2 ret = float2(t, 1.0);
            if (t < CYL_DIST - u.radius)
                return ret;                    /// Before the curl
            if (t > CYL_DIST + u.radius)
                return float2(-1.0);            /// After the curl

            /// Inside the curl
            float a = asin((t - CYL_DIST) / u.radius);
            float ca = -a + M_PI;
            ret.x = CYL_DIST + ca * u.radius;
            ret.y = cos(ca);

            if (t < CYL_DIST)
                return float2(t, 1.0);        /// Front face before the curve starts
            ret.y = cos(a);
            ret.x = CYL_DIST + a * u.radius;
            return ret.x < maxt ? ret : float2(-1.0);  /// Front face curve
        }

        float4 blendColor( float4 base, float4 color, int mode, float p) {
            if( mode == 1 ) {           // Multiply
                float3 aa = base.rgb / max(base.a,0.00001);
                float3 bb = color.rgb / max(color.a,0.00001);
                float3 cc = aa * bb;
                float4 adjColor = float4(cc,1.) * color.a * p;
                return base * (1.-adjColor.a) + adjColor;
            } else if( mode == 2 ) {    // Screen
                float3 aa = base.rgb / max(base.a,0.00001);
                float3 bb = color.rgb / max(color.a,0.00001);
                float3 cc = 1.-((1.-aa) * (1.-bb));
                float4 adjColor = float4(cc,1.) * color.a * p;
                return base * (1.-adjColor.a) + adjColor;
            } else {                    // Normal
                float4 adjColor = color * p;
                return base * (1.-adjColor.a) + adjColor;
            }
        }

fragment float4 fx_toji_pagecurl(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_pagecurlParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> blurBuf [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& blurBuf_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
            float2 uv = in.acLayerNorm;
            float2 ur = float2(1.0);//, eng.acScreenSize.y/eng.acScreenSize.x);
            float h = sqrt(tan(M_PI/4.-abs(__nv_mod(u.angle*0.0174533, M_PI/2.)-M_PI/4.))+1.);
            float d = (1.-u.progress) * h;//((u.progress-0.5) * h)+0.5;
            d = 1.-((1.0-d) * (1.+u.radius));
            float2 cd = float2(1.0,0.0)*rot2(u.angle*0.0174533);
            float2 iv = step(cd,float2(0.));
            uv = iv + uv * (1.-iv*2.);
            
            float3 cyl = float3(abs(cd),d);

            d = dot(uv, cyl.xy);
            float2 end = abs((ur - uv) / cyl.xy);
            float maxt = d + min(end.x, end.y);
            float2 cff = curlFunFront(d, maxt, cyl);
            float2 cf = curlFun(d, maxt, cyl);
            float2 tuv = uv + cyl.xy * (cf.x - d);
            float2 tuvf = uv + cyl.xy * (cff.x - d);

            tuv /= ur;
            tuv = iv + tuv * (1.-iv*2.);
            tuvf /= ur;
            tuvf = iv + tuvf * (1.-iv*2.);

            float shadow = 1.0 - smoothstep(0.0, u.radius * 2.0, -(d - CYL_DIST));
            shadow *= (smoothstep(-u.radius, u.radius, (maxt - (cf.x + 1.5 * M_PI * u.radius + u.radius))));
            
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float4 blurColor = blurBuf.sample(__nv_smp, in.acScreenNorm);
            float4 frontColor = inputImg.sample(__nv_smp, l2s(tuvf));
            float4 result = inputImg.sample(__nv_smp, l2s(tuv));

            float4 front = blendColor(frontColor, u.frontShadowColor * u.frontShadowAlpha * frontColor.a, u.frontShadowBlendMode, saturate(1.0 - cff.y)  );
            result = cf.y > 0.0
                ? front
                : blendColor(
                    blendColor(
                        composite(front,mix(texColor * (1.-blurColor.a)+blurColor,result,u.alpha)),
                        u.backColor * u.backAlpha * result.a, u.backBlendMode, 1. * step(uv.x,1.) * step(uv.y,1.)
                    ),
                    u.shineColor * u.shineAlpha * result.a, u.shineBlendMode, pow(-cf.y,u.shineSpec) * step(uv.x,1.) * step(uv.y,1.)
                );
            
            shadow = smoothstep(0.0, u.radius * 2.0, (d - CYL_DIST));
            
            if(u.softDropShadow) {
                shadow = saturate((1.-shadow)*2.) * (1.-pow(length(in.acLayerNorm-0.5)*2.,2.) );
                float4 adjShadowColor = u.dropShadowColor * u.dropShadowAlpha * shadow * (smoothstep(0.5,1.0,blurColor.a)) * texColor.a;
                __nv_out = (cf.x > 0.0 ? composite(adjShadowColor,result) : adjShadowColor) * step(uv.x,1.) * step(uv.y,1.);
            } else {
                __nv_out = (cf.x > 0.0 ? result : u.dropShadowColor * u.dropShadowAlpha * saturate((1.-shadow)*2.) * texColor.a) * step(uv.x,1.) * step(uv.y,1.);
            }
    return __nv_out;
}
