// ---------------------------------------------------------------------------
// Rendercommand Flow (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-flow.xml
// id     : nv.effect.nodevideo-rendercommand-flow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_flowParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _strength;
    float _speed;
    float _show_canvas;
    float _blend;
    float2 _offset;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat13;
bool u_xlatb13;
float u_xlat19;

fragment float4 fx_nv_nodevideo_rendercommand_flow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_flowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> flow_map [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + (-u._offset.xy);
    u_xlat0 = flow_map.sample(__nv_smp, u_xlat0.xy);
    u_xlat1.xy = u_xlat0.xy + float2(-0.501960814, -0.501960814);
    u_xlat1.xy = u_xlat1.xy * float2(u._strength);
    u_xlatb13 = int(u._blend)<0;
    if(u_xlatb13){
        u_xlat13.x = _cur_time * u._speed + 0.5;
        u_xlat13.x = fract(u_xlat13.x);
        u_xlat13.xy = (-u_xlat1.xy) * u_xlat13.xx + in.acScreenNorm.xy;
        u_xlat2 = inputImg.sample(__nv_smp, u_xlat13.xy);
    } else {
        u_xlat13.x = _cur_time * u._speed;
        u_xlat13.x = fract(u_xlat13.x);
        u_xlat3.xy = (-u_xlat1.xy) * u_xlat13.xx + in.acScreenNorm.xy;
        u_xlat19 = _cur_time * u._speed + 0.5;
        u_xlat19 = fract(u_xlat19);
        u_xlat1.xy = (-u_xlat1.xy) * float2(u_xlat19) + in.acScreenNorm.xy;
        u_xlat13.x = (-u_xlat13.x) + 0.5;
        u_xlat13.x = u_xlat13.x + u_xlat13.x;
        u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.xy);
        u_xlat4 = inputImg.sample(__nv_smp, u_xlat1.xy);
        u_xlat4 = (-u_xlat3) + u_xlat4;
        u_xlat2 = abs(u_xlat13.xxxx) * u_xlat4 + u_xlat3;
    }
    u_xlatb1 = 0<int(u._show_canvas);
    u_xlat0 = u_xlat0 + float4(-0.5, -0.5, -0.5, -0.5);
    u_xlat0 = u_xlat0 * float4(0.5, 0.5, 0.5, 0.5) + u_xlat2;
    u_xlat0 = (bool(u_xlatb1)) ? u_xlat0 : u_xlat2;
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
