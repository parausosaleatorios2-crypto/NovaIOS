// ---------------------------------------------------------------------------
// Fill Gradient (NV)
// origem : assets/effects/nv-nodevideo-fill-gradient.xml
// id     : nv.effect.nodevideo-fill-gradient
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_gradientParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _color1;
    float4 _color2;
    float _angle;
    float _offset1;
    float2 _offset2;
    float _scale;
    float _type;
    float _blend_mode;
    float _blend;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool4 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float4 u_xlat6;
float3 u_xlat8;
bool u_xlatb8;
float u_xlat10;
bool u_xlatb10;
float2 u_xlat15;
float u_xlat17;
float u_xlat22;
bool u_xlatb24;

fragment float4 fx_nv_nodevideo_fill_gradient(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_gradientParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = u._angle * 0.0174532998;
    u_xlat8.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat8.xy = u_xlat8.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat2.x = cos(u_xlat1.x);
    u_xlat1.x = sin(u_xlat1.x);
    u_xlat3.x = (-u_xlat2.x);
    u_xlat3.y = u_xlat1.x;
    u_xlat3.z = u_xlat2.x;
    u_xlat2.x = dot(u_xlat8.xy, u_xlat3.yz);
    u_xlat2.y = dot(u_xlat8.xy, u_xlat3.xy);
    u_xlat1.xy = u_xlat2.xy / float2(u._scale);
    u_xlat15.xy = u_xlat1.xy + (-float2(float2(u._offset1, u._offset1)));
    u_xlat1.xy = u_xlat1.xy + float2(u._offset2.y, u._offset2.x);
    u_xlat1.xy = (int(u._type) != 0) ? u_xlat1.xy : u_xlat15.xy;
    u_xlat15.x = u_xlat1.x + 0.5;
    u_xlat22 = dot(u_xlat1.xy, u_xlat1.xy);
    u_xlat22 = sqrt(u_xlat22);
    u_xlat22 = u_xlat22 + u_xlat22;
    u_xlatb2 = equal(int4(int(u._type), int(u._type), int(u._blend_mode), int(u._blend_mode)), int4(1, 2, 1, 2));
    u_xlat3.x = min(abs(u_xlat1.y), abs(u_xlat1.x));
    u_xlat10 = max(abs(u_xlat1.y), abs(u_xlat1.x));
    u_xlat10 = float(1.0) / u_xlat10;
    u_xlat3.x = u_xlat10 * u_xlat3.x;
    u_xlat10 = u_xlat3.x * u_xlat3.x;
    u_xlat17 = u_xlat10 * 0.0208350997 + -0.0851330012;
    u_xlat17 = u_xlat10 * u_xlat17 + 0.180141002;
    u_xlat17 = u_xlat10 * u_xlat17 + -0.330299497;
    u_xlat10 = u_xlat10 * u_xlat17 + 0.999866009;
    u_xlat17 = u_xlat10 * u_xlat3.x;
    u_xlatb24 = abs(u_xlat1.y)<abs(u_xlat1.x);
    u_xlat17 = u_xlat17 * -2.0 + 1.57079637;
    u_xlat17 = u_xlatb24 ? u_xlat17 : float(0.0);
    u_xlat3.x = u_xlat3.x * u_xlat10 + u_xlat17;
    u_xlatb10 = u_xlat1.y<(-u_xlat1.y);
    u_xlat10 = u_xlatb10 ? -3.14159274 : float(0.0);
    u_xlat3.x = u_xlat10 + u_xlat3.x;
    u_xlat10 = min(u_xlat1.y, u_xlat1.x);
    u_xlat1.x = max(u_xlat1.y, u_xlat1.x);
    u_xlatb8 = u_xlat10<(-u_xlat10);
    u_xlatb1 = u_xlat1.x>=(-u_xlat1.x);
    u_xlatb1 = u_xlatb1 && u_xlatb8;
    u_xlat1.x = (u_xlatb1) ? (-u_xlat3.x) : u_xlat3.x;
    u_xlat1.x = u_xlat1.x + 6.28000021;
    u_xlat1.x = u_xlat1.x * 0.159235656;
    u_xlatb8 = u_xlat1.x>=(-u_xlat1.x);
    u_xlat1.x = fract(u_xlat1.x);
    u_xlat1.x = (u_xlatb8) ? u_xlat1.x : (-u_xlat1.x);
    u_xlat1.x = u_xlat1.x * 0.99999994;
    u_xlat1.x = (u_xlatb2.y) ? u_xlat1.x : u_xlat15.x;
    u_xlat1.x = (u_xlatb2.x) ? u_xlat22 : u_xlat1.x;
    u_xlat1.x = (int(u._type) != 0) ? u_xlat1.x : u_xlat15.x;
    u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
    u_xlat8.xyz = u._color1.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat8.xyz = u._color1.xyz * u_xlat8.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat3.xyz = u_xlat8.xyz * u._color1.xyz;
    u_xlat8.xyz = u._color2.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat8.xyz = u._color2.xyz * u_xlat8.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat3.w = u._color1.w;
    u_xlat4.xyz = u._color2.xyz * u_xlat8.xyz + (-u_xlat3.xyz);
    u_xlat4.w = (-u_xlat3.w) + u._color2.w;
    u_xlat1 = u_xlat1.xxxx * u_xlat4 + u_xlat3;
    u_xlat2.xy = in.acScreenNorm.xy * _resolution.xy;
    u_xlat2.x = dot(u_xlat2.xy, float2(0.0671105608, 0.00583714992));
    u_xlat2.x = fract(u_xlat2.x);
    u_xlat2.x = u_xlat2.x * 52.9829178;
    u_xlat2.x = fract(u_xlat2.x);
    u_xlat2.x = u_xlat2.x * 0.00392156886 + -0.00196078443;
    u_xlat1 = u_xlat1 + u_xlat2.xxxx;
    u_xlat3.xyz = u_xlat0.xyz / u_xlat0.www;
    u_xlat4.xyz = u_xlat1.xyz * u_xlat3.xyz;
    u_xlat4.w = 1.0;
    u_xlat4 = u_xlat0.wwww * u_xlat4;
    u_xlat5.xyz = u_xlat0.xyz + u_xlat1.xyz;
    u_xlatb2.x = int(u._blend_mode)==3;
    u_xlat3.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat6.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat3.xyz = (-u_xlat3.xyz) * u_xlat6.xyz + float3(1.0, 1.0, 1.0);
    u_xlat3.w = 1.0;
    u_xlat3 = u_xlat0.wwww * u_xlat3;
    u_xlat6.xyz = u_xlat1.xyz;
    u_xlat6.w = 1.0;
    u_xlat6 = u_xlat0.wwww * u_xlat6;
    u_xlat3 = (u_xlatb2.x) ? u_xlat3 : u_xlat6;
    u_xlat5.w = u_xlat0.w;
    u_xlat3 = (u_xlatb2.w) ? u_xlat5 : u_xlat3;
    u_xlat2 = (u_xlatb2.z) ? u_xlat4 : u_xlat3;
    u_xlat1.x = u_xlat1.w * u._blend;
    u_xlat2 = (-u_xlat0) + u_xlat2;
    u_xlat1 = u_xlat1.xxxx * u_xlat2 + u_xlat0;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat3 * u_xlat4 + u_xlat0;
        u_xlat2.x = u_xlat4.x * u_xlat0.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat0.w;
        __nv_out.xyz = u_xlat0.xyz;
    } else {
        __nv_out = u_xlat1;
    }
    return __nv_out;
    return __nv_out;
}
