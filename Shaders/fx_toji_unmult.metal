// ---------------------------------------------------------------------------
// Unmult
// origem : assets/effects/toji-unmult.xml
// id     : com.alightcreative.effects.unmult
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_unmultParams {
    float blackLevel;
    float softness;
    float featherPx;
    float cleanupPx;
    float edgeGamma;
    int preserveLuma;
    int previewMatte;
    float quality;
};

// --- funcoes auxiliares do efeito
// Utility
        float3 toLinear(float3 c){ return pow(max(c, 0.0), float3(2.2)); }
        float3 toSRGB(float3 c){ return pow(max(c, 0.0), float3(1.0/2.2)); }

        // Sample helpers
        float4 sampleImg(AC_ImageInfo img, float2 uv){ return img.texture.sample(__nv_smp, uv); }

        float max3(float3 v){ return max(v.r, max(v.g, v.b)); }

        float getBaseAlpha(float3 srgb, float thr, float soft, float gamma){
            float m = max3(srgb);
            float a = smoothstep(thr, thr + soft, m);
            a = pow(clamp(a, 0.0, 1.0), gamma);
            return a;
        }

        float featherAlpha(AC_ImageInfo img, float2 uv, float baseA, float2 px, float feather){
            if (feather <= 0.0001) return baseA;
            float f = clamp(feather, 0.0, 10.0);
            float2 off = px * f;
            // 5-tap cross blur for performance
            float3 cC = sampleImg(img, uv).rgb;
            float3 cL = sampleImg(img, uv - float2(off.x, 0.0)).rgb;
            float3 cR = sampleImg(img, uv + float2(off.x, 0.0)).rgb;
            float3 cT = sampleImg(img, uv - float2(0.0, off.y)).rgb;
            float3 cB = sampleImg(img, uv + float2(0.0, off.y)).rgb;
            float aC = max3(cC);
            float aL = max3(cL);
            float aR = max3(cR);
            float aT = max3(cT);
            float aB = max3(cB);
            float avg = (aC*0.4 + (aL+aR+aT+aB)*0.15);
            return mix(baseA, avg, 0.75);
        }

        float cleanupAlpha(AC_ImageInfo img, float2 uv, float2 px, float pixels){
            float p = abs(pixels);
            if (p < 0.001) return max3(sampleImg(img, uv).rgb);
            float2 off = px * p;
            float aC = max3(sampleImg(img, uv).rgb);
            float aL = max3(sampleImg(img, uv - float2(off.x, 0.0)).rgb);
            float aR = max3(sampleImg(img, uv + float2(off.x, 0.0)).rgb);
            float aT = max3(sampleImg(img, uv - float2(0.0, off.y)).rgb);
            float aB = max3(sampleImg(img, uv + float2(0.0, off.y)).rgb);
            float spread = max(aC, max(max(aL,aR), max(aT,aB))); // dilate
            float choke  = min(aC, min(min(aL,aR), min(aT,aB))); // erode
            return (pixels >= 0.0) ? spread : choke;
        }

fragment float4 fx_toji_unmult(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_unmultParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 image_size = __nv_getTexSize(inputImg_info.size);
            float2 px = float2(1.0) / max(float2(image_size.x, image_size.y), 1.0);
            float2 uv = in.acScreenNorm.st;
            float4 col = sampleImg(inputImg, uv);

            float thr = clamp(u.blackLevel / 255.0, 0.0, 1.0);
            float soft = max(u.softness, 0.0) * 0.25; // map u.softness to a reasonable ramp width
            float gamma = u.edgeGamma;

            // Base alpha from max RGB with threshold + u.softness
            float aBase = getBaseAlpha(col.rgb, thr, soft, gamma);

            // Feathering
            float aFeather = featherAlpha(inputImg, uv, aBase, px, u.featherPx);

            // Matte cleanup (choke/spread). Blend with feathered alpha based on magnitude.
            float aClean = cleanupAlpha(inputImg, uv, px, u.cleanupPx);
            float mAmt = clamp(abs(u.cleanupPx)/10.0, 0.0, 1.0);
            float aMatte = mix(aFeather, aClean, mAmt);

            // Respect original alpha channel; output straight alpha
            float aOut = aMatte * col.a;

            // Unmult color to preserve luminance under reduced alpha (classic Unmult behavior)
            float3 unmultRGB = u.preserveLuma ? (col.rgb / max(aMatte, 1e-4)) : col.rgb;
            unmultRGB = clamp(unmultRGB, 0.0, 1.0);

            if (u.previewMatte) {
                __nv_out = float4(float3(aOut), aOut);
            } else {
                __nv_out = float4(unmultRGB, aOut);
            }
    return __nv_out;
}
