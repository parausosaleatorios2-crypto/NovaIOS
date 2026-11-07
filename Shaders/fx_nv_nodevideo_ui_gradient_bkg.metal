// ---------------------------------------------------------------------------
// Ui Gradient Bkg (NV)
// origem : assets/effects/nv-nodevideo-ui-gradient-bkg.xml
// id     : nv.effect.nodevideo-ui-gradient-bkg
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_ui_gradient_bkgParams {
    float _point_count;
};

// --- funcoes auxiliares do efeito
float3 u_xlat0;
int u_xlati0;
bool u_xlatb0;
float4 u_xlat1;
float4 u_xlat2;
bool u_xlatb3;
float4 u_xlat4;
int u_xlati5;
bool u_xlatb5;
float u_xlat8;
bool u_xlatb8;
int u_xlati10;
float u_xlat13;
int u_xlati15;
bool u_xlatb15;

fragment float4 fx_nv_nodevideo_ui_gradient_bkg(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_ui_gradient_bkgParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0 = 1<u._point_count;
    if(u_xlatb0){
        u_xlatb0 = _color_pos[0]<in.acScreenNorm.x;
        if(u_xlatb0){
            u_xlati0 = u._point_count + int(0xFFFFFFFFu);
            u_xlatb5 = in.acScreenNorm.x>=_color_pos[u_xlati0];
            if(u_xlatb5){
                u_xlat1 = _colors[u_xlati0];
            } else {
                u_xlat1 = _colors[0];
            }
            if(!u_xlatb5){
                u_xlat2 = u_xlat1;
                u_xlati5 = int(0);
                u_xlati10 = int(0);
                while(true){
                    u_xlatb15 = u_xlati5>=u_xlati0;
                    u_xlati10 = 0;
                    if(u_xlatb15){break;}
                    u_xlati15 = u_xlati5 + 1;
                    u_xlatb3 = in.acScreenNorm.x>=_color_pos[u_xlati5];
                    u_xlatb8 = _color_pos[u_xlati15]>=in.acScreenNorm.x;
                    u_xlatb3 = u_xlatb8 && u_xlatb3;
                    if(u_xlatb3){
                        u_xlat8 = in.acScreenNorm.x + (-_color_pos[u_xlati5]);
                        u_xlat13 = (-_color_pos[u_xlati5]) + _color_pos[u_xlati15];
                        u_xlat8 = u_xlat8 / u_xlat13;
                        u_xlat4 = (-_colors[u_xlati5]) + _colors[u_xlati15];
                        u_xlat4 = float4(u_xlat8) * u_xlat4 + _colors[u_xlati5];
                        u_xlati10 = int(0xFFFFFFFFu);
                        u_xlat2 = u_xlat4;
                        break;
                    }
                    u_xlati5 = u_xlati15;
                    u_xlati10 = int(u_xlatb3);
                }
                u_xlat1 = as_type<float>(uint4(uint(as_type<uint>(u_xlat2.x)) & uint(u_xlati10), uint(as_type<uint>(u_xlat2.y)) & uint(u_xlati10), uint(as_type<uint>(u_xlat2.z)) & uint(u_xlati10), uint(as_type<uint>(u_xlat2.w)) & uint(u_xlati10)));
            }
        } else {
            u_xlat1 = _colors[0];
        }
    } else {
        u_xlat1 = _colors[0];
    }
    u_xlat0.xyz = u_xlat1.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat0.xyz = u_xlat1.xyz * u_xlat0.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xyz;
    __nv_out = u_xlat1;
    return __nv_out;
    return __nv_out;
}
