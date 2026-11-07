// ---------------------------------------------------------------------------
// Fill Lens Flare (NV)
// origem : assets/effects/nv-nodevideo-fill-lens-flare.xml
// id     : nv.effect.nodevideo-fill-lens-flare
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_lens_flareParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _sun_pos;
    float _brightness;
    float _glow_radius;
    float _point_glow;
    float _lens_dist;
    float _lens_opacity;
    float _sun_size;
    float _sun_shaft;
    float4 _lens_color;
    float4 _sun_color;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
bool u_xlatb0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
bool u_xlatb6;
float u_xlat7;
bool u_xlatb7;
float3 u_xlat8;
bool u_xlatb8;
float u_xlat11;
float u_xlat14;
float u_xlat15;
float2 u_xlat18;
float u_xlat19;
bool u_xlatb19;
float u_xlat21;
bool u_xlatb21;
float u_xlat22;
bool u_xlatb22;
float u_xlat24;
bool u_xlatb24;
float u_xlat25;
float u_xlat26;
bool u_xlatb26;

fragment float4 fx_nv_nodevideo_fill_lens_flare(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_lens_flareParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = in.acScreenNorm.yxxy + float4(-0.5, -0.5, -0.5, -0.5);
    u_xlat1.xy = u_xlat0.zw * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat2 = u._sun_pos.yxxy + float4(-0.5, -0.5, -0.5, -0.5);
    u_xlat2 = u_xlat2 * float4(_viewport_ratio.y, _viewport_ratio.x, _viewport_ratio.x, _viewport_ratio.y);
    u_xlat15 = u._point_glow * 0.100000001;
    u_xlat3.x = float(0.0);
    u_xlat3.y = float(0.0);
    u_xlat3.z = float(0.0);
    u_xlat22 = 0.0;
    while(true){
        u_xlatb24 = u_xlat22>=10.0;
        if(u_xlatb24){break;}
        u_xlat4.xy = float2(u_xlat22) * float2(2000.0, 20.0);
        u_xlat4.xy = sin(u_xlat4.xy);
        u_xlat4.xy = u_xlat4.xy * float2(1000.0, 1000.0);
        u_xlat4.xy = fract(u_xlat4.xy);
        u_xlat24 = u_xlat4.x * u_xlat4.x + u._glow_radius;
        u_xlat4.x = u_xlat4.y * 3.0 + u._lens_dist;
        u_xlat4.x = u_xlat4.x + -0.300000012;
        u_xlat11 = u_xlat4.x * 4.0;
        u_xlat18.xy = u_xlat2.zw * float2(u_xlat11) + u_xlat1.xy;
        u_xlat18.x = dot(u_xlat18.xy, u_xlat18.xy);
        u_xlat18.x = sqrt(u_xlat18.x);
        u_xlat25 = u_xlat24 * 1.39999998;
        u_xlat24 = u_xlat24 * 0.5 + u_xlat18.x;
        u_xlat5 = u_xlat2.zwzw * u_xlat4.xxxx;
        u_xlat4.xz = u_xlat0.zw * float2(_viewport_ratio.x, _viewport_ratio.y) + u_xlat5.zw;
        u_xlat4.x = dot(u_xlat4.xz, u_xlat4.xz);
        u_xlat4.x = sqrt(u_xlat4.x);
        u_xlat4.x = log2(u_xlat4.x);
        u_xlat4.x = u_xlat4.x * u_xlat25;
        u_xlat4.x = exp2(u_xlat4.x);
        u_xlat4.x = (-u_xlat4.x) + 0.00999999978;
        u_xlat4.x = max(u_xlat4.x, 0.0);
        u_xlat18.x = u_xlat24 + -0.300000012;
        u_xlat4.z = log2(abs(u_xlat18.x));
        u_xlat4.xz = u_xlat4.xz * float2(50.0, 0.0250000004);
        u_xlat18.x = exp2(u_xlat4.z);
        u_xlat18.x = (-u_xlat18.x) + 0.00100000005;
        u_xlat24 = u_xlat24 * 30.0;
        u_xlat24 = sin(u_xlat24);
        u_xlat24 = u_xlat24 + u_xlat18.x;
        u_xlat24 = max(u_xlat24, 0.0);
        u_xlat24 = u_xlat24 * 3.0;
        u_xlat5 = u_xlat5 * float4(0.5, 0.5, 5.0, 5.0);
        u_xlat18.xy = u_xlat0.zw * float2(_viewport_ratio.x, _viewport_ratio.y) + (-u_xlat5.xy);
        u_xlat18.x = dot(u_xlat18.xy, u_xlat18.xy);
        u_xlat18.x = sqrt(u_xlat18.x);
        u_xlat18.x = u_xlat15 / u_xlat18.x;
        u_xlat18.x = max(u_xlat18.x, 0.0);
        u_xlat18.x = u_xlat18.x * 0.0500000007;
        u_xlat5.xy = u_xlat1.xy * float2(5.0, 5.0) + u_xlat5.zw;
        u_xlat5.xy = u_xlat5.xy + float2(0.400000006, 0.400000006);
        u_xlat25 = min(abs(u_xlat5.y), abs(u_xlat5.x));
        u_xlat19 = max(abs(u_xlat5.y), abs(u_xlat5.x));
        u_xlat19 = float(1.0) / u_xlat19;
        u_xlat25 = u_xlat25 * u_xlat19;
        u_xlat19 = u_xlat25 * u_xlat25;
        u_xlat26 = u_xlat19 * 0.0208350997 + -0.0851330012;
        u_xlat26 = u_xlat19 * u_xlat26 + 0.180141002;
        u_xlat26 = u_xlat19 * u_xlat26 + -0.330299497;
        u_xlat19 = u_xlat19 * u_xlat26 + 0.999866009;
        u_xlat26 = u_xlat25 * u_xlat19;
        u_xlatb6 = abs(u_xlat5.y)<abs(u_xlat5.x);
        u_xlat26 = u_xlat26 * -2.0 + 1.57079637;
        u_xlat26 = u_xlatb6 ? u_xlat26 : float(0.0);
        u_xlat25 = u_xlat25 * u_xlat19 + u_xlat26;
        u_xlatb19 = u_xlat5.y<(-u_xlat5.y);
        u_xlat19 = u_xlatb19 ? -3.14159274 : float(0.0);
        u_xlat25 = u_xlat25 + u_xlat19;
        u_xlat19 = min(u_xlat5.y, u_xlat5.x);
        u_xlat26 = max(u_xlat5.y, u_xlat5.x);
        u_xlatb19 = u_xlat19<(-u_xlat19);
        u_xlatb26 = u_xlat26>=(-u_xlat26);
        u_xlatb19 = u_xlatb26 && u_xlatb19;
        u_xlat25 = (u_xlatb19) ? (-u_xlat25) : u_xlat25;
        u_xlat25 = u_xlat25 + 0.200000003;
        u_xlat19 = u_xlat25 * 0.954928994 + 0.5;
        u_xlat19 = floor(u_xlat19);
        u_xlat25 = u_xlat19 * 1.0471983 + (-u_xlat25);
        u_xlat25 = cos(u_xlat25);
        u_xlat5.x = dot(u_xlat5.xy, u_xlat5.xy);
        u_xlat5.x = sqrt(u_xlat5.x);
        u_xlat25 = u_xlat25 * u_xlat5.x + -0.5;
        u_xlat25 = u_xlat25 * 100.000099;
        u_xlat25 = clamp(u_xlat25, 0.0, 1.0);
        u_xlat5.x = u_xlat25 * -2.0 + 3.0;
        u_xlat25 = u_xlat25 * u_xlat25;
        u_xlat25 = (-u_xlat5.x) * u_xlat25 + 0.00999999978;
        u_xlat25 = max(u_xlat25, 0.0);
        u_xlat25 = u_xlat25 * u._lens_opacity;
        u_xlat5.xyz = u._lens_color.xyz * float3(8.0, 8.0, 8.0) + float3(u_xlat11);
        u_xlat5.xyz = cos(u_xlat5.xyz);
        u_xlat5.xyz = u_xlat5.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
        u_xlat6.xyz = float3(u_xlat24) * u_xlat5.xyz;
        u_xlat6.xyz = u_xlat4.xxx * u_xlat5.xyz + u_xlat6.xyz;
        u_xlat4.xyz = u_xlat18.xxx * u_xlat5.xyz + u_xlat6.xyz;
        u_xlat4.xyz = float3(u_xlat25) * u_xlat5.xyz + u_xlat4.xyz;
        u_xlat4.xyz = u_xlat3.xyz + u_xlat4.xyz;
        u_xlat3.xyz = u_xlat4.xyz + float3(-0.00999999978, -0.00999999978, -0.00999999978);
        u_xlat22 = u_xlat22 + 1.0;
    }
    u_xlat0 = u_xlat0 * float4(_viewport_ratio.y, _viewport_ratio.x, _viewport_ratio.x, _viewport_ratio.y) + (-u_xlat2);
    u_xlat1.x = min(abs(u_xlat0.y), abs(u_xlat0.x));
    u_xlat8.x = max(abs(u_xlat0.y), abs(u_xlat0.x));
    u_xlat8.x = float(1.0) / u_xlat8.x;
    u_xlat1.x = u_xlat8.x * u_xlat1.x;
    u_xlat8.x = u_xlat1.x * u_xlat1.x;
    u_xlat15 = u_xlat8.x * 0.0208350997 + -0.0851330012;
    u_xlat15 = u_xlat8.x * u_xlat15 + 0.180141002;
    u_xlat15 = u_xlat8.x * u_xlat15 + -0.330299497;
    u_xlat8.x = u_xlat8.x * u_xlat15 + 0.999866009;
    u_xlat15 = u_xlat8.x * u_xlat1.x;
    u_xlatb22 = abs(u_xlat0.y)<abs(u_xlat0.x);
    u_xlat15 = u_xlat15 * -2.0 + 1.57079637;
    u_xlat15 = u_xlatb22 ? u_xlat15 : float(0.0);
    u_xlat1.x = u_xlat1.x * u_xlat8.x + u_xlat15;
    u_xlatb8 = u_xlat0.y<(-u_xlat0.y);
    u_xlat8.x = u_xlatb8 ? -3.14159274 : float(0.0);
    u_xlat1.x = u_xlat8.x + u_xlat1.x;
    u_xlat8.x = min(u_xlat0.y, u_xlat0.x);
    u_xlat0.x = max(u_xlat0.y, u_xlat0.x);
    u_xlatb7 = u_xlat8.x<(-u_xlat8.x);
    u_xlatb0 = u_xlat0.x>=(-u_xlat0.x);
    u_xlatb0 = u_xlatb0 && u_xlatb7;
    u_xlat0.x = (u_xlatb0) ? (-u_xlat1.x) : u_xlat1.x;
    u_xlat7 = dot(u_xlat0.zw, u_xlat0.zw);
    u_xlat7 = sqrt(u_xlat7);
    u_xlat14 = u_xlat7 / u._sun_size;
    u_xlat21 = u_xlat14 * u_xlat14;
    u_xlat21 = u_xlat21 * u_xlat21;
    u_xlat14 = u_xlat21 * u_xlat14;
    u_xlat14 = 0.100000001 / u_xlat14;
    u_xlat14 = max(u_xlat14, 0.0);
    u_xlat21 = u_xlat0.x * 9.0;
    u_xlat1.x = sin(u_xlat21);
    u_xlat2.x = cos(u_xlat21);
    u_xlat0.xw = u_xlat0.xx * float2(5.0, 3.0) + u_xlat2.xx;
    u_xlat0.xw = sin(u_xlat0.xw);
    u_xlat0.x = abs(u_xlat0.x) * u_xlat14;
    u_xlat8.xyz = u_xlat0.xxx * float3(0.0500000007, 0.0500000007, 0.0500000007) + u_xlat3.xyz;
    u_xlat0.xz = float2(u_xlat7) * float2(10.0, 4.0);
    u_xlat0.x = log2(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * 0.0500000007;
    u_xlat0.x = exp2(u_xlat0.x);
    u_xlat0.x = 0.100000001 / u_xlat0.x;
    u_xlat21 = abs(u_xlat0.w) * 0.125;
    u_xlat21 = abs(u_xlat1.x) * u_xlat21;
    u_xlat0.x = u_xlat21 * u._sun_shaft + u_xlat0.x;
    u_xlat1.xyz = u_xlat0.xxx + u_xlat8.xyz;
    u_xlat0.x = rsqrt(u_xlat0.z);
    u_xlat0.x = float(1.0) / u_xlat0.x;
    u_xlat0.x = u._brightness / u_xlat0.x;
    u_xlat0.x = max(u_xlat0.x, 0.0);
    u_xlat0.x = u_xlat0.x * 4.0;
    u_xlat0.xzw = u_xlat0.xxx * u._sun_color.xyz;
    u_xlat0.xzw = u_xlat0.xzw * float3(4.0, 4.0, 4.0) + u_xlat1.xyz;
    u_xlat7 = (-u_xlat7) + 1.0;
    u_xlat7 = u_xlat7 * 1.44269502;
    u_xlat7 = exp2(u_xlat7);
    u_xlat7 = u_xlat7 * 0.200000003;
    u_xlat0.xyz = float3(u_xlat7) * u_xlat0.xzw;
    u_xlat1.xyz = u_xlat0.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.xyz = u_xlat0.xyz * u_xlat1.xyz;
    u_xlat3 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb21 = int(u._blend_mode)==1;
    u_xlat2.w = 1.0;
    u_xlat4 = u_xlat2 * u_xlat3;
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xyz + u_xlat3.xyz;
    u_xlat1.w = u_xlat3.w;
    u_xlat0 = (bool(u_xlatb21)) ? u_xlat4 : u_xlat1;
    u_xlat1.xyz = u_xlat2.xyz;
    u_xlat0 = (int(u._blend_mode) != 0) ? u_xlat0 : u_xlat1;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat2 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat3 = u_xlat3 * u_xlat5;
        u_xlat2 = u_xlat2 * u_xlat4 + u_xlat3;
        u_xlat1.x = u_xlat4.x * u_xlat2.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat2.w;
        __nv_out.xyz = u_xlat2.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
