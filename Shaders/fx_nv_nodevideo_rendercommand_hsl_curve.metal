// ---------------------------------------------------------------------------
// Rendercommand Hsl Curve (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-hsl-curve.xml
// id     : nv.effect.nodevideo-rendercommand-hsl-curve
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_hsl_curveParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _hslcurve_segs;
    float _hslcurve_mode;
    float _amount;
    float _smooth_gradient;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
int u_xlati2;
bool2 u_xlatb2;
float4 u_xlat3;
bool3 u_xlatb3;
float4 u_xlat4;
int u_xlati4;
float4 u_xlat5;
bool u_xlatb5;
float u_xlat8;
bool u_xlatb8;
float u_xlat10;
int u_xlati10;
bool u_xlatb10;
float u_xlat13;
float2 u_xlat14;
float u_xlat15;
int u_xlati15;
bool u_xlatb15;
float u_xlat16;
bool u_xlatb16;
float u_xlat19;
int u_xlati19;
bool u_xlatb19;
float u_xlat20;
float u_xlat21;
int u_xlati21;
int u_xlati22;
static int int_bitfieldInsert(int base, int insert, int offset, int bits) {
    uint mask = uint(~(int(~0) << uint(bits)) << uint(offset));
    return int((uint(base) & ~mask) | ((uint(insert) << uint(offset)) & mask));
}

fragment float4 fx_nv_nodevideo_rendercommand_hsl_curve(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_hsl_curveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb1 = u_xlat0.y>=u_xlat0.z;
    u_xlat1.x = u_xlatb1 ? 1.0 : float(0.0);
    u_xlat2.xy = u_xlat0.zy;
    u_xlat2.z = float(-1.0);
    u_xlat2.w = float(0.666666687);
    u_xlat3.xy = u_xlat0.yz + (-u_xlat2.xy);
    u_xlat3.z = float(1.0);
    u_xlat3.w = float(-1.0);
    u_xlat1 = u_xlat1.xxxx * u_xlat3 + u_xlat2;
    u_xlatb2.x = u_xlat0.x>=u_xlat1.x;
    u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
    u_xlat3.xyz = u_xlat1.xyw;
    u_xlat3.w = u_xlat0.x;
    u_xlat1.xyw = u_xlat3.wyx;
    u_xlat1 = (-u_xlat3) + u_xlat1;
    u_xlat1 = u_xlat2.xxxx * u_xlat1.yxzw + u_xlat3.yxzw;
    u_xlat2.x = min(u_xlat1.x, u_xlat1.w);
    u_xlat2.x = u_xlat1.y + (-u_xlat2.x);
    u_xlat19 = (-u_xlat1.x) + u_xlat1.w;
    u_xlat8 = u_xlat2.x * 6.0 + 1.00000001e-10;
    u_xlat19 = u_xlat19 / u_xlat8;
    u_xlat13 = u_xlat19 + u_xlat1.z;
    u_xlat3.x = abs(u_xlat13);
    u_xlat13 = u_xlat1.y + 1.00000001e-10;
    u_xlat13 = u_xlat2.x / u_xlat13;
    u_xlatb19 = _hslcurve_points[0].x>=u_xlat3.x;
    if(u_xlatb19){
        u_xlati19 = int(u._hslcurve_segs << (1 & int(0x1F)));
        u_xlati19 = u_xlati19 + int(0xFFFFFFFEu);
        u_xlati2 = u_xlati19 + 1;
        u_xlat8 = (-_hslcurve_points[u_xlati19].x) + _hslcurve_points[u_xlati2].x;
        u_xlat14.x = u_xlat3.x + (-_hslcurve_points[u_xlati19].x);
        u_xlat14.x = u_xlat14.x + 1.0;
        u_xlat8 = u_xlat14.x / u_xlat8;
        u_xlat14.xy = _hslcurve_points[u_xlati2].yw;
        u_xlat2.x = _hslcurve_points[u_xlati19].y;
        u_xlat19 = _hslcurve_points[u_xlati19].w;
    } else {
        u_xlati15 = int(u._hslcurve_segs << (1 & int(0x1F)));
        u_xlati15 = u_xlati15 + int(0xFFFFFFFEu);
        u_xlatb15 = u_xlat3.x>=_hslcurve_points[u_xlati15].x;
        if(u_xlatb15){
            u_xlati15 = int(u._hslcurve_segs << (1 & int(0x1F)));
            u_xlati15 = u_xlati15 + int(0xFFFFFFFEu);
            u_xlati21 = u_xlati15 + 1;
            u_xlat4.x = (-_hslcurve_points[u_xlati15].x) + _hslcurve_points[u_xlati21].x;
            u_xlat10 = u_xlat3.x + (-_hslcurve_points[u_xlati15].x);
            u_xlat8 = u_xlat10 / u_xlat4.x;
            u_xlat14.xy = _hslcurve_points[u_xlati21].yw;
            u_xlat2.x = _hslcurve_points[u_xlati15].y;
            u_xlat19 = _hslcurve_points[u_xlati15].w;
        } else {
            u_xlati15 = u._hslcurve_segs + int(0xFFFFFFFFu);
            u_xlati21 = 0;
            u_xlat8 = 0.0;
            u_xlati4 = 0;
            while(true){
                u_xlatb10 = u_xlati4>=u_xlati15;
                if(u_xlatb10){break;}
                u_xlati10 = int(u_xlati4 << (1 & int(0x1F)));
                u_xlatb16 = u_xlat3.x>=_hslcurve_points[u_xlati10].x;
                u_xlati22 = int(int_bitfieldInsert(1, u_xlati4, 1 & int(0x1F), 31));
                u_xlatb5 = _hslcurve_points[u_xlati22].x>=u_xlat3.x;
                u_xlatb16 = u_xlatb16 && u_xlatb5;
                if(u_xlatb16){
                    u_xlat16 = u_xlat3.x + (-_hslcurve_points[u_xlati10].x);
                    u_xlat10 = (-_hslcurve_points[u_xlati10].x) + _hslcurve_points[u_xlati22].x;
                    u_xlat8 = u_xlat16 / u_xlat10;
                    u_xlati21 = u_xlati4;
                    break;
                }
                u_xlati4 = u_xlati4 + 1;
                u_xlati21 = 0;
                u_xlat8 = 0.0;
            }
            u_xlati15 = int(u_xlati21 << (1 & int(0x1F)));
            u_xlati21 = int(int_bitfieldInsert(1, u_xlati21, 1 & int(0x1F), 31));
            u_xlat14.xy = _hslcurve_points[u_xlati21].yw;
            u_xlat2.x = _hslcurve_points[u_xlati15].y;
            u_xlat19 = _hslcurve_points[u_xlati15].w;
        }
    }
    u_xlat15 = u_xlat19 + (-u_xlat2.x);
    u_xlat21 = u_xlat15 * 3.0;
    u_xlat19 = (-u_xlat19) + u_xlat14.y;
    u_xlat19 = u_xlat19 * 3.0 + (-u_xlat21);
    u_xlat14.x = (-u_xlat2.x) + u_xlat14.x;
    u_xlat14.x = (-u_xlat15) * 3.0 + u_xlat14.x;
    u_xlat14.x = (-u_xlat19) + u_xlat14.x;
    u_xlat20 = u_xlat8 * u_xlat8;
    u_xlat15 = u_xlat8 * u_xlat20;
    u_xlat19 = u_xlat19 * u_xlat20;
    u_xlat19 = u_xlat14.x * u_xlat15 + u_xlat19;
    u_xlat19 = u_xlat21 * u_xlat8 + u_xlat19;
    u_xlat19 = u_xlat2.x + u_xlat19;
    u_xlat19 = u_xlat19 + -0.300000012;
    u_xlat19 = u_xlat19 * 1.42857146 + -0.5;
    if(u._hslcurve_mode == 0) {
        u_xlatb2.x = u._smooth_gradient==1;
        u_xlat8 = u_xlat1.y * u_xlat13;
        u_xlat8 = u_xlat8 * u._amount;
        u_xlat8 = u_xlat19 * u_xlat8 + u_xlat13;
        u_xlat14.x = u_xlat19 * u._amount + u_xlat13;
        u_xlat13 = (u_xlatb2.x) ? u_xlat8 : u_xlat14.x;
        u_xlat13 = clamp(u_xlat13, 0.0, 1.0);
        u_xlat1.x = u_xlat3.x;
    } else {
        u_xlat2.x = u_xlat19 * u._amount + u_xlat3.x;
        u_xlatb8 = 1.0<u_xlat2.x;
        u_xlat14.x = u_xlat2.x + -1.0;
        u_xlat2.x = (u_xlatb8) ? u_xlat14.x : u_xlat2.x;
        u_xlatb8 = u_xlat2.x<0.0;
        u_xlat14.x = u_xlat2.x + 1.0;
        u_xlat1.x = (u_xlatb8) ? u_xlat14.x : u_xlat2.x;
        u_xlatb2.xy = equal(int4(u._hslcurve_mode, u._smooth_gradient, u._hslcurve_mode, u._hslcurve_mode), int4(1, 1, 0, 0)).xy;
        u_xlat14.x = u_xlat1.y * u_xlat13;
        u_xlat14.x = u_xlat14.x * u._amount;
        u_xlat14.x = u_xlat19 * u_xlat14.x + u_xlat1.y;
        u_xlat20 = u_xlat19 * u._amount + u_xlat1.y;
        u_xlat8 = (u_xlatb2.y) ? u_xlat14.x : u_xlat20;
        u_xlat14.x = u_xlat13 * u_xlat8;
        u_xlat19 = u_xlat19 * u_xlat14.x;
        u_xlat3.y = u_xlat19 * 4.0 + u_xlat8;
        u_xlat3.y = clamp(u_xlat3.y, 0.0, 1.0);
        u_xlat1.xy = (u_xlatb2.x) ? u_xlat1.xy : u_xlat3.xy;
    }
    u_xlat2.xyz = u_xlat1.xxx * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
    u_xlat2.xyz = u_xlat2.xyz * float3(0.166666672, 0.166666672, 0.166666672);
    u_xlatb3.xyz = greaterThanEqual(u_xlat2.xyzx, (-u_xlat2.xyzx)).xyz;
    u_xlat2.xyz = fract(abs(u_xlat2.xyz));
    {
        float4 hlslcc_movcTemp = u_xlat2;
        hlslcc_movcTemp.x = (u_xlatb3.x) ? u_xlat2.x : (-u_xlat2.x);
        hlslcc_movcTemp.y = (u_xlatb3.y) ? u_xlat2.y : (-u_xlat2.y);
        hlslcc_movcTemp.z = (u_xlatb3.z) ? u_xlat2.z : (-u_xlat2.z);
        u_xlat2 = hlslcc_movcTemp;
    }
    u_xlat2.xyz = u_xlat2.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
    u_xlat2.xyz = abs(u_xlat2.xyz) + float3(-1.0, -1.0, -1.0);
    u_xlat2.xyz = clamp(u_xlat2.xyz, 0.0, 1.0);
    u_xlat2.xyz = u_xlat2.xyz + float3(-1.0, -1.0, -1.0);
    u_xlat1.xzw = float3(u_xlat13) * u_xlat2.xyz + float3(1.0, 1.0, 1.0);
    u_xlat1.xyz = u_xlat1.xzw * u_xlat1.yyy;
    u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
    if(u._use_inner_mask != 0) {
        u_xlatb2.xy = equal(int4(u._show_inner_mask, u._b_clip_mask, u._show_inner_mask, u._show_inner_mask), int4(1, 1, 0, 0)).xy;
        u_xlat1.w = u_xlat0.w;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat5 = u_xlat0 * u_xlat5;
        u_xlat3 = u_xlat3 * u_xlat4 + u_xlat5;
        u_xlat0.x = u_xlat4.x * u_xlat3.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat0.x : u_xlat3.w;
        __nv_out.xyz = u_xlat3.xyz;
    } else {
        __nv_out.xyz = u_xlat1.xyz;
        __nv_out.w = u_xlat0.w;
    }
    return __nv_out;
    return __nv_out;
}
