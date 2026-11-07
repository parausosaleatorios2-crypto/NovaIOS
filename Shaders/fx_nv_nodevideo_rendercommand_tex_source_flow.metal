// ---------------------------------------------------------------------------
// Rendercommand Tex Source Flow (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-tex-source-flow.xml
// id     : nv.effect.nodevideo-rendercommand-tex-source-flow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_tex_source_flowParams {
    float4 _tex_size;
    float4 _viewport_ratio;
    float _tex_rotation;
    float _is_image_asset;
    float _strength;
    float _debug_view;
    float _start_pos;
    float _end_pos;
    float _crop_offset;
    float _ratio;
};

// --- funcoes auxiliares do efeito
float4 phase0_Input0_1;

float4 u_xlat0;
bool2 u_xlatb0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat6;
float u_xlat7;
float2 u_xlat12;
bool u_xlatb12;
float2 u_xlat13;
bool2 u_xlatb13;
float u_xlat18;
bool u_xlatb18;

fragment float4 fx_nv_nodevideo_rendercommand_tex_source_flow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_tex_source_flowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> tex_source [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    phase0_Input0_1 = float4(in.acScreenNorm, in.vs_TEXCOORD1);
    u_xlatb0.xy = equal(int4(int4(u._tex_rotation, u._tex_rotation, u._tex_rotation, u._tex_rotation)), int4(90, 270, 0, 0)).xy;
    u_xlatb12 = u_xlatb0.y || u_xlatb0.x;
    u_xlat18 = (-u._viewport_ratio.y) + u._viewport_ratio.x;
    u_xlatb18 = abs(u_xlat18)<0.00100000005;
    u_xlatb1 = u._ratio>=1.0;
    u_xlat7 = (-u._start_pos) + u._end_pos;
    u_xlat2 = phase0_Input0_1.ywxz * float4(u_xlat7) + float4(float4(u._start_pos, u._start_pos, u._start_pos, u._start_pos));
    u_xlat3 = phase0_Input0_1 + float4(float4(u._crop_offset, u._crop_offset, u._crop_offset, u._crop_offset));
    u_xlat4.xz = u_xlat3.xz;
    u_xlat4.yw = u_xlat2.xy;
    u_xlat3.xz = u_xlat2.zw;
    u_xlat1 = (bool(u_xlatb1)) ? u_xlat4 : u_xlat3;
    u_xlatb2.x = u._viewport_ratio.y<u._viewport_ratio.x;
    u_xlat5 = (bool(u_xlatb12)) ? u_xlat4 : u_xlat3;
    u_xlat4 = (bool(u_xlatb12)) ? u_xlat3 : u_xlat4;
    u_xlat3 = u_xlat5;
    u_xlat2 = (u_xlatb2.x) ? u_xlat4 : u_xlat3;
    u_xlat1 = (bool(u_xlatb18)) ? u_xlat1 : u_xlat2;
    u_xlat1 = u_xlat1 + float4(-0.5, -0.5, -0.5, -0.5);
    u_xlat2 = u_xlat1.xyxy / u._tex_size.yxxy;
    u_xlat12.xy = (bool(u_xlatb12)) ? u_xlat2.xy : u_xlat2.zw;
    u_xlat1.xy = u_xlat1.zw / u._tex_size.xy;
    u_xlat1.xy = u_xlat1.xy + float2(0.5, 0.5);
    u_xlat12.xy = u_xlat12.xy + float2(0.5, 0.5);
    u_xlatb13.xy = greaterThanEqual(u_xlat1.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb2.xy = greaterThanEqual(float4(1.0, 1.0, 0.0, 0.0), u_xlat1.xyxx).xy;
    u_xlatb13.x = u_xlatb13.x && u_xlatb2.x;
    u_xlatb13.x = u_xlatb13.y && u_xlatb13.x;
    u_xlatb13.x = u_xlatb2.y && u_xlatb13.x;
    if(u_xlatb13.x){
        u_xlat1.xy = inputImg.sample(__nv_smp, u_xlat1.xy).xy;
        u_xlat2.yz = u_xlat1.xy + float2(-0.501960814, -0.501960814);
        u_xlatb13.x = u._is_image_asset!=1;
        u_xlat2.w = (u_xlatb13.x) ? (-u_xlat2.z) : u_xlat2.z;
        u_xlatb13.x = _ProjectionParams.x<0.0;
        u_xlat3.y = (u_xlatb13.x) ? (-u_xlat2.y) : u_xlat2.y;
        u_xlat2.x = (u_xlatb13.x) ? (-u_xlat2.w) : u_xlat2.w;
        u_xlatb13.x = u._tex_rotation==180;
        u_xlat13.xy = (u_xlatb13.x) ? (-u_xlat2.yw) : u_xlat2.yw;
        u_xlat13.xy = (u_xlatb0.y) ? u_xlat2.xy : u_xlat13.xy;
        u_xlat3.x = u_xlat2.w;
        u_xlat0.xy = (u_xlatb0.x) ? u_xlat3.xy : u_xlat13.xy;
        u_xlat0.xy = u_xlat0.xy * float2(float2(u._strength, u._strength));
        u_xlat12.xy = (-u_xlat0.xy) * float2(0.5, 0.5) + u_xlat12.xy;
    } else {
        u_xlat1.x = float(0.5);
        u_xlat1.y = float(0.5);
    }
    u_xlatb0.xy = greaterThanEqual(u_xlat12.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlat0.x = u_xlatb0.x ? float(1.0) : 0.0;
    u_xlat0.y = u_xlatb0.y ? float(1.0) : 0.0;
;
    u_xlat13.xy = (-u_xlat12.xy) + float2(1.0, 1.0);
    u_xlatb13.xy = greaterThanEqual(u_xlat13.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlat13.x = u_xlatb13.x ? float(1.0) : 0.0;
    u_xlat13.y = u_xlatb13.y ? float(1.0) : 0.0;
;
    u_xlat2 = tex_source.sample(__nv_smp, u_xlat12.xy);
    u_xlat2 = u_xlat0.xxxx * u_xlat2;
    u_xlat2 = u_xlat13.xxxx * u_xlat2;
    u_xlat0 = u_xlat0.yyyy * u_xlat2;
    u_xlat2 = u_xlat13.yyyy * u_xlat0;
    u_xlatb0.x = 0<u._debug_view;
    u_xlat12.xy = u_xlat1.xy + float2(-0.501960814, -0.501960814);
    u_xlat12.x = dot(u_xlat12.xy, u_xlat12.xy);
    u_xlat12.x = sqrt(u_xlat12.x);
    u_xlat6 = u_xlat0.y * u_xlat13.y + u_xlat12.x;
    __nv_out.y = (u_xlatb0.x) ? u_xlat6 : u_xlat2.y;
    __nv_out.xzw = u_xlat2.xzw;
    return __nv_out;
    return __nv_out;
}
