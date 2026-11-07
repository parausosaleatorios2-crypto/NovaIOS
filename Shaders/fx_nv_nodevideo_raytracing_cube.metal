// ---------------------------------------------------------------------------
// Raytracing Cube (NV)
// origem : assets/effects/nv-nodevideo-raytracing-cube.xml
// id     : nv.effect.nodevideo-raytracing-cube
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_raytracing_cubeParams {
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
    float3 _size;
    float _smoothness;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
bool2 u_xlatb4;
float4 u_xlat5;
bool3 u_xlatb5;
float4 u_xlat6;
float3 u_xlat7;
float3 u_xlat8;
float4 u_xlat9;
float3 u_xlat10;
float3 u_xlat11;
bool2 u_xlatb11;
float3 u_xlat12;
float u_xlat13;
float3 u_xlat14;
float3 u_xlat16;
float2 u_xlat22;
bool u_xlatb22;
float2 u_xlat24;
int2 u_xlati24;
bool u_xlatb24;
float u_xlat33;
float u_xlat34;
int u_xlati34;
float u_xlat35;
bool u_xlatb36;

fragment float4 fx_nv_nodevideo_raytracing_cube(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_raytracing_cubeParams&  u    [[buffer(1)]],
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
    u_xlat1.xyz = (-float3(float3(u._smoothness, u._smoothness, u._smoothness))) + u._size.xyz;
    u_xlat9.zw = u_xlat0.xx;
    u_xlat0.x = 0.0;
    u_xlati34 = 0;
    while(true){
        u_xlatb2.x = u_xlati34>=int(u._iteration);
        if(u_xlatb2.x){break;}
        u_xlat2.xy = u_xlat0.xx * u_xlat11.xy;
        u_xlat24.x = u_xlat11.z * u_xlat0.x + (-u._position.z);
        u_xlat3.xy = u_xlat2.xy + (-u._position.xy);
        u_xlat3.z = u_xlat24.x + -1.0;
        u_xlat2.x = dot(u_xlat3.xyz, u_xlat7.xyz);
        u_xlat2.y = dot(u_xlat3.xyz, u_xlat9.xyz);
        u_xlat2.z = dot(u_xlat3.xyz, u_xlat8.xyz);
        u_xlat2.xyz = (-u_xlat1.xyz) + abs(u_xlat2.xyz);
        u_xlat3.xyz = max(u_xlat2.xyz, float3(0.0, 0.0, 0.0));
        u_xlat35 = dot(u_xlat3.xyz, u_xlat3.xyz);
        u_xlat35 = sqrt(u_xlat35);
        u_xlat13 = max(u_xlat2.z, u_xlat2.y);
        u_xlat2.x = max(u_xlat13, u_xlat2.x);
        u_xlat2.x = min(u_xlat2.x, 0.0);
        u_xlat2.x = u_xlat2.x + u_xlat35;
        u_xlat2.x = u_xlat2.x + (-u._smoothness);
        u_xlat2.x = min(u_xlat2.x, 100000000.0);
        u_xlat13 = u_xlat0.x + u_xlat2.x;
        u_xlatb2.x = u_xlat2.x<9.99999975e-06;
        u_xlatb24 = 1000.0<u_xlat13;
        u_xlatb2.x = u_xlatb24 || u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlat0.x = u_xlat13;
            break;
        }
        u_xlati34 = u_xlati34 + 1;
        u_xlat0.x = u_xlat13;
    }
    u_xlat24.xy = u_xlat0.xx * u_xlat11.yx;
    u_xlat2 = u_xlat24.yxxy;
    u_xlat3.xyz = u_xlat11.zxz * u_xlat0.xxx + (-u._position.zxz);
    u_xlat4.xy = u_xlat2.xy + (-u._position.xy);
    u_xlat4.z = u_xlat3.x + -1.0;
    u_xlat5.x = dot(u_xlat4.xyz, u_xlat7.xyz);
    u_xlat5.y = dot(u_xlat4.xyz, u_xlat9.xyw);
    u_xlat5.z = dot(u_xlat4.xyz, u_xlat8.xyz);
    u_xlat4.xyz = (-u_xlat1.xyz) + abs(u_xlat5.xyz);
    u_xlat6.xyz = max(u_xlat4.xyz, float3(0.0, 0.0, 0.0));
    u_xlat11.x = dot(u_xlat6.xyz, u_xlat6.xyz);
    u_xlat11.x = sqrt(u_xlat11.x);
    u_xlat34 = max(u_xlat4.z, u_xlat4.y);
    u_xlat34 = max(u_xlat34, u_xlat4.x);
    u_xlat34 = min(u_xlat34, 0.0);
    u_xlat11.x = u_xlat11.x + u_xlat34;
    u_xlat11.x = u_xlat11.x + (-u._smoothness);
    u_xlat11.x = min(u_xlat11.x, 100000000.0);
    u_xlat4.xz = u_xlat3.yz + float2(-0.00999999978, -1.0);
    u_xlat4.y = u_xlat2.z + (-u._position.y);
    u_xlat6.x = dot(u_xlat4.xyz, u_xlat7.xyz);
    u_xlat6.y = dot(u_xlat4.xyz, u_xlat9.xyw);
    u_xlat6.z = dot(u_xlat4.xyz, u_xlat8.xyz);
    u_xlat14.xyz = (-u_xlat1.xyz) + abs(u_xlat6.xyz);
    u_xlat4.xyz = max(u_xlat14.xyz, float3(0.0, 0.0, 0.0));
    u_xlat34 = dot(u_xlat4.xyz, u_xlat4.xyz);
    u_xlat34 = sqrt(u_xlat34);
    u_xlat24.x = max(u_xlat14.z, u_xlat14.y);
    u_xlat24.x = max(u_xlat24.x, u_xlat14.x);
    u_xlat24.x = min(u_xlat24.x, 0.0);
    u_xlat34 = u_xlat34 + u_xlat24.x;
    u_xlat34 = u_xlat34 + (-u._smoothness);
    u_xlat4.x = min(u_xlat34, 100000000.0);
    u_xlat22.xy = u_xlat11.yz * u_xlat0.xx + (-u._position.yz);
    u_xlat6.x = u_xlat2.w + (-u._position.x);
    u_xlat6.yz = u_xlat22.xy + float2(-0.00999999978, -1.0);
    u_xlat10.x = dot(u_xlat6.xyz, u_xlat7.xyz);
    u_xlat10.y = dot(u_xlat6.xyz, u_xlat9.xyw);
    u_xlat10.z = dot(u_xlat6.xyz, u_xlat8.xyz);
    u_xlat14.xyz = (-u_xlat1.xyz) + abs(u_xlat10.xyz);
    u_xlat6.xyz = max(u_xlat14.xyz, float3(0.0, 0.0, 0.0));
    u_xlat22.x = dot(u_xlat6.xyz, u_xlat6.xyz);
    u_xlat22.x = sqrt(u_xlat22.x);
    u_xlat33 = max(u_xlat14.z, u_xlat14.y);
    u_xlat33 = max(u_xlat33, u_xlat14.x);
    u_xlat33 = min(u_xlat33, 0.0);
    u_xlat22.x = u_xlat33 + u_xlat22.x;
    u_xlat22.x = u_xlat22.x + (-u._smoothness);
    u_xlat4.y = min(u_xlat22.x, 100000000.0);
    u_xlat2.xy = u_xlat2.xy + (-u._position.xy);
    u_xlat2.z = u_xlat3.x + -1.00999999;
    u_xlat3.x = dot(u_xlat2.xyz, u_xlat7.xyz);
    u_xlat3.y = dot(u_xlat2.xyz, u_xlat9.xyw);
    u_xlat3.z = dot(u_xlat2.xyz, u_xlat8.xyz);
    u_xlat1.xyz = (-u_xlat1.xyz) + abs(u_xlat3.xyz);
    u_xlat2.xyz = max(u_xlat1.xyz, float3(0.0, 0.0, 0.0));
    u_xlat22.x = dot(u_xlat2.xyz, u_xlat2.xyz);
    u_xlat22.x = sqrt(u_xlat22.x);
    u_xlat33 = max(u_xlat1.z, u_xlat1.y);
    u_xlat33 = max(u_xlat33, u_xlat1.x);
    u_xlat33 = min(u_xlat33, 0.0);
    u_xlat22.x = u_xlat33 + u_xlat22.x;
    u_xlat22.x = u_xlat22.x + (-u._smoothness);
    u_xlat4.z = min(u_xlat22.x, 100000000.0);
    u_xlat11.xyz = u_xlat11.xxx + (-u_xlat4.xyz);
    u_xlat1.x = dot(u_xlat11.xyz, u_xlat11.xyz);
    u_xlat1.x = rsqrt(u_xlat1.x);
    u_xlat12.xyz = u_xlat11.xyz * u_xlat1.xxx;
    u_xlat11.x = dot(u_xlat12.xyz, u_xlat7.xyz);
    u_xlat2 = u_xlat5.xzxy / u._size.xzxy;
    u_xlatb22 = 0.5<u_xlat11.x;
    if(u_xlatb22){
        u_xlat3.xy = u_xlat2.yw + float2(1.0, 1.0);
        u_xlat3.xy = u_xlat3.xy * float2(0.5, 0.5);
        u_xlatb4.xy = lessThan(u._size.yzyy, float4(0.0104999999, 0.0104999999, 0.0, 0.0)).xy;
        u_xlatb22 = u_xlatb4.y || u_xlatb4.x;
        u_xlat3.z = (u_xlatb22) ? 0.0 : 1.0;
    } else {
        u_xlatb11.x = u_xlat11.x<-0.5;
        if(u_xlatb11.x){
            u_xlat11.xy = u_xlat2.yw + float2(1.0, 1.0);
            u_xlat3.y = u_xlat11.y * 0.5;
            u_xlatb4.xy = lessThan(u._size.yzyy, float4(0.0104999999, 0.0104999999, 0.0, 0.0)).xy;
            u_xlatb22 = u_xlatb4.y || u_xlatb4.x;
            u_xlat3.z = (u_xlatb22) ? 0.0 : 1.0;
            u_xlat3.x = (-u_xlat11.x) * 0.5 + 1.0;
        } else {
            u_xlat11.x = dot(u_xlat12.xyz, u_xlat9.xyw);
            u_xlat11.y = dot(u_xlat12.xyz, u_xlat8.xyz);
            u_xlatb36 = 0.5<u_xlat11.x;
            u_xlat2 = u_xlat2 + float4(1.0, 1.0, 1.0, 1.0);
            u_xlat4 = u_xlat2 * float4(0.5, 0.5, 0.5, 0.5);
            u_xlatb5.xyz = lessThan(u._size.xzyx, float4(0.0104999999, 0.0104999999, 0.0104999999, 0.0)).xyz;
            u_xlati24.xy = int2(uint2((uint(u_xlatb5.y) * 0xffffffffu) | (uint(u_xlatb5.x) * 0xffffffffu), (uint(u_xlatb5.z) * 0xffffffffu) | (uint(u_xlatb5.x) * 0xffffffffu)));
            u_xlat2.xy = (-u_xlat2.xy) * float2(0.5, 0.5) + float2(1.0, 1.0);
            u_xlatb5.x = 0.5<u_xlat11.y;
            u_xlat6.x = (u_xlati24.y != 0) ? float(0.0) : float(1.0);
            u_xlat6.z = (u_xlati24.x != 0) ? float(0.0) : float(1.0);
            u_xlatb11.xy = lessThan(u_xlat11.xyxx, float4(-0.5, -0.5, 0.0, 0.0)).xy;
            u_xlat6.yw = u_xlat4.zw;
            u_xlat16.xyz = (u_xlatb11.y) ? u_xlat6.ywx : float3(0.0, 0.0, 1.0);
            u_xlat7.xy = u_xlat6.yw * float2(-1.0, 1.0) + float2(1.0, 0.0);
            u_xlat7.z = u_xlat6.x;
            u_xlat5.xyz = (u_xlatb5.x) ? u_xlat7.xyz : u_xlat16.xyz;
            u_xlat6.xy = u_xlat2.xy * float2(-1.0, 1.0) + float2(1.0, 0.0);
            u_xlat2.xyz = (u_xlatb11.x) ? u_xlat6.xyz : u_xlat5.xyz;
            u_xlat6.xy = u_xlat4.xy;
            u_xlat3.xyz = (bool(u_xlatb36)) ? u_xlat6.xyz : u_xlat2.xyz;
        }
    }
    u_xlat11.x = u._tex_angle * 0.0174532998;
    u_xlat2.x = sin(u_xlat11.x);
    u_xlat4.x = cos(u_xlat11.x);
    u_xlat5.x = (-u_xlat2.x);
    u_xlat5.y = u_xlat4.x;
    u_xlat5.z = u_xlat2.x;
    u_xlat2.x = dot(u_xlat3.xy, u_xlat5.yz);
    u_xlat2.y = dot(u_xlat3.xy, u_xlat5.xy);
    u_xlat0.yz = u_xlat2.xy + float2(u._tex_offset.x, u._tex_offset.y);
    u_xlat0.xyz = u_xlat0.xyz + float3(-30.0, -0.5, -0.5);
    u_xlat2.x = _resolution.y * _resolution.x;
    u_xlat2.x = 5.0 / u_xlat2.x;
    u_xlat2.x = (-u_xlat2.x) + 1.0;
    u_xlat11.xy = u_xlat0.yz * u_xlat2.xx;
    u_xlat11.xy = u_xlat11.xy * u._tex_scale.xy + float2(0.5, 0.5);
    u_xlatb2.xy = greaterThanEqual(u_xlat11.xyxx, (-u_xlat11.xyxx)).xy;
    u_xlat11.xy = fract(abs(u_xlat11.xy));
    {
        float3 hlslcc_movcTemp = u_xlat11;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? u_xlat11.x : (-u_xlat11.x);
        hlslcc_movcTemp.y = (u_xlatb2.y) ? u_xlat11.y : (-u_xlat11.y);
        u_xlat11 = hlslcc_movcTemp;
    }
    u_xlatb2.xy = lessThan(u_xlat11.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    {
        float3 hlslcc_movcTemp = u_xlat11;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? (-u_xlat11.x) : u_xlat11.x;
        hlslcc_movcTemp.y = (u_xlatb2.y) ? (-u_xlat11.y) : u_xlat11.y;
        u_xlat11 = hlslcc_movcTemp;
    }
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat11.xy);
    u_xlat0.x = u_xlat0.x * -0.0476190485;
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat11.x = u_xlat0.x * -2.0 + 3.0;
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat0.x = u_xlat0.x * u_xlat11.x;
    u_xlat11.x = u_xlat11.z * u_xlat1.x + -0.300000012;
    u_xlat11.x = u_xlat11.x * -9.99999905;
    u_xlat11.x = clamp(u_xlat11.x, 0.0, 1.0);
    u_xlat22.x = u_xlat11.x * -2.0 + 3.0;
    u_xlat11.x = u_xlat11.x * u_xlat11.x;
    u_xlat11.x = u_xlat11.x * u_xlat22.x;
    u_xlat0.x = u_xlat11.x * u_xlat0.x;
    u_xlatb11.x = 0<int(u._enable_lighting);
    u_xlat3.xyw = u._light_direction.xyz * float3(0.5, -0.5, -2.0);
    u_xlat22.x = dot(u_xlat3.xyw, u_xlat3.xyw);
    u_xlat22.x = rsqrt(u_xlat22.x);
    u_xlat3.xyw = u_xlat22.xxx * u_xlat3.xyw;
    u_xlat22.x = dot(u_xlat12.xyz, u_xlat3.xyw);
    u_xlat1.xyz = u_xlat2.xyz * u._light_color.xyz;
    u_xlat1.xyz = u_xlat22.xxx * u_xlat1.xyz;
    u_xlat33 = (-u._ambient) + 1.0;
    u_xlat1.xyz = float3(u_xlat33) * u_xlat1.xyz;
    u_xlat1.xyz = u_xlat2.xyz * float3(float3(u._ambient, u._ambient, u._ambient)) + u_xlat1.xyz;
    u_xlat1.xyz = u_xlat1.xyz * float3(float3(u._light_intensity, u._light_intensity, u._light_intensity));
    u_xlat22.x = log2(u_xlat22.x);
    u_xlat22.x = u_xlat22.x * u._specular;
    u_xlat22.x = exp2(u_xlat22.x);
    u_xlat33 = (-u._shine) * 0.100000001 + 1.0;
    u_xlat3.xyw = float3(u_xlat33) * u_xlat1.xyz;
    u_xlat22.x = u_xlat22.x * u._shine;
    u_xlat1.xyz = (-u_xlat1.xyz) * float3(u_xlat33) + float3(1.0, 1.0, 1.0);
    u_xlat1.xyz = u_xlat22.xxx * u_xlat1.xyz + u_xlat3.xyw;
    u_xlat1.w = u_xlat2.w;
    u_xlat1 = u_xlat0.xxxx * u_xlat1;
    u_xlat2 = u_xlat0.xxxx * u_xlat2;
    u_xlat0 = (u_xlatb11.x) ? u_xlat1 : u_xlat2;
    u_xlat0 = u_xlat3.zzzz * u_xlat0;
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
