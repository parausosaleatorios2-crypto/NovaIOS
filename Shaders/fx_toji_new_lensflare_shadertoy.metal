// ---------------------------------------------------------------------------
// New Lensflare
// origem : assets/effects/toji-new-lensflare-shadertoy.xml
// id     : com.alightcreative.effects.new_lensflare_shadertoy
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_new_lensflare_shadertoyParams {
    float3 position;
    float progressc;
    float progressd;
    float progresse;
    float progressa;
    float progressb;
    float alpha;
    float4 color1;
    float4 color3;
    float4 color4;
    int blendMode;
};

// --- funcoes auxiliares do efeito
// Shadertoy lens flare port adapted to AM. Uses same control IDs as skexnxxnewlensflare.

const float PI = 3.14159265359;
const float3 suncolor = float3(0.643,0.494,0.867);

static float getSun(float2 uv){ return (length(uv) < 0.009) ? 1.0 : 0.0; }

static float3 lensflares(float2 uv, float2 pos, out float3 sunflare, out float3 lensflare){
    float2 main = uv - pos;
    float2 uvd = uv * (length(uv));

    float ang = __nv_atan(main.y, main.x);
    float dist = length(main);
    dist = pow(dist, 0.1);

    float f0 = 1.0 / (length(uv - pos) * 25.0 + 1.0);
    f0 = pow(f0, 2.0);
    f0 = f0 + f0 * (sin((ang + 1.0/18.0) * 12.0) * 0.1 + dist * 0.1 + 0.8);

    float f2  = max(1.0/(1.0 + 32.0*pow(length(uvd + 0.8*pos),  2.0)), 0.0) * 0.25;
    float f22 = max(1.0/(1.0 + 32.0*pow(length(uvd + 0.85*pos), 2.0)), 0.0) * 0.23;
    float f23 = max(1.0/(1.0 + 32.0*pow(length(uvd + 0.9*pos),  2.0)), 0.0) * 0.21;

    float2 uvx = mix(uv, uvd, -0.5);
    float f4  = max(0.01 - pow(length(uvx + 0.4*pos),  2.4), 0.0) * 6.0;
    float f42 = max(0.01 - pow(length(uvx + 0.45*pos), 2.4), 0.0) * 5.0;
    float f43 = max(0.01 - pow(length(uvx + 0.5*pos),  2.4), 0.0) * 3.0;

    uvx = mix(uv, uvd, -0.4);
    float f5  = max(0.01 - pow(length(uvx + 0.2*pos),  5.5), 0.0) * 2.0;
    float f52 = max(0.01 - pow(length(uvx + 0.4*pos),  5.5), 0.0) * 2.0;
    float f53 = max(0.01 - pow(length(uvx + 0.6*pos),  5.5), 0.0) * 2.0;

    uvx = mix(uv, uvd, -0.5);
    float f6  = max(0.01 - pow(length(uvx - 0.3*pos), 1.6), 0.0) * 6.0;
    float f62 = max(0.01 - pow(length(uvx - 0.325*pos),1.6), 0.0) * 3.0;
    float f63 = max(0.01 - pow(length(uvx - 0.35*pos), 1.6), 0.0) * 5.0;

    sunflare = float3(f0);
    lensflare = float3(f2+f4+f5+f6, f22+f42+f52+f62, f23+f43+f53+f63);
    return sunflare + lensflare;
}

static float3 anflares1(float2 uv, float intensity, float stretch, float brightness){
    uv.x *= 1.0 / max(intensity*stretch, 1e-3);
    uv.y *= 0.5;
    return float3(smoothstep(0.009, 0.0, length(uv))) * brightness;
}

static float3 anflares2(float2 uv, float threshold, float intensity, float stretch, float brightness){
    threshold = 1.0 - threshold;
    float3 hdr = float3(getSun(uv));
    hdr = float3(floor(threshold + pow(hdr.r, 1.0)));
    float d = max(intensity, 1e-3);
    float c = max(intensity * stretch, 0.0);
    const int STEPS = 64;
    for (int k = 0; k <= STEPS; k++){
        float i = float(k) * (c / float(STEPS));
        float texL = getSun(uv + float2(i/d, 0.0));
        float texR = getSun(uv - float2(i/d, 0.0));
        float w = (c > 0.0) ? (1.0 - i / c) : 0.0;
        hdr += floor(threshold + pow(max(texL, texR), 4.0)) * max(w, 0.0);
    }
    return hdr * brightness;
}

static float3 applyBlend(float3 base, float3 over, float a, int mode){
    float3 outc = base;
    if (mode == 0){ // NORMAL
        outc = mix(base, over, a);
    } else if (mode == 1){ // MULTIPLY
        outc = mix(base, base * over, a);
    } else if (mode == 2){ // SCREEN
        float3 screen = 1.0 - (1.0 - base) * (1.0 - over);
        outc = mix(base, screen, a);
    }
    return outc;
}

fragment float4 fx_toji_new_lensflare_shadertoy(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_new_lensflare_shadertoyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 R = eng.acScreenSize;
    float2 uv = in.acScreenNorm - 0.5;
    uv.x *= R.x / max(R.y, 1.0);

    // Position mapping: interpret u.position.x/y as percentage (0..100) of screen
    float2 pos01 = clamp(float2(u.position.x, u.position.y) / 100.0, 0.0, 1.0);
    float2 mouse = pos01 - 0.5;
    mouse.x *= R.x / max(R.y, 1.0);

    // Orient controls slightly skew the mouse
    mouse += float2(u.progressc * 0.05, u.progressd * 0.05);

    float3 col = float3(0.0);

    float3 sun, sunflare, lensflare;
    float3 flare = lensflares(uv * 1.5, mouse * 1.5, sunflare, lensflare);

    // Two variants of anamorphic flare; choose richer one similar to non-cheap path
    float3 anflare = pow(anflares2(uv - mouse, 0.5, 400.0, 0.9, 0.1), float3(4.0));

    float3 tint1 = u.color1.rgb;
    float3 tintBase = u.color3.rgb;
    float3 tintSec = u.color4.rgb;

    float refl = u.progressa;      // reflection strength scaler
    float lumin = u.progressb;     // luminance scaler
    float Strength = u.progresse;  // global intensity

    float3 flareCol = (flare + anflare) * suncolor * 2.0;
    flareCol *= lumin;
    flareCol = mix(flareCol, flareCol * tint1, 0.6);
    flareCol += sunflare * tintBase * 0.5;
    flareCol += lensflare * tintSec * 0.25 * refl;

    float3 src = inputImg.sample(__nv_smp, in.acScreenNorm).rgb;

    // gamma-like tone on flare
    flareCol = pow(max(flareCol, 0.0), float3(1.0/2.2));

    float a = clamp(u.alpha * Strength, 0.0, 1.0);
    // Float-based selection to avoid int/float mismatch across platforms
    float bmode = float(u.blendMode);
    float wN = 1.0 - step(0.5, abs(bmode - 0.0)); // NORMAL
    float wM = 1.0 - step(0.5, abs(bmode - 1.0)); // MULTIPLY
    float wS = 1.0 - step(0.5, abs(bmode - 2.0)); // SCREEN

    float3 colNormal   = mix(src, flareCol, a);
    float3 colMultiply = mix(src, src * flareCol, a);
    float3 screenMix   = 1.0 - (1.0 - src) * (1.0 - flareCol);
    float3 colScreen   = mix(src, screenMix, a);

    float3 outc = colNormal * wN + colMultiply * wM + colScreen * wS;
    __nv_out = float4(outc, 1.0);
    return __nv_out;
}
