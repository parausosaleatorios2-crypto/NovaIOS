// ---------------------------------------------------------------------------
// Raytracing Star (NV)
// origem : assets/effects/nv-nodevideo-raytracing-star.xml
// id     : nv.effect.nodevideo-raytracing-star
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_raytracing_starParams {
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
    float _size;
    float _thickness;
    float _sides;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
int u_xlati3;
float4 u_xlat4;
bool2 u_xlatb4;
float4 u_xlat5;
bool u_xlatb5;
float3 u_xlat6;
float3 u_xlat7;
float3 u_xlat8;
float4 u_xlat9;
float3 u_xlat10;
float3 u_xlat11;
float3 u_xlat12;
bool2 u_xlatb12;
float3 u_xlat13;
int u_xlati13;
float2 u_xlat15;
bool u_xlatb15;
float2 u_xlat24;
bool u_xlatb24;
float2 u_xlat25;
bool u_xlatb25;
bool2 u_xlatb26;
float2 u_xlat27;
int u_xlati27;
float u_xlat29;
float u_xlat36;
float u_xlat37;
int u_xlati37;
float u_xlat38;
bool u_xlatb38;
float u_xlat39;
bool u_xlatb39;
float u_xlat40;
int u_xlati40;
float u_xlat41;
bool u_xlatb41;
float u_xlat42;

fragment float4 fx_nv_nodevideo_raytracing_star(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_raytracing_starParams&  u    [[buffer(1)]],
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
    u_xlat12.x = _resolution.x / _resolution.y;
    u_xlat1.y = u_xlat12.x * u_xlat1.x;
    u_xlat1.xy = u_xlat1.yz / float2(float2(u._zoom, u._zoom));
    u_xlat1.z = 1.0;
    u_xlat12.x = dot(u_xlat1.xyz, u_xlat1.xyz);
    u_xlat12.x = rsqrt(u_xlat12.x);
    u_xlat12.xyz = u_xlat12.xxx * u_xlat1.xyz;
    u_xlat13.y = u._size * -0.5;
    u_xlat1.x = float(int(u._sides));
    u_xlat1.x = 6.28318024 / u_xlat1.x;
    u_xlat2.x = cos(u_xlat1.x);
    u_xlat1.x = sin(u_xlat1.x);
    u_xlat2.z = (-u_xlat1.x);
    u_xlat9.zw = u_xlat0.xx;
    u_xlat13.x = float(0.0);
    u_xlat13.z = float(0.0);
    u_xlat2.y = u_xlat1.x;
    u_xlat0.x = 0.0;
    u_xlati3 = 0;
    while(true){
        u_xlatb15 = u_xlati3>=int(u._iteration);
        if(u_xlatb15){break;}
        u_xlat15.xy = u_xlat0.xx * u_xlat12.xy;
        u_xlat39 = u_xlat12.z * u_xlat0.x + (-u._position.z);
        u_xlat4.xy = u_xlat15.xy + (-u._position.xy);
        u_xlat4.z = u_xlat39 + -1.0;
        u_xlat15.x = dot(u_xlat4.xyz, u_xlat7.xyz);
        u_xlat15.y = dot(u_xlat4.xyz, u_xlat9.xyz);
        u_xlat4.z = dot(u_xlat4.xyz, u_xlat8.xyz);
        u_xlat4.xy = u_xlat15.xy;
        u_xlat39 = 100000000.0;
        u_xlati40 = 0;
        while(true){
            u_xlatb5 = u_xlati40>=int(u._sides);
            if(u_xlatb5){break;}
            u_xlat5.xyz = u_xlat13.xyz + u_xlat4.xyz;
            u_xlat29 = abs(u_xlat5.z) + (-u._thickness);
            u_xlat41 = u_xlat5.y * 0.5;
            u_xlat5.x = abs(u_xlat5.x) * 0.866024971 + u_xlat41;
            u_xlat5.x = max((-u_xlat5.y), u_xlat5.x);
            u_xlat5.x = (-u._size) * 0.5 + u_xlat5.x;
            u_xlat5.x = max(u_xlat5.x, u_xlat29);
            u_xlat39 = min(u_xlat39, u_xlat5.x);
            u_xlat5.x = dot(u_xlat4.xy, u_xlat2.xy);
            u_xlat5.y = dot(u_xlat4.yx, u_xlat2.xz);
            u_xlati40 = u_xlati40 + 1;
            u_xlat4.xy = u_xlat5.xy;
        }
        u_xlat15.x = min(u_xlat39, 100000000.0);
        u_xlat27.x = u_xlat0.x + u_xlat15.x;
        u_xlatb15 = u_xlat15.x<9.99999975e-06;
        u_xlatb4.x = 1000.0<u_xlat27.x;
        u_xlatb15 = u_xlatb15 || u_xlatb4.x;
        if(u_xlatb15){
            u_xlat0.x = u_xlat27.x;
            break;
        }
        u_xlati3 = u_xlati3 + 1;
        u_xlat0.x = u_xlat27.x;
    }
    u_xlat27.xy = u_xlat0.xx * u_xlat12.yx;
    u_xlat3 = u_xlat27.yxxy;
    u_xlat13.xyz = u_xlat12.zxz * u_xlat0.xxx + (-u._position.zxz);
    u_xlat4.xy = u_xlat3.xy + (-u._position.xy);
    u_xlat4.z = u_xlat13.x + -1.0;
    u_xlat5.x = dot(u_xlat4.xyz, u_xlat7.xyz);
    u_xlat5.y = dot(u_xlat4.xyz, u_xlat9.xyw);
    u_xlat4.z = dot(u_xlat4.xyz, u_xlat8.xyz);
    u_xlat6.x = float(0.0);
    u_xlat6.z = float(0.0);
    u_xlat6.y = u._size * -0.5;
    u_xlat2.y = u_xlat1.x;
    u_xlat2.w = u_xlat2.x;
    u_xlat4.xy = u_xlat5.xy;
    u_xlat12.x = 100000000.0;
    u_xlati40 = 0;
    while(true){
        u_xlatb41 = u_xlati40>=int(u._sides);
        if(u_xlatb41){break;}
        u_xlat10.xyz = u_xlat4.xyz + u_xlat6.xyz;
        u_xlat41 = abs(u_xlat10.z) + (-u._thickness);
        u_xlat42 = u_xlat10.y * 0.5;
        u_xlat42 = abs(u_xlat10.x) * 0.866024971 + u_xlat42;
        u_xlat42 = max((-u_xlat10.y), u_xlat42);
        u_xlat42 = (-u._size) * 0.5 + u_xlat42;
        u_xlat41 = max(u_xlat41, u_xlat42);
        u_xlat12.x = min(u_xlat12.x, u_xlat41);
        u_xlat10.x = dot(u_xlat4.xy, u_xlat2.xy);
        u_xlat10.y = dot(u_xlat4.xy, u_xlat2.zw);
        u_xlati40 = u_xlati40 + 1;
        u_xlat4.xy = u_xlat10.xy;
    }
    u_xlat12.x = min(u_xlat12.x, 100000000.0);
    u_xlat6.xz = u_xlat13.yz + float2(-0.00999999978, -1.0);
    u_xlat6.y = u_xlat3.z + (-u._position.y);
    u_xlat25.x = dot(u_xlat6.xyz, u_xlat7.xyz);
    u_xlat25.y = dot(u_xlat6.xyz, u_xlat9.xyw);
    u_xlat6.z = dot(u_xlat6.xyz, u_xlat8.xyz);
    u_xlat10.x = float(0.0);
    u_xlat10.z = float(0.0);
    u_xlat10.y = u._size * -0.5;
    u_xlat2.y = u_xlat1.x;
    u_xlat6.xy = u_xlat25.xy;
    u_xlat38 = 100000000.0;
    u_xlati27 = 0;
    while(true){
        u_xlatb4.x = u_xlati27>=int(u._sides);
        if(u_xlatb4.x){break;}
        u_xlat4.xyw = u_xlat6.xyz + u_xlat10.xyz;
        u_xlat40 = abs(u_xlat4.w) + (-u._thickness);
        u_xlat41 = u_xlat4.y * 0.5;
        u_xlat4.x = abs(u_xlat4.x) * 0.866024971 + u_xlat41;
        u_xlat4.x = max((-u_xlat4.y), u_xlat4.x);
        u_xlat4.x = (-u._size) * 0.5 + u_xlat4.x;
        u_xlat4.x = max(u_xlat4.x, u_xlat40);
        u_xlat38 = min(u_xlat38, u_xlat4.x);
        u_xlat4.x = dot(u_xlat6.xy, u_xlat2.xy);
        u_xlat4.y = dot(u_xlat6.yx, u_xlat2.xz);
        u_xlati27 = u_xlati27 + 1;
        u_xlat6.xy = u_xlat4.xy;
    }
    u_xlat6.x = min(u_xlat38, 100000000.0);
    u_xlat24.xy = u_xlat12.yz * u_xlat0.xx + (-u._position.yz);
    u_xlat10.x = u_xlat3.w + (-u._position.x);
    u_xlat10.yz = u_xlat24.xy + float2(-0.00999999978, -1.0);
    u_xlat24.x = dot(u_xlat10.xyz, u_xlat7.xyz);
    u_xlat24.y = dot(u_xlat10.xyz, u_xlat9.xyw);
    u_xlat10.z = dot(u_xlat10.xyz, u_xlat8.xyz);
    u_xlat11.x = float(0.0);
    u_xlat11.z = float(0.0);
    u_xlat11.y = u._size * -0.5;
    u_xlat2.y = u_xlat1.x;
    u_xlat10.xy = u_xlat24.xy;
    u_xlat25.x = float(100000000.0);
    u_xlati37 = int(0);
    while(true){
        u_xlatb38 = u_xlati37>=int(u._sides);
        if(u_xlatb38){break;}
        u_xlat4.xyw = u_xlat10.xyz + u_xlat11.xyz;
        u_xlat38 = abs(u_xlat4.w) + (-u._thickness);
        u_xlat27.x = u_xlat4.y * 0.5;
        u_xlat27.x = abs(u_xlat4.x) * 0.866024971 + u_xlat27.x;
        u_xlat27.x = max((-u_xlat4.y), u_xlat27.x);
        u_xlat27.x = (-u._size) * 0.5 + u_xlat27.x;
        u_xlat38 = max(u_xlat38, u_xlat27.x);
        u_xlat25.x = min(u_xlat25.x, u_xlat38);
        u_xlat4.x = dot(u_xlat10.xy, u_xlat2.xy);
        u_xlat4.y = dot(u_xlat10.yx, u_xlat2.xz);
        u_xlati37 = u_xlati37 + 1;
        u_xlat10.xy = u_xlat4.xy;
    }
    u_xlat6.y = min(u_xlat25.x, 100000000.0);
    u_xlat3.xy = u_xlat3.xy + (-u._position.xy);
    u_xlat3.z = u_xlat13.x + -1.00999999;
    u_xlat24.x = dot(u_xlat3.xyz, u_xlat7.xyz);
    u_xlat24.y = dot(u_xlat3.xyz, u_xlat9.xyw);
    u_xlat3.z = dot(u_xlat3.xyz, u_xlat8.xyz);
    u_xlat10.x = float(0.0);
    u_xlat10.z = float(0.0);
    u_xlat10.y = u._size * -0.5;
    u_xlat2.y = u_xlat1.x;
    u_xlat3.xy = u_xlat24.xy;
    u_xlat1.x = float(100000000.0);
    u_xlati13 = int(0);
    while(true){
        u_xlatb25 = u_xlati13>=int(u._sides);
        if(u_xlatb25){break;}
        u_xlat4.xyw = u_xlat3.xyz + u_xlat10.xyz;
        u_xlat25.x = abs(u_xlat4.w) + (-u._thickness);
        u_xlat37 = u_xlat4.y * 0.5;
        u_xlat37 = abs(u_xlat4.x) * 0.866024971 + u_xlat37;
        u_xlat37 = max((-u_xlat4.y), u_xlat37);
        u_xlat37 = (-u._size) * 0.5 + u_xlat37;
        u_xlat25.x = max(u_xlat37, u_xlat25.x);
        u_xlat1.x = min(u_xlat25.x, u_xlat1.x);
        u_xlat4.x = dot(u_xlat3.xy, u_xlat2.xy);
        u_xlat4.y = dot(u_xlat3.yx, u_xlat2.xz);
        u_xlati13 = u_xlati13 + 1;
        u_xlat3.xy = u_xlat4.xy;
    }
    u_xlat6.z = min(u_xlat1.x, 100000000.0);
    u_xlat12.xyz = u_xlat12.xxx + (-u_xlat6.xyz);
    u_xlat1.x = dot(u_xlat12.xyz, u_xlat12.xyz);
    u_xlat1.x = rsqrt(u_xlat1.x);
    u_xlat13.xyz = u_xlat12.xyz * u_xlat1.xxx;
    u_xlat12.x = dot(u_xlat13.xyz, u_xlat7.xyz);
    u_xlat5.z = u_xlat4.z;
    u_xlat2 = u_xlat5.xzxy / float4(u._size, u._thickness, u._size, u._size);
    u_xlatb24 = 0.5<u_xlat12.x;
    if(u_xlatb24){
        u_xlat3.xy = u_xlat2.yw + float2(1.0, 1.0);
        u_xlat3.xy = u_xlat3.xy * float2(0.5, 0.5);
        u_xlatb4.xy = lessThan(float4(u._size, u._thickness, u._size, u._size), float4(0.0104999999, 0.0104999999, 0.0, 0.0)).xy;
        u_xlatb24 = u_xlatb4.y || u_xlatb4.x;
        u_xlat3.z = (u_xlatb24) ? 0.0 : 1.0;
    } else {
        u_xlatb12.x = u_xlat12.x<-0.5;
        if(u_xlatb12.x){
            u_xlat12.xy = u_xlat2.yw + float2(1.0, 1.0);
            u_xlat3.y = u_xlat12.y * 0.5;
            u_xlatb4.xy = lessThan(float4(u._size, u._thickness, u._size, u._size), float4(0.0104999999, 0.0104999999, 0.0, 0.0)).xy;
            u_xlatb24 = u_xlatb4.y || u_xlatb4.x;
            u_xlat3.z = (u_xlatb24) ? 0.0 : 1.0;
            u_xlat3.x = (-u_xlat12.x) * 0.5 + 1.0;
        } else {
            u_xlat12.x = dot(u_xlat13.xyz, u_xlat9.xyw);
            u_xlat12.y = dot(u_xlat13.xyz, u_xlat8.xyz);
            u_xlatb39 = 0.5<u_xlat12.x;
            u_xlat2 = u_xlat2 + float4(1.0, 1.0, 1.0, 1.0);
            u_xlat4 = u_xlat2 * float4(0.5, 0.5, 0.5, 0.5);
            u_xlatb26.xy = lessThan(float4(u._size, u._thickness, u._size, u._thickness), float4(0.0104999999, 0.0104999999, 0.0104999999, 0.0104999999)).xy;
            u_xlatb38 = u_xlatb26.y || u_xlatb26.x;
            u_xlat5.z = (u_xlatb38) ? 0.0 : 1.0;
            u_xlat2.xy = (-u_xlat2.xy) * float2(0.5, 0.5) + float2(1.0, 1.0);
            u_xlatb38 = 0.5<u_xlat12.y;
            u_xlat6.z = (u_xlatb26.x) ? 0.0 : 1.0;
            u_xlatb12.xy = lessThan(u_xlat12.xyxx, float4(-0.5, -0.5, 0.0, 0.0)).xy;
            u_xlat6.xy = u_xlat4.zw;
            u_xlat7.xyz = (u_xlatb12.y) ? u_xlat6.xyz : float3(0.0, 0.0, 1.0);
            u_xlat6.xy = u_xlat4.zw * float2(-1.0, 1.0) + float2(1.0, 0.0);
            u_xlat6.xyz = (bool(u_xlatb38)) ? u_xlat6.xyz : u_xlat7.xyz;
            u_xlat5.xy = u_xlat2.xy * float2(-1.0, 1.0) + float2(1.0, 0.0);
            u_xlat2.xyz = (u_xlatb12.x) ? u_xlat5.xyz : u_xlat6.xyz;
            u_xlat5.xy = u_xlat4.xy;
            u_xlat3.xyz = (bool(u_xlatb39)) ? u_xlat5.xyz : u_xlat2.xyz;
        }
    }
    u_xlat12.x = u._tex_angle * 0.0174532998;
    u_xlat2.x = sin(u_xlat12.x);
    u_xlat4.x = cos(u_xlat12.x);
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
    u_xlat12.xy = u_xlat0.yz * u_xlat2.xx;
    u_xlat12.xy = u_xlat12.xy * u._tex_scale.xy + float2(0.5, 0.5);
    u_xlatb2.xy = greaterThanEqual(u_xlat12.xyxx, (-u_xlat12.xyxx)).xy;
    u_xlat12.xy = fract(abs(u_xlat12.xy));
    {
        float3 hlslcc_movcTemp = u_xlat12;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? u_xlat12.x : (-u_xlat12.x);
        hlslcc_movcTemp.y = (u_xlatb2.y) ? u_xlat12.y : (-u_xlat12.y);
        u_xlat12 = hlslcc_movcTemp;
    }
    u_xlatb2.xy = lessThan(u_xlat12.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    {
        float3 hlslcc_movcTemp = u_xlat12;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? (-u_xlat12.x) : u_xlat12.x;
        hlslcc_movcTemp.y = (u_xlatb2.y) ? (-u_xlat12.y) : u_xlat12.y;
        u_xlat12 = hlslcc_movcTemp;
    }
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat12.xy);
    u_xlat0.x = u_xlat0.x * -0.0476190485;
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat12.x = u_xlat0.x * -2.0 + 3.0;
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat0.x = u_xlat0.x * u_xlat12.x;
    u_xlat12.x = u_xlat12.z * u_xlat1.x + -0.300000012;
    u_xlat12.x = u_xlat12.x * -9.99999905;
    u_xlat12.x = clamp(u_xlat12.x, 0.0, 1.0);
    u_xlat24.x = u_xlat12.x * -2.0 + 3.0;
    u_xlat12.x = u_xlat12.x * u_xlat12.x;
    u_xlat12.x = u_xlat12.x * u_xlat24.x;
    u_xlat0.x = u_xlat12.x * u_xlat0.x;
    u_xlatb12.x = 0<int(u._enable_lighting);
    u_xlat3.xyw = u._light_direction.xyz * float3(0.5, -0.5, -2.0);
    u_xlat24.x = dot(u_xlat3.xyw, u_xlat3.xyw);
    u_xlat24.x = rsqrt(u_xlat24.x);
    u_xlat3.xyw = u_xlat24.xxx * u_xlat3.xyw;
    u_xlat24.x = dot(u_xlat13.xyz, u_xlat3.xyw);
    u_xlat1.xyz = u_xlat2.xyz * u._light_color.xyz;
    u_xlat1.xyz = u_xlat24.xxx * u_xlat1.xyz;
    u_xlat36 = (-u._ambient) + 1.0;
    u_xlat1.xyz = float3(u_xlat36) * u_xlat1.xyz;
    u_xlat1.xyz = u_xlat2.xyz * float3(float3(u._ambient, u._ambient, u._ambient)) + u_xlat1.xyz;
    u_xlat1.xyz = u_xlat1.xyz * float3(float3(u._light_intensity, u._light_intensity, u._light_intensity));
    u_xlat24.x = log2(u_xlat24.x);
    u_xlat24.x = u_xlat24.x * u._specular;
    u_xlat24.x = exp2(u_xlat24.x);
    u_xlat36 = (-u._shine) * 0.100000001 + 1.0;
    u_xlat3.xyw = float3(u_xlat36) * u_xlat1.xyz;
    u_xlat24.x = u_xlat24.x * u._shine;
    u_xlat1.xyz = (-u_xlat1.xyz) * float3(u_xlat36) + float3(1.0, 1.0, 1.0);
    u_xlat1.xyz = u_xlat24.xxx * u_xlat1.xyz + u_xlat3.xyw;
    u_xlat1.w = u_xlat2.w;
    u_xlat1 = u_xlat0.xxxx * u_xlat1;
    u_xlat2 = u_xlat0.xxxx * u_xlat2;
    u_xlat0 = (u_xlatb12.x) ? u_xlat1 : u_xlat2;
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
