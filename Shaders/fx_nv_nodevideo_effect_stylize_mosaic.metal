// ---------------------------------------------------------------------------
// Effect Stylize Mosaic (NV)
// origem : assets/effects/nv-nodevideo-effect-stylize-mosaic.xml
// id     : nv.effect.nodevideo-effect-stylize-mosaic
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_stylize_mosaicParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _pixelisation;
    float _horizontal_size;
    float _vertical_size;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
bool u_xlatb12;
float u_xlat18;

fragment float4 fx_nv_nodevideo_effect_stylize_mosaic(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_stylize_mosaicParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.yx + float2(-0.5, -0.5);
    u_xlat1.xyz = float3(512.0, 512.0, 512.0) / float3(u._pixelisation, u._horizontal_size, u._vertical_size);
    u_xlat18 = _resolution.x / _resolution.y;
    u_xlat0.z = u_xlat0.x / u_xlat18;
    u_xlat0.xy = u_xlat0.yz * u_xlat1.xx;
    u_xlat0.xy = rint(u_xlat0.xy);
    u_xlat0.xy = u_xlat0.xy / u_xlat1.xx;
    u_xlat0.xy = u_xlat1.yz * u_xlat0.xy;
    u_xlat0.xy = rint(u_xlat0.xy);
    u_xlat0.xy = u_xlat0.xy / u_xlat1.yz;
    u_xlat0.z = u_xlat18 * u_xlat0.y;
    u_xlat0.xy = u_xlat0.xz + float2(0.5, 0.5);
    u_xlatb12 = u._pixelisation<0.5;
    u_xlat0.xy = (bool(u_xlatb12)) ? in.acScreenNorm.xy : u_xlat0.xy;
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
    if(int(u._use_inner_mask) != 0) {
        u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat2 = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2 : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
