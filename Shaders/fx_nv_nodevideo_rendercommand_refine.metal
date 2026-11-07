// ---------------------------------------------------------------------------
// Rendercommand Refine (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-refine.xml
// id     : nv.effect.nodevideo-rendercommand-refine
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_refineParams {
    float _blur_amount;
    float _z;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _SourceTex_TexelSize (1.0 / float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))))
float2 u_xlat0;
float2 u_xlat1;
float4 u_xlat2;
float4 u_xlat3;
int u_xlati8;
int2 u_xlati9;
float u_xlat12;
bool u_xlatb12;

fragment float4 fx_nv_nodevideo_rendercommand_refine(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_refineParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy / _SourceTex_TexelSize.xy;
    u_xlat1.y = 0.0;
    u_xlat2.x = float(0.0);
    u_xlat2.y = float(0.0);
    u_xlat2.z = float(0.0);
    u_xlat2.w = float(0.0);
    u_xlati8 = int(0xFFFFFFF4u);
    while(true){
        u_xlatb12 = 12<u_xlati8;
        if(u_xlatb12){break;}
        u_xlati9.xy = int2(u_xlati8) + int2(12, 1);
        u_xlat12 = float(u_xlati8);
        u_xlat1.x = u_xlat12 * u._blur_amount;
        u_xlat3.xy = u_xlat0.xy + u_xlat1.xy;
        u_xlat3.xy = u_xlat3.xy * _SourceTex_TexelSize.xy;
        u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.xy);
        u_xlat2 = float4(_kernel[u_xlati9.x]) * u_xlat3 + u_xlat2;
        u_xlati8 = u_xlati9.y;
    }
    __nv_out = u_xlat2 / float4(float4(u._z, u._z, u._z, u._z));
    return __nv_out;
    return __nv_out;
}
