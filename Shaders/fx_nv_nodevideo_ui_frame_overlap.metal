// ---------------------------------------------------------------------------
// Ui Frame Overlap (NV)
// origem : assets/effects/nv-nodevideo-ui-frame-overlap.xml
// id     : nv.effect.nodevideo-ui-frame-overlap
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_ui_frame_overlapParams {
    float _x_scale;
    float _y_scale;
    float4 _outline_color;
    float _outline_size;
    float _blur;
    float _style;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
bool u_xlatb0;
float4 u_xlat1;
float4 u_xlat2;
bool u_xlatb2;
float u_xlat3;
bool u_xlatb3;
float u_xlat4;
float2 u_xlat6;
float2 u_xlat7;
float u_xlat9;

fragment float4 fx_nv_nodevideo_ui_frame_overlap(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_ui_frame_overlapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = min(u._y_scale, u._x_scale);
    u_xlat3 = u_xlat0.x * 0.5 + (-u._outline_size);
    u_xlat3 = min(u_xlat3, u._blur);
    u_xlat0.y = max(u_xlat3, 0.0);
    u_xlat0.x = u_xlat0.x * 0.5 + (-u_xlat0.y);
    u_xlat0.x = u_xlat0.x + (-u._outline_size);
    u_xlat0.x = min(u_xlat0.x, u_xlat0.y);
    u_xlat0.x = max(u_xlat0.x, 0.0);
    u_xlat6.x = u_xlat0.y + u._outline_size;
    u_xlat1.xy = in.acScreenNorm.xy * float2(u._x_scale, u._y_scale);
    u_xlat7.xy = float2(u._x_scale, u._y_scale) * float2(0.5, 0.5);
    u_xlat9 = min(u_xlat7.x, 0.0);
    u_xlat9 = min(u_xlat7.y, u_xlat9);
    u_xlat7.x = in.acScreenNorm.y * u._y_scale + u_xlat7.y;
    u_xlat2.xy = float2(u._x_scale, u._y_scale) * float2(0.5, 0.5) + (-float2(u_xlat9));
    u_xlat1.xy = abs(u_xlat1.xy) + (-u_xlat2.xy);
    u_xlat2.xy = max(u_xlat1.xy, float2(0.0, 0.0));
    u_xlat1.x = max(u_xlat1.y, u_xlat1.x);
    u_xlat1.x = min(u_xlat1.x, 0.0);
    u_xlat4 = dot(u_xlat2.xy, u_xlat2.xy);
    u_xlat4 = sqrt(u_xlat4);
    u_xlat1.x = u_xlat4 + u_xlat1.x;
    u_xlat6.y = u_xlat9 + (-u_xlat1.x);
    u_xlat6.x = (-u_xlat6.x) + u_xlat6.y;
    u_xlat0.xy = u_xlat6.xy / u_xlat0.xy;
    u_xlat0.xy = clamp(u_xlat0.xy, 0.0, 1.0);
    u_xlat2 = u_xlat0.xxxx * (-u._outline_color) + u._outline_color;
    u_xlat2.w = u_xlat0.y * u_xlat2.w;
    u_xlat0.x = (-u._outline_size) * 3.0 + u._y_scale;
    u_xlatb0 = u_xlat7.x<u_xlat0.x;
    u_xlatb3 = u._outline_size==0.0;
    u_xlatb0 = u_xlatb0 || u_xlatb3;
    u_xlat1 = (bool(u_xlatb3)) ? float4(0.0, 0.0, 0.0, 0.0) : u_xlat2;
    u_xlat0 = (bool(u_xlatb0)) ? float4(0.0, 0.0, 0.0, 0.0) : u_xlat2;
    u_xlatb2 = int(u._style)==1;
    __nv_out = (bool(u_xlatb2)) ? u_xlat0 : u_xlat1;
    return __nv_out;
    return __nv_out;
}
