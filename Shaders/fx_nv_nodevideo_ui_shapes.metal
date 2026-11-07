// ---------------------------------------------------------------------------
// Ui Shapes (NV)
// origem : assets/effects/nv-nodevideo-ui-shapes.xml
// id     : nv.effect.nodevideo-ui-shapes
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_ui_shapesParams {
    float _Radius;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float2 u_xlat16_0;
float u_xlat1;
float u_xlat3;
float u_xlat5;

fragment float4 fx_nv_nodevideo_ui_shapes(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_ui_shapesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat16_0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat16_0.xy = u_xlat16_0.xy + u_xlat16_0.xy;
    u_xlat1 = dot(u_xlat16_0.xy, u_xlat16_0.xy);
    u_xlat1 = sqrt(u_xlat1);
    u_xlat1 = u_xlat1 + (-u._Radius);
    u_xlat3 = dfdx(u_xlat1);
    u_xlat5 = dfdy(u_xlat1);
    u_xlat3 = abs(u_xlat5) + abs(u_xlat3);
    u_xlat1 = (-u_xlat3) * 0.5 + u_xlat1;
    u_xlat3 = float(1.0) / (-u_xlat3);
    u_xlat1 = u_xlat3 * u_xlat1;
    u_xlat1 = clamp(u_xlat1, 0.0, 1.0);
    u_xlat3 = u_xlat1 * -2.0 + 3.0;
    u_xlat1 = u_xlat1 * u_xlat1;
    u_xlat0.w = u_xlat1 * u_xlat3;
    u_xlat0.x = float(1.0);
    u_xlat0.y = float(1.0);
    u_xlat0.z = float(1.0);
    __nv_out = u_xlat0 * in.vs_COLOR0;
    return __nv_out;
    return __nv_out;
}
