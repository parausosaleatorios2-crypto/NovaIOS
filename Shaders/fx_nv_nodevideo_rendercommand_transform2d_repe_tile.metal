// ---------------------------------------------------------------------------
// Rendercommand Transform2D Repe Tile (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-transform2d-repe-tile.xml
// id     : nv.effect.nodevideo-rendercommand-transform2d-repe-tile
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_transform2d_repe_tileParams {
    float4 _viewport_ratio;
    float _amount;
    float _stay;
    float _samples;
    float _enable_motion_blur;
    float _dispersion;
    float _expand_right;
    float _expand_left;
    float _expand_up;
    float _expand_down;
    float2 _range_start;
    float2 _range_end;
    float _tillingt_rotation;
    float2 _tiling_offset;
    float2 _tiling_scale;
    float _phase;
    float _enable_subtrans;
    float _enable_motion;
    float _partition;
    float _phase_type;
    float _mirror_edges;
    float _enable_grading;
    float _grading_scale_right;
    float _grading_rotate_right;
    float _grading_scale_left;
    float _grading_rotate_left;
    float _grading_scale_down;
    float _grading_rotate_down;
    float _grading_scale_up;
    float _grading_rotate_up;
};

// --- funcoes auxiliares do efeito
float2 u_xlat0;
int2 u_xlati0;
bool2 u_xlatb0;
float4 u_xlat1;
float4 u_xlat2;
float4 u_xlat3;
bool4 u_xlatb3;
float4 u_xlat4;
int4 u_xlati4;
bool2 u_xlatb4;
float4 u_xlat5;
int4 u_xlati5;
bool4 u_xlatb5;
float4 u_xlat6;
bool2 u_xlatb6;
float4 u_xlat7;
float4 u_xlat8;
bool2 u_xlatb8;
float4 u_xlat9;
bool2 u_xlatb9;
float3 u_xlat10;
float4 u_xlat11;
bool2 u_xlatb11;
float u_xlat14;
float3 u_xlat15;
float2 u_xlat17;
int2 u_xlati17;
float2 u_xlat20;
float2 u_xlat21;
float2 u_xlat24;
int2 u_xlati24;
bool2 u_xlatb24;
float2 u_xlat25;
float2 u_xlat26;
bool2 u_xlatb26;
float2 u_xlat27;
float2 u_xlat28;
float2 u_xlat30;
bool2 u_xlatb30;
float2 u_xlat31;
float2 u_xlat32;
bool2 u_xlatb32;
float2 u_xlat35;
int u_xlati36;
bool u_xlatb36;
float u_xlat38;
int u_xlati38;
bool u_xlatb38;
float u_xlat39;
float u_xlat41;

fragment float4 fx_nv_nodevideo_rendercommand_transform2d_repe_tile(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_transform2d_repe_tileParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * u._viewport_ratio.xy;
    u_xlat24.xy = u_xlat0.yy * hlslcc_mtx4x4_trans_mat[1].xy;
    u_xlat24.xy = hlslcc_mtx4x4_trans_mat[0].xy * u_xlat0.xx + u_xlat24.xy;
    u_xlat24.xy = u_xlat24.xy + hlslcc_mtx4x4_trans_mat[3].xy;
    u_xlat24.xy = u_xlat24.xy / u._viewport_ratio.xy;
    u_xlat24.xy = u_xlat24.xy + float2(0.5, 0.5);
    u_xlat1.xy = (-u._range_start.xy) + float2(u._range_end.x, u._range_end.y);
    u_xlat25.xy = float2(u._range_end.x, u._range_end.y) + u._range_start.xy;
    u_xlat24.xy = u_xlat24.xy + (-u._range_start.xy);
    u_xlat2.xy = u_xlat24.xy / u_xlat1.xy;
    u_xlatb24.xy = greaterThanEqual(u_xlat2.yxyx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlat3.xy = abs(u_xlat2.yx) + float2(1.0, 1.0);
    {
        float4 hlslcc_movcTemp = u_xlat3;
        hlslcc_movcTemp.z = (u_xlatb24.x) ? u_xlat2.y : u_xlat3.x;
        hlslcc_movcTemp.w = (u_xlatb24.y) ? u_xlat2.x : u_xlat3.y;
        u_xlat3 = hlslcc_movcTemp;
    }
    u_xlat24.xy = u_xlat3.zw * float2(0.5, 0.5);
    u_xlatb4.xy = greaterThanEqual(u_xlat24.xyxx, (-u_xlat24.xyxx)).xy;
    u_xlat24.xy = fract(abs(u_xlat24.xy));
    {
        float2 hlslcc_movcTemp = u_xlat24;
        hlslcc_movcTemp.x = (u_xlatb4.x) ? u_xlat24.x : (-u_xlat24.x);
        hlslcc_movcTemp.y = (u_xlatb4.y) ? u_xlat24.y : (-u_xlat24.y);
        u_xlat24 = hlslcc_movcTemp;
    }
    u_xlatb24.xy = greaterThanEqual(u_xlat24.xyxy, float4(0.5, 0.5, 0.5, 0.5)).xy;
    u_xlat4.z = u_xlatb24.x ? float(1.0) : 0.0;
    u_xlat4.w = u_xlatb24.y ? float(1.0) : 0.0;
;
    u_xlatb5 = equal(int4(u._enable_motion, u._mirror_edges, u._mirror_edges, u._mirror_edges), int4(1, 1, 3, 2));
    u_xlat24.xy = u_xlat4.zw * float2(float2(u._phase, u._phase)) + u_xlat2.xy;
    u_xlatb6.xy = greaterThanEqual(u_xlat24.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlat30.xy = abs(u_xlat24.xy) + float2(1.0, 1.0);
    u_xlat3.x = (u_xlatb6.x) ? u_xlat24.x : u_xlat30.x;
    u_xlat3.y = (u_xlatb6.y) ? u_xlat24.y : u_xlat30.y;
    u_xlat4.x = u_xlat2.x;
    u_xlat4.y = u_xlat24.y;
    u_xlat2.x = u_xlat24.x;
    u_xlat2.zw = u_xlat4.zw;
    u_xlat6 = (int(u._phase_type) != 0) ? u_xlat4 : u_xlat2;
    u_xlat24.xy = (int(u._phase_type) != 0) ? u_xlat3.wy : u_xlat3.xz;
    u_xlat2.xzw = u_xlat4.xzw;
    u_xlat2 = (u_xlatb5.x) ? u_xlat6 : u_xlat2;
    u_xlat24.xy = (u_xlatb5.x) ? u_xlat24.xy : u_xlat3.wz;
    u_xlat3.xy = fract(u_xlat2.xy);
    u_xlati4 = int4(uint4(lessThan(float4(1.0, 1.0, 0.5, 0.5), u_xlat2)) * 0xFFFFFFFFu);
    u_xlat26.xy = u_xlat2.xy + float2(-1.0, -1.0);
    u_xlatb6.x = u._expand_right<u_xlat26.x;
    u_xlat3.z = (u_xlatb6.x) ? 0.0 : 1.0;
    u_xlat3.w = 1.0;
    u_xlat6.xy = (u_xlati4.x != 0) ? u_xlat3.xz : u_xlat3.xw;
    u_xlatb30.xy = lessThan(u_xlat2.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlat7.xy = fract((-u_xlat2.xy));
    u_xlat7.xy = (-u_xlat7.xy) + float2(1.0, 1.0);
    u_xlatb8.xy = lessThan(float4(u._expand_left, u._expand_up, u._expand_left, u._expand_left), (-u_xlat2.xyxx)).xy;
    u_xlat7.z = (u_xlatb8.x) ? 0.0 : u_xlat6.y;
    u_xlat3.zw = (u_xlatb30.x) ? u_xlat7.xz : u_xlat6.xy;
    u_xlatb6.x = u._expand_down<u_xlat26.y;
    u_xlat3.x = (u_xlatb6.x) ? 0.0 : u_xlat3.w;
    u_xlat3.xy = (u_xlati4.y != 0) ? u_xlat3.yx : u_xlat3.yw;
    u_xlat7.w = (u_xlatb8.y) ? 0.0 : u_xlat3.y;
    u_xlat3.xy = (u_xlatb30.y) ? u_xlat7.yw : u_xlat3.xy;
    u_xlati17.xy = int2(uint2((uint(u_xlatb5.z) * 0xffffffffu) | (uint(u_xlatb5.y) * 0xffffffffu), (uint(u_xlatb5.z) * 0xffffffffu) | (uint(u_xlatb5.w) * 0xffffffffu)));
    u_xlat24.xy = u_xlat24.xy * float2(0.5, 0.5);
    u_xlatb6.xy = greaterThanEqual(u_xlat24.xyxx, (-u_xlat24.xyxx)).xy;
    u_xlat24.xy = fract(abs(u_xlat24.xy));
    {
        float2 hlslcc_movcTemp = u_xlat24;
        hlslcc_movcTemp.x = (u_xlatb6.x) ? u_xlat24.x : (-u_xlat24.x);
        hlslcc_movcTemp.y = (u_xlatb6.y) ? u_xlat24.y : (-u_xlat24.y);
        u_xlat24 = hlslcc_movcTemp;
    }
    u_xlatb24.xy = greaterThanEqual(u_xlat24.xyxy, float4(0.5, 0.5, 0.5, 0.5)).xy;
    u_xlati24.xy = int2((uint2(u_xlatb24.xy) * 0xFFFFFFFFu) & uint2(u_xlati17.xy));
    u_xlat39 = (-u_xlat3.z) + 1.0;
    u_xlat6.x = (u_xlati24.x != 0) ? u_xlat39 : u_xlat3.z;
    u_xlat24.x = (-u_xlat3.x) + 1.0;
    u_xlat6.y = (u_xlati24.y != 0) ? u_xlat24.x : u_xlat3.x;
    u_xlatb24.x = u._enable_subtrans==1;
    u_xlatb3.xzw = equal(int4(int4(u._partition, u._partition, u._partition, u._partition)), int4(0, 0, 1, 2)).xzw;
    u_xlati36 = int(uint(uint(u_xlati4.z) | uint(u_xlati4.w)));
    u_xlati36 = (u_xlatb3.w) ? u_xlati4.w : u_xlati36;
    u_xlati36 = (u_xlatb3.z) ? u_xlati4.z : u_xlati36;
    u_xlati36 = int(uint(uint(u_xlati36) | (uint(u_xlatb3.x) * 0xffffffffu)));
    u_xlati36 = u_xlatb24.x ? u_xlati36 : int(0);
    u_xlat28.xy = u_xlat6.xy + float2(-0.5, -0.5);
    u_xlat7.xy = u_xlat1.xy * u._viewport_ratio.xy;
    u_xlat28.xy = u_xlat28.xy * u_xlat7.xy;
    u_xlat31.xy = float2(1.0, 1.0) / u._tiling_scale.xy;
    u_xlat28.xy = u_xlat28.xy * u_xlat31.xy;
    u_xlat41 = u._tillingt_rotation * 0.0174532942;
    u_xlat8.x = sin(u_xlat41);
    u_xlat9.x = cos(u_xlat41);
    u_xlat10.x = sin((-u_xlat41));
    u_xlat10.y = u_xlat9.x;
    u_xlat10.z = u_xlat8.x;
    u_xlat8.x = dot(u_xlat28.xy, u_xlat10.yz);
    u_xlat8.y = dot(u_xlat28.xy, u_xlat10.xy);
    u_xlat28.xy = u_xlat8.xy / u_xlat7.xy;
    u_xlat28.xy = u_xlat28.xy + float2(u._tiling_offset.x, u._tiling_offset.y);
    u_xlat28.xy = u_xlat28.xy + float2(0.5, 0.5);
    u_xlat28.xy = (int(u_xlati36) != 0) ? u_xlat28.xy : u_xlat6.xy;
    u_xlatb36 = u._enable_grading==1;
    u_xlat26.xy = ceil(u_xlat26.xy);
    u_xlat20.x = u_xlat26.x * u._grading_rotate_right;
    u_xlat20.y = u_xlat26.x * u._grading_scale_right + 1.0;
    u_xlat6.xy = (u_xlati4.x != 0) ? u_xlat20.yx : float2(1.0, 0.0);
    u_xlat2.xy = ceil((-u_xlat2.xy));
    u_xlat8.x = u_xlat2.x * u._grading_scale_left + u_xlat6.x;
    u_xlat8.y = u_xlat2.x * u._grading_rotate_left + u_xlat6.y;
    u_xlat2.xz = (u_xlatb30.x) ? u_xlat8.xy : u_xlat6.xy;
    u_xlat6.xy = u_xlat26.yy * float2(u._grading_scale_down, u._grading_rotate_down) + u_xlat2.xz;
    u_xlat2.xz = (u_xlati4.y != 0) ? u_xlat6.xy : u_xlat2.xz;
    u_xlat4.x = u_xlat2.y * u._grading_scale_up + u_xlat2.x;
    u_xlat4.y = u_xlat2.y * u._grading_rotate_up + u_xlat2.z;
    u_xlat2.xy = (u_xlatb30.y) ? u_xlat4.xy : u_xlat2.xz;
    u_xlat26.xy = (-u_xlat25.xy) * float2(0.5, 0.5) + u_xlat28.xy;
    u_xlat26.xy = u_xlat7.xy * u_xlat26.xy;
    u_xlat2.xz = u_xlat2.xx * u_xlat26.xy;
    u_xlat14 = u_xlat2.y * 0.0174532942;
    u_xlat4.x = sin(u_xlat14);
    u_xlat6.x = cos(u_xlat14);
    u_xlat8.x = sin((-u_xlat14));
    u_xlat8.y = u_xlat6.x;
    u_xlat8.z = u_xlat4.x;
    u_xlat4.x = dot(u_xlat2.xz, u_xlat8.yz);
    u_xlat4.y = dot(u_xlat2.xz, u_xlat8.xy);
    u_xlat2.xy = u_xlat4.xy / u_xlat7.xy;
    u_xlat2.xy = u_xlat25.xy * float2(0.5, 0.5) + u_xlat2.xy;
    u_xlat2.xy = (bool(u_xlatb36)) ? u_xlat2.xy : u_xlat28.xy;
    u_xlat2.xy = u_xlat1.xy * u_xlat2.xy + u._range_start.xy;
    u_xlatb26.xy = lessThan(u_xlat2.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb4.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat2.xyxx).xy;
    u_xlatb26.x = u_xlatb26.x || u_xlatb4.x;
    u_xlatb26.x = u_xlatb26.y || u_xlatb26.x;
    u_xlatb26.x = u_xlatb4.y || u_xlatb26.x;
    u_xlat26.x = (u_xlatb26.x) ? 0.0 : u_xlat3.y;
    u_xlat4 = inputImg.sample(__nv_smp, u_xlat2.xy);
    u_xlatb38 = 0<u._enable_motion_blur;
    if(u_xlatb38){
        u_xlat6.xy = u_xlat0.yy * hlslcc_mtx4x4_trans_mat_prev[1].xy;
        u_xlat0.xy = hlslcc_mtx4x4_trans_mat_prev[0].xy * u_xlat0.xx + u_xlat6.xy;
        u_xlat0.xy = u_xlat0.xy + hlslcc_mtx4x4_trans_mat_prev[3].xy;
        u_xlat0.xy = u_xlat0.xy / u._viewport_ratio.xy;
        u_xlat0.xy = u_xlat0.xy + (-u._range_start.xy);
        u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
        u_xlat6.xy = u_xlat0.xy / u_xlat1.xy;
        u_xlatb0.xy = greaterThanEqual(u_xlat6.yxyy, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlat8.xy = abs(u_xlat6.yx) + float2(1.0, 1.0);
        {
            float4 hlslcc_movcTemp = u_xlat8;
            hlslcc_movcTemp.z = (u_xlatb0.x) ? u_xlat6.y : u_xlat8.x;
            hlslcc_movcTemp.w = (u_xlatb0.y) ? u_xlat6.x : u_xlat8.y;
            u_xlat8 = hlslcc_movcTemp;
        }
        u_xlat0.xy = u_xlat8.zw * float2(0.5, 0.5);
        u_xlatb9.xy = greaterThanEqual(u_xlat0.xyxx, (-u_xlat0.xyxx)).xy;
        u_xlat0.xy = fract(abs(u_xlat0.xy));
        {
            float2 hlslcc_movcTemp = u_xlat0;
            hlslcc_movcTemp.x = (u_xlatb9.x) ? u_xlat0.x : (-u_xlat0.x);
            hlslcc_movcTemp.y = (u_xlatb9.y) ? u_xlat0.y : (-u_xlat0.y);
            u_xlat0 = hlslcc_movcTemp;
        }
        u_xlatb0.xy = greaterThanEqual(u_xlat0.xyxx, float4(0.5, 0.5, 0.0, 0.0)).xy;
        u_xlat9.z = u_xlatb0.x ? float(1.0) : 0.0;
        u_xlat9.w = u_xlatb0.y ? float(1.0) : 0.0;
;
        u_xlat0.xy = u_xlat9.zw * float2(float2(u._phase, u._phase)) + u_xlat6.xy;
        u_xlatb11.xy = greaterThanEqual(u_xlat0.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlat35.xy = abs(u_xlat0.xy) + float2(1.0, 1.0);
        u_xlat8.x = (u_xlatb11.x) ? u_xlat0.x : u_xlat35.x;
        u_xlat8.y = (u_xlatb11.y) ? u_xlat0.y : u_xlat35.y;
        u_xlat9.x = u_xlat6.x;
        u_xlat9.y = u_xlat0.y;
        u_xlat6.x = u_xlat0.x;
        u_xlat6.zw = u_xlat9.zw;
        u_xlat11 = (int(u._phase_type) != 0) ? u_xlat9 : u_xlat6;
        u_xlat0.xy = (int(u._phase_type) != 0) ? u_xlat8.wy : u_xlat8.xz;
        u_xlat6.xzw = u_xlat9.xzw;
        u_xlat6 = (u_xlatb5.x) ? u_xlat11 : u_xlat6;
        u_xlat0.xy = (u_xlatb5.x) ? u_xlat0.xy : u_xlat8.wz;
        u_xlat5.xw = fract(u_xlat6.xy);
        u_xlatb8.xy = lessThan(u_xlat6.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlat32.xy = fract((-u_xlat6.xy));
        u_xlat32.xy = (-u_xlat32.xy) + float2(1.0, 1.0);
        {
            float4 hlslcc_movcTemp = u_xlat5;
            hlslcc_movcTemp.x = (u_xlatb8.x) ? u_xlat32.x : u_xlat5.x;
            hlslcc_movcTemp.w = (u_xlatb8.y) ? u_xlat32.y : u_xlat5.w;
            u_xlat5 = hlslcc_movcTemp;
        }
        u_xlat0.xy = u_xlat0.xy * float2(0.5, 0.5);
        u_xlatb32.xy = greaterThanEqual(u_xlat0.xyxy, (-u_xlat0.xyxy)).xy;
        u_xlat0.xy = fract(abs(u_xlat0.xy));
        {
            float2 hlslcc_movcTemp = u_xlat0;
            hlslcc_movcTemp.x = (u_xlatb32.x) ? u_xlat0.x : (-u_xlat0.x);
            hlslcc_movcTemp.y = (u_xlatb32.y) ? u_xlat0.y : (-u_xlat0.y);
            u_xlat0 = hlslcc_movcTemp;
        }
        u_xlatb0.xy = greaterThanEqual(u_xlat0.xyxx, float4(0.5, 0.5, 0.0, 0.0)).xy;
        u_xlati0.xy = int2((uint2(u_xlatb0.xy) * 0xFFFFFFFFu) & uint2(u_xlati17.xy));
        u_xlat17.xy = (-u_xlat5.xw) + float2(1.0, 1.0);
        u_xlat0.x = (u_xlati0.x != 0) ? u_xlat17.x : u_xlat5.x;
        u_xlat0.y = (u_xlati0.y != 0) ? u_xlat17.y : u_xlat5.w;
        u_xlati5 = int4(uint4(lessThan(float4(1.0, 1.0, 0.5, 0.5), u_xlat6)) * 0xFFFFFFFFu);
        u_xlati38 = int(uint(uint(u_xlati5.z) | uint(u_xlati5.w)));
        u_xlati38 = (u_xlatb3.w) ? u_xlati5.w : u_xlati38;
        u_xlati38 = (u_xlatb3.z) ? u_xlati5.z : u_xlati38;
        u_xlati38 = int(uint(uint(u_xlati38) | (uint(u_xlatb3.x) * 0xffffffffu)));
        u_xlati24.x = u_xlatb24.x ? u_xlati38 : int(0);
        u_xlat3.xy = u_xlat0.xy + float2(-0.5, -0.5);
        u_xlat3.xy = u_xlat7.xy * u_xlat3.xy;
        u_xlat3.xy = u_xlat31.xy * u_xlat3.xy;
        u_xlat9.x = dot(u_xlat3.xy, u_xlat10.yz);
        u_xlat9.y = dot(u_xlat3.xy, u_xlat10.xy);
        u_xlat3.xy = u_xlat9.xy / u_xlat7.xy;
        u_xlat3.xy = u_xlat3.xy + float2(u._tiling_offset.x, u._tiling_offset.y);
        u_xlat3.xy = u_xlat3.xy + float2(0.5, 0.5);
        u_xlat0.xy = (u_xlati24.x != 0) ? u_xlat3.xy : u_xlat0.xy;
        u_xlat3.xy = u_xlat6.xy + float2(-1.0, -1.0);
        u_xlat3.xy = ceil(u_xlat3.xy);
        u_xlat21.x = u_xlat3.x * u._grading_rotate_right;
        u_xlat21.y = u_xlat3.x * u._grading_scale_right + 1.0;
        u_xlat3.xz = (u_xlati5.x != 0) ? u_xlat21.yx : float2(1.0, 0.0);
        u_xlat5.xz = ceil((-u_xlat6.xy));
        u_xlat6.x = u_xlat5.x * u._grading_scale_left + u_xlat3.x;
        u_xlat6.y = u_xlat5.x * u._grading_rotate_left + u_xlat3.z;
        u_xlat3.xz = (u_xlatb8.x) ? u_xlat6.xy : u_xlat3.xz;
        u_xlat15.xz = u_xlat3.yy * float2(u._grading_scale_down, u._grading_rotate_down) + u_xlat3.xz;
        u_xlat3.xy = (u_xlati5.y != 0) ? u_xlat15.xz : u_xlat3.xz;
        u_xlat5.x = u_xlat5.z * u._grading_scale_up + u_xlat3.x;
        u_xlat5.y = u_xlat5.z * u._grading_rotate_up + u_xlat3.y;
        u_xlat3.xy = (u_xlatb8.y) ? u_xlat5.xy : u_xlat3.xy;
        u_xlat27.xy = (-u_xlat25.xy) * float2(0.5, 0.5) + u_xlat0.xy;
        u_xlat27.xy = u_xlat7.xy * u_xlat27.xy;
        u_xlat3.xz = u_xlat3.xx * u_xlat27.xy;
        u_xlat24.x = u_xlat3.y * 0.0174532942;
        u_xlat5.x = sin(u_xlat24.x);
        u_xlat6.x = cos(u_xlat24.x);
        u_xlat8.x = sin((-u_xlat24.x));
        u_xlat8.y = u_xlat6.x;
        u_xlat8.z = u_xlat5.x;
        u_xlat5.x = dot(u_xlat3.xz, u_xlat8.yz);
        u_xlat5.y = dot(u_xlat3.xz, u_xlat8.xy);
        u_xlat3.xy = u_xlat5.xy / u_xlat7.xy;
        u_xlat25.xy = u_xlat25.xy * float2(0.5, 0.5) + u_xlat3.xy;
        u_xlat0.xy = (bool(u_xlatb36)) ? u_xlat25.xy : u_xlat0.xy;
        u_xlat0.xy = u_xlat1.xy * u_xlat0.xy + u._range_start.xy;
        u_xlat0.xy = (-u_xlat0.xy) + u_xlat2.xy;
        u_xlat0.xy = u_xlat0.xy * float2(u._amount);
        u_xlati24.x = u._samples + int(0xFFFFFFFFu);
        u_xlat24.x = float(u_xlati24.x);
        u_xlat1 = u_xlat4;
        for(int u_xlati_loop_1 = 1 ; u_xlati_loop_1<u._samples ; u_xlati_loop_1++)
        {
            u_xlat38 = float(u_xlati_loop_1);
            u_xlat38 = u_xlat38 / u_xlat24.x;
            u_xlat3.xy = u_xlat0.xy * float2(u_xlat38) + u_xlat2.xy;
            u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.xy);
            u_xlat5.z = u_xlat38 * 3.0 + -1.5;
            u_xlat5.y = -abs(u_xlat5.z) + 1.0;
            u_xlat5.x = (-u_xlat5.z);
            u_xlat5.xyz = u_xlat5.xyz;
            u_xlat5.xyz = clamp(u_xlat5.xyz, 0.0, 1.0);
            u_xlat5.xyz = u_xlat3.xyz * u_xlat5.xyz;
            u_xlat5.xyz = u_xlat5.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat3.xyz);
            u_xlat3.xyz = float3(u._dispersion) * u_xlat5.xyz + u_xlat3.xyz;
            u_xlat1 = u_xlat1 + u_xlat3;
            u_xlat1.xyz = u_xlat4.xyz * float3(float3(u._stay, u._stay, u._stay)) + u_xlat1.xyz;
        }
        u_xlat0.x = float(u._samples);
        u_xlat4 = u_xlat1 / u_xlat0.xxxx;
    }
    __nv_out = u_xlat26.xxxx * u_xlat4;
    return __nv_out;
    return __nv_out;
}
