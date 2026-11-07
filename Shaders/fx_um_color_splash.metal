// ---------------------------------------------------------------------------
// Respingo de Cor (Ultra Motion)
// origem : assets/effects/um-color-splash.xml
// id     : nova.effect.ultramotion.colorsplash
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_color_splashParams {
    float hue;
    float tolerance;
    float softness;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

static float3 rgb2hsv(float3 c) {
    float4 K = float4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

fragment float4 fx_um_color_splash(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_color_splashParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
    float3 hsv = rgb2hsv(c.rgb);
    float h = hsv.x * 360.0;
    float alvo = __nv_mod(u.hue, 360.0);
    float diff = abs(h - alvo);
    diff = min(diff, 360.0 - diff);
    float k = 1.0 - smoothstep(u.tolerance, u.tolerance + u.softness, diff);
    // Peso também pela saturação — cinza puro não "é cor".
    k *= smoothstep(0.1, 0.3, hsv.y);
    float cinza = dot(c.rgb, LUMA);
    __nv_out = float4(mix(float3(cinza), c.rgb, k), c.a);
    return __nv_out;
}
