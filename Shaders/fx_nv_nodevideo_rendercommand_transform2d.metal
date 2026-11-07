// ---------------------------------------------------------------------------
// Rendercommand Transform2D (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-transform2d.xml
// id     : nv.effect.nodevideo-rendercommand-transform2d
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_transform2dParams {
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
    float _texture_wrap_mode;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _node_size (eng.acTamanhoDaCamada / eng.acTamanhoDaTela)
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _output_size eng.acTamanhoDaTela
float4 u_xlat0;
int u_xlati0;
bool4 u_xlatb0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
int3 u_xlati2;
bool3 u_xlatb2;
float4 u_xlat3;
bool3 u_xlatb3;
float4 u_xlat4;
int u_xlati5;
bool3 u_xlatb5;
float3 u_xlat6;
bool2 u_xlatb6;
float4 u_xlat7;
bool2 u_xlatb7;
float3 u_xlat8;
float2 u_xlat9;
float2 u_xlat10;
bool2 u_xlatb10;
float3 u_xlat11;
float u_xlat12;
bool u_xlatb12;
float3 u_xlat13;
float3 u_xlat15;
int u_xlati15;
bool u_xlatb15;
float2 u_xlat16;
bool u_xlatb16;
float2 u_xlat17;
bool u_xlatb17;
float2 u_xlat20;
bool u_xlatb20;
float2 u_xlat21;
bool2 u_xlatb21;
float u_xlat22;
bool u_xlatb22;
float2 u_xlat23;
int u_xlati23;
float2 u_xlat25;
int u_xlati25;
float u_xlat26;
bool2 u_xlatb26;
float2 u_xlat27;
bool u_xlatb27;
float u_xlat30;
float u_xlat32;
bool u_xlatb32;
int u_xlati33;
int u_xlati35;
float u_xlat36;
bool u_xlatb36;

fragment float4 fx_nv_nodevideo_rendercommand_transform2d(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_transform2dParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0.x = u._enable_motion_tile==1;
    if(u_xlatb0.x){
        u_xlatb0.x = u._do_motion_warp==1;
        if(u_xlatb0.x){
            u_xlat10.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
            u_xlat10.xy = u_xlat10.xy / u._norm_size.xy;
            u_xlat1.xy = u_xlat10.xy + float2(0.5, 0.5);
            u_xlat10.xy = (-u_xlat1.xy) + float2(1.0, 1.0);
            u_xlatb2.xyz = equal(int4(int4(u._asset_rotation, u._asset_rotation, u._asset_rotation, u._asset_rotation)), int4(90, 270, 180, 0)).xyz;
            u_xlat10.xy = (u_xlatb2.z) ? u_xlat10.xy : u_xlat1.xy;
            u_xlat1.zw = (-u_xlat1.xy) + float2(1.0, 1.0);
            u_xlat10.xy = (u_xlatb2.y) ? u_xlat1.yz : u_xlat10.xy;
            u_xlat1.xy = (u_xlatb2.x) ? u_xlat1.wx : u_xlat10.xy;
            u_xlat1.z = (-u_xlat1.y) + 1.0;
            u_xlat10.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5);
            u_xlat10.xy = u_xlat1.xz * float2(u._asset_size.x, u._asset_size.y) + (-u_xlat10.xy);
            u_xlat30 = u_xlat10.y * _warp_params[1];
            u_xlat30 = _warp_params[0] * u_xlat10.x + u_xlat30;
            u_xlat1.x = u_xlat30 + _warp_params[2];
            u_xlat20.x = u_xlat10.y * _warp_params[4];
            u_xlat10.x = _warp_params[3] * u_xlat10.x + u_xlat20.x;
            u_xlat1.y = u_xlat10.x + _warp_params[5];
            u_xlat10.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5) + u_xlat1.xy;
            u_xlat1.xy = u_xlat10.xy / float2(u._asset_size.x, u._asset_size.y);
            u_xlat3.xy = (-u_xlat1.yx) + float2(1.0, 1.0);
            u_xlat3.z = (-u_xlat3.x) + 1.0;
            u_xlat1.z = (-u_xlat1.y) + 1.0;
            u_xlat10.xy = (u_xlatb2.z) ? u_xlat3.yz : u_xlat1.xz;
            u_xlat10.xy = (u_xlatb2.y) ? u_xlat1.yx : u_xlat10.xy;
            u_xlat10.xy = (u_xlatb2.x) ? u_xlat3.xy : u_xlat10.xy;
            u_xlat10.xy = u_xlat10.xy + float2(-0.5, -0.5);
            u_xlat10.xy = u_xlat10.xy * u._norm_size.xy + float2(0.5, 0.5);
        } else {
            u_xlat10.xy = in.acScreenNorm.xy;
        }
        u_xlat10.xy = u_xlat10.xy + float2(-0.5, -0.5);
        u_xlat10.xy = u_xlat10.xy * u._viewport_ratio.xy;
        u_xlat20.xy = u_xlat10.yy * hlslcc_mtx4x4_trans_mat[1].xy;
        u_xlat10.xy = hlslcc_mtx4x4_trans_mat[0].xy * u_xlat10.xx + u_xlat20.xy;
        u_xlat10.xy = u_xlat10.xy + hlslcc_mtx4x4_trans_mat[3].xy;
        u_xlat10.xy = u_xlat10.xy / u._viewport_ratio.xy;
        u_xlat10.xy = u_xlat10.xy + float2(0.5, 0.5);
        u_xlat1.xy = _node_size.xy * float2(0.5, 0.5) + float2(0.5, 0.5);
        u_xlat21.xy = (-_node_size.xy) * float2(0.5, 0.5) + float2(0.5, 0.5);
        u_xlat10.xy = u_xlat10.xy + (-u_xlat21.xy);
        u_xlat1.xy = (-u_xlat21.xy) + u_xlat1.xy;
        u_xlat10.xy = u_xlat10.xy / u_xlat1.xy;
        u_xlat30 = u._edge_width * 0.00999999978 + 1.0;
        u_xlat10.xy = u_xlat10.xy + float2(-0.5, -0.5);
        u_xlat10.xy = u_xlat10.xy * float2(u_xlat30) + float2(0.5, 0.5);
        if(u._phase_type == 0) {
            u_xlatb2.x = u_xlat10.y>=0.0;
            u_xlat12 = abs(u_xlat10.y) + 1.0;
            u_xlat2.x = (u_xlatb2.x) ? u_xlat10.y : u_xlat12;
            u_xlat2.x = u_xlat2.x * 0.5;
            u_xlatb12 = u_xlat2.x>=(-u_xlat2.x);
            u_xlat2.x = fract(abs(u_xlat2.x));
            u_xlat2.x = (u_xlatb12) ? u_xlat2.x : (-u_xlat2.x);
            u_xlatb2.x = u_xlat2.x>=0.5;
            u_xlat12 = u_xlatb2.x ? 1.0 : float(0.0);
            u_xlat12 = u_xlat12 * u._phase + u_xlat10.x;
            u_xlatb22 = u_xlat12>=0.0;
            u_xlat32 = abs(u_xlat12) + 1.0;
            u_xlat22 = (u_xlatb22) ? u_xlat12 : u_xlat32;
            u_xlat3.x = fract(u_xlat12);
            u_xlat3.y = fract(u_xlat10.y);
            u_xlatb12 = u._mirror_edges==1;
            u_xlat22 = u_xlat22 * 0.5;
            u_xlatb32 = u_xlat22>=(-u_xlat22);
            u_xlat22 = fract(abs(u_xlat22));
            u_xlat22 = (u_xlatb32) ? u_xlat22 : (-u_xlat22);
            u_xlatb2.z = u_xlat22>=0.5;
            u_xlati2.xz = int2(uint2((uint(u_xlatb2.x) * 0xffffffffu) & (uint(u_xlatb12) * 0xffffffffu), (uint(u_xlatb2.z) * 0xffffffffu) & (uint(u_xlatb12) * 0xffffffffu)));
            u_xlat23.xy = (-u_xlat3.xy) + float2(1.0, 1.0);
            u_xlat4.x = (u_xlati2.z != 0) ? u_xlat23.x : u_xlat3.x;
            u_xlat4.y = (u_xlati2.x != 0) ? u_xlat23.y : u_xlat3.y;
        } else {
            u_xlatb2.x = u_xlat10.x>=0.0;
            u_xlat12 = abs(u_xlat10.x) + 1.0;
            u_xlat2.x = (u_xlatb2.x) ? u_xlat10.x : u_xlat12;
            u_xlat2.x = u_xlat2.x * 0.5;
            u_xlatb12 = u_xlat2.x>=(-u_xlat2.x);
            u_xlat2.x = fract(abs(u_xlat2.x));
            u_xlat2.x = (u_xlatb12) ? u_xlat2.x : (-u_xlat2.x);
            u_xlatb2.x = u_xlat2.x>=0.5;
            u_xlat12 = u_xlatb2.x ? 1.0 : float(0.0);
            u_xlat20.x = u_xlat12 * u._phase + u_xlat10.y;
            u_xlatb12 = u_xlat20.x>=0.0;
            u_xlat22 = abs(u_xlat20.x) + 1.0;
            u_xlat12 = (u_xlatb12) ? u_xlat20.x : u_xlat22;
            u_xlat3.x = fract(u_xlat10.x);
            u_xlat3.y = fract(u_xlat20.x);
            u_xlatb10.x = u._mirror_edges==1;
            u_xlatb20 = u_xlatb2.x && u_xlatb10.x;
            u_xlat2.xz = (-u_xlat3.xy) + float2(1.0, 1.0);
            u_xlat4.x = (u_xlatb20) ? u_xlat2.x : u_xlat3.x;
            u_xlat20.x = u_xlat12 * 0.5;
            u_xlatb2.x = u_xlat20.x>=(-u_xlat20.x);
            u_xlat20.x = fract(abs(u_xlat20.x));
            u_xlat20.x = (u_xlatb2.x) ? u_xlat20.x : (-u_xlat20.x);
            u_xlatb20 = u_xlat20.x>=0.5;
            u_xlatb10.x = u_xlatb20 && u_xlatb10.x;
            u_xlat4.y = (u_xlatb10.x) ? u_xlat2.z : u_xlat3.y;
        }
        u_xlat10.xy = u_xlat4.xy + float2(-0.5, -0.5);
        u_xlat10.xy = u_xlat10.xy / float2(u_xlat30);
        u_xlat10.xy = u_xlat10.xy + float2(0.5, 0.5);
        u_xlat10.xy = u_xlat1.xy * u_xlat10.xy + u_xlat21.xy;
        u_xlatb2.x = u._texture_wrap_mode==2;
        if(u_xlatb2.x){
            u_xlat2 = inputImg.sample(__nv_smp, u_xlat10.xy);
        } else {
            u_xlat2 = inputImg.sample(__nv_smp, u_xlat10.xy);
        }
        u_xlatb3.x = 0<u._enable_motion_blur;
        if(u_xlatb3.x){
            if(u_xlatb0.x){
                u_xlat3.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
                u_xlat3.xy = u_xlat3.xy / u._norm_size.xy;
                u_xlat3.xy = u_xlat3.xy + float2(0.5, 0.5);
                u_xlat4.xy = (-u_xlat3.xy) + float2(1.0, 1.0);
                u_xlatb5.xyz = equal(int4(int4(u._asset_rotation, u._asset_rotation, u._asset_rotation, u._asset_rotation)), int4(90, 270, 180, 0)).xyz;
                u_xlat4.xy = (u_xlatb5.z) ? u_xlat4.xy : u_xlat3.xy;
                u_xlat3.zw = (-u_xlat3.xy) + float2(1.0, 1.0);
                u_xlat13.xy = (u_xlatb5.y) ? u_xlat3.yz : u_xlat4.xy;
                u_xlat3.xy = (u_xlatb5.x) ? u_xlat3.wx : u_xlat13.xy;
                u_xlat3.z = (-u_xlat3.y) + 1.0;
                u_xlat13.xz = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5);
                u_xlat3.xy = u_xlat3.xz * float2(u._asset_size.x, u._asset_size.y) + (-u_xlat13.xz);
                u_xlat23.x = u_xlat3.y * _warp_params[1];
                u_xlat23.x = _warp_params[0] * u_xlat3.x + u_xlat23.x;
                u_xlat4.x = u_xlat23.x + _warp_params[2];
                u_xlat13.x = u_xlat3.y * _warp_params[4];
                u_xlat3.x = _warp_params[3] * u_xlat3.x + u_xlat13.x;
                u_xlat4.y = u_xlat3.x + _warp_params[5];
                u_xlat3.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5) + u_xlat4.xy;
                u_xlat3.xy = u_xlat3.xy / float2(u._asset_size.x, u._asset_size.y);
                u_xlat4.xy = (-u_xlat3.yx) + float2(1.0, 1.0);
                u_xlat4.z = (-u_xlat4.x) + 1.0;
                u_xlat3.z = (-u_xlat3.y) + 1.0;
                u_xlat23.xy = (u_xlatb5.z) ? u_xlat4.yz : u_xlat3.xz;
                u_xlat3.xy = (u_xlatb5.y) ? u_xlat3.yx : u_xlat23.xy;
                u_xlat3.xy = (u_xlatb5.x) ? u_xlat4.xy : u_xlat3.xy;
                u_xlat3.xy = u_xlat3.xy + float2(-0.5, -0.5);
                u_xlat3.xy = u_xlat3.xy * u._norm_size.xy + float2(0.5, 0.5);
            } else {
                u_xlat3.xy = in.acScreenNorm.xy;
            }
            u_xlat3.xy = u_xlat3.xy + float2(-0.5, -0.5);
            u_xlat3.xy = u_xlat3.xy * u._viewport_ratio.xy;
            u_xlat13.xy = u_xlat3.yy * hlslcc_mtx4x4_trans_mat[1].xy;
            u_xlat3.xy = hlslcc_mtx4x4_trans_mat[0].xy * u_xlat3.xx + u_xlat13.xy;
            u_xlat3.xy = u_xlat3.xy + hlslcc_mtx4x4_trans_mat[3].xy;
            u_xlat3.xy = u_xlat3.xy / u._viewport_ratio.xy;
            if(u_xlatb0.x){
                u_xlat23.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
                u_xlat23.xy = u_xlat23.xy / u._norm_size.xy;
                u_xlat4.xy = u_xlat23.xy + float2(0.5, 0.5);
                u_xlat23.xy = (-u_xlat4.xy) + float2(1.0, 1.0);
                u_xlatb5.xyz = equal(int4(int4(u._asset_rotation, u._asset_rotation, u._asset_rotation, u._asset_rotation)), int4(90, 270, 180, 0)).xyz;
                u_xlat23.xy = (u_xlatb5.z) ? u_xlat23.xy : u_xlat4.xy;
                u_xlat4.zw = (-u_xlat4.xy) + float2(1.0, 1.0);
                u_xlat23.xy = (u_xlatb5.y) ? u_xlat4.yz : u_xlat23.xy;
                u_xlat4.xy = (u_xlatb5.x) ? u_xlat4.wx : u_xlat23.xy;
                u_xlat4.z = (-u_xlat4.y) + 1.0;
                u_xlat23.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5);
                u_xlat23.xy = u_xlat4.xz * float2(u._asset_size.x, u._asset_size.y) + (-u_xlat23.xy);
                u_xlat0.x = u_xlat23.y * _warp_params[1];
                u_xlat0.x = _warp_params[0] * u_xlat23.x + u_xlat0.x;
                u_xlat4.x = u_xlat0.x + _warp_params[2];
                u_xlat0.x = u_xlat23.y * _warp_params[4];
                u_xlat0.x = _warp_params[3] * u_xlat23.x + u_xlat0.x;
                u_xlat4.y = u_xlat0.x + _warp_params[5];
                u_xlat23.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5) + u_xlat4.xy;
                u_xlat4.xy = u_xlat23.xy / float2(u._asset_size.x, u._asset_size.y);
                u_xlat6.xy = (-u_xlat4.yx) + float2(1.0, 1.0);
                u_xlat6.z = (-u_xlat6.x) + 1.0;
                u_xlat4.z = (-u_xlat4.y) + 1.0;
                u_xlat23.xy = (u_xlatb5.z) ? u_xlat6.yz : u_xlat4.xz;
                u_xlat23.xy = (u_xlatb5.y) ? u_xlat4.yx : u_xlat23.xy;
                u_xlat23.xy = (u_xlatb5.x) ? u_xlat6.xy : u_xlat23.xy;
                u_xlat23.xy = u_xlat23.xy + float2(-0.5, -0.5);
                u_xlat3.zw = u_xlat23.xy * u._norm_size.xy + float2(0.5, 0.5);
            } else {
                u_xlat3.zw = in.acScreenNorm.xy;
            }
            u_xlat3 = u_xlat3 + float4(0.5, 0.5, -0.5, -0.5);
            u_xlat23.xy = u_xlat3.zw * u._viewport_ratio.xy;
            u_xlat4.xy = u_xlat23.yy * hlslcc_mtx4x4_trans_mat_prev[1].xy;
            u_xlat23.xy = hlslcc_mtx4x4_trans_mat_prev[0].xy * u_xlat23.xx + u_xlat4.xy;
            u_xlat23.xy = u_xlat23.xy + hlslcc_mtx4x4_trans_mat_prev[3].xy;
            u_xlat23.xy = u_xlat23.xy / u._viewport_ratio.xy;
            u_xlat23.xy = u_xlat23.xy + float2(0.5, 0.5);
            u_xlat23.xy = (-u_xlat23.xy) + u_xlat3.xy;
            u_xlat23.xy = u_xlat23.xy * float2(u._amount);
            u_xlati0 = u._samples + int(0xFFFFFFFFu);
            u_xlat0.x = float(u_xlati0);
            u_xlat4 = u_xlat2;
            u_xlati5 = u._mirror_edges;
            u_xlati15 = u._phase_type;
            u_xlati25 = u._texture_wrap_mode;
            for(int u_xlati_loop_1 = 1 ; u_xlati_loop_1<u._samples ; u_xlati_loop_1++)
            {
                u_xlat6.x = float(u_xlati_loop_1);
                u_xlat6.x = u_xlat6.x / u_xlat0.x;
                u_xlat16.xy = (-u_xlat23.xy) * u_xlat6.xx + u_xlat3.xy;
                u_xlat16.xy = (-u_xlat21.xy) + u_xlat16.xy;
                u_xlat16.xy = u_xlat16.xy / u_xlat1.xy;
                u_xlat16.xy = u_xlat16.xy + float2(-0.5, -0.5);
                u_xlat16.xy = u_xlat16.xy * float2(u_xlat30) + float2(0.5, 0.5);
                if(u_xlati15 == 0) {
                    u_xlatb36 = u_xlat16.y>=0.0;
                    u_xlat7.x = abs(u_xlat16.y) + 1.0;
                    u_xlat36 = (u_xlatb36) ? u_xlat16.y : u_xlat7.x;
                    u_xlat36 = u_xlat36 * 0.5;
                    u_xlatb7.x = u_xlat36>=(-u_xlat36);
                    u_xlat36 = fract(abs(u_xlat36));
                    u_xlat36 = (u_xlatb7.x) ? u_xlat36 : (-u_xlat36);
                    u_xlatb36 = u_xlat36>=0.5;
                    u_xlat7.x = u_xlatb36 ? 1.0 : float(0.0);
                    u_xlat7.x = u_xlat7.x * u._phase + u_xlat16.x;
                    u_xlatb17 = u_xlat7.x>=0.0;
                    u_xlat27.x = abs(u_xlat7.x) + 1.0;
                    u_xlat17.x = (u_xlatb17) ? u_xlat7.x : u_xlat27.x;
                    u_xlat8.x = fract(u_xlat7.x);
                    u_xlat8.y = fract(u_xlat16.y);
                    u_xlatb7.x = u_xlati5==1;
                    u_xlat17.x = u_xlat17.x * 0.5;
                    u_xlatb27 = u_xlat17.x>=(-u_xlat17.x);
                    u_xlat17.x = fract(abs(u_xlat17.x));
                    u_xlat17.x = (u_xlatb27) ? u_xlat17.x : (-u_xlat17.x);
                    u_xlatb17 = u_xlat17.x>=0.5;
                    u_xlatb17 = u_xlatb17 && u_xlatb7.x;
                    u_xlat27.xy = (-u_xlat8.xy) + float2(1.0, 1.0);
                    u_xlat9.x = (u_xlatb17) ? u_xlat27.x : u_xlat8.x;
                    u_xlatb36 = u_xlatb36 && u_xlatb7.x;
                    u_xlat9.y = (u_xlatb36) ? u_xlat27.y : u_xlat8.y;
                } else {
                    u_xlatb36 = u_xlat16.x>=0.0;
                    u_xlat7.x = abs(u_xlat16.x) + 1.0;
                    u_xlat36 = (u_xlatb36) ? u_xlat16.x : u_xlat7.x;
                    u_xlat36 = u_xlat36 * 0.5;
                    u_xlatb7.x = u_xlat36>=(-u_xlat36);
                    u_xlat36 = fract(abs(u_xlat36));
                    u_xlat36 = (u_xlatb7.x) ? u_xlat36 : (-u_xlat36);
                    u_xlatb36 = u_xlat36>=0.5;
                    u_xlat7.x = u_xlatb36 ? 1.0 : float(0.0);
                    u_xlat26 = u_xlat7.x * u._phase + u_xlat16.y;
                    u_xlatb7.x = u_xlat26>=0.0;
                    u_xlat17.x = abs(u_xlat26) + 1.0;
                    u_xlat7.x = (u_xlatb7.x) ? u_xlat26 : u_xlat17.x;
                    u_xlat8.x = fract(u_xlat16.x);
                    u_xlat8.y = fract(u_xlat26);
                    u_xlatb16 = u_xlati5==1;
                    u_xlatb26.x = u_xlatb36 && u_xlatb16;
                    u_xlat17.xy = (-u_xlat8.xy) + float2(1.0, 1.0);
                    u_xlat9.x = (u_xlatb26.x) ? u_xlat17.x : u_xlat8.x;
                    u_xlat26 = u_xlat7.x * 0.5;
                    u_xlatb36 = u_xlat26>=(-u_xlat26);
                    u_xlat26 = fract(abs(u_xlat26));
                    u_xlat26 = (u_xlatb36) ? u_xlat26 : (-u_xlat26);
                    u_xlatb26.x = u_xlat26>=0.5;
                    u_xlatb16 = u_xlatb26.x && u_xlatb16;
                    u_xlat9.y = (u_xlatb16) ? u_xlat17.y : u_xlat8.y;
                }
                u_xlat16.xy = u_xlat9.xy + float2(-0.5, -0.5);
                u_xlat16.xy = u_xlat16.xy / float2(u_xlat30);
                u_xlat16.xy = u_xlat16.xy + float2(0.5, 0.5);
                u_xlat16.xy = u_xlat1.xy * u_xlat16.xy + u_xlat21.xy;
                u_xlatb36 = u_xlati25==2;
                if(u_xlatb36){
                    u_xlat7 = inputImg.sample(__nv_smp, u_xlat16.xy);
                } else {
                    u_xlat7 = inputImg.sample(__nv_smp, u_xlat16.xy);
                }
                u_xlat6.z = u_xlat6.x * 3.0 + -1.5;
                u_xlat6.y = -abs(u_xlat6.z) + 1.0;
                u_xlat6.x = (-u_xlat6.z);
                u_xlat6.xyz = u_xlat6.xyz;
                u_xlat6.xyz = clamp(u_xlat6.xyz, 0.0, 1.0);
                u_xlat6.xyz = u_xlat6.xyz * u_xlat7.xyz;
                u_xlat6.xyz = u_xlat6.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat7.xyz);
                u_xlat7.xyz = float3(u._dispersion) * u_xlat6.xyz + u_xlat7.xyz;
                u_xlat4 = u_xlat4 + u_xlat7;
                u_xlat4.xyz = u_xlat2.xyz * float3(float3(u._stay, u._stay, u._stay)) + u_xlat4.xyz;
            }
            u_xlat0.x = float(u._samples);
            u_xlat2 = u_xlat4 / u_xlat0.xxxx;
        }
        u_xlat0.xw = (-float2(_output_size.x, _output_size.y)) + float2(1.0, 1.0);
        u_xlatb1.xy = greaterThanEqual(in.acScreenNorm.xyxx, u_xlat0.xwxx).xy;
        u_xlat21.xy = (-in.acScreenNorm.xy) + float2(1.0, 1.0);
        u_xlatb0.xw = greaterThanEqual(u_xlat21.xxxy, u_xlat0.xxxw).xw;
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
        u_xlatb0.xw = lessThan(u_xlat10.xxxy, float4(0.0, 0.0, 0.0, 0.0)).xw;
        u_xlatb10.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat10.xyxx).xy;
        u_xlatb0.x = u_xlatb10.x || u_xlatb0.x;
        u_xlatb0.x = u_xlatb0.w || u_xlatb0.x;
        u_xlatb0.x = u_xlatb10.y || u_xlatb0.x;
        u_xlat0.x = (u_xlatb0.x) ? 0.0 : 1.0;
        u_xlat0 = u_xlat0.xxxx * u_xlat1.wxyz;
        __nv_out.xyz = u_xlat0.yzw;
    } else {
        u_xlatb1.x = u._do_motion_warp==1;
        if(u_xlatb1.x){
            u_xlat1.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
            u_xlat1.xy = u_xlat1.xy / u._norm_size.xy;
            u_xlat1.xy = u_xlat1.xy + float2(0.5, 0.5);
            u_xlat2.xy = (-u_xlat1.xy) + float2(1.0, 1.0);
            u_xlatb3.xyz = equal(int4(int4(u._asset_rotation, u._asset_rotation, u._asset_rotation, u._asset_rotation)), int4(90, 270, 180, 0)).xyz;
            u_xlat2.xy = (u_xlatb3.z) ? u_xlat2.xy : u_xlat1.xy;
            u_xlat1.zw = (-u_xlat1.xy) + float2(1.0, 1.0);
            u_xlat11.xy = (u_xlatb3.y) ? u_xlat1.yz : u_xlat2.xy;
            u_xlat1.xy = (u_xlatb3.x) ? u_xlat1.wx : u_xlat11.xy;
            u_xlat1.z = (-u_xlat1.y) + 1.0;
            u_xlat11.xz = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5);
            u_xlat1.xy = u_xlat1.xz * float2(u._asset_size.x, u._asset_size.y) + (-u_xlat11.xz);
            u_xlat21.x = u_xlat1.y * _warp_params[1];
            u_xlat21.x = _warp_params[0] * u_xlat1.x + u_xlat21.x;
            u_xlat2.x = u_xlat21.x + _warp_params[2];
            u_xlat11.x = u_xlat1.y * _warp_params[4];
            u_xlat1.x = _warp_params[3] * u_xlat1.x + u_xlat11.x;
            u_xlat2.y = u_xlat1.x + _warp_params[5];
            u_xlat1.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5) + u_xlat2.xy;
            u_xlat1.xy = u_xlat1.xy / float2(u._asset_size.x, u._asset_size.y);
            u_xlat2.xy = (-u_xlat1.yx) + float2(1.0, 1.0);
            u_xlat2.z = (-u_xlat2.x) + 1.0;
            u_xlat1.z = (-u_xlat1.y) + 1.0;
            u_xlat21.xy = (u_xlatb3.z) ? u_xlat2.yz : u_xlat1.xz;
            u_xlat1.xy = (u_xlatb3.y) ? u_xlat1.yx : u_xlat21.xy;
            u_xlat1.xy = (u_xlatb3.x) ? u_xlat2.xy : u_xlat1.xy;
            u_xlat1.xy = u_xlat1.xy + float2(-0.5, -0.5);
            u_xlat1.xy = u_xlat1.xy * u._norm_size.xy + float2(0.5, 0.5);
        } else {
            u_xlat1.xy = in.acScreenNorm.xy;
        }
        u_xlat1.xy = u_xlat1.xy + float2(-0.5, -0.5);
        u_xlat1.xy = u_xlat1.xy * u._viewport_ratio.xy;
        u_xlat11.xy = u_xlat1.yy * hlslcc_mtx4x4_trans_mat[1].xy;
        u_xlat1.xy = hlslcc_mtx4x4_trans_mat[0].xy * u_xlat1.xx + u_xlat11.xy;
        u_xlat1.xy = u_xlat1.xy + hlslcc_mtx4x4_trans_mat[3].xy;
        u_xlat1.xy = u_xlat1.xy / u._viewport_ratio.xy;
        u_xlat1.xy = u_xlat1.xy + float2(0.5, 0.5);
        u_xlatb21.xy = equal(int4(int4(u._texture_wrap_mode, u._texture_wrap_mode, u._texture_wrap_mode, u._texture_wrap_mode)), int4(2, 0, 2, 0)).xy;
        if(u_xlatb21.x){
            u_xlat2 = inputImg.sample(__nv_smp, u_xlat1.xy);
        } else {
            u_xlat2 = inputImg.sample(__nv_smp, u_xlat1.xy);
        }
        u_xlatb21.x = 0<u._enable_motion_blur;
        if(u_xlatb21.x){
            u_xlatb3.x = u._do_motion_warp==1;
            if(u_xlatb3.x){
                u_xlat3.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
                u_xlat3.xy = u_xlat3.xy / u._norm_size.xy;
                u_xlat3.xy = u_xlat3.xy + float2(0.5, 0.5);
                u_xlat4.xy = (-u_xlat3.xy) + float2(1.0, 1.0);
                u_xlatb5.xyz = equal(int4(int4(u._asset_rotation, u._asset_rotation, u._asset_rotation, u._asset_rotation)), int4(90, 270, 180, 0)).xyz;
                u_xlat4.xy = (u_xlatb5.z) ? u_xlat4.xy : u_xlat3.xy;
                u_xlat3.zw = (-u_xlat3.xy) + float2(1.0, 1.0);
                u_xlat13.xy = (u_xlatb5.y) ? u_xlat3.yz : u_xlat4.xy;
                u_xlat3.xy = (u_xlatb5.x) ? u_xlat3.wx : u_xlat13.xy;
                u_xlat3.z = (-u_xlat3.y) + 1.0;
                u_xlat13.xz = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5);
                u_xlat3.xy = u_xlat3.xz * float2(u._asset_size.x, u._asset_size.y) + (-u_xlat13.xz);
                u_xlat23.x = u_xlat3.y * _warp_params[1];
                u_xlat23.x = _warp_params[0] * u_xlat3.x + u_xlat23.x;
                u_xlat4.x = u_xlat23.x + _warp_params[2];
                u_xlat13.x = u_xlat3.y * _warp_params[4];
                u_xlat3.x = _warp_params[3] * u_xlat3.x + u_xlat13.x;
                u_xlat4.y = u_xlat3.x + _warp_params[5];
                u_xlat3.xy = float2(u._asset_size.x, u._asset_size.y) * float2(0.5, 0.5) + u_xlat4.xy;
                u_xlat3.xy = u_xlat3.xy / float2(u._asset_size.x, u._asset_size.y);
                u_xlat4.xy = (-u_xlat3.yx) + float2(1.0, 1.0);
                u_xlat4.z = (-u_xlat4.x) + 1.0;
                u_xlat3.z = (-u_xlat3.y) + 1.0;
                u_xlat23.xy = (u_xlatb5.z) ? u_xlat4.yz : u_xlat3.xz;
                u_xlat3.xy = (u_xlatb5.y) ? u_xlat3.yx : u_xlat23.xy;
                u_xlat3.xy = (u_xlatb5.x) ? u_xlat4.xy : u_xlat3.xy;
                u_xlat3.xy = u_xlat3.xy + float2(-0.5, -0.5);
                u_xlat3.xy = u_xlat3.xy * u._norm_size.xy + float2(0.5, 0.5);
            } else {
                u_xlat3.xy = in.acScreenNorm.xy;
            }
            u_xlat3.xy = u_xlat3.xy + float2(-0.5, -0.5);
            u_xlat3.xy = u_xlat3.xy * u._viewport_ratio.xy;
            u_xlat13.xy = u_xlat3.yy * hlslcc_mtx4x4_trans_mat_prev[1].xy;
            u_xlat3.xy = hlslcc_mtx4x4_trans_mat_prev[0].xy * u_xlat3.xx + u_xlat13.xy;
            u_xlat3.xy = u_xlat3.xy + hlslcc_mtx4x4_trans_mat_prev[3].xy;
            u_xlat3.xy = u_xlat3.xy / u._viewport_ratio.xy;
            u_xlat3.xy = u_xlat3.xy + float2(0.5, 0.5);
            u_xlat3.xy = u_xlat1.xy + (-u_xlat3.xy);
            u_xlat3.xy = u_xlat3.xy * float2(u._amount);
            u_xlati23 = u._samples + int(0xFFFFFFFFu);
            u_xlat23.x = float(u_xlati23);
            u_xlat4 = u_xlat2;
            u_xlati33 = u._texture_wrap_mode;
            for(int u_xlati_loop_2 = 1 ; u_xlati_loop_2<u._samples ; u_xlati_loop_2++)
            {
                u_xlat15.x = float(u_xlati_loop_2);
                u_xlat15.x = u_xlat15.x / u_xlat23.x;
                u_xlat25.xy = (-u_xlat3.xy) * u_xlat15.xx + u_xlat1.xy;
                u_xlatb6.xy = equal(int4(u_xlati33), int4(0, 2, 0, 0)).xy;
                u_xlatb26.xy = lessThan(u_xlat25.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlatb7.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat25.xyxx).xy;
                u_xlatb26.x = u_xlatb26.x || u_xlatb7.x;
                u_xlatb26.x = u_xlatb26.y || u_xlatb26.x;
                u_xlatb26.x = u_xlatb7.y || u_xlatb26.x;
                u_xlatb6.x = u_xlatb26.x && u_xlatb6.x;
                u_xlat6.x = (u_xlatb6.x) ? 0.0 : 1.0;
                if(u_xlatb6.y){
                    u_xlat7 = inputImg.sample(__nv_smp, u_xlat25.xy);
                } else {
                    u_xlat7 = inputImg.sample(__nv_smp, u_xlat25.xy);
                }
                u_xlat8.z = u_xlat15.x * 3.0 + -1.5;
                u_xlat8.y = -abs(u_xlat8.z) + 1.0;
                u_xlat8.x = (-u_xlat8.z);
                u_xlat8.xyz = u_xlat8.xyz;
                u_xlat8.xyz = clamp(u_xlat8.xyz, 0.0, 1.0);
                u_xlat15.xyz = u_xlat7.xyz * u_xlat8.xyz;
                u_xlat15.xyz = u_xlat15.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat7.xyz);
                u_xlat7.xyz = float3(u._dispersion) * u_xlat15.xyz + u_xlat7.xyz;
                u_xlat4 = u_xlat7 * u_xlat6.xxxx + u_xlat4;
                u_xlat4.xyz = u_xlat2.xyz * float3(float3(u._stay, u._stay, u._stay)) + u_xlat4.xyz;
            }
            u_xlat3.x = float(u._samples);
            u_xlat2 = u_xlat4 / u_xlat3.xxxx;
        }
        u_xlatb3.xy = lessThan(u_xlat1.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlatb1.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat1.xyxx).xy;
        u_xlatb1.x = u_xlatb1.x || u_xlatb3.x;
        u_xlatb1.x = u_xlatb3.y || u_xlatb1.x;
        u_xlatb1.x = u_xlatb1.y || u_xlatb1.x;
        u_xlatb1.x = u_xlatb1.x && u_xlatb21.y;
        u_xlat1.x = (u_xlatb1.x) ? 0.0 : 1.0;
        u_xlat1.x = (u_xlatb21.x) ? 1.0 : u_xlat1.x;
        u_xlat0 = u_xlat1.xxxx * u_xlat2.wxyz;
        __nv_out.xyz = u_xlat0.yzw;
    }
    __nv_out.w = u_xlat0.x * u._trans_alpha;
    return __nv_out;
    return __nv_out;
}
