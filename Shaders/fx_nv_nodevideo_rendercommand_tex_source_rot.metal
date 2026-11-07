// ---------------------------------------------------------------------------
// Rendercommand Tex Source Rot (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-tex-source-rot.xml
// id     : nv.effect.nodevideo-rendercommand-tex-source-rot
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_tex_source_rotParams { int __vazio; };

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float3 u_xlat1;
bool3 u_xlatb1;

fragment float4 fx_nv_nodevideo_rendercommand_tex_source_rot(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_tex_source_rotParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb1.xy = greaterThanEqual(in.acScreenNorm.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlat1.x = u_xlatb1.x ? float(1.0) : 0.0;
    u_xlat1.y = u_xlatb1.y ? float(1.0) : 0.0;
;
    u_xlat0 = u_xlat0 * u_xlat1.xxxx;
    u_xlat1.xz = (-in.acScreenNorm.xy) + float2(1.0, 1.0);
    u_xlatb1.xz = greaterThanEqual(u_xlat1.xxzx, float4(0.0, 0.0, 0.0, 0.0)).xz;
    u_xlat1.x = u_xlatb1.x ? float(1.0) : 0.0;
    u_xlat1.z = u_xlatb1.z ? float(1.0) : 0.0;
;
    u_xlat0 = u_xlat0 * u_xlat1.xxxx;
    u_xlat0 = u_xlat1.yyyy * u_xlat0;
    __nv_out = u_xlat1.zzzz * u_xlat0;
    return __nv_out;
    return __nv_out;
}
