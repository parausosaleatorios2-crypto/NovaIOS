// ---------------------------------------------------------------------------
// Raytracing Ocean (NV)
// origem : assets/effects/nv-nodevideo-raytracing-ocean.xml
// id     : nv.effect.nodevideo-raytracing-ocean
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_raytracing_oceanParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _base_color;
    float4 _background_color;
    float _brightness;
    float3 _position;
    float3 _rotation;
    float _zoom;
    float _enable_sky;
    float _enable_clouds;
    float _intensity;
    float _radius;
    float2 _sun_position;
    float _opacity;
    float _reflection;
    float _complexity;
    float _detail;
    float2 _iteration;
    float _scale;
    float _speed;
    float _frequency;
    float _height;
    float2 _scroll;
    float _direction;
    float _drag;
    float _reflection_source;
    float3 _reflection_dir;
    float _hue;
    float _feather;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
int u_xlati1;
bool u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
bool4 u_xlatb5;
float3 u_xlat6;
bool u_xlatb6;
float4 u_xlat7;
float4 u_xlat8;
float4 u_xlat9;
float4 u_xlat10;
float4 u_xlat11;
float4 u_xlat12;
float4 u_xlat13;
float4 u_xlat14;
float4 u_xlat15;
float3 u_xlat16;
float3 u_xlat17;
float2 u_xlat18;
int u_xlati18;
bool u_xlatb18;
float u_xlat19;
bool u_xlatb19;
float3 u_xlat21;
bool u_xlatb21;
float u_xlat22;
bool u_xlatb22;
float u_xlat23;
int u_xlati23;
bool u_xlatb23;
float u_xlat24;
float2 u_xlat25;
int u_xlati26;
float3 u_xlat31;
float u_xlat36;
bool u_xlatb36;
float u_xlat37;
float u_xlat38;
int u_xlati38;
float2 u_xlat42;
bool u_xlatb42;
float2 u_xlat43;
float2 u_xlat44;
bool u_xlatb44;
float2 u_xlat47;
float2 u_xlat51;
float u_xlat54;
float u_xlat55;
float u_xlat57;
bool u_xlatb57;
float u_xlat58;
bool u_xlatb58;
float u_xlat59;
float u_xlat60;
bool u_xlatb60;
float u_xlat62;

fragment float4 fx_nv_nodevideo_raytracing_ocean(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_raytracing_oceanParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> panoramic_texture [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy * _resolution.xy;
    u_xlat0.xy = u_xlat0.xy / _resolution.xy;
    u_xlat0.yz = u_xlat0.xy + float2(-0.5, -0.5);
    u_xlat54 = _resolution.x / _resolution.y;
    u_xlat0.x = u_xlat54 * u_xlat0.y;
    u_xlat0.xy = u_xlat0.xz / float2(float2(u._zoom, u._zoom));
    u_xlat0.z = 1.0;
    u_xlat54 = dot(u_xlat0.xyz, u_xlat0.xyz);
    u_xlat54 = rsqrt(u_xlat54);
    u_xlat0.xyz = float3(u_xlat54) * u_xlat0.xyz;
    u_xlat1.xyz = u._rotation.xyz * float3(6.28318548, 6.28318548, 6.28318548);
    u_xlat2.x = sin(u_xlat1.z);
    u_xlat3.x = cos(u_xlat1.z);
    u_xlat4.x = (-u_xlat2.x);
    u_xlat5.x = cos(u_xlat1.x);
    u_xlat1.x = sin(u_xlat1.x);
    u_xlat6.y = u_xlat2.x * u_xlat5.x;
    u_xlat3.y = (-u_xlat1.x) * u_xlat2.x;
    u_xlat2.y = u_xlat3.x * u_xlat5.x;
    u_xlat4.y = (-u_xlat1.x) * u_xlat3.x;
    u_xlat7.x = sin(u_xlat1.y);
    u_xlat8.x = cos(u_xlat1.y);
    u_xlat9.x = (-u_xlat7.x);
    u_xlat9.y = u_xlat8.x;
    u_xlat6.x = dot(u_xlat3.yx, u_xlat9.xy);
    u_xlat9.z = u_xlat7.x;
    u_xlat6.z = dot(u_xlat3.yx, u_xlat9.yz);
    u_xlat2.x = dot(u_xlat4.yx, u_xlat9.xy);
    u_xlat2.z = dot(u_xlat4.yx, u_xlat9.yz);
    u_xlat3.x = u_xlat5.x * u_xlat9.x;
    u_xlat3.z = u_xlat5.x * u_xlat8.x;
    u_xlat4.x = dot(u_xlat6.xyz, u_xlat0.xyz);
    u_xlat4.y = dot(u_xlat2.xyz, u_xlat0.xyz);
    u_xlat3.y = u_xlat1.x;
    u_xlat4.z = dot(u_xlat3.xyz, u_xlat0.xyz);
    u_xlat0.x = u._position.xxyz.z + -1.86000001;
    u_xlat0.x = (-u_xlat0.x) / u_xlat4.y;
    u_xlatb18 = 0.0<u_xlat0.x;
    if(u_xlatb18){
        u_xlati18 = int(u._iteration.x);
        u_xlat36 = _cur_time * 1.5;
        u_xlat54 = _cur_time * u._speed;
        u_xlat1.x = trunc(u._iteration.x);
        u_xlat1.x = u_xlat1.x * -0.321928084;
        u_xlat2.x = sin(u._direction);
        u_xlat3.x = cos(u._direction);
        u_xlat5.x = sin((-u._direction));
        u_xlat1.x = exp2(u_xlat1.x);
        u_xlat1.x = u_xlat1.x + -1.0;
        u_xlat1.x = (-u_xlat1.x) / u._height;
        u_xlat19 = u._complexity + -2.0;
        u_xlat37 = u._feather * 100.0;
        u_xlat5.y = u_xlat3.x;
        u_xlat5.z = u_xlat2.x;
        u_xlat55 = u_xlat0.x;
        u_xlati38 = 0;
        u_xlat2.xyw = float3(u._position.x, u._position.z, u._position.y);
        u_xlat3.x = 0.0;
        while(true){
            u_xlatb21 = u_xlat3.x>=u._complexity;
            if(u_xlatb21){break;}
            u_xlat21.xyz = u_xlat4.xyz * float3(u_xlat55) + float3(u._position.x, u._position.y, u._position.z);
            u_xlat6.xy = float2(u_xlat36) * float2(u._scroll.x, u._scroll.y) + u_xlat21.xz;
            u_xlat6.xy = u_xlat6.xy * float2(float2(u._scale, u._scale));
            u_xlat42.xy = u_xlat6.xy;
            u_xlat59 = 0.0;
            u_xlat7.x = float(1.0);
            u_xlat7.y = float(0.0);
            u_xlat43.x = float(1.0);
            u_xlat43.y = u._frequency;
            u_xlat8.x = u_xlat54;
            u_xlati26 = 0;
            while(true){
                u_xlatb44 = u_xlati26>=u_xlati18;
                if(u_xlatb44){break;}
                u_xlat9.x = dot(u_xlat5.yz, u_xlat7.xy);
                u_xlat9.y = dot(u_xlat5.xy, u_xlat7.xy);
                u_xlat44.x = dot(u_xlat9.xy, u_xlat42.xy);
                u_xlat44.x = u_xlat44.x * u_xlat43.y + u_xlat8.x;
                u_xlat10.x = sin(u_xlat44.x);
                u_xlat11.x = cos(u_xlat44.x);
                u_xlat44.x = u_xlat10.x + -1.0;
                u_xlat44.x = u_xlat44.x * 1.44269502;
                u_xlat44.x = exp2(u_xlat44.x);
                u_xlat62 = u_xlat43.x * u_xlat44.x;
                u_xlat59 = u_xlat44.x * u_xlat43.x + u_xlat59;
                u_xlat8.x = u_xlat8.x * 1.09500003;
                u_xlat44.xy = float2(u_xlat62) * u_xlat9.xy;
                u_xlat44.xy = u_xlat44.xy * float2(float2(u._drag, u._drag));
                u_xlat42.xy = (-u_xlat44.xy) * u_xlat11.xx + u_xlat42.xy;
                u_xlat43.xy = u_xlat43.xy * float2(0.800000012, 1.20000005);
                u_xlati26 = u_xlati26 + 1;
                u_xlat7.xy = u_xlat9.xy;
            }
            u_xlat6.x = u_xlat59 / u_xlat1.x;
            u_xlat6.x = u_xlat21.y + (-u_xlat6.x);
            u_xlat24 = u_xlat55 + u_xlat6.x;
            u_xlatb6 = abs(u_xlat6.x)<0.00499999989;
            u_xlatb42 = u_xlat19<u_xlat3.x;
            u_xlatb6 = u_xlatb42 || u_xlatb6;
            if(u_xlatb6){
                u_xlat55 = u_xlat24;
                u_xlati38 = int(0xFFFFFFFFu);
                u_xlat2.xyw = u_xlat21.xzy;
                break;
            }
            u_xlatb6 = u_xlat37<u_xlat24;
            if(u_xlatb6){
                u_xlat55 = u_xlat37;
                u_xlati38 = 0;
                u_xlat2.xyw = u_xlat21.xzy;
                break;
            }
            u_xlat55 = u_xlat24;
            u_xlat3.x = u_xlat3.x + 1.0;
            u_xlat2.xyw = u_xlat21.xzy;
            u_xlati38 = 0;
        }
    } else {
        u_xlat55 = 0.0;
        u_xlati38 = 0;
        u_xlat2.xyw = float3(u._position.x, u._position.z, u._position.y);
    }
    u_xlat0.x = min(_resolution.y, _resolution.x);
    u_xlat18.x = u._radius * 0.100000001;
    u_xlat1.x = sin(u._sun_position.xxyx.z);
    u_xlat3.x = cos(u._sun_position.xxyx.z);
    u_xlat5.xy = sin((-float2(u._sun_position.y, u._sun_position.x)));
    u_xlat5.z = u_xlat3.x;
    u_xlat5.w = u_xlat1.x;
    u_xlat1.y = dot(u_xlat5.zw, u_xlat4.yz);
    u_xlat4.w = dot(u_xlat5.xz, u_xlat4.yz);
    u_xlat3.x = sin(u._sun_position.xxyx.y);
    u_xlat6.x = cos(u._sun_position.xxyx.y);
    u_xlat6.y = u_xlat3.x;
    u_xlat1.x = dot(u_xlat6.xy, u_xlat4.xw);
    u_xlat6.z = u_xlat5.y;
    u_xlat36 = dot(u_xlat6.zx, u_xlat4.xw);
    u_xlat0.xw = float2(1.5, 2.5) / u_xlat0.xx;
    u_xlat36 = u_xlat36 * 0.5 + 0.5;
    u_xlat3.xyz = u._base_color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat3.xyz = u._base_color.xyz * u_xlat3.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat7.xyz = u_xlat3.xyz * u._base_color.xyz;
    u_xlat37 = u._hue + 1.0;
    u_xlat37 = u_xlat37 * 3.14159274;
    u_xlat7.w = u._base_color.w;
    u_xlat8 = u_xlat7 + float4(0.899999976, 0.899999976, 0.899999976, 0.899999976);
    u_xlat8 = float4(u_xlat37) * u_xlat8;
    u_xlat8 = cos(u_xlat8);
    u_xlat9 = u_xlat8 * float4(0.5, 0.5, 0.5, 0.5) + float4(float4(u._intensity, u._intensity, u._intensity, u._intensity));
    u_xlat10 = u_xlat9 * float4(0.850000024, 0.850000024, 0.850000024, 0.850000024);
    u_xlat1.x = dot(u_xlat1.xy, u_xlat1.xy);
    u_xlat1.x = sqrt(u_xlat1.x);
    u_xlat19 = (-u_xlat0.x) + u_xlat1.x;
    u_xlat19 = (-u_xlat0.w) + u_xlat19;
    u_xlat57 = u_xlat0.x + u_xlat1.x;
    u_xlat57 = u_xlat0.w + u_xlat57;
    u_xlat57 = (-u_xlat19) + u_xlat57;
    u_xlat19 = u._radius * 0.100000001 + (-u_xlat19);
    u_xlat57 = float(1.0) / u_xlat57;
    u_xlat19 = u_xlat19 * u_xlat57;
    u_xlat19 = clamp(u_xlat19, 0.0, 1.0);
    u_xlat57 = u_xlat19 * -2.0 + 3.0;
    u_xlat19 = u_xlat19 * u_xlat19;
    u_xlat19 = u_xlat19 * u_xlat57;
    u_xlat11 = u_xlat10 * float4(u_xlat19);
    u_xlat11 = float4(u_xlat36) * u_xlat11;
    u_xlat12 = u_xlat11 + u_xlat11;
    u_xlat1.x = log2(u_xlat1.x);
    u_xlat1.x = u_xlat1.x * u._intensity;
    u_xlat1.x = exp2(u_xlat1.x);
    u_xlat1.x = u._radius * 0.100000001 + u_xlat1.x;
    u_xlat1.x = u_xlat18.x / u_xlat1.x;
    u_xlat13 = u_xlat10 * u_xlat1.xxxx;
    u_xlat12 = u_xlat13 * float4(u_xlat36) + u_xlat12;
    u_xlat7 = u_xlat7 + float4(1.10000002, 1.10000002, 1.10000002, 1.10000002);
    u_xlat7 = float4(u_xlat37) * u_xlat7;
    u_xlat7 = cos(u_xlat7);
    u_xlat7 = u_xlat7 * float4(0.5, 0.5, 0.5, 0.5) + float4(u._brightness);
    u_xlat36 = dot(u_xlat12, u_xlat12);
    u_xlat36 = sqrt(u_xlat36);
    u_xlat36 = (-u_xlat36) + 1.0;
    u_xlat36 = max(u_xlat36, 0.0);
    u_xlat13 = (-u_xlat12) + u_xlat7;
    u_xlat13 = float4(u_xlat36) * u_xlat13 + u_xlat12;
    u_xlat12 = u_xlat13 * float4(0.200000003, 0.200000003, 0.200000003, 0.200000003) + u_xlat12;
    u_xlatb36 = 0<int(u._enable_clouds);
    if(u_xlatb36){
        u_xlat1.x = u_xlat4.z * 0.400000006;
        u_xlat13.xy = float2(float2(_cur_time, _cur_time)) * float2(0.00700000022, 0.0199999996);
        u_xlat1.y = u_xlat4.x * 0.400000006 + u_xlat13.x;
        u_xlat14.xy = u_xlat1.yx;
        u_xlat57 = 0.0;
        u_xlat14.z = u_xlat4.y;
        u_xlat58 = 200.0;
        while(true){
            u_xlatb23 = 10.0>=u_xlat58;
            if(u_xlatb23){break;}
            u_xlat13.x = sin(u_xlat58);
            u_xlat15.x = cos(u_xlat58);
            u_xlat16.x = sin((-u_xlat58));
            u_xlat16.y = u_xlat15.x;
            u_xlat16.z = u_xlat13.x;
            u_xlat15.x = dot(u_xlat16.yz, u_xlat14.xy);
            u_xlat15.z = dot(u_xlat16.xy, u_xlat14.xy);
            u_xlat15.y = u_xlat14.z;
            u_xlat14.xyz = float3(u_xlat58) + u_xlat15.xzy;
            u_xlat13.xzw = u_xlat14.xzy * float3(u_xlat58) + u_xlat13.yyy;
            u_xlat13.xzw = sin(u_xlat13.xzw);
            u_xlat13.xzw = u_xlat13.xzw / float3(u_xlat58);
            u_xlat23 = dot(u_xlat13.xzw, float3(1.64999998, 1.64999998, 1.64999998));
            u_xlat57 = u_xlat57 + abs(u_xlat23);
            u_xlat58 = u_xlat58 * 0.800000012;
        }
        u_xlat1.x = u_xlat57 + -0.595000029;
        u_xlat1.x = u_xlat1.x * -10.000001;
        u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
        u_xlat19 = u_xlat1.x * -2.0 + 3.0;
        u_xlat1.x = u_xlat1.x * u_xlat1.x;
        u_xlat1.x = u_xlat1.x * u_xlat19;
        u_xlat1.x = u_xlat1.x * u_xlat57;
        u_xlat19 = u_xlat4.y + 0.0199999996;
        u_xlat19 = u_xlat19 * 3.12499976;
        u_xlat19 = clamp(u_xlat19, 0.0, 1.0);
        u_xlat57 = u_xlat19 * -2.0 + 3.0;
        u_xlat19 = u_xlat19 * u_xlat19;
        u_xlat19 = u_xlat19 * u_xlat57;
        u_xlat1.x = u_xlat19 * u_xlat1.x;
        u_xlat1.x = u_xlat1.x * 0.800000012;
        u_xlat11 = (-u_xlat11) * float4(7.5, 7.5, 7.5, 7.5) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat11 = u_xlat1.xxxx * u_xlat11;
        u_xlat13 = (-u_xlat9) * float4(0.850000024, 0.850000024, 0.850000024, 0.850000024) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat13 = u_xlat13 * float4(0.400000006, 0.400000006, 0.400000006, 0.400000006) + u_xlat10;
        u_xlat12 = u_xlat11 * u_xlat13 + u_xlat12;
    }
    if(u_xlati38 != 0) {
        u_xlati1 = int(u._iteration.y);
        u_xlat19 = _cur_time * 1.5;
        u_xlat2.xy = float2(u_xlat19) * float2(u._scroll.x, u._scroll.y) + u_xlat2.xy;
        u_xlat2.xy = u_xlat2.xy * float2(float2(u._scale, u._scale));
        u_xlat19 = _cur_time * u._speed;
        u_xlat11.x = sin(u._direction);
        u_xlat13.x = cos(u._direction);
        u_xlat14.x = sin((-u._direction));
        u_xlat14.y = u_xlat13.x;
        u_xlat14.z = u_xlat11.x;
        u_xlat11.xy = u_xlat2.xy;
        u_xlat13.x = float(0.0);
        u_xlat13.z = float(0.0);
        u_xlat47.x = float(1.0);
        u_xlat47.y = float(0.0);
        u_xlat38 = 1.0;
        u_xlat57 = u._frequency;
        u_xlat58 = u_xlat19;
        u_xlati23 = 0;
        while(true){
            u_xlatb60 = u_xlati23>=u_xlati1;
            if(u_xlatb60){break;}
            u_xlat15.x = dot(u_xlat14.yz, u_xlat47.xy);
            u_xlat15.y = dot(u_xlat14.xy, u_xlat47.xy);
            u_xlat60 = dot(u_xlat15.xy, u_xlat11.xy);
            u_xlat60 = u_xlat60 * u_xlat57 + u_xlat58;
            u_xlat16.x = sin(u_xlat60);
            u_xlat17.x = cos(u_xlat60);
            u_xlat60 = u_xlat16.x + -1.0;
            u_xlat60 = u_xlat60 * 1.44269502;
            u_xlat60 = exp2(u_xlat60);
            u_xlat60 = u_xlat17.x * u_xlat60;
            u_xlat60 = u_xlat38 * u_xlat60;
            u_xlat31.xz = u_xlat15.xy * float2(u_xlat60);
            u_xlat60 = log2(u_xlat38);
            u_xlat60 = u_xlat60 * u._detail;
            u_xlat60 = exp2(u_xlat60);
            u_xlat51.xy = u_xlat31.xz / float2(u_xlat60);
            u_xlat13.xz = u_xlat13.xz + u_xlat51.xy;
            u_xlat57 = u_xlat57 * 1.20000005;
            u_xlat58 = u_xlat58 * 1.09500003;
            u_xlat11.xy = (-u_xlat31.xz) * float2(float2(u._drag, u._drag)) + u_xlat11.xy;
            u_xlat38 = u_xlat38 * 0.800000012;
            u_xlati23 = u_xlati23 + 1;
            u_xlat47.xy = u_xlat15.xy;
        }
        u_xlat1.x = trunc(u._iteration.y);
        u_xlat1.x = u_xlat1.x * -0.321928084;
        u_xlat1.x = exp2(u_xlat1.x);
        u_xlat1.x = u_xlat1.x + -1.0;
        u_xlat1.x = (-u_xlat1.x) / u._height;
        u_xlat19 = (-u._detail) + 1.0;
        u_xlat1.x = log2(u_xlat1.x);
        u_xlat1.x = u_xlat1.x * u_xlat19;
        u_xlat1.x = exp2(u_xlat1.x);
        u_xlat1.xy = u_xlat13.xz / u_xlat1.xx;
        u_xlat2.xz = (-u_xlat1.xy);
        u_xlat2.y = 1.0;
        u_xlat1.x = dot(u_xlat2.xyz, u_xlat2.xyz);
        u_xlat1.x = rsqrt(u_xlat1.x);
        u_xlat2.xyz = u_xlat1.xxx * u_xlat2.xyz;
        u_xlat1.x = dot(u_xlat4.xyz, u_xlat2.xyz);
        u_xlat19 = u_xlat1.x + u_xlat1.x;
        u_xlat11.yzw = u_xlat2.xyz * (-float3(u_xlat19)) + u_xlat4.xyz;
        u_xlat11.x = abs(u_xlat11.z);
        u_xlat19 = (-u_xlat1.x) * u_xlat1.x + 1.0;
        u_xlat19 = (-u_xlat19) * 0.565323055 + 1.0;
        u_xlat57 = sqrt(u_xlat19);
        u_xlat1.x = u_xlat1.x * 0.751879692 + u_xlat57;
        u_xlatb19 = u_xlat19>=0.0;
        u_xlat13.xyz = u_xlat2.xyz * u_xlat1.xxx;
        u_xlat13.xyz = u_xlat4.xyz * float3(0.751879692, 0.751879692, 0.751879692) + (-u_xlat13.xyz);
        u_xlat13.xyz = bool(u_xlatb19) ? u_xlat13.xyz : float3(0.0, 0.0, 0.0);
        u_xlat1.x = dot((-u_xlat2.xyz), u_xlat4.xyz);
        u_xlat1.x = max(u_xlat1.x, 0.0);
        u_xlat1.x = (-u_xlat1.x) + 1.0;
        u_xlat19 = u_xlat1.x * u_xlat1.x;
        u_xlat19 = u_xlat19 * u_xlat19;
        u_xlat1.x = u_xlat19 * u_xlat1.x;
        u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
        u_xlat2.z = cos((-u._sun_position.xxyx.y));
        if(int(u._reflection_source) == 0) {
            u_xlat14.y = dot(u_xlat5.zw, u_xlat11.xw);
            u_xlat5.y = dot(u_xlat5.xz, u_xlat11.xw);
            u_xlat5.x = u_xlat11.y;
            u_xlat14.x = dot(u_xlat6.xy, u_xlat5.xy);
            u_xlat19 = dot(u_xlat6.zx, u_xlat5.xy);
            u_xlat19 = u_xlat19 * 0.5 + 0.5;
            u_xlat57 = dot(u_xlat14.xy, u_xlat14.xy);
            u_xlat57 = sqrt(u_xlat57);
            u_xlat22 = (-u_xlat0.x) + u_xlat57;
            u_xlat22 = (-u_xlat0.w) + u_xlat22;
            u_xlat0.x = u_xlat0.x + u_xlat57;
            u_xlat0.x = u_xlat0.w + u_xlat0.x;
            u_xlat0.x = (-u_xlat22) + u_xlat0.x;
            u_xlat54 = u._radius * 0.100000001 + (-u_xlat22);
            u_xlat0.x = float(1.0) / u_xlat0.x;
            u_xlat0.x = u_xlat0.x * u_xlat54;
            u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
            u_xlat54 = u_xlat0.x * -2.0 + 3.0;
            u_xlat0.x = u_xlat0.x * u_xlat0.x;
            u_xlat0.x = u_xlat0.x * u_xlat54;
            u_xlat5 = u_xlat10 * u_xlat0.xxxx;
            u_xlat5 = float4(u_xlat19) * u_xlat5;
            u_xlat14 = u_xlat5 + u_xlat5;
            u_xlat0.x = log2(u_xlat57);
            u_xlat0.x = u_xlat0.x * u._intensity;
            u_xlat0.x = exp2(u_xlat0.x);
            u_xlat0.x = u._radius * 0.100000001 + u_xlat0.x;
            u_xlat0.x = u_xlat18.x / u_xlat0.x;
            u_xlat15 = u_xlat10 * u_xlat0.xxxx;
            u_xlat14 = u_xlat15 * float4(u_xlat19) + u_xlat14;
            u_xlat0.x = dot(u_xlat14, u_xlat14);
            u_xlat0.x = sqrt(u_xlat0.x);
            u_xlat0.x = (-u_xlat0.x) + 1.0;
            u_xlat0.x = max(u_xlat0.x, 0.0);
            u_xlat7 = u_xlat7 + (-u_xlat14);
            u_xlat7 = u_xlat0.xxxx * u_xlat7 + u_xlat14;
            u_xlat7 = u_xlat7 * float4(0.200000003, 0.200000003, 0.200000003, 0.200000003) + u_xlat14;
            if(u_xlatb36){
                u_xlat0.x = u_xlat11.w * 0.400000006;
                u_xlat18.xy = float2(float2(_cur_time, _cur_time)) * float2(0.00700000022, 0.0199999996);
                u_xlat0.y = u_xlat11.y * 0.400000006 + u_xlat18.x;
                u_xlat14.xy = u_xlat0.yx;
                u_xlat0.w = 0.0;
                u_xlat14.z = u_xlat11.x;
                u_xlat19 = 200.0;
                while(true){
                    u_xlatb57 = 10.0>=u_xlat19;
                    if(u_xlatb57){break;}
                    u_xlat15.x = sin(u_xlat19);
                    u_xlat16.x = cos(u_xlat19);
                    u_xlat17.x = sin((-u_xlat19));
                    u_xlat17.y = u_xlat16.x;
                    u_xlat17.z = u_xlat15.x;
                    u_xlat15.x = dot(u_xlat17.yz, u_xlat14.xy);
                    u_xlat15.z = dot(u_xlat17.xy, u_xlat14.xy);
                    u_xlat15.y = u_xlat14.z;
                    u_xlat14.xyz = float3(u_xlat19) + u_xlat15.xzy;
                    u_xlat15.xyz = u_xlat14.xzy * float3(u_xlat19) + u_xlat18.yyy;
                    u_xlat15.xyz = sin(u_xlat15.xyz);
                    u_xlat15.xyz = u_xlat15.xyz / float3(u_xlat19);
                    u_xlat57 = dot(u_xlat15.xyz, float3(1.64999998, 1.64999998, 1.64999998));
                    u_xlat0.w = u_xlat0.w + abs(u_xlat57);
                    u_xlat19 = u_xlat19 * 0.800000012;
                }
                u_xlat0.x = u_xlat0.w + -0.595000029;
                u_xlat0.x = u_xlat0.x * -10.000001;
                u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
                u_xlat18.x = u_xlat0.x * -2.0 + 3.0;
                u_xlat0.x = u_xlat0.x * u_xlat0.x;
                u_xlat0.x = u_xlat0.x * u_xlat18.x;
                u_xlat18.x = u_xlat11.x + 0.0199999996;
                u_xlat18.x = u_xlat18.x * 3.12499976;
                u_xlat0.y = min(u_xlat18.x, 1.0);
                u_xlat36 = u_xlat0.y * -2.0 + 3.0;
                u_xlat0.xy = u_xlat0.xy * u_xlat0.wy;
                u_xlat18.x = u_xlat0.y * u_xlat36;
                u_xlat0.x = u_xlat18.x * u_xlat0.x;
                u_xlat0.x = u_xlat0.x * 0.800000012;
                u_xlat5 = (-u_xlat5) * float4(7.5, 7.5, 7.5, 7.5) + float4(1.0, 1.0, 1.0, 1.0);
                u_xlat0 = u_xlat0.xxxx * u_xlat5;
                u_xlat5 = (-u_xlat9) * float4(0.850000024, 0.850000024, 0.850000024, 0.850000024) + float4(1.0, 1.0, 1.0, 1.0);
                u_xlat5 = u_xlat5 * float4(0.400000006, 0.400000006, 0.400000006, 0.400000006) + u_xlat10;
                u_xlat7 = u_xlat0 * u_xlat5 + u_xlat7;
            }
            u_xlat0 = u_xlat1.xxxx * u_xlat7;
            u_xlat0 = u_xlat0 * float4(u._reflection);
        } else {
            u_xlat5.xyz = u_xlat11.xwy + u._reflection_dir.yzx;
            u_xlat19 = dot(u_xlat5.xyz, u_xlat5.xyz);
            u_xlat19 = rsqrt(u_xlat19);
            u_xlat5.xyz = float3(u_xlat19) * u_xlat5.xyz;
            u_xlat19 = -abs(u_xlat5.x) + 1.0;
            u_xlat19 = sqrt(u_xlat19);
            u_xlat57 = abs(u_xlat5.x) * -0.0187292993 + 0.0742610022;
            u_xlat57 = u_xlat57 * abs(u_xlat5.x) + -0.212114394;
            u_xlat57 = u_xlat57 * abs(u_xlat5.x) + 1.57072878;
            u_xlat22 = u_xlat19 * u_xlat57;
            u_xlat22 = u_xlat22 * -2.0 + 3.14159274;
            u_xlatb5.xw = lessThan(u_xlat5.xxxz, (-u_xlat5.xxxz)).xw;
            u_xlat22 = u_xlatb5.x ? u_xlat22 : float(0.0);
            u_xlat25.y = u_xlat57 * u_xlat19 + u_xlat22;
            u_xlat19 = min(abs(u_xlat5.z), abs(u_xlat5.y));
            u_xlat57 = max(abs(u_xlat5.z), abs(u_xlat5.y));
            u_xlat57 = float(1.0) / u_xlat57;
            u_xlat19 = u_xlat19 * u_xlat57;
            u_xlat57 = u_xlat19 * u_xlat19;
            u_xlat22 = u_xlat57 * 0.0208350997 + -0.0851330012;
            u_xlat22 = u_xlat57 * u_xlat22 + 0.180141002;
            u_xlat22 = u_xlat57 * u_xlat22 + -0.330299497;
            u_xlat57 = u_xlat57 * u_xlat22 + 0.999866009;
            u_xlat22 = u_xlat19 * u_xlat57;
            u_xlatb58 = abs(u_xlat5.z)<abs(u_xlat5.y);
            u_xlat22 = u_xlat22 * -2.0 + 1.57079637;
            u_xlat22 = u_xlatb58 ? u_xlat22 : float(0.0);
            u_xlat19 = u_xlat19 * u_xlat57 + u_xlat22;
            u_xlat57 = u_xlatb5.w ? -3.14159274 : float(0.0);
            u_xlat19 = u_xlat19 + u_xlat57;
            u_xlat57 = min(u_xlat5.z, u_xlat5.y);
            u_xlat22 = max(u_xlat5.z, u_xlat5.y);
            u_xlatb57 = u_xlat57<(-u_xlat57);
            u_xlatb22 = u_xlat22>=(-u_xlat22);
            u_xlatb57 = u_xlatb57 && u_xlatb22;
            u_xlat25.x = (u_xlatb57) ? (-u_xlat19) : u_xlat19;
            u_xlat5.yz = (-u_xlat25.xy) * float2(0.159154952, 0.318309903) + float2(0.5, 1.0);
            u_xlatb19 = 1.0>=u_xlat5.y;
            if(u_xlatb19){
                u_xlatb19 = u_xlat5.y>=(-u_xlat5.y);
                u_xlat57 = fract(abs(u_xlat5.y));
                u_xlat5.x = (u_xlatb19) ? u_xlat57 : (-u_xlat57);
                u_xlat5.xyz = panoramic_texture.sample(__nv_smp, u_xlat5.xz).xyz;
            } else {
                u_xlat5.x = float(0.0);
                u_xlat5.y = float(0.0);
                u_xlat5.z = float(0.0);
            }
            u_xlat5.xyz = u_xlat1.xxx * u_xlat5.xyz;
            u_xlat0.xyz = u_xlat5.xyz * float3(u._reflection);
            u_xlat0.w = 0.0;
        }
        u_xlat2.x = u_xlat6.z;
        u_xlat2.y = 0.150000006;
        u_xlat1.x = dot(u_xlat13.xyz, u_xlat2.xyz);
        u_xlat1.x = max(u_xlat1.x, 0.0);
        u_xlat1.x = log2(u_xlat1.x);
        u_xlat1.x = u_xlat1.x * 35.0;
        u_xlat1.x = exp2(u_xlat1.x);
        u_xlat5 = u_xlat8 * float4(0.5, 0.5, 0.5, 0.5) + float4(0.5, 0.5, 0.5, 0.5);
        u_xlat5 = log2(u_xlat5);
        u_xlat5 = u_xlat5 * float4(2.20000005, 2.20000005, 2.20000005, 2.20000005);
        u_xlat5 = exp2(u_xlat5);
        u_xlat5 = u_xlat1.xxxx * u_xlat5;
        u_xlat0 = u_xlat5 * float4(2.5, 2.5, 2.5, 2.5) + u_xlat0;
        u_xlat1.x = dot(u_xlat6.zx, u_xlat4.xz);
        u_xlat2.xyz = u._base_color.xyz * u_xlat3.xyz + float3(0.899999976, 0.899999976, 0.899999976);
        u_xlat2.xyz = float3(u_xlat37) * u_xlat2.xyz;
        u_xlat2.xyz = cos(u_xlat2.xyz);
        u_xlat2.xyz = u_xlat2.xyz * float3(0.5, 0.5, 0.5) + float3(0.400000006, 0.400000006, 0.400000006);
        u_xlat2.xyz = max(u_xlat2.xyz, float3(0.0, 0.0, 0.0));
        u_xlat19 = u_xlat2.w * 0.699999988 + 0.899999976;
        u_xlat19 = min(u_xlat19, 1.79999995);
        u_xlat19 = u_xlat19 * u_xlat19;
        u_xlat19 = u_xlat19 * u_xlat19;
        u_xlat19 = u_xlat19 * 0.400000006;
        u_xlat37 = dot(u_xlat12, u_xlat12);
        u_xlat37 = sqrt(u_xlat37);
        u_xlat19 = u_xlat37 * u_xlat19;
        u_xlat1.x = u_xlat1.x * 0.150000006 + 0.850000024;
        u_xlat1.x = u_xlat1.x * u_xlat19;
        u_xlat2.xyz = u_xlat1.xxx * u_xlat2.xyz;
        u_xlat2.w = 1.0;
        u_xlat0 = u_xlat2 * float4(float4(u._opacity, u._opacity, u._opacity, u._opacity)) + u_xlat0;
        u_xlat1.x = u._feather * 100.0;
        u_xlat1.x = u_xlat55 / u_xlat1.x;
        u_xlat2 = (-u_xlat0) + u_xlat12;
        u_xlat0 = u_xlat1.xxxx * u_xlat2 + u_xlat0;
        u_xlat1 = (-u_xlat0) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat1 * u._background_color + u_xlat0;
    } else {
        u_xlatb1 = 0<int(u._enable_sky);
        u_xlat2 = (-u_xlat12) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat2 = u_xlat2 * u._background_color + u_xlat12;
        u_xlat0 = bool(u_xlatb1) ? u_xlat2 : float4(0.0, 0.0, 0.0, 0.0);
    }
    u_xlat1.xyz = u_xlat0.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat0.xyz = u_xlat0.xyz * u_xlat1.xyz;
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
