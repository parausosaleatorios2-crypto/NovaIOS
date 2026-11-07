// ---------------------------------------------------------------------------
// Rendercommand Roto Brush (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-roto-brush.xml
// id     : nv.effect.nodevideo-rendercommand-roto-brush
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_roto_brushParams {
    float _has_mask;
};

// --- funcoes auxiliares do efeito
bool u_xlatb0;
float4 u_xlat1;
float4 u_xlat2;

fragment float4 fx_nv_nodevideo_rendercommand_roto_brush(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_roto_brushParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> rotomask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0 = int(u._has_mask)==1;
    u_xlat1 = rotomask.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat2 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1 = u_xlat1 + u_xlat2;
    __nv_out = (bool(u_xlatb0)) ? u_xlat1 : u_xlat2;
    return __nv_out;
    return __nv_out;
}
