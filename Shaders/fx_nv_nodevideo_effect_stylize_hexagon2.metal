// ---------------------------------------------------------------------------
// Effect Stylize Hexagon2 (NV)
// origem : assets/effects/nv-nodevideo-effect-stylize-hexagon2.xml
// id     : nv.effect.nodevideo-effect-stylize-hexagon2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_stylize_hexagon2Params {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _edge;
    float _scale;
    float _blend;
    float4 _color;
    float _flat_top;
    float _shine;
    float _type;
    float _multiplier;
    float _invert;
    float _shading;
    float _dissolve;
    float _spread;
    float _width;
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
bool u_xlatb3;
float4 u_xlat4;
bool u_xlatb4;
float4 u_xlat5;
float4 u_xlat6;
float u_xlat7;
float u_xlat8;
float u_xlat10;
bool u_xlatb10;
float u_xlat11;
bool u_xlatb14;
float2 u_xlat15;
bool u_xlatb15;
float2 u_xlat17;
bool u_xlatb18;
float u_xlat21;
float u_xlat22;
bool u_xlatb22;
float u_xlat24;

fragment float4 fx_nv_nodevideo_effect_stylize_hexagon2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_stylize_hexagon2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlatb14 = 0<int(u._flat_top);
    u_xlat1.xy = (bool(u_xlatb14)) ? float2(1.73205078, 1.0) : float2(1.0, 1.73205078);
    u_xlat2 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat21 = u._scale * 10.0;
    u_xlat3.xy = float2(u_xlat21) * u_xlat0.xy;
    u_xlat3.zw = u_xlat0.xy * float2(u_xlat21) + float2(-1.0, -0.5);
    u_xlat4 = u_xlat3 / u_xlat1.xyxy;
    u_xlat4 = floor(u_xlat4);
    u_xlat4 = u_xlat4 + float4(0.5, 0.5, 0.5, 0.5);
    u_xlat5 = u_xlat0.xyxy * float4(u_xlat21) + float4(0.0, 0.0, -0.5, -1.0);
    u_xlat5 = u_xlat5 / u_xlat1.xyxy;
    u_xlat5 = floor(u_xlat5);
    u_xlat5 = u_xlat5 + float4(0.5, 0.5, 0.5, 0.5);
    u_xlat4 = (bool(u_xlatb14)) ? u_xlat4 : u_xlat5;
    u_xlat5.xy = (-u_xlat4.xy) * u_xlat1.xy + u_xlat3.xy;
    u_xlat6 = u_xlat4.zwzw + float4(0.5, 0.5, 0.5, 1.0);
    u_xlat6.xy = (-u_xlat6.xy) * u_xlat1.xy + u_xlat3.xy;
    u_xlat15.x = dot(u_xlat5.xy, u_xlat5.xy);
    u_xlat22 = dot(u_xlat6.xy, u_xlat6.xy);
    u_xlatb15 = u_xlat15.x<u_xlat22;
    u_xlat5.zw = u_xlat4.xy;
    u_xlat3 = (bool(u_xlatb15)) ? u_xlat5 : u_xlat6;
    u_xlat15.x = dot(abs(u_xlat3.xy), float2(0.866025388, 0.5));
    u_xlat15.y = dot(abs(u_xlat3.xy), float2(0.5, 0.866025388));
    u_xlat15.xy = max(abs(u_xlat3.yx), u_xlat15.xy);
    u_xlat15.x = (u_xlatb14) ? u_xlat15.x : u_xlat15.y;
    u_xlat22 = u._edge + 1.0;
    u_xlat15.x = u_xlat15.x * u_xlat22 + -0.5;
    u_xlat15.x = u_xlat15.x * 16.6666679;
    u_xlat15.x = clamp(u_xlat15.x, 0.0, 1.0);
    u_xlat22 = u_xlat15.x * -2.0 + 3.0;
    u_xlat15.x = u_xlat15.x * u_xlat15.x;
    u_xlat15.x = (-u_xlat22) * u_xlat15.x + 1.0;
    u_xlat17.xy = u_xlat1.xy * u_xlat3.zw;
    u_xlat17.xy = u_xlat17.xy / float2(u_xlat21);
    u_xlat22 = min(abs(u_xlat3.y), abs(u_xlat3.x));
    u_xlat4.x = max(abs(u_xlat3.y), abs(u_xlat3.x));
    u_xlat4.x = float(1.0) / u_xlat4.x;
    u_xlat22 = u_xlat22 * u_xlat4.x;
    u_xlat4.x = u_xlat22 * u_xlat22;
    u_xlat11 = u_xlat4.x * 0.0208350997 + -0.0851330012;
    u_xlat11 = u_xlat4.x * u_xlat11 + 0.180141002;
    u_xlat11 = u_xlat4.x * u_xlat11 + -0.330299497;
    u_xlat4.x = u_xlat4.x * u_xlat11 + 0.999866009;
    u_xlat11 = u_xlat22 * u_xlat4.x;
    u_xlatb18 = abs(u_xlat3.y)<abs(u_xlat3.x);
    u_xlat11 = u_xlat11 * -2.0 + 1.57079637;
    u_xlat11 = u_xlatb18 ? u_xlat11 : float(0.0);
    u_xlat22 = u_xlat22 * u_xlat4.x + u_xlat11;
    u_xlatb4 = u_xlat3.y<(-u_xlat3.y);
    u_xlat4.x = u_xlatb4 ? -3.14159274 : float(0.0);
    u_xlat22 = u_xlat22 + u_xlat4.x;
    u_xlat4.x = min(u_xlat3.y, u_xlat3.x);
    u_xlat3.x = max(u_xlat3.y, u_xlat3.x);
    u_xlatb10 = u_xlat4.x<(-u_xlat4.x);
    u_xlatb3 = u_xlat3.x>=(-u_xlat3.x);
    u_xlatb3 = u_xlatb3 && u_xlatb10;
    u_xlat22 = (u_xlatb3) ? (-u_xlat22) : u_xlat22;
    u_xlat22 = u_xlat22 * 0.159154937 + 0.5;
    u_xlatb3 = 0.333299994>=u_xlat22;
    u_xlat10 = (-u._shading) + 1.0;
    u_xlat3.x = (u_xlatb3) ? u_xlat10 : 1.0;
    u_xlatb10 = u_xlat22>=0.666599989;
    u_xlat3.x = (u_xlatb10) ? 1.0 : u_xlat3.x;
    u_xlatb10 = 0.333299994<u_xlat22;
    u_xlatb22 = u_xlat22<0.666599989;
    u_xlatb22 = u_xlatb22 && u_xlatb10;
    u_xlat10 = u._shading + 1.0;
    u_xlat22 = (u_xlatb22) ? u_xlat10 : u_xlat3.x;
    u_xlat3.xy = u_xlat17.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat3.xy = u_xlat3.xy + float2(0.5, 0.5);
    u_xlat3.xyz = inputImg.sample(__nv_smp, u_xlat3.xy).xyz;
    u_xlat3.x = dot(u_xlat3.xyz, float3(0.300000012, 0.589999974, 0.109999999));
    u_xlat10 = u._dissolve + (-u._width);
    u_xlat17.x = (-u_xlat10) + u._dissolve;
    u_xlat3.x = (-u_xlat10) + u_xlat3.x;
    u_xlat10 = float(1.0) / u_xlat17.x;
    u_xlat3.x = u_xlat10 * u_xlat3.x;
    u_xlat3.x = clamp(u_xlat3.x, 0.0, 1.0);
    u_xlat10 = u_xlat3.x * -2.0 + 3.0;
    u_xlat3.x = u_xlat3.x * u_xlat3.x;
    u_xlat17.x = u_xlat3.x * u_xlat10;
    u_xlat24 = (-u_xlat10) * u_xlat3.x + 1.0;
    u_xlat24 = u_xlat24 * u._shine;
    u_xlat3.x = u_xlat10 * u_xlat3.x + -1.0;
    u_xlat3.x = u._spread * u_xlat3.x + 1.0;
    u_xlat21 = u_xlat21 * u_xlat3.x;
    u_xlat4.xy = float2(u_xlat21) * u_xlat0.xy;
    u_xlat4.zw = u_xlat0.xy * float2(u_xlat21) + float2(-1.0, -0.5);
    u_xlat5 = u_xlat4 / u_xlat1.xyxy;
    u_xlat5 = floor(u_xlat5);
    u_xlat5 = u_xlat5 + float4(0.5, 0.5, 0.5, 0.5);
    u_xlat6 = u_xlat0.xyxy * float4(u_xlat21) + float4(0.0, 0.0, -0.5, -1.0);
    u_xlat6 = u_xlat6 / u_xlat1.xyxy;
    u_xlat6 = floor(u_xlat6);
    u_xlat6 = u_xlat6 + float4(0.5, 0.5, 0.5, 0.5);
    u_xlat5 = (bool(u_xlatb14)) ? u_xlat5 : u_xlat6;
    u_xlat0.xy = (-u_xlat5.xy) * u_xlat1.xy + u_xlat4.xy;
    u_xlat6 = u_xlat5.zwzw + float4(0.5, 0.5, 0.5, 1.0);
    u_xlat3.xy = (-u_xlat6.xy) * u_xlat1.xy + u_xlat4.xy;
    u_xlat0.x = dot(u_xlat0.xy, u_xlat0.xy);
    u_xlat7 = dot(u_xlat3.xy, u_xlat3.xy);
    u_xlatb0 = u_xlat0.x<u_xlat7;
    u_xlat0.xy = (bool(u_xlatb0)) ? u_xlat5.xy : u_xlat6.zw;
    u_xlat0.xy = u_xlat1.xy * u_xlat0.xy;
    u_xlat0.xy = u_xlat0.xy / float2(u_xlat21);
    u_xlat0.xy = u_xlat0.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
    u_xlat0.xyz = float3(u_xlat22) * u_xlat0.xyz;
    u_xlatb1.x = 0<int(u._invert);
    u_xlat8 = (-u_xlat15.x) + 1.0;
    u_xlat1.x = (u_xlatb1.x) ? u_xlat8 : u_xlat15.x;
    u_xlat4 = u_xlat0 * u_xlat1.xxxx;
    u_xlat0 = u_xlat0 * float4(float4(u._multiplier, u._multiplier, u._multiplier, u._multiplier));
    u_xlat1.x = (-u_xlat1.x) + 1.0;
    u_xlat0 = u_xlat0 * u_xlat1.xxxx + u_xlat4;
    u_xlat1 = u._color * u_xlat1.xxxx + u_xlat4;
    u_xlat0 = (int(u._type) != 0) ? u_xlat1 : u_xlat0;
    u_xlat1.x = exp2(u_xlat24);
    u_xlat0.xyz = u_xlat0.xyz * u_xlat1.xxx;
    u_xlat0 = u_xlat17.xxxx * u_xlat0;
    u_xlat1.x = (-u_xlat17.x) * u._blend + 1.0;
    u_xlat1 = u_xlat1.xxxx * u_xlat2;
    u_xlat0 = u_xlat0 * float4(float4(u._blend, u._blend, u._blend, u._blend)) + u_xlat1;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat2 = u_xlat2 * u_xlat5;
        u_xlat2 = u_xlat3 * u_xlat4 + u_xlat2;
        u_xlat1.x = u_xlat4.x * u_xlat2.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat2.w;
        __nv_out.xyz = u_xlat2.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
