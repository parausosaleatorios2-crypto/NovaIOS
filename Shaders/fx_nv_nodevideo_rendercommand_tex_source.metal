// ---------------------------------------------------------------------------
// Rendercommand Tex Source (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-tex-source.xml
// id     : nv.effect.nodevideo-rendercommand-tex-source
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_tex_sourceParams {
    float4 _tex_size;
    float4 _viewport_ratio;
    float _tex_rotation;
    float _start_pos;
    float _end_pos;
    float _crop_offset;
    float _ratio;
    float _has_sam2_mask;
    float _sam2_state;
    float _sam2_dilate;
    float _sam2_color_channel;
    float4 _sam2_outline_color;
    float _sam2_outline;
    float2 _sam2_resolution;
    float _sam2_invert;
    float _has_camera_tracker_mask;
};

// --- funcoes auxiliares do efeito
float2 u_xlat0;
bool2 u_xlatb0;
float4 u_xlat1;
bool4 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
int u_xlati4;
float3 u_xlat5;
float3 u_xlat6;
float2 u_xlat7;
float3 u_xlat8;
bool u_xlatb8;
float u_xlat11;
bool2 u_xlatb11;
float2 u_xlat12;
bool u_xlatb12;
float u_xlat16;
bool u_xlatb16;
float2 u_xlat17;
float u_xlat19;
bool u_xlatb19;
float u_xlat20;
float u_xlat24;
bool u_xlatb24;
float u_xlat27;

fragment float4 fx_nv_nodevideo_rendercommand_tex_source(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_tex_sourceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> sam2_mask [[texture(1)]],
    texture2d<float> camera_tracker_mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0.xy = equal(int4(int4(u._tex_rotation, u._tex_rotation, u._tex_rotation, u._tex_rotation)), int4(90, 270, 0, 0)).xy;
    u_xlatb0.x = u_xlatb0.y || u_xlatb0.x;
    u_xlat8.x = (-u._viewport_ratio.y) + u._viewport_ratio.x;
    u_xlatb8 = abs(u_xlat8.x)<0.00100000005;
    u_xlatb16 = u._ratio>=1.0;
    u_xlat24 = (-u._start_pos) + u._end_pos;
    u_xlat1.zw = in.acScreenNorm.yx * float2(u_xlat24) + float2(float2(u._start_pos, u._start_pos));
    u_xlat1.xy = in.acScreenNorm.xy + float2(float2(u._crop_offset, u._crop_offset));
    u_xlat2 = (bool(u_xlatb16)) ? u_xlat1.xzxz : u_xlat1.wywy;
    u_xlatb16 = u._viewport_ratio.y<u._viewport_ratio.x;
    u_xlat7.xy = (u_xlatb0.x) ? u_xlat1.xz : u_xlat1.wy;
    u_xlat3.xy = (u_xlatb0.x) ? u_xlat1.wy : u_xlat1.xz;
    u_xlat1.xy = u_xlat7.xy;
    u_xlat1 = (bool(u_xlatb16)) ? u_xlat3.xyxy : u_xlat1.xyxy;
    u_xlat1 = (bool(u_xlatb8)) ? u_xlat2 : u_xlat1;
    u_xlat1 = u_xlat1 + float4(-0.5, -0.5, -0.5, -0.5);
    u_xlat1 = u_xlat1 / u._tex_size.yxxy;
    u_xlat8.xy = (u_xlatb0.x) ? u_xlat1.xy : u_xlat1.zw;
    u_xlat8.xy = u_xlat8.xy + float2(0.5, 0.5);
    u_xlatb1.xy = greaterThanEqual(u_xlat8.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlat17.xy = (-u_xlat8.xy) + float2(1.0, 1.0);
    u_xlatb1.zw = greaterThanEqual(u_xlat17.xxxy, float4(0.0, 0.0, 0.0, 0.0)).zw;
    u_xlat1.x = u_xlatb1.x ? float(1.0) : 0.0;
    u_xlat1.y = u_xlatb1.y ? float(1.0) : 0.0;
    u_xlat1.z = u_xlatb1.z ? float(1.0) : 0.0;
    u_xlat1.w = u_xlatb1.w ? float(1.0) : 0.0;
;
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat8.xy);
    u_xlat2 = u_xlat1.xxxx * u_xlat2;
    u_xlat2 = u_xlat1.zzzz * u_xlat2;
    u_xlat2 = u_xlat1.yyyy * u_xlat2;
    u_xlat2 = u_xlat1.wwww * u_xlat2;
    u_xlatb24 = 0<u._has_sam2_mask;
    u_xlatb3 = u._sam2_state!=0;
    u_xlatb24 = u_xlatb24 && u_xlatb3;
    if(u_xlatb24){
        u_xlat3.xy = in.vs_TEXCOORD1.xy + float2(-0.5, -0.5);
        u_xlat3.xy = u_xlat3.xy / u._tex_size.xy;
        u_xlat3.xy = u_xlat3.xy + float2(0.5, 0.5);
        u_xlat0.xy = (u_xlatb0.x) ? u_xlat3.xy : u_xlat8.xy;
        u_xlat16 = sam2_mask.sample(__nv_smp, u_xlat0.xy).x;
        u_xlat24 = u_xlat16 * 0.305306017 + 0.682171106;
        u_xlat24 = u_xlat16 * u_xlat24 + 0.0125228781;
        u_xlat16 = u_xlat24 * u_xlat16;
        u_xlat24 = (-u._sam2_dilate) + 1.0;
        u_xlat24 = float(1.0) / u_xlat24;
        u_xlat16 = u_xlat24 * u_xlat16;
        u_xlat16 = clamp(u_xlat16, 0.0, 1.0);
        u_xlat3.x = u_xlat16 * -2.0 + 3.0;
        u_xlat16 = u_xlat16 * u_xlat16;
        u_xlat11 = u_xlat16 * u_xlat3.x;
        u_xlatb19 = 0<u._sam2_invert;
        u_xlat16 = (-u_xlat3.x) * u_xlat16 + 1.0;
        u_xlat16 = (u_xlatb19) ? u_xlat16 : u_xlat11;
        u_xlatb3 = u._sam2_state==1;
        if(u_xlatb3){
            u_xlat3.x = (-u_xlat16) + 1.0;
            u_xlat4 = u_xlat2.xyzz * u_xlat3.xxxx;
            u_xlatb11.xy = equal(int4(int4(u._sam2_color_channel, u._sam2_color_channel, u._sam2_color_channel, u._sam2_color_channel)), int4(1, 2, 0, 0)).xy;
            u_xlat3.xw = u_xlat2.xy * u_xlat3.xx;
            u_xlat5.xy = (u_xlatb11.y) ? u_xlat3.xw : u_xlat2.xy;
            u_xlat6.xz = u_xlat4.xw;
            u_xlat6.y = u_xlat2.y;
            u_xlat5.z = u_xlat2.z;
            u_xlat3.xyz = (u_xlatb11.x) ? u_xlat6.xyz : u_xlat5.xyz;
            u_xlat4.x = u_xlat2.x;
            u_xlat2.xyz = (int(u._sam2_color_channel) != 0) ? u_xlat3.xyz : u_xlat4.xyz;
            u_xlat3.x = u._sam2_outline * 10.0;
            u_xlat3.xy = u_xlat3.xx / float2(u._sam2_resolution.x, u._sam2_resolution.y);
            u_xlat19 = float(0.0);
            u_xlat27 = float(0.0);
            for(int u_xlati_loop_1 = 0 ; u_xlati_loop_1<16 ; u_xlati_loop_1++)
            {
                u_xlat27 = u_xlat27 + 0.392699093;
                u_xlat5.x = sin(u_xlat27);
                u_xlat6.x = cos(u_xlat27);
                u_xlat6.x = u_xlat3.x * u_xlat6.x;
                u_xlat6.y = u_xlat3.y * u_xlat5.x;
                u_xlat12.xy = u_xlat0.xy + u_xlat6.xy;
                u_xlat12.xy = clamp(u_xlat12.xy, 0.0, 1.0);
                u_xlat12.x = sam2_mask.sample(__nv_smp, u_xlat12.xy).x;
                u_xlat12.x = u_xlat24 * u_xlat12.x;
                u_xlat12.x = clamp(u_xlat12.x, 0.0, 1.0);
                u_xlat20 = u_xlat12.x * -2.0 + 3.0;
                u_xlat12.x = u_xlat12.x * u_xlat12.x;
                u_xlat12.x = u_xlat12.x * u_xlat20;
                u_xlat12.x = u_xlat1.x * u_xlat12.x;
                u_xlat12.x = u_xlat1.z * u_xlat12.x;
                u_xlat12.x = u_xlat1.y * u_xlat12.x;
                u_xlat12.x = u_xlat1.w * u_xlat12.x;
                u_xlat19 = max(u_xlat19, u_xlat12.x);
            }
            u_xlat0.x = u_xlat19 + -0.899999976;
            u_xlat0.x = u_xlat0.x * 9.99999809;
            u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
            u_xlat8.x = u_xlat0.x * -2.0 + 3.0;
            u_xlat0.x = u_xlat0.x * u_xlat0.x;
            u_xlat0.x = u_xlat0.x * u_xlat8.x;
            u_xlat8.x = u_xlat0.x * u._sam2_outline_color.w;
            u_xlat1 = u_xlat8.xxxx * u._sam2_outline_color;
            u_xlat0.x = (-u_xlat0.x) * u._sam2_outline_color.w + 1.0;
            u_xlat3 = (-u_xlat8.xxxx) * u._sam2_outline_color + u_xlat2;
            u_xlat1 = float4(u_xlat16) * u_xlat3 + u_xlat1;
            u_xlat1 = u_xlat8.xxxx * u_xlat1;
            u_xlat2 = u_xlat2 * u_xlat0.xxxx + u_xlat1;
            __nv_out.w = u_xlat2.w;
        } else {
            u_xlat2 = float4(u_xlat16) * u_xlat2;
            __nv_out.w = u_xlat2.w;
        }
    } else {
        __nv_out.w = u_xlat2.w;
    }
    u_xlatb0.x = 0<u._has_camera_tracker_mask;
    if(u_xlatb0.x){
        u_xlat0.x = camera_tracker_mask.sample(__nv_smp, in.acScreenNorm.xy).x;
        u_xlatb0.x = u_xlat0.x<0.5;
        u_xlat2.w = 0.0;
        u_xlat8.xyz = u_xlat2.xyz * float3(0.200000003, 1.0, 0.200000003);
        __nv_out.xyz = (u_xlatb0.x) ? u_xlat2.xww : u_xlat8.xyz;
    } else {
        __nv_out.xyz = u_xlat2.xyz;
    }
    return __nv_out;
    return __nv_out;
}
