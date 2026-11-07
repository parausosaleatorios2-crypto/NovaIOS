// ---------------------------------------------------------------------------
// Droplets (NV)
// origem : assets/effects/nv-nodevideo-assetstore-droplets.xml
// id     : nv.effect.nodevideo-assetstore-droplets
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_dropletsParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _evolution;
    float _size;
    float _density;
    float _spread;
    float3 _position;
    float3 _rotation;
    float _blend;
    float _distortion;
    float _noise_scale;
    float3 _light_pos;
    float _seed;
    float4 _diffuse_color;
    float4 _rim_color;
    float _enable_lighting;
    float _diffusion;
    float _rim;
    float _refraction;
    float _reflection;
    float _fade;
    float _intensity;
    float _tex_scale;
    float2 _tex_offset;
    float _turbulence;
    float _depth;
    float _reflectionenvironment;
    float _environment_texture;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
// O Node lê o ambiente num cubemap; aqui ele chega como imagem 2D: a direção vira a UV equirretangular (0.910.0).
float2 acDirParaUv(float3 d) { d = normalize(d); return float2(__nv_atan(d.x, d.z) * 0.15915494 + 0.5, acos(clamp(d.y, -1.0, 1.0)) * 0.31830989); }
float4 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
bool u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
int u_xlati4;
bool2 u_xlatb4;
float4 u_xlat5;
bool u_xlatb5;
float3 u_xlat6;
bool4 u_xlatb6;
float4 u_xlat7;
bool2 u_xlatb7;
float4 u_xlat8;
float3 u_xlat9;
float3 u_xlat10;
float3 u_xlat11;
bool u_xlatb11;
float4 u_xlat12;
float4 u_xlat13;
float3 u_xlat14;
float4 u_xlat15;
float4 u_xlat16;
float3 u_xlat17;
float3 u_xlat18;
float3 u_xlat20;
float3 u_xlat21;
float3 u_xlat22;
bool u_xlatb22;
float3 u_xlat23;
int u_xlati23;
bool u_xlatb23;
float u_xlat24;
bool u_xlatb24;
float3 u_xlat25;
int u_xlati27;
bool u_xlatb27;
float3 u_xlat31;
float3 u_xlat32;
float3 u_xlat33;
float u_xlat41;
bool u_xlatb41;
float2 u_xlat42;
int u_xlati42;
bool2 u_xlatb42;
float2 u_xlat43;
bool2 u_xlatb43;
float2 u_xlat44;
int u_xlati44;
bool2 u_xlatb44;
float2 u_xlat45;
int u_xlati45;
bool2 u_xlatb45;
float u_xlat47;
int u_xlati47;
bool u_xlatb47;
float u_xlat50;
bool u_xlatb50;
float2 u_xlat51;
float u_xlat57;
float u_xlat58;
bool u_xlatb58;
float u_xlat59;
int u_xlati59;
float u_xlat60;
bool u_xlatb60;
float u_xlat61;
bool u_xlatb61;
float u_xlat62;
bool u_xlatb62;
float u_xlat63;
bool u_xlatb63;
float u_xlat64;
float u_xlat65;
bool u_xlatb65;
float u_xlat66;
bool u_xlatb66;
float u_xlat67;
int u_xlati67;
float u_xlat68;
int u_xlati68;
bool u_xlatb68;
float u_xlat69;
float u_xlat71;

fragment float4 fx_nv_nodevideo_assetstore_droplets(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_dropletsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> cubemap1 [[texture(1)]],
    texture2d<float> cubemap2 [[texture(2)]],
    texture2d<float> cubemap3 [[texture(3)]],
    texture2d<float> cubemap4 [[texture(4)]],
    texture2d<float> cubemap5 [[texture(5)]],
    texture2d<float> panoramic_texture [[texture(6)]],
    texture2d<float> Mask [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = _resolution.xxyy * float4(0.5, 0.5, 0.5, 0.5);
    u_xlat0 = in.acScreenNorm.xxyy * _resolution.xxyy + (-u_xlat0);
    u_xlat0 = u_xlat0 / _resolution.yyyy;
    u_xlat1.xyz = u_xlat0.xyy * float3(-1.0, 0.0, 0.0) + float3(0.0, 0.0, 9.30000019);
    u_xlat0.xyz = u_xlat0.zwz * float3(0.0, 1.0, 0.0) + u_xlat1.xyz;
    u_xlat0.xyz = u_xlat0.xyz + float3(-0.0, -0.0, -10.0);
    u_xlat57 = dot(u_xlat0.xyz, u_xlat0.xyz);
    u_xlat1.w = rsqrt(u_xlat57);
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.www;
    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat2.xyz = u._rotation.xyz * float3(6.28318548, 6.28318548, 6.28318548);
    u_xlat3.x = sin(u_xlat2.z);
    u_xlat4.x = cos(u_xlat2.z);
    u_xlat5.x = (-u_xlat3.x);
    u_xlat6.x = cos(u_xlat2.x);
    u_xlat2.x = sin(u_xlat2.x);
    u_xlat7.x = u_xlat3.x * u_xlat6.x;
    u_xlat4.y = (-u_xlat2.x) * u_xlat3.x;
    u_xlat7.y = u_xlat4.x * u_xlat6.x;
    u_xlat5.y = (-u_xlat2.x) * u_xlat4.x;
    u_xlat3.x = sin(u_xlat2.y);
    u_xlat8.x = cos(u_xlat2.y);
    u_xlat9.x = (-u_xlat3.x);
    u_xlat9.y = u_xlat8.x;
    u_xlat10.x = dot(u_xlat4.yx, u_xlat9.xy);
    u_xlat9.z = u_xlat3.x;
    u_xlat3.x = dot(u_xlat4.yx, u_xlat9.yz);
    u_xlat10.y = dot(u_xlat5.yx, u_xlat9.xy);
    u_xlat3.y = dot(u_xlat5.yx, u_xlat9.yz);
    u_xlat10.z = u_xlat6.x * u_xlat9.x;
    u_xlat3.z = u_xlat6.x * u_xlat8.x;
    u_xlat21.xyz = u._position.xyz + float3(-0.000500000024, -0.00400000019, 0.0);
    u_xlat4.xyz = u_xlat21.xyz * float3(100.0, -100.0, 100.0);
    u_xlat5.xy = float2(float2(float2(u._spread, u._spread)));
    u_xlat5.z = u._depth;
    u_xlat60 = _cur_time * u._turbulence;
    u_xlat61 = u._evolution + u._evolution;
    u_xlat6.xy = float2(u._spread, u._density) * float2(4.0, 0.100000001);
    u_xlat62 = float(1.0) / u_xlat6.y;
    u_xlat7.z = u_xlat2.x;
    u_xlat8.x = u._spread * 4.0;
    u_xlat8.z = u._depth * 12.0;
    u_xlat9.y = 0.0;
    u_xlat25.x = float(0.0);
    u_xlat25.y = float(0.0);
    u_xlat63 = float(0.0);
    u_xlati27 = 0;
    while(true){
        u_xlatb65 = as_type<int>(u_xlat25.y)>=80;
        u_xlati27 = 0;
        if(u_xlatb65){break;}
        u_xlat11.xyz = u_xlat1.xyz * float3(u_xlat63);
        u_xlat65 = u_xlat21.z * 100.0 + u_xlat11.z;
        u_xlat11.xy = u_xlat21.xy * float2(100.0, -100.0) + u_xlat11.xy;
        u_xlat11.z = u_xlat65 + 10.0;
        u_xlat12.x = dot(u_xlat11.xyz, u_xlat10.xyz);
        u_xlat12.y = dot(u_xlat11.xyz, u_xlat7.xyz);
        u_xlat12.z = dot(u_xlat11.xyz, u_xlat3.xyz);
        u_xlat11.xyz = u_xlat5.xyz * float3(2.0, 2.0, 6.0) + u_xlat12.xyz;
        u_xlat13.xyz = u_xlat11.xyz / u_xlat8.xxz;
        u_xlat13.xyz = floor(u_xlat13.xyz);
        u_xlat11.xyz = (-u_xlat8.xxz) * u_xlat13.xyz + u_xlat11.xyz;
        u_xlat11.xyz = (-u_xlat5.yyz) * float3(2.0, 2.0, 6.0) + u_xlat11.xyz;
        u_xlat13.z = u_xlat12.z;
        u_xlat65 = 100.0;
        for(int u_xlati_loop_1 = int(0xFFFFFFFFu) ; u_xlati_loop_1<=1 ; u_xlati_loop_1++)
        {
            u_xlat66 = float(u_xlati_loop_1);
            u_xlat13.x = u_xlat66 * u_xlat6.x + u_xlat12.x;
            u_xlat67 = u_xlat65;
            for(int u_xlati_loop_2 = int(0xFFFFFFFFu) ; u_xlati_loop_2<=1 ; u_xlati_loop_2++)
            {
                u_xlat50 = float(u_xlati_loop_2);
                u_xlat13.y = u_xlat50 * u_xlat6.x + u_xlat12.y;
                u_xlat14.xyz = u_xlat5.yyz * float3(2.0, 2.0, 6.0) + u_xlat13.xyz;
                u_xlat14.xyz = u_xlat14.xyz / u_xlat8.xxz;
                u_xlat14.xyz = floor(u_xlat14.xyz);
                u_xlat69 = dot(u_xlat14.xyz, float3(1.0, 10.0, 100.0));
                u_xlat32.x = u_xlat69 * u._seed;
                u_xlat14.xyz = u_xlat32.xxx * float3(0.103100002, 0.103, 0.0973000005);
                u_xlat14.xyz = fract(u_xlat14.xyz);
                u_xlat15.xyz = u_xlat14.yzx + float3(33.3300018, 33.3300018, 33.3300018);
                u_xlat32.x = dot(u_xlat14.xyz, u_xlat15.xyz);
                u_xlat14.xyz = u_xlat32.xxx + u_xlat14.xyz;
                u_xlat32.xz = u_xlat14.yz + u_xlat14.xx;
                u_xlat32.xz = u_xlat14.zy * u_xlat32.xz;
                u_xlat32.xz = fract(u_xlat32.xz);
                u_xlat14.x = u_xlat69 * u_xlat32.x;
                u_xlat14.x = u_xlat14.x * 4.0 + u_xlat61;
                u_xlat14.x = sin(u_xlat14.x);
                u_xlat14.x = u_xlat14.x * 0.5 + 0.5;
                u_xlat14.z = u_xlat14.x * 3.0 + -6.0;
                u_xlat71 = (-u_xlat14.z) + -3.0;
                u_xlat71 = (-u_xlat71) * 0.333333343 + 1.0;
                u_xlat71 = log2(u_xlat71);
                u_xlat71 = u_xlat62 * u_xlat71;
                u_xlat71 = exp2(u_xlat71);
                u_xlat71 = u_xlat71 * u._size;
                u_xlat32.xz = u_xlat32.xz * float2(1.5, 1.5);
                u_xlat69 = u_xlat14.z * 3.0 + u_xlat69;
                u_xlat15.x = sin(u_xlat69);
                u_xlat16.x = cos(u_xlat69);
                u_xlat69 = u_xlat16.x * 0.400000006 + u_xlat32.x;
                u_xlat32.x = u_xlat15.x * 0.400000006 + u_xlat32.z;
                u_xlat14.x = u_xlat66 * u_xlat6.x + u_xlat69;
                u_xlat14.y = u_xlat50 * u_xlat6.x + u_xlat32.x;
                u_xlat14.xyz = u_xlat11.xyz + (-u_xlat14.xyz);
                u_xlat50 = dot(u_xlat14.xyz, u_xlat14.xyz);
                u_xlat50 = sqrt(u_xlat50);
                u_xlat50 = (-u_xlat71) * 1.20000005 + u_xlat50;
                u_xlat67 = min(u_xlat67, u_xlat50);
            }
            u_xlat65 = u_xlat67;
        }
        u_xlat11.xyz = u_xlat11.xyz * float3(float3(u._noise_scale, u._noise_scale, u._noise_scale)) + float3(u_xlat60);
        u_xlat12.xyz = floor(u_xlat11.xyz);
        u_xlat11.xyz = fract(u_xlat11.xyz);
        u_xlat13.xyz = u_xlat11.xyz * float3(-2.0, -2.0, -2.0) + float3(3.0, 3.0, 3.0);
        u_xlat11.xyz = u_xlat11.xyz * u_xlat11.xyz;
        u_xlat11.xyz = u_xlat11.xyz * u_xlat13.xyz;
        u_xlat47 = u_xlat12.y * 57.0 + u_xlat12.x;
        u_xlat47 = u_xlat12.z * 113.0 + u_xlat47;
        u_xlat66 = cos(u_xlat47);
        u_xlat66 = u_xlat66 * 41415.9258;
        u_xlat66 = fract(u_xlat66);
        u_xlat12 = float4(u_xlat47) + float4(1.0, 57.0, 58.0, 113.0);
        u_xlat12 = cos(u_xlat12);
        u_xlat12 = u_xlat12 * float4(41415.9258, 41415.9258, 41415.9258, 41415.9258);
        u_xlat12 = fract(u_xlat12);
        u_xlat68 = (-u_xlat66) + u_xlat12.x;
        u_xlat66 = u_xlat11.x * u_xlat68 + u_xlat66;
        u_xlat68 = (-u_xlat12.y) + u_xlat12.z;
        u_xlat68 = u_xlat11.x * u_xlat68 + u_xlat12.y;
        u_xlat68 = (-u_xlat66) + u_xlat68;
        u_xlat66 = u_xlat11.y * u_xlat68 + u_xlat66;
        u_xlat12.xyz = float3(u_xlat47) + float3(114.0, 170.0, 171.0);
        u_xlat12.xyz = cos(u_xlat12.xyz);
        u_xlat12.xyz = u_xlat12.xyz * float3(41415.9258, 41415.9258, 41415.9258);
        u_xlat12.xyz = fract(u_xlat12.xyz);
        u_xlat47 = (-u_xlat12.w) + u_xlat12.x;
        u_xlat47 = u_xlat11.x * u_xlat47 + u_xlat12.w;
        u_xlat68 = (-u_xlat12.y) + u_xlat12.z;
        u_xlat11.x = u_xlat11.x * u_xlat68 + u_xlat12.y;
        u_xlat11.x = (-u_xlat47) + u_xlat11.x;
        u_xlat47 = u_xlat11.y * u_xlat11.x + u_xlat47;
        u_xlat47 = (-u_xlat66) + u_xlat47;
        u_xlat47 = u_xlat11.z * u_xlat47 + u_xlat66;
        u_xlat47 = u_xlat47 * u._distortion + u_xlat65;
        u_xlatb66 = u_xlat47<0.0;
        if(u_xlatb66){
            u_xlati27 = 0;
            break;
        }
        u_xlat66 = u_xlat63 + u_xlat47;
        u_xlatb11 = 100.0<u_xlat66;
        if(u_xlatb11){
            u_xlat25.x = -1.0;
            u_xlat63 = u_xlat66;
            u_xlati27 = int(0xFFFFFFFFu);
            break;
        }
        u_xlatb47 = u_xlat47<0.100000001;
        if(u_xlatb47){
            u_xlat25.x = 0.0;
            u_xlat63 = u_xlat66;
            u_xlati27 = 0;
            break;
        }
        u_xlat63 = u_xlat66;
        u_xlatb27 = u_xlatb11;
        u_xlat9.x = as_type<float>(as_type<int>(u_xlat25.y) + 1);
        u_xlat25.xy = u_xlat9.yx;
    }
    u_xlat44.x = min(u_xlat63, 100.0);
    u_xlat25.x = (u_xlati27 != 0) ? u_xlat25.x : u_xlat44.x;
    u_xlatb44.x = u_xlat25.x<0.0;
    if(u_xlatb44.x){
        u_xlat8 = u_xlat0;
    } else {
        u_xlat44.xy = u_xlat1.xy * u_xlat25.xx;
        u_xlat9.xyz = u_xlat1.xyz * u_xlat25.xxx + float3(0.0, 0.0, 10.0);
        u_xlat11.xyz = u._light_pos.xyz * float3(10.0, 10.0, 10.0) + float3(0.0, 0.0, 10.0);
        u_xlat11.xyz = (-u_xlat9.xyz) + u_xlat11.xyz;
        u_xlat45.x = dot(u_xlat11.xyz, u_xlat11.xyz);
        u_xlat45.x = rsqrt(u_xlat45.x);
        u_xlat11.xyz = u_xlat45.xxx * u_xlat11.xyz;
        u_xlat12.xyz = u_xlat21.xyz * float3(100.0, -100.0, 100.0) + u_xlat9.xyz;
        u_xlat13.x = dot(u_xlat12.xyz, u_xlat10.xyz);
        u_xlat7.w = u_xlat2.x;
        u_xlat13.y = dot(u_xlat12.xyz, u_xlat7.xyw);
        u_xlat13.z = dot(u_xlat12.xyz, u_xlat3.xyz);
        u_xlat12.xyz = u_xlat5.xyz * float3(2.0, 2.0, 6.0) + u_xlat13.xyz;
        u_xlat14.x = u._spread * 4.0;
        u_xlat14.z = u._depth * 12.0;
        u_xlat15.xyz = u_xlat12.xyz / u_xlat14.xxz;
        u_xlat15.xyz = floor(u_xlat15.xyz);
        u_xlat12.xyz = (-u_xlat14.xxz) * u_xlat15.xyz + u_xlat12.xyz;
        u_xlat12.xyz = (-u_xlat5.yyz) * float3(2.0, 2.0, 6.0) + u_xlat12.xyz;
        u_xlat15.z = u_xlat13.z;
        u_xlat2.x = float(100.0);
        for(int u_xlati_loop_3 = int(int(0xFFFFFFFFu)) ; u_xlati_loop_3<=1 ; u_xlati_loop_3++)
        {
            u_xlat45.x = float(u_xlati_loop_3);
            u_xlat15.x = u_xlat45.x * u_xlat6.x + u_xlat13.x;
            u_xlat66 = u_xlat2.x;
            for(int u_xlati_loop_4 = int(0xFFFFFFFFu) ; u_xlati_loop_4<=1 ; u_xlati_loop_4++)
            {
                u_xlat68 = float(u_xlati_loop_4);
                u_xlat15.y = u_xlat68 * u_xlat6.x + u_xlat13.y;
                u_xlat16.xyz = u_xlat5.yyz * float3(2.0, 2.0, 6.0) + u_xlat15.xyz;
                u_xlat16.xyz = u_xlat16.xyz / u_xlat14.xxz;
                u_xlat16.xyz = floor(u_xlat16.xyz);
                u_xlat69 = dot(u_xlat16.xyz, float3(1.0, 10.0, 100.0));
                u_xlat51.x = u_xlat69 * u._seed;
                u_xlat16.xyz = u_xlat51.xxx * float3(0.103100002, 0.103, 0.0973000005);
                u_xlat16.xyz = fract(u_xlat16.xyz);
                u_xlat17.xyz = u_xlat16.yzx + float3(33.3300018, 33.3300018, 33.3300018);
                u_xlat51.x = dot(u_xlat16.xyz, u_xlat17.xyz);
                u_xlat16.xyz = u_xlat51.xxx + u_xlat16.xyz;
                u_xlat51.xy = u_xlat16.yz + u_xlat16.xx;
                u_xlat51.xy = u_xlat16.zy * u_xlat51.xy;
                u_xlat51.xy = fract(u_xlat51.xy);
                u_xlat33.x = u_xlat69 * u_xlat51.x;
                u_xlat33.x = u_xlat33.x * 4.0 + u_xlat61;
                u_xlat33.x = sin(u_xlat33.x);
                u_xlat33.x = u_xlat33.x * 0.5 + 0.5;
                u_xlat16.z = u_xlat33.x * 3.0 + -6.0;
                u_xlat33.x = (-u_xlat16.z) + -3.0;
                u_xlat33.x = (-u_xlat33.x) * 0.333333343 + 1.0;
                u_xlat33.x = log2(u_xlat33.x);
                u_xlat33.x = u_xlat62 * u_xlat33.x;
                u_xlat33.x = exp2(u_xlat33.x);
                u_xlat33.x = u_xlat33.x * u._size;
                u_xlat51.xy = u_xlat51.xy * float2(1.5, 1.5);
                u_xlat69 = u_xlat16.z * 3.0 + u_xlat69;
                u_xlat17.x = sin(u_xlat69);
                u_xlat18.x = cos(u_xlat69);
                u_xlat69 = u_xlat18.x * 0.400000006 + u_xlat51.x;
                u_xlat51.x = u_xlat17.x * 0.400000006 + u_xlat51.y;
                u_xlat16.x = u_xlat45.x * u_xlat6.x + u_xlat69;
                u_xlat16.y = u_xlat68 * u_xlat6.x + u_xlat51.x;
                u_xlat16.xyz = u_xlat12.xyz + (-u_xlat16.xyz);
                u_xlat68 = dot(u_xlat16.xyz, u_xlat16.xyz);
                u_xlat68 = sqrt(u_xlat68);
                u_xlat68 = (-u_xlat33.x) * 1.20000005 + u_xlat68;
                u_xlat66 = min(u_xlat66, u_xlat68);
            }
            u_xlat2.x = u_xlat66;
        }
        u_xlat12.xyz = u_xlat12.xyz * float3(float3(u._noise_scale, u._noise_scale, u._noise_scale)) + float3(u_xlat60);
        u_xlat13.xyz = floor(u_xlat12.xyz);
        u_xlat12.xyz = fract(u_xlat12.xyz);
        u_xlat15.xyz = u_xlat12.xyz * float3(-2.0, -2.0, -2.0) + float3(3.0, 3.0, 3.0);
        u_xlat12.xyz = u_xlat12.xyz * u_xlat12.xyz;
        u_xlat12.xyz = u_xlat12.xyz * u_xlat15.xyz;
        u_xlat59 = u_xlat13.y * 57.0 + u_xlat13.x;
        u_xlat59 = u_xlat13.z * 113.0 + u_xlat59;
        u_xlat45.x = cos(u_xlat59);
        u_xlat45.x = u_xlat45.x * 41415.9258;
        u_xlat45.x = fract(u_xlat45.x);
        u_xlat13 = float4(u_xlat59) + float4(1.0, 57.0, 58.0, 113.0);
        u_xlat13 = cos(u_xlat13);
        u_xlat13 = u_xlat13 * float4(41415.9258, 41415.9258, 41415.9258, 41415.9258);
        u_xlat13 = fract(u_xlat13);
        u_xlat66 = (-u_xlat45.x) + u_xlat13.x;
        u_xlat45.x = u_xlat12.x * u_xlat66 + u_xlat45.x;
        u_xlat66 = (-u_xlat13.y) + u_xlat13.z;
        u_xlat66 = u_xlat12.x * u_xlat66 + u_xlat13.y;
        u_xlat66 = (-u_xlat45.x) + u_xlat66;
        u_xlat45.x = u_xlat12.y * u_xlat66 + u_xlat45.x;
        u_xlat13.xyz = float3(u_xlat59) + float3(114.0, 170.0, 171.0);
        u_xlat13.xyz = cos(u_xlat13.xyz);
        u_xlat13.xyz = u_xlat13.xyz * float3(41415.9258, 41415.9258, 41415.9258);
        u_xlat13.xyz = fract(u_xlat13.xyz);
        u_xlat59 = (-u_xlat13.w) + u_xlat13.x;
        u_xlat59 = u_xlat12.x * u_xlat59 + u_xlat13.w;
        u_xlat66 = (-u_xlat13.y) + u_xlat13.z;
        u_xlat66 = u_xlat12.x * u_xlat66 + u_xlat13.y;
        u_xlat66 = (-u_xlat59) + u_xlat66;
        u_xlat59 = u_xlat12.y * u_xlat66 + u_xlat59;
        u_xlat59 = (-u_xlat45.x) + u_xlat59;
        u_xlat59 = u_xlat12.z * u_xlat59 + u_xlat45.x;
        u_xlat2.x = u_xlat59 * u._distortion + u_xlat2.x;
        u_xlat12.xyz = u_xlat1.xzz * u_xlat25.xxx + u_xlat4.xzz;
        u_xlat13 = u_xlat44.yxxy;
        u_xlat15.xz = u_xlat12.xy + float2(-0.00999999978, 10.0);
        u_xlat15.y = u_xlat21.y * -100.0 + u_xlat13.x;
        u_xlat16.x = dot(u_xlat15.xyz, u_xlat10.xyz);
        u_xlat16.y = dot(u_xlat15.xyz, u_xlat7.xyw);
        u_xlat16.z = dot(u_xlat15.xyz, u_xlat3.xyz);
        u_xlat12.xyw = u_xlat5.xyz * float3(2.0, 2.0, 6.0) + u_xlat16.xyz;
        u_xlat15.xyz = u_xlat12.xyw / u_xlat14.xxz;
        u_xlat15.xyz = floor(u_xlat15.xyz);
        u_xlat12.xyw = (-u_xlat14.xxz) * u_xlat15.xyz + u_xlat12.xyw;
        u_xlat12.xyw = (-u_xlat5.yyz) * float3(2.0, 2.0, 6.0) + u_xlat12.xyw;
        u_xlat15.z = u_xlat16.z;
        u_xlat59 = 100.0;
        for(int u_xlati_loop_5 = int(0xFFFFFFFFu) ; u_xlati_loop_5<=1 ; u_xlati_loop_5++)
        {
            u_xlat44.x = float(u_xlati_loop_5);
            u_xlat15.x = u_xlat44.x * u_xlat6.x + u_xlat16.x;
            u_xlat63 = u_xlat59;
            for(int u_xlati_loop_6 = int(0xFFFFFFFFu) ; u_xlati_loop_6<=1 ; u_xlati_loop_6++)
            {
                u_xlat66 = float(u_xlati_loop_6);
                u_xlat15.y = u_xlat66 * u_xlat6.x + u_xlat16.y;
                u_xlat17.xyz = u_xlat5.yyz * float3(2.0, 2.0, 6.0) + u_xlat15.xyz;
                u_xlat17.xyz = u_xlat17.xyz / u_xlat14.xxz;
                u_xlat17.xyz = floor(u_xlat17.xyz);
                u_xlat67 = dot(u_xlat17.xyz, float3(1.0, 10.0, 100.0));
                u_xlat68 = u_xlat67 * u._seed;
                u_xlat17.xyz = float3(u_xlat68) * float3(0.103100002, 0.103, 0.0973000005);
                u_xlat17.xyz = fract(u_xlat17.xyz);
                u_xlat18.xyz = u_xlat17.yzx + float3(33.3300018, 33.3300018, 33.3300018);
                u_xlat68 = dot(u_xlat17.xyz, u_xlat18.xyz);
                u_xlat17.xyz = float3(u_xlat68) + u_xlat17.xyz;
                u_xlat33.xz = u_xlat17.yz + u_xlat17.xx;
                u_xlat33.xz = u_xlat17.zy * u_xlat33.xz;
                u_xlat33.xz = fract(u_xlat33.xz);
                u_xlat68 = u_xlat67 * u_xlat33.x;
                u_xlat68 = u_xlat68 * 4.0 + u_xlat61;
                u_xlat68 = sin(u_xlat68);
                u_xlat68 = u_xlat68 * 0.5 + 0.5;
                u_xlat17.z = u_xlat68 * 3.0 + -6.0;
                u_xlat68 = (-u_xlat17.z) + -3.0;
                u_xlat68 = (-u_xlat68) * 0.333333343 + 1.0;
                u_xlat68 = log2(u_xlat68);
                u_xlat68 = u_xlat62 * u_xlat68;
                u_xlat68 = exp2(u_xlat68);
                u_xlat68 = u_xlat68 * u._size;
                u_xlat33.xz = u_xlat33.xz * float2(1.5, 1.5);
                u_xlat67 = u_xlat17.z * 3.0 + u_xlat67;
                u_xlat13.x = sin(u_xlat67);
                u_xlat18.x = cos(u_xlat67);
                u_xlat67 = u_xlat18.x * 0.400000006 + u_xlat33.x;
                u_xlat13.x = u_xlat13.x * 0.400000006 + u_xlat33.z;
                u_xlat17.x = u_xlat44.x * u_xlat6.x + u_xlat67;
                u_xlat17.y = u_xlat66 * u_xlat6.x + u_xlat13.x;
                u_xlat17.xyz = u_xlat12.xyw + (-u_xlat17.xyz);
                u_xlat66 = dot(u_xlat17.xyz, u_xlat17.xyz);
                u_xlat66 = sqrt(u_xlat66);
                u_xlat66 = (-u_xlat68) * 1.20000005 + u_xlat66;
                u_xlat63 = min(u_xlat63, u_xlat66);
            }
            u_xlat59 = u_xlat63;
        }
        u_xlat12.xyw = u_xlat12.xyw * float3(float3(u._noise_scale, u._noise_scale, u._noise_scale)) + float3(u_xlat60);
        u_xlat15.xyz = floor(u_xlat12.xyw);
        u_xlat12.xyw = fract(u_xlat12.xyw);
        u_xlat16.xyz = u_xlat12.xyw * float3(-2.0, -2.0, -2.0) + float3(3.0, 3.0, 3.0);
        u_xlat12.xyw = u_xlat12.xyw * u_xlat12.xyw;
        u_xlat12.xyw = u_xlat12.xyw * u_xlat16.xyz;
        u_xlat4.x = u_xlat15.y * 57.0 + u_xlat15.x;
        u_xlat4.x = u_xlat15.z * 113.0 + u_xlat4.x;
        u_xlat44.x = cos(u_xlat4.x);
        u_xlat44.x = u_xlat44.x * 41415.9258;
        u_xlat44.x = fract(u_xlat44.x);
        u_xlat15 = u_xlat4.xxxx + float4(1.0, 57.0, 58.0, 113.0);
        u_xlat15 = cos(u_xlat15);
        u_xlat15 = u_xlat15 * float4(41415.9258, 41415.9258, 41415.9258, 41415.9258);
        u_xlat15 = fract(u_xlat15);
        u_xlat63 = (-u_xlat44.x) + u_xlat15.x;
        u_xlat44.x = u_xlat12.x * u_xlat63 + u_xlat44.x;
        u_xlat63 = (-u_xlat15.y) + u_xlat15.z;
        u_xlat63 = u_xlat12.x * u_xlat63 + u_xlat15.y;
        u_xlat63 = (-u_xlat44.x) + u_xlat63;
        u_xlat44.x = u_xlat12.y * u_xlat63 + u_xlat44.x;
        u_xlat15.xyz = u_xlat4.xxx + float3(114.0, 170.0, 171.0);
        u_xlat15.xyz = cos(u_xlat15.xyz);
        u_xlat15.xyz = u_xlat15.xyz * float3(41415.9258, 41415.9258, 41415.9258);
        u_xlat15.xyz = fract(u_xlat15.xyz);
        u_xlat4.x = (-u_xlat15.w) + u_xlat15.x;
        u_xlat4.x = u_xlat12.x * u_xlat4.x + u_xlat15.w;
        u_xlat63 = (-u_xlat15.y) + u_xlat15.z;
        u_xlat63 = u_xlat12.x * u_xlat63 + u_xlat15.y;
        u_xlat63 = (-u_xlat4.x) + u_xlat63;
        u_xlat4.x = u_xlat12.y * u_xlat63 + u_xlat4.x;
        u_xlat4.x = (-u_xlat44.x) + u_xlat4.x;
        u_xlat4.x = u_xlat12.w * u_xlat4.x + u_xlat44.x;
        u_xlat15.x = u_xlat4.x * u._distortion + u_xlat59;
        u_xlat4.xy = u_xlat1.yz * u_xlat25.xx + u_xlat4.yz;
        u_xlat16.x = u_xlat21.x * 100.0 + u_xlat13.y;
        u_xlat16.yz = u_xlat4.xy + float2(-0.00999999978, 10.0);
        u_xlat4.x = dot(u_xlat16.xyz, u_xlat10.xyz);
        u_xlat4.y = dot(u_xlat16.xyz, u_xlat7.xyw);
        u_xlat4.z = dot(u_xlat16.xyz, u_xlat3.xyz);
        u_xlat25.xyz = u_xlat5.xyz * float3(2.0, 2.0, 6.0) + u_xlat4.xyz;
        u_xlat12.xyw = u_xlat25.xyz / u_xlat14.xxz;
        u_xlat12.xyw = floor(u_xlat12.xyw);
        u_xlat25.xyz = (-u_xlat14.xxz) * u_xlat12.xyw + u_xlat25.xyz;
        u_xlat25.xyz = (-u_xlat5.yyz) * float3(2.0, 2.0, 6.0) + u_xlat25.xyz;
        u_xlat16.z = u_xlat4.z;
        u_xlat59 = 100.0;
        for(int u_xlati_loop_7 = int(0xFFFFFFFFu) ; u_xlati_loop_7<=1 ; u_xlati_loop_7++)
        {
            u_xlat45.x = float(u_xlati_loop_7);
            u_xlat16.x = u_xlat45.x * u_xlat6.x + u_xlat4.x;
            u_xlat66 = u_xlat59;
            for(int u_xlati_loop_8 = int(0xFFFFFFFFu) ; u_xlati_loop_8<=1 ; u_xlati_loop_8++)
            {
                u_xlat68 = float(u_xlati_loop_8);
                u_xlat16.y = u_xlat68 * u_xlat6.x + u_xlat4.y;
                u_xlat12.xyw = u_xlat5.yyz * float3(2.0, 2.0, 6.0) + u_xlat16.xyz;
                u_xlat12.xyw = u_xlat12.xyw / u_xlat14.xxz;
                u_xlat12.xyw = floor(u_xlat12.xyw);
                u_xlat12.x = dot(u_xlat12.xyw, float3(1.0, 10.0, 100.0));
                u_xlat31.x = u_xlat12.x * u._seed;
                u_xlat17.xyz = u_xlat31.xxx * float3(0.103100002, 0.103, 0.0973000005);
                u_xlat17.xyz = fract(u_xlat17.xyz);
                u_xlat18.xyz = u_xlat17.yzx + float3(33.3300018, 33.3300018, 33.3300018);
                u_xlat31.x = dot(u_xlat17.xyz, u_xlat18.xyz);
                u_xlat17.xyz = u_xlat31.xxx + u_xlat17.xyz;
                u_xlat31.xz = u_xlat17.yz + u_xlat17.xx;
                u_xlat31.xz = u_xlat17.zy * u_xlat31.xz;
                u_xlat31.xz = fract(u_xlat31.xz);
                u_xlat13.x = u_xlat31.x * u_xlat12.x;
                u_xlat13.x = u_xlat13.x * 4.0 + u_xlat61;
                u_xlat13.x = sin(u_xlat13.x);
                u_xlat13.x = u_xlat13.x * 0.5 + 0.5;
                u_xlat17.z = u_xlat13.x * 3.0 + -6.0;
                u_xlat13.x = (-u_xlat17.z) + -3.0;
                u_xlat13.x = (-u_xlat13.x) * 0.333333343 + 1.0;
                u_xlat13.x = log2(u_xlat13.x);
                u_xlat13.x = u_xlat62 * u_xlat13.x;
                u_xlat13.x = exp2(u_xlat13.x);
                u_xlat13.x = u_xlat13.x * u._size;
                u_xlat31.xz = u_xlat31.xz * float2(1.5, 1.5);
                u_xlat12.x = u_xlat17.z * 3.0 + u_xlat12.x;
                u_xlat18.x = cos(u_xlat12.x);
                u_xlat12.x = sin(u_xlat12.x);
                u_xlat31.x = u_xlat18.x * 0.400000006 + u_xlat31.x;
                u_xlat12.x = u_xlat12.x * 0.400000006 + u_xlat31.z;
                u_xlat17.x = u_xlat45.x * u_xlat6.x + u_xlat31.x;
                u_xlat17.y = u_xlat68 * u_xlat6.x + u_xlat12.x;
                u_xlat12.xyw = u_xlat25.xyz + (-u_xlat17.xyz);
                u_xlat68 = dot(u_xlat12.xyw, u_xlat12.xyw);
                u_xlat68 = sqrt(u_xlat68);
                u_xlat68 = (-u_xlat13.x) * 1.20000005 + u_xlat68;
                u_xlat66 = min(u_xlat66, u_xlat68);
            }
            u_xlat59 = u_xlat66;
        }
        u_xlat4.xyz = u_xlat25.xyz * float3(float3(u._noise_scale, u._noise_scale, u._noise_scale)) + float3(u_xlat60);
        u_xlat25.xyz = floor(u_xlat4.xyz);
        u_xlat4.xyz = fract(u_xlat4.xyz);
        u_xlat12.xyw = u_xlat4.xyz * float3(-2.0, -2.0, -2.0) + float3(3.0, 3.0, 3.0);
        u_xlat4.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat4.xyz = u_xlat4.xyz * u_xlat12.xyw;
        u_xlat25.x = u_xlat25.y * 57.0 + u_xlat25.x;
        u_xlat25.x = u_xlat25.z * 113.0 + u_xlat25.x;
        u_xlat44.x = cos(u_xlat25.x);
        u_xlat44.x = u_xlat44.x * 41415.9258;
        u_xlat44.x = fract(u_xlat44.x);
        u_xlat16 = u_xlat25.xxxx + float4(1.0, 57.0, 58.0, 113.0);
        u_xlat16 = cos(u_xlat16);
        u_xlat16 = u_xlat16 * float4(41415.9258, 41415.9258, 41415.9258, 41415.9258);
        u_xlat16 = fract(u_xlat16);
        u_xlat63 = (-u_xlat44.x) + u_xlat16.x;
        u_xlat44.x = u_xlat4.x * u_xlat63 + u_xlat44.x;
        u_xlat63 = (-u_xlat16.y) + u_xlat16.z;
        u_xlat63 = u_xlat4.x * u_xlat63 + u_xlat16.y;
        u_xlat63 = (-u_xlat44.x) + u_xlat63;
        u_xlat44.x = u_xlat4.y * u_xlat63 + u_xlat44.x;
        u_xlat12.xyw = u_xlat25.xxx + float3(114.0, 170.0, 171.0);
        u_xlat12.xyw = cos(u_xlat12.xyw);
        u_xlat12.xyw = u_xlat12.xyw * float3(41415.9258, 41415.9258, 41415.9258);
        u_xlat12.xyw = fract(u_xlat12.xyw);
        u_xlat25.x = (-u_xlat16.w) + u_xlat12.x;
        u_xlat25.x = u_xlat4.x * u_xlat25.x + u_xlat16.w;
        u_xlat63 = (-u_xlat12.y) + u_xlat12.w;
        u_xlat4.x = u_xlat4.x * u_xlat63 + u_xlat12.y;
        u_xlat4.x = (-u_xlat25.x) + u_xlat4.x;
        u_xlat4.x = u_xlat4.y * u_xlat4.x + u_xlat25.x;
        u_xlat4.x = (-u_xlat44.x) + u_xlat4.x;
        u_xlat4.x = u_xlat4.z * u_xlat4.x + u_xlat44.x;
        u_xlat15.y = u_xlat4.x * u._distortion + u_xlat59;
        u_xlat4.xy = u_xlat21.xy * float2(100.0, -100.0) + u_xlat13.zw;
        u_xlat4.z = u_xlat12.z + 9.98999977;
        u_xlat10.x = dot(u_xlat4.xyz, u_xlat10.xyz);
        u_xlat10.y = dot(u_xlat4.xyz, u_xlat7.xyw);
        u_xlat10.z = dot(u_xlat4.xyz, u_xlat3.xyz);
        u_xlat21.xyz = u_xlat5.xyz * float3(2.0, 2.0, 6.0) + u_xlat10.xyz;
        u_xlat3.xyz = u_xlat21.xyz / u_xlat14.xxz;
        u_xlat3.xyz = floor(u_xlat3.xyz);
        u_xlat21.xyz = (-u_xlat14.xxz) * u_xlat3.xyz + u_xlat21.xyz;
        u_xlat21.xyz = (-u_xlat5.yyz) * float3(2.0, 2.0, 6.0) + u_xlat21.xyz;
        u_xlat3.z = u_xlat10.z;
        u_xlat4.x = float(100.0);
        for(int u_xlati_loop_9 = int(int(0xFFFFFFFFu)) ; u_xlati_loop_9<=1 ; u_xlati_loop_9++)
        {
            u_xlat42.x = float(u_xlati_loop_9);
            u_xlat3.x = u_xlat42.x * u_xlat6.x + u_xlat10.x;
            u_xlat25.x = u_xlat4.x;
            for(int u_xlati_loop_10 = int(0xFFFFFFFFu) ; u_xlati_loop_10<=1 ; u_xlati_loop_10++)
            {
                u_xlat63 = float(u_xlati_loop_10);
                u_xlat3.y = u_xlat63 * u_xlat6.x + u_xlat10.y;
                u_xlat7.xyz = u_xlat5.xyz * float3(2.0, 2.0, 6.0) + u_xlat3.xyz;
                u_xlat7.xyz = u_xlat7.xyz / u_xlat14.xxz;
                u_xlat7.xyz = floor(u_xlat7.xyz);
                u_xlat22.x = dot(u_xlat7.xyz, float3(1.0, 10.0, 100.0));
                u_xlat7.x = u_xlat22.x * u._seed;
                u_xlat7.xyz = u_xlat7.xxx * float3(0.103100002, 0.103, 0.0973000005);
                u_xlat7.xyz = fract(u_xlat7.xyz);
                u_xlat12.xyz = u_xlat7.yzx + float3(33.3300018, 33.3300018, 33.3300018);
                u_xlat64 = dot(u_xlat7.xyz, u_xlat12.xyz);
                u_xlat7.xyz = float3(u_xlat64) + u_xlat7.xyz;
                u_xlat7.xw = u_xlat7.yz + u_xlat7.xx;
                u_xlat7.xy = u_xlat7.zy * u_xlat7.xw;
                u_xlat7.xy = fract(u_xlat7.xy);
                u_xlat45.x = u_xlat22.x * u_xlat7.x;
                u_xlat45.x = u_xlat45.x * 4.0 + u_xlat61;
                u_xlat45.x = sin(u_xlat45.x);
                u_xlat45.x = u_xlat45.x * 0.5 + 0.5;
                u_xlat12.z = u_xlat45.x * 3.0 + -6.0;
                u_xlat45.x = (-u_xlat12.z) + -3.0;
                u_xlat45.x = (-u_xlat45.x) * 0.333333343 + 1.0;
                u_xlat45.x = log2(u_xlat45.x);
                u_xlat45.x = u_xlat62 * u_xlat45.x;
                u_xlat45.x = exp2(u_xlat45.x);
                u_xlat45.x = u_xlat45.x * u._size;
                u_xlat7.xy = u_xlat7.xy * float2(1.5, 1.5);
                u_xlat22.x = u_xlat12.z * 3.0 + u_xlat22.x;
                u_xlat13.x = sin(u_xlat22.x);
                u_xlat16.x = cos(u_xlat22.x);
                u_xlat22.x = u_xlat16.x * 0.400000006 + u_xlat7.x;
                u_xlat7.x = u_xlat13.x * 0.400000006 + u_xlat7.y;
                u_xlat12.x = u_xlat42.x * u_xlat6.x + u_xlat22.x;
                u_xlat12.y = u_xlat63 * u_xlat6.x + u_xlat7.x;
                u_xlat7.xyw = u_xlat21.xyz + (-u_xlat12.xyz);
                u_xlat22.x = dot(u_xlat7.xyw, u_xlat7.xyw);
                u_xlat22.x = sqrt(u_xlat22.x);
                u_xlat22.x = (-u_xlat45.x) * 1.20000005 + u_xlat22.x;
                u_xlat25.x = min(u_xlat22.x, u_xlat25.x);
            }
            u_xlat4.x = u_xlat25.x;
        }
        u_xlat21.xyz = u_xlat21.xyz * float3(float3(u._noise_scale, u._noise_scale, u._noise_scale)) + float3(u_xlat60);
        u_xlat3.xyz = floor(u_xlat21.xyz);
        u_xlat21.xyz = fract(u_xlat21.xyz);
        u_xlat23.xyz = u_xlat21.xyz * float3(-2.0, -2.0, -2.0) + float3(3.0, 3.0, 3.0);
        u_xlat21.xyz = u_xlat21.xyz * u_xlat21.xyz;
        u_xlat21.xyz = u_xlat21.xyz * u_xlat23.xyz;
        u_xlat3.x = u_xlat3.y * 57.0 + u_xlat3.x;
        u_xlat3.x = u_xlat3.z * 113.0 + u_xlat3.x;
        u_xlat22.x = cos(u_xlat3.x);
        u_xlat22.x = u_xlat22.x * 41415.9258;
        u_xlat22.x = fract(u_xlat22.x);
        u_xlat5 = u_xlat3.xxxx + float4(1.0, 57.0, 58.0, 113.0);
        u_xlat5 = cos(u_xlat5);
        u_xlat5 = u_xlat5 * float4(41415.9258, 41415.9258, 41415.9258, 41415.9258);
        u_xlat5 = fract(u_xlat5);
        u_xlat41 = (-u_xlat22.x) + u_xlat5.x;
        u_xlat22.x = u_xlat21.x * u_xlat41 + u_xlat22.x;
        u_xlat41 = (-u_xlat5.y) + u_xlat5.z;
        u_xlat41 = u_xlat21.x * u_xlat41 + u_xlat5.y;
        u_xlat41 = (-u_xlat22.x) + u_xlat41;
        u_xlat22.x = u_xlat21.y * u_xlat41 + u_xlat22.x;
        u_xlat3.xzw = u_xlat3.xxx + float3(114.0, 170.0, 171.0);
        u_xlat3.xzw = cos(u_xlat3.xzw);
        u_xlat3.xzw = u_xlat3.xzw * float3(41415.9258, 41415.9258, 41415.9258);
        u_xlat3.xzw = fract(u_xlat3.xzw);
        u_xlat3.x = (-u_xlat5.w) + u_xlat3.x;
        u_xlat3.x = u_xlat21.x * u_xlat3.x + u_xlat5.w;
        u_xlat60 = (-u_xlat3.z) + u_xlat3.w;
        u_xlat21.x = u_xlat21.x * u_xlat60 + u_xlat3.z;
        u_xlat21.x = (-u_xlat3.x) + u_xlat21.x;
        u_xlat21.x = u_xlat21.y * u_xlat21.x + u_xlat3.x;
        u_xlat21.x = (-u_xlat22.x) + u_xlat21.x;
        u_xlat21.x = u_xlat21.z * u_xlat21.x + u_xlat22.x;
        u_xlat15.z = u_xlat21.x * u._distortion + u_xlat4.x;
        u_xlat2.xyz = u_xlat2.xxx + (-u_xlat15.xyz);
        u_xlat59 = dot(u_xlat2.xyz, u_xlat2.xyz);
        u_xlat59 = rsqrt(u_xlat59);
        u_xlat2.xyz = float3(u_xlat59) * u_xlat2.xyz;
        u_xlat3.xyz = (-u_xlat9.xyz) + float3(0.0, 0.0, 10.0);
        u_xlat59 = dot(u_xlat3.xyz, u_xlat3.xyz);
        u_xlat59 = sqrt(u_xlat59);
        u_xlat3.x = 100.0 / u._fade;
        u_xlat59 = u_xlat59 / u_xlat3.x;
        u_xlat59 = u_xlat59 + -1.0;
        u_xlat59 = u_xlat59 * -1.25;
        u_xlat59 = clamp(u_xlat59, 0.0, 1.0);
        u_xlat3.x = u_xlat59 * -2.0 + 3.0;
        u_xlat59 = u_xlat59 * u_xlat59;
        u_xlat59 = u_xlat59 * u_xlat3.x;
        u_xlat3.x = dot(u_xlat2.xyz, u_xlat11.xyz);
        u_xlat3.x = u_xlat3.x * 0.5 + 0.5;
        u_xlat3.x = clamp(u_xlat3.x, 0.0, 1.0);
        u_xlat3.x = u_xlat3.x * 0.899999976;
        u_xlat22.x = dot(u_xlat1.xyz, u_xlat2.xyz);
        u_xlat41 = (-u_xlat22.x) * u_xlat22.x + 1.0;
        u_xlat41 = (-u_xlat41) * 0.25 + 1.0;
        u_xlat60 = sqrt(u_xlat41);
        u_xlat60 = u_xlat22.x * 0.5 + u_xlat60;
        u_xlatb41 = u_xlat41>=0.0;
        u_xlat4.xyz = u_xlat2.yzx * float3(u_xlat60);
        u_xlat4.xyz = u_xlat1.ywx * float3(0.5, -0.349999905, 0.5) + (-u_xlat4.xyz);
        u_xlat4.xyz = bool(u_xlatb41) ? u_xlat4.xyz : float3(0.0, 0.0, 0.0);
        u_xlat58 = u_xlat22.x + u_xlat22.x;
        u_xlat22.xyz = u_xlat2.yzx * (-float3(u_xlat58)) + u_xlat1.yzx;
        if(int(u._reflectionenvironment) == 0) {
            u_xlat58 = dot(u_xlat4.xyz, u_xlat4.xyz);
            u_xlat58 = rsqrt(u_xlat58);
            u_xlat5.xyz = float3(u_xlat58) * u_xlat4.xyz;
            u_xlat58 = -abs(u_xlat5.x) + 1.0;
            u_xlat58 = sqrt(u_xlat58);
            u_xlat61 = abs(u_xlat5.x) * -0.0187292993 + 0.0742610022;
            u_xlat61 = u_xlat61 * abs(u_xlat5.x) + -0.212114394;
            u_xlat61 = u_xlat61 * abs(u_xlat5.x) + 1.57072878;
            u_xlat62 = u_xlat58 * u_xlat61;
            u_xlat62 = u_xlat62 * -2.0 + 3.14159274;
            u_xlatb6.xy = lessThan(u_xlat5.xzxx, (-u_xlat5.xzxx)).xy;
            u_xlat5.x = u_xlatb6.x ? u_xlat62 : float(0.0);
            u_xlat58 = u_xlat61 * u_xlat58 + u_xlat5.x;
            u_xlat61 = min(abs(u_xlat5.z), abs(u_xlat5.y));
            u_xlat5.x = max(abs(u_xlat5.z), abs(u_xlat5.y));
            u_xlat5.x = float(1.0) / u_xlat5.x;
            u_xlat61 = u_xlat61 * u_xlat5.x;
            u_xlat5.x = u_xlat61 * u_xlat61;
            u_xlat62 = u_xlat5.x * 0.0208350997 + -0.0851330012;
            u_xlat62 = u_xlat5.x * u_xlat62 + 0.180141002;
            u_xlat62 = u_xlat5.x * u_xlat62 + -0.330299497;
            u_xlat5.x = u_xlat5.x * u_xlat62 + 0.999866009;
            u_xlat62 = u_xlat61 * u_xlat5.x;
            u_xlatb6.x = abs(u_xlat5.z)<abs(u_xlat5.y);
            u_xlat62 = u_xlat62 * -2.0 + 1.57079637;
            u_xlat62 = u_xlatb6.x ? u_xlat62 : float(0.0);
            u_xlat61 = u_xlat61 * u_xlat5.x + u_xlat62;
            u_xlat5.x = u_xlatb6.y ? -3.14159274 : float(0.0);
            u_xlat61 = u_xlat61 + u_xlat5.x;
            u_xlat5.x = min(u_xlat5.z, u_xlat5.y);
            u_xlat24 = max(u_xlat5.z, u_xlat5.y);
            u_xlatb5 = u_xlat5.x<(-u_xlat5.x);
            u_xlatb24 = u_xlat24>=(-u_xlat24);
            u_xlatb5 = u_xlatb24 && u_xlatb5;
            u_xlat61 = (u_xlatb5) ? (-u_xlat61) : u_xlat61;
            u_xlat58 = u_xlat58 * 0.318309903;
            u_xlat5.z = (-u_xlat58);
            u_xlat58 = (-u_xlat61) * 0.159154952 + 0.5;
            u_xlatb61 = 1.0>=u_xlat58;
            if(u_xlatb61){
                u_xlatb61 = u_xlat58>=(-u_xlat58);
                u_xlat58 = fract(abs(u_xlat58));
                u_xlat5.x = (u_xlatb61) ? u_xlat58 : (-u_xlat58);
                u_xlat5.xy = u_xlat5.xz + float2(-0.5, 0.5);
                u_xlat43.xy = u._tex_offset.xy * float2(1.0, -1.0);
                u_xlat5.xy = u_xlat5.xy * float2(float2(u._tex_scale, u._tex_scale)) + u_xlat43.xy;
                u_xlat5.xy = u_xlat5.xy + float2(0.5, 0.5);
                u_xlatb43.xy = lessThan(u_xlat5.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat6.xy = fract(u_xlat5.xy);
                u_xlatb44.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat5.xyxy).xy;
                u_xlat7.xy = (-u_xlat6.xy) + float2(1.0, 1.0);
                {
                    float4 hlslcc_movcTemp = u_xlat5;
                    hlslcc_movcTemp.x = (u_xlatb44.x) ? u_xlat7.x : u_xlat5.x;
                    hlslcc_movcTemp.y = (u_xlatb44.y) ? u_xlat7.y : u_xlat5.y;
                    u_xlat5 = hlslcc_movcTemp;
                }
                {
                    float4 hlslcc_movcTemp = u_xlat5;
                    hlslcc_movcTemp.x = (u_xlatb43.x) ? u_xlat6.x : u_xlat5.x;
                    hlslcc_movcTemp.y = (u_xlatb43.y) ? u_xlat6.y : u_xlat5.y;
                    u_xlat5 = hlslcc_movcTemp;
                }
                u_xlat5.xyz = inputImg.sample(__nv_smp, u_xlat5.xy).xyz;
            } else {
                u_xlat5.x = float(0.0);
                u_xlat5.y = float(0.0);
                u_xlat5.z = float(0.0);
            }
            u_xlat58 = dot(u_xlat22.xyz, u_xlat22.xyz);
            u_xlat58 = rsqrt(u_xlat58);
            u_xlat6.xyz = float3(u_xlat58) * u_xlat22.xyz;
            u_xlat58 = -abs(u_xlat6.x) + 1.0;
            u_xlat58 = sqrt(u_xlat58);
            u_xlat61 = abs(u_xlat6.x) * -0.0187292993 + 0.0742610022;
            u_xlat61 = u_xlat61 * abs(u_xlat6.x) + -0.212114394;
            u_xlat61 = u_xlat61 * abs(u_xlat6.x) + 1.57072878;
            u_xlat62 = u_xlat58 * u_xlat61;
            u_xlat62 = u_xlat62 * -2.0 + 3.14159274;
            u_xlatb6.xw = lessThan(u_xlat6.xxxz, (-u_xlat6.xxxz)).xw;
            u_xlat62 = u_xlatb6.x ? u_xlat62 : float(0.0);
            u_xlat58 = u_xlat61 * u_xlat58 + u_xlat62;
            u_xlat61 = min(abs(u_xlat6.z), abs(u_xlat6.y));
            u_xlat62 = max(abs(u_xlat6.z), abs(u_xlat6.y));
            u_xlat62 = float(1.0) / u_xlat62;
            u_xlat61 = u_xlat61 * u_xlat62;
            u_xlat62 = u_xlat61 * u_xlat61;
            u_xlat6.x = u_xlat62 * 0.0208350997 + -0.0851330012;
            u_xlat6.x = u_xlat62 * u_xlat6.x + 0.180141002;
            u_xlat6.x = u_xlat62 * u_xlat6.x + -0.330299497;
            u_xlat62 = u_xlat62 * u_xlat6.x + 0.999866009;
            u_xlat6.x = u_xlat61 * u_xlat62;
            u_xlatb7.x = abs(u_xlat6.z)<abs(u_xlat6.y);
            u_xlat6.x = u_xlat6.x * -2.0 + 1.57079637;
            u_xlat6.x = u_xlatb7.x ? u_xlat6.x : float(0.0);
            u_xlat61 = u_xlat61 * u_xlat62 + u_xlat6.x;
            u_xlat62 = u_xlatb6.w ? -3.14159274 : float(0.0);
            u_xlat61 = u_xlat61 + u_xlat62;
            u_xlat62 = min(u_xlat6.z, u_xlat6.y);
            u_xlat6.x = max(u_xlat6.z, u_xlat6.y);
            u_xlatb62 = u_xlat62<(-u_xlat62);
            u_xlatb6.x = u_xlat6.x>=(-u_xlat6.x);
            u_xlatb62 = u_xlatb62 && u_xlatb6.x;
            u_xlat61 = (u_xlatb62) ? (-u_xlat61) : u_xlat61;
            u_xlat58 = u_xlat58 * 0.318309903;
            u_xlat6.z = (-u_xlat58);
            u_xlat58 = (-u_xlat61) * 0.159154952 + 0.5;
            u_xlatb61 = 1.0>=u_xlat58;
            if(u_xlatb61){
                u_xlatb61 = u_xlat58>=(-u_xlat58);
                u_xlat58 = fract(abs(u_xlat58));
                u_xlat6.x = (u_xlatb61) ? u_xlat58 : (-u_xlat58);
                u_xlat6.xy = u_xlat6.xz + float2(-0.5, 0.5);
                u_xlat44.xy = u._tex_offset.xy * float2(1.0, -1.0);
                u_xlat6.xy = u_xlat6.xy * float2(float2(u._tex_scale, u._tex_scale)) + u_xlat44.xy;
                u_xlat6.xy = u_xlat6.xy + float2(0.5, 0.5);
                u_xlatb44.xy = lessThan(u_xlat6.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat7.xy = fract(u_xlat6.xy);
                u_xlatb45.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat6.xyxy).xy;
                u_xlat9.xy = (-u_xlat7.xy) + float2(1.0, 1.0);
                {
                    float3 hlslcc_movcTemp = u_xlat6;
                    hlslcc_movcTemp.x = (u_xlatb45.x) ? u_xlat9.x : u_xlat6.x;
                    hlslcc_movcTemp.y = (u_xlatb45.y) ? u_xlat9.y : u_xlat6.y;
                    u_xlat6 = hlslcc_movcTemp;
                }
                {
                    float3 hlslcc_movcTemp = u_xlat6;
                    hlslcc_movcTemp.x = (u_xlatb44.x) ? u_xlat7.x : u_xlat6.x;
                    hlslcc_movcTemp.y = (u_xlatb44.y) ? u_xlat7.y : u_xlat6.y;
                    u_xlat6 = hlslcc_movcTemp;
                }
                u_xlat6.xyz = inputImg.sample(__nv_smp, u_xlat6.xy).xyz;
            } else {
                u_xlat6.x = float(0.0);
                u_xlat6.y = float(0.0);
                u_xlat6.z = float(0.0);
            }
        } else {
            u_xlatb58 = int(u._reflectionenvironment)==1;
            if(u_xlatb58){
                if(int(u._environment_texture) == 0) {
                    u_xlat5.xyz = cubemap1.sample(__nv_smp, acDirParaUv(u_xlat4.zxy)).xyz;
                } else {
                    u_xlatb61 = int(u._environment_texture)==1;
                    if(u_xlatb61){
                        u_xlat5.xyz = cubemap2.sample(__nv_smp, acDirParaUv(u_xlat4.zxy)).xyz;
                    } else {
                        u_xlatb61 = int(u._environment_texture)==2;
                        if(u_xlatb61){
                            u_xlat5.xyz = cubemap3.sample(__nv_smp, acDirParaUv(u_xlat4.zxy)).xyz;
                        } else {
                            u_xlatb61 = int(u._environment_texture)==3;
                            if(u_xlatb61){
                                u_xlat5.xyz = cubemap4.sample(__nv_smp, acDirParaUv(u_xlat4.zxy)).xyz;
                            } else {
                                u_xlat5.xyz = cubemap5.sample(__nv_smp, acDirParaUv(u_xlat4.zxy)).xyz;
                            }
                        }
                    }
                }
            } else {
                u_xlat61 = dot(u_xlat4.xyz, u_xlat4.xyz);
                u_xlat61 = rsqrt(u_xlat61);
                u_xlat4.xyz = float3(u_xlat61) * u_xlat4.xyz;
                u_xlat61 = -abs(u_xlat4.x) + 1.0;
                u_xlat61 = sqrt(u_xlat61);
                u_xlat62 = abs(u_xlat4.x) * -0.0187292993 + 0.0742610022;
                u_xlat62 = u_xlat62 * abs(u_xlat4.x) + -0.212114394;
                u_xlat62 = u_xlat62 * abs(u_xlat4.x) + 1.57072878;
                u_xlat63 = u_xlat61 * u_xlat62;
                u_xlat63 = u_xlat63 * -2.0 + 3.14159274;
                u_xlatb7.xy = lessThan(u_xlat4.xzxx, (-u_xlat4.xzxx)).xy;
                u_xlat4.x = u_xlatb7.x ? u_xlat63 : float(0.0);
                u_xlat4.x = u_xlat62 * u_xlat61 + u_xlat4.x;
                u_xlat61 = min(abs(u_xlat4.z), abs(u_xlat4.y));
                u_xlat62 = max(abs(u_xlat4.z), abs(u_xlat4.y));
                u_xlat62 = float(1.0) / u_xlat62;
                u_xlat61 = u_xlat61 * u_xlat62;
                u_xlat62 = u_xlat61 * u_xlat61;
                u_xlat63 = u_xlat62 * 0.0208350997 + -0.0851330012;
                u_xlat63 = u_xlat62 * u_xlat63 + 0.180141002;
                u_xlat63 = u_xlat62 * u_xlat63 + -0.330299497;
                u_xlat62 = u_xlat62 * u_xlat63 + 0.999866009;
                u_xlat63 = u_xlat61 * u_xlat62;
                u_xlatb7.x = abs(u_xlat4.z)<abs(u_xlat4.y);
                u_xlat63 = u_xlat63 * -2.0 + 1.57079637;
                u_xlat63 = u_xlatb7.x ? u_xlat63 : float(0.0);
                u_xlat61 = u_xlat61 * u_xlat62 + u_xlat63;
                u_xlat62 = u_xlatb7.y ? -3.14159274 : float(0.0);
                u_xlat61 = u_xlat61 + u_xlat62;
                u_xlat62 = min(u_xlat4.z, u_xlat4.y);
                u_xlat23.x = max(u_xlat4.z, u_xlat4.y);
                u_xlatb42.x = u_xlat62<(-u_xlat62);
                u_xlatb23 = u_xlat23.x>=(-u_xlat23.x);
                u_xlatb23 = u_xlatb23 && u_xlatb42.x;
                u_xlat23.x = (u_xlatb23) ? (-u_xlat61) : u_xlat61;
                u_xlat4.x = u_xlat4.x * 0.318309903;
                u_xlat4.z = (-u_xlat4.x);
                u_xlat23.x = (-u_xlat23.x) * 0.159154952 + 0.5;
                u_xlatb61 = 1.0>=u_xlat23.x;
                if(u_xlatb61){
                    u_xlatb61 = u_xlat23.x>=(-u_xlat23.x);
                    u_xlat23.x = fract(abs(u_xlat23.x));
                    u_xlat4.x = (u_xlatb61) ? u_xlat23.x : (-u_xlat23.x);
                    u_xlat4.xy = u_xlat4.xz + float2(-0.5, 0.5);
                    u_xlat42.xy = u._tex_offset.xy * float2(1.0, -1.0);
                    u_xlat4.xy = u_xlat4.xy * float2(float2(u._tex_scale, u._tex_scale)) + u_xlat42.xy;
                    u_xlat4.xy = u_xlat4.xy + float2(0.5, 0.5);
                    u_xlatb42.xy = lessThan(u_xlat4.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
                    u_xlat7.xy = fract(u_xlat4.xy);
                    u_xlatb45.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat4.xyxy).xy;
                    u_xlat9.xy = (-u_xlat7.xy) + float2(1.0, 1.0);
                    {
                        float4 hlslcc_movcTemp = u_xlat4;
                        hlslcc_movcTemp.x = (u_xlatb45.x) ? u_xlat9.x : u_xlat4.x;
                        hlslcc_movcTemp.y = (u_xlatb45.y) ? u_xlat9.y : u_xlat4.y;
                        u_xlat4 = hlslcc_movcTemp;
                    }
                    {
                        float4 hlslcc_movcTemp = u_xlat4;
                        hlslcc_movcTemp.x = (u_xlatb42.x) ? u_xlat7.x : u_xlat4.x;
                        hlslcc_movcTemp.y = (u_xlatb42.y) ? u_xlat7.y : u_xlat4.y;
                        u_xlat4 = hlslcc_movcTemp;
                    }
                    u_xlat5.xyz = panoramic_texture.sample(__nv_smp, u_xlat4.xy).xyz;
                } else {
                    u_xlat5.x = float(0.0);
                    u_xlat5.y = float(0.0);
                    u_xlat5.z = float(0.0);
                }
            }
            if(u_xlatb58){
                if(int(u._environment_texture) == 0) {
                    u_xlat6.xyz = cubemap1.sample(__nv_smp, acDirParaUv(u_xlat22.zxy)).xyz;
                } else {
                    u_xlatb58 = int(u._environment_texture)==1;
                    if(u_xlatb58){
                        u_xlat6.xyz = cubemap2.sample(__nv_smp, acDirParaUv(u_xlat22.zxy)).xyz;
                    } else {
                        u_xlatb58 = int(u._environment_texture)==2;
                        if(u_xlatb58){
                            u_xlat6.xyz = cubemap3.sample(__nv_smp, acDirParaUv(u_xlat22.zxy)).xyz;
                        } else {
                            u_xlatb58 = int(u._environment_texture)==3;
                            if(u_xlatb58){
                                u_xlat6.xyz = cubemap4.sample(__nv_smp, acDirParaUv(u_xlat22.zxy)).xyz;
                            } else {
                                u_xlat6.xyz = cubemap5.sample(__nv_smp, acDirParaUv(u_xlat22.zxy)).xyz;
                            }
                        }
                    }
                }
            } else {
                u_xlat58 = dot(u_xlat22.xyz, u_xlat22.xyz);
                u_xlat58 = rsqrt(u_xlat58);
                u_xlat22.xyz = float3(u_xlat58) * u_xlat22.xyz;
                u_xlat58 = -abs(u_xlat22.x) + 1.0;
                u_xlat58 = sqrt(u_xlat58);
                u_xlat4.x = abs(u_xlat22.x) * -0.0187292993 + 0.0742610022;
                u_xlat4.x = u_xlat4.x * abs(u_xlat22.x) + -0.212114394;
                u_xlat4.x = u_xlat4.x * abs(u_xlat22.x) + 1.57072878;
                u_xlat23.x = u_xlat58 * u_xlat4.x;
                u_xlat23.x = u_xlat23.x * -2.0 + 3.14159274;
                u_xlatb42.xy = lessThan(u_xlat22.xzxz, (-u_xlat22.xzxz)).xy;
                u_xlat22.x = u_xlatb42.x ? u_xlat23.x : float(0.0);
                u_xlat58 = u_xlat4.x * u_xlat58 + u_xlat22.x;
                u_xlat22.x = min(abs(u_xlat22.z), abs(u_xlat22.y));
                u_xlat4.x = max(abs(u_xlat22.z), abs(u_xlat22.y));
                u_xlat4.x = float(1.0) / u_xlat4.x;
                u_xlat22.x = u_xlat22.x * u_xlat4.x;
                u_xlat4.x = u_xlat22.x * u_xlat22.x;
                u_xlat23.x = u_xlat4.x * 0.0208350997 + -0.0851330012;
                u_xlat23.x = u_xlat4.x * u_xlat23.x + 0.180141002;
                u_xlat23.x = u_xlat4.x * u_xlat23.x + -0.330299497;
                u_xlat4.x = u_xlat4.x * u_xlat23.x + 0.999866009;
                u_xlat23.x = u_xlat22.x * u_xlat4.x;
                u_xlatb42.x = abs(u_xlat22.z)<abs(u_xlat22.y);
                u_xlat23.x = u_xlat23.x * -2.0 + 1.57079637;
                u_xlat23.x = u_xlatb42.x ? u_xlat23.x : float(0.0);
                u_xlat22.x = u_xlat22.x * u_xlat4.x + u_xlat23.x;
                u_xlat4.x = u_xlatb42.y ? -3.14159274 : float(0.0);
                u_xlat22.x = u_xlat22.x + u_xlat4.x;
                u_xlat4.x = min(u_xlat22.z, u_xlat22.y);
                u_xlat41 = max(u_xlat22.z, u_xlat22.y);
                u_xlatb60 = u_xlat4.x<(-u_xlat4.x);
                u_xlatb41 = u_xlat41>=(-u_xlat41);
                u_xlatb41 = u_xlatb41 && u_xlatb60;
                u_xlat22.x = (u_xlatb41) ? (-u_xlat22.x) : u_xlat22.x;
                u_xlat58 = u_xlat58 * 0.318309903;
                u_xlat4.z = (-u_xlat58);
                u_xlat58 = (-u_xlat22.x) * 0.159154952 + 0.5;
                u_xlatb22 = 1.0>=u_xlat58;
                if(u_xlatb22){
                    u_xlatb22 = u_xlat58>=(-u_xlat58);
                    u_xlat58 = fract(abs(u_xlat58));
                    u_xlat4.x = (u_xlatb22) ? u_xlat58 : (-u_xlat58);
                    u_xlat22.xy = u_xlat4.xz + float2(-0.5, 0.5);
                    u_xlat4.xy = u._tex_offset.xy * float2(1.0, -1.0);
                    u_xlat22.xy = u_xlat22.xy * float2(float2(u._tex_scale, u._tex_scale)) + u_xlat4.xy;
                    u_xlat22.xy = u_xlat22.xy + float2(0.5, 0.5);
                    u_xlatb4.xy = lessThan(u_xlat22.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                    u_xlat42.xy = fract(u_xlat22.xy);
                    u_xlatb7.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat22.xyxx).xy;
                    u_xlat45.xy = (-u_xlat42.xy) + float2(1.0, 1.0);
                    {
                        float3 hlslcc_movcTemp = u_xlat22;
                        hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat45.x : u_xlat22.x;
                        hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat45.y : u_xlat22.y;
                        u_xlat22 = hlslcc_movcTemp;
                    }
                    {
                        float3 hlslcc_movcTemp = u_xlat22;
                        hlslcc_movcTemp.x = (u_xlatb4.x) ? u_xlat42.x : u_xlat22.x;
                        hlslcc_movcTemp.y = (u_xlatb4.y) ? u_xlat42.y : u_xlat22.y;
                        u_xlat22 = hlslcc_movcTemp;
                    }
                    u_xlat6.xyz = panoramic_texture.sample(__nv_smp, u_xlat22.xy).xyz;
                } else {
                    u_xlat6.x = float(0.0);
                    u_xlat6.y = float(0.0);
                    u_xlat6.z = float(0.0);
                }
            }
        }
        u_xlat1.x = dot(u_xlat2.xyz, (-u_xlat1.xyz));
        u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
        u_xlat20.x = u_xlat1.x * -2.0 + 3.0;
        u_xlat1.x = u_xlat1.x * u_xlat1.x;
        u_xlat1.x = (-u_xlat20.x) * u_xlat1.x + 1.0;
        u_xlat1.x = log2(abs(u_xlat1.x));
        u_xlat1.x = u_xlat1.x * 1.39999998;
        u_xlat1.x = exp2(u_xlat1.x);
        u_xlat1.x = u_xlat1.x * u._rim;
        u_xlat20.xyz = u_xlat6.xyz * float3(u._reflection);
        u_xlat20.xyz = u_xlat5.xyz * float3(float3(u._refraction, u._refraction, u._refraction)) + u_xlat20.xyz;
        u_xlatb2 = 0<int(u._enable_lighting);
        u_xlat3.xyz = u_xlat3.xxx * u._diffuse_color.xyz;
        u_xlat3.xyz = u_xlat3.xyz * float3(float3(u._diffusion, u._diffusion, u._diffusion));
        u_xlat1.x = u_xlat1.x * 0.450000018;
        u_xlat4.xyz = u_xlat1.xxx * u._rim_color.xyz;
        u_xlat3.xyz = u_xlat3.xyz * float3(0.400000006, 0.400000006, 0.400000006) + u_xlat4.xyz;
        u_xlat3.xyz = u_xlat20.xyz + u_xlat3.xyz;
        u_xlat1.xyz = (bool(u_xlatb2)) ? u_xlat3.xyz : u_xlat20.xyz;
        u_xlat1.xyz = u_xlat1.xyz * float3(float3(u._intensity, u._intensity, u._intensity));
        u_xlat1.xyz = float3(u_xlat59) * u_xlat1.xyz;
        u_xlat58 = (-u._blend) + 1.0;
        u_xlat2.xyz = u_xlat0.xyz * float3(u_xlat58);
        u_xlat8.xyz = u_xlat1.xyz * float3(float3(u._blend, u._blend, u._blend)) + u_xlat2.xyz;
        u_xlat8.w = 1.0;
    }
    if(int(u._use_inner_mask) != 0) {
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat2 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat8;
        u_xlat3 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat4 = (-u_xlat3) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat4;
        u_xlat0 = u_xlat2 * u_xlat3 + u_xlat0;
        u_xlat1.x = u_xlat3.x * u_xlat0.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat0.w;
        __nv_out.xyz = u_xlat0.xyz;
    } else {
        __nv_out = u_xlat8;
    }
    return __nv_out;
    return __nv_out;
}
