// ---------------------------------------------------------------------------
// Effect Blur Bokeh (NV)
// origem : assets/effects/nv-nodevideo-effect-blur-bokeh.xml
// id     : nv.effect.nodevideo-effect-blur-bokeh
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_blur_bokehParams {
    float _blur_radius;
    float2 _threshold;
    float _gain;
    float2 _blur_dir;
    float _samples;
    float _enable_highlight;
    float _angle;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float2 u_xlat1;
float4 u_xlat2;
int u_xlati3;
float4 u_xlat4;
float3 u_xlat5;
float3 u_xlat9;
bool u_xlatb9;
float u_xlat11;
float2 u_xlat12;
float2 u_xlat13;
float u_xlat17;

fragment float4 fx_nv_nodevideo_effect_blur_bokeh(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_blur_bokehParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = u._angle * 0.0174532942;
    u_xlat1.x = sin(u_xlat0.x);
    u_xlat2.x = cos(u_xlat0.x);
    u_xlat0.x = sin((-u_xlat0.x));
    u_xlat0.y = u_xlat2.x;
    u_xlat2.x = dot(u_xlat0.yx, u._blur_dir.xy);
    u_xlat0.z = u_xlat1.x;
    u_xlat2.y = dot(u_xlat0.zy, u._blur_dir.xy);
    u_xlat0.x = dot(u_xlat2.xy, u_xlat2.xy);
    u_xlat0.x = rsqrt(u_xlat0.x);
    u_xlat0.xy = u_xlat0.xx * u_xlat2.xy;
    u_xlat0.xy = u_xlat0.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat12.x = u._blur_radius * 0.0500000007;
    u_xlat1.xy = (-u_xlat12.xx) * u_xlat0.xy + in.acScreenNorm.xy;
    u_xlat0.xy = u_xlat12.xx * u_xlat0.xy + in.acScreenNorm.xy;
    u_xlat0.xy = (-u_xlat1.xy) + u_xlat0.xy;
    u_xlat12.xy = float2(int2(int(u._samples), int(u._enable_highlight)));
    u_xlat0.xy = u_xlat0.xy / u_xlat12.xx;
    u_xlat1.xy = u_xlat0.xy * float2(0.5, 0.5) + u_xlat1.xy;
    u_xlat13.x = fract(_cur_time);
    u_xlat13.xy = u_xlat13.xx + in.acScreenNorm.xy;
    u_xlat13.xy = u_xlat13.xy * float2(5.39870024, 5.44210005);
    u_xlat13.xy = fract(u_xlat13.xy);
    u_xlat2.xy = u_xlat13.xy + float2(21.5351009, 14.3136997);
    u_xlat2.x = dot(u_xlat13.yx, u_xlat2.xy);
    u_xlat13.xy = u_xlat13.xy + u_xlat2.xx;
    u_xlat13.x = u_xlat13.y * u_xlat13.x;
    u_xlat13.x = u_xlat13.x * 95.4307022;
    u_xlat13.x = fract(u_xlat13.x);
    u_xlat13.x = u_xlat13.x + -0.5;
    u_xlat1.xy = u_xlat13.xx * u_xlat0.xy + u_xlat1.xy;
    u_xlat2.x = float(0.0);
    u_xlat2.y = float(0.0);
    u_xlat2.z = float(0.0);
    u_xlat2.w = float(0.0);
    u_xlat13.xy = u_xlat1.xy;
    for(int u_xlati_loop_1 = 0 ; u_xlati_loop_1<int(u._samples) ; u_xlati_loop_1++)
    {
        u_xlat4 = inputImg.sample(__nv_smp, u_xlat13.xy);
        u_xlat4 = u_xlat4 * u_xlat4;
        u_xlat9.x = dot(u_xlat4.xyz, u_xlat4.xyz);
        u_xlat9.x = rsqrt(u_xlat9.x);
        u_xlat9.xyz = u_xlat9.xxx * u_xlat4.xyz;
        u_xlat9.xyz = u_xlat9.xyz * float3(u._threshold.y, u._threshold.y, u._threshold.y);
        u_xlat9.xyz = min(u_xlat9.xyz, u_xlat4.xyz);
        u_xlat9.xyz = u_xlat9.xyz * float3(0.908999979, 0.908999979, 0.908999979);
        u_xlat5.x = max(u_xlat9.z, u_xlat9.y);
        u_xlat5.x = max(u_xlat9.x, u_xlat5.x);
        u_xlat11 = u_xlat5.x + (-u._threshold.xxyx.y);
        u_xlat5.z = u_xlat11 + 9.99999975e-05;
        u_xlat5.xz = max(u_xlat5.xz, float2(9.99999975e-05, 0.0));
        u_xlat17 = min(u_xlat5.z, 0.000199999995);
        u_xlat17 = u_xlat17 * u_xlat17;
        u_xlat17 = u_xlat17 * 2000.00012;
        u_xlat11 = max(u_xlat11, u_xlat17);
        u_xlat9.xyz = u_xlat9.xyz * float3(u_xlat11);
        u_xlat9.xyz = u_xlat9.xyz / u_xlat5.xxx;
        u_xlat9.xyz = max(u_xlat9.xyz, float3(0.0, 0.0, 0.0));
        u_xlat9.xyz = u_xlat9.xyz * u_xlat4.xyz;
        u_xlat9.xyz = u_xlat9.xyz * float3(float3(u._gain, u._gain, u._gain));
        u_xlat9.xyz = u_xlat12.yyy * u_xlat9.xyz;
        u_xlat9.xyz = u_xlat9.xyz * float3(u._blur_radius);
        u_xlat4.xyz = u_xlat9.xyz * float3(2.0, 2.0, 2.0) + u_xlat4.xyz;
        u_xlat2 = u_xlat2 + u_xlat4;
        u_xlat13.xy = u_xlat0.xy + u_xlat13.xy;
    }
    u_xlat0 = u_xlat2 / u_xlat12.xxxx;
    __nv_out = sqrt(u_xlat0);
    return __nv_out;
    return __nv_out;
}
