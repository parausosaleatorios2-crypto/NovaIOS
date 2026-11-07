// ---------------------------------------------------------------------------
// Meio-Tom+
// origem : assets/effects/nv-um-halftone-plus.xml
// id     : nova.effect.um-halftone-plus
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_um_halftone_plusParams {
    float cellSize;
    float angleDeg;
    float contrast;
    float4 dotColor;
    float4 bgColor;
};

fragment float4 fx_nv_um_halftone_plus(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_um_halftone_plusParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float2 px = uv * eng.acResolution;
    float a = radians(u.angleDeg);
    float2x2 R = float2x2(cos(a), -sin(a), sin(a), cos(a));
    float2 cell = R * px / u.cellSize;
    float2 cellId = floor(cell);
    float2 center = (cellId + 0.5) * u.cellSize;
    float2 centerUV = (transpose(R) * center) / eng.acResolution;

    float4 sampled = inputImg.sample(__nv_smp, centerUV);
    float L = dot(sampled.rgb, float3(0.2126, 0.7152, 0.0722));
    float t = clamp((1.0 - L) * u.contrast, 0.0, 1.0);
    float radius = sqrt(t) * (u.cellSize * 0.5);

    float2 local = R * px - center;
    float d = length(local);
    float aa = fwidth(d) * 0.5 + 0.5;
    float dotMask = 1.0 - smoothstep(radius - aa, radius + aa, d);

    float3 col = mix(u.bgColor.rgb, u.dotColor.rgb, dotMask);
    __nv_out = float4(col, sampled.a);
    return __nv_out;
}
