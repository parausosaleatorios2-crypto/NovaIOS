// ---------------------------------------------------------------------------
// Meio-Tom Plus (Ultra Motion)
// origem : assets/effects/um-halftone-plus.xml
// id     : nova.effect.ultramotion.halftoneplus
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_halftone_plusParams {
    float size;
    float angle;
    float softness;
    float4 dotColor;
    float4 bgColor;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_um_halftone_plus(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_halftone_plusParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 px = in.acScreenNorm * eng.acResolution;
    float a = radians(u.angle);
    float c = cos(a), s = sin(a);
    float2 rot = float2(px.x * c - px.y * s, px.x * s + px.y * c);
    float2 cell = floor(rot / u.size) * u.size + u.size * 0.5;
    float2 centro = float2(cell.x * c + cell.y * s, -cell.x * s + cell.y * c);
    float2 uv = centro / eng.acResolution;

    float3 amostra = inputImg.sample(__nv_smp, clamp(uv, 0.0, 1.0)).rgb;
    float l = dot(amostra, LUMA);
    float raio = sqrt(1.0 - l) * u.size * 0.5;
    float d = distance(rot, cell);
    float pt = 1.0 - smoothstep(raio - u.softness * u.size, raio + u.softness * u.size, d);
    float3 cor = mix(u.bgColor.rgb, u.dotColor.rgb, pt);
    float alphaOrig = inputImg.sample(__nv_smp, in.acScreenNorm).a;
    __nv_out = float4(cor, alphaOrig);
    return __nv_out;
}
