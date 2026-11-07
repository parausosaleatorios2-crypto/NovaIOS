// ---------------------------------------------------------------------------
// Camera Skybox (NV)
// origem : assets/effects/nv-nodevideo-camera-skybox.xml
// id     : nv.effect.nodevideo-camera-skybox
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_camera_skyboxParams {
    float _type;
    float4 _color1;
    float4 _color2;
    float4 _color;
    float _power;
    float3 _amount;
    float3 _view_dir;
    float2 _sun_pos;
    float _sun_size;
    float _sun_shaft;
    float _iris;
    float _distance;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float2 u_xlat1;
float4 u_xlat2;
float4 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float3 u_xlat7;
float3 u_xlat8;
float u_xlat12;
float u_xlat13;
float u_xlat14;
bool u_xlatb14;
float2 u_xlat15;
float u_xlat18;
float u_xlat19;
float u_xlat20;
bool u_xlatb20;
float u_xlat21;

fragment float4 fx_nv_nodevideo_camera_skybox(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_camera_skyboxParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if(u._type == 0) {
        u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
        u_xlat0.xy = u_xlat0.xy + u_xlat0.xy;
        u_xlat6.xyz = u_xlat0.yyy * hlslcc_mtx4x4_view_mat[1].xyz;
        u_xlat0.xyz = hlslcc_mtx4x4_view_mat[0].xyz * u_xlat0.xxx + u_xlat6.xyz;
        u_xlat0.xyz = u_xlat0.xyz + hlslcc_mtx4x4_view_mat[2].xyz;
        u_xlat0.xyz = u_xlat0.xyz * u._amount.xyz;
        u_xlat0.xyz = u_xlat0.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
        u_xlat0.x = dot(u_xlat0.xyz, u._amount.xyz);
        u_xlat0.x = u_xlat0.x * 0.5 + 0.5;
        u_xlat0.x = log2(u_xlat0.x);
        u_xlat0.x = u_xlat0.x * u._power;
        u_xlat0.x = exp2(u_xlat0.x);
        u_xlat6.xyz = (-u._color1.xyz) + u._color2.xyz;
        __nv_out.xyz = u_xlat0.xxx * u_xlat6.xyz + u._color1.xyz;
        __nv_out.w = 1.0;
        return __nv_out;
    } else {
        u_xlat0.xz = in.acScreenNorm.xy + float2(-0.5, -0.5);
        u_xlat18 = _resolution.x / _resolution.y;
        u_xlat0.y = u_xlat18 * u_xlat0.x;
        u_xlat1.x = (-u._view_dir.y) * u._distance;
        u_xlat1.y = u._view_dir.x * u._distance;
        u_xlat0.xw = u_xlat1.xy + u._sun_pos.xy;
        u_xlat1.xy = (-u_xlat0.xw) + u_xlat0.yz;
        u_xlat13 = dot(u_xlat0.yz, u_xlat0.yz);
        u_xlat13 = sqrt(u_xlat13);
        u_xlat2.xy = u_xlat0.yz * float2(u_xlat13);
        u_xlat19 = min(abs(u_xlat1.y), abs(u_xlat1.x));
        u_xlat14 = max(abs(u_xlat1.y), abs(u_xlat1.x));
        u_xlat14 = float(1.0) / u_xlat14;
        u_xlat19 = u_xlat19 * u_xlat14;
        u_xlat14 = u_xlat19 * u_xlat19;
        u_xlat20 = u_xlat14 * 0.0208350997 + -0.0851330012;
        u_xlat20 = u_xlat14 * u_xlat20 + 0.180141002;
        u_xlat20 = u_xlat14 * u_xlat20 + -0.330299497;
        u_xlat14 = u_xlat14 * u_xlat20 + 0.999866009;
        u_xlat20 = u_xlat19 * u_xlat14;
        u_xlatb3 = abs(u_xlat1.y)<abs(u_xlat1.x);
        u_xlat20 = u_xlat20 * -2.0 + 1.57079637;
        u_xlat20 = u_xlatb3 ? u_xlat20 : float(0.0);
        u_xlat19 = u_xlat19 * u_xlat14 + u_xlat20;
        u_xlatb14 = u_xlat1.y<(-u_xlat1.y);
        u_xlat14 = u_xlatb14 ? -3.14159274 : float(0.0);
        u_xlat19 = u_xlat19 + u_xlat14;
        u_xlat14 = min(u_xlat1.y, u_xlat1.x);
        u_xlat20 = max(u_xlat1.y, u_xlat1.x);
        u_xlatb14 = u_xlat14<(-u_xlat14);
        u_xlatb20 = u_xlat20>=(-u_xlat20);
        u_xlatb14 = u_xlatb20 && u_xlatb14;
        u_xlat19 = (u_xlatb14) ? (-u_xlat19) : u_xlat19;
        u_xlat1.x = dot(u_xlat1.xy, u_xlat1.xy);
        u_xlat1.x = sqrt(u_xlat1.x);
        u_xlat7.x = log2(u_xlat1.x);
        u_xlat7.x = u_xlat7.x * 0.699999988;
        u_xlat7.x = exp2(u_xlat7.x);
        u_xlat1.x = u_xlat1.x * 16.0 + 1.0;
        u_xlat1.x = u._sun_size / u_xlat1.x;
        u_xlat14 = u_xlat19 * 2.0 + u_xlat0.x;
        u_xlat14 = sin(u_xlat14);
        u_xlat19 = u_xlat19 * 3.0 + u_xlat0.w;
        u_xlat19 = cos(u_xlat19);
        u_xlat19 = u_xlat14 * 4.0 + (-u_xlat19);
        u_xlat3.x = u_xlat19 / _resolution.x;
        u_xlat3.y = 0.0;
        u_xlat19 = inputImg.sample(__nv_smp, u_xlat3.xy).x;
        u_xlat7.z = u_xlat19 * u._sun_shaft;
        u_xlat7.xz = u_xlat7.xz * float2(0.100000001, 16.0);
        u_xlat19 = sin(u_xlat7.z);
        u_xlat7.x = u_xlat19 * 0.100000001 + u_xlat7.x;
        u_xlat7.x = u_xlat7.x + 0.800000012;
        u_xlat1.x = u_xlat1.x * u_xlat7.x + u_xlat1.x;
        u_xlat2 = u_xlat0.xwxw * float4(0.800000012, 0.800000012, 0.850000024, 0.850000024) + u_xlat2.xyxy;
        u_xlat7.x = dot(u_xlat2.xy, u_xlat2.xy);
        u_xlat7.x = u_xlat7.x * 32.0 + 1.0;
        u_xlat7.x = float(1.0) / u_xlat7.x;
        u_xlat19 = dot(u_xlat2.zw, u_xlat2.zw);
        u_xlat19 = u_xlat19 * 32.0 + 1.0;
        u_xlat19 = float(1.0) / u_xlat19;
        u_xlat2.xy = u_xlat0.xw * float2(0.899999976, 0.899999976);
        u_xlat2.xy = u_xlat0.yz * float2(u_xlat13) + u_xlat2.xy;
        u_xlat2.x = dot(u_xlat2.xy, u_xlat2.xy);
        u_xlat2.x = u_xlat2.x * 32.0 + 1.0;
        u_xlat2.x = float(1.0) / u_xlat2.x;
        u_xlat3 = u_xlat0.yzyz * float4(u_xlat13) + (-u_xlat0.yzyz);
        u_xlat3 = u_xlat3 * float4(-0.5, -0.5, -0.400000006, -0.400000006) + u_xlat0.yzyz;
        u_xlat4 = u_xlat0.xwxw * float4(0.400000006, 0.400000006, 0.400000006, 0.400000006) + u_xlat3;
        u_xlat6.x = dot(u_xlat4.xy, u_xlat4.xy);
        u_xlat6.x = sqrt(u_xlat6.x);
        u_xlat6.x = log2(u_xlat6.x);
        u_xlat6.x = u_xlat6.x * 2.4000001;
        u_xlat6.x = exp2(u_xlat6.x);
        u_xlat6.x = (-u_xlat6.x) + 0.00999999978;
        u_xlat6.x = max(u_xlat6.x, 0.0);
        u_xlat5 = u_xlat0.xwxw * float4(0.449999988, 0.449999988, 0.5, 0.5) + u_xlat3.xyxy;
        u_xlat12 = dot(u_xlat5.xy, u_xlat5.xy);
        u_xlat12 = sqrt(u_xlat12);
        u_xlat6.y = log2(u_xlat12);
        u_xlat6.xy = u_xlat6.xy * float2(6.0, 2.4000001);
        u_xlat12 = exp2(u_xlat6.y);
        u_xlat12 = (-u_xlat12) + 0.00999999978;
        u_xlat0.z = max(u_xlat12, 0.0);
        u_xlat13 = dot(u_xlat5.zw, u_xlat5.zw);
        u_xlat13 = sqrt(u_xlat13);
        u_xlat13 = log2(u_xlat13);
        u_xlat13 = u_xlat13 * 2.4000001;
        u_xlat13 = exp2(u_xlat13);
        u_xlat13 = (-u_xlat13) + 0.00999999978;
        u_xlat13 = max(u_xlat13, 0.0);
        u_xlat13 = u_xlat13 * 3.0;
        u_xlat5 = u_xlat0.xwxw * float4(0.200000003, 0.200000003, 0.600000024, 0.600000024) + u_xlat3.zwzw;
        u_xlat8.x = dot(u_xlat5.xy, u_xlat5.xy);
        u_xlat8.x = sqrt(u_xlat8.x);
        u_xlat8.x = log2(u_xlat8.x);
        u_xlat8.x = u_xlat8.x * 5.5;
        u_xlat8.x = exp2(u_xlat8.x);
        u_xlat8.x = (-u_xlat8.x) + 0.00999999978;
        u_xlat14 = dot(u_xlat4.zw, u_xlat4.zw);
        u_xlat14 = sqrt(u_xlat14);
        u_xlat14 = log2(u_xlat14);
        u_xlat14 = u_xlat14 * 5.5;
        u_xlat14 = exp2(u_xlat14);
        u_xlat8.y = (-u_xlat14) + 0.00999999978;
        u_xlat20 = dot(u_xlat5.zw, u_xlat5.zw);
        u_xlat20 = sqrt(u_xlat20);
        u_xlat20 = log2(u_xlat20);
        u_xlat20 = u_xlat20 * 5.5;
        u_xlat20 = exp2(u_xlat20);
        u_xlat8.z = (-u_xlat20) + 0.00999999978;
        u_xlat8.xyz = max(u_xlat8.xyz, float3(0.0, 0.0, 0.0));
        u_xlat4 = (-u_xlat0.xwxw) * float4(0.300000012, 0.300000012, 0.324999988, 0.324999988) + u_xlat3.xyxy;
        u_xlat15.x = dot(u_xlat4.xy, u_xlat4.xy);
        u_xlat15.x = sqrt(u_xlat15.x);
        u_xlat15.x = log2(u_xlat15.x);
        u_xlat15.x = u_xlat15.x * 1.60000002;
        u_xlat15.x = exp2(u_xlat15.x);
        u_xlat15.x = (-u_xlat15.x) + 0.00999999978;
        u_xlat21 = dot(u_xlat4.zw, u_xlat4.zw);
        u_xlat21 = sqrt(u_xlat21);
        u_xlat21 = log2(u_xlat21);
        u_xlat21 = u_xlat21 * 1.60000002;
        u_xlat21 = exp2(u_xlat21);
        u_xlat15.y = (-u_xlat21) + 0.00999999978;
        u_xlat15.xy = max(u_xlat15.xy, float2(0.0, 0.0));
        u_xlat0.xw = (-u_xlat0.xw) * float2(0.349999994, 0.349999994) + u_xlat3.xy;
        u_xlat0.x = dot(u_xlat0.xw, u_xlat0.xw);
        u_xlat0.x = sqrt(u_xlat0.x);
        u_xlat0.x = log2(u_xlat0.x);
        u_xlat0.xz = u_xlat0.xz * float2(1.60000002, 5.0);
        u_xlat0.x = exp2(u_xlat0.x);
        u_xlat0.x = (-u_xlat0.x) + 0.00999999978;
        u_xlat0.x = max(u_xlat0.x, 0.0);
        u_xlat6.x = u_xlat7.x * 0.25 + u_xlat6.x;
        u_xlat6.x = u_xlat8.x * 2.0 + u_xlat6.x;
        u_xlat3.x = u_xlat15.x * 6.0 + u_xlat6.x;
        u_xlat6.x = u_xlat19 * 0.230000004 + u_xlat0.z;
        u_xlat6.x = u_xlat8.y * 2.0 + u_xlat6.x;
        u_xlat3.y = u_xlat15.y * 3.0 + u_xlat6.x;
        u_xlat6.x = u_xlat2.x * 0.209999993 + u_xlat13;
        u_xlat6.x = u_xlat8.z * 2.0 + u_xlat6.x;
        u_xlat3.z = u_xlat0.x * 5.0 + u_xlat6.x;
        u_xlat0.xyz = u_xlat3.xyz * float3(u._iris);
        u_xlat0.xyz = u_xlat0.xyz * float3(1.29999995, 1.29999995, 1.29999995) + u_xlat1.xxx;
        u_xlat0.xyz = u_xlat0.xyz * u_xlat0.xyz;
        u_xlat0.w = 1.0;
        __nv_out = u_xlat0 * u._color;
        return __nv_out;
    }
    return __nv_out;
    return __nv_out;
}
