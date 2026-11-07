// ---------------------------------------------------------------------------
// Anáglifo 3D
// origem : assets/effects/nv-um-anaglyph-3d.xml
// id     : nova.effect.um-anaglyph-3d
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_um_anaglyph_3dParams {
    float shift;
    float angleDeg;
    int desat;
};

fragment float4 fx_nv_um_anaglyph_3d(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_um_anaglyph_3dParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float a = radians(u.angleDeg);
    float2 dir = float2(cos(a), sin(a)) / eng.acResolution;
    float2 off = dir * u.shift;

    float4 left = inputImg.sample(__nv_smp, uv - off);
    float4 right = inputImg.sample(__nv_smp, uv + off);

    float3 lRgb = left.rgb;
    float3 rRgb = right.rgb;
    if (u.desat) {
        lRgb = float3(dot(lRgb, float3(0.2126, 0.7152, 0.0722)));
        rRgb = float3(dot(rRgb, float3(0.2126, 0.7152, 0.0722)));
    }

    // olho esquerdo = vermelho, olho direito = ciano (verde + azul)
    float3 col = float3(lRgb.r, rRgb.g, rRgb.b);
    float alpha = max(left.a, right.a);
    __nv_out = float4(col, alpha);
    return __nv_out;
}
