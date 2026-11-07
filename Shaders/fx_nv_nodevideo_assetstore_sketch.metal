// ---------------------------------------------------------------------------
// Sketch (NV)
// origem : assets/effects/nv-nodevideo-assetstore-sketch.xml
// id     : nv.effect.nodevideo-assetstore-sketch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_sketchParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _color;
    float _brush_size;
    float _detail;
    float _intensity;
    float _scratch_speed;
    float _blend;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float u_xlat7;
float3 u_xlat9;
float u_xlat14;
float2 u_xlat17;
float u_xlat21;
float u_xlat23;

fragment float4 fx_nv_nodevideo_assetstore_sketch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_sketchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0.xyz = texture0.sample(__nv_smp, u_xlat0.xy).xyz;
    u_xlat21 = u._detail * 25.0;
    u_xlat2.x = _cur_time * u._scratch_speed;
    u_xlat2.x = u_xlat2.x * 10.0;
    u_xlat3.x = cos(u_xlat2.x);
    u_xlat2.x = sin(u_xlat2.x);
    u_xlat2.x = u_xlat2.x * 0.0199999996;
    u_xlat2.y = u_xlat3.x * 0.0199999996;
    u_xlat2.xy = floor(u_xlat2.xy);
    u_xlat7 = (-u_xlat0.y) + 1.0;
    u_xlat14 = u_xlat0.z * 0.0199999996;
    u_xlat3.x = u_xlat2.y * 0.0833333358 + u_xlat14;
    u_xlat3.y = u_xlat2.x * 0.0833333358 + u_xlat14;
    u_xlat2.xy = in.acScreenNorm.xy * float2(_viewport_ratio.x, _viewport_ratio.y) + u_xlat3.xy;
    u_xlat14 = texture0.sample(__nv_smp, u_xlat2.xy).z;
    u_xlat2.x = u._brush_size * 9.99999975e-05 + in.acScreenNorm.x;
    u_xlat2.yw = in.acScreenNorm.yy;
    u_xlat2.xy = u_xlat3.xy * float2(0.0078125, 0.0078125) + u_xlat2.xy;
    u_xlat4.xyz = inputImg.sample(__nv_smp, u_xlat2.xy).xyz;
    u_xlat2.z = (-u._brush_size) * 9.99999975e-05 + in.acScreenNorm.x;
    u_xlat2.xy = u_xlat3.xy * float2(0.0078125, 0.0078125) + u_xlat2.zw;
    u_xlat2.xyz = inputImg.sample(__nv_smp, u_xlat2.xy).xyz;
    u_xlat5.xz = in.acScreenNorm.xx;
    u_xlat5.y = u._brush_size * 9.99999975e-05 + in.acScreenNorm.y;
    u_xlat17.xy = u_xlat3.xy * float2(0.0078125, 0.0078125) + u_xlat5.xy;
    u_xlat6.xyz = inputImg.sample(__nv_smp, u_xlat17.xy).xyz;
    u_xlat5.w = (-u._brush_size) * 9.99999975e-05 + in.acScreenNorm.y;
    u_xlat3.xy = u_xlat3.xy * float2(0.0078125, 0.0078125) + u_xlat5.zw;
    u_xlat3.xyz = inputImg.sample(__nv_smp, u_xlat3.xy).xyz;
    u_xlat4.xyz = u_xlat1.xyz + (-u_xlat4.xyz);
    u_xlat4.xyz = -abs(u_xlat4.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat4.xyz = max(u_xlat4.xyz, float3(0.0, 0.0, 0.0));
    u_xlat23 = u_xlat4.y * u_xlat4.x;
    u_xlat23 = u_xlat4.z * u_xlat23;
    u_xlat23 = log2(u_xlat23);
    u_xlat23 = u_xlat21 * u_xlat23;
    u_xlat23 = exp2(u_xlat23);
    u_xlat23 = dot(float4(u_xlat23), float4(1.0, 1.0, 1.0, 1.0));
    u_xlat2.xyz = u_xlat1.xyz + (-u_xlat2.xyz);
    u_xlat2.xyz = -abs(u_xlat2.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat2.xyz = max(u_xlat2.xyz, float3(0.0, 0.0, 0.0));
    u_xlat2.x = u_xlat2.y * u_xlat2.x;
    u_xlat2.x = u_xlat2.z * u_xlat2.x;
    u_xlat2.x = log2(u_xlat2.x);
    u_xlat2.x = u_xlat21 * u_xlat2.x;
    u_xlat2.x = exp2(u_xlat2.x);
    u_xlat2.x = dot(u_xlat2.xxxx, float4(1.0, 1.0, 1.0, 1.0));
    u_xlat2.x = u_xlat2.x * u_xlat23;
    u_xlat9.xyz = u_xlat1.xyz + (-u_xlat6.xyz);
    u_xlat9.xyz = -abs(u_xlat9.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat9.xyz = max(u_xlat9.xyz, float3(0.0, 0.0, 0.0));
    u_xlat9.x = u_xlat9.y * u_xlat9.x;
    u_xlat9.x = u_xlat9.z * u_xlat9.x;
    u_xlat9.x = log2(u_xlat9.x);
    u_xlat9.x = u_xlat21 * u_xlat9.x;
    u_xlat9.x = exp2(u_xlat9.x);
    u_xlat9.x = dot(u_xlat9.xxxx, float4(1.0, 1.0, 1.0, 1.0));
    u_xlat2.x = u_xlat9.x * u_xlat2.x;
    u_xlat9.xyz = u_xlat1.xyz + (-u_xlat3.xyz);
    u_xlat9.xyz = -abs(u_xlat9.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat9.xyz = max(u_xlat9.xyz, float3(0.0, 0.0, 0.0));
    u_xlat9.x = u_xlat9.y * u_xlat9.x;
    u_xlat9.x = u_xlat9.z * u_xlat9.x;
    u_xlat9.x = log2(u_xlat9.x);
    u_xlat21 = u_xlat21 * u_xlat9.x;
    u_xlat21 = exp2(u_xlat21);
    u_xlat21 = dot(float4(u_xlat21), float4(1.0, 1.0, 1.0, 1.0));
    u_xlat21 = u_xlat21 * u_xlat2.x;
    u_xlat21 = min(u_xlat21, 1.0);
    u_xlat21 = (-u_xlat21) + 1.0;
    u_xlat14 = u_xlat14 * u_xlat21;
    u_xlat14 = u_xlat14 * u._intensity;
    u_xlat14 = u_xlat14 * 1.5;
    u_xlat14 = u_xlat14 * u._intensity;
    u_xlat2.xyz = (-u_xlat0.xxx) + u._color.xyz;
    u_xlat0.xzw = float3(u_xlat14) * u_xlat2.xyz + u_xlat0.xxx;
    u_xlat0.xyz = (-float3(u_xlat7)) * float3(0.5, 0.5, 0.5) + u_xlat0.xzw;
    u_xlat21 = (-u._blend) + 1.0;
    u_xlat0.xyz = (-u_xlat1.xyz) + u_xlat0.xyz;
    u_xlat0.xyz = float3(u_xlat21) * u_xlat0.xyz + u_xlat1.xyz;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat0.w = u_xlat1.w;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat5 = u_xlat1 * u_xlat5;
        u_xlat3 = u_xlat3 * u_xlat4 + u_xlat5;
        u_xlat21 = u_xlat4.x * u_xlat3.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat21 : u_xlat3.w;
        __nv_out.xyz = u_xlat3.xyz;
    } else {
        __nv_out.xyz = u_xlat0.xyz;
        __nv_out.w = u_xlat1.w;
    }
    return __nv_out;
    return __nv_out;
}
