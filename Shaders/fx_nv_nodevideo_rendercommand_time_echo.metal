// ---------------------------------------------------------------------------
// Rendercommand  Time Echo (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-time-echo.xml
// id     : nv.effect.nodevideo-rendercommand-time-echo
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_time_echoParams {
    float _opacity;
    float _blend;
    float _frame;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
bool4 u_xlatb4;
float4 u_xlat5;
bool u_xlatb6;

fragment float4 fx_nv_nodevideo_rendercommand_time_echo(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_time_echoParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> EchoBuff [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1 = EchoBuff.sample(__nv_smp, in.acScreenNorm.xy);
    if(int(u._blend) == 0) {
        __nv_out = u_xlat0 * float4(u._opacity) + u_xlat1;
    } else {
        u_xlatb2 = int(u._blend)==1;
        if(u_xlatb2){
            u_xlatb2 = 0<int(u._frame);
            u_xlat3 = max(u_xlat0, u_xlat1);
            __nv_out = (bool(u_xlatb2)) ? u_xlat3 : u_xlat0;
        } else {
            u_xlatb2 = int(u._blend)==2;
            if(u_xlatb2){
                u_xlatb2 = 0<int(u._frame);
                u_xlat3 = min(u_xlat0, u_xlat1);
                __nv_out = (bool(u_xlatb2)) ? u_xlat3 : u_xlat0;
            } else {
                u_xlat2 = u_xlat0 * float4(u._opacity);
                u_xlat3 = (-u_xlat0) * float4(u._opacity) + float4(1.0, 1.0, 1.0, 1.0);
                u_xlat4 = (-u_xlat1) + float4(1.0, 1.0, 1.0, 1.0);
                u_xlat3 = (-u_xlat3) * u_xlat4 + float4(1.0, 1.0, 1.0, 1.0);
                u_xlat4.x = (-u._opacity) + 1.0;
                u_xlat5 = u_xlat1 * float4(u._opacity);
                u_xlat5 = u_xlat0 * u_xlat4.xxxx + u_xlat5;
                u_xlat2 = u_xlat1 * u_xlat4.xxxx + u_xlat2;
                u_xlatb4 = equal(int4(int4(int(u._blend), int(u._blend), int(u._blend), int(u._blend))), int4(3, 4, 5, 6));
                u_xlatb6 = 0<int(u._frame);
                u_xlat1 = u_xlat0 + u_xlat1;
                u_xlat1 = u_xlat1 * float4(0.5, 0.5, 0.5, 0.5);
                u_xlat0 = (bool(u_xlatb6)) ? u_xlat1 : u_xlat0;
                u_xlat0 = u_xlatb4.w ? u_xlat0 : float4(0.0, 0.0, 0.0, 0.0);
                u_xlat0 = (u_xlatb4.z) ? u_xlat2 : u_xlat0;
                u_xlat0 = (u_xlatb4.y) ? u_xlat5 : u_xlat0;
                __nv_out = (u_xlatb4.x) ? u_xlat3 : u_xlat0;
            }
        }
    }
    return __nv_out;
    return __nv_out;
}
