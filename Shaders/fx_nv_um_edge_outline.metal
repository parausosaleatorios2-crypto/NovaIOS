// ---------------------------------------------------------------------------
// Contorno de Borda
// origem : assets/effects/nv-um-edge-outline.xml
// id     : nova.effect.um-edge-outline
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_um_edge_outlineParams {
    float threshold;
    float thickness;
    float4 edgeColor;
    float4 bgColor;
    float mistura;
};

// --- funcoes auxiliares do efeito
float luma(float3 c) { return dot(c, float3(0.2126, 0.7152, 0.0722)); }

fragment float4 fx_nv_um_edge_outline(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_um_edge_outlineParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float2 t = u.thickness / eng.acResolution;

    float tl = luma(inputImg.sample(__nv_smp, uv + float2(-t.x,  t.y)).rgb);
    float  l = luma(inputImg.sample(__nv_smp, uv + float2(-t.x,  0.0)).rgb);
    float bl = luma(inputImg.sample(__nv_smp, uv + float2(-t.x, -t.y)).rgb);
    float tt = luma(inputImg.sample(__nv_smp, uv + float2( 0.0,  t.y)).rgb);
    float bb = luma(inputImg.sample(__nv_smp, uv + float2( 0.0, -t.y)).rgb);
    float tr = luma(inputImg.sample(__nv_smp, uv + float2( t.x,  t.y)).rgb);
    float  r = luma(inputImg.sample(__nv_smp, uv + float2( t.x,  0.0)).rgb);
    float br = luma(inputImg.sample(__nv_smp, uv + float2( t.x, -t.y)).rgb);

    float gx = -tl - 2.0 * l - bl + tr + 2.0 * r + br;
    float gy = -tl - 2.0 * tt - tr + bl + 2.0 * bb + br;
    float g = sqrt(gx * gx + gy * gy);
    float m = smoothstep(u.threshold, u.threshold + 0.1, g);

    float4 base = inputImg.sample(__nv_smp, uv);
    float4 bg = mix(u.bgColor, base, u.mistura);
    float3 col = mix(bg.rgb, u.edgeColor.rgb, m);
    float a = mix(bg.a, u.edgeColor.a, m);
    __nv_out = float4(col, a);
    return __nv_out;
}
