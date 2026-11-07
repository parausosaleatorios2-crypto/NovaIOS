// ---------------------------------------------------------------------------
// Ui Prop Node (NV)
// origem : assets/effects/nv-nodevideo-ui-prop-node.xml
// id     : nv.effect.nodevideo-ui-prop-node
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_ui_prop_nodeParams {
    float4 _fill_color;
    float _hasRT;
};

// --- funcoes auxiliares do efeito
float3 u_xlat0;
float3 u_xlat1;
bool u_xlatb6;

fragment float4 fx_nv_nodevideo_ui_prop_node(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_ui_prop_nodeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = u._fill_color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat0.xyz = u._fill_color.xyz * u_xlat0.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat0.xyz = u_xlat0.xyz * u._fill_color.xyz;
    u_xlat1.xyz = inputImg.sample(__nv_smp, in.acScreenNorm.xy).xyz;
    u_xlatb6 = 0<int(u._hasRT);
    __nv_out.xyz = (bool(u_xlatb6)) ? u_xlat1.xyz : u_xlat0.xyz;
    u_xlat0.x = 1.0;
    __nv_out.w = (u_xlatb6) ? u_xlat0.x : u._fill_color.w;
    return __nv_out;
    return __nv_out;
}
