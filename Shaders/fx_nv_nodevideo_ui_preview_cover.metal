// ---------------------------------------------------------------------------
// Ui Preview Cover (NV)
// origem : assets/effects/nv-nodevideo-ui-preview-cover.xml
// id     : nv.effect.nodevideo-ui-preview-cover
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_ui_preview_coverParams {
    float4 _outline_color;
    float _left;
    float _right;
    float _width;
    float _height;
    float _blur;
    float _ratio;
};

// --- funcoes auxiliares do efeito
float2 u_xlat0;
bool u_xlatb0;
float4 u_xlat1;
bool u_xlatb1;
float2 u_xlat2;
bool2 u_xlatb2;
float3 u_xlat3;
bool3 u_xlatb3;
float u_xlat4;
bool u_xlatb4;
float u_xlat6;
bool u_xlatb6;
float u_xlat7;
float u_xlat9;
bool u_xlatb9;
float u_xlat10;

fragment float4 fx_nv_nodevideo_ui_preview_cover(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_ui_preview_coverParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = u._blur * u._ratio + u._height;
    u_xlat3.x = (-u_xlat0.x) + u._height;
    u_xlat0.x = (-u_xlat0.x) + in.acScreenNorm.y;
    u_xlat3.x = float(1.0) / u_xlat3.x;
    u_xlat0.x = u_xlat3.x * u_xlat0.x;
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat3.x = u_xlat0.x * -2.0 + 3.0;
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat0.x = u_xlat0.x * u_xlat3.x;
    u_xlat3.x = (-u._height) + 1.0;
    u_xlat6 = (-u._blur) * u._ratio + u_xlat3.x;
    u_xlat9 = (-u_xlat6) + u_xlat3.x;
    u_xlat6 = (-u_xlat6) + in.acScreenNorm.y;
    u_xlatb3.x = in.acScreenNorm.y>=u_xlat3.x;
    u_xlat9 = float(1.0) / u_xlat9;
    u_xlat6 = u_xlat9 * u_xlat6;
    u_xlat6 = clamp(u_xlat6, 0.0, 1.0);
    u_xlat9 = u_xlat6 * -2.0 + 3.0;
    u_xlat6 = u_xlat6 * u_xlat6;
    u_xlat3.y = u_xlat6 * u_xlat9;
    u_xlatb3.z = 1.0>=in.acScreenNorm.y;
    u_xlat3.x = u_xlatb3.x ? float(1.0) : 0.0;
    u_xlat3.z = u_xlatb3.z ? float(1.0) : 0.0;
;
    u_xlat3.xy = u_xlat3.zz * u_xlat3.xy;
    u_xlatb9 = in.acScreenNorm.y>=0.0;
    u_xlat9 = u_xlatb9 ? 1.0 : float(0.0);
    u_xlat0.x = u_xlat9 * u_xlat0.x + u_xlat3.y;
    u_xlat6 = u._width + u._left;
    u_xlat1.x = u_xlat6 + u._blur;
    u_xlat4 = u_xlat6 + (-u_xlat1.x);
    u_xlat1.x = (-u_xlat1.x) + in.acScreenNorm.x;
    u_xlatb6 = u_xlat6>=in.acScreenNorm.x;
    u_xlat6 = u_xlatb6 ? 1.0 : float(0.0);
    u_xlat4 = float(1.0) / u_xlat4;
    u_xlat1.x = u_xlat4 * u_xlat1.x;
    u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
    u_xlat4 = u_xlat1.x * -2.0 + 3.0;
    u_xlat1.x = u_xlat1.x * u_xlat1.x;
    u_xlat1.x = u_xlat1.x * u_xlat4;
    u_xlatb4 = in.acScreenNorm.x>=u._left;
    u_xlat4 = u_xlatb4 ? 1.0 : float(0.0);
    u_xlat1.x = u_xlat1.x * u_xlat4;
    u_xlat0.x = max(u_xlat0.x, u_xlat1.x);
    u_xlat1.x = (-u._width) + u._right;
    u_xlat7 = u_xlat1.x + (-u._blur);
    u_xlat10 = (-u_xlat7) + u_xlat1.x;
    u_xlat7 = (-u_xlat7) + in.acScreenNorm.x;
    u_xlatb1 = in.acScreenNorm.x>=u_xlat1.x;
    u_xlat1.x = u_xlatb1 ? 1.0 : float(0.0);
    u_xlat10 = float(1.0) / u_xlat10;
    u_xlat7 = u_xlat10 * u_xlat7;
    u_xlat7 = clamp(u_xlat7, 0.0, 1.0);
    u_xlat10 = u_xlat7 * -2.0 + 3.0;
    u_xlat7 = u_xlat7 * u_xlat7;
    u_xlat7 = u_xlat7 * u_xlat10;
    u_xlatb2.xy = greaterThanEqual(float4(u._right, u._height, u._right, u._right), in.acScreenNorm.xyxx).xy;
    u_xlat2.x = u_xlatb2.x ? float(1.0) : 0.0;
    u_xlat2.y = u_xlatb2.y ? float(1.0) : 0.0;
;
    u_xlat7 = u_xlat7 * u_xlat2.x;
    u_xlat0.x = max(u_xlat0.x, u_xlat7);
    u_xlat6 = u_xlat6 * u_xlat4;
    u_xlat3.x = u_xlat9 * u_xlat2.y + u_xlat3.x;
    u_xlat3.x = u_xlat4 * u_xlat3.x;
    u_xlat3.x = u_xlat3.x * u_xlat2.x + u_xlat6;
    u_xlat3.x = u_xlat1.x * u_xlat2.x + u_xlat3.x;
    u_xlat0.xy = u_xlat0.xx * float2(0.0, 0.899999976) + u_xlat3.xx;
    u_xlat0.xy = min(u_xlat0.xy, float2(1.0, 1.0));
    u_xlat1.xyz = u._outline_color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u._outline_color.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat1.xyz = u_xlat1.xyz * u._outline_color.xyz;
    u_xlat1.xyz = u_xlat0.xxx * u_xlat1.xyz;
    u_xlat1.w = u_xlat0.y * u._outline_color.w;
    u_xlatb0 = in.acScreenNorm.x<u._left;
    u_xlatb3.x = u._right<in.acScreenNorm.x;
    u_xlatb0 = u_xlatb3.x || u_xlatb0;
    __nv_out = (bool(u_xlatb0)) ? float4(0.0, 0.0, 0.0, 0.800000012) : u_xlat1;
    return __nv_out;
    return __nv_out;
}
