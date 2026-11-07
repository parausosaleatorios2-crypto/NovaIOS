// ---------------------------------------------------------------------------
// Rendercommand Color (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-color.xml
// id     : nv.effect.nodevideo-rendercommand-color
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_colorParams {
    float4 _fill_color;
    float _fill_type;
    float _gradient_type;
    float4 _gradient_color1;
    float4 _gradient_color2;
    float _gradient_axis;
    float _gradient_start;
    float2 _gradient_offset;
    float _gradient_rotation;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool u_xlatb2;
float4 u_xlat3;
float3 u_xlat4;
float2 u_xlat11;
bool u_xlatb11;
bool u_xlatb16;

fragment float4 fx_nv_nodevideo_rendercommand_color(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_colorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if(int(u._fill_type) == 0) {
        u_xlat0.xyz = u._fill_color.xyz;
        __nv_out.w = u._fill_color.w;
    } else {
        u_xlatb1 = int(u._fill_type)==1;
        if(u_xlatb1){
            u_xlat1.xy = _viewport_ratio.yx * float2(0.5, 0.5);
            u_xlat1.xy = in.acScreenNorm.yx * _viewport_ratio.yx + (-u_xlat1.xy);
            u_xlat2.x = sin(u._gradient_rotation);
            u_xlat3.x = cos(u._gradient_rotation);
            u_xlat11.xy = u_xlat1.xy * u_xlat2.xx;
            u_xlat2.x = u_xlat1.y * u_xlat3.x + (-u_xlat11.x);
            u_xlat2.y = u_xlat1.x * u_xlat3.x + u_xlat11.y;
            u_xlat1.xy = u_xlat2.xy + float2(u._gradient_offset.x, u._gradient_offset.y);
            u_xlat1.z = u._gradient_start + -0.5;
            u_xlat1.w = 0.5;
            u_xlat2.xyz = (int(u._gradient_axis) != 0) ? u_xlat1.zwy : u_xlat1.zwx;
            u_xlatb11 = int(u._gradient_type)==1;
            u_xlat3.xy = abs(u_xlat1.xy);
            u_xlat3.z = u._gradient_start * 0.5;
            u_xlat3.w = 0.5;
            u_xlat3.xyz = (int(u._gradient_axis) != 0) ? u_xlat3.zwy : u_xlat3.zwx;
            u_xlat1.x = dot(u_xlat1.xy, u_xlat1.xy);
            u_xlat4.z = sqrt(u_xlat1.x);
            u_xlat4.x = u._gradient_start * 0.707106769;
            u_xlat4.y = 0.707106769;
            u_xlat1.xyz = (bool(u_xlatb11)) ? u_xlat3.xyz : u_xlat4.xyz;
            u_xlat1.xyz = (int(u._gradient_type) != 0) ? u_xlat1.xyz : u_xlat2.xyz;
            u_xlatb16 = u_xlat1.z>=u_xlat1.x;
            u_xlatb2 = u_xlat1.x==u_xlat1.y;
            u_xlat1.xy = (-u_xlat1.xx) + u_xlat1.zy;
            u_xlat1.x = u_xlat1.x / u_xlat1.y;
            u_xlat3 = (-u._gradient_color1) + u._gradient_color2;
            u_xlat3 = u_xlat1.xxxx * u_xlat3 + u._gradient_color1;
            u_xlat2 = (bool(u_xlatb2)) ? u._gradient_color2 : u_xlat3;
            u_xlat0 = (bool(u_xlatb16)) ? u_xlat2 : u._gradient_color1;
            __nv_out.w = u_xlat0.w;
        } else {
            u_xlat0.x = float(0.0);
            u_xlat0.y = float(0.0);
            u_xlat0.z = float(0.0);
            __nv_out.w = 0.0;
        }
    }
    u_xlat1.xyz = u_xlat0.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    __nv_out.xyz = u_xlat0.xyz * u_xlat1.xyz;
    return __nv_out;
    return __nv_out;
}
