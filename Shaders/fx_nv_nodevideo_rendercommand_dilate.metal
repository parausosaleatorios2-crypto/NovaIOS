// ---------------------------------------------------------------------------
// Rendercommand Dilate (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-dilate.xml
// id     : nv.effect.nodevideo-rendercommand-dilate
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_dilateParams {
    float _dilate;
    float _dilate_threshold;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _SourceTex_TexelSize (1.0 / float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))))
float2 u_xlat0;
int u_xlati1;
float u_xlat2;
float2 u_xlat3;
float2 u_xlat5;
bool u_xlatb5;
float u_xlat8;
float u_xlat12;

fragment float4 fx_nv_nodevideo_rendercommand_dilate(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_dilateParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = _SourceTex_TexelSize.xy * float2(float2(u._dilate, u._dilate));
    u_xlat8 = float(0.0);
    u_xlat12 = float(0.0);
    for(int u_xlati_loop_1 = 0 ; u_xlati_loop_1<32 ; u_xlati_loop_1++)
    {
        u_xlat12 = u_xlat12 + 0.196349531;
        u_xlat2 = sin(u_xlat12);
        u_xlat3.x = cos(u_xlat12);
        u_xlat3.x = u_xlat0.x * u_xlat3.x;
        u_xlat3.y = u_xlat0.y * u_xlat2;
        u_xlat5.xy = u_xlat3.xy + in.acScreenNorm.xy;
        u_xlat5.xy = clamp(u_xlat5.xy, 0.0, 1.0);
        u_xlat5.x = inputImg.sample(__nv_smp, u_xlat5.xy).w;
        u_xlatb5 = u._dilate_threshold<u_xlat5.x;
        u_xlat8 = (u_xlatb5) ? 1.0 : u_xlat8;
    }
    __nv_out = float4(u_xlat8);
    return __nv_out;
    return __nv_out;
}
