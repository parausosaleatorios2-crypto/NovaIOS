// ---------------------------------------------------------------------------
// Ui Color Picker Slider Bkg (NV)
// origem : assets/effects/nv-nodevideo-ui-color-picker-slider-bkg.xml
// id     : nv.effect.nodevideo-ui-color-picker-slider-bkg
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_ui_color_picker_slider_bkgParams {
    float _type;
    float _mode;
    float _h;
    float _s;
    float _b;
};

// --- funcoes auxiliares do efeito
float3 u_xlat0;
float3 u_xlat1;
bool3 u_xlatb1;
float3 u_xlat2;
bool3 u_xlatb2;
float3 u_xlat3;
bool2 u_xlatb3;
float3 u_xlat4;

fragment float4 fx_nv_nodevideo_ui_color_picker_slider_bkg(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_ui_color_picker_slider_bkgParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if(int(u._mode) == 0) {
        u_xlat0.xyz = in.acScreenNorm.xxx * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
        u_xlat0.xyz = u_xlat0.xyz * float3(0.166666672, 0.166666672, 0.166666672);
        u_xlatb1.xyz = greaterThanEqual(u_xlat0.xyzx, (-u_xlat0.xyzx)).xyz;
        u_xlat0.xyz = fract(abs(u_xlat0.xyz));
        {
            float3 hlslcc_movcTemp = u_xlat0;
            hlslcc_movcTemp.x = (u_xlatb1.x) ? u_xlat0.x : (-u_xlat0.x);
            hlslcc_movcTemp.y = (u_xlatb1.y) ? u_xlat0.y : (-u_xlat0.y);
            hlslcc_movcTemp.z = (u_xlatb1.z) ? u_xlat0.z : (-u_xlat0.z);
            u_xlat0 = hlslcc_movcTemp;
        }
        u_xlat0.xyz = u_xlat0.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
        u_xlat0.xyz = abs(u_xlat0.xyz) + float3(-1.0, -1.0, -1.0);
        u_xlat0.xyz = clamp(u_xlat0.xyz, 0.0, 1.0);
        u_xlat1.xyz = u_xlat0.xyz * u_xlat0.xyz;
        u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xyz;
        u_xlat0.xyz = (-u_xlat0.xyz) * float3(2.0, 2.0, 2.0) + float3(3.0, 3.0, 3.0);
        u_xlat0.xyz = u_xlat1.xyz * u_xlat0.xyz + float3(-1.0, -1.0, -1.0);
        u_xlat0.xyz = float3(float3(u._s, u._s, u._s)) * u_xlat0.xyz + float3(1.0, 1.0, 1.0);
        u_xlat0.xyz = u_xlat0.xyz * float3(u._b);
        u_xlat1.x = in.acScreenNorm.x;
        u_xlat1.y = u._s;
        u_xlat1.z = u._b;
        u_xlat0.xyz = (int(u._type) != 0) ? u_xlat1.xyz : u_xlat0.xyz;
    } else {
        u_xlat1.xyz = float3(float3(u._h, u._h, u._h)) * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
        u_xlat1.xyz = u_xlat1.xyz * float3(0.166666672, 0.166666672, 0.166666672);
        u_xlatb2.xyz = greaterThanEqual(u_xlat1.xyzx, (-u_xlat1.xyzx)).xyz;
        u_xlat1.xyz = fract(abs(u_xlat1.xyz));
        {
            float3 hlslcc_movcTemp = u_xlat1;
            hlslcc_movcTemp.x = (u_xlatb2.x) ? u_xlat1.x : (-u_xlat1.x);
            hlslcc_movcTemp.y = (u_xlatb2.y) ? u_xlat1.y : (-u_xlat1.y);
            hlslcc_movcTemp.z = (u_xlatb2.z) ? u_xlat1.z : (-u_xlat1.z);
            u_xlat1 = hlslcc_movcTemp;
        }
        u_xlat1.xyz = u_xlat1.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
        u_xlat1.xyz = abs(u_xlat1.xyz) + float3(-1.0, -1.0, -1.0);
        u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
        u_xlat2.xyz = u_xlat1.xyz * u_xlat1.xyz;
        u_xlat2.xyz = u_xlat1.xyz * u_xlat2.xyz;
        u_xlat1.xyz = (-u_xlat1.xyz) * float3(2.0, 2.0, 2.0) + float3(3.0, 3.0, 3.0);
        u_xlat1.xyz = u_xlat2.xyz * u_xlat1.xyz + float3(-1.0, -1.0, -1.0);
        u_xlat2.xyz = in.acScreenNorm.xxx * u_xlat1.xyz + float3(1.0, 1.0, 1.0);
        u_xlat2.xyz = u_xlat2.xyz * float3(u._b);
        u_xlat3.x = u._h;
        u_xlat3.y = in.acScreenNorm.x;
        u_xlat3.z = u._b;
        u_xlat2.xyz = (int(u._type) != 0) ? u_xlat3.xyz : u_xlat2.xyz;
        u_xlatb3.xy = equal(int4(int4(int(u._mode), int(u._mode), int(u._mode), int(u._mode))), int4(1, 2, 0, 0)).xy;
        u_xlat1.xyz = float3(float3(u._s, u._s, u._s)) * u_xlat1.xyz + float3(1.0, 1.0, 1.0);
        u_xlat1.xyz = u_xlat1.xyz * in.acScreenNorm.xxx;
        u_xlat4.xy = float2(u._h, u._s);
        u_xlat4.z = in.acScreenNorm.x;
        u_xlat1.xyz = (int(u._type) != 0) ? u_xlat4.xyz : u_xlat1.xyz;
        u_xlat1.xyz = (u_xlatb3.y) ? u_xlat1.xyz : float3(1.0, 1.0, 1.0);
        u_xlat0.xyz = (u_xlatb3.x) ? u_xlat2.xyz : u_xlat1.xyz;
    }
    u_xlat1.xyz = u_xlat0.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    __nv_out.xyz = u_xlat0.xyz * u_xlat1.xyz;
    __nv_out.w = 1.0;
    return __nv_out;
    return __nv_out;
}
