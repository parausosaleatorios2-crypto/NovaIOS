// ---------------------------------------------------------------------------
// Effect Distort Skew (NV)
// origem : assets/effects/nv-nodevideo-effect-distort-skew.xml
// id     : nv.effect.nodevideo-effect-distort-skew
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_distort_skewParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _skew_pivot;
    float2 _skew_pivot_prev;
    float _skew_x;
    float _skew_y;
    float _motion_amount;
    float _motion_stay;
    float _motion_samples;
    float _enable_motion_blur;
    float _texture_wrap_mode;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
// Matrizes de skew que o HLSLcc esperava do cbuffer VGlobals do Unity (que o conversor automático perdeu).
// Column-major (GLSL): coluna 0 = (1, shearY, 0, 0); coluna 1 = (shearX, 1, 0, 0); coluna 3 = translação (zero aqui,
// o pivô é tratado fora da matriz). O _prev é identidade — motion blur do skew exige o valor do quadro anterior,
// que o motor não guarda hoje; fica off (passthrough) pra esse lado até surgir `prevState`.
// Global do GLSL ES só aceita valor constante: a matriz é montada no começo do main (0.910.0).
float4x4 hlslcc_mtx4x4_skew_mat;
float4x4 hlslcc_mtx4x4_skew_mat_prev = float4x4(1.0);

float4 u_xlat0;
bool2 u_xlatb0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
bool u_xlatb4;
float4 u_xlat5;
float2 u_xlat7;
int u_xlati7;
bool u_xlatb7;
float2 u_xlat12;
bool2 u_xlatb12;
int u_xlati13;
bool u_xlatb16;
int u_xlati19;

fragment float4 fx_nv_nodevideo_effect_distort_skew(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_distort_skewParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> SourceTexMirror [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    hlslcc_mtx4x4_skew_mat = float4x4(
    float4(1.0, u._skew_y, 0.0, 0.0),
    float4(u._skew_x, 1.0, 0.0, 0.0),
    float4(0.0, 0.0, 1.0, 0.0),
    float4(0.0, 0.0, 0.0, 1.0));
    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat12.xy = u._skew_pivot.xy + float2(-0.5, -0.5);
    u_xlat1.xy = (-u_xlat12.xy) + u_xlat0.xy;
    u_xlat1.xy = u_xlat1.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat7.xy = u_xlat1.yy * hlslcc_mtx4x4_skew_mat[1].xy;
    u_xlat1.xy = hlslcc_mtx4x4_skew_mat[0].xy * u_xlat1.xx + u_xlat7.xy;
    u_xlat1.xy = u_xlat1.xy + hlslcc_mtx4x4_skew_mat[3].xy;
    u_xlat1.xy = u_xlat1.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat12.xy = u_xlat12.xy + u_xlat1.xy;
    u_xlat12.xy = u_xlat12.xy + float2(0.5, 0.5);
    u_xlatb1 = int(u._texture_wrap_mode)==2;
    if(u_xlatb1){
        u_xlat2 = SourceTexMirror.sample(__nv_smp, u_xlat12.xy);
    } else {
        u_xlat2 = inputImg.sample(__nv_smp, u_xlat12.xy);
    }
    u_xlatb7 = 0<int(u._enable_motion_blur);
    if(u_xlatb7){
        u_xlat7.xy = float2(u._skew_pivot_prev.x, u._skew_pivot_prev.y) + float2(-0.5, -0.5);
        u_xlat0.xy = u_xlat0.xy + (-u_xlat7.xy);
        u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
        u_xlat3.xy = u_xlat0.yy * hlslcc_mtx4x4_skew_mat_prev[1].xy;
        u_xlat0.xy = hlslcc_mtx4x4_skew_mat_prev[0].xy * u_xlat0.xx + u_xlat3.xy;
        u_xlat0.xy = u_xlat0.xy + hlslcc_mtx4x4_skew_mat_prev[3].xy;
        u_xlat0.xy = u_xlat0.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
        u_xlat0.xy = u_xlat7.xy + u_xlat0.xy;
        u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
        u_xlat0.xy = (-u_xlat0.xy) + u_xlat12.xy;
        u_xlat0.xy = u_xlat0.xy * float2(u._motion_amount);
        u_xlati7 = int(u._motion_samples) + int(0xFFFFFFFFu);
        u_xlat7.x = float(u_xlati7);
        u_xlat3 = u_xlat2;
        u_xlati13 = int(u._texture_wrap_mode);
        for(int u_xlati_loop_1 = 1 ; u_xlati_loop_1<int(u._motion_samples) ; u_xlati_loop_1++)
        {
            u_xlat4.x = float(u_xlati_loop_1);
            u_xlat4.x = u_xlat4.x / u_xlat7.x;
            u_xlat4.xy = (-u_xlat0.xy) * u_xlat4.xx + u_xlat12.xy;
            u_xlatb16 = u_xlati13==2;
            if(u_xlatb16){
                u_xlat5 = SourceTexMirror.sample(__nv_smp, u_xlat4.xy);
            } else {
                u_xlat5 = inputImg.sample(__nv_smp, u_xlat4.xy);
            }
            u_xlat3 = u_xlat3 + u_xlat5;
            u_xlat3.xyz = u_xlat2.xyz * float3(float3(u._motion_stay, u._motion_stay, u._motion_stay)) + u_xlat3.xyz;
        }
        u_xlat0.x = float(int(u._motion_samples));
        u_xlat2 = u_xlat3 / u_xlat0.xxxx;
    }
    u_xlatb0.xy = lessThan(u_xlat12.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb12.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat12.xyxy).xy;
    u_xlatb0.x = u_xlatb12.x || u_xlatb0.x;
    u_xlatb0.x = u_xlatb0.y || u_xlatb0.x;
    u_xlatb0.x = u_xlatb12.y || u_xlatb0.x;
    u_xlat0.x = (u_xlatb0.x) ? 0.0 : 1.0;
    u_xlat0.x = (int(u._texture_wrap_mode) != 0) ? 1.0 : u_xlat0.x;
    u_xlat0 = u_xlat0.xxxx * u_xlat2;
    if(u_xlatb1){
        u_xlat1 = SourceTexMirror.sample(__nv_smp, in.acScreenNorm.xy);
    } else {
        u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    }
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
