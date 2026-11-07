// ---------------------------------------------------------------------------
// Raytracing Cylinder (NV)
// origem : assets/effects/nv-nodevideo-raytracing-cylinder.xml
// id     : nv.effect.nodevideo-raytracing-cylinder
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_raytracing_cylinderParams {
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
    float _height;
    float _smoothness;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float3 u_xlat7;
float3 u_xlat8;
float4 u_xlat9;
float2 u_xlat10;
float3 u_xlat11;
bool u_xlatb11;
float3 u_xlat12;
int u_xlati12;
float2 u_xlat14;
float2 u_xlat22;
float2 u_xlat23;
bool u_xlatb23;
float2 u_xlat24;
float u_xlat25;
float u_xlat33;
float u_xlat34;
float u_xlat35;
bool u_xlatb35;

fragment float4 fx_nv_nodevideo_raytracing_cylinder(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_raytracing_cylinderParams&  u    [[buffer(1)]],
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
    u_xlat11.x = _resolution.x / _resolution.y;
    u_xlat1.y = u_xlat11.x * u_xlat1.x;
    u_xlat1.xy = u_xlat1.yz / float2(float2(u._zoom, u._zoom));
    u_xlat1.z = 1.0;
    u_xlat11.x = dot(u_xlat1.xyz, u_xlat1.xyz);
    u_xlat11.x = rsqrt(u_xlat11.x);
    u_xlat11.xyz = u_xlat11.xxx * u_xlat1.xyz;
    u_xlat1.x = u._radius + u._radius;
    u_xlat9.zw = u_xlat0.xx;
    u_xlat0.x = 0.0;
    u_xlati12 = 0;
    while(true){
        u_xlatb23 = u_xlati12>=int(u._iteration);
        if(u_xlatb23){break;}
        u_xlat23.xy = u_xlat0.xx * u_xlat11.xy;
        u_xlat2.x = u_xlat11.z * u_xlat0.x + (-u._position.z);
        u_xlat3.xy = u_xlat23.xy + (-u._position.xy);
        u_xlat3.z = u_xlat2.x + -1.0;
        u_xlat2.x = dot(u_xlat3.xyz, u_xlat7.xyz);
        u_xlat23.x = dot(u_xlat3.xyz, u_xlat9.xyz);
        u_xlat2.y = dot(u_xlat3.xyz, u_xlat8.xyz);
        u_xlat34 = dot(u_xlat2.xy, u_xlat2.xy);
        u_xlat34 = sqrt(u_xlat34);
        u_xlat34 = (-u._radius) * 2.0 + u_xlat34;
        u_xlat2.x = u_xlat34 + u._smoothness;
        u_xlat2.y = abs(u_xlat23.x) + (-u._height);
        u_xlat23.x = max(u_xlat2.y, u_xlat2.x);
        u_xlat23.x = min(u_xlat23.x, 0.0);
        u_xlat2.xy = max(u_xlat2.xy, float2(0.0, 0.0));
        u_xlat34 = dot(u_xlat2.xy, u_xlat2.xy);
        u_xlat34 = sqrt(u_xlat34);
        u_xlat23.x = u_xlat34 + u_xlat23.x;
        u_xlat23.x = u_xlat23.x + (-u._smoothness);
        u_xlat23.x = min(u_xlat23.x, 100000000.0);
        u_xlat34 = u_xlat0.x + u_xlat23.x;
        u_xlatb23 = u_xlat23.x<9.99999975e-06;
        u_xlatb2.x = 1000.0<u_xlat34;
        u_xlatb23 = u_xlatb23 || u_xlatb2.x;
        if(u_xlatb23){
            u_xlat0.x = u_xlat34;
            break;
        }
        u_xlati12 = u_xlati12 + 1;
        u_xlat0.x = u_xlat34;
    }
    u_xlat24.xy = u_xlat0.xx * u_xlat11.yx;
    u_xlat2 = u_xlat24.yxxy;
    u_xlat12.xyz = u_xlat11.zxz * u_xlat0.xxx + (-u._position.zxz);
    u_xlat3.xy = u_xlat2.xy + (-u._position.xy);
    u_xlat3.z = u_xlat12.x + -1.0;
    u_xlat4.x = dot(u_xlat3.xyz, u_xlat7.xyz);
    u_xlat11.x = dot(u_xlat3.xyz, u_xlat9.xyw);
    u_xlat4.y = dot(u_xlat3.xyz, u_xlat8.xyz);
    u_xlat3.x = dot(u_xlat4.xy, u_xlat4.xy);
    u_xlat3.x = sqrt(u_xlat3.x);
    u_xlat3.x = (-u._radius) * 2.0 + u_xlat3.x;
    u_xlat3.x = u_xlat3.x + u._smoothness;
    u_xlat3.y = abs(u_xlat11.x) + (-u._height);
    u_xlat25 = max(u_xlat3.y, u_xlat3.x);
    u_xlat25 = min(u_xlat25, 0.0);
    u_xlat3.xy = max(u_xlat3.xy, float2(0.0, 0.0));
    u_xlat3.x = dot(u_xlat3.xy, u_xlat3.xy);
    u_xlat3.x = sqrt(u_xlat3.x);
    u_xlat3.x = u_xlat3.x + u_xlat25;
    u_xlat3.x = u_xlat3.x + (-u._smoothness);
    u_xlat3.x = min(u_xlat3.x, 100000000.0);
    u_xlat5.xz = u_xlat12.yz + float2(-0.00999999978, -1.0);
    u_xlat5.y = u_xlat2.z + (-u._position.y);
    u_xlat6.x = dot(u_xlat5.xyz, u_xlat7.xyz);
    u_xlat23.x = dot(u_xlat5.xyz, u_xlat9.xyw);
    u_xlat6.y = dot(u_xlat5.xyz, u_xlat8.xyz);
    u_xlat34 = dot(u_xlat6.xy, u_xlat6.xy);
    u_xlat34 = sqrt(u_xlat34);
    u_xlat34 = (-u._radius) * 2.0 + u_xlat34;
    u_xlat5.x = u_xlat34 + u._smoothness;
    u_xlat5.y = abs(u_xlat23.x) + (-u._height);
    u_xlat23.x = max(u_xlat5.y, u_xlat5.x);
    u_xlat23.x = min(u_xlat23.x, 0.0);
    u_xlat14.xy = max(u_xlat5.xy, float2(0.0, 0.0));
    u_xlat34 = dot(u_xlat14.xy, u_xlat14.xy);
    u_xlat34 = sqrt(u_xlat34);
    u_xlat23.x = u_xlat34 + u_xlat23.x;
    u_xlat23.x = u_xlat23.x + (-u._smoothness);
    u_xlat5.x = min(u_xlat23.x, 100000000.0);
    u_xlat22.xy = u_xlat11.yz * u_xlat0.xx + (-u._position.yz);
    u_xlat6.x = u_xlat2.w + (-u._position.x);
    u_xlat6.yz = u_xlat22.xy + float2(-0.00999999978, -1.0);
    u_xlat10.x = dot(u_xlat6.xyz, u_xlat7.xyz);
    u_xlat22.x = dot(u_xlat6.xyz, u_xlat9.xyw);
    u_xlat10.y = dot(u_xlat6.xyz, u_xlat8.xyz);
    u_xlat33 = dot(u_xlat10.xy, u_xlat10.xy);
    u_xlat33 = sqrt(u_xlat33);
    u_xlat33 = (-u._radius) * 2.0 + u_xlat33;
    u_xlat6.x = u_xlat33 + u._smoothness;
    u_xlat6.y = abs(u_xlat22.x) + (-u._height);
    u_xlat22.x = max(u_xlat6.y, u_xlat6.x);
    u_xlat22.x = min(u_xlat22.x, 0.0);
    u_xlat23.xy = max(u_xlat6.xy, float2(0.0, 0.0));
    u_xlat33 = dot(u_xlat23.xy, u_xlat23.xy);
    u_xlat33 = sqrt(u_xlat33);
    u_xlat22.x = u_xlat33 + u_xlat22.x;
    u_xlat22.x = u_xlat22.x + (-u._smoothness);
    u_xlat5.y = min(u_xlat22.x, 100000000.0);
    u_xlat2.xy = u_xlat2.xy + (-u._position.xy);
    u_xlat2.z = u_xlat12.x + -1.00999999;
    u_xlat6.x = dot(u_xlat2.xyz, u_xlat7.xyz);
    u_xlat22.x = dot(u_xlat2.xyz, u_xlat9.xyw);
    u_xlat6.y = dot(u_xlat2.xyz, u_xlat8.xyz);
    u_xlat33 = dot(u_xlat6.xy, u_xlat6.xy);
    u_xlat33 = sqrt(u_xlat33);
    u_xlat33 = (-u._radius) * 2.0 + u_xlat33;
    u_xlat2.x = u_xlat33 + u._smoothness;
    u_xlat2.y = abs(u_xlat22.x) + (-u._height);
    u_xlat22.x = max(u_xlat2.y, u_xlat2.x);
    u_xlat22.x = min(u_xlat22.x, 0.0);
    u_xlat12.xy = max(u_xlat2.xy, float2(0.0, 0.0));
    u_xlat33 = dot(u_xlat12.xy, u_xlat12.xy);
    u_xlat33 = sqrt(u_xlat33);
    u_xlat22.x = u_xlat33 + u_xlat22.x;
    u_xlat22.x = u_xlat22.x + (-u._smoothness);
    u_xlat5.z = min(u_xlat22.x, 100000000.0);
    u_xlat12.xyz = u_xlat3.xxx + (-u_xlat5.xyz);
    u_xlat22.x = dot(u_xlat12.xyz, u_xlat12.xyz);
    u_xlat22.x = rsqrt(u_xlat22.x);
    u_xlat2.xyz = u_xlat22.xxx * u_xlat12.xyz;
    u_xlat33 = dot(u_xlat2.xyz, u_xlat9.xyw);
    u_xlat12.x = min(abs(u_xlat4.x), abs(u_xlat4.y));
    u_xlat23.x = max(abs(u_xlat4.x), abs(u_xlat4.y));
    u_xlat23.x = float(1.0) / u_xlat23.x;
    u_xlat12.x = u_xlat23.x * u_xlat12.x;
    u_xlat23.x = u_xlat12.x * u_xlat12.x;
    u_xlat35 = u_xlat23.x * 0.0208350997 + -0.0851330012;
    u_xlat35 = u_xlat23.x * u_xlat35 + 0.180141002;
    u_xlat35 = u_xlat23.x * u_xlat35 + -0.330299497;
    u_xlat23.x = u_xlat23.x * u_xlat35 + 0.999866009;
    u_xlat35 = u_xlat23.x * u_xlat12.x;
    u_xlatb3 = abs(u_xlat4.x)<abs(u_xlat4.y);
    u_xlat35 = u_xlat35 * -2.0 + 1.57079637;
    u_xlat35 = u_xlatb3 ? u_xlat35 : float(0.0);
    u_xlat12.x = u_xlat12.x * u_xlat23.x + u_xlat35;
    u_xlatb23 = u_xlat4.x<(-u_xlat4.x);
    u_xlat23.x = u_xlatb23 ? -3.14159274 : float(0.0);
    u_xlat12.x = u_xlat23.x + u_xlat12.x;
    u_xlat23.x = min(u_xlat4.x, u_xlat4.y);
    u_xlat35 = max(u_xlat4.x, u_xlat4.y);
    u_xlatb23 = u_xlat23.x<(-u_xlat23.x);
    u_xlatb35 = u_xlat35>=(-u_xlat35);
    u_xlatb23 = u_xlatb23 && u_xlatb35;
    u_xlat12.x = (u_xlatb23) ? (-u_xlat12.x) : u_xlat12.x;
    u_xlat23.x = u_xlat12.x * 0.159157097;
    u_xlat11.x = u_xlat11.x / u._height;
    u_xlat3.y = u_xlat11.x * 0.5 + 0.5;
    u_xlat11.x = u_xlat12.x * 0.159157097 + 1.0;
    u_xlatb11 = u_xlat11.x>=(-u_xlat11.x);
    u_xlat12.x = fract(u_xlat23.x);
    u_xlat11.x = (u_xlatb11) ? u_xlat12.x : (-u_xlat12.x);
    u_xlat3.x = (-u_xlat11.x) + 1.0;
    u_xlat1.xy = u_xlat4.xy / u_xlat1.xx;
    u_xlat1.xy = u_xlat1.xy + float2(1.0, 1.0);
    u_xlat4.xy = u_xlat1.xy * float2(0.5, 0.5);
    u_xlatb11 = u_xlat33<0.0;
    u_xlat1.x = (-u_xlat1.y) * 0.5 + 1.0;
    u_xlat4.z = (u_xlatb11) ? u_xlat1.x : u_xlat4.y;
    u_xlat1.xy = (-u_xlat3.xy) + u_xlat4.xz;
    u_xlat11.xz = abs(float2(u_xlat33)) * u_xlat1.xy + u_xlat3.xy;
    u_xlat1.x = u._tex_angle * 0.0174532998;
    u_xlat3.x = cos(u_xlat1.x);
    u_xlat1.x = sin(u_xlat1.x);
    u_xlat4.x = (-u_xlat1.x);
    u_xlat4.y = u_xlat3.x;
    u_xlat4.z = u_xlat1.x;
    u_xlat1.x = dot(u_xlat11.xz, u_xlat4.yz);
    u_xlat1.y = dot(u_xlat11.xz, u_xlat4.xy);
    u_xlat0.yw = u_xlat1.xy + float2(u._tex_offset.x, u._tex_offset.y);
    u_xlat0.xyw = u_xlat0.xyw + float3(-30.0, -0.5, -0.5);
    u_xlat1.x = _resolution.y * _resolution.x;
    u_xlat1.x = 5.0 / u_xlat1.x;
    u_xlat1.x = (-u_xlat1.x) + 1.0;
    u_xlat11.xz = u_xlat0.yw * u_xlat1.xx;
    u_xlat11.xz = u_xlat11.xz * u._tex_scale.xy + float2(0.5, 0.5);
    u_xlatb1.xy = greaterThanEqual(u_xlat11.xzxx, (-u_xlat11.xzxx)).xy;
    u_xlat11.xz = fract(abs(u_xlat11.xz));
    {
        float3 hlslcc_movcTemp = u_xlat11;
        hlslcc_movcTemp.x = (u_xlatb1.x) ? u_xlat11.x : (-u_xlat11.x);
        hlslcc_movcTemp.z = (u_xlatb1.y) ? u_xlat11.z : (-u_xlat11.z);
        u_xlat11 = hlslcc_movcTemp;
    }
    u_xlatb1.xy = lessThan(u_xlat11.xzxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    {
        float3 hlslcc_movcTemp = u_xlat11;
        hlslcc_movcTemp.x = (u_xlatb1.x) ? (-u_xlat11.x) : u_xlat11.x;
        hlslcc_movcTemp.z = (u_xlatb1.y) ? (-u_xlat11.z) : u_xlat11.z;
        u_xlat11 = hlslcc_movcTemp;
    }
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat11.xz);
    u_xlat0.x = u_xlat0.x * -0.0476190485;
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat11.x = u_xlat0.x * -2.0 + 3.0;
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat0.x = u_xlat0.x * u_xlat11.x;
    u_xlat11.x = u_xlat12.z * u_xlat22.x + -0.300000012;
    u_xlat11.x = u_xlat11.x * -9.99999905;
    u_xlat11.x = clamp(u_xlat11.x, 0.0, 1.0);
    u_xlat22.x = u_xlat11.x * -2.0 + 3.0;
    u_xlat11.x = u_xlat11.x * u_xlat11.x;
    u_xlat11.x = u_xlat11.x * u_xlat22.x;
    u_xlat0.x = u_xlat11.x * u_xlat0.x;
    u_xlatb11 = 0<int(u._enable_lighting);
    u_xlat1.xyz = u._light_direction.xyz * float3(0.5, -0.5, -2.0);
    u_xlat22.x = dot(u_xlat1.xyz, u_xlat1.xyz);
    u_xlat22.x = rsqrt(u_xlat22.x);
    u_xlat1.xyz = u_xlat22.xxx * u_xlat1.xyz;
    u_xlat22.x = dot(u_xlat2.xyz, u_xlat1.xyz);
    u_xlat1.xyz = u_xlat3.xyz * u._light_color.xyz;
    u_xlat1.xyz = u_xlat22.xxx * u_xlat1.xyz;
    u_xlat33 = (-u._ambient) + 1.0;
    u_xlat1.xyz = float3(u_xlat33) * u_xlat1.xyz;
    u_xlat1.xyz = u_xlat3.xyz * float3(float3(u._ambient, u._ambient, u._ambient)) + u_xlat1.xyz;
    u_xlat1.xyz = u_xlat1.xyz * float3(float3(u._light_intensity, u._light_intensity, u._light_intensity));
    u_xlat22.x = log2(u_xlat22.x);
    u_xlat22.x = u_xlat22.x * u._specular;
    u_xlat22.x = exp2(u_xlat22.x);
    u_xlat33 = (-u._shine) * 0.100000001 + 1.0;
    u_xlat2.xyz = float3(u_xlat33) * u_xlat1.xyz;
    u_xlat22.x = u_xlat22.x * u._shine;
    u_xlat1.xyz = (-u_xlat1.xyz) * float3(u_xlat33) + float3(1.0, 1.0, 1.0);
    u_xlat1.xyz = u_xlat22.xxx * u_xlat1.xyz + u_xlat2.xyz;
    u_xlat1.w = u_xlat3.w;
    u_xlat1 = u_xlat0.xxxx * u_xlat1;
    u_xlat2 = u_xlat0.xxxx * u_xlat3;
    u_xlat0 = (bool(u_xlatb11)) ? u_xlat1 : u_xlat2;
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
