// ---------------------------------------------------------------------------
// Blit Watermark (NV)
// origem : assets/effects/nv-nodevideo-blit-watermark.xml
// id     : nv.effect.nodevideo-blit-watermark
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_blit_watermarkParams {
    float2 _rt_size;
};

// --- funcoes auxiliares do efeito
float2 u_xlat0;
float4 u_xlat1;
float2 u_xlat4;

fragment float4 fx_nv_nodevideo_blit_watermark(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_blit_watermarkParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = dot(u._rt_size.xy, u._rt_size.xy);
    u_xlat0.x = rsqrt(u_xlat0.x);
    u_xlat0.xy = u_xlat0.xx * u._rt_size.xy;
    u_xlat4.xy = in.acScreenNorm.xy * float2(1.07135487, 2.78672647);
    u_xlat0.xy = u_xlat0.xy * u_xlat4.xy;
    u_xlat1 = u._rt_size.xyxy * float4(0.239999995, 0.239999995, 0.0335999988, 0.0527999997);
    u_xlat0.xy = u_xlat0.xy * u._rt_size.xy + u_xlat1.zw;
    u_xlat0.xy = u_xlat0.xy / u_xlat1.xy;
    u_xlat0.xy = clamp(u_xlat0.xy, 0.0, 1.0);
    __nv_out = inputImg.sample(__nv_smp, u_xlat0.xy);
    return __nv_out;
    return __nv_out;
}
