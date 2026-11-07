// ---------------------------------------------------------------------------
// Prism (NV)
// origem : assets/effects/nv-nodevideo-assetstore-prism.xml
// id     : nv.effect.nodevideo-assetstore-prism
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_prismParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _samples;
    float _blur;
    float _falloff;
    float2 _center;
    float3 _rgb_shift;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float4 u_xlat6;
float2 u_xlat14;
int u_xlati15;
float2 u_xlat19;
float u_xlat21;
float u_xlat22;
bool u_xlatb22;

fragment float4 fx_nv_nodevideo_assetstore_prism(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_prismParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + (-u._center.xy);
    u_xlat14.x = dot(u_xlat0.xy, u_xlat0.xy);
    u_xlat14.x = rsqrt(u_xlat14.x);
    u_xlat0.xy = u_xlat14.xx * u_xlat0.xy;
    u_xlat0.xy = u_xlat0.xy * float2(float2(u._blur, u._blur));
    u_xlat14.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat14.x = dot(u_xlat14.xy, u_xlat14.xy);
    u_xlat14.x = sqrt(u_xlat14.x);
    u_xlat14.x = log2(u_xlat14.x);
    u_xlat14.x = u_xlat14.x * u._falloff;
    u_xlat14.x = exp2(u_xlat14.x);
    u_xlat0.xy = u_xlat14.xx * u_xlat0.xy;
    u_xlat14.x = float(int(u._samples));
    u_xlat21 = float(1.0) / u_xlat14.x;
    u_xlat1 = u_xlat0.xyxy * u._rgb_shift.xxyy;
    u_xlat2.xy = float2(u_xlat21) * u_xlat1.zw;
    u_xlat0.xy = u_xlat0.xy * u._rgb_shift.zz;
    u_xlat2.zw = float2(u_xlat21) * u_xlat0.xy;
    u_xlat3.x = float(0.0);
    u_xlat3.y = float(0.0);
    u_xlat3.z = float(0.0);
    u_xlat3.w = float(0.0);
    u_xlat0.x = float(0.0);
    u_xlat0.y = float(0.0);
    u_xlat4.x = float(0.0);
    u_xlat4.y = float(0.0);
    u_xlat4.z = float(0.0);
    u_xlat4.w = float(0.0);
    for(int u_xlati_loop_1 = 0 ; u_xlati_loop_1<int(u._samples) ; u_xlati_loop_1++)
    {
        u_xlat5.xy = u_xlat0.xy + in.acScreenNorm.xy;
        u_xlat5.xy = inputImg.sample(__nv_smp, u_xlat5.xy).xw;
        u_xlat19.xy = u_xlat4.xy + in.acScreenNorm.xy;
        u_xlat5.zw = inputImg.sample(__nv_smp, u_xlat19.xy).yw;
        u_xlat6.xy = u_xlat4.zw + in.acScreenNorm.xy;
        u_xlat6.zw = inputImg.sample(__nv_smp, u_xlat6.xy).zw;
        u_xlat22 = u_xlat5.w + u_xlat5.y;
        u_xlat22 = u_xlat6.w + u_xlat22;
        u_xlat6.w = u_xlat22 * 0.333333343;
        u_xlat6.xy = u_xlat5.xz;
        u_xlat3 = u_xlat3 + u_xlat6;
        u_xlat0.xy = (-u_xlat1.xy) * float2(u_xlat21) + u_xlat0.xy;
        u_xlat4 = (-u_xlat2) + u_xlat4;
    }
    u_xlat0 = u_xlat3 / u_xlat14.xxxx;
    if(int(u._use_inner_mask) != 0) {
        u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat2.x = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
