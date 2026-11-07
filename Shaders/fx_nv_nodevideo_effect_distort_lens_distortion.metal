// ---------------------------------------------------------------------------
// Effect Distort Lens Distortion (NV)
// origem : assets/effects/nv-nodevideo-effect-distort-lens-distortion.xml
// id     : nv.effect.nodevideo-effect-distort-lens-distortion
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_distort_lens_distortionParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _amount;
    float _radius;
    float _zoom;
    float2 _center;
    float2 _size;
    float _keep_edge;
    float _inverse;
    float _enable_dispersion;
    float _range;
    float _strength;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
bool2 u_xlatb0;
float4 u_xlat1;
int2 u_xlati1;
bool2 u_xlatb1;
float u_xlat2;
int u_xlati2;
bool2 u_xlatb2;
float4 u_xlat3;
int2 u_xlati3;
bool2 u_xlatb3;
float4 u_xlat4;
bool2 u_xlatb4;
float4 u_xlat5;
float u_xlat6;
float u_xlat7;
float3 u_xlat9;
bool u_xlatb9;
float u_xlat10;
float u_xlat11;
float2 u_xlat14;
bool2 u_xlatb14;
float2 u_xlat15;
float2 u_xlat16;
float2 u_xlat17;
float u_xlat18;
float u_xlat21;
float u_xlat23;
bool u_xlatb23;
float u_xlat24;
bool u_xlatb25;

fragment float4 fx_nv_nodevideo_effect_distort_lens_distortion(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_distort_lens_distortionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0.xy = lessThan(int4(0, 0, 0, 0), int4(int(u._inverse), int(u._enable_dispersion), int(u._inverse), int(u._inverse))).xy;
    u_xlat14.x = max(u._amount, 0.100000001);
    u_xlat14.x = (u_xlatb0.x) ? u_xlat14.x : u._amount;
    u_xlat14.xy = u_xlat14.xx * float2(0.0174532924, 0.00872664619);
    u_xlat1.x = sin(u_xlat14.y);
    u_xlat2 = cos(u_xlat14.y);
    u_xlat21 = u_xlat1.x / u_xlat2;
    u_xlat14.y = u_xlat21 + u_xlat21;
    u_xlat1.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat1.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat15.xy = u._center.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat1.xy * float2(float2(u._zoom, u._zoom));
    u_xlat15.xy = (-u_xlat15.xy) * float2(_viewport_ratio.x, _viewport_ratio.y) + u_xlat1.xy;
    u_xlat15.xy = u_xlat15.xy * float2(u._size.x, u._size.y);
    u_xlat2 = dot(u_xlat15.xy, u_xlat15.xy);
    u_xlat2 = sqrt(u_xlat2);
    u_xlat9.xy = float2(_viewport_ratio.x, _viewport_ratio.y) * u._center.xy;
    if(u_xlatb0.x){
        u_xlat23 = min(u_xlat9.y, u_xlat9.x);
        u_xlat23 = u_xlat23 * u._radius;
        u_xlat3.x = float(1.0) / u_xlat2;
        u_xlat3.x = u_xlat23 * u_xlat3.x;
        u_xlat3.x = u_xlat3.x / u_xlat14.x;
        u_xlat10 = u_xlat14.y * u_xlat2;
        u_xlat23 = u_xlat10 / u_xlat23;
        u_xlat10 = min(abs(u_xlat23), 1.0);
        u_xlat17.x = max(abs(u_xlat23), 1.0);
        u_xlat17.x = float(1.0) / u_xlat17.x;
        u_xlat10 = u_xlat17.x * u_xlat10;
        u_xlat17.x = u_xlat10 * u_xlat10;
        u_xlat24 = u_xlat17.x * 0.0208350997 + -0.0851330012;
        u_xlat24 = u_xlat17.x * u_xlat24 + 0.180141002;
        u_xlat24 = u_xlat17.x * u_xlat24 + -0.330299497;
        u_xlat17.x = u_xlat17.x * u_xlat24 + 0.999866009;
        u_xlat24 = u_xlat17.x * u_xlat10;
        u_xlatb4.x = 1.0<abs(u_xlat23);
        u_xlat24 = u_xlat24 * -2.0 + 1.57079637;
        u_xlat24 = u_xlatb4.x ? u_xlat24 : float(0.0);
        u_xlat10 = u_xlat10 * u_xlat17.x + u_xlat24;
        u_xlat23 = min(u_xlat23, 1.0);
        u_xlatb23 = u_xlat23<(-u_xlat23);
        u_xlat23 = (u_xlatb23) ? (-u_xlat10) : u_xlat10;
        u_xlat23 = u_xlat3.x * u_xlat23 + -1.0;
        u_xlat3.xy = u_xlat15.xy * float2(u_xlat23) + u_xlat1.xy;
    } else {
        u_xlat14.xy = u_xlat14.xy * float2(u_xlat2);
        u_xlat14.x = u_xlat14.x / u._radius;
        u_xlat4.x = sin(u_xlat14.x);
        u_xlat5.x = cos(u_xlat14.x);
        u_xlat14.x = u_xlat4.x / u_xlat5.x;
        u_xlat21 = u._radius / u_xlat14.y;
        u_xlat14.x = u_xlat14.x * u_xlat21 + -1.0;
        u_xlat3.xy = u_xlat15.xy * u_xlat14.xx + u_xlat1.xy;
    }
    u_xlat14.xy = u_xlat3.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat14.xy = u_xlat14.xy + float2(0.5, 0.5);
    u_xlatb23 = int(u._keep_edge)==1;
    u_xlatb3.xy = lessThan(u_xlat14.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlat17.xy = fract(u_xlat14.xy);
    u_xlat17.xy = (-u_xlat17.xy) + float2(1.0, 1.0);
    u_xlatb4.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat14.xyxx).xy;
    u_xlati3.xy = int2(uint2((uint(u_xlatb3.x) * 0xffffffffu) | (uint(u_xlatb4.x) * 0xffffffffu), (uint(u_xlatb3.y) * 0xffffffffu) | (uint(u_xlatb4.y) * 0xffffffffu)));
    u_xlat3.x = (u_xlati3.x != 0) ? u_xlat17.x : u_xlat14.x;
    u_xlat3.y = (u_xlati3.y != 0) ? u_xlat17.y : u_xlat14.y;
    u_xlat14.xy = (bool(u_xlatb23)) ? u_xlat3.xy : u_xlat14.xy;
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat14.xy);
    if(u_xlatb0.y){
        u_xlat7 = (-u._amount) * u._range + u._amount;
        u_xlat4.x = max(u_xlat7, 0.100000001);
        u_xlat7 = (u_xlatb0.x) ? u_xlat4.x : u_xlat7;
        u_xlat4.xy = float2(u_xlat7) * float2(0.0174532924, 0.00872664619);
        u_xlat5.x = sin(u_xlat4.y);
        u_xlat6 = cos(u_xlat4.y);
        u_xlat7 = u_xlat5.x / u_xlat6;
        u_xlat7 = u_xlat7 + u_xlat7;
        if(u_xlatb0.x){
            u_xlat0.x = min(u_xlat9.y, u_xlat9.x);
            u_xlat0.x = u_xlat0.x * u._radius;
            u_xlat9.x = float(1.0) / u_xlat2;
            u_xlat9.x = u_xlat0.x * u_xlat9.x;
            u_xlat9.x = u_xlat9.x / u_xlat4.x;
            u_xlat16.x = u_xlat7 * u_xlat2;
            u_xlat0.x = u_xlat16.x / u_xlat0.x;
            u_xlat16.x = min(abs(u_xlat0.x), 1.0);
            u_xlat11 = max(abs(u_xlat0.x), 1.0);
            u_xlat11 = float(1.0) / u_xlat11;
            u_xlat16.x = u_xlat16.x * u_xlat11;
            u_xlat11 = u_xlat16.x * u_xlat16.x;
            u_xlat18 = u_xlat11 * 0.0208350997 + -0.0851330012;
            u_xlat18 = u_xlat11 * u_xlat18 + 0.180141002;
            u_xlat18 = u_xlat11 * u_xlat18 + -0.330299497;
            u_xlat11 = u_xlat11 * u_xlat18 + 0.999866009;
            u_xlat18 = u_xlat16.x * u_xlat11;
            u_xlatb25 = 1.0<abs(u_xlat0.x);
            u_xlat18 = u_xlat18 * -2.0 + 1.57079637;
            u_xlat18 = u_xlatb25 ? u_xlat18 : float(0.0);
            u_xlat16.x = u_xlat16.x * u_xlat11 + u_xlat18;
            u_xlat0.x = min(u_xlat0.x, 1.0);
            u_xlatb0.x = u_xlat0.x<(-u_xlat0.x);
            u_xlat0.x = (u_xlatb0.x) ? (-u_xlat16.x) : u_xlat16.x;
            u_xlat0.x = u_xlat9.x * u_xlat0.x + -1.0;
            u_xlat9.xy = u_xlat15.xy * u_xlat0.xx + u_xlat1.xy;
        } else {
            u_xlat0.x = u_xlat2 * u_xlat4.x;
            u_xlat0.x = u_xlat0.x / u._radius;
            u_xlat4.x = cos(u_xlat0.x);
            u_xlat0.x = sin(u_xlat0.x);
            u_xlat0.x = u_xlat0.x / u_xlat4.x;
            u_xlat7 = u_xlat7 * u_xlat2;
            u_xlat7 = u._radius / u_xlat7;
            u_xlat0.x = u_xlat0.x * u_xlat7 + -1.0;
            u_xlat9.xy = u_xlat15.xy * u_xlat0.xx + u_xlat1.xy;
        }
        u_xlat0.xy = u_xlat9.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
        u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
        u_xlatb1.xy = lessThan(u_xlat0.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlat15.xy = fract(u_xlat0.xy);
        u_xlat15.xy = (-u_xlat15.xy) + float2(1.0, 1.0);
        u_xlatb2.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.xyxx).xy;
        u_xlati1.xy = int2(uint2((uint(u_xlatb1.x) * 0xffffffffu) | (uint(u_xlatb2.x) * 0xffffffffu), (uint(u_xlatb1.y) * 0xffffffffu) | (uint(u_xlatb2.y) * 0xffffffffu)));
        u_xlat1.x = (u_xlati1.x != 0) ? u_xlat15.x : u_xlat0.x;
        u_xlat1.y = (u_xlati1.y != 0) ? u_xlat15.y : u_xlat0.y;
        u_xlat0.xy = (bool(u_xlatb23)) ? u_xlat1.xy : u_xlat0.xy;
        u_xlat0.xy = (-u_xlat0.xy) + u_xlat14.xy;
        u_xlat1 = u_xlat3;
        for(int u_xlati_loop_1 = 1 ; u_xlati_loop_1<64 ; u_xlati_loop_1++)
        {
            u_xlat9.x = float(u_xlati_loop_1);
            u_xlat16.x = u_xlat9.x * 0.0158730168;
            u_xlat16.xy = (-u_xlat0.xy) * u_xlat16.xx;
            u_xlat16.xy = u_xlat16.xy * float2(u._strength) + u_xlat14.xy;
            u_xlat4 = inputImg.sample(__nv_smp, u_xlat16.xy);
            u_xlat5.z = u_xlat9.x * 0.0476190522 + -1.5;
            u_xlat5.y = -abs(u_xlat5.z) + 1.0;
            u_xlat5.x = (-u_xlat5.z);
            u_xlat5.xyz = u_xlat5.xyz;
            u_xlat5.xyz = clamp(u_xlat5.xyz, 0.0, 1.0);
            u_xlat9.xyz = u_xlat4.xyz * u_xlat5.xyz;
            u_xlat4.xyz = u_xlat9.xyz * float3(3.0, 3.0, 3.0);
            u_xlat1 = u_xlat1 + u_xlat4;
        }
        u_xlat3 = u_xlat1 * float4(0.015625, 0.015625, 0.015625, 0.015625);
    }
    u_xlatb0.xy = lessThan(u_xlat14.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb14.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat14.xyxy).xy;
    u_xlatb0.x = u_xlatb14.x || u_xlatb0.x;
    u_xlatb0.x = u_xlatb0.y || u_xlatb0.x;
    u_xlatb0.x = u_xlatb14.y || u_xlatb0.x;
    u_xlat0.x = (u_xlatb0.x) ? 0.0 : 1.0;
    u_xlat0 = u_xlat0.xxxx * u_xlat3;
    if(int(u._use_inner_mask) != 0) {
        u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat2 = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2 : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
