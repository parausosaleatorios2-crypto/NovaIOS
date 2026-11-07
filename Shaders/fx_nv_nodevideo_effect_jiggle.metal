// ---------------------------------------------------------------------------
// Effect Jiggle (NV)
// origem : assets/effects/nv-nodevideo-effect-jiggle.xml
// id     : nv.effect.nodevideo-effect-jiggle
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_jiggleParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _amplitude;
    float _evolution;
    float _elastic;
    float _soft;
    float _loop;
    float _direction;
    float2 _center;
    float _keep_edge;
    float _prev_evolution;
    float _enable_motion_blur;
    float _samples;
    float _length;
    float _dispersion;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
int u_xlati1;
bool2 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
bool2 u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
int u_xlati7;
float u_xlat9;
float2 u_xlat12;
float u_xlat13;
bool u_xlatb13;
bool2 u_xlatb14;
float2 u_xlat15;
bool2 u_xlatb15;
float u_xlat18;
float u_xlat19;
bool u_xlatb19;

fragment float4 fx_nv_nodevideo_effect_jiggle(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_jiggleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + (-float2(u._center.x, u._center.y));
    u_xlat12.xy = float2(float2(u._evolution, u._evolution)) * float2(10.0, 0.5);
    u_xlat12.x = u_xlat12.x;
    u_xlat12.x = clamp(u_xlat12.x, 0.0, 1.0);
    u_xlat12.x = u_xlat12.x * u._soft;
    u_xlatb1.xy = equal(int4(int(u._loop), int(u._direction), int(u._loop), int(u._loop)), int4(1, 1, 0, 0)).xy;
    u_xlatb13 = u_xlat12.y>=(-u_xlat12.y);
    u_xlat18 = fract(abs(u_xlat12.y));
    u_xlat18 = (u_xlatb13) ? u_xlat18 : (-u_xlat18);
    u_xlat18 = (u_xlatb1.x) ? u_xlat18 : u._evolution;
    u_xlat13 = log2(u_xlat18);
    u_xlat13 = u_xlat13 * 0.200000003;
    u_xlat13 = exp2(u_xlat13);
    u_xlat13 = u_xlat13 * 0.5 + 0.5;
    u_xlat13 = u_xlat13 * u._amplitude;
    u_xlat19 = u_xlat18 * u._elastic;
    u_xlat12.x = u_xlat12.x * u_xlat0.y;
    u_xlat12.x = u_xlat19 * 6.28310013 + u_xlat12.x;
    u_xlat12.x = sin(u_xlat12.x);
    u_xlat12.x = u_xlat12.x * u_xlat13;
    u_xlat18 = u_xlat18 * -5.77078009;
    u_xlat18 = exp2(u_xlat18);
    u_xlat12.x = u_xlat12.x * u_xlat18 + 1.0;
    u_xlat12.xy = u_xlat12.xx * float2(0.5, -0.5) + float2(0.5, 1.5);
    u_xlat2.yz = u_xlat0.xy * u_xlat12.xy + float2(u._center.x, u._center.y);
    u_xlat2.x = (u_xlatb1.y) ? in.acScreenNorm.x : u_xlat2.y;
    u_xlat2.w = in.acScreenNorm.y;
    u_xlat12.xy = (int(u._direction) != 0) ? u_xlat2.xz : u_xlat2.yw;
    u_xlatb13 = int(u._keep_edge)==1;
    u_xlat2.xy = u_xlat12.xy + float2(-0.5, -0.5);
    u_xlat2.xy = u_xlat2.xy * float2(1.00999999, 1.00999999) + float2(0.5, 0.5);
    u_xlatb14.xy = lessThan(u_xlat2.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb3.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat2.xyxx).xy;
    u_xlat15.xy = fract(u_xlat2.xy);
    u_xlat15.xy = (-u_xlat15.xy) + float2(1.0, 1.0);
    u_xlat3.x = (u_xlatb3.x) ? u_xlat15.x : u_xlat2.x;
    u_xlat3.y = (u_xlatb3.y) ? u_xlat15.y : u_xlat2.y;
    {
        float4 hlslcc_movcTemp = u_xlat2;
        hlslcc_movcTemp.x = (u_xlatb14.x) ? (-u_xlat2.x) : u_xlat3.x;
        hlslcc_movcTemp.y = (u_xlatb14.y) ? (-u_xlat2.y) : u_xlat3.y;
        u_xlat2 = hlslcc_movcTemp;
    }
    u_xlat2.xy = u_xlat2.xy + float2(-0.5, -0.5);
    u_xlat2.xy = u_xlat2.xy * float2(0.990099013, 0.990099013) + float2(0.5, 0.5);
    u_xlat12.xy = (bool(u_xlatb13)) ? u_xlat2.xy : u_xlat12.xy;
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat12.xy);
    u_xlatb19 = 0<int(u._enable_motion_blur);
    if(u_xlatb19){
        u_xlat3.xy = float2(float2(u._prev_evolution, u._prev_evolution)) * float2(10.0, 0.5);
        u_xlat3.x = u_xlat3.x;
        u_xlat3.x = clamp(u_xlat3.x, 0.0, 1.0);
        u_xlat19 = u_xlat3.x * u._soft;
        u_xlatb3.x = u_xlat3.y>=(-u_xlat3.y);
        u_xlat9 = fract(abs(u_xlat3.y));
        u_xlat3.x = (u_xlatb3.x) ? u_xlat9 : (-u_xlat9);
        u_xlat1.x = (u_xlatb1.x) ? u_xlat3.x : u._prev_evolution;
        u_xlat3.x = log2(u_xlat1.x);
        u_xlat3.x = u_xlat3.x * 0.200000003;
        u_xlat3.x = exp2(u_xlat3.x);
        u_xlat3.x = u_xlat3.x * 0.5 + 0.5;
        u_xlat3.x = u_xlat3.x * u._amplitude;
        u_xlat9 = u_xlat1.x * u._elastic;
        u_xlat19 = u_xlat0.y * u_xlat19;
        u_xlat19 = u_xlat9 * 6.28310013 + u_xlat19;
        u_xlat19 = sin(u_xlat19);
        u_xlat19 = u_xlat19 * u_xlat3.x;
        u_xlat1.x = u_xlat1.x * -5.77078009;
        u_xlat1.x = exp2(u_xlat1.x);
        u_xlat1.x = u_xlat19 * u_xlat1.x + 1.0;
        u_xlat1.xw = u_xlat1.xx * float2(0.5, -0.5) + float2(0.5, 1.5);
        u_xlat3.yz = u_xlat0.xy * u_xlat1.xw + float2(u._center.x, u._center.y);
        u_xlat3.x = (u_xlatb1.y) ? in.acScreenNorm.x : u_xlat3.y;
        u_xlat3.w = in.acScreenNorm.y;
        u_xlat0.xy = (int(u._direction) != 0) ? u_xlat3.xz : u_xlat3.yw;
        u_xlat1.xy = u_xlat0.xy + float2(-0.5, -0.5);
        u_xlat1.xy = u_xlat1.xy * float2(1.00999999, 1.00999999) + float2(0.5, 0.5);
        u_xlatb3.xy = lessThan(u_xlat1.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlatb15.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat1.xyxy).xy;
        u_xlat4.xy = fract(u_xlat1.xy);
        u_xlat4.xy = (-u_xlat4.xy) + float2(1.0, 1.0);
        u_xlat15.x = (u_xlatb15.x) ? u_xlat4.x : u_xlat1.x;
        u_xlat15.y = (u_xlatb15.y) ? u_xlat4.y : u_xlat1.y;
        {
            float4 hlslcc_movcTemp = u_xlat1;
            hlslcc_movcTemp.x = (u_xlatb3.x) ? (-u_xlat1.x) : u_xlat15.x;
            hlslcc_movcTemp.y = (u_xlatb3.y) ? (-u_xlat1.y) : u_xlat15.y;
            u_xlat1 = hlslcc_movcTemp;
        }
        u_xlat1.xy = u_xlat1.xy + float2(-0.5, -0.5);
        u_xlat1.xy = u_xlat1.xy * float2(0.990099013, 0.990099013) + float2(0.5, 0.5);
        u_xlat0.xy = (bool(u_xlatb13)) ? u_xlat1.xy : u_xlat0.xy;
        u_xlat0.xy = (-u_xlat0.xy) + u_xlat12.xy;
        u_xlati1 = int(u._samples) + int(0xFFFFFFFFu);
        u_xlat1.x = float(u_xlati1);
        u_xlat3 = u_xlat2;
        for(int u_xlati_loop_1 = 0 ; u_xlati_loop_1<int(u._samples) ; u_xlati_loop_1++)
        {
            u_xlat13 = float(u_xlati_loop_1);
            u_xlat13 = u_xlat13 / u_xlat1.x;
            u_xlat4.xy = (-u_xlat0.xy) * float2(u_xlat13);
            u_xlat4.xy = (-u_xlat4.xy) * float2(u._length) + u_xlat12.xy;
            u_xlat4 = inputImg.sample(__nv_smp, u_xlat4.xy);
            u_xlat5.z = u_xlat13 * 3.0 + -1.5;
            u_xlat5.y = -abs(u_xlat5.z) + 1.0;
            u_xlat5.x = (-u_xlat5.z);
            u_xlat5.xyz = u_xlat5.xyz;
            u_xlat5.xyz = clamp(u_xlat5.xyz, 0.0, 1.0);
            u_xlat5.xyz = u_xlat4.xyz * u_xlat5.xyz;
            u_xlat5.xyz = u_xlat5.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat4.xyz);
            u_xlat4.xyz = float3(float3(u._dispersion, u._dispersion, u._dispersion)) * u_xlat5.xyz + u_xlat4.xyz;
            u_xlat3 = u_xlat3 + u_xlat4;
        }
        u_xlat0.x = float(int(u._samples));
        u_xlat2 = u_xlat3 / u_xlat0.xxxx;
    }
    if(int(u._use_inner_mask) != 0) {
        u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat2;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat3 * u_xlat4 + u_xlat0;
        u_xlat1.x = u_xlat4.x * u_xlat0.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat0.w;
        __nv_out.xyz = u_xlat0.xyz;
    } else {
        __nv_out = u_xlat2;
    }
    return __nv_out;
    return __nv_out;
}
