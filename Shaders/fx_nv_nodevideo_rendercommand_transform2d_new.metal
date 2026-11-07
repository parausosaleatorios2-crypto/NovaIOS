// ---------------------------------------------------------------------------
// Rendercommand Transform2D New (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-transform2d-new.xml
// id     : nv.effect.nodevideo-rendercommand-transform2d-new
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_transform2d_newParams {
    float _do_motion_warp;
    float2 _asset_size;
    float2 _norm_size;
    float _asset_rotation;
    float4 _viewport_ratio;
    float _amount;
    float _stay;
    float _samples;
    float _enable_motion_blur;
    float _dispersion;
    float _trans_alpha;
    float _enable_motion_tile;
    float _mirror_edges;
    float _phase;
    float _phase_type;
    float _edge_width;
    float2 _asset_scale;
    float _is_image_asset;
    float _tex_rotation;
    float _has_sam2_mask;
    float _sam2_state;
    float _sam2_dilate;
    float _sam2_color_channel;
    float4 _sam2_outline_color;
    float _sam2_outline;
    float2 _sam2_resolution;
    float _sam2_invert;
    float _has_camera_tracker_mask;
    float _texture_wrap_mode;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _output_size eng.acTamanhoDaTela
float4 u_xlat0;
bool4 u_xlatb0;
float4 u_xlat1;
int u_xlati1;
bool4 u_xlatb1;
float4 u_xlat2;
bool4 u_xlatb2;
float4 u_xlat3;
bool4 u_xlatb3;
float4 u_xlat4;
bool4 u_xlatb4;
float3 u_xlat5;
int u_xlati5;
bool3 u_xlatb5;
float4 u_xlat6;
bool2 u_xlatb6;
float4 u_xlat7;
bool2 u_xlatb7;
float3 u_xlat8;
float3 u_xlat9;
bool u_xlatb9;
float2 u_xlat10;
int u_xlati10;
bool u_xlatb10;
float3 u_xlat11;
bool u_xlatb11;
float3 u_xlat12;
int u_xlati12;
float3 u_xlat14;
bool u_xlatb14;
float3 u_xlat15;
bool u_xlatb15;
float2 u_xlat18;
bool2 u_xlatb18;
float2 u_xlat19;
float2 u_xlat20;
bool2 u_xlatb20;
float2 u_xlat21;
int u_xlati21;
bool2 u_xlatb21;
float2 u_xlat23;
bool u_xlatb23;
float2 u_xlat24;
bool2 u_xlatb24;
float u_xlat27;
bool u_xlatb27;
float u_xlat28;
int u_xlati28;
bool u_xlatb28;
float u_xlat29;
bool u_xlatb29;
float u_xlat30;
int u_xlati30;
bool u_xlatb30;
float u_xlat32;
bool u_xlatb32;

fragment float4 fx_nv_nodevideo_rendercommand_transform2d_new(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_transform2d_newParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> camera_tracker_mask [[texture(1)]],
    texture2d<float> MainTex [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0.x = u._enable_motion_tile==1;
    if(u_xlatb0.x){
        u_xlatb0.x = u._do_motion_warp==1;
        if(u_xlatb0.x){
            u_xlat9.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
            u_xlat9.xy = u_xlat9.xy / u._norm_size.xy;
            u_xlat1.xy = u_xlat9.xy + float2(0.5, 0.5);
            u_xlat9.xy = (-u_xlat1.xy) + float2(1.0, 1.0);
            u_xlatb2.xyz = equal(int4(int4(u._asset_rotation, u._asset_rotation, u._asset_rotation, u._asset_rotation)), int4(90, 270, 180, 0)).xyz;
            u_xlat9.xy = (u_xlatb2.z) ? u_xlat9.xy : u_xlat1.xy;
            u_xlat1.zw = (-u_xlat1.xy) + float2(1.0, 1.0);
            u_xlat9.xy = (u_xlatb2.y) ? u_xlat1.yz : u_xlat9.xy;
            u_xlat1.xy = (u_xlatb2.x) ? u_xlat1.wx : u_xlat9.xy;
            u_xlat1.z = (-u_xlat1.y) + 1.0;
            u_xlat9.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5);
            u_xlat9.xy = u_xlat1.xz * float2(u._asset_size.x, u._asset_size.y) + (-u_xlat9.xy);
            u_xlat27 = u_xlat9.y * _warp_params[1];
            u_xlat27 = _warp_params[0] * u_xlat9.x + u_xlat27;
            u_xlat1.x = u_xlat27 + _warp_params[2];
            u_xlat18.x = u_xlat9.y * _warp_params[4];
            u_xlat9.x = _warp_params[3] * u_xlat9.x + u_xlat18.x;
            u_xlat1.y = u_xlat9.x + _warp_params[5];
            u_xlat9.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5) + u_xlat1.xy;
            u_xlat1.xy = u_xlat9.xy / float2(u._asset_size.x, u._asset_size.y);
            u_xlat3.xy = (-u_xlat1.yx) + float2(1.0, 1.0);
            u_xlat3.z = (-u_xlat3.x) + 1.0;
            u_xlat1.z = (-u_xlat1.y) + 1.0;
            u_xlat9.xy = (u_xlatb2.z) ? u_xlat3.yz : u_xlat1.xz;
            u_xlat9.xy = (u_xlatb2.y) ? u_xlat1.yx : u_xlat9.xy;
            u_xlat9.xy = (u_xlatb2.x) ? u_xlat3.xy : u_xlat9.xy;
            u_xlat9.xy = u_xlat9.xy + float2(-0.5, -0.5);
            u_xlat9.xy = u_xlat9.xy * u._norm_size.xy + float2(0.5, 0.5);
        } else {
            u_xlat9.xy = in.acScreenNorm.xy;
        }
        u_xlat9.xy = u_xlat9.xy + float2(-0.5, -0.5);
        u_xlat9.xy = u_xlat9.xy * u._viewport_ratio.xy;
        u_xlat18.xy = u_xlat9.yy * hlslcc_mtx4x4_trans_mat[1].xy;
        u_xlat9.xy = hlslcc_mtx4x4_trans_mat[0].xy * u_xlat9.xx + u_xlat18.xy;
        u_xlat9.xy = u_xlat9.xy + hlslcc_mtx4x4_trans_mat[3].xy;
        u_xlat9.xy = u_xlat9.xy * u._asset_scale.xy;
        u_xlat27 = min(u._asset_scale.y, u._asset_scale.x);
        u_xlat9.xy = u_xlat9.xy / float2(u_xlat27);
        u_xlatb1 = equal(int4(u._tex_rotation, u._tex_rotation, u._is_image_asset, u._tex_rotation), int4(90, 270, 1, 180));
        u_xlatb1.x = u_xlatb1.y || u_xlatb1.x;
        u_xlatb10 = _ProjectionParams.x<0.0;
        u_xlat2.xy = (bool(u_xlatb10)) ? float2(1.0, -1.0) : float2(-1.0, 1.0);
        u_xlat20.y = (u_xlatb1.z) ? u_xlat2.y : u_xlat2.x;
        u_xlat2.y = (-u_xlat20.y);
        u_xlat2.x = float(-1.0);
        u_xlat20.x = float(1.0);
        u_xlat10.xy = (u_xlatb1.w) ? u_xlat2.xy : u_xlat20.xy;
        u_xlat1.xy = (u_xlatb1.x) ? float2(1.0, 1.0) : u_xlat10.xy;
        u_xlat9.xy = u_xlat9.xy * u_xlat1.xy;
        u_xlat9.xy = u_xlat9.xy / u._viewport_ratio.xy;
        u_xlat19.x = u._edge_width * 0.00999999978 + 1.0;
        u_xlat9.xy = u_xlat9.xy * u_xlat19.xx + float2(0.5, 0.5);
        if(u._phase_type == 0) {
            u_xlatb28 = u_xlat9.y>=0.0;
            u_xlat2.x = abs(u_xlat9.y) + 1.0;
            u_xlat28 = (u_xlatb28) ? u_xlat9.y : u_xlat2.x;
            u_xlat28 = u_xlat28 * 0.5;
            u_xlatb2.x = u_xlat28>=(-u_xlat28);
            u_xlat28 = fract(abs(u_xlat28));
            u_xlat28 = (u_xlatb2.x) ? u_xlat28 : (-u_xlat28);
            u_xlatb28 = u_xlat28>=0.5;
            u_xlat2.x = u_xlatb28 ? 1.0 : float(0.0);
            u_xlat2.x = u_xlat2.x * u._phase + u_xlat9.x;
            u_xlatb11 = u_xlat2.x>=0.0;
            u_xlat20.x = abs(u_xlat2.x) + 1.0;
            u_xlat11.x = (u_xlatb11) ? u_xlat2.x : u_xlat20.x;
            u_xlat3.x = fract(u_xlat2.x);
            u_xlat3.y = fract(u_xlat9.y);
            u_xlatb2.x = u._mirror_edges==1;
            u_xlat11.x = u_xlat11.x * 0.5;
            u_xlatb20.x = u_xlat11.x>=(-u_xlat11.x);
            u_xlat11.x = fract(abs(u_xlat11.x));
            u_xlat11.x = (u_xlatb20.x) ? u_xlat11.x : (-u_xlat11.x);
            u_xlatb11 = u_xlat11.x>=0.5;
            u_xlatb11 = u_xlatb11 && u_xlatb2.x;
            u_xlat20.xy = (-u_xlat3.xy) + float2(1.0, 1.0);
            u_xlat4.x = (u_xlatb11) ? u_xlat20.x : u_xlat3.x;
            u_xlatb28 = u_xlatb28 && u_xlatb2.x;
            u_xlat4.y = (u_xlatb28) ? u_xlat20.y : u_xlat3.y;
        } else {
            u_xlatb28 = u_xlat9.x>=0.0;
            u_xlat2.x = abs(u_xlat9.x) + 1.0;
            u_xlat28 = (u_xlatb28) ? u_xlat9.x : u_xlat2.x;
            u_xlat28 = u_xlat28 * 0.5;
            u_xlatb2.x = u_xlat28>=(-u_xlat28);
            u_xlat28 = fract(abs(u_xlat28));
            u_xlat28 = (u_xlatb2.x) ? u_xlat28 : (-u_xlat28);
            u_xlatb28 = u_xlat28>=0.5;
            u_xlat2.x = u_xlatb28 ? 1.0 : float(0.0);
            u_xlat18.x = u_xlat2.x * u._phase + u_xlat9.y;
            u_xlatb2.x = u_xlat18.x>=0.0;
            u_xlat11.x = abs(u_xlat18.x) + 1.0;
            u_xlat2.x = (u_xlatb2.x) ? u_xlat18.x : u_xlat11.x;
            u_xlat3.x = fract(u_xlat9.x);
            u_xlat3.y = fract(u_xlat18.x);
            u_xlatb9 = u._mirror_edges==1;
            u_xlatb18.x = u_xlatb28 && u_xlatb9;
            u_xlat11.xy = (-u_xlat3.xy) + float2(1.0, 1.0);
            u_xlat4.x = (u_xlatb18.x) ? u_xlat11.x : u_xlat3.x;
            u_xlat18.x = u_xlat2.x * 0.5;
            u_xlatb28 = u_xlat18.x>=(-u_xlat18.x);
            u_xlat18.x = fract(abs(u_xlat18.x));
            u_xlat18.x = (u_xlatb28) ? u_xlat18.x : (-u_xlat18.x);
            u_xlatb18.x = u_xlat18.x>=0.5;
            u_xlatb9 = u_xlatb18.x && u_xlatb9;
            u_xlat4.y = (u_xlatb9) ? u_xlat11.y : u_xlat3.y;
        }
        u_xlat9.xy = u_xlat4.xy + float2(-0.5, -0.5);
        u_xlat9.xy = u_xlat9.xy / u_xlat19.xx;
        u_xlat9.xy = u_xlat9.xy + float2(0.5, 0.5);
        u_xlatb28 = u._texture_wrap_mode==2;
        if(u_xlatb28){
            u_xlat2 = MainTex.sample(__nv_smp, u_xlat9.xy);
        } else {
            u_xlat2 = MainTex.sample(__nv_smp, u_xlat9.xy);
        }
        u_xlat2.xyz = u_xlat2.www * u_xlat2.xyz;
        u_xlatb28 = 0<u._enable_motion_blur;
        if(u_xlatb28){
            if(u_xlatb0.x){
                u_xlat3.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
                u_xlat3.xy = u_xlat3.xy / u._norm_size.xy;
                u_xlat3.xy = u_xlat3.xy + float2(0.5, 0.5);
                u_xlat4.xy = (-u_xlat3.xy) + float2(1.0, 1.0);
                u_xlatb5.xyz = equal(int4(int4(u._asset_rotation, u._asset_rotation, u._asset_rotation, u._asset_rotation)), int4(90, 270, 180, 0)).xyz;
                u_xlat4.xy = (u_xlatb5.z) ? u_xlat4.xy : u_xlat3.xy;
                u_xlat3.zw = (-u_xlat3.xy) + float2(1.0, 1.0);
                u_xlat12.xy = (u_xlatb5.y) ? u_xlat3.yz : u_xlat4.xy;
                u_xlat3.xy = (u_xlatb5.x) ? u_xlat3.wx : u_xlat12.xy;
                u_xlat3.z = (-u_xlat3.y) + 1.0;
                u_xlat12.xz = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5);
                u_xlat3.xy = u_xlat3.xz * float2(u._asset_size.x, u._asset_size.y) + (-u_xlat12.xz);
                u_xlat28 = u_xlat3.y * _warp_params[1];
                u_xlat28 = _warp_params[0] * u_xlat3.x + u_xlat28;
                u_xlat4.x = u_xlat28 + _warp_params[2];
                u_xlat28 = u_xlat3.y * _warp_params[4];
                u_xlat28 = _warp_params[3] * u_xlat3.x + u_xlat28;
                u_xlat4.y = u_xlat28 + _warp_params[5];
                u_xlat3.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5) + u_xlat4.xy;
                u_xlat3.xy = u_xlat3.xy / float2(u._asset_size.x, u._asset_size.y);
                u_xlat4.xy = (-u_xlat3.yx) + float2(1.0, 1.0);
                u_xlat4.z = (-u_xlat4.x) + 1.0;
                u_xlat3.z = (-u_xlat3.y) + 1.0;
                u_xlat21.xy = (u_xlatb5.z) ? u_xlat4.yz : u_xlat3.xz;
                u_xlat3.xy = (u_xlatb5.y) ? u_xlat3.yx : u_xlat21.xy;
                u_xlat3.xy = (u_xlatb5.x) ? u_xlat4.xy : u_xlat3.xy;
                u_xlat3.xy = u_xlat3.xy + float2(-0.5, -0.5);
                u_xlat3.xy = u_xlat3.xy * u._norm_size.xy + float2(0.5, 0.5);
            } else {
                u_xlat3.xy = in.acScreenNorm.xy;
            }
            u_xlat3.xy = u_xlat3.xy + float2(-0.5, -0.5);
            u_xlat3.xy = u_xlat3.xy * u._viewport_ratio.xy;
            u_xlat12.xy = u_xlat3.yy * hlslcc_mtx4x4_trans_mat[1].xy;
            u_xlat3.xy = hlslcc_mtx4x4_trans_mat[0].xy * u_xlat3.xx + u_xlat12.xy;
            u_xlat3.xy = u_xlat3.xy + hlslcc_mtx4x4_trans_mat[3].xy;
            u_xlat3.xy = u_xlat3.xy * u._asset_scale.xy;
            u_xlat3.xy = u_xlat3.xy / float2(u_xlat27);
            u_xlat3.xy = u_xlat1.xy * u_xlat3.xy;
            u_xlat3.xy = u_xlat3.xy / u._viewport_ratio.xy;
            if(u_xlatb0.x){
                u_xlat21.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
                u_xlat21.xy = u_xlat21.xy / u._norm_size.xy;
                u_xlat4.xy = u_xlat21.xy + float2(0.5, 0.5);
                u_xlat21.xy = (-u_xlat4.xy) + float2(1.0, 1.0);
                u_xlatb5.xyz = equal(int4(int4(u._asset_rotation, u._asset_rotation, u._asset_rotation, u._asset_rotation)), int4(90, 270, 180, 0)).xyz;
                u_xlat21.xy = (u_xlatb5.z) ? u_xlat21.xy : u_xlat4.xy;
                u_xlat4.zw = (-u_xlat4.xy) + float2(1.0, 1.0);
                u_xlat21.xy = (u_xlatb5.y) ? u_xlat4.yz : u_xlat21.xy;
                u_xlat4.xy = (u_xlatb5.x) ? u_xlat4.wx : u_xlat21.xy;
                u_xlat4.z = (-u_xlat4.y) + 1.0;
                u_xlat21.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5);
                u_xlat21.xy = u_xlat4.xz * float2(u._asset_size.x, u._asset_size.y) + (-u_xlat21.xy);
                u_xlat0.x = u_xlat21.y * _warp_params[1];
                u_xlat0.x = _warp_params[0] * u_xlat21.x + u_xlat0.x;
                u_xlat4.x = u_xlat0.x + _warp_params[2];
                u_xlat0.x = u_xlat21.y * _warp_params[4];
                u_xlat0.x = _warp_params[3] * u_xlat21.x + u_xlat0.x;
                u_xlat4.y = u_xlat0.x + _warp_params[5];
                u_xlat21.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5) + u_xlat4.xy;
                u_xlat4.xy = u_xlat21.xy / float2(u._asset_size.x, u._asset_size.y);
                u_xlat6.xy = (-u_xlat4.yx) + float2(1.0, 1.0);
                u_xlat6.z = (-u_xlat6.x) + 1.0;
                u_xlat4.z = (-u_xlat4.y) + 1.0;
                u_xlat21.xy = (u_xlatb5.z) ? u_xlat6.yz : u_xlat4.xz;
                u_xlat21.xy = (u_xlatb5.y) ? u_xlat4.yx : u_xlat21.xy;
                u_xlat21.xy = (u_xlatb5.x) ? u_xlat6.xy : u_xlat21.xy;
                u_xlat21.xy = u_xlat21.xy + float2(-0.5, -0.5);
                u_xlat3.zw = u_xlat21.xy * u._norm_size.xy + float2(0.5, 0.5);
            } else {
                u_xlat3.zw = in.acScreenNorm.xy;
            }
            u_xlat3 = u_xlat3 + float4(0.5, 0.5, -0.5, -0.5);
            u_xlat21.xy = u_xlat3.zw * u._viewport_ratio.xy;
            u_xlat4.xy = u_xlat21.yy * hlslcc_mtx4x4_trans_mat_prev[1].xy;
            u_xlat21.xy = hlslcc_mtx4x4_trans_mat_prev[0].xy * u_xlat21.xx + u_xlat4.xy;
            u_xlat21.xy = u_xlat21.xy + hlslcc_mtx4x4_trans_mat_prev[3].xy;
            u_xlat21.xy = u_xlat21.xy * u._asset_scale.xy;
            u_xlat0.xw = u_xlat21.xy / float2(u_xlat27);
            u_xlat0.xw = u_xlat1.xy * u_xlat0.xw;
            u_xlat0.xw = u_xlat0.xw / u._viewport_ratio.xy;
            u_xlat0.xw = u_xlat0.xw + float2(0.5, 0.5);
            u_xlat0.xw = (-u_xlat0.xw) + u_xlat3.xy;
            u_xlat0.xw = u_xlat0.xw * float2(u._amount);
            u_xlati1 = u._samples + int(0xFFFFFFFFu);
            u_xlat1.x = float(u_xlati1);
            u_xlat4 = u_xlat2;
            u_xlati10 = u._mirror_edges;
            u_xlati28 = u._phase_type;
            u_xlati21 = u._texture_wrap_mode;
            for(int u_xlati_loop_1 = 1 ; u_xlati_loop_1<u._samples ; u_xlati_loop_1++)
            {
                u_xlat5.x = float(u_xlati_loop_1);
                u_xlat5.x = u_xlat5.x / u_xlat1.x;
                u_xlat14.xy = (-u_xlat0.xw) * u_xlat5.xx + u_xlat3.xy;
                u_xlat14.xy = u_xlat14.xy + float2(-0.5, -0.5);
                u_xlat14.xy = u_xlat14.xy * u_xlat19.xx + float2(0.5, 0.5);
                if(u_xlati28 == 0) {
                    u_xlatb32 = u_xlat14.y>=0.0;
                    u_xlat6.x = abs(u_xlat14.y) + 1.0;
                    u_xlat32 = (u_xlatb32) ? u_xlat14.y : u_xlat6.x;
                    u_xlat32 = u_xlat32 * 0.5;
                    u_xlatb6.x = u_xlat32>=(-u_xlat32);
                    u_xlat32 = fract(abs(u_xlat32));
                    u_xlat32 = (u_xlatb6.x) ? u_xlat32 : (-u_xlat32);
                    u_xlatb32 = u_xlat32>=0.5;
                    u_xlat6.x = u_xlatb32 ? 1.0 : float(0.0);
                    u_xlat6.x = u_xlat6.x * u._phase + u_xlat14.x;
                    u_xlatb15 = u_xlat6.x>=0.0;
                    u_xlat24.x = abs(u_xlat6.x) + 1.0;
                    u_xlat15.x = (u_xlatb15) ? u_xlat6.x : u_xlat24.x;
                    u_xlat7.x = fract(u_xlat6.x);
                    u_xlat7.y = fract(u_xlat14.y);
                    u_xlatb6.x = u_xlati10==1;
                    u_xlat15.x = u_xlat15.x * 0.5;
                    u_xlatb24.x = u_xlat15.x>=(-u_xlat15.x);
                    u_xlat15.x = fract(abs(u_xlat15.x));
                    u_xlat15.x = (u_xlatb24.x) ? u_xlat15.x : (-u_xlat15.x);
                    u_xlatb15 = u_xlat15.x>=0.5;
                    u_xlatb15 = u_xlatb15 && u_xlatb6.x;
                    u_xlat24.xy = (-u_xlat7.xy) + float2(1.0, 1.0);
                    u_xlat8.x = (u_xlatb15) ? u_xlat24.x : u_xlat7.x;
                    u_xlatb32 = u_xlatb32 && u_xlatb6.x;
                    u_xlat8.y = (u_xlatb32) ? u_xlat24.y : u_xlat7.y;
                } else {
                    u_xlatb32 = u_xlat14.x>=0.0;
                    u_xlat6.x = abs(u_xlat14.x) + 1.0;
                    u_xlat32 = (u_xlatb32) ? u_xlat14.x : u_xlat6.x;
                    u_xlat32 = u_xlat32 * 0.5;
                    u_xlatb6.x = u_xlat32>=(-u_xlat32);
                    u_xlat32 = fract(abs(u_xlat32));
                    u_xlat32 = (u_xlatb6.x) ? u_xlat32 : (-u_xlat32);
                    u_xlatb32 = u_xlat32>=0.5;
                    u_xlat6.x = u_xlatb32 ? 1.0 : float(0.0);
                    u_xlat23.x = u_xlat6.x * u._phase + u_xlat14.y;
                    u_xlatb6.x = u_xlat23.x>=0.0;
                    u_xlat15.x = abs(u_xlat23.x) + 1.0;
                    u_xlat6.x = (u_xlatb6.x) ? u_xlat23.x : u_xlat15.x;
                    u_xlat7.x = fract(u_xlat14.x);
                    u_xlat7.y = fract(u_xlat23.x);
                    u_xlatb14 = u_xlati10==1;
                    u_xlatb23 = u_xlatb32 && u_xlatb14;
                    u_xlat15.xy = (-u_xlat7.xy) + float2(1.0, 1.0);
                    u_xlat8.x = (u_xlatb23) ? u_xlat15.x : u_xlat7.x;
                    u_xlat23.x = u_xlat6.x * 0.5;
                    u_xlatb32 = u_xlat23.x>=(-u_xlat23.x);
                    u_xlat23.x = fract(abs(u_xlat23.x));
                    u_xlat23.x = (u_xlatb32) ? u_xlat23.x : (-u_xlat23.x);
                    u_xlatb23 = u_xlat23.x>=0.5;
                    u_xlatb14 = u_xlatb23 && u_xlatb14;
                    u_xlat8.y = (u_xlatb14) ? u_xlat15.y : u_xlat7.y;
                }
                u_xlat14.xy = u_xlat8.xy + float2(-0.5, -0.5);
                u_xlat14.xy = u_xlat14.xy / u_xlat19.xx;
                u_xlat14.xy = u_xlat14.xy + float2(0.5, 0.5);
                u_xlatb32 = u_xlati21==2;
                if(u_xlatb32){
                    u_xlat6 = MainTex.sample(__nv_smp, u_xlat14.xy);
                } else {
                    u_xlat6 = MainTex.sample(__nv_smp, u_xlat14.xy);
                }
                u_xlat14.xyz = u_xlat6.www * u_xlat6.xyz;
                u_xlat7.z = u_xlat5.x * 3.0 + -1.5;
                u_xlat7.y = -abs(u_xlat7.z) + 1.0;
                u_xlat7.x = (-u_xlat7.z);
                u_xlat7.xyz = u_xlat7.xyz;
                u_xlat7.xyz = clamp(u_xlat7.xyz, 0.0, 1.0);
                u_xlat7.xyz = u_xlat14.xyz * u_xlat7.xyz;
                u_xlat7.xyz = u_xlat7.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat14.xyz);
                u_xlat6.xyz = float3(u._dispersion) * u_xlat7.xyz + u_xlat14.xyz;
                u_xlat4 = u_xlat4 + u_xlat6;
                u_xlat4.xyz = u_xlat2.xyz * float3(float3(u._stay, u._stay, u._stay)) + u_xlat4.xyz;
            }
            u_xlat0.x = float(u._samples);
            u_xlat2 = u_xlat4 / u_xlat0.xxxx;
        }
        u_xlat0.xw = (-float2(_output_size.x, _output_size.y)) + float2(1.0, 1.0);
        u_xlatb1.xy = greaterThanEqual(in.acScreenNorm.xyxx, u_xlat0.xwxx).xy;
        u_xlat19.xy = (-in.acScreenNorm.xy) + float2(1.0, 1.0);
        u_xlatb0.xw = greaterThanEqual(u_xlat19.xxxy, u_xlat0.xxxw).xw;
        u_xlat1.x = u_xlatb1.x ? float(1.0) : 0.0;
        u_xlat1.y = u_xlatb1.y ? float(1.0) : 0.0;
;
        u_xlat0.x = u_xlatb0.x ? float(1.0) : 0.0;
        u_xlat0.w = u_xlatb0.w ? float(1.0) : 0.0;
;
        u_xlat2 = u_xlat1.xxxx * u_xlat2;
        u_xlat2 = u_xlat0.xxxx * u_xlat2;
        u_xlat1 = u_xlat1.yyyy * u_xlat2;
        u_xlat1 = u_xlat0.wwww * u_xlat1;
        u_xlatb0.xw = greaterThanEqual(float4(0.0, 0.0, 0.0, 0.0), u_xlat9.xxxy).xw;
        u_xlatb2.xy = greaterThanEqual(u_xlat9.xyxx, float4(1.0, 1.0, 0.0, 0.0)).xy;
        u_xlatb0.x = u_xlatb0.x || u_xlatb2.x;
        u_xlatb0.x = u_xlatb0.w || u_xlatb0.x;
        u_xlatb0.x = u_xlatb2.y || u_xlatb0.x;
        u_xlat0.x = (u_xlatb0.x) ? 0.0 : 1.0;
        u_xlat1 = u_xlat0.xxxx * u_xlat1;
        u_xlatb0.x = 0<u._has_sam2_mask;
        u_xlatb27 = u._sam2_state!=0;
        u_xlatb0.x = u_xlatb27 && u_xlatb0.x;
        if(u_xlatb0.x){
            u_xlat0.x = inputImg.sample(__nv_smp, u_xlat9.xy).x;
            u_xlat9.x = u_xlat0.x * 0.305306017 + 0.682171106;
            u_xlat9.x = u_xlat0.x * u_xlat9.x + 0.0125228781;
            u_xlat0.x = u_xlat9.x * u_xlat0.x;
            u_xlat9.x = (-u._sam2_dilate) + 1.0;
            u_xlat9.x = float(1.0) / u_xlat9.x;
            u_xlat0.x = u_xlat9.x * u_xlat0.x;
            u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
            u_xlat9.x = u_xlat0.x * -2.0 + 3.0;
            u_xlat0.x = u_xlat0.x * u_xlat0.x;
            u_xlat18.x = u_xlat0.x * u_xlat9.x;
            u_xlatb27 = 0<u._sam2_invert;
            u_xlat0.x = (-u_xlat9.x) * u_xlat0.x + 1.0;
            u_xlat0.x = (u_xlatb27) ? u_xlat0.x : u_xlat18.x;
            u_xlat9.x = (-u_xlat0.x) + 1.0;
            u_xlatb18.xy = equal(int4(u._sam2_state, u._sam2_color_channel, u._sam2_state, u._sam2_color_channel), int4(1, 1, 1, 1)).xy;
            u_xlat2 = u_xlat9.xxxx * u_xlat1.xyzz;
            u_xlat3.xy = u_xlat9.xx * u_xlat1.xy;
            u_xlat4.xz = u_xlat2.xw;
            u_xlat4.y = u_xlat1.y;
            u_xlat3.z = u_xlat1.z;
            u_xlat3.xyz = (u_xlatb18.y) ? u_xlat4.xyz : u_xlat3.xyz;
            u_xlat2.xw = u_xlat1.xw;
            u_xlat2.xyz = (int(u._sam2_color_channel) != 0) ? u_xlat3.xyz : u_xlat2.xyz;
            u_xlat3 = u_xlat0.xxxx * u_xlat1;
            u_xlat1 = (u_xlatb18.x) ? u_xlat2 : u_xlat3;
        }
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        u_xlatb0.x = u._do_motion_warp==1;
        if(u_xlatb0.x){
            u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
            u_xlat0.xy = u_xlat0.xy / u._norm_size.xy;
            u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
            u_xlat2.xy = (-u_xlat0.xy) + float2(1.0, 1.0);
            u_xlatb3.xyz = equal(int4(int4(u._asset_rotation, u._asset_rotation, u._asset_rotation, u._asset_rotation)), int4(90, 270, 180, 0)).xyz;
            u_xlat2.xy = (u_xlatb3.z) ? u_xlat2.xy : u_xlat0.xy;
            u_xlat0.zw = (-u_xlat0.xy) + float2(1.0, 1.0);
            u_xlat9.xy = (u_xlatb3.y) ? u_xlat0.yz : u_xlat2.xy;
            u_xlat0.xy = (u_xlatb3.x) ? u_xlat0.wx : u_xlat9.xy;
            u_xlat0.z = (-u_xlat0.y) + 1.0;
            u_xlat9.xz = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5);
            u_xlat0.xy = u_xlat0.xz * float2(u._asset_size.x, u._asset_size.y) + (-u_xlat9.xz);
            u_xlat18.x = u_xlat0.y * _warp_params[1];
            u_xlat18.x = _warp_params[0] * u_xlat0.x + u_xlat18.x;
            u_xlat2.x = u_xlat18.x + _warp_params[2];
            u_xlat9.x = u_xlat0.y * _warp_params[4];
            u_xlat0.x = _warp_params[3] * u_xlat0.x + u_xlat9.x;
            u_xlat2.y = u_xlat0.x + _warp_params[5];
            u_xlat0.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5) + u_xlat2.xy;
            u_xlat0.xy = u_xlat0.xy / float2(u._asset_size.x, u._asset_size.y);
            u_xlat2.xy = (-u_xlat0.yx) + float2(1.0, 1.0);
            u_xlat2.z = (-u_xlat2.x) + 1.0;
            u_xlat0.z = (-u_xlat0.y) + 1.0;
            u_xlat18.xy = (u_xlatb3.z) ? u_xlat2.yz : u_xlat0.xz;
            u_xlat0.xy = (u_xlatb3.y) ? u_xlat0.yx : u_xlat18.xy;
            u_xlat0.xy = (u_xlatb3.x) ? u_xlat2.xy : u_xlat0.xy;
            u_xlat0.xy = u_xlat0.xy + float2(-0.5, -0.5);
            u_xlat0.xy = u_xlat0.xy * u._norm_size.xy + float2(0.5, 0.5);
        } else {
            u_xlat0.xy = in.acScreenNorm.xy;
        }
        u_xlat0.xy = u_xlat0.xy + float2(-0.5, -0.5);
        u_xlat0.xy = u_xlat0.xy * u._viewport_ratio.xy;
        u_xlat9.xy = u_xlat0.yy * hlslcc_mtx4x4_trans_mat[1].xy;
        u_xlat0.xy = hlslcc_mtx4x4_trans_mat[0].xy * u_xlat0.xx + u_xlat9.xy;
        u_xlat0.xy = u_xlat0.xy + hlslcc_mtx4x4_trans_mat[3].xy;
        u_xlat0.xy = u_xlat0.xy * u._asset_scale.xy;
        u_xlat18.x = min(u._asset_scale.y, u._asset_scale.x);
        u_xlat0.xy = u_xlat0.xy / u_xlat18.xx;
        u_xlatb2 = equal(int4(u._tex_rotation, u._tex_rotation, u._is_image_asset, u._tex_rotation), int4(90, 270, 1, 180));
        u_xlatb18.x = u_xlatb2.y || u_xlatb2.x;
        u_xlatb27 = _ProjectionParams.x<0.0;
        u_xlat2.xy = (bool(u_xlatb27)) ? float2(1.0, -1.0) : float2(-1.0, 1.0);
        u_xlat21.y = (u_xlatb2.z) ? u_xlat2.y : u_xlat2.x;
        u_xlat3.y = (-u_xlat21.y);
        u_xlat3.x = float(-1.0);
        u_xlat21.x = float(1.0);
        u_xlat2.xy = (u_xlatb2.w) ? u_xlat3.xy : u_xlat21.xy;
        u_xlat18.xy = (u_xlatb18.x) ? float2(1.0, 1.0) : u_xlat2.xy;
        u_xlat0.xy = u_xlat18.xy * u_xlat0.xy;
        u_xlat0.xy = u_xlat0.xy / u._viewport_ratio.xy;
        u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
        u_xlatb18.xy = equal(int4(int4(u._texture_wrap_mode, u._texture_wrap_mode, u._texture_wrap_mode, u._texture_wrap_mode)), int4(2, 0, 2, 0)).xy;
        if(u_xlatb18.x){
            u_xlat2 = MainTex.sample(__nv_smp, u_xlat0.xy);
        } else {
            u_xlat2 = MainTex.sample(__nv_smp, u_xlat0.xy);
        }
        u_xlat2.xyz = u_xlat2.www * u_xlat2.xyz;
        u_xlatb18.x = 0<u._enable_motion_blur;
        if(u_xlatb18.x){
            u_xlatb3.x = u._do_motion_warp==1;
            if(u_xlatb3.x){
                u_xlat3.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
                u_xlat3.xy = u_xlat3.xy / u._norm_size.xy;
                u_xlat3.xy = u_xlat3.xy + float2(0.5, 0.5);
                u_xlat4.xy = (-u_xlat3.xy) + float2(1.0, 1.0);
                u_xlatb5.xyz = equal(int4(int4(u._asset_rotation, u._asset_rotation, u._asset_rotation, u._asset_rotation)), int4(90, 270, 180, 0)).xyz;
                u_xlat4.xy = (u_xlatb5.z) ? u_xlat4.xy : u_xlat3.xy;
                u_xlat3.zw = (-u_xlat3.xy) + float2(1.0, 1.0);
                u_xlat12.xy = (u_xlatb5.y) ? u_xlat3.yz : u_xlat4.xy;
                u_xlat3.xy = (u_xlatb5.x) ? u_xlat3.wx : u_xlat12.xy;
                u_xlat3.z = (-u_xlat3.y) + 1.0;
                u_xlat12.xz = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5);
                u_xlat3.xy = u_xlat3.xz * float2(u._asset_size.x, u._asset_size.y) + (-u_xlat12.xz);
                u_xlat21.x = u_xlat3.y * _warp_params[1];
                u_xlat21.x = _warp_params[0] * u_xlat3.x + u_xlat21.x;
                u_xlat4.x = u_xlat21.x + _warp_params[2];
                u_xlat12.x = u_xlat3.y * _warp_params[4];
                u_xlat3.x = _warp_params[3] * u_xlat3.x + u_xlat12.x;
                u_xlat4.y = u_xlat3.x + _warp_params[5];
                u_xlat3.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5) + u_xlat4.xy;
                u_xlat3.xy = u_xlat3.xy / float2(u._asset_size.x, u._asset_size.y);
                u_xlat4.xy = (-u_xlat3.yx) + float2(1.0, 1.0);
                u_xlat4.z = (-u_xlat4.x) + 1.0;
                u_xlat3.z = (-u_xlat3.y) + 1.0;
                u_xlat21.xy = (u_xlatb5.z) ? u_xlat4.yz : u_xlat3.xz;
                u_xlat3.xy = (u_xlatb5.y) ? u_xlat3.yx : u_xlat21.xy;
                u_xlat3.xy = (u_xlatb5.x) ? u_xlat4.xy : u_xlat3.xy;
                u_xlat3.xy = u_xlat3.xy + float2(-0.5, -0.5);
                u_xlat3.xy = u_xlat3.xy * u._norm_size.xy + float2(0.5, 0.5);
            } else {
                u_xlat3.xy = in.acScreenNorm.xy;
            }
            u_xlat3.xy = u_xlat3.xy + float2(-0.5, -0.5);
            u_xlat3.xy = u_xlat3.xy * u._viewport_ratio.xy;
            u_xlat12.xy = u_xlat3.yy * hlslcc_mtx4x4_trans_mat_prev[1].xy;
            u_xlat3.xy = hlslcc_mtx4x4_trans_mat_prev[0].xy * u_xlat3.xx + u_xlat12.xy;
            u_xlat3.xy = u_xlat3.xy + hlslcc_mtx4x4_trans_mat_prev[3].xy;
            u_xlat3.xy = u_xlat3.xy * u._asset_scale.xy;
            u_xlat21.x = min(u._asset_scale.y, u._asset_scale.x);
            u_xlat3.xy = u_xlat3.xy / u_xlat21.xx;
            u_xlatb4 = equal(int4(u._tex_rotation, u._tex_rotation, u._is_image_asset, u._tex_rotation), int4(90, 270, 1, 180));
            u_xlatb21.x = u_xlatb4.y || u_xlatb4.x;
            u_xlatb30 = _ProjectionParams.x<0.0;
            u_xlat4.xy = (bool(u_xlatb30)) ? float2(1.0, -1.0) : float2(-1.0, 1.0);
            u_xlat23.y = (u_xlatb4.z) ? u_xlat4.y : u_xlat4.x;
            u_xlat5.y = (-u_xlat23.y);
            u_xlat5.x = float(-1.0);
            u_xlat23.x = float(1.0);
            u_xlat4.xy = (u_xlatb4.w) ? u_xlat5.xy : u_xlat23.xy;
            u_xlat21.xy = (u_xlatb21.x) ? float2(1.0, 1.0) : u_xlat4.xy;
            u_xlat3.xy = u_xlat21.xy * u_xlat3.xy;
            u_xlat3.xy = u_xlat3.xy / u._viewport_ratio.xy;
            u_xlat3.xy = u_xlat3.xy + float2(0.5, 0.5);
            u_xlat3.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat3.xy = u_xlat3.xy * float2(u._amount);
            u_xlati21 = u._samples + int(0xFFFFFFFFu);
            u_xlat21.x = float(u_xlati21);
            u_xlat4 = u_xlat2;
            u_xlati30 = u._texture_wrap_mode;
            for(int u_xlati_loop_2 = 1 ; u_xlati_loop_2<u._samples ; u_xlati_loop_2++)
            {
                u_xlat14.x = float(u_xlati_loop_2);
                u_xlat14.x = u_xlat14.x / u_xlat21.x;
                u_xlat23.xy = (-u_xlat3.xy) * u_xlat14.xx + u_xlat0.xy;
                u_xlatb6.xy = equal(int4(u_xlati30), int4(0, 2, 0, 0)).xy;
                u_xlatb24.xy = lessThan(u_xlat23.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlatb7.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat23.xyxx).xy;
                u_xlatb24.x = u_xlatb24.x || u_xlatb7.x;
                u_xlatb24.x = u_xlatb24.y || u_xlatb24.x;
                u_xlatb24.x = u_xlatb7.y || u_xlatb24.x;
                u_xlatb6.x = u_xlatb24.x && u_xlatb6.x;
                u_xlat6.x = (u_xlatb6.x) ? 0.0 : 1.0;
                if(u_xlatb6.y){
                    u_xlat7 = MainTex.sample(__nv_smp, u_xlat23.xy);
                } else {
                    u_xlat7 = MainTex.sample(__nv_smp, u_xlat23.xy);
                }
                u_xlat15.xyz = u_xlat7.www * u_xlat7.xyz;
                u_xlat8.z = u_xlat14.x * 3.0 + -1.5;
                u_xlat8.y = -abs(u_xlat8.z) + 1.0;
                u_xlat8.x = (-u_xlat8.z);
                u_xlat8.xyz = u_xlat8.xyz;
                u_xlat8.xyz = clamp(u_xlat8.xyz, 0.0, 1.0);
                u_xlat14.xyz = u_xlat15.xyz * u_xlat8.xyz;
                u_xlat14.xyz = u_xlat14.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat15.xyz);
                u_xlat7.xyz = float3(u._dispersion) * u_xlat14.xyz + u_xlat15.xyz;
                u_xlat4 = u_xlat7 * u_xlat6.xxxx + u_xlat4;
                u_xlat4.xyz = u_xlat2.xyz * float3(float3(u._stay, u._stay, u._stay)) + u_xlat4.xyz;
            }
            u_xlat3.x = float(u._samples);
            u_xlat2 = u_xlat4 / u_xlat3.xxxx;
        }
        u_xlatb3.xy = lessThan(u_xlat0.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlatb21.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat0.xyxy).xy;
        u_xlatb3.x = u_xlatb21.x || u_xlatb3.x;
        u_xlatb3.x = u_xlatb3.y || u_xlatb3.x;
        u_xlatb3.x = u_xlatb21.y || u_xlatb3.x;
        u_xlatb27 = u_xlatb18.y && u_xlatb3.x;
        u_xlat27 = (u_xlatb27) ? 0.0 : 1.0;
        u_xlat18.x = (u_xlatb18.x) ? 1.0 : u_xlat27;
        u_xlat1 = u_xlat18.xxxx * u_xlat2;
        u_xlatb27 = 0<u._has_sam2_mask;
        u_xlatb2.x = u._sam2_state!=0;
        u_xlatb27 = u_xlatb27 && u_xlatb2.x;
        if(u_xlatb27){
            u_xlat27 = inputImg.sample(__nv_smp, u_xlat0.xy).x;
            u_xlat2.x = u_xlat27 * 0.305306017 + 0.682171106;
            u_xlat2.x = u_xlat27 * u_xlat2.x + 0.0125228781;
            u_xlat27 = u_xlat27 * u_xlat2.x;
            u_xlat2.x = (-u._sam2_dilate) + 1.0;
            u_xlat2.x = float(1.0) / u_xlat2.x;
            u_xlat27 = u_xlat27 * u_xlat2.x;
            u_xlat27 = clamp(u_xlat27, 0.0, 1.0);
            u_xlat11.x = u_xlat27 * -2.0 + 3.0;
            u_xlat27 = u_xlat27 * u_xlat27;
            u_xlat20.x = u_xlat27 * u_xlat11.x;
            u_xlatb29 = 0<u._sam2_invert;
            u_xlat27 = (-u_xlat11.x) * u_xlat27 + 1.0;
            u_xlat27 = (u_xlatb29) ? u_xlat27 : u_xlat20.x;
            u_xlatb11 = u._sam2_state==1;
            if(u_xlatb11){
                u_xlat11.x = (-u_xlat27) + 1.0;
                u_xlat3 = u_xlat1.xyzz * u_xlat11.xxxx;
                u_xlatb20.xy = equal(int4(int4(u._sam2_color_channel, u._sam2_color_channel, u._sam2_color_channel, u._sam2_color_channel)), int4(1, 2, 1, 2)).xy;
                u_xlat4.xy = u_xlat1.xy * u_xlat11.xx;
                u_xlat4.xy = (u_xlatb20.y) ? u_xlat4.xy : u_xlat1.xy;
                u_xlat5.xz = u_xlat3.xw;
                u_xlat5.y = u_xlat1.y;
                u_xlat4.z = u_xlat1.z;
                u_xlat11.xyz = (u_xlatb20.x) ? u_xlat5.xyz : u_xlat4.xyz;
                u_xlat3.x = u_xlat1.x;
                u_xlat1.xyz = (int(u._sam2_color_channel) != 0) ? u_xlat11.xyz : u_xlat3.xyz;
                u_xlat11.x = u._sam2_outline * 10.0;
                u_xlat11.xy = u_xlat11.xx / float2(u._sam2_resolution.x, u._sam2_resolution.y);
                u_xlat29 = 0.0;
                u_xlat3.x = float(0.0);
                for(int u_xlati_loop_3 = int(0) ; u_xlati_loop_3<16 ; u_xlati_loop_3++)
                {
                    u_xlat3.x = u_xlat3.x + 0.392699093;
                    u_xlat4.x = sin(u_xlat3.x);
                    u_xlat5.x = cos(u_xlat3.x);
                    u_xlat5.x = u_xlat11.x * u_xlat5.x;
                    u_xlat5.y = u_xlat11.y * u_xlat4.x;
                    u_xlat21.xy = u_xlat0.xy + u_xlat5.xy;
                    u_xlat21.xy = clamp(u_xlat21.xy, 0.0, 1.0);
                    u_xlat21.x = inputImg.sample(__nv_smp, u_xlat21.xy).x;
                    u_xlat21.x = u_xlat2.x * u_xlat21.x;
                    u_xlat21.x = clamp(u_xlat21.x, 0.0, 1.0);
                    u_xlat30 = u_xlat21.x * -2.0 + 3.0;
                    u_xlat21.x = u_xlat21.x * u_xlat21.x;
                    u_xlat21.x = u_xlat21.x * u_xlat30;
                    u_xlat21.x = u_xlat18.x * u_xlat21.x;
                    u_xlat29 = max(u_xlat29, u_xlat21.x);
                }
                u_xlat0.x = u_xlat29 + -0.699999988;
                u_xlat0.x = u_xlat0.x * 3.33333325;
                u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
                u_xlat9.x = u_xlat0.x * -2.0 + 3.0;
                u_xlat0.x = u_xlat0.x * u_xlat0.x;
                u_xlat0.x = u_xlat0.x * u_xlat9.x;
                u_xlat9.x = u_xlat0.x * u._sam2_outline_color.w;
                u_xlat2 = u_xlat9.xxxx * u._sam2_outline_color;
                u_xlat0.x = (-u_xlat0.x) * u._sam2_outline_color.w + 1.0;
                u_xlat3 = (-u_xlat9.xxxx) * u._sam2_outline_color + u_xlat1;
                u_xlat2 = float4(u_xlat27) * u_xlat3 + u_xlat2;
                u_xlat2 = u_xlat9.xxxx * u_xlat2;
                u_xlat1 = u_xlat1 * u_xlat0.xxxx + u_xlat2;
                u_xlat2.xyz = u_xlat1.xyz;
            } else {
                u_xlat1 = float4(u_xlat27) * u_xlat1;
                u_xlat2.xyz = u_xlat1.xyz;
            }
        } else {
            u_xlat2.xyz = u_xlat1.xyz;
        }
        u_xlatb0.x = 0<u._has_camera_tracker_mask;
        if(u_xlatb0.x){
            u_xlatb0.x = _ProjectionParams.x<0.0;
            u_xlat1.xy = (-in.acScreenNorm.yx) + float2(1.0, 1.0);
            u_xlat0.x = (u_xlatb0.x) ? u_xlat1.x : in.acScreenNorm.y;
            u_xlat0.x = (-u_xlat0.x) + 1.0;
            u_xlatb3 = equal(int4(u._is_image_asset, u._tex_rotation, u._tex_rotation, u._tex_rotation), int4(1, 90, 270, 180));
            u_xlat9.x = (-u_xlat0.x) + 1.0;
            u_xlat0.x = (u_xlatb3.x) ? u_xlat9.x : u_xlat0.x;
            u_xlat1.z = (-u_xlat0.x) + 1.0;
            u_xlat0.y = in.acScreenNorm.x;
            u_xlat1.xy = (u_xlatb3.w) ? u_xlat1.yz : u_xlat0.yx;
            u_xlat0.z = (-u_xlat0.x) + 1.0;
            u_xlat9.xy = (u_xlatb3.z) ? u_xlat0.zy : u_xlat1.xy;
            u_xlat0.w = (-in.acScreenNorm.x) + 1.0;
            u_xlat0.xy = (u_xlatb3.y) ? u_xlat0.xw : u_xlat9.xy;
            u_xlat0.xy = u_xlat0.xy + float2(-0.5, -0.5);
            u_xlat0.xy = u_xlat0.xy * u._viewport_ratio.xy;
            u_xlat9.xy = u_xlat0.yy * hlslcc_mtx4x4_trans_mat[1].xy;
            u_xlat0.xy = hlslcc_mtx4x4_trans_mat[0].xy * u_xlat0.xx + u_xlat9.xy;
            u_xlat0.xy = u_xlat0.xy + hlslcc_mtx4x4_trans_mat[3].xy;
            u_xlat0.xy = u_xlat0.xy / u._viewport_ratio.xy;
            u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
            u_xlat0.x = camera_tracker_mask.sample(__nv_smp, u_xlat0.xy).x;
            u_xlatb0.x = u_xlat0.x<0.5;
            u_xlat2.w = 0.0;
            u_xlat9.xyz = u_xlat2.xyz * float3(0.200000003, 1.0, 0.200000003);
            __nv_out.xyz = (u_xlatb0.x) ? u_xlat2.xww : u_xlat9.xyz;
        } else {
            __nv_out.xyz = u_xlat2.xyz;
        }
    }
    __nv_out.w = u_xlat1.w * u._trans_alpha;
    return __nv_out;
    return __nv_out;
}
