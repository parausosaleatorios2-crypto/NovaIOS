// ---------------------------------------------------------------------------
// Tint (Luma Colorize)
// origem : assets/effects/toji-tint_luma_colorize.xml
// id     : com.alightcreative.effects.tint_luma_colorize
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_tint_luma_colorizeParams {
    float4 tintColor;
    float hue;
    float brightness;
};

// --- funcoes auxiliares do efeito
static float3 rgb2hsv(float3 c) {
            float4 K = float4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
            float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
            float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
            float d = q.x - min(q.w, q.y);
            float e = 1.0e-10;
            return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }

        float3 hsv2rgb(float3 c) {
            float4 K = float4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
            float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

fragment float4 fx_toji_tint_luma_colorize(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_tint_luma_colorizeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float3 color = texColor.rgb;

            // Shadertoy-style grayscale u.brightness, scaled by parameter
            float lum = dot(color, float3(0.369, 1.000, 0.000)) * u.brightness;
            lum = clamp(lum, 0.0, 1.0);

            // Base tint from color picker, apply u.hue shift in degrees
            float3 tint = u.tintColor.rgb;
            float3 tintHSV = rgb2hsv(tint);
            tintHSV.x = fract(tintHSV.x + (u.hue / 360.0));
            tint = hsv2rgb(tintHSV);

            float3 tinted = lum * tint;
            __nv_out = float4(tinted, texColor.a);
    return __nv_out;
}
