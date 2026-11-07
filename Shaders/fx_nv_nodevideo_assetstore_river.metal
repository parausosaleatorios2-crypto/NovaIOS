// ---------------------------------------------------------------------------
// River (NV)
// origem : assets/effects/nv-nodevideo-assetstore-river.xml
// id     : nv.effect.nodevideo-assetstore-river
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_riverParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _tex_scale;
    float2 _tex_offset;
    float _tex_angle;
    float3 _rotation;
    float _width;
    float2 _depth;
    float2 _scale;
    float _displacementmap;
    float _environment_texture;
    float _material;
    float _speed;
    float _direction;
    float _tiling;
    float _mirror_edges;
    float _enable1;
    float3 _color1;
    float3 _direction1;
    float _enable2;
    float3 _color2;
    float3 _direction2;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
// O Node lê o ambiente num cubemap; aqui ele chega como imagem 2D: a direção vira a UV equirretangular (0.910.0).
static float2 acDirParaUv(float3 d) { d = normalize(d); return float2(__nv_atan(d.x, d.z) * 0.15915494 + 0.5, acos(clamp(d.y, -1.0, 1.0)) * 0.31830989); }
float4 u_xlat0;
float4 u_xlat1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
int2 u_xlati3;
bool2 u_xlatb3;
float4 u_xlat4;
bool2 u_xlatb4;
float4 u_xlat5;
float3 u_xlat6;
float3 u_xlat7;
float2 u_xlat8;
float3 u_xlat9;
float3 u_xlat10;
float u_xlat11;
bool u_xlatb11;
float u_xlat12;
bool u_xlatb12;
float3 u_xlat13;
int u_xlati13;
bool u_xlatb13;
float u_xlat14;
bool u_xlatb14;
float2 u_xlat16;
float2 u_xlat22;
bool u_xlatb22;
bool u_xlatb23;
float2 u_xlat24;
float2 u_xlat25;
bool2 u_xlatb25;
float2 u_xlat26;
bool u_xlatb26;
float u_xlat33;
int u_xlati33;
bool u_xlatb33;
float u_xlat34;
int u_xlati34;
bool u_xlatb34;
float u_xlat35;
int u_xlati35;
bool u_xlatb35;

fragment float4 fx_nv_nodevideo_assetstore_river(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_riverParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> displacement_source [[texture(1)]],
    texture2d<float> texture0 [[texture(2)]],
    texture2d<float> texture1 [[texture(3)]],
    texture2d<float> texture2 [[texture(4)]],
    texture2d<float> texture3 [[texture(5)]],
    texture2d<float> texture4 [[texture(6)]],
    texture2d<float> cubemap0 [[texture(7)]],
    texture2d<float> cubemap1 [[texture(8)]],
    texture2d<float> cubemap2 [[texture(9)]],
    texture2d<float> cubemap3 [[texture(10)]],
    texture2d<float> cubemap4 [[texture(11)]],
    texture2d<float> cubemap5 [[texture(12)]],
    texture2d<float> panoramic_texture [[texture(13)]],
    texture2d<float> Mask [[texture(14)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy * _resolution.xy;
    u_xlat0.xy = u_xlat0.xy * float2(2.0, 2.0) + (-_resolution.xy);
    u_xlat0.xy = u_xlat0.xy * float2(0.5, 0.5);
    u_xlat0.xy = u_xlat0.xy / _resolution.yy;
    u_xlat22.xy = u._rotation.xxyz.zz + float2(1.57079995, 0.0);
    u_xlat22.xy = sin(u_xlat22.xy);
    u_xlat1.xz = u_xlat22.xy * u._rotation.xxyz.yy;
    u_xlat1.y = u._rotation.xxyz.w;
    u_xlat22.x = dot((-u_xlat1.xyz), (-u_xlat1.xyz));
    u_xlat22.x = rsqrt(u_xlat22.x);
    u_xlat2.xyz = u_xlat22.xxx * (-u_xlat1.yzx);
    u_xlat3.xyz = u_xlat2.yzx * float3(0.0, 1.0, 0.0);
    u_xlat3.xyz = u_xlat2.zxy * float3(0.0, 0.0, 1.0) + (-u_xlat3.xyz);
    u_xlat33 = dot(u_xlat3.yz, u_xlat3.yz);
    u_xlat33 = rsqrt(u_xlat33);
    u_xlat3.xyz = float3(u_xlat33) * u_xlat3.xyz;
    u_xlat4.xyz = u_xlat2.zxy * u_xlat3.yzx;
    u_xlat2.xyz = u_xlat2.yzx * u_xlat3.zxy + (-u_xlat4.xyz);
    u_xlat33 = dot(u_xlat2.xyz, u_xlat2.xyz);
    u_xlat33 = rsqrt(u_xlat33);
    u_xlat2.xyz = float3(u_xlat33) * u_xlat2.xyz;
    u_xlat2.xyz = u_xlat0.yyy * u_xlat2.xyz;
    u_xlat0.xyw = u_xlat3.xyz * u_xlat0.xxx + u_xlat2.xyz;
    u_xlat0.xyz = (-u_xlat1.yzx) * u_xlat22.xxx + u_xlat0.xyw;
    u_xlat33 = dot(u_xlat0.xyz, u_xlat0.xyz);
    u_xlat33 = rsqrt(u_xlat33);
    u_xlat0.xyz = float3(u_xlat33) * u_xlat0.xyz;
    u_xlat33 = u._rotation.xxyz.w + (-u._depth.xxyx.z);
    u_xlat33 = u_xlat33 / (-u_xlat0.x);
    u_xlatb34 = u_xlat33>=0.0;
    if(u_xlatb34){
        u_xlat1.xyz = u_xlat0.zxy * float3(u_xlat33) + u_xlat1.xyz;
        u_xlat33 = _cur_time * u._speed;
        u_xlati34 = int((int(u._displacementmap)==5) ? 0xFFFFFFFFu : uint(0));
        u_xlat2.x = u._scale.x * 4.0;
        u_xlat2.x = (u_xlati34 != 0) ? u_xlat2.x : u._scale.x;
        u_xlat13.x = u._direction + 90.0;
        u_xlat13.x = u_xlat13.x * 0.0174532942;
        u_xlat3.x = sin(u_xlat13.x);
        u_xlat4.x = cos(u_xlat13.x);
        u_xlat5.x = sin((-u_xlat13.x));
        u_xlat13.xyz = float3(u_xlat33) * float3(0.660000026, 0.83160001, 1.6500001);
        u_xlat5.y = u_xlat4.x;
        u_xlat4.x = dot(u_xlat5.yx, u_xlat13.xx);
        u_xlat5.z = u_xlat3.x;
        u_xlat4.y = dot(u_xlat5.zy, u_xlat13.xx);
        u_xlat3.xy = u_xlat1.xz + u_xlat4.xy;
        u_xlat3.xy = u_xlat2.xx * u_xlat3.xy;
        u_xlat3.xy = u_xlat3.xy * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat25.xy = fract(u_xlat3.xy);
            u_xlat6.xyz = displacement_source.sample(__nv_smp, u_xlat25.xy).xyz;
            u_xlati13 = int(0xFFFFFFFFu);
        } else {
            u_xlatb25.x = int(u._displacementmap)==1;
            if(u_xlatb25.x){
                u_xlat6.xyz = texture0.sample(__nv_smp, u_xlat3.xy).xyz;
                u_xlati13 = int(0xFFFFFFFFu);
            } else {
                u_xlatb25.x = int(u._displacementmap)==2;
                if(u_xlatb25.x){
                    u_xlat6.xyz = texture1.sample(__nv_smp, u_xlat3.xy).xyz;
                    u_xlati13 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb25.x = int(u._displacementmap)==3;
                    if(u_xlatb25.x){
                        u_xlat6.xyz = texture2.sample(__nv_smp, u_xlat3.xy).xyz;
                        u_xlati13 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb25.x = int(u._displacementmap)==4;
                        if(u_xlatb25.x){
                            u_xlat6.xyz = texture3.sample(__nv_smp, u_xlat3.xy).xyz;
                            u_xlati13 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat6.xyz = texture4.sample(__nv_smp, u_xlat3.xy).xyz;
                            }
                            u_xlati13 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati13 == 0) {
            u_xlat6.xyz = texture0.sample(__nv_smp, u_xlat3.xy).xyz;
        }
        u_xlat3.x = dot(u_xlat5.yx, u_xlat13.yz);
        u_xlat3.y = dot(u_xlat5.zy, u_xlat13.yz);
        u_xlat13.xy = u_xlat1.xz + u_xlat3.xy;
        u_xlat13.xy = u_xlat2.xx * u_xlat13.xy;
        u_xlat13.xy = u_xlat13.xy * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat25.xy = fract(u_xlat13.xy);
            u_xlat7.xyz = displacement_source.sample(__nv_smp, u_xlat25.xy).xyz;
            u_xlati35 = int(0xFFFFFFFFu);
        } else {
            u_xlatb25.x = int(u._displacementmap)==1;
            if(u_xlatb25.x){
                u_xlat7.xyz = texture0.sample(__nv_smp, u_xlat13.xy).xyz;
                u_xlati35 = int(0xFFFFFFFFu);
            } else {
                u_xlatb25.x = int(u._displacementmap)==2;
                if(u_xlatb25.x){
                    u_xlat7.xyz = texture1.sample(__nv_smp, u_xlat13.xy).xyz;
                    u_xlati35 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb25.x = int(u._displacementmap)==3;
                    if(u_xlatb25.x){
                        u_xlat7.xyz = texture2.sample(__nv_smp, u_xlat13.xy).xyz;
                        u_xlati35 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb25.x = int(u._displacementmap)==4;
                        if(u_xlatb25.x){
                            u_xlat7.xyz = texture3.sample(__nv_smp, u_xlat13.xy).xyz;
                            u_xlati35 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat7.xyz = texture4.sample(__nv_smp, u_xlat13.xy).xyz;
                            }
                            u_xlati35 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati35 == 0) {
            u_xlat7.xyz = texture0.sample(__nv_smp, u_xlat13.xy).xyz;
        }
        u_xlat13.xy = float2(u_xlat33) * float2(1.09560001, 2.97000003);
        u_xlat8.x = dot(u_xlat5.yx, u_xlat13.xy);
        u_xlat8.y = dot(u_xlat5.zy, u_xlat13.xy);
        u_xlat13.xy = u_xlat1.xz + u_xlat8.xy;
        u_xlat13.xy = u_xlat2.xx * u_xlat13.xy;
        u_xlat13.xy = u_xlat13.xy * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat25.xy = fract(u_xlat13.xy);
            u_xlat5.xyz = displacement_source.sample(__nv_smp, u_xlat25.xy).xyz;
            u_xlati33 = int(0xFFFFFFFFu);
        } else {
            u_xlatb35 = int(u._displacementmap)==1;
            if(u_xlatb35){
                u_xlat5.xyz = texture0.sample(__nv_smp, u_xlat13.xy).xyz;
                u_xlati33 = int(0xFFFFFFFFu);
            } else {
                u_xlatb35 = int(u._displacementmap)==2;
                if(u_xlatb35){
                    u_xlat5.xyz = texture1.sample(__nv_smp, u_xlat13.xy).xyz;
                    u_xlati33 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb35 = int(u._displacementmap)==3;
                    if(u_xlatb35){
                        u_xlat5.xyz = texture2.sample(__nv_smp, u_xlat13.xy).xyz;
                        u_xlati33 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb35 = int(u._displacementmap)==4;
                        if(u_xlatb35){
                            u_xlat5.xyz = texture3.sample(__nv_smp, u_xlat13.xy).xyz;
                            u_xlati33 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat5.xyz = texture4.sample(__nv_smp, u_xlat13.xy).xyz;
                            }
                            u_xlati33 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati33 == 0) {
            u_xlat5.xyz = texture0.sample(__nv_smp, u_xlat13.xy).xyz;
        }
        u_xlat13.xyz = (-u_xlat5.xyz) + u_xlat7.xyz;
        u_xlat13.xyz = u_xlat13.xyz + u_xlat6.xyz;
        u_xlat33 = u_xlat13.y + u_xlat13.x;
        u_xlat33 = u_xlat13.z + u_xlat33;
        u_xlat33 = u_xlat33 * 0.0833333358 + u_xlat1.y;
        u_xlat33 = (-u._depth.xxyx.z) * 0.5 + u_xlat33;
        u_xlat33 = u_xlat33 + u_xlat33;
        u_xlat1.xz = float2(u_xlat33) * u_xlat0.zy + u_xlat1.xz;
        u_xlat33 = max(u._width, 0.00999999978);
        u_xlat5.z = min(u_xlat33, 100.0);
        u_xlat5.x = float(0.0);
        u_xlat5.y = float(0.0);
        u_xlat13.xyz = u_xlat1.xyz + u_xlat5.zyy;
        u_xlat25.xy = u_xlat4.xy + u_xlat13.xz;
        u_xlat25.xy = u_xlat2.xx * u_xlat25.xy;
        u_xlat25.xy = u_xlat25.xy * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat26.xy = fract(u_xlat25.xy);
            u_xlat6.xyz = displacement_source.sample(__nv_smp, u_xlat26.xy).xyz;
            u_xlati33 = int(0xFFFFFFFFu);
        } else {
            u_xlatb26 = int(u._displacementmap)==1;
            if(u_xlatb26){
                u_xlat6.xyz = texture0.sample(__nv_smp, u_xlat25.xy).xyz;
                u_xlati33 = int(0xFFFFFFFFu);
            } else {
                u_xlatb26 = int(u._displacementmap)==2;
                if(u_xlatb26){
                    u_xlat6.xyz = texture1.sample(__nv_smp, u_xlat25.xy).xyz;
                    u_xlati33 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb26 = int(u._displacementmap)==3;
                    if(u_xlatb26){
                        u_xlat6.xyz = texture2.sample(__nv_smp, u_xlat25.xy).xyz;
                        u_xlati33 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb26 = int(u._displacementmap)==4;
                        if(u_xlatb26){
                            u_xlat6.xyz = texture3.sample(__nv_smp, u_xlat25.xy).xyz;
                            u_xlati33 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat6.xyz = texture4.sample(__nv_smp, u_xlat25.xy).xyz;
                            }
                            u_xlati33 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati33 == 0) {
            u_xlat6.xyz = texture0.sample(__nv_smp, u_xlat25.xy).xyz;
        }
        u_xlat25.xy = u_xlat3.xy + u_xlat13.xz;
        u_xlat25.xy = u_xlat2.xx * u_xlat25.xy;
        u_xlat25.xy = u_xlat25.xy * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat26.xy = fract(u_xlat25.xy);
            u_xlat7.xyz = displacement_source.sample(__nv_smp, u_xlat26.xy).xyz;
            u_xlati33 = int(0xFFFFFFFFu);
        } else {
            u_xlatb26 = int(u._displacementmap)==1;
            if(u_xlatb26){
                u_xlat7.xyz = texture0.sample(__nv_smp, u_xlat25.xy).xyz;
                u_xlati33 = int(0xFFFFFFFFu);
            } else {
                u_xlatb26 = int(u._displacementmap)==2;
                if(u_xlatb26){
                    u_xlat7.xyz = texture1.sample(__nv_smp, u_xlat25.xy).xyz;
                    u_xlati33 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb26 = int(u._displacementmap)==3;
                    if(u_xlatb26){
                        u_xlat7.xyz = texture2.sample(__nv_smp, u_xlat25.xy).xyz;
                        u_xlati33 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb26 = int(u._displacementmap)==4;
                        if(u_xlatb26){
                            u_xlat7.xyz = texture3.sample(__nv_smp, u_xlat25.xy).xyz;
                            u_xlati33 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat7.xyz = texture4.sample(__nv_smp, u_xlat25.xy).xyz;
                            }
                            u_xlati33 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati33 == 0) {
            u_xlat7.xyz = texture0.sample(__nv_smp, u_xlat25.xy).xyz;
        }
        u_xlat13.xz = u_xlat8.xy + u_xlat13.xz;
        u_xlat13.xz = u_xlat2.xx * u_xlat13.xz;
        u_xlat13.xz = u_xlat13.xz * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat25.xy = fract(u_xlat13.xz);
            u_xlat9.xyz = displacement_source.sample(__nv_smp, u_xlat25.xy).xyz;
            u_xlati33 = int(0xFFFFFFFFu);
        } else {
            u_xlatb25.x = int(u._displacementmap)==1;
            if(u_xlatb25.x){
                u_xlat9.xyz = texture0.sample(__nv_smp, u_xlat13.xz).xyz;
                u_xlati33 = int(0xFFFFFFFFu);
            } else {
                u_xlatb25.x = int(u._displacementmap)==2;
                if(u_xlatb25.x){
                    u_xlat9.xyz = texture1.sample(__nv_smp, u_xlat13.xz).xyz;
                    u_xlati33 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb25.x = int(u._displacementmap)==3;
                    if(u_xlatb25.x){
                        u_xlat9.xyz = texture2.sample(__nv_smp, u_xlat13.xz).xyz;
                        u_xlati33 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb25.x = int(u._displacementmap)==4;
                        if(u_xlatb25.x){
                            u_xlat9.xyz = texture3.sample(__nv_smp, u_xlat13.xz).xyz;
                            u_xlati33 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat9.xyz = texture4.sample(__nv_smp, u_xlat13.xz).xyz;
                            }
                            u_xlati33 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati33 == 0) {
            u_xlat9.xyz = texture0.sample(__nv_smp, u_xlat13.xz).xyz;
        }
        u_xlat7.xyz = u_xlat7.xyz + (-u_xlat9.xyz);
        u_xlat6.xyz = u_xlat6.xyz + u_xlat7.xyz;
        u_xlat33 = u_xlat6.y + u_xlat6.x;
        u_xlat33 = u_xlat6.z + u_xlat33;
        u_xlat6.z = u_xlat33 * 0.0833333358 + u_xlat13.y;
        u_xlat13.xyz = u_xlat1.xyz + u_xlat5.yzy;
        u_xlat25.xy = u_xlat4.xy + u_xlat13.xz;
        u_xlat25.xy = u_xlat2.xx * u_xlat25.xy;
        u_xlat25.xy = u_xlat25.xy * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat26.xy = fract(u_xlat25.xy);
            u_xlat7.xyz = displacement_source.sample(__nv_smp, u_xlat26.xy).xyz;
            u_xlati33 = int(0xFFFFFFFFu);
        } else {
            u_xlatb26 = int(u._displacementmap)==1;
            if(u_xlatb26){
                u_xlat7.xyz = texture0.sample(__nv_smp, u_xlat25.xy).xyz;
                u_xlati33 = int(0xFFFFFFFFu);
            } else {
                u_xlatb26 = int(u._displacementmap)==2;
                if(u_xlatb26){
                    u_xlat7.xyz = texture1.sample(__nv_smp, u_xlat25.xy).xyz;
                    u_xlati33 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb26 = int(u._displacementmap)==3;
                    if(u_xlatb26){
                        u_xlat7.xyz = texture2.sample(__nv_smp, u_xlat25.xy).xyz;
                        u_xlati33 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb26 = int(u._displacementmap)==4;
                        if(u_xlatb26){
                            u_xlat7.xyz = texture3.sample(__nv_smp, u_xlat25.xy).xyz;
                            u_xlati33 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat7.xyz = texture4.sample(__nv_smp, u_xlat25.xy).xyz;
                            }
                            u_xlati33 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati33 == 0) {
            u_xlat7.xyz = texture0.sample(__nv_smp, u_xlat25.xy).xyz;
        }
        u_xlat25.xy = u_xlat3.xy + u_xlat13.xz;
        u_xlat25.xy = u_xlat2.xx * u_xlat25.xy;
        u_xlat25.xy = u_xlat25.xy * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat26.xy = fract(u_xlat25.xy);
            u_xlat9.xyz = displacement_source.sample(__nv_smp, u_xlat26.xy).xyz;
            u_xlati33 = int(0xFFFFFFFFu);
        } else {
            u_xlatb26 = int(u._displacementmap)==1;
            if(u_xlatb26){
                u_xlat9.xyz = texture0.sample(__nv_smp, u_xlat25.xy).xyz;
                u_xlati33 = int(0xFFFFFFFFu);
            } else {
                u_xlatb26 = int(u._displacementmap)==2;
                if(u_xlatb26){
                    u_xlat9.xyz = texture1.sample(__nv_smp, u_xlat25.xy).xyz;
                    u_xlati33 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb26 = int(u._displacementmap)==3;
                    if(u_xlatb26){
                        u_xlat9.xyz = texture2.sample(__nv_smp, u_xlat25.xy).xyz;
                        u_xlati33 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb26 = int(u._displacementmap)==4;
                        if(u_xlatb26){
                            u_xlat9.xyz = texture3.sample(__nv_smp, u_xlat25.xy).xyz;
                            u_xlati33 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat9.xyz = texture4.sample(__nv_smp, u_xlat25.xy).xyz;
                            }
                            u_xlati33 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati33 == 0) {
            u_xlat9.xyz = texture0.sample(__nv_smp, u_xlat25.xy).xyz;
        }
        u_xlat13.xz = u_xlat8.xy + u_xlat13.xz;
        u_xlat13.xz = u_xlat2.xx * u_xlat13.xz;
        u_xlat13.xz = u_xlat13.xz * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat25.xy = fract(u_xlat13.xz);
            u_xlat10.xyz = displacement_source.sample(__nv_smp, u_xlat25.xy).xyz;
            u_xlati33 = int(0xFFFFFFFFu);
        } else {
            u_xlatb25.x = int(u._displacementmap)==1;
            if(u_xlatb25.x){
                u_xlat10.xyz = texture0.sample(__nv_smp, u_xlat13.xz).xyz;
                u_xlati33 = int(0xFFFFFFFFu);
            } else {
                u_xlatb25.x = int(u._displacementmap)==2;
                if(u_xlatb25.x){
                    u_xlat10.xyz = texture1.sample(__nv_smp, u_xlat13.xz).xyz;
                    u_xlati33 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb25.x = int(u._displacementmap)==3;
                    if(u_xlatb25.x){
                        u_xlat10.xyz = texture2.sample(__nv_smp, u_xlat13.xz).xyz;
                        u_xlati33 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb25.x = int(u._displacementmap)==4;
                        if(u_xlatb25.x){
                            u_xlat10.xyz = texture3.sample(__nv_smp, u_xlat13.xz).xyz;
                            u_xlati33 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat10.xyz = texture4.sample(__nv_smp, u_xlat13.xz).xyz;
                            }
                            u_xlati33 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati33 == 0) {
            u_xlat10.xyz = texture0.sample(__nv_smp, u_xlat13.xz).xyz;
        }
        u_xlat9.xyz = u_xlat9.xyz + (-u_xlat10.xyz);
        u_xlat7.xyz = u_xlat7.xyz + u_xlat9.xyz;
        u_xlat33 = u_xlat7.y + u_xlat7.x;
        u_xlat33 = u_xlat7.z + u_xlat33;
        u_xlat6.x = u_xlat33 * 0.0833333358 + u_xlat13.y;
        u_xlat13.xyz = u_xlat1.xyz + u_xlat5.xyz;
        u_xlat25.xy = u_xlat4.xy + u_xlat13.xz;
        u_xlat25.xy = u_xlat2.xx * u_xlat25.xy;
        u_xlat25.xy = u_xlat25.xy * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat26.xy = fract(u_xlat25.xy);
            u_xlat5.xyz = displacement_source.sample(__nv_smp, u_xlat26.xy).xyz;
            u_xlati33 = int(0xFFFFFFFFu);
        } else {
            u_xlatb26 = int(u._displacementmap)==1;
            if(u_xlatb26){
                u_xlat5.xyz = texture0.sample(__nv_smp, u_xlat25.xy).xyz;
                u_xlati33 = int(0xFFFFFFFFu);
            } else {
                u_xlatb26 = int(u._displacementmap)==2;
                if(u_xlatb26){
                    u_xlat5.xyz = texture1.sample(__nv_smp, u_xlat25.xy).xyz;
                    u_xlati33 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb26 = int(u._displacementmap)==3;
                    if(u_xlatb26){
                        u_xlat5.xyz = texture2.sample(__nv_smp, u_xlat25.xy).xyz;
                        u_xlati33 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb26 = int(u._displacementmap)==4;
                        if(u_xlatb26){
                            u_xlat5.xyz = texture3.sample(__nv_smp, u_xlat25.xy).xyz;
                            u_xlati33 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat5.xyz = texture4.sample(__nv_smp, u_xlat25.xy).xyz;
                            }
                            u_xlati33 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati33 == 0) {
            u_xlat5.xyz = texture0.sample(__nv_smp, u_xlat25.xy).xyz;
        }
        u_xlat25.xy = u_xlat3.xy + u_xlat13.xz;
        u_xlat25.xy = u_xlat2.xx * u_xlat25.xy;
        u_xlat25.xy = u_xlat25.xy * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat4.zw = fract(u_xlat25.xy);
            u_xlat7.xyz = displacement_source.sample(__nv_smp, u_xlat4.zw).xyz;
            u_xlati33 = int(0xFFFFFFFFu);
        } else {
            u_xlat4.z = as_type<float>((int(u._displacementmap)==1) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat4.z)) != uint(0)) {
                u_xlat7.xyz = texture0.sample(__nv_smp, u_xlat25.xy).xyz;
                u_xlati33 = int(0xFFFFFFFFu);
            } else {
                u_xlat4.z = as_type<float>((int(u._displacementmap)==2) ? 0xFFFFFFFFu : uint(0));
                if(uint(as_type<uint>(u_xlat4.z)) != uint(0)) {
                    u_xlat7.xyz = texture1.sample(__nv_smp, u_xlat25.xy).xyz;
                    u_xlati33 = int(0xFFFFFFFFu);
                } else {
                    u_xlat4.z = as_type<float>((int(u._displacementmap)==3) ? 0xFFFFFFFFu : uint(0));
                    if(uint(as_type<uint>(u_xlat4.z)) != uint(0)) {
                        u_xlat7.xyz = texture2.sample(__nv_smp, u_xlat25.xy).xyz;
                        u_xlati33 = int(0xFFFFFFFFu);
                    } else {
                        u_xlat4.z = as_type<float>((int(u._displacementmap)==4) ? 0xFFFFFFFFu : uint(0));
                        if(uint(as_type<uint>(u_xlat4.z)) != uint(0)) {
                            u_xlat7.xyz = texture3.sample(__nv_smp, u_xlat25.xy).xyz;
                            u_xlati33 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat7.xyz = texture4.sample(__nv_smp, u_xlat25.xy).xyz;
                            }
                            u_xlati33 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati33 == 0) {
            u_xlat7.xyz = texture0.sample(__nv_smp, u_xlat25.xy).xyz;
        }
        u_xlat13.xz = u_xlat8.xy + u_xlat13.xz;
        u_xlat13.xz = u_xlat2.xx * u_xlat13.xz;
        u_xlat13.xz = u_xlat13.xz * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat3.zw = fract(u_xlat13.xz);
            u_xlat9.xyz = displacement_source.sample(__nv_smp, u_xlat3.zw).xyz;
            u_xlati33 = int(0xFFFFFFFFu);
        } else {
            u_xlat3.z = as_type<float>((int(u._displacementmap)==1) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.z)) != uint(0)) {
                u_xlat9.xyz = texture0.sample(__nv_smp, u_xlat13.xz).xyz;
                u_xlati33 = int(0xFFFFFFFFu);
            } else {
                u_xlat3.z = as_type<float>((int(u._displacementmap)==2) ? 0xFFFFFFFFu : uint(0));
                if(uint(as_type<uint>(u_xlat3.z)) != uint(0)) {
                    u_xlat9.xyz = texture1.sample(__nv_smp, u_xlat13.xz).xyz;
                    u_xlati33 = int(0xFFFFFFFFu);
                } else {
                    u_xlat3.z = as_type<float>((int(u._displacementmap)==3) ? 0xFFFFFFFFu : uint(0));
                    if(uint(as_type<uint>(u_xlat3.z)) != uint(0)) {
                        u_xlat9.xyz = texture2.sample(__nv_smp, u_xlat13.xz).xyz;
                        u_xlati33 = int(0xFFFFFFFFu);
                    } else {
                        u_xlat3.z = as_type<float>((int(u._displacementmap)==4) ? 0xFFFFFFFFu : uint(0));
                        if(uint(as_type<uint>(u_xlat3.z)) != uint(0)) {
                            u_xlat9.xyz = texture3.sample(__nv_smp, u_xlat13.xz).xyz;
                            u_xlati33 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat9.xyz = texture4.sample(__nv_smp, u_xlat13.xz).xyz;
                            }
                            u_xlati33 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati33 == 0) {
            u_xlat9.xyz = texture0.sample(__nv_smp, u_xlat13.xz).xyz;
        }
        u_xlat7.xyz = u_xlat7.xyz + (-u_xlat9.xyz);
        u_xlat5.xyz = u_xlat5.xyz + u_xlat7.xyz;
        u_xlat33 = u_xlat5.y + u_xlat5.x;
        u_xlat33 = u_xlat5.z + u_xlat33;
        u_xlat6.y = u_xlat33 * 0.0833333358 + u_xlat13.y;
        u_xlat13.xy = u_xlat4.xy + u_xlat1.xz;
        u_xlat13.xy = u_xlat2.xx * u_xlat13.xy;
        u_xlat13.xy = u_xlat13.xy * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat3.zw = fract(u_xlat13.xy);
            u_xlat4.xyz = displacement_source.sample(__nv_smp, u_xlat3.zw).xyz;
            u_xlati33 = int(0xFFFFFFFFu);
        } else {
            u_xlatb35 = int(u._displacementmap)==1;
            if(u_xlatb35){
                u_xlat4.xyz = texture0.sample(__nv_smp, u_xlat13.xy).xyz;
                u_xlati33 = int(0xFFFFFFFFu);
            } else {
                u_xlatb35 = int(u._displacementmap)==2;
                if(u_xlatb35){
                    u_xlat4.xyz = texture1.sample(__nv_smp, u_xlat13.xy).xyz;
                    u_xlati33 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb35 = int(u._displacementmap)==3;
                    if(u_xlatb35){
                        u_xlat4.xyz = texture2.sample(__nv_smp, u_xlat13.xy).xyz;
                        u_xlati33 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb35 = int(u._displacementmap)==4;
                        if(u_xlatb35){
                            u_xlat4.xyz = texture3.sample(__nv_smp, u_xlat13.xy).xyz;
                            u_xlati33 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat4.xyz = texture4.sample(__nv_smp, u_xlat13.xy).xyz;
                            }
                            u_xlati33 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati33 == 0) {
            u_xlat4.xyz = texture0.sample(__nv_smp, u_xlat13.xy).xyz;
        }
        u_xlat13.xy = u_xlat3.xy + u_xlat1.xz;
        u_xlat13.xy = u_xlat2.xx * u_xlat13.xy;
        u_xlat13.xy = u_xlat13.xy * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat3.xy = fract(u_xlat13.xy);
            u_xlat3.xyz = displacement_source.sample(__nv_smp, u_xlat3.xy).xyz;
            u_xlati33 = int(0xFFFFFFFFu);
        } else {
            u_xlatb35 = int(u._displacementmap)==1;
            if(u_xlatb35){
                u_xlat3.xyz = texture0.sample(__nv_smp, u_xlat13.xy).xyz;
                u_xlati33 = int(0xFFFFFFFFu);
            } else {
                u_xlatb35 = int(u._displacementmap)==2;
                if(u_xlatb35){
                    u_xlat3.xyz = texture1.sample(__nv_smp, u_xlat13.xy).xyz;
                    u_xlati33 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb35 = int(u._displacementmap)==3;
                    if(u_xlatb35){
                        u_xlat3.xyz = texture2.sample(__nv_smp, u_xlat13.xy).xyz;
                        u_xlati33 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb35 = int(u._displacementmap)==4;
                        if(u_xlatb35){
                            u_xlat3.xyz = texture3.sample(__nv_smp, u_xlat13.xy).xyz;
                            u_xlati33 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat3.xyz = texture4.sample(__nv_smp, u_xlat13.xy).xyz;
                            }
                            u_xlati33 = u_xlati34;
                        }
                    }
                }
            }
        }
        if(u_xlati33 == 0) {
            u_xlat3.xyz = texture0.sample(__nv_smp, u_xlat13.xy).xyz;
        }
        u_xlat13.xy = u_xlat8.xy + u_xlat1.xz;
        u_xlat2.xy = u_xlat2.xx * u_xlat13.xy;
        u_xlat2.xy = u_xlat2.xy * float2(0.0333333351, 0.0333333351);
        if(int(u._displacementmap) == 0) {
            u_xlat24.xy = fract(u_xlat2.xy);
            u_xlat5.xyz = displacement_source.sample(__nv_smp, u_xlat24.xy).xyz;
            u_xlati34 = int(0xFFFFFFFFu);
        } else {
            u_xlatb33 = int(u._displacementmap)==1;
            if(u_xlatb33){
                u_xlat5.xyz = texture0.sample(__nv_smp, u_xlat2.xy).xyz;
                u_xlati34 = int(0xFFFFFFFFu);
            } else {
                u_xlatb33 = int(u._displacementmap)==2;
                if(u_xlatb33){
                    u_xlat5.xyz = texture1.sample(__nv_smp, u_xlat2.xy).xyz;
                    u_xlati34 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb33 = int(u._displacementmap)==3;
                    if(u_xlatb33){
                        u_xlat5.xyz = texture2.sample(__nv_smp, u_xlat2.xy).xyz;
                        u_xlati34 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb33 = int(u._displacementmap)==4;
                        if(u_xlatb33){
                            u_xlat5.xyz = texture3.sample(__nv_smp, u_xlat2.xy).xyz;
                            u_xlati34 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlati34 != 0) {
                                u_xlat5.xyz = texture4.sample(__nv_smp, u_xlat2.xy).xyz;
                            }
                        }
                    }
                }
            }
        }
        if(u_xlati34 == 0) {
            u_xlat5.xyz = texture0.sample(__nv_smp, u_xlat2.xy).xyz;
        }
        u_xlat2.xyz = u_xlat3.xyz + (-u_xlat5.xyz);
        u_xlat2.xyz = u_xlat2.xyz + u_xlat4.xyz;
        u_xlat33 = u_xlat2.y + u_xlat2.x;
        u_xlat33 = u_xlat2.z + u_xlat33;
        u_xlat33 = u_xlat33 * 0.0833333358 + u_xlat1.y;
        u_xlat2.xyz = (-float3(u_xlat33)) + u_xlat6.xyz;
        u_xlat33 = dot(u_xlat2.xyz, u_xlat2.xyz);
        u_xlat33 = rsqrt(u_xlat33);
        u_xlat2.xyz = float3(u_xlat33) * u_xlat2.xyz;
        u_xlat33 = dot(float3(0.577350259, 0.577350259, 0.577350259), u_xlat2.xyz);
        u_xlat33 = u_xlat33 + u_xlat33;
        u_xlat3.xyz = u_xlat2.zxy * (-float3(u_xlat33)) + u._direction2.xyz;
        u_xlat3.xyz = u_xlat3.xyz + float3(0.577350259, 0.577350259, 0.577350259);
        u_xlat33 = dot(u_xlat3.xyz, u_xlat3.xyz);
        u_xlat33 = rsqrt(u_xlat33);
        u_xlat3.xyz = float3(u_xlat33) * u_xlat3.xyz;
        u_xlat33 = dot(u_xlat3.yzx, u_xlat0.xyz);
        u_xlat33 = max(u_xlat33, 0.0);
        u_xlat33 = log2(u_xlat33);
        u_xlat33 = u_xlat33 * 30.0;
        u_xlat33 = exp2(u_xlat33);
        u_xlat12 = dot(u_xlat0.xyz, u_xlat2.xyz);
        u_xlat34 = (-u_xlat12) * u_xlat12 + 1.0;
        u_xlat34 = (-u_xlat34) * 0.595271587 + 1.0;
        u_xlat35 = sqrt(u_xlat34);
        u_xlat35 = u_xlat12 * 0.771538436 + u_xlat35;
        u_xlatb34 = u_xlat34>=0.0;
        u_xlat3.xyz = u_xlat2.zxy * float3(u_xlat35);
        u_xlat3.xyz = u_xlat0.zxy * float3(0.771538436, 0.771538436, 0.771538436) + (-u_xlat3.xyz);
        u_xlat3.xyz = bool(u_xlatb34) ? u_xlat3.xyz : float3(0.0, 0.0, 0.0);
        u_xlat1.w = -4.0 / u_xlat3.y;
        u_xlat12 = u_xlat12 + u_xlat12;
        u_xlat0.xyz = u_xlat2.xyz * (-float3(u_xlat12)) + u_xlat0.xyz;
        u_xlat0.xyz = u_xlat0.xyz + u._direction1.yzx;
        if(int(u._material) == 0) {
            if(int(u._environment_texture) == 0) {
                u_xlat2.xyz = cubemap0.sample(__nv_smp, acDirParaUv(u_xlat0.zxy)).xyz;
            } else {
                u_xlatb12 = int(u._environment_texture)==1;
                if(u_xlatb12){
                    u_xlat2.xyz = cubemap1.sample(__nv_smp, acDirParaUv(u_xlat0.zxy)).xyz;
                } else {
                    u_xlatb12 = int(u._environment_texture)==2;
                    if(u_xlatb12){
                        u_xlat2.xyz = cubemap2.sample(__nv_smp, acDirParaUv(u_xlat0.zxy)).xyz;
                    } else {
                        u_xlatb12 = int(u._environment_texture)==3;
                        if(u_xlatb12){
                            u_xlat2.xyz = cubemap3.sample(__nv_smp, acDirParaUv(u_xlat0.zxy)).xyz;
                        } else {
                            u_xlatb12 = int(u._environment_texture)==4;
                            if(u_xlatb12){
                                u_xlat2.xyz = cubemap4.sample(__nv_smp, acDirParaUv(u_xlat0.zxy)).xyz;
                            } else {
                                u_xlat2.xyz = cubemap5.sample(__nv_smp, acDirParaUv(u_xlat0.zxy)).xyz;
                            }
                        }
                    }
                }
            }
        } else {
            u_xlat12 = dot(u_xlat0.xyz, u_xlat0.xyz);
            u_xlat12 = rsqrt(u_xlat12);
            u_xlat0.xyz = u_xlat0.xyz * float3(u_xlat12);
            u_xlat12 = -abs(u_xlat0.x) + 1.0;
            u_xlat12 = sqrt(u_xlat12);
            u_xlat35 = abs(u_xlat0.x) * -0.0187292993 + 0.0742610022;
            u_xlat35 = u_xlat35 * abs(u_xlat0.x) + -0.212114394;
            u_xlat35 = u_xlat35 * abs(u_xlat0.x) + 1.57072878;
            u_xlat14 = u_xlat12 * u_xlat35;
            u_xlat14 = u_xlat14 * -2.0 + 3.14159274;
            u_xlatb4.xy = lessThan(u_xlat0.xzxx, (-u_xlat0.xzxx)).xy;
            u_xlat0.x = u_xlatb4.x ? u_xlat14 : float(0.0);
            u_xlat16.y = u_xlat35 * u_xlat12 + u_xlat0.x;
            u_xlat0.x = min(abs(u_xlat0.z), abs(u_xlat0.y));
            u_xlat12 = max(abs(u_xlat0.z), abs(u_xlat0.y));
            u_xlat12 = float(1.0) / u_xlat12;
            u_xlat0.x = u_xlat0.x * u_xlat12;
            u_xlat12 = u_xlat0.x * u_xlat0.x;
            u_xlat35 = u_xlat12 * 0.0208350997 + -0.0851330012;
            u_xlat35 = u_xlat12 * u_xlat35 + 0.180141002;
            u_xlat35 = u_xlat12 * u_xlat35 + -0.330299497;
            u_xlat12 = u_xlat12 * u_xlat35 + 0.999866009;
            u_xlat35 = u_xlat0.x * u_xlat12;
            u_xlatb14 = abs(u_xlat0.z)<abs(u_xlat0.y);
            u_xlat35 = u_xlat35 * -2.0 + 1.57079637;
            u_xlat35 = u_xlatb14 ? u_xlat35 : float(0.0);
            u_xlat0.x = u_xlat0.x * u_xlat12 + u_xlat35;
            u_xlat12 = u_xlatb4.y ? -3.14159274 : float(0.0);
            u_xlat0.x = u_xlat0.x + u_xlat12;
            u_xlat12 = min(u_xlat0.z, u_xlat0.y);
            u_xlat11 = max(u_xlat0.z, u_xlat0.y);
            u_xlatb22 = u_xlat12<(-u_xlat12);
            u_xlatb11 = u_xlat11>=(-u_xlat11);
            u_xlatb11 = u_xlatb11 && u_xlatb22;
            u_xlat16.x = (u_xlatb11) ? (-u_xlat0.x) : u_xlat0.x;
            u_xlat0.yz = (-u_xlat16.xy) * float2(0.159154952, 0.318309903) + float2(0.5, 1.0);
            u_xlatb12 = 1.0>=u_xlat0.y;
            if(u_xlatb12){
                u_xlatb12 = u_xlat0.y>=(-u_xlat0.y);
                u_xlat11 = fract(abs(u_xlat0.y));
                u_xlat0.x = (u_xlatb12) ? u_xlat11 : (-u_xlat11);
                u_xlat2.xyz = panoramic_texture.sample(__nv_smp, u_xlat0.xz).xyz;
            } else {
                u_xlat2.x = float(0.0);
                u_xlat2.y = float(0.0);
                u_xlat2.z = float(0.0);
            }
        }
        u_xlat0.xy = u_xlat3.xz * u._depth.xxyx.yy;
        u_xlat0.xy = u_xlat0.xy * u_xlat1.ww + u_xlat1.xz;
        u_xlat0.xy = u_xlat0.xy + float2(-0.5, -0.5);
        u_xlat22.x = u._tex_angle * -0.0174532942;
        u_xlat1.x = sin(u_xlat22.x);
        u_xlat3.x = cos(u_xlat22.x);
        u_xlat4.x = sin((-u_xlat22.x));
        u_xlat4.y = u_xlat3.x;
        u_xlat4.z = u_xlat1.x;
        u_xlat1.x = dot(u_xlat0.xy, u_xlat4.yz);
        u_xlat1.y = dot(u_xlat0.xy, u_xlat4.xy);
        u_xlat0.xy = u_xlat1.xy * u._tex_scale.xy;
        u_xlat0.xy = u_xlat0.xy * float2(0.100000001, 0.100000001) + float2(0.5, 0.5);
        u_xlat0.xy = u_xlat0.xy + (-float2(u._tex_offset.x, u._tex_offset.y));
        u_xlatb22 = 0<int(u._tiling);
        u_xlat1.xy = u_xlat0.xy + float2(-0.5, -0.5);
        u_xlat1.xy = u_xlat1.xy * float2(1.00999999, 1.00999999) + float2(0.5, 0.5);
        u_xlatb3.xy = greaterThanEqual(u_xlat1.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlat25.xy = abs(u_xlat1.xy) + float2(1.0, 1.0);
        u_xlat3.x = (u_xlatb3.x) ? u_xlat1.x : u_xlat25.x;
        u_xlat3.y = (u_xlatb3.y) ? u_xlat1.y : u_xlat25.y;
        u_xlat1.xy = fract(u_xlat1.xy);
        u_xlatb23 = int(u._mirror_edges)==1;
        u_xlat3.xy = u_xlat3.xy * float2(0.5, 0.5);
        u_xlatb25.xy = greaterThanEqual(u_xlat3.xyxy, (-u_xlat3.xyxy)).xy;
        u_xlat3.xy = fract(abs(u_xlat3.xy));
        {
            float4 hlslcc_movcTemp = u_xlat3;
            hlslcc_movcTemp.x = (u_xlatb25.x) ? u_xlat3.x : (-u_xlat3.x);
            hlslcc_movcTemp.y = (u_xlatb25.y) ? u_xlat3.y : (-u_xlat3.y);
            u_xlat3 = hlslcc_movcTemp;
        }
        u_xlatb3.xy = greaterThanEqual(u_xlat3.xyxx, float4(0.5, 0.5, 0.0, 0.0)).xy;
        u_xlati3.xy = int2(uint2((uint(u_xlatb23) * 0xffffffffu) & (uint(u_xlatb3.x) * 0xffffffffu), (uint(u_xlatb23) * 0xffffffffu) & (uint(u_xlatb3.y) * 0xffffffffu)));
        u_xlat25.xy = (-u_xlat1.xy) + float2(1.0, 1.0);
        {
            float4 hlslcc_movcTemp = u_xlat1;
            hlslcc_movcTemp.x = (u_xlati3.x != 0) ? u_xlat25.x : u_xlat1.x;
            hlslcc_movcTemp.y = (u_xlati3.y != 0) ? u_xlat25.y : u_xlat1.y;
            u_xlat1 = hlslcc_movcTemp;
        }
        u_xlat1.xy = u_xlat1.xy + float2(-0.5, -0.5);
        u_xlat1.xy = u_xlat1.xy * float2(0.990099013, 0.990099013) + float2(0.5, 0.5);
        u_xlat0.xy = (bool(u_xlatb22)) ? u_xlat1.xy : u_xlat0.xy;
        u_xlat0.xyz = inputImg.sample(__nv_smp, u_xlat0.xy).xyz;
        u_xlat1.xyz = u_xlat2.xyz * u._color1.xyz;
        u_xlat1 = u_xlat1 * float4(0.5, 0.5, 0.5, -0.125);
        u_xlat34 = exp2(u_xlat1.w);
        u_xlatb2.x = 0>=int(u._enable2);
        u_xlatb13 = 0>=int(u._enable1);
        u_xlat1.xyz = (bool(u_xlatb13)) ? float3(0.0, 0.0, 0.0) : u_xlat1.xyz;
        u_xlat0.xyz = u_xlat0.xyz * float3(u_xlat34) + u_xlat1.xyz;
        u_xlat1.xyz = float3(u_xlat33) * u._color2.xyz;
        u_xlat1.xyz = u_xlat1.xyz * float3(0.5, 0.5, 0.5);
        u_xlat1.xyz = (u_xlatb2.x) ? float3(0.0, 0.0, 0.0) : u_xlat1.xyz;
        u_xlat0.xyz = u_xlat0.xyz + u_xlat1.xyz;
    } else {
        u_xlat0.x = float(0.0);
        u_xlat0.y = float(0.0);
        u_xlat0.z = float(0.0);
    }
    if(int(u._use_inner_mask) != 0) {
        u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3.xyz = (u_xlatb2.x) ? float3(1.0, 0.0, 1.0) : u_xlat0.xyz;
        u_xlat3.w = 1.0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat33 = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat33 : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out.xyz = u_xlat0.xyz;
        __nv_out.w = 1.0;
    }
    return __nv_out;
    return __nv_out;
}
