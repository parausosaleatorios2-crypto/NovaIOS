// ---------------------------------------------------------------------------
// Rendercommand Shape Mask (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-shape-mask.xml
// id     : nv.effect.nodevideo-rendercommand-shape-mask
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_shape_maskParams {
    float _show_inner_mask;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;

fragment float4 fx_nv_nodevideo_rendercommand_shape_mask(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_shape_maskParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb1 = 0<int(u._show_inner_mask);
    if(u_xlatb1){
        __nv_out = u_xlat0 * float4(1.0, 0.0, 1.0, 1.0);
        return __nv_out;
    }
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    __nv_out = u_xlat0 * u_xlat1;
    return __nv_out;
    return __nv_out;
}
