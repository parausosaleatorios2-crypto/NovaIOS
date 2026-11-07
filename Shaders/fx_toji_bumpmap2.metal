// ---------------------------------------------------------------------------
// @am:string/effect_bumpmap_name
// origem : assets/effects/toji-bumpmap2.xml
// id     : com.alightcreative.effects.bumpmap2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_bumpmap2Params {
    int imgNo;
    int texNo;
    float4 texColor;
    int mirror;
    float texScale;
    float2 texStretch;
    float texAngle;
    float texCrop;
    float2 texOffset;
    int shadingType;
    float lightIntensity;
    float shine;
    float spec;
    float ambient;
    float4 lightColor;
    float4 shineColor;
    float2 lightDir;
    float lightDepth;
    float height;
    float smoothing;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

        float lighting(float3 p, float3 n) {
            float3 lightPos = float3(u.lightDir.x/2.0, -u.lightDir.y/2.0, u.lightDepth*2.0) / 1000.0;
            float3 l = normalize(lightPos-p);
            return dot(n,l);
        }

        float directionalLighting(float3 p, float3 n) {
            float3 lightPos = float3(u.lightDir.x/2.0, -u.lightDir.y/2.0, u.lightDepth*2.0) / 1000.0;
            float3 l = normalize(lightPos);
            return dot(n,l);
        }

        float4 applyShading(float4 u.texColor, float3 p, float3 n, float d ) {
            float4 result = float4(0.);
            float a = smoothstep(30.0,9.,d);
            a *= smoothstep(0.3,0.2,n.z);
            if( u.shadingType == 0 ) {                // Flat
                result = u.texColor * a;
            } else if( u.shadingType == 1 ) {         // Point Light
                float l = lighting(p,n);
                float3 tc = u.texColor.rgb;
                float3 surface = tc * u.ambient + tc * u.lightColor.rgb * l * (1.-u.ambient);
                surface *= lightIntensity;
                float s = abs(pow(l,u.spec));
                surface = mix(surface*(1.-u.shine*0.1),u.shineColor.rgb,u.shine*s);
                result = float4(surface, u.texColor.a);// * a;
            } else if( u.shadingType == 2 ) {         // Directonal Light
                float l = directionalLighting(p,n);
                float3 tc = u.texColor.rgb;
                float3 surface = tc * u.ambient + tc * u.lightColor.rgb * l * (1.-u.ambient);
                surface *= lightIntensity;
                float s = abs(pow(l,u.spec));
                surface = mix(surface*(1.-u.shine*0.1),u.shineColor.rgb,u.shine*s);
                result = float4(surface, u.texColor.a);// * a;
            } else if( u.shadingType == 3 ) {         // Depth Map
                result = float4( (n/2.)+0.5, 1. ) * a;
            } else if( u.shadingType == 4 ) {         // Normal Map
                result = float4( (n/2.)+0.5, 1. ) * a;
            } else if( u.shadingType == 5 ) {         // Normal * Depth
                result = float4( (n/2.)+0.5, 1. ) * a;
            }

            return result;
        }

        float2 mapTexture( float2 texCoord, float rate ) {
            float texRad = u.texAngle * 0.0174533;
            float texCos = cos(texRad);
            float texSin = sin(texRad);
            float2x2 texRot = float2x2( texCos, -texSin, texSin, texCos );

            float texTwirl = 0.0;
            //float u.texCrop = 1.0;

            float texTwirlRad = texTwirl * 0.0174533;
            float texTwirlCos = cos(texTwirlRad);
            float texTwirlSin = sin(texTwirlRad);
            float2x2 texTwirlRot = float2x2( texTwirlCos, -texTwirlSin, texTwirlSin, texTwirlCos );

            float2 texScaleVec = float2(u.texScale,u.texScale);
            texScaleVec *= float2(u.texStretch.x,u.texStretch.y);

            texCoord -= u.texOffset * float2(1.0,-1.0) / 1000.0;
            texCoord -= 0.5;
            texCoord.x *= rate;
            texCoord *= texRot;
            texCoord.x /= rate;
            texCoord /= texScaleVec;
            texCoord += 0.5;
            //if( u.mirror ) {
            //    texCoord = 1.0 - texCoord;
            //}

            texCoord -= 0.5;
            texCoord = texCoord * (1.-5./eng.acScreenSize);
            //texCoord *= u.texCrop;
            texCoord *= texTwirlRot;
            texCoord += 0.5;
            return texCoord;
        }

fragment float4 fx_toji_bumpmap2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_bumpmap2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    texture2d<float> bumpmap_a [[texture(2)]],
    texture2d<float> bumpmap_b [[texture(3)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]],
    constant NovaTexInfo& bumpmap_a_info [[buffer(4)]],
    constant NovaTexInfo& bumpmap_b_info [[buffer(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st = in.acScreenNorm;
            float2 fragSize;
            float curHeight = 0.0;
            float left = 0.0;
            float right = 0.0;
            float top = 0.0;
            float bottom = 0.0;
            float2 gradient = float2(0,0);

            if(u.imgNo == 0) {
                //st calc----------------------------------------------------
                st = (float4(st.xy, 0, 1)*eng.acScreenToLayer).xy;
                st = mapTexture(st, eng.acScreenSize.x / eng.acScreenSize.y);
                if( u.mirror ) {
                    st = abs(__nv_mod(st, 2.0)-1.0);
                } else {
                    st = __nv_mod(st, 1.);
                }
                st = __nv_mod(st, 1.);
                st = (float4(st.xy, 0,1)*eng.acLayerToScreen).xy;
                st -= eng.acLayerCenterNorm;
                st *= u.texCrop;
                st += eng.acLayerCenterNorm;
                //----------------------------------------------------st calc
                fragSize = float2(1.)/__nv_getTexSize(inputImg_info.size) * u.smoothing;
                curHeight = length(inputImg.sample(__nv_smp, st).xyz*luminanceWeighting);
                left = length(inputImg.sample(__nv_smp, float2(st.x - fragSize.x, st.y)).xyz*luminanceWeighting);
                right = length(inputImg.sample(__nv_smp, float2(st.x + fragSize.x, st.y)).xyz*luminanceWeighting);
                top = length(inputImg.sample(__nv_smp, float2(st.x, st.y + fragSize.y)).xyz*luminanceWeighting);
                bottom = length(inputImg.sample(__nv_smp, float2(st.x, st.y - fragSize.y)).xyz*luminanceWeighting);
            } else if(u.imgNo == 1) {
                //st calc----------------------------------------------------
                st = (float4(st.xy, 0, 1)*eng.acScreenToLayer).xy;
                st = mapTexture(st, eng.acScreenSize.x / eng.acScreenSize.y);
                if( u.mirror ) {
                    st = abs(__nv_mod(st, 2.0)-1.0);
                } else {
                    st = __nv_mod(st, 1.);
                }
                st = __nv_mod(st, 1.);
                st = (float4(st.xy, 0,1)*eng.acLayerToScreen).xy;
                st -= eng.acLayerCenterNorm;
                st *= u.texCrop;
                st += eng.acLayerCenterNorm;
                //----------------------------------------------------st calc
                fragSize = float2(1.)/comp_info.size * u.smoothing;
                curHeight = length(comp.sample(__nv_smp, st).xyz*luminanceWeighting);
                left = length(comp.sample(__nv_smp, float2(st.x - fragSize.x, st.y)).xyz*luminanceWeighting);
                right = length(comp.sample(__nv_smp, float2(st.x + fragSize.x, st.y)).xyz*luminanceWeighting);
                top = length(comp.sample(__nv_smp, float2(st.x, st.y + fragSize.y)).xyz*luminanceWeighting);
                bottom = length(comp.sample(__nv_smp, float2(st.x, st.y - fragSize.y)).xyz*luminanceWeighting);
            } else if(u.imgNo == 2) {//canvas - bumpmap_b.g
                st = (float4(st.xy, 0, 1)*eng.acScreenToLayer).xy;
                st.x *= (eng.acLayerSize.x / bumpmap_b_info.size.x);
                st.y *= (eng.acLayerSize.y / bumpmap_b_info.size.y);
                st = mapTexture(st, 1.0);
                if( u.mirror ) {
                    st = abs(__nv_mod(st, 2.0)-1.0);
                } else {
                    st = __nv_mod(st, 1.);
                }
                fragSize = float2(1.)/bumpmap_b_info.size * u.smoothing;
                curHeight = bumpmap_b.sample(__nv_smp, st).g;
                left = bumpmap_b.sample(__nv_smp, float2(st.x - fragSize.x, st.y)).g;
                right = bumpmap_b.sample(__nv_smp, float2(st.x + fragSize.x, st.y)).g;
                top = bumpmap_b.sample(__nv_smp, float2(st.x, st.y + fragSize.y)).g;
                bottom = bumpmap_b.sample(__nv_smp, float2(st.x, st.y - fragSize.y)).g;
            } else if(u.imgNo == 3) {//bumpmap_b - bumpmap_b.r
                st = (float4(st.xy, 0, 1)*eng.acScreenToLayer).xy;
                st.x *= (eng.acLayerSize.x / bumpmap_b_info.size.x);
                st.y *= (eng.acLayerSize.y / bumpmap_b_info.size.y);
                st = mapTexture(st, 1.0);
                if( u.mirror ) {
                    st = abs(__nv_mod(st, 2.0)-1.0);
                } else {
                    st = __nv_mod(st, 1.);
                }
                fragSize = float2(1.)/bumpmap_b_info.size * u.smoothing;
                curHeight = bumpmap_b.sample(__nv_smp, st).r;
                left = bumpmap_b.sample(__nv_smp, float2(st.x - fragSize.x, st.y)).r;
                right = bumpmap_b.sample(__nv_smp, float2(st.x + fragSize.x, st.y)).r;
                top = bumpmap_b.sample(__nv_smp, float2(st.x, st.y + fragSize.y)).r;
                bottom = bumpmap_b.sample(__nv_smp, float2(st.x, st.y - fragSize.y)).r;
            } else if(u.imgNo == 4) {//mud - bumpmap_a.b
                st = (float4(st.xy, 0, 1)*eng.acScreenToLayer).xy;
                st.x *= (eng.acLayerSize.x / bumpmap_a_info.size.x);
                st.y *= (eng.acLayerSize.y / bumpmap_a_info.size.y);
                st = mapTexture(st, 1.0);
                if( u.mirror ) {
                    st = abs(__nv_mod(st, 2.0)-1.0);
                } else {
                    st = __nv_mod(st, 1.);
                }
                fragSize = float2(1.)/bumpmap_a_info.size * u.smoothing;
                curHeight = bumpmap_a.sample(__nv_smp, st).b;
                left = bumpmap_a.sample(__nv_smp, float2(st.x - fragSize.x, st.y)).b;
                right = bumpmap_a.sample(__nv_smp, float2(st.x + fragSize.x, st.y)).b;
                top = bumpmap_a.sample(__nv_smp, float2(st.x, st.y + fragSize.y)).b;
                bottom = bumpmap_a.sample(__nv_smp, float2(st.x, st.y - fragSize.y)).b;
            } else if(u.imgNo == 5) { //parchment - bumpmap_a.g
                st = (float4(st.xy, 0, 1)*eng.acScreenToLayer).xy;
                st.x *= (eng.acLayerSize.x / bumpmap_a_info.size.x);
                st.y *= (eng.acLayerSize.y / bumpmap_a_info.size.y);
                st = mapTexture(st, 1.0);
                if( u.mirror ) {
                    st = abs(__nv_mod(st, 2.0)-1.0);
                } else {
                    st = __nv_mod(st, 1.);
                }
                fragSize = float2(1.)/bumpmap_a_info.size * u.smoothing;
                curHeight = bumpmap_a.sample(__nv_smp, st).g;
                left = bumpmap_a.sample(__nv_smp, float2(st.x - fragSize.x, st.y)).g;
                right = bumpmap_a.sample(__nv_smp, float2(st.x + fragSize.x, st.y)).g;
                top = bumpmap_a.sample(__nv_smp, float2(st.x, st.y + fragSize.y)).g;
                bottom = bumpmap_a.sample(__nv_smp, float2(st.x, st.y - fragSize.y)).g;
            } else if(u.imgNo == 6) {//wood - bumpmap_a.r
                st = (float4(st.xy, 0, 1)*eng.acScreenToLayer).xy;
                st.x *= (eng.acLayerSize.x / bumpmap_a_info.size.x);
                st.y *= (eng.acLayerSize.y / bumpmap_a_info.size.y);
                st = mapTexture(st, 1.0);
                if( u.mirror ) {
                    st = abs(__nv_mod(st, 2.0)-1.0);
                } else {
                    st = __nv_mod(st, 1.);
                }
                fragSize = float2(1.)/bumpmap_a_info.size * u.smoothing;
                curHeight = bumpmap_a.sample(__nv_smp, st).r;
                left = bumpmap_a.sample(__nv_smp, float2(st.x - fragSize.x, st.y)).r;
                right = bumpmap_a.sample(__nv_smp, float2(st.x + fragSize.x, st.y)).r;
                top = bumpmap_a.sample(__nv_smp, float2(st.x, st.y + fragSize.y)).r;
                bottom = bumpmap_a.sample(__nv_smp, float2(st.x, st.y - fragSize.y)).r;
            }
            else if(u.imgNo == 7) { // weave - bumpmap_b.b
                st = (float4(st.xy, 0, 1)*eng.acScreenToLayer).xy;
                st.x *= (eng.acLayerSize.x / bumpmap_b_info.size.x);
                st.y *= (eng.acLayerSize.y / bumpmap_b_info.size.y);
                st = mapTexture(st, 1.0);
                if( u.mirror ) {
                    st = abs(__nv_mod(st, 2.0)-1.0);
                } else {
                    st = __nv_mod(st, 1.);
                }
                fragSize = float2(1.)/bumpmap_b_info.size * u.smoothing;
                curHeight = bumpmap_b.sample(__nv_smp, st).b;
                left = bumpmap_b.sample(__nv_smp, float2(st.x - fragSize.x, st.y)).b;
                right = bumpmap_b.sample(__nv_smp, float2(st.x + fragSize.x, st.y)).b;
                top = bumpmap_b.sample(__nv_smp, float2(st.x, st.y + fragSize.y)).b;
                bottom = bumpmap_b.sample(__nv_smp, float2(st.x, st.y - fragSize.y)).b;
            }
            gradient = normalize(float2((right - left) / (2.*fragSize.x), (top - bottom) / (2.*fragSize.y)));

            float adjHeight = u.height / 10.0;
            curHeight *= adjHeight;
            left *= adjHeight;
            right *= adjHeight;
            top *= adjHeight;
            bottom *= adjHeight;

            float3 va = normalize(float3(fragSize.x*2.0,0.0,right-left));
            float3 vb = normalize(float3(0.0,fragSize.y*2.0,top-bottom));
            float3 n = normalize(cross(va,vb));

            float4 baseColor;
            if(u.texNo == 0) {
                baseColor = comp.sample(__nv_smp, in.acScreenNorm);
            } else if(u.texNo == 1) {
                baseColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            } else {
                baseColor = u.texColor;
            }

            baseColor = applyShading(baseColor,float3(in.acScreenNorm.x - 0.5, in.acScreenNorm.y - 0.5, curHeight), n, 1.0);
            float alpha = inputImg.sample(__nv_smp, in.acScreenNorm).a;
            float4 result = baseColor*alpha;
            if(eng.acShowGuides)
            {
                float2 ld = in.acScreenNorm - (eng.acLayerCenterNorm+float2(u.lightDir.x/2.0, -u.lightDir.y/2.0)/1000.0);
                ld.x *= eng.acScreenSize.x / eng.acScreenSize.y;
                float4 u.lightColor= float4(0.,0.,0.,1.);
                float lightSize = 0.02;
                float lightIntensity = 0.5;
                result = mix(result,u.lightColor,lightIntensity * smoothstep(0., .05, max(0.,lightSize-length(ld))*(1.0/lightSize)));
                u.lightColor= float4(1.,1.,1.,1.);
                lightSize = 0.01;
                lightIntensity = 1.0;
                result = mix(result,u.lightColor,lightIntensity * smoothstep(0., .05, max(0.,lightSize-length(ld))*(1.0/lightSize)));
            }
            __nv_out = result;
    return __nv_out;
}
