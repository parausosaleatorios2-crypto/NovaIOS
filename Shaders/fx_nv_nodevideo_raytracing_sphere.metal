// ---------------------------------------------------------------------------
// Raytracing Sphere (NV)
// origem : assets/effects/nv-nodevideo-raytracing-sphere.xml
// id     : nv.effect.nodevideo-raytracing-sphere
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_raytracing_sphereParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float3 _position;
    float3 _rotation;
    float _zoom;
    float _iteration;
    float _enable_lighting;
    float3 _light_direction;
    float _ambient;
    float3 _light_color;
    float _light_intensity;
    float _specular;
    float _shine;
    float2 _tex_offset;
    float2 _tex_scale;
    float _tex_angle;
    float _radius;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
int u_xlati1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float3 u_xlat7;
float3 u_xlat8;
float4 u_xlat9;
float3 u_xlat10;
bool u_xlatb10;
float3 u_xlat11;
bool u_xlatb11;
float u_xlat12;
bool u_xlatb12;
bool u_xlatb13;
float2 u_xlat20;
bool u_xlatb20;
float2 u_xlat21;
float u_xlat22;
bool u_xlatb22;
float u_xlat30;
float u_xlat31;
bool u_xlatb31;
float u_xlat32;

fragment float4 fx_nv_nodevideo_raytracing_sphere(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_raytracing_sphereParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = u._rotation.xyz * float3(6.28318787, 6.28318787, 6.28318787);
    u_xlat1.x = cos(u_xlat0.x);
    u_xlat0.x = sin(u_xlat0.x);
    u_xlat2.x = sin(u_xlat0.y);
    u_xlat3.x = cos(u_xlat0.y);
    u_xlat4.x = sin(u_xlat0.z);
    u_xlat5.x = cos(u_xlat0.z);
    u_xlat6.x = (-u_xlat4.x);
    u_xlat3.y = u_xlat0.x * u_xlat2.x;
    u_xlat2.y = (-u_xlat0.x) * u_xlat3.x;
    u_xlat7.z = u_xlat1.x * (-u_xlat2.x);
    u_xlat8.z = u_xlat1.x * u_xlat3.x;
    u_xlat6.y = u_xlat5.x;
    u_xlat7.x = dot(u_xlat6.yx, u_xlat3.xy);
    u_xlat9.x = u_xlat1.x * u_xlat6.x;
    u_xlat8.x = dot(u_xlat6.yx, u_xlat2.xy);
    u_xlat6.z = u_xlat4.x;
    u_xlat7.y = dot(u_xlat6.zy, u_xlat3.xy);
    u_xlat9.y = u_xlat1.x * u_xlat5.x;
    u_xlat8.y = dot(u_xlat6.zy, u_xlat2.xy);
    u_xlat1.xz = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat10.x = _resolution.x / _resolution.y;
    u_xlat1.y = u_xlat10.x * u_xlat1.x;
    u_xlat1.xy = u_xlat1.yz / float2(float2(u._zoom, u._zoom));
    u_xlat1.z = 1.0;
    u_xlat10.x = dot(u_xlat1.xyz, u_xlat1.xyz);
    u_xlat10.x = rsqrt(u_xlat10.x);
    u_xlat10.xyz = u_xlat10.xxx * u_xlat1.xyz;
    u_xlat9.zw = u_xlat0.xx;
    u_xlat0.x = 0.0;
    u_xlati1 = 0;
    while(true){
        u_xlatb11 = u_xlati1>=int(u._iteration);
        if(u_xlatb11){break;}
        u_xlat11.xy = u_xlat0.xx * u_xlat10.xy;
        u_xlat31 = u_xlat10.z * u_xlat0.x + (-u._position.z);
        u_xlat2.xy = u_xlat11.xy + (-u._position.xy);
        u_xlat2.z = u_xlat31 + -1.0;
        u_xlat3.x = dot(u_xlat2.xyz, u_xlat7.xyz);
        u_xlat3.y = dot(u_xlat2.xyz, u_xlat9.xyz);
        u_xlat3.z = dot(u_xlat2.xyz, u_xlat8.xyz);
        u_xlat11.x = dot(u_xlat3.xyz, u_xlat3.xyz);
        u_xlat11.x = sqrt(u_xlat11.x);
        u_xlat11.x = u_xlat11.x + (-u._radius);
        u_xlat11.x = min(u_xlat11.x, 100000000.0);
        u_xlat21.x = u_xlat0.x + u_xlat11.x;
        u_xlatb11 = u_xlat11.x<9.99999975e-06;
        u_xlatb31 = 1000.0<u_xlat21.x;
        u_xlatb11 = u_xlatb31 || u_xlatb11;
        if(u_xlatb11){
            u_xlat0.x = u_xlat21.x;
            break;
        }
        u_xlati1 = u_xlati1 + 1;
        u_xlat0.x = u_xlat21.x;
    }
    u_xlat21.xy = u_xlat0.xx * u_xlat10.yx;
    u_xlat1 = u_xlat21.yxxy;
    u_xlat2.xyz = u_xlat10.zxz * u_xlat0.xxx + (-u._position.zxz);
    u_xlat3.xy = u_xlat1.xy + (-u._position.xy);
    u_xlat3.z = u_xlat2.x + -1.0;
    u_xlat4.x = dot(u_xlat3.xyz, u_xlat7.xyz);
    u_xlat4.y = dot(u_xlat3.xyz, u_xlat9.xyw);
    u_xlat4.z = dot(u_xlat3.xyz, u_xlat8.xyz);
    u_xlat10.x = dot(u_xlat4.xyz, u_xlat4.xyz);
    u_xlat10.x = sqrt(u_xlat10.x);
    u_xlat10.x = u_xlat10.x + (-u._radius);
    u_xlat10.x = min(u_xlat10.x, 100000000.0);
    u_xlat3.xz = u_xlat2.yz + float2(-0.00999999978, -1.0);
    u_xlat3.y = u_xlat1.z + (-u._position.y);
    u_xlat5.x = dot(u_xlat3.xyz, u_xlat7.xyz);
    u_xlat5.y = dot(u_xlat3.xyz, u_xlat9.xyw);
    u_xlat5.z = dot(u_xlat3.xyz, u_xlat8.xyz);
    u_xlat21.x = dot(u_xlat5.xyz, u_xlat5.xyz);
    u_xlat21.x = sqrt(u_xlat21.x);
    u_xlat21.x = u_xlat21.x + (-u._radius);
    u_xlat3.x = min(u_xlat21.x, 100000000.0);
    u_xlat20.xy = u_xlat10.yz * u_xlat0.xx + (-u._position.yz);
    u_xlat5.x = u_xlat1.w + (-u._position.x);
    u_xlat5.yz = u_xlat20.xy + float2(-0.00999999978, -1.0);
    u_xlat6.x = dot(u_xlat5.xyz, u_xlat7.xyz);
    u_xlat6.y = dot(u_xlat5.xyz, u_xlat9.xyw);
    u_xlat6.z = dot(u_xlat5.xyz, u_xlat8.xyz);
    u_xlat20.x = dot(u_xlat6.xyz, u_xlat6.xyz);
    u_xlat20.x = sqrt(u_xlat20.x);
    u_xlat20.x = u_xlat20.x + (-u._radius);
    u_xlat3.y = min(u_xlat20.x, 100000000.0);
    u_xlat1.xy = u_xlat1.xy + (-u._position.xy);
    u_xlat1.z = u_xlat2.x + -1.00999999;
    u_xlat2.x = dot(u_xlat1.xyz, u_xlat7.xyz);
    u_xlat2.y = dot(u_xlat1.xyz, u_xlat9.xyw);
    u_xlat2.z = dot(u_xlat1.xyz, u_xlat8.xyz);
    u_xlat20.x = dot(u_xlat2.xyz, u_xlat2.xyz);
    u_xlat20.x = sqrt(u_xlat20.x);
    u_xlat20.x = u_xlat20.x + (-u._radius);
    u_xlat3.z = min(u_xlat20.x, 100000000.0);
    u_xlat10.xyz = u_xlat10.xxx + (-u_xlat3.xyz);
    u_xlat1.x = dot(u_xlat10.xyz, u_xlat10.xyz);
    u_xlat1.x = rsqrt(u_xlat1.x);
    u_xlat11.xyz = u_xlat10.xyz * u_xlat1.xxx;
    u_xlat10.x = min(abs(u_xlat4.x), abs(u_xlat4.z));
    u_xlat20.x = max(abs(u_xlat4.x), abs(u_xlat4.z));
    u_xlat20.x = float(1.0) / u_xlat20.x;
    u_xlat10.x = u_xlat20.x * u_xlat10.x;
    u_xlat20.x = u_xlat10.x * u_xlat10.x;
    u_xlat2.x = u_xlat20.x * 0.0208350997 + -0.0851330012;
    u_xlat2.x = u_xlat20.x * u_xlat2.x + 0.180141002;
    u_xlat2.x = u_xlat20.x * u_xlat2.x + -0.330299497;
    u_xlat20.x = u_xlat20.x * u_xlat2.x + 0.999866009;
    u_xlat2.x = u_xlat20.x * u_xlat10.x;
    u_xlatb12 = abs(u_xlat4.x)<abs(u_xlat4.z);
    u_xlat2.x = u_xlat2.x * -2.0 + 1.57079637;
    u_xlat2.x = u_xlatb12 ? u_xlat2.x : float(0.0);
    u_xlat10.x = u_xlat10.x * u_xlat20.x + u_xlat2.x;
    u_xlatb2.xy = lessThan(u_xlat4.xyxx, (-u_xlat4.xyxx)).xy;
    u_xlat2.x = u_xlatb2.x ? float(-3.14159274) : 0.0;
    u_xlat2.y = u_xlatb2.y ? float(-3.14159274) : 0.0;
;
    u_xlat10.x = u_xlat10.x + u_xlat2.x;
    u_xlat20.x = min(u_xlat4.x, u_xlat4.z);
    u_xlat2.x = max(u_xlat4.x, u_xlat4.z);
    u_xlatb20 = u_xlat20.x<(-u_xlat20.x);
    u_xlatb2.x = u_xlat2.x>=(-u_xlat2.x);
    u_xlatb20 = u_xlatb20 && u_xlatb2.x;
    u_xlat10.x = (u_xlatb20) ? (-u_xlat10.x) : u_xlat10.x;
    u_xlat20.x = u_xlat10.x * 0.159157097;
    u_xlat2.x = dot(u_xlat4.xz, u_xlat4.xz);
    u_xlat2.x = sqrt(u_xlat2.x);
    u_xlat22 = min(abs(u_xlat4.y), u_xlat2.x);
    u_xlat32 = max(abs(u_xlat4.y), u_xlat2.x);
    u_xlat32 = float(1.0) / u_xlat32;
    u_xlat22 = u_xlat32 * u_xlat22;
    u_xlat32 = u_xlat22 * u_xlat22;
    u_xlat3.x = u_xlat32 * 0.0208350997 + -0.0851330012;
    u_xlat3.x = u_xlat32 * u_xlat3.x + 0.180141002;
    u_xlat3.x = u_xlat32 * u_xlat3.x + -0.330299497;
    u_xlat32 = u_xlat32 * u_xlat3.x + 0.999866009;
    u_xlat3.x = u_xlat32 * u_xlat22;
    u_xlatb13 = abs(u_xlat4.y)<u_xlat2.x;
    u_xlat3.x = u_xlat3.x * -2.0 + 1.57079637;
    u_xlat3.x = u_xlatb13 ? u_xlat3.x : float(0.0);
    u_xlat22 = u_xlat22 * u_xlat32 + u_xlat3.x;
    u_xlat12 = u_xlat2.y + u_xlat22;
    u_xlat22 = min(u_xlat4.y, u_xlat2.x);
    u_xlat2.x = max(u_xlat4.y, u_xlat2.x);
    u_xlatb22 = u_xlat22<(-u_xlat22);
    u_xlatb2.x = u_xlat2.x>=(-u_xlat2.x);
    u_xlatb2.x = u_xlatb2.x && u_xlatb22;
    u_xlat2.x = (u_xlatb2.x) ? (-u_xlat12) : u_xlat12;
    u_xlat2.x = u_xlat2.x * 0.159157097 + 0.5;
    u_xlat2.x = (-u_xlat2.x) + 1.0;
    u_xlat2.y = u_xlat2.x + u_xlat2.x;
    u_xlat10.x = u_xlat10.x * 0.159157097 + 1.0;
    u_xlatb10 = u_xlat10.x>=(-u_xlat10.x);
    u_xlat20.x = fract(u_xlat20.x);
    u_xlat10.x = (u_xlatb10) ? u_xlat20.x : (-u_xlat20.x);
    u_xlat2.x = (-u_xlat10.x) + 1.0;
    u_xlat10.x = u._tex_angle * 0.0174532998;
    u_xlat3.x = sin(u_xlat10.x);
    u_xlat4.x = cos(u_xlat10.x);
    u_xlat5.x = (-u_xlat3.x);
    u_xlat5.y = u_xlat4.x;
    u_xlat5.z = u_xlat3.x;
    u_xlat3.x = dot(u_xlat2.xy, u_xlat5.yz);
    u_xlat3.y = dot(u_xlat2.xy, u_xlat5.xy);
    u_xlat0.yz = u_xlat3.xy + float2(u._tex_offset.x, u._tex_offset.y);
    u_xlat0.xyz = u_xlat0.xyz + float3(-30.0, -0.5, -0.5);
    u_xlat2.x = _resolution.y * _resolution.x;
    u_xlat2.x = 5.0 / u_xlat2.x;
    u_xlat2.x = (-u_xlat2.x) + 1.0;
    u_xlat10.xy = u_xlat0.yz * u_xlat2.xx;
    u_xlat10.xy = u_xlat10.xy * u._tex_scale.xy + float2(0.5, 0.5);
    u_xlatb2.xy = greaterThanEqual(u_xlat10.xyxx, (-u_xlat10.xyxx)).xy;
    u_xlat10.xy = fract(abs(u_xlat10.xy));
    {
        float3 hlslcc_movcTemp = u_xlat10;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? u_xlat10.x : (-u_xlat10.x);
        hlslcc_movcTemp.y = (u_xlatb2.y) ? u_xlat10.y : (-u_xlat10.y);
        u_xlat10 = hlslcc_movcTemp;
    }
    u_xlatb2.xy = lessThan(u_xlat10.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    {
        float3 hlslcc_movcTemp = u_xlat10;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? (-u_xlat10.x) : u_xlat10.x;
        hlslcc_movcTemp.y = (u_xlatb2.y) ? (-u_xlat10.y) : u_xlat10.y;
        u_xlat10 = hlslcc_movcTemp;
    }
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat10.xy);
    u_xlat0.x = u_xlat0.x * -0.0476190485;
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat10.x = u_xlat0.x * -2.0 + 3.0;
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat0.x = u_xlat0.x * u_xlat10.x;
    u_xlat10.x = u_xlat10.z * u_xlat1.x + -0.300000012;
    u_xlat10.x = u_xlat10.x * -9.99999905;
    u_xlat10.x = clamp(u_xlat10.x, 0.0, 1.0);
    u_xlat20.x = u_xlat10.x * -2.0 + 3.0;
    u_xlat10.x = u_xlat10.x * u_xlat10.x;
    u_xlat10.x = u_xlat10.x * u_xlat20.x;
    u_xlat0.x = u_xlat10.x * u_xlat0.x;
    u_xlatb10 = 0<int(u._enable_lighting);
    u_xlat3.xyz = u._light_direction.xyz * float3(0.5, -0.5, -2.0);
    u_xlat20.x = dot(u_xlat3.xyz, u_xlat3.xyz);
    u_xlat20.x = rsqrt(u_xlat20.x);
    u_xlat3.xyz = u_xlat20.xxx * u_xlat3.xyz;
    u_xlat20.x = dot(u_xlat11.xyz, u_xlat3.xyz);
    u_xlat1.xyz = u_xlat2.xyz * u._light_color.xyz;
    u_xlat1.xyz = u_xlat20.xxx * u_xlat1.xyz;
    u_xlat30 = (-u._ambient) + 1.0;
    u_xlat1.xyz = float3(u_xlat30) * u_xlat1.xyz;
    u_xlat1.xyz = u_xlat2.xyz * float3(float3(u._ambient, u._ambient, u._ambient)) + u_xlat1.xyz;
    u_xlat1.xyz = u_xlat1.xyz * float3(float3(u._light_intensity, u._light_intensity, u._light_intensity));
    u_xlat20.x = log2(u_xlat20.x);
    u_xlat20.x = u_xlat20.x * u._specular;
    u_xlat20.x = exp2(u_xlat20.x);
    u_xlat30 = (-u._shine) * 0.100000001 + 1.0;
    u_xlat3.xyz = float3(u_xlat30) * u_xlat1.xyz;
    u_xlat20.x = u_xlat20.x * u._shine;
    u_xlat1.xyz = (-u_xlat1.xyz) * float3(u_xlat30) + float3(1.0, 1.0, 1.0);
    u_xlat1.xyz = u_xlat20.xxx * u_xlat1.xyz + u_xlat3.xyz;
    u_xlat1.w = u_xlat2.w;
    u_xlat1 = u_xlat0.xxxx * u_xlat1;
    u_xlat2 = u_xlat0.xxxx * u_xlat2;
    u_xlat0 = (bool(u_xlatb10)) ? u_xlat1 : u_xlat2;
    if(int(u._use_inner_mask) != 0) {
        u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat2.x = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
