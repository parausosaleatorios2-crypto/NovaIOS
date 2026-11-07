// ---------------------------------------------------------------------------
// Light streak
// origem : assets/effects/toji-brightpass-hblur-add.xml
// id     : com.alightcreative.effects.brightpass_hblur_add
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_brightpass_hblur_addParams {
    float THRESH;
    float RADIUS;
    float SIZEX;
    float BLUR_GAIN;
    float BASE_GAIN;
    float GAMMA;
};

// --- funcoes auxiliares do efeito
// Bright-pass + Horizontal Blur (SCurve weights) + Add

float SCurve(float x){
    x = x * 2.0 - 1.0;
    return -x * abs(x) * 0.5 + x + 0.5;
}

float4 BlurH(sampler2D source, float2 uv, float radius, float sizeX){
    if (radius < 1.0) return source.sample(__nv_smp, uv);
    float width = 1.0 / max(sizeX, 1.0);
    float3 C = float3(0.0);
    float divisor = 0.0;
    const int MAX_R = 128;
    float rad = clamp(radius, 0.0, float(MAX_R));
    for (int i = -MAX_R; i <= MAX_R; i++){
        float x = float(i);
        if (abs(x) > rad) continue;
        float w = SCurve(1.0 - (abs(x) / max(rad, 1e-3)));
        float2 o = float2(x * width, 0.0);
        C += source.sample(__nv_smp, clamp(uv + o, 0.0, 1.0)).rgb * w;
        divisor += w;
    }
    return float4(C / max(divisor, 1e-6), 1.0);
}

fragment float4 fx_toji_brightpass_hblur_add(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_brightpass_hblur_addParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float3 src = inputImg.sample(__nv_smp, uv).rgb;

    float thresh = u.THRESH;
    float b = dot(src, float3(0.2126, 0.7152, 0.0722));
    float3 bright = (b > thresh) ? src : float3(0.0);

    // Blur only the bright-pass by sampling from a virtual texture: mix via mask
    // Since we don't have MRT, approximate by blurring src then masking by bright pass ratios.
    float4 blurredSrc = BlurH(inputImg, uv, u.RADIUS, u.SIZEX);
    // Preserve color where bright, otherwise zero
    float3 blurredBright = blurredSrc.rgb * step(thresh, b);

    float3 outc = src * u.BASE_GAIN + blurredBright * u.BLUR_GAIN;
    outc = pow(max(outc, 0.0), float3(u.GAMMA));

    __nv_out = float4(outc, 1.0);
    return __nv_out;
}
