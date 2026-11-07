// ---------------------------------------------------------------------------
// Ui Color Mask Range Bkg (NV)
// origem : assets/effects/nv-nodevideo-ui-color-mask-range-bkg.xml
// id     : nv.effect.nodevideo-ui-color-mask-range-bkg
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_ui_color_mask_range_bkgParams {
    float4 _CenterColor;
    float4 _FeatherColor;
    float _center;
    float _radius;
    float _feather;
    float _loop;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
int3 u_xlati0;
bool3 u_xlatb0;
float3 u_xlat1;
bool3 u_xlatb1;
float4 u_xlat2;
bool4 u_xlatb2;
int2 u_xlati3;
bool2 u_xlatb3;
int3 u_xlati4;
bool3 u_xlatb4;
float u_xlat5;
float u_xlat6;
bool u_xlatb6;
float2 u_xlat9;
bool u_xlatb9;
float2 u_xlat10;
bool2 u_xlatb11;
bool u_xlatb13;

fragment float4 fx_nv_nodevideo_ui_color_mask_range_bkg(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_ui_color_mask_range_bkgParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = in.acScreenNorm.x + (-u._center);
    u_xlatb0.x = abs(u_xlat0.x)<0.00499999989;
    if(u_xlatb0.x){
        __nv_out = float4(1.0, 1.0, 1.0, 1.0);
        return __nv_out;
    }
    u_xlat0.x = (-u._radius) + u._center;
    u_xlat0.y = u_xlat0.x + (-u._feather);
    u_xlat0.z = u._radius + u._center;
    u_xlat0.w = u_xlat0.z + u._feather;
    u_xlat1.xz = (-u_xlat0.yz) + in.acScreenNorm.xx;
    u_xlat5 = (-u_xlat0.y) + u_xlat0.x;
    u_xlat1.x = u_xlat1.x / u_xlat5;
    u_xlat9.x = u_xlat1.z / u._feather;
    u_xlat1.z = (-u_xlat9.x) + 1.0;
    u_xlatb13 = u_xlat0.y<in.acScreenNorm.x;
    u_xlatb2.xyz = lessThan(in.acScreenNorm.xxxx, u_xlat0.xwzx).xyz;
    u_xlatb13 = u_xlatb13 && u_xlatb2.x;
    u_xlatb1.xz = greaterThanEqual(u_xlat1.xxzx, in.acScreenNorm.yyyy).xz;
    u_xlatb2.x = u_xlat0.z<in.acScreenNorm.x;
    u_xlatb2.x = u_xlatb2.y && u_xlatb2.x;
    u_xlat1.x = u_xlatb1.x ? float(1.0) : 0.0;
    u_xlat1.z = u_xlatb1.z ? float(1.0) : 0.0;
;
    u_xlat1.xz = u_xlat1.xz * u._FeatherColor.xx;
    u_xlatb6 = u_xlat0.x<in.acScreenNorm.x;
    u_xlatb6 = u_xlatb2.z && u_xlatb6;
    u_xlat6 = u_xlatb6 ? u._CenterColor.x : float(0.0);
    u_xlat9.x = (u_xlatb2.x) ? u_xlat1.z : u_xlat6;
    u_xlat1.x = (u_xlatb13) ? u_xlat1.x : u_xlat9.x;
    u_xlatb9 = int(u._loop)==1;
    if(u_xlatb9){
        u_xlat9.xy = in.acScreenNorm.xx + float2(-1.0, 1.0);
        u_xlat2 = (-u_xlat0.yyzz) + u_xlat9.xyxy;
        u_xlat2.xy = u_xlat2.xy / float2(u_xlat5);
        u_xlat10.xy = u_xlat2.zw / float2(float2(u._feather, u._feather));
        u_xlat2.zw = (-u_xlat10.xy) + float2(1.0, 1.0);
        u_xlatb3.xy = lessThan(u_xlat0.yyyy, u_xlat9.xyxx).xy;
        u_xlatb11.xy = lessThan(u_xlat9.xyxy, u_xlat0.xxxx).xy;
        u_xlati3.xy = int2(uint2((uint(u_xlatb11.x) * 0xffffffffu) & (uint(u_xlatb3.x) * 0xffffffffu), (uint(u_xlatb11.y) * 0xffffffffu) & (uint(u_xlatb3.y) * 0xffffffffu)));
        u_xlatb2 = greaterThanEqual(u_xlat2, in.acScreenNorm.yyyy);
        u_xlatb11.xy = lessThan(u_xlat0.zzzz, u_xlat9.xyxy).xy;
        u_xlatb4.xz = lessThan(u_xlat9.xxyy, u_xlat0.wwww).xz;
        u_xlati4.xz = int2(uint2((uint(u_xlatb4.x) * 0xffffffffu) & (uint(u_xlatb11.x) * 0xffffffffu), (uint(u_xlatb4.z) * 0xffffffffu) & (uint(u_xlatb11.y) * 0xffffffffu)));
        u_xlat2.x = u_xlatb2.x ? float(1.0) : 0.0;
        u_xlat2.y = u_xlatb2.y ? float(1.0) : 0.0;
        u_xlat2.z = u_xlatb2.z ? float(1.0) : 0.0;
        u_xlat2.w = u_xlatb2.w ? float(1.0) : 0.0;
;
        u_xlat2 = u_xlat2 * u._FeatherColor.xxxx;
        u_xlatb11.xy = lessThan(u_xlat0.xxxx, u_xlat9.xyxy).xy;
        u_xlatb0.xz = lessThan(u_xlat9.xxyx, u_xlat0.zzzz).xz;
        u_xlati0.xz = int2(uint2((uint(u_xlatb0.x) * 0xffffffffu) & (uint(u_xlatb11.x) * 0xffffffffu), (uint(u_xlatb0.z) * 0xffffffffu) & (uint(u_xlatb11.y) * 0xffffffffu)));
        u_xlat0.xz = as_type<float>(uint2(uint(u_xlati0.x) & uint(as_type<uint>(u._CenterColor.x)), uint(u_xlati0.z) & uint(as_type<uint>(u._CenterColor.x))));
        {
            float4 hlslcc_movcTemp = u_xlat0;
            hlslcc_movcTemp.x = (u_xlati4.x != 0) ? u_xlat2.z : u_xlat0.x;
            hlslcc_movcTemp.y = (u_xlati4.z != 0) ? u_xlat2.w : u_xlat0.z;
            u_xlat0 = hlslcc_movcTemp;
        }
        {
            float4 hlslcc_movcTemp = u_xlat0;
            hlslcc_movcTemp.x = (u_xlati3.x != 0) ? u_xlat2.x : u_xlat0.x;
            hlslcc_movcTemp.y = (u_xlati3.y != 0) ? u_xlat2.y : u_xlat0.y;
            u_xlat0 = hlslcc_movcTemp;
        }
    } else {
        u_xlat0.x = float(0.0);
        u_xlat0.y = float(0.0);
    }
    u_xlat0.x = u_xlat0.x + u_xlat1.x;
    __nv_out = u_xlat0.yyyy + u_xlat0.xxxx;
    return __nv_out;
    return __nv_out;
}
