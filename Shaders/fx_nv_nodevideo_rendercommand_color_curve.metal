// ---------------------------------------------------------------------------
// Rendercommand Color Curve (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-color-curve.xml
// id     : nv.effect.nodevideo-rendercommand-color-curve
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_color_curveParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _colorcurve_segs;
    float _colorcurve_segs_r;
    float _colorcurve_segs_g;
    float _colorcurve_segs_b;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
int u_xlati4;
bool u_xlatb4;
float4 u_xlat5;
int u_xlati5;
bool u_xlatb5;
float4 u_xlat6;
bool u_xlatb6;
float4 u_xlat7;
float3 u_xlat9;
bool u_xlatb9;
float3 u_xlat10;
float2 u_xlat11;
int u_xlati11;
bool u_xlatb11;
float u_xlat12;
int u_xlati12;
bool u_xlatb12;
float2 u_xlat13;
bool u_xlatb13;
float2 u_xlat14;
float2 u_xlat17;
bool u_xlatb17;
float2 u_xlat18;
bool u_xlatb18;
float2 u_xlat19;
int u_xlati19;
bool u_xlatb19;
float2 u_xlat20;
int u_xlati20;
bool u_xlatb20;
float u_xlat21;
bool u_xlatb21;
float u_xlat25;
bool u_xlatb25;
float u_xlat26;
int u_xlati26;
bool u_xlatb26;
int u_xlati27;
bool u_xlatb27;
float u_xlat28;
int u_xlati28;
bool u_xlatb28;
bool u_xlatb29;
static int int_bitfieldInsert(int base, int insert, int offset, int bits) {
    uint mask = uint(~(int(~0) << uint(bits)) << uint(offset));
    return int((uint(base) & ~mask) | ((uint(insert) << uint(offset)) & mask));
}

fragment float4 fx_nv_nodevideo_rendercommand_color_curve(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_color_curveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = float(0.0);
    u_xlat1.y = float(0.0);
    u_xlat1.z = float(0.0);
    u_xlat1.w = float(0.0);
    u_xlat2.x = float(0.0);
    u_xlat2.y = float(0.0);
    u_xlat2.z = float(0.0);
    u_xlat2.w = float(0.0);
    u_xlat3.x = float(0.0);
    u_xlati11 = int(0);
    while(true){
        u_xlatb19 = u_xlati11>=u._colorcurve_segs_r;
        if(u_xlatb19){break;}
        u_xlati19 = int(u_xlati11 << (1 & int(0x1F)));
        u_xlati27 = int(int_bitfieldInsert(1, u_xlati11, 1 & int(0x1F), 31));
        u_xlatb4 = u_xlat0.x>=_colorcurve_points_r[u_xlati19].z;
        u_xlatb12 = _colorcurve_points_r[u_xlati27].x>=u_xlat0.x;
        u_xlatb4 = u_xlatb12 && u_xlatb4;
        if(u_xlatb4){
            u_xlat4.x = u_xlat0.x + (-_colorcurve_points_r[u_xlati19].z);
            u_xlat12 = (-_colorcurve_points_r[u_xlati19].z) + _colorcurve_points_r[u_xlati27].x;
            u_xlat3.x = u_xlat4.x / u_xlat12;
            u_xlat1 = _colorcurve_points_r[u_xlati19].yxzw;
            u_xlat2 = _colorcurve_points_r[u_xlati27].yxwz;
            break;
        }
        u_xlati11 = u_xlati11 + 1;
        u_xlat1 = _colorcurve_points_r[u_xlati19].yxzw;
        u_xlat2 = _colorcurve_points_r[u_xlati27].yxwz;
        u_xlat3.x = 0.0;
    }
    u_xlat4 = u_xlat1.zwzw;
    u_xlat17.xy = (-u_xlat4.xy) + u_xlat2.yx;
    u_xlat11.xy = u_xlat1.yx + (-u_xlat4.zw);
    u_xlat11.x = dot(u_xlat11.xy, u_xlat11.xy);
    u_xlat19.xy = (-u_xlat2.wz) + u_xlat2.yx;
    u_xlat11.y = dot(u_xlat19.xy, u_xlat19.xy);
    u_xlat11.xy = sqrt(u_xlat11.xy);
    u_xlatb27 = u_xlat11.x<9.99999975e-06;
    u_xlatb20 = u_xlat11.y<9.99999975e-06;
    u_xlatb5 = u_xlatb27 && u_xlatb20;
    u_xlat13.xy = u_xlat17.yy * float2(0.333333343, 0.666666687) + u_xlat4.ww;
    u_xlatb25 = 9.99999975e-06<u_xlat11.y;
    u_xlatb25 = u_xlatb25 && u_xlatb27;
    u_xlat18.xy = (-u_xlat4.yx) + u_xlat2.zw;
    u_xlat18.x = u_xlat18.x / u_xlat18.y;
    u_xlat18.x = u_xlat17.x * u_xlat18.x;
    u_xlat6.w = (-u_xlat18.x) * 0.333333343 + u_xlat2.x;
    u_xlat18.x = (-u_xlat4.y) + u_xlat6.w;
    u_xlat6.x = u_xlat18.x * 0.5 + u_xlat4.w;
    u_xlatb18 = 9.99999975e-06<u_xlat11.x;
    u_xlatb18 = u_xlatb20 && u_xlatb18;
    u_xlat1.xy = (-u_xlat1.xy) + u_xlat2.xy;
    u_xlat1.x = u_xlat1.x / u_xlat1.y;
    u_xlat1.x = u_xlat17.x * u_xlat1.x;
    u_xlat6.y = u_xlat1.x * 0.333333343 + u_xlat4.w;
    u_xlat1.x = (-u_xlat2.x) + u_xlat6.y;
    u_xlat6.z = u_xlat1.x * 0.5 + u_xlat2.x;
    u_xlat1.xy = (bool(u_xlatb18)) ? u_xlat6.yz : u_xlat6.yw;
    u_xlat1.xy = (bool(u_xlatb25)) ? u_xlat6.xw : u_xlat1.xy;
    u_xlat1.xy = (bool(u_xlatb5)) ? u_xlat13.xy : u_xlat1.xy;
    u_xlat1.z = (-u_xlat3.x) + 1.0;
    u_xlat9.xz = u_xlat1.yz * u_xlat1.zz;
    u_xlat10.x = u_xlat4.w * u_xlat9.z;
    u_xlat1.x = u_xlat1.x * u_xlat9.z;
    u_xlat1.x = u_xlat3.x * u_xlat1.x;
    u_xlat1.x = u_xlat1.x * 3.0;
    u_xlat1.x = u_xlat10.x * u_xlat1.z + u_xlat1.x;
    u_xlat17.x = u_xlat3.x * u_xlat3.x;
    u_xlat9.x = u_xlat9.x * u_xlat17.x;
    u_xlat1.x = u_xlat9.x * 3.0 + u_xlat1.x;
    u_xlat9.x = u_xlat2.x * u_xlat17.x;
    u_xlat1.x = u_xlat9.x * u_xlat3.x + u_xlat1.x;
    u_xlat2.x = float(0.0);
    u_xlat2.y = float(0.0);
    u_xlat2.z = float(0.0);
    u_xlat2.w = float(0.0);
    u_xlat3.x = float(0.0);
    u_xlat3.y = float(0.0);
    u_xlat3.z = float(0.0);
    u_xlat3.w = float(0.0);
    u_xlat25 = 0.0;
    u_xlati4 = 0;
    while(true){
        u_xlatb12 = u_xlati4>=u._colorcurve_segs_g;
        if(u_xlatb12){break;}
        u_xlati12 = int(u_xlati4 << (1 & int(0x1F)));
        u_xlati20 = int(int_bitfieldInsert(1, u_xlati4, 1 & int(0x1F), 31));
        u_xlatb28 = u_xlat0.y>=_colorcurve_points_g[u_xlati12].z;
        u_xlatb5 = _colorcurve_points_g[u_xlati20].x>=u_xlat0.y;
        u_xlatb28 = u_xlatb28 && u_xlatb5;
        if(u_xlatb28){
            u_xlat28 = u_xlat0.y + (-_colorcurve_points_g[u_xlati12].z);
            u_xlat5.x = (-_colorcurve_points_g[u_xlati12].z) + _colorcurve_points_g[u_xlati20].x;
            u_xlat25 = u_xlat28 / u_xlat5.x;
            u_xlat2 = _colorcurve_points_g[u_xlati12].yxzw;
            u_xlat3 = _colorcurve_points_g[u_xlati20].yxwz;
            break;
        }
        u_xlati4 = u_xlati4 + 1;
        u_xlat2 = _colorcurve_points_g[u_xlati12].yxzw;
        u_xlat3 = _colorcurve_points_g[u_xlati20].yxwz;
        u_xlat25 = 0.0;
    }
    u_xlat4 = u_xlat2.zwzw;
    u_xlat18.xy = (-u_xlat4.xy) + u_xlat3.yx;
    u_xlat5.xy = u_xlat2.yx + (-u_xlat4.zw);
    u_xlat20.x = dot(u_xlat5.xy, u_xlat5.xy);
    u_xlat20.x = sqrt(u_xlat20.x);
    u_xlat5.xy = (-u_xlat3.wz) + u_xlat3.yx;
    u_xlat5.x = dot(u_xlat5.xy, u_xlat5.xy);
    u_xlat5.x = sqrt(u_xlat5.x);
    u_xlatb13 = u_xlat20.x<9.99999975e-06;
    u_xlatb21 = u_xlat5.x<9.99999975e-06;
    u_xlatb29 = u_xlatb21 && u_xlatb13;
    u_xlat6.xy = u_xlat18.yy * float2(0.333333343, 0.666666687) + u_xlat4.ww;
    u_xlatb26 = 9.99999975e-06<u_xlat5.x;
    u_xlatb26 = u_xlatb26 && u_xlatb13;
    u_xlat19.xy = (-u_xlat4.yx) + u_xlat3.zw;
    u_xlat19.x = u_xlat19.x / u_xlat19.y;
    u_xlat19.x = u_xlat18.x * u_xlat19.x;
    u_xlat7.w = (-u_xlat19.x) * 0.333333343 + u_xlat3.x;
    u_xlat19.x = (-u_xlat4.y) + u_xlat7.w;
    u_xlat7.x = u_xlat19.x * 0.5 + u_xlat4.w;
    u_xlatb19 = 9.99999975e-06<u_xlat20.x;
    u_xlatb19 = u_xlatb21 && u_xlatb19;
    u_xlat2.xy = (-u_xlat2.xy) + u_xlat3.xy;
    u_xlat2.x = u_xlat2.x / u_xlat2.y;
    u_xlat2.x = u_xlat18.x * u_xlat2.x;
    u_xlat7.y = u_xlat2.x * 0.333333343 + u_xlat4.w;
    u_xlat2.x = (-u_xlat3.x) + u_xlat7.y;
    u_xlat7.z = u_xlat2.x * 0.5 + u_xlat3.x;
    u_xlat2.xy = (bool(u_xlatb19)) ? u_xlat7.yz : u_xlat7.yw;
    u_xlat2.xy = (bool(u_xlatb26)) ? u_xlat7.xw : u_xlat2.xy;
    u_xlat2.xy = (bool(u_xlatb29)) ? u_xlat6.xy : u_xlat2.xy;
    u_xlat2.z = (-u_xlat25) + 1.0;
    u_xlat10.xz = u_xlat2.yz * u_xlat2.zz;
    u_xlat11.x = u_xlat4.w * u_xlat10.z;
    u_xlat2.x = u_xlat2.x * u_xlat10.z;
    u_xlat2.x = u_xlat25 * u_xlat2.x;
    u_xlat2.x = u_xlat2.x * 3.0;
    u_xlat2.x = u_xlat11.x * u_xlat2.z + u_xlat2.x;
    u_xlat18.x = u_xlat25 * u_xlat25;
    u_xlat10.x = u_xlat10.x * u_xlat18.x;
    u_xlat2.x = u_xlat10.x * 3.0 + u_xlat2.x;
    u_xlat10.x = u_xlat3.x * u_xlat18.x;
    u_xlat1.y = u_xlat10.x * u_xlat25 + u_xlat2.x;
    u_xlat2.x = float(0.0);
    u_xlat2.y = float(0.0);
    u_xlat2.z = float(0.0);
    u_xlat2.w = float(0.0);
    u_xlat3.x = float(0.0);
    u_xlat3.y = float(0.0);
    u_xlat3.z = float(0.0);
    u_xlat3.w = float(0.0);
    u_xlat25 = 0.0;
    u_xlati4 = 0;
    while(true){
        u_xlatb12 = u_xlati4>=u._colorcurve_segs_b;
        if(u_xlatb12){break;}
        u_xlati12 = int(u_xlati4 << (1 & int(0x1F)));
        u_xlati20 = int(int_bitfieldInsert(1, u_xlati4, 1 & int(0x1F), 31));
        u_xlatb28 = u_xlat0.z>=_colorcurve_points_b[u_xlati12].z;
        u_xlatb5 = _colorcurve_points_b[u_xlati20].x>=u_xlat0.z;
        u_xlatb28 = u_xlatb28 && u_xlatb5;
        if(u_xlatb28){
            u_xlat28 = u_xlat0.z + (-_colorcurve_points_b[u_xlati12].z);
            u_xlat5.x = (-_colorcurve_points_b[u_xlati12].z) + _colorcurve_points_b[u_xlati20].x;
            u_xlat25 = u_xlat28 / u_xlat5.x;
            u_xlat2 = _colorcurve_points_b[u_xlati12].yxzw;
            u_xlat3 = _colorcurve_points_b[u_xlati20].yxwz;
            break;
        }
        u_xlati4 = u_xlati4 + 1;
        u_xlat2 = _colorcurve_points_b[u_xlati12].yxzw;
        u_xlat3 = _colorcurve_points_b[u_xlati20].yxwz;
        u_xlat25 = 0.0;
    }
    u_xlat4 = u_xlat2.zwzw;
    u_xlat18.xy = (-u_xlat4.xy) + u_xlat3.yx;
    u_xlat5.xy = u_xlat2.yx + (-u_xlat4.zw);
    u_xlat20.x = dot(u_xlat5.xy, u_xlat5.xy);
    u_xlat20.x = sqrt(u_xlat20.x);
    u_xlat5.xy = (-u_xlat3.wz) + u_xlat3.yx;
    u_xlat5.x = dot(u_xlat5.xy, u_xlat5.xy);
    u_xlat5.x = sqrt(u_xlat5.x);
    u_xlatb13 = u_xlat20.x<9.99999975e-06;
    u_xlatb21 = u_xlat5.x<9.99999975e-06;
    u_xlatb29 = u_xlatb21 && u_xlatb13;
    u_xlat6.xy = u_xlat18.yy * float2(0.333333343, 0.666666687) + u_xlat4.ww;
    u_xlatb26 = 9.99999975e-06<u_xlat5.x;
    u_xlatb26 = u_xlatb26 && u_xlatb13;
    u_xlat19.xy = (-u_xlat4.yx) + u_xlat3.zw;
    u_xlat19.x = u_xlat19.x / u_xlat19.y;
    u_xlat19.x = u_xlat18.x * u_xlat19.x;
    u_xlat7.w = (-u_xlat19.x) * 0.333333343 + u_xlat3.x;
    u_xlat19.x = (-u_xlat4.y) + u_xlat7.w;
    u_xlat7.x = u_xlat19.x * 0.5 + u_xlat4.w;
    u_xlatb19 = 9.99999975e-06<u_xlat20.x;
    u_xlatb19 = u_xlatb21 && u_xlatb19;
    u_xlat2.xy = (-u_xlat2.xy) + u_xlat3.xy;
    u_xlat2.x = u_xlat2.x / u_xlat2.y;
    u_xlat2.x = u_xlat18.x * u_xlat2.x;
    u_xlat7.y = u_xlat2.x * 0.333333343 + u_xlat4.w;
    u_xlat2.x = (-u_xlat3.x) + u_xlat7.y;
    u_xlat7.z = u_xlat2.x * 0.5 + u_xlat3.x;
    u_xlat2.xy = (bool(u_xlatb19)) ? u_xlat7.yz : u_xlat7.yw;
    u_xlat2.xy = (bool(u_xlatb26)) ? u_xlat7.xw : u_xlat2.xy;
    u_xlat2.xy = (bool(u_xlatb29)) ? u_xlat6.xy : u_xlat2.xy;
    u_xlat2.z = (-u_xlat25) + 1.0;
    u_xlat10.xz = u_xlat2.yz * u_xlat2.zz;
    u_xlat11.x = u_xlat4.w * u_xlat10.z;
    u_xlat2.x = u_xlat2.x * u_xlat10.z;
    u_xlat2.x = u_xlat25 * u_xlat2.x;
    u_xlat2.x = u_xlat2.x * 3.0;
    u_xlat2.x = u_xlat11.x * u_xlat2.z + u_xlat2.x;
    u_xlat18.x = u_xlat25 * u_xlat25;
    u_xlat10.x = u_xlat10.x * u_xlat18.x;
    u_xlat2.x = u_xlat10.x * 3.0 + u_xlat2.x;
    u_xlat10.x = u_xlat3.x * u_xlat18.x;
    u_xlat1.z = u_xlat10.x * u_xlat25 + u_xlat2.x;
    u_xlat1.xyz = max(u_xlat1.xyz, float3(0.0, 0.0, 0.0));
    u_xlat1.xyz = log2(u_xlat1.xyz);
    u_xlat1.xyz = u_xlat1.xyz * float3(0.416666657, 0.416666657, 0.416666657);
    u_xlat1.xyz = exp2(u_xlat1.xyz);
    u_xlat1.xyz = u_xlat1.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
    u_xlat1.xyz = max(u_xlat1.xyz, float3(0.0, 0.0, 0.0));
    u_xlat2.x = float(0.0);
    u_xlat2.y = float(0.0);
    u_xlat2.z = float(0.0);
    u_xlat2.w = float(0.0);
    u_xlat3.x = float(0.0);
    u_xlat3.y = float(0.0);
    u_xlat3.z = float(0.0);
    u_xlat3.w = float(0.0);
    u_xlat25 = 0.0;
    u_xlati4 = 0;
    while(true){
        u_xlatb12 = u_xlati4>=u._colorcurve_segs;
        if(u_xlatb12){break;}
        u_xlati12 = int(u_xlati4 << (1 & int(0x1F)));
        u_xlati20 = int(int_bitfieldInsert(1, u_xlati4, 1 & int(0x1F), 31));
        u_xlatb28 = u_xlat1.x>=_colorcurve_points[u_xlati12].z;
        u_xlatb5 = _colorcurve_points[u_xlati20].x>=u_xlat1.x;
        u_xlatb28 = u_xlatb28 && u_xlatb5;
        if(u_xlatb28){
            u_xlat28 = u_xlat1.x + (-_colorcurve_points[u_xlati12].z);
            u_xlat5.x = (-_colorcurve_points[u_xlati12].z) + _colorcurve_points[u_xlati20].x;
            u_xlat25 = u_xlat28 / u_xlat5.x;
            u_xlat2 = _colorcurve_points[u_xlati12].yxzw;
            u_xlat3 = _colorcurve_points[u_xlati20].yxwz;
            break;
        }
        u_xlati4 = u_xlati4 + 1;
        u_xlat2 = _colorcurve_points[u_xlati12].yxzw;
        u_xlat3 = _colorcurve_points[u_xlati20].yxwz;
        u_xlat25 = 0.0;
    }
    u_xlat4 = u_xlat2.zwzw;
    u_xlat18.xy = (-u_xlat4.xy) + u_xlat3.yx;
    u_xlat5.xy = u_xlat2.yx + (-u_xlat4.zw);
    u_xlat1.x = dot(u_xlat5.xy, u_xlat5.xy);
    u_xlat1.x = sqrt(u_xlat1.x);
    u_xlat5.xy = (-u_xlat3.wz) + u_xlat3.yx;
    u_xlat20.x = dot(u_xlat5.xy, u_xlat5.xy);
    u_xlat20.x = sqrt(u_xlat20.x);
    u_xlatb5 = u_xlat1.x<9.99999975e-06;
    u_xlatb13 = u_xlat20.x<9.99999975e-06;
    u_xlatb21 = u_xlatb13 && u_xlatb5;
    u_xlat6.xy = u_xlat18.yy * float2(0.333333343, 0.666666687) + u_xlat4.ww;
    u_xlatb26 = 9.99999975e-06<u_xlat20.x;
    u_xlatb26 = u_xlatb26 && u_xlatb5;
    u_xlat19.xy = (-u_xlat4.yx) + u_xlat3.zw;
    u_xlat19.x = u_xlat19.x / u_xlat19.y;
    u_xlat19.x = u_xlat18.x * u_xlat19.x;
    u_xlat7.w = (-u_xlat19.x) * 0.333333343 + u_xlat3.x;
    u_xlat19.x = (-u_xlat4.y) + u_xlat7.w;
    u_xlat7.x = u_xlat19.x * 0.5 + u_xlat4.w;
    u_xlatb1 = 9.99999975e-06<u_xlat1.x;
    u_xlatb1 = u_xlatb13 && u_xlatb1;
    u_xlat2.xy = (-u_xlat2.xy) + u_xlat3.xy;
    u_xlat2.x = u_xlat2.x / u_xlat2.y;
    u_xlat2.x = u_xlat18.x * u_xlat2.x;
    u_xlat7.y = u_xlat2.x * 0.333333343 + u_xlat4.w;
    u_xlat2.x = (-u_xlat3.x) + u_xlat7.y;
    u_xlat7.z = u_xlat2.x * 0.5 + u_xlat3.x;
    u_xlat2.xy = (bool(u_xlatb1)) ? u_xlat7.yz : u_xlat7.yw;
    u_xlat2.xy = (bool(u_xlatb26)) ? u_xlat7.xw : u_xlat2.xy;
    u_xlat2.xy = (bool(u_xlatb21)) ? u_xlat6.xy : u_xlat2.xy;
    u_xlat1.x = (-u_xlat25) + 1.0;
    u_xlat18.x = u_xlat1.x * u_xlat1.x;
    u_xlat26 = u_xlat4.w * u_xlat18.x;
    u_xlat2.x = u_xlat2.x * u_xlat18.x;
    u_xlat2.x = u_xlat25 * u_xlat2.x;
    u_xlat2.x = u_xlat2.x * 3.0;
    u_xlat2.x = u_xlat26 * u_xlat1.x + u_xlat2.x;
    u_xlat1.x = u_xlat2.y * u_xlat1.x;
    u_xlat10.x = u_xlat25 * u_xlat25;
    u_xlat1.x = u_xlat1.x * u_xlat10.x;
    u_xlat1.x = u_xlat1.x * 3.0 + u_xlat2.x;
    u_xlat2.x = u_xlat3.x * u_xlat10.x;
    u_xlat2.x = u_xlat2.x * u_xlat25 + u_xlat1.x;
    u_xlat1.x = float(0.0);
    u_xlat1.w = float(0.0);
    u_xlat3.x = float(0.0);
    u_xlat3.y = float(0.0);
    u_xlat19.x = float(0.0);
    u_xlat19.y = float(0.0);
    u_xlat26 = 0.0;
    u_xlat4.x = float(0.0);
    u_xlat4.y = float(0.0);
    u_xlati20 = int(0);
    while(true){
        u_xlatb28 = u_xlati20>=u._colorcurve_segs;
        if(u_xlatb28){break;}
        u_xlati28 = int(u_xlati20 << (1 & int(0x1F)));
        u_xlati5 = int(int_bitfieldInsert(1, u_xlati20, 1 & int(0x1F), 31));
        u_xlatb13 = u_xlat1.y>=_colorcurve_points[u_xlati28].z;
        u_xlatb21 = _colorcurve_points[u_xlati5].x>=u_xlat1.y;
        u_xlatb13 = u_xlatb21 && u_xlatb13;
        if(u_xlatb13){
            u_xlat13.x = u_xlat1.y + (-_colorcurve_points[u_xlati28].z);
            u_xlat21 = (-_colorcurve_points[u_xlati28].z) + _colorcurve_points[u_xlati5].x;
            u_xlat26 = u_xlat13.x / u_xlat21;
            u_xlat1.xw = _colorcurve_points[u_xlati28].yx;
            u_xlat3.xy = _colorcurve_points[u_xlati28].zw;
            u_xlat19.xy = _colorcurve_points[u_xlati5].yx;
            u_xlat4.xy = _colorcurve_points[u_xlati5].wz;
            break;
        }
        u_xlati20 = u_xlati20 + 1;
        u_xlat1.xw = _colorcurve_points[u_xlati28].yx;
        u_xlat3.xy = _colorcurve_points[u_xlati28].zw;
        u_xlat19.xy = _colorcurve_points[u_xlati5].yx;
        u_xlat4.xy = _colorcurve_points[u_xlati5].wz;
        u_xlat26 = 0.0;
    }
    u_xlat5 = u_xlat3.xyxy;
    u_xlat3.xy = (-u_xlat5.xy) + u_xlat19.yx;
    u_xlat20.xy = u_xlat1.wx + (-u_xlat5.zw);
    u_xlat9.x = dot(u_xlat20.xy, u_xlat20.xy);
    u_xlat9.x = sqrt(u_xlat9.x);
    u_xlat20.xy = u_xlat19.yx + (-u_xlat4.yx);
    u_xlat20.x = dot(u_xlat20.xy, u_xlat20.xy);
    u_xlat20.x = sqrt(u_xlat20.x);
    u_xlatb28 = u_xlat9.x<9.99999975e-06;
    u_xlatb21 = u_xlat20.x<9.99999975e-06;
    u_xlatb6 = u_xlatb28 && u_xlatb21;
    u_xlat14.xy = u_xlat3.yy * float2(0.333333343, 0.666666687) + u_xlat5.ww;
    u_xlatb11 = 9.99999975e-06<u_xlat20.x;
    u_xlatb11 = u_xlatb11 && u_xlatb28;
    u_xlat4.xy = (-u_xlat5.yx) + u_xlat4.xy;
    u_xlat4.x = u_xlat4.x / u_xlat4.y;
    u_xlat4.x = u_xlat3.x * u_xlat4.x;
    u_xlat4.w = (-u_xlat4.x) * 0.333333343 + u_xlat19.x;
    u_xlat5.x = (-u_xlat5.y) + u_xlat4.w;
    u_xlat4.x = u_xlat5.x * 0.5 + u_xlat5.w;
    u_xlatb9 = 9.99999975e-06<u_xlat9.x;
    u_xlatb9 = u_xlatb21 && u_xlatb9;
    u_xlat1.xw = (-u_xlat1.xw) + u_xlat19.xy;
    u_xlat1.x = u_xlat1.x / u_xlat1.w;
    u_xlat1.x = u_xlat3.x * u_xlat1.x;
    u_xlat4.y = u_xlat1.x * 0.333333343 + u_xlat5.w;
    u_xlat1.x = (-u_xlat19.x) + u_xlat4.y;
    u_xlat4.z = u_xlat1.x * 0.5 + u_xlat19.x;
    u_xlat1.xy = (bool(u_xlatb9)) ? u_xlat4.yz : u_xlat4.yw;
    u_xlat1.xy = (bool(u_xlatb11)) ? u_xlat4.xw : u_xlat1.xy;
    u_xlat1.xy = (bool(u_xlatb6)) ? u_xlat14.xy : u_xlat1.xy;
    u_xlat25 = (-u_xlat26) + 1.0;
    u_xlat3.x = u_xlat25 * u_xlat25;
    u_xlat11.x = u_xlat5.w * u_xlat3.x;
    u_xlat1.x = u_xlat1.x * u_xlat3.x;
    u_xlat1.x = u_xlat26 * u_xlat1.x;
    u_xlat1.x = u_xlat1.x * 3.0;
    u_xlat1.x = u_xlat11.x * u_xlat25 + u_xlat1.x;
    u_xlat9.x = u_xlat1.y * u_xlat25;
    u_xlat25 = u_xlat26 * u_xlat26;
    u_xlat9.x = u_xlat9.x * u_xlat25;
    u_xlat1.x = u_xlat9.x * 3.0 + u_xlat1.x;
    u_xlat9.x = u_xlat19.x * u_xlat25;
    u_xlat2.y = u_xlat9.x * u_xlat26 + u_xlat1.x;
    u_xlat3.x = float(0.0);
    u_xlat3.y = float(0.0);
    u_xlat19.x = float(0.0);
    u_xlat19.y = float(0.0);
    u_xlat4.x = float(0.0);
    u_xlat4.y = float(0.0);
    u_xlat1.x = float(0.0);
    u_xlat1.y = float(0.0);
    u_xlat1.w = float(0.0);
    u_xlati26 = 0;
    while(true){
        u_xlatb20 = u_xlati26>=u._colorcurve_segs;
        if(u_xlatb20){break;}
        u_xlati20 = int(u_xlati26 << (1 & int(0x1F)));
        u_xlati28 = int(int_bitfieldInsert(1, u_xlati26, 1 & int(0x1F), 31));
        u_xlatb5 = u_xlat1.z>=_colorcurve_points[u_xlati20].z;
        u_xlatb13 = _colorcurve_points[u_xlati28].x>=u_xlat1.z;
        u_xlatb5 = u_xlatb13 && u_xlatb5;
        if(u_xlatb5){
            u_xlat5.x = u_xlat1.z + (-_colorcurve_points[u_xlati20].z);
            u_xlat13.x = (-_colorcurve_points[u_xlati20].z) + _colorcurve_points[u_xlati28].x;
            u_xlat1.w = u_xlat5.x / u_xlat13.x;
            u_xlat1.xy = _colorcurve_points[u_xlati20].yx;
            u_xlat3.xy = _colorcurve_points[u_xlati20].zw;
            u_xlat19.xy = _colorcurve_points[u_xlati28].yx;
            u_xlat4.xy = _colorcurve_points[u_xlati28].wz;
            break;
        }
        u_xlati26 = u_xlati26 + 1;
        u_xlat1.xy = _colorcurve_points[u_xlati20].yx;
        u_xlat3.xy = _colorcurve_points[u_xlati20].zw;
        u_xlat19.xy = _colorcurve_points[u_xlati28].yx;
        u_xlat4.xy = _colorcurve_points[u_xlati28].wz;
        u_xlat1.w = 0.0;
    }
    u_xlat5 = u_xlat3.xyxy;
    u_xlat3.xy = (-u_xlat5.xy) + u_xlat19.yx;
    u_xlat20.xy = (-u_xlat5.zw) + u_xlat1.yx;
    u_xlat17.x = dot(u_xlat20.xy, u_xlat20.xy);
    u_xlat17.x = sqrt(u_xlat17.x);
    u_xlat20.xy = u_xlat19.yx + (-u_xlat4.yx);
    u_xlat26 = dot(u_xlat20.xy, u_xlat20.xy);
    u_xlat26 = sqrt(u_xlat26);
    u_xlatb20 = u_xlat17.x<9.99999975e-06;
    u_xlatb28 = u_xlat26<9.99999975e-06;
    u_xlatb21 = u_xlatb28 && u_xlatb20;
    u_xlat6.xy = u_xlat3.yy * float2(0.333333343, 0.666666687) + u_xlat5.ww;
    u_xlatb26 = 9.99999975e-06<u_xlat26;
    u_xlatb26 = u_xlatb26 && u_xlatb20;
    u_xlat4.xy = (-u_xlat5.yx) + u_xlat4.xy;
    u_xlat11.x = u_xlat4.x / u_xlat4.y;
    u_xlat11.x = u_xlat3.x * u_xlat11.x;
    u_xlat7.w = (-u_xlat11.x) * 0.333333343 + u_xlat19.x;
    u_xlat11.x = (-u_xlat5.y) + u_xlat7.w;
    u_xlat7.x = u_xlat11.x * 0.5 + u_xlat5.w;
    u_xlatb17 = 9.99999975e-06<u_xlat17.x;
    u_xlatb17 = u_xlatb28 && u_xlatb17;
    u_xlat1.xy = (-u_xlat1.xy) + u_xlat19.xy;
    u_xlat1.x = u_xlat1.x / u_xlat1.y;
    u_xlat1.x = u_xlat3.x * u_xlat1.x;
    u_xlat7.y = u_xlat1.x * 0.333333343 + u_xlat5.w;
    u_xlat1.x = (-u_xlat19.x) + u_xlat7.y;
    u_xlat7.z = u_xlat1.x * 0.5 + u_xlat19.x;
    u_xlat1.xy = (bool(u_xlatb17)) ? u_xlat7.yz : u_xlat7.yw;
    u_xlat1.xy = (bool(u_xlatb26)) ? u_xlat7.xw : u_xlat1.xy;
    u_xlat1.xy = (bool(u_xlatb21)) ? u_xlat6.xy : u_xlat1.xy;
    u_xlat1.z = (-u_xlat1.w) + 1.0;
    u_xlat26 = u_xlat1.z * u_xlat1.z;
    u_xlat3.x = u_xlat5.w * u_xlat26;
    u_xlat1.x = u_xlat1.x * u_xlat26;
    u_xlat1.xy = u_xlat1.wy * u_xlat1.xz;
    u_xlat1.x = u_xlat1.x * 3.0;
    u_xlat1.x = u_xlat3.x * u_xlat1.z + u_xlat1.x;
    u_xlat17.x = u_xlat1.w * u_xlat1.w;
    u_xlat9.x = u_xlat1.y * u_xlat17.x;
    u_xlat1.x = u_xlat9.x * 3.0 + u_xlat1.x;
    u_xlat9.x = u_xlat19.x * u_xlat17.x;
    u_xlat2.z = u_xlat9.x * u_xlat1.w + u_xlat1.x;
    u_xlat1.xyz = u_xlat2.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u_xlat2.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat1.xyz = u_xlat1.xyz * u_xlat2.xyz;
    u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
    u_xlat1.w = u_xlat0.w;
    u_xlat1.w = clamp(u_xlat1.w, 0.0, 1.0);
    if(u._use_inner_mask != 0) {
        u_xlatb2.xy = equal(int4(u._show_inner_mask, u._b_clip_mask, u._show_inner_mask, u._show_inner_mask), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat3 * u_xlat4 + u_xlat0;
        u_xlat2.x = u_xlat4.x * u_xlat0.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat0.w;
        __nv_out.xyz = u_xlat0.xyz;
    } else {
        __nv_out = u_xlat1;
    }
    return __nv_out;
    return __nv_out;
}
