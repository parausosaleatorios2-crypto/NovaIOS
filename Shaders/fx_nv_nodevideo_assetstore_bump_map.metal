// ---------------------------------------------------------------------------
// Bump Map (NV)
// origem : assets/effects/nv-nodevideo-assetstore-bump-map.xml
// id     : nv.effect.nodevideo-assetstore-bump-map
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_bump_mapParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _height;
    float2 _tex_scale;
    float _tex_angle;
    float2 _tex_offset;
    float3 _light_pos;
    float3 _light_direction;
    float4 _light_color;
    float4 _ambient_color;
    float _brightness;
    float3 _specular;
    float _bumpmap;
    float _light_type;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat6;
bool u_xlatb7;
bool u_xlatb9;
float u_xlat12;
float2 u_xlat14;
float u_xlat18;
bool u_xlatb18;
float u_xlat19;

fragment float4 fx_nv_nodevideo_assetstore_bump_map(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_bump_mapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> source [[texture(1)]],
    texture2d<float> texture0 [[texture(2)]],
    texture2d<float> texture1 [[texture(3)]],
    texture2d<float> texture2 [[texture(4)]],
    texture2d<float> Mask [[texture(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = (int(u._light_type) != 0) ? u._light_pos.xyz : u._light_direction.xyz;
    u_xlat1.xy = in.acScreenNorm.xy;
    u_xlat1.z = 0.0;
    u_xlat1.xyz = u_xlat0.xyz + (-u_xlat1.xyz);
    u_xlat1.xyz = (int(u._light_type) != 0) ? u_xlat1.xyz : u._light_direction.xyz;
    u_xlat18 = u._tex_angle * 0.0174532998;
    u_xlat2.xy = float2(u._height) * float2(0.00100000005, 0.00100000005) + in.acScreenNorm.xy;
    u_xlat2.zw = in.acScreenNorm.yx;
    u_xlat2 = u_xlat2.xzwy + float4(-0.5, -0.5, -0.5, -0.5);
    u_xlat3.x = sin(u_xlat18);
    u_xlat4.x = cos(u_xlat18);
    u_xlat5.x = (-u_xlat3.x);
    u_xlat5.y = u_xlat4.x;
    u_xlat5.z = u_xlat3.x;
    u_xlat3.x = dot(u_xlat2.xy, u_xlat5.yz);
    u_xlat3.y = dot(u_xlat2.xy, u_xlat5.xy);
    u_xlat2.xy = u_xlat3.xy / float2(u._tex_scale.x, u._tex_scale.y);
    u_xlat2.xy = u_xlat2.xy + u._tex_offset.xy;
    u_xlat2.xy = u_xlat2.xy + float2(0.5, 0.5);
    u_xlatb18 = int(u._light_type)==1;
    if(int(u._bumpmap) == 0) {
        u_xlat19 = inputImg.sample(__nv_smp, u_xlat2.xy).x;
    } else {
        u_xlatb3 = int(u._bumpmap)==1;
        if(u_xlatb3){
            u_xlat19 = source.sample(__nv_smp, u_xlat2.xy).x;
        } else {
            u_xlatb3 = int(u._bumpmap)==2;
            if(u_xlatb3){
                u_xlat19 = texture0.sample(__nv_smp, u_xlat2.xy).x;
            } else {
                u_xlatb3 = int(u._bumpmap)==3;
                if(u_xlatb3){
                    u_xlat19 = texture1.sample(__nv_smp, u_xlat2.xy).x;
                } else {
                    u_xlat19 = texture2.sample(__nv_smp, u_xlat2.xy).x;
                }
            }
        }
    }
    u_xlat3.xy = (-float2(u._height)) * float2(0.00100000005, 0.00100000005) + in.acScreenNorm.xy;
    u_xlat3.zw = in.acScreenNorm.yx;
    u_xlat3 = u_xlat3.xzwy + float4(-0.5, -0.5, -0.5, -0.5);
    u_xlat2.x = dot(u_xlat3.xy, u_xlat5.yz);
    u_xlat2.y = dot(u_xlat3.xy, u_xlat5.xy);
    u_xlat2.xy = u_xlat2.xy / float2(u._tex_scale.x, u._tex_scale.y);
    u_xlat2.xy = u_xlat2.xy + u._tex_offset.xy;
    u_xlat2.xy = u_xlat2.xy + float2(0.5, 0.5);
    if(int(u._bumpmap) == 0) {
        u_xlat3.x = inputImg.sample(__nv_smp, u_xlat2.xy).x;
    } else {
        u_xlatb9 = int(u._bumpmap)==1;
        if(u_xlatb9){
            u_xlat3.x = source.sample(__nv_smp, u_xlat2.xy).x;
        } else {
            u_xlatb9 = int(u._bumpmap)==2;
            if(u_xlatb9){
                u_xlat3.x = texture0.sample(__nv_smp, u_xlat2.xy).x;
            } else {
                u_xlatb9 = int(u._bumpmap)==3;
                if(u_xlatb9){
                    u_xlat3.x = texture1.sample(__nv_smp, u_xlat2.xy).x;
                } else {
                    u_xlat3.x = texture2.sample(__nv_smp, u_xlat2.xy).x;
                }
            }
        }
    }
    u_xlat2.x = u_xlat19 + (-u_xlat3.x);
    u_xlat3.x = dot(u_xlat2.zw, u_xlat5.yz);
    u_xlat3.y = dot(u_xlat2.zw, u_xlat5.xy);
    u_xlat14.xy = u_xlat3.xy / float2(u._tex_scale.x, u._tex_scale.y);
    u_xlat14.xy = u_xlat14.xy + u._tex_offset.xy;
    u_xlat14.xy = u_xlat14.xy + float2(0.5, 0.5);
    if(int(u._bumpmap) == 0) {
        u_xlat19 = inputImg.sample(__nv_smp, u_xlat14.xy).x;
    } else {
        u_xlatb3 = int(u._bumpmap)==1;
        if(u_xlatb3){
            u_xlat19 = source.sample(__nv_smp, u_xlat14.xy).x;
        } else {
            u_xlatb3 = int(u._bumpmap)==2;
            if(u_xlatb3){
                u_xlat19 = texture0.sample(__nv_smp, u_xlat14.xy).x;
            } else {
                u_xlatb3 = int(u._bumpmap)==3;
                if(u_xlatb3){
                    u_xlat19 = texture1.sample(__nv_smp, u_xlat14.xy).x;
                } else {
                    u_xlat19 = texture2.sample(__nv_smp, u_xlat14.xy).x;
                }
            }
        }
    }
    u_xlat3.x = dot(u_xlat3.zw, u_xlat5.yz);
    u_xlat3.y = dot(u_xlat3.zw, u_xlat5.xy);
    u_xlat14.xy = u_xlat3.xy / float2(u._tex_scale.x, u._tex_scale.y);
    u_xlat14.xy = u_xlat14.xy + u._tex_offset.xy;
    u_xlat14.xy = u_xlat14.xy + float2(0.5, 0.5);
    if(int(u._bumpmap) == 0) {
        u_xlat3.x = inputImg.sample(__nv_smp, u_xlat14.xy).x;
    } else {
        u_xlatb9 = int(u._bumpmap)==1;
        if(u_xlatb9){
            u_xlat3.x = source.sample(__nv_smp, u_xlat14.xy).x;
        } else {
            u_xlatb9 = int(u._bumpmap)==2;
            if(u_xlatb9){
                u_xlat3.x = texture0.sample(__nv_smp, u_xlat14.xy).x;
            } else {
                u_xlatb9 = int(u._bumpmap)==3;
                if(u_xlatb9){
                    u_xlat3.x = texture1.sample(__nv_smp, u_xlat14.xy).x;
                } else {
                    u_xlat3.x = texture2.sample(__nv_smp, u_xlat14.xy).x;
                }
            }
        }
    }
    u_xlat2.y = u_xlat19 + (-u_xlat3.x);
    u_xlat14.xy = u_xlat2.xy * float2(-0.5, -0.5) + float2(0.5, 0.5);
    u_xlat19 = dot(u_xlat14.xy, u_xlat14.xy);
    u_xlat19 = (-u_xlat19) + 1.0;
    u_xlat3.z = sqrt(u_xlat19);
    u_xlat3.xy = (-u_xlat2.xy);
    u_xlat19 = dot(u_xlat3.xyz, u_xlat3.xyz);
    u_xlat19 = rsqrt(u_xlat19);
    u_xlat2.xyz = float3(u_xlat19) * u_xlat3.xyz;
    u_xlat19 = dot(u_xlat1.xyz, u_xlat1.xyz);
    u_xlat19 = rsqrt(u_xlat19);
    u_xlat1.xyz = float3(u_xlat19) * u_xlat1.xyz;
    u_xlat1.x = dot(u_xlat1.xyz, u_xlat2.xyz);
    u_xlat2.xy = in.acScreenNorm.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat2.z = 0.0;
    u_xlat0.xyz = u_xlat0.xyz + (-u_xlat2.xyz);
    u_xlat0.x = dot(u_xlat0.xyz, u_xlat0.xyz);
    u_xlat0.x = sqrt(u_xlat0.x);
    u_xlat0.x = u_xlatb18 ? u_xlat0.x : float(0.0);
    u_xlat0.x = (-u_xlat0.x) + 1.0;
    u_xlat6.x = u_xlat0.x * u._brightness;
    u_xlat6.x = u_xlat1.x * u_xlat6.x;
    u_xlat2 = u_xlat6.xxxx * u._light_color;
    u_xlat2 = clamp(u_xlat2, 0.0, 1.0);
    u_xlat6.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat3.x = dot(u_xlat6.xy, u_xlat5.yz);
    u_xlat3.y = dot(u_xlat6.xy, u_xlat5.xy);
    u_xlat6.xy = u_xlat3.xy / float2(u._tex_scale.x, u._tex_scale.y);
    u_xlat6.xy = u_xlat6.xy + u._tex_offset.xy;
    u_xlat6.xy = u_xlat6.xy + float2(0.5, 0.5);
    if(int(u._bumpmap) == 0) {
        u_xlat18 = inputImg.sample(__nv_smp, u_xlat6.xy).z;
    } else {
        u_xlatb7 = int(u._bumpmap)==1;
        if(u_xlatb7){
            u_xlat18 = source.sample(__nv_smp, u_xlat6.xy).z;
        } else {
            u_xlatb7 = int(u._bumpmap)==2;
            if(u_xlatb7){
                u_xlat18 = texture0.sample(__nv_smp, u_xlat6.xy).z;
            } else {
                u_xlatb7 = int(u._bumpmap)==3;
                if(u_xlatb7){
                    u_xlat18 = texture1.sample(__nv_smp, u_xlat6.xy).z;
                } else {
                    u_xlat18 = texture2.sample(__nv_smp, u_xlat6.xy).z;
                }
            }
        }
    }
    u_xlat6.x = u_xlat18 * u._specular.xxyz.w;
    u_xlat0.x = log2(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * u._specular.xxyz.y;
    u_xlat0.x = exp2(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * u._brightness;
    u_xlat12 = u._specular.xxyz.z * u._specular.xxyz.y;
    u_xlat18 = log2(u_xlat1.x);
    u_xlat12 = u_xlat18 * u_xlat12;
    u_xlat12 = exp2(u_xlat12);
    u_xlat0.x = u_xlat12 * u_xlat0.x;
    u_xlat1 = u_xlat0.xxxx * u._light_color;
    u_xlat0.x = u_xlat6.x * 0.5;
    u_xlat0 = u_xlat0.xxxx * u_xlat1;
    u_xlat0 = clamp(u_xlat0, 0.0, 1.0);
    u_xlat1 = u_xlat2 + u._ambient_color;
    u_xlat0 = u_xlat0 + u_xlat1;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0 = u_xlat0 * u_xlat1;
    if(int(u._use_inner_mask) != 0) {
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
