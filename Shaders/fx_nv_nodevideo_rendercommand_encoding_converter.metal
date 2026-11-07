// ---------------------------------------------------------------------------
// Rendercommand  Encoding Converter (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-encoding-converter.xml
// id     : nv.effect.nodevideo-rendercommand-encoding-converter
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_encoding_converterParams { int __vazio; };

// --- funcoes auxiliares do efeito
float4 u_xlat0;

fragment float4 fx_nv_nodevideo_rendercommand_encoding_converter(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_encoding_converterParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    __nv_out = u_xlat0.yzwx;
    return __nv_out;
    return __nv_out;
}
