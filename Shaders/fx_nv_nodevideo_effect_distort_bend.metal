// ---------------------------------------------------------------------------
// Effect Distort Bend (NV)
// origem : assets/effects/nv-nodevideo-effect-distort-bend.xml
// id     : nv.effect.nodevideo-effect-distort-bend
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_distort_bendParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _pivot;
    float _amount;
    float _offset;
    float _type;
    float2 _tex_offset;
    float2 _tex_scale;
    float _tex_angle;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
bool2 u_xlatb0;
float4 u_xlat1;
int3 u_xlati1;
bool2 u_xlatb1;
float4 u_xlat2;
bool4 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
int u_xlati5;
bool2 u_xlatb5;
float4 u_xlat6;
bool u_xlatb6;
float4 u_xlat7;
float4 u_xlat8;
float2 u_xlat9;
float3 u_xlat10;
int u_xlati10;
float2 u_xlat11;
bool u_xlatb11;
float u_xlat14;
bool u_xlatb14;
float2 u_xlat18;
bool2 u_xlatb18;
float2 u_xlat19;
bool2 u_xlatb19;
float u_xlat20;
float u_xlat23;
bool u_xlatb23;
bool u_xlatb27;
float u_xlat28;
bool u_xlatb28;
float u_xlat29;
int u_xlati29;
float u_xlat30;
bool u_xlatb30;
float u_xlat32;
bool u_xlatb32;
static int op_not(int value) { return -value - 1; }
static int2 op_not(int2 a) { a.x = op_not(a.x); a.y = op_not(a.y); return a; }
static int3 op_not(int3 a) { a.x = op_not(a.x); a.y = op_not(a.y); a.z = op_not(a.z); return a; }
static int4 op_not(int4 a) { a.x = op_not(a.x); a.y = op_not(a.y); a.z = op_not(a.z); a.w = op_not(a.w); return a; }

fragment float4 fx_nv_nodevideo_effect_distort_bend(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_distort_bendParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = u._tex_angle * 0.0174532998;
    u_xlat1.x = cos(u_xlat0.x);
    u_xlat0.x = sin(u_xlat0.x);
    u_xlat2.x = (-u_xlat0.x);
    u_xlat9.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat9.xy = u_xlat9.xy / float2(u._tex_scale.x, u._tex_scale.y);
    u_xlat2.y = u_xlat1.x;
    u_xlat2.z = u_xlat0.x;
    u_xlat10.x = dot(u_xlat9.xy, u_xlat2.yz);
    u_xlat10.y = dot(u_xlat9.xy, u_xlat2.xy);
    u_xlat0.xy = u_xlat10.xy + u._tex_offset.xy;
    u_xlat0.yz = u_xlat0.xy + float2(0.5, 0.5);
    u_xlati1.xyz = int3(uint3(equal(int4(int(u._pivot)), int4(1, 2, 3, 0)).xyz) * 0xFFFFFFFFu);
    u_xlat2.z = as_type<float>(op_not(u_xlati1.x));
    u_xlat3.x = float(0.5);
    u_xlat3.y = float(0.0);
    u_xlat3.w = (-u._amount);
    u_xlat4.x = 0.0;
    u_xlat4.z = u._amount;
    u_xlat3.xyz = (u_xlati1.z != 0) ? u_xlat3.xyw : u_xlat4.xxz;
    u_xlat4.y = float(0.5);
    u_xlat4.z = float(0.0);
    u_xlat4.w = float(0.5);
    u_xlat4.x = u._offset * -0.99000001 + 1.0;
    u_xlat5.x = float(0.5);
    u_xlat5.z = float(0.5);
    u_xlat5.w = float(1.0);
    u_xlat5.y = u._offset * 0.99000001;
    u_xlat6 = (u_xlati1.y != 0) ? u_xlat4.wxwz : u_xlat5;
    u_xlat7.x = float(0.5);
    u_xlat7.y = float(1.0);
    u_xlat7.w = u._amount;
    u_xlat10.xyz = (u_xlati1.y != 0) ? u_xlat7.xyw : u_xlat3.xyz;
    u_xlat3.x = float(1.0);
    u_xlat3.y = float(0.5);
    u_xlat3.w = (-u._amount);
    u_xlat2.xyw = (u_xlati1.x != 0) ? u_xlat3.xyw : u_xlat10.xyz;
    u_xlat1 = (u_xlati1.x != 0) ? u_xlat4 : u_xlat6;
    u_xlat3.yw = (int(u._pivot) != 0) ? u_xlat1.xy : u_xlat5.yz;
    u_xlat1.xy = (int(u._pivot) != 0) ? u_xlat1.zw : float2(1.0, 0.5);
    u_xlat4.x = float(0.0);
    u_xlat4.y = float(0.5);
    u_xlat4.w = u._amount;
    u_xlat2 = (int(u._pivot) != 0) ? u_xlat2.wxyz : u_xlat4.wxyx;
    u_xlat1.xy = (-u_xlat3.yw) + u_xlat1.xy;
    u_xlat19.xy = u_xlat0.yz + (-u_xlat3.yw);
    u_xlat19.x = dot(u_xlat1.xy, u_xlat19.xy);
    u_xlat4 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb19.x = u_xlat19.x<0.0;
    if(u_xlatb19.x){
        u_xlatb19.x = int(u._type)==0;
        u_xlatb28 = 0.0>=u._offset;
        u_xlatb19.x = u_xlatb28 || u_xlatb19.x;
        if(u_xlatb19.x){
            u_xlatb19.xy = lessThan(u_xlat0.yzyz, float4(0.0, 0.0, 0.0, 0.0)).xy;
            u_xlatb5.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.yzyy).xy;
            u_xlatb19.x = u_xlatb19.x || u_xlatb5.x;
            u_xlatb19.x = u_xlatb19.y || u_xlatb19.x;
            u_xlatb19.x = u_xlatb5.y || u_xlatb19.x;
            u_xlat5 = inputImg.sample(__nv_smp, u_xlat0.yz);
            u_xlat19.x = (u_xlatb19.x) ? 0.0 : 1.0;
            u_xlat5 = u_xlat19.xxxx * u_xlat5;
            if(int(u._use_inner_mask) != 0) {
                u_xlatb19.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._b_clip_mask)), int4(1, 1, 1, 1)).xy;
                u_xlat6 = (u_xlatb19.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat5;
                u_xlat7 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
                u_xlat8 = (-u_xlat7) + float4(1.0, 1.0, 1.0, 1.0);
                u_xlat8 = u_xlat4 * u_xlat8;
                u_xlat6 = u_xlat6 * u_xlat7 + u_xlat8;
                u_xlat19.x = u_xlat7.x * u_xlat6.w;
                __nv_out.w = (u_xlatb19.y) ? u_xlat19.x : u_xlat6.w;
                __nv_out.xyz = u_xlat6.xyz;
            } else {
                __nv_out = u_xlat5;
            }
            return __nv_out;
        } else {
            u_xlat1.xy = (-u_xlat3.yw) + u_xlat2.yz;
            u_xlatb19.x = int(u._type)==2;
            u_xlat2.x = (u_xlatb19.x) ? (-u_xlat2.x) : u_xlat2.x;
        }
    }
    u_xlat19.x = u_xlat2.x * 0.00872664619;
    u_xlat1.x = dot(u_xlat1.xy, u_xlat1.xy);
    u_xlat1.x = sqrt(u_xlat1.x);
    u_xlat1.x = u_xlat19.x / u_xlat1.x;
    if(uint(as_type<uint>(u_xlat2.w)) != uint(0)) {
        u_xlat10.xy = _resolution.xy / _resolution.yx;
        u_xlat0.x = u_xlat0.y * u_xlat10.x;
        u_xlat3.z = u_xlat10.x * u_xlat3.y;
        u_xlat10.xz = u_xlat0.xz + (-u_xlat3.zw);
        u_xlatb0.x = abs(u_xlat1.x)<0.00100000005;
        u_xlat2.x = u_xlat10.z;
        u_xlat2.x = clamp(u_xlat2.x, 0.0, 1.0);
        u_xlat2.x = u_xlat10.z + (-u_xlat2.x);
        u_xlat2.y = (u_xlatb0.x) ? u_xlat2.x : u_xlat10.z;
        u_xlat20 = 0.5 / u_xlat1.x;
        u_xlat2.x = u_xlat10.x + (-u_xlat20);
        u_xlati29 = int((0.0<u_xlat1.x) ? 0xFFFFFFFFu : uint(0));
        u_xlati5 = int((u_xlat1.x<0.0) ? 0xFFFFFFFFu : uint(0));
        u_xlati29 = (-u_xlati29) + u_xlati5;
        u_xlat29 = float(u_xlati29);
        u_xlat5.x = dot(u_xlat2.xy, u_xlat2.xy);
        u_xlat5.x = sqrt(u_xlat5.x);
        u_xlat5.x = abs(u_xlat20) + (-u_xlat5.x);
        u_xlat11.x = u_xlat2.y * u_xlat29;
        u_xlat2.x = u_xlat2.x * (-u_xlat29);
        u_xlat14 = min(abs(u_xlat2.x), abs(u_xlat11.x));
        u_xlat23 = max(abs(u_xlat2.x), abs(u_xlat11.x));
        u_xlat23 = float(1.0) / u_xlat23;
        u_xlat14 = u_xlat23 * u_xlat14;
        u_xlat23 = u_xlat14 * u_xlat14;
        u_xlat32 = u_xlat23 * 0.0208350997 + -0.0851330012;
        u_xlat32 = u_xlat23 * u_xlat32 + 0.180141002;
        u_xlat32 = u_xlat23 * u_xlat32 + -0.330299497;
        u_xlat23 = u_xlat23 * u_xlat32 + 0.999866009;
        u_xlat32 = u_xlat23 * u_xlat14;
        u_xlatb6 = abs(u_xlat2.x)<abs(u_xlat11.x);
        u_xlat32 = u_xlat32 * -2.0 + 1.57079637;
        u_xlat32 = u_xlatb6 ? u_xlat32 : float(0.0);
        u_xlat14 = u_xlat14 * u_xlat23 + u_xlat32;
        u_xlatb23 = u_xlat2.x<(-u_xlat2.x);
        u_xlat23 = u_xlatb23 ? -3.14159274 : float(0.0);
        u_xlat14 = u_xlat23 + u_xlat14;
        u_xlat23 = min(u_xlat2.x, u_xlat11.x);
        u_xlat2.x = max(u_xlat2.x, u_xlat11.x);
        u_xlatb11 = u_xlat23<(-u_xlat23);
        u_xlatb2.x = u_xlat2.x>=(-u_xlat2.x);
        u_xlatb2.x = u_xlatb2.x && u_xlatb11;
        u_xlat2.x = (u_xlatb2.x) ? (-u_xlat14) : u_xlat14;
        u_xlat11.y = u_xlat2.x * u_xlat20;
        u_xlat11.x = u_xlat29 * u_xlat5.x;
        u_xlat2.yz = (u_xlatb0.x) ? u_xlat10.xz : u_xlat11.xy;
        u_xlat2.x = u_xlat10.y * u_xlat2.y;
        u_xlat3.x = u_xlat10.y * u_xlat3.z;
        u_xlat10.xy = u_xlat3.xw + u_xlat2.xz;
        u_xlatb2.xy = greaterThanEqual(u_xlat10.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlatb2.zw = greaterThanEqual(float4(0.0, 0.0, 1.0, 1.0), u_xlat10.xxxy).zw;
        u_xlat2.x = u_xlatb2.x ? float(1.0) : 0.0;
        u_xlat2.y = u_xlatb2.y ? float(1.0) : 0.0;
        u_xlat2.z = u_xlatb2.z ? float(1.0) : 0.0;
        u_xlat2.w = u_xlatb2.w ? float(1.0) : 0.0;
;
        u_xlat0.x = u_xlat2.z * u_xlat2.x;
        u_xlat0.x = u_xlat2.y * u_xlat0.x;
        u_xlat0.x = u_xlat2.w * u_xlat0.x;
        u_xlat2 = inputImg.sample(__nv_smp, u_xlat10.xy);
        u_xlat2 = u_xlat0.xxxx * u_xlat2;
    } else {
        u_xlat10.xy = _resolution.yx / _resolution.xy;
        u_xlat0.w = u_xlat0.z * u_xlat10.x;
        u_xlat3.x = u_xlat10.x * u_xlat3.w;
        u_xlat0.xy = u_xlat0.yw + (-u_xlat3.yx);
        u_xlatb27 = abs(u_xlat1.x)<0.00100000005;
        u_xlat10.x = u_xlat0.y;
        u_xlat10.x = clamp(u_xlat10.x, 0.0, 1.0);
        u_xlat10.x = u_xlat0.y + (-u_xlat10.x);
        u_xlat10.x = (u_xlatb27) ? u_xlat10.x : u_xlat0.y;
        u_xlat28 = 0.5 / u_xlat1.x;
        u_xlat0.z = (-u_xlat28) + u_xlat10.x;
        u_xlati10 = int((0.0<u_xlat1.x) ? 0xFFFFFFFFu : uint(0));
        u_xlati1.x = int((u_xlat1.x<0.0) ? 0xFFFFFFFFu : uint(0));
        u_xlati1.x = (-u_xlati10) + u_xlati1.x;
        u_xlat1.x = float(u_xlati1.x);
        u_xlat10.x = dot(u_xlat0.xz, u_xlat0.xz);
        u_xlat10.x = sqrt(u_xlat10.x);
        u_xlat10.x = (-u_xlat10.x) + abs(u_xlat28);
        u_xlat30 = u_xlat0.x * u_xlat1.x;
        u_xlat18.x = u_xlat0.z * (-u_xlat1.x);
        u_xlat5.x = min(abs(u_xlat18.x), abs(u_xlat30));
        u_xlat14 = max(abs(u_xlat18.x), abs(u_xlat30));
        u_xlat14 = float(1.0) / u_xlat14;
        u_xlat5.x = u_xlat14 * u_xlat5.x;
        u_xlat14 = u_xlat5.x * u_xlat5.x;
        u_xlat23 = u_xlat14 * 0.0208350997 + -0.0851330012;
        u_xlat23 = u_xlat14 * u_xlat23 + 0.180141002;
        u_xlat23 = u_xlat14 * u_xlat23 + -0.330299497;
        u_xlat14 = u_xlat14 * u_xlat23 + 0.999866009;
        u_xlat23 = u_xlat14 * u_xlat5.x;
        u_xlatb32 = abs(u_xlat18.x)<abs(u_xlat30);
        u_xlat23 = u_xlat23 * -2.0 + 1.57079637;
        u_xlat23 = u_xlatb32 ? u_xlat23 : float(0.0);
        u_xlat5.x = u_xlat5.x * u_xlat14 + u_xlat23;
        u_xlatb14 = u_xlat18.x<(-u_xlat18.x);
        u_xlat14 = u_xlatb14 ? -3.14159274 : float(0.0);
        u_xlat5.x = u_xlat14 + u_xlat5.x;
        u_xlat14 = min(u_xlat18.x, u_xlat30);
        u_xlat18.x = max(u_xlat18.x, u_xlat30);
        u_xlatb30 = u_xlat14<(-u_xlat14);
        u_xlatb18.x = u_xlat18.x>=(-u_xlat18.x);
        u_xlatb18.x = u_xlatb18.x && u_xlatb30;
        u_xlat18.x = (u_xlatb18.x) ? (-u_xlat5.x) : u_xlat5.x;
        u_xlat5.x = u_xlat18.x * u_xlat28;
        u_xlat5.y = u_xlat1.x * u_xlat10.x;
        u_xlat0.xy = (bool(u_xlatb27)) ? u_xlat0.xy : u_xlat5.xy;
        u_xlat0.z = u_xlat10.y * u_xlat0.y;
        u_xlat3.z = u_xlat10.y * u_xlat3.x;
        u_xlat0.xy = u_xlat0.xz + u_xlat3.yz;
        u_xlatb18.xy = greaterThanEqual(u_xlat0.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlat18.x = u_xlatb18.x ? float(1.0) : 0.0;
        u_xlat18.y = u_xlatb18.y ? float(1.0) : 0.0;
;
        u_xlatb1.xy = greaterThanEqual(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.xyxx).xy;
        u_xlat1.x = u_xlatb1.x ? float(1.0) : 0.0;
        u_xlat1.y = u_xlatb1.y ? float(1.0) : 0.0;
;
        u_xlat18.x = u_xlat18.x * u_xlat1.x;
        u_xlat18.x = u_xlat18.y * u_xlat18.x;
        u_xlat18.x = u_xlat1.y * u_xlat18.x;
        u_xlat1 = inputImg.sample(__nv_smp, u_xlat0.xy);
        u_xlat2 = u_xlat18.xxxx * u_xlat1;
    }
    if(int(u._use_inner_mask) != 0) {
        u_xlatb0.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat1 = (u_xlatb0.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat2;
        u_xlat3 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat3) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat4 = u_xlat4 * u_xlat5;
        u_xlat1 = u_xlat1 * u_xlat3 + u_xlat4;
        u_xlat0.x = u_xlat3.x * u_xlat1.w;
        __nv_out.w = (u_xlatb0.y) ? u_xlat0.x : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat2;
    }
    return __nv_out;
    return __nv_out;
}
