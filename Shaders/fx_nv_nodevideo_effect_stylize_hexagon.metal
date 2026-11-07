// ---------------------------------------------------------------------------
// Effect Stylize Hexagon (NV)
// origem : assets/effects/nv-nodevideo-effect-stylize-hexagon.xml
// id     : nv.effect.nodevideo-effect-stylize-hexagon
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_stylize_hexagonParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _edge;
    float _scale;
    float _blend;
    float4 _edge_color;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
bool2 u_xlatb4;
float4 u_xlat5;
float3 u_xlat6;
float2 u_xlat8;
bool2 u_xlatb8;
float2 u_xlat15;
bool u_xlatb15;
float u_xlat22;
bool u_xlatb22;
float u_xlat23;
bool u_xlatb23;

fragment float4 fx_nv_nodevideo_effect_stylize_hexagon(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_stylize_hexagonParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = _resolution.x * u._scale;
    u_xlat8.xy = in.acScreenNorm.xy * _resolution.xy;
    u_xlat2.xyz = u_xlat1.xxx * float3(0.00625000009, 0.0108253174, 0.0187500007);
    u_xlat22 = u_xlat2.x / u_xlat2.y;
    u_xlat3.xyz = u_xlat1.xxx * float3(0.0216506347, 0.0187500007, 0.0216506347);
    u_xlat4.xyz = u_xlat8.yxy / u_xlat3.yxy;
    u_xlatb8.xy = greaterThanEqual(u_xlat4.yzyy, (-u_xlat4.yzyy)).xy;
    u_xlat3.xw = fract(abs(u_xlat4.yz));
    u_xlat8.x = (u_xlatb8.x) ? u_xlat3.x : (-u_xlat3.x);
    u_xlat8.y = (u_xlatb8.y) ? u_xlat3.w : (-u_xlat3.w);
    u_xlat8.xy = u_xlat3.zy * u_xlat8.xy;
    u_xlat3.xyz = floor(u_xlat4.xyz);
    u_xlat23 = u_xlat3.x * 0.5;
    u_xlatb3 = u_xlat23>=(-u_xlat23);
    u_xlat23 = fract(abs(u_xlat23));
    u_xlat23 = (u_xlatb3) ? u_xlat23 : (-u_xlat23);
    u_xlatb23 = 0.0<u_xlat23;
    u_xlat3.x = u_xlat22 * u_xlat8.x;
    u_xlat4.xy = u_xlat1.xx * float2(0.00625000009, 0.0125000002) + (-u_xlat3.xx);
    u_xlatb4.xy = lessThan(u_xlat8.yyyy, u_xlat4.xyxx).xy;
    u_xlat5 = u_xlat3.yzyz + float4(-1.0, -1.0, -1.0, 0.0);
    u_xlat22 = u_xlat8.x * u_xlat22 + (-u_xlat2.x);
    u_xlatb22 = u_xlat8.y<u_xlat22;
    u_xlat3.w = (u_xlatb22) ? u_xlat5.y : u_xlat3.z;
    u_xlat4.xz = (u_xlatb4.x) ? u_xlat5.xy : u_xlat3.yw;
    u_xlatb8.x = u_xlat2.y<u_xlat8.x;
    u_xlat6.z = (u_xlatb4.y) ? u_xlat5.y : u_xlat3.z;
    u_xlatb15 = u_xlat8.y<u_xlat3.x;
    u_xlat6.xy = u_xlat3.yz + float2(0.0, -1.0);
    u_xlat15.xy = (bool(u_xlatb15)) ? u_xlat6.xy : u_xlat5.zw;
    u_xlat8.xy = (u_xlatb8.x) ? u_xlat6.xz : u_xlat15.xy;
    u_xlat8.xy = (bool(u_xlatb23)) ? u_xlat4.xz : u_xlat8.xy;
    u_xlat22 = u_xlat8.y * 0.5;
    u_xlatb2.x = u_xlat22>=(-u_xlat22);
    u_xlat22 = fract(abs(u_xlat22));
    u_xlat22 = (u_xlatb2.x) ? u_xlat22 : (-u_xlat22);
    u_xlat22 = dot(float2(u_xlat22), u_xlat2.yy);
    u_xlat8.x = dot(u_xlat8.xx, u_xlat2.yy);
    u_xlat2.x = (-u_xlat22) + u_xlat8.x;
    u_xlat2.y = u_xlat2.z * u_xlat8.y;
    u_xlat8.xy = u_xlat1.xx * float2(0.0216506347, 0.0125000002) + u_xlat2.xy;
    u_xlat2.xy = u_xlat8.xy / _resolution.xy;
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat2.xy);
    u_xlat8.xy = (-in.acScreenNorm.xy) * _resolution.xy + u_xlat8.xy;
    u_xlat15.x = dot(abs(u_xlat8.xy), float2(0.5, 0.866025388));
    u_xlat8.x = max(abs(u_xlat8.x), u_xlat15.x);
    u_xlat8.x = u_xlat8.x * u._edge;
    u_xlat15.x = u_xlat1.x * 0.0125000002 + -1.0;
    u_xlat1.x = u_xlat1.x * 0.0125000002 + (-u_xlat15.x);
    u_xlat8.x = u_xlat8.x * 1.15470052 + (-u_xlat15.x);
    u_xlat1.x = float(1.0) / u_xlat1.x;
    u_xlat1.x = u_xlat1.x * u_xlat8.x;
    u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
    u_xlat8.x = u_xlat1.x * -2.0 + 3.0;
    u_xlat1.x = u_xlat1.x * u_xlat1.x;
    u_xlat1.x = (-u_xlat8.x) * u_xlat1.x + 1.0;
    u_xlat8.x = (-u_xlat1.x) + 1.0;
    u_xlat3 = u_xlat8.xxxx * u._edge_color;
    u_xlat3 = u_xlat0.wwww * u_xlat3;
    u_xlat1 = u_xlat2 * u_xlat1.xxxx + u_xlat3;
    u_xlat2.x = (-u._blend) + 1.0;
    u_xlat1 = u_xlat1 * float4(float4(u._blend, u._blend, u._blend, u._blend));
    u_xlat1 = u_xlat0 * u_xlat2.xxxx + u_xlat1;
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
