// ---------------------------------------------------------------------------
// Effect Stylize Motion Tile (NV)
// origem : assets/effects/nv-nodevideo-effect-stylize-motion-tile.xml
// id     : nv.effect.nodevideo-effect-stylize-motion-tile
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_stylize_motion_tileParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _tile_center;
    float2 _tile_center_prev;
    float2 _tile_scale;
    float2 _tile_scale_prev;
    float2 _tile_anchor;
    float _tile_rotation;
    float _tile_rotation_prev;
    float _mirror_edges;
    float _phase;
    float _phase_type;
    float _motion_amount;
    float _motion_stay;
    float _motion_samples;
    float _enable_motion_blur;
    float _dispersion;
    float _edge_width;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _node_size (eng.acTamanhoDaCamada / eng.acTamanhoDaTela)
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
int u_xlati5;
float4 u_xlat6;
int3 u_xlati6;
bool3 u_xlatb6;
float3 u_xlat7;
float2 u_xlat8;
float3 u_xlat12;
bool u_xlatb12;
float3 u_xlat14;
bool u_xlatb14;
float u_xlat15;
bool u_xlatb15;
float2 u_xlat18;
int u_xlati18;
float u_xlat20;
float u_xlat21;
bool u_xlatb21;
float2 u_xlat22;
bool u_xlatb22;
float2 u_xlat23;
bool u_xlatb23;
float u_xlat24;
bool u_xlatb24;
float2 u_xlat25;
int u_xlati27;
float u_xlat29;
int u_xlati29;
bool u_xlatb29;
float u_xlat30;
bool u_xlatb30;
float u_xlat32;
bool u_xlatb32;
float u_xlat33;
bool u_xlatb33;

fragment float4 fx_nv_nodevideo_effect_stylize_motion_tile(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_stylize_motion_tileParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat18.xy = u._tile_anchor.xy + float2(-0.5, -0.5);
    u_xlat0.xy = (-u_xlat18.xy) + u_xlat0.xy;
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat1.x = u._tile_rotation * 0.0174532942;
    u_xlat2.x = sin(u_xlat1.x);
    u_xlat3.x = cos(u_xlat1.x);
    u_xlat1.x = sin((-u_xlat1.x));
    u_xlat1.y = u_xlat3.x;
    u_xlat3.x = dot(u_xlat1.yx, u_xlat0.xy);
    u_xlat1.z = u_xlat2.x;
    u_xlat3.y = dot(u_xlat1.zy, u_xlat0.xy);
    u_xlat1.xy = u_xlat3.xy * u._tile_scale.xy + u._tile_center.xy;
    u_xlat1.xy = u_xlat1.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat1.xy = u_xlat18.xy + u_xlat1.xy;
    u_xlat1.xy = u_xlat1.xy + float2(0.5, 0.5);
    u_xlat1.zw = _node_size.xy * float2(0.5, 0.5) + float2(0.5, 0.5);
    u_xlat2.xy = (-_node_size.xy) * float2(0.5, 0.5) + float2(0.5, 0.5);
    u_xlat1 = u_xlat1 + (-u_xlat2.xyxy);
    u_xlat1.xy = u_xlat1.xy / u_xlat1.zw;
    u_xlat20 = u._edge_width * 0.00999999978 + 1.0;
    u_xlat3.xy = u_xlat1.xy + float2(-0.5, -0.5);
    u_xlat3.xy = u_xlat3.xy * float2(u_xlat20) + float2(0.5, 0.5);
    if(int(u._phase_type) == 0) {
        u_xlatb29 = u_xlat3.y>=0.0;
        u_xlat21 = abs(u_xlat3.y) + 1.0;
        u_xlat29 = (u_xlatb29) ? u_xlat3.y : u_xlat21;
        u_xlat29 = u_xlat29 * 0.5;
        u_xlatb21 = u_xlat29>=(-u_xlat29);
        u_xlat29 = fract(abs(u_xlat29));
        u_xlat29 = (u_xlatb21) ? u_xlat29 : (-u_xlat29);
        u_xlatb29 = u_xlat29>=0.5;
        u_xlat21 = u_xlatb29 ? 1.0 : float(0.0);
        u_xlat21 = u_xlat21 * u._phase + u_xlat3.x;
        u_xlatb30 = u_xlat21>=0.0;
        u_xlat4.x = abs(u_xlat21) + 1.0;
        u_xlat30 = (u_xlatb30) ? u_xlat21 : u_xlat4.x;
        u_xlat4.x = fract(u_xlat21);
        u_xlat4.y = fract(u_xlat3.y);
        u_xlatb21 = int(u._mirror_edges)==1;
        u_xlat30 = u_xlat30 * 0.5;
        u_xlatb22 = u_xlat30>=(-u_xlat30);
        u_xlat30 = fract(abs(u_xlat30));
        u_xlat30 = (u_xlatb22) ? u_xlat30 : (-u_xlat30);
        u_xlatb30 = u_xlat30>=0.5;
        u_xlatb30 = u_xlatb30 && u_xlatb21;
        u_xlat22.xy = (-u_xlat4.xy) + float2(1.0, 1.0);
        u_xlat5.x = (u_xlatb30) ? u_xlat22.x : u_xlat4.x;
        u_xlatb29 = u_xlatb29 && u_xlatb21;
        u_xlat5.y = (u_xlatb29) ? u_xlat22.y : u_xlat4.y;
    } else {
        u_xlatb29 = u_xlat3.x>=0.0;
        u_xlat21 = abs(u_xlat3.x) + 1.0;
        u_xlat29 = (u_xlatb29) ? u_xlat3.x : u_xlat21;
        u_xlat29 = u_xlat29 * 0.5;
        u_xlatb21 = u_xlat29>=(-u_xlat29);
        u_xlat29 = fract(abs(u_xlat29));
        u_xlat29 = (u_xlatb21) ? u_xlat29 : (-u_xlat29);
        u_xlatb29 = u_xlat29>=0.5;
        u_xlat21 = u_xlatb29 ? 1.0 : float(0.0);
        u_xlat12.x = u_xlat21 * u._phase + u_xlat3.y;
        u_xlatb21 = u_xlat12.x>=0.0;
        u_xlat30 = abs(u_xlat12.x) + 1.0;
        u_xlat21 = (u_xlatb21) ? u_xlat12.x : u_xlat30;
        u_xlat4.x = fract(u_xlat3.x);
        u_xlat4.y = fract(u_xlat12.x);
        u_xlatb3 = int(u._mirror_edges)==1;
        u_xlatb29 = u_xlatb29 && u_xlatb3;
        u_xlat12.xz = (-u_xlat4.xy) + float2(1.0, 1.0);
        u_xlat5.x = (u_xlatb29) ? u_xlat12.x : u_xlat4.x;
        u_xlat29 = u_xlat21 * 0.5;
        u_xlatb12 = u_xlat29>=(-u_xlat29);
        u_xlat29 = fract(abs(u_xlat29));
        u_xlat29 = (u_xlatb12) ? u_xlat29 : (-u_xlat29);
        u_xlatb29 = u_xlat29>=0.5;
        u_xlatb29 = u_xlatb29 && u_xlatb3;
        u_xlat5.y = (u_xlatb29) ? u_xlat12.z : u_xlat4.y;
    }
    u_xlat3.xy = u_xlat5.xy + float2(-0.5, -0.5);
    u_xlat3.xy = u_xlat3.xy / float2(u_xlat20);
    u_xlat3.xy = u_xlat3.xy + float2(0.5, 0.5);
    u_xlat3.xy = u_xlat1.zw * u_xlat3.xy + u_xlat2.xy;
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.xy);
    u_xlatb29 = 0<int(u._enable_motion_blur);
    if(u_xlatb29){
        u_xlat29 = u._tile_rotation_prev * 0.0174532942;
        u_xlat4.x = sin(u_xlat29);
        u_xlat5.x = cos(u_xlat29);
        u_xlat6.x = sin((-u_xlat29));
        u_xlat6.y = u_xlat5.x;
        u_xlat5.x = dot(u_xlat6.yx, u_xlat0.xy);
        u_xlat6.z = u_xlat4.x;
        u_xlat5.y = dot(u_xlat6.zy, u_xlat0.xy);
        u_xlat0.xy = u_xlat5.xy * float2(u._tile_scale_prev.x, u._tile_scale_prev.y) + float2(u._tile_center_prev.x, u._tile_center_prev.y);
        u_xlat0.xy = u_xlat0.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
        u_xlat0.xy = u_xlat18.xy + u_xlat0.xy;
        u_xlat0.xy = (-u_xlat2.xy) + u_xlat0.xy;
        u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
        u_xlat0.xy = u_xlat0.xy / u_xlat1.zw;
        u_xlat0.xy = (-u_xlat0.xy) + u_xlat1.xy;
        u_xlat0.xy = u_xlat0.xy * float2(float2(u._motion_amount, u._motion_amount));
        u_xlati18 = int(u._motion_samples) + int(0xFFFFFFFFu);
        u_xlat18.x = float(u_xlati18);
        u_xlat4 = u_xlat3;
        u_xlati27 = int(u._mirror_edges);
        u_xlati29 = int(u._phase_type);
        for(int u_xlati_loop_1 = 1 ; u_xlati_loop_1<int(u._motion_samples) ; u_xlati_loop_1++)
        {
            u_xlat14.x = float(u_xlati_loop_1);
            u_xlat14.x = u_xlat14.x / u_xlat18.x;
            u_xlat23.xy = (-u_xlat0.xy) * u_xlat14.xx + u_xlat1.xy;
            u_xlat23.xy = u_xlat23.xy + float2(-0.5, -0.5);
            u_xlat23.xy = u_xlat23.xy * float2(u_xlat20) + float2(0.5, 0.5);
            if(u_xlati29 == 0) {
                u_xlatb6.x = u_xlat23.y>=0.0;
                u_xlat15 = abs(u_xlat23.y) + 1.0;
                u_xlat6.x = (u_xlatb6.x) ? u_xlat23.y : u_xlat15;
                u_xlat6.x = u_xlat6.x * 0.5;
                u_xlatb15 = u_xlat6.x>=(-u_xlat6.x);
                u_xlat6.x = fract(abs(u_xlat6.x));
                u_xlat6.x = (u_xlatb15) ? u_xlat6.x : (-u_xlat6.x);
                u_xlatb6.x = u_xlat6.x>=0.5;
                u_xlat15 = u_xlatb6.x ? 1.0 : float(0.0);
                u_xlat15 = u_xlat15 * u._phase + u_xlat23.x;
                u_xlatb24 = u_xlat15>=0.0;
                u_xlat33 = abs(u_xlat15) + 1.0;
                u_xlat24 = (u_xlatb24) ? u_xlat15 : u_xlat33;
                u_xlat7.x = fract(u_xlat15);
                u_xlat7.y = fract(u_xlat23.y);
                u_xlatb15 = u_xlati27==1;
                u_xlat24 = u_xlat24 * 0.5;
                u_xlatb33 = u_xlat24>=(-u_xlat24);
                u_xlat24 = fract(abs(u_xlat24));
                u_xlat24 = (u_xlatb33) ? u_xlat24 : (-u_xlat24);
                u_xlatb6.z = u_xlat24>=0.5;
                u_xlati6.xz = int2(uint2((uint(u_xlatb6.x) * 0xffffffffu) & (uint(u_xlatb15) * 0xffffffffu), (uint(u_xlatb6.z) * 0xffffffffu) & (uint(u_xlatb15) * 0xffffffffu)));
                u_xlat25.xy = (-u_xlat7.xy) + float2(1.0, 1.0);
                u_xlat8.x = (u_xlati6.z != 0) ? u_xlat25.x : u_xlat7.x;
                u_xlat8.y = (u_xlati6.x != 0) ? u_xlat25.y : u_xlat7.y;
            } else {
                u_xlatb6.x = u_xlat23.x>=0.0;
                u_xlat15 = abs(u_xlat23.x) + 1.0;
                u_xlat6.x = (u_xlatb6.x) ? u_xlat23.x : u_xlat15;
                u_xlat6.x = u_xlat6.x * 0.5;
                u_xlatb15 = u_xlat6.x>=(-u_xlat6.x);
                u_xlat6.x = fract(abs(u_xlat6.x));
                u_xlat6.x = (u_xlatb15) ? u_xlat6.x : (-u_xlat6.x);
                u_xlatb6.x = u_xlat6.x>=0.5;
                u_xlat15 = u_xlatb6.x ? 1.0 : float(0.0);
                u_xlat32 = u_xlat15 * u._phase + u_xlat23.y;
                u_xlatb15 = u_xlat32>=0.0;
                u_xlat24 = abs(u_xlat32) + 1.0;
                u_xlat15 = (u_xlatb15) ? u_xlat32 : u_xlat24;
                u_xlat7.x = fract(u_xlat23.x);
                u_xlat7.y = fract(u_xlat32);
                u_xlatb23 = u_xlati27==1;
                u_xlatb32 = u_xlatb6.x && u_xlatb23;
                u_xlat6.xz = (-u_xlat7.xy) + float2(1.0, 1.0);
                u_xlat8.x = (u_xlatb32) ? u_xlat6.x : u_xlat7.x;
                u_xlat32 = u_xlat15 * 0.5;
                u_xlatb6.x = u_xlat32>=(-u_xlat32);
                u_xlat32 = fract(abs(u_xlat32));
                u_xlat32 = (u_xlatb6.x) ? u_xlat32 : (-u_xlat32);
                u_xlatb32 = u_xlat32>=0.5;
                u_xlatb23 = u_xlatb32 && u_xlatb23;
                u_xlat8.y = (u_xlatb23) ? u_xlat6.z : u_xlat7.y;
            }
            u_xlat23.xy = u_xlat8.xy + float2(-0.5, -0.5);
            u_xlat23.xy = u_xlat23.xy / float2(u_xlat20);
            u_xlat23.xy = u_xlat23.xy + float2(0.5, 0.5);
            u_xlat23.xy = u_xlat1.zw * u_xlat23.xy + u_xlat2.xy;
            u_xlat6 = inputImg.sample(__nv_smp, u_xlat23.xy);
            u_xlat7.z = u_xlat14.x * 3.0 + -1.5;
            u_xlat7.y = -abs(u_xlat7.z) + 1.0;
            u_xlat7.x = (-u_xlat7.z);
            u_xlat7.xyz = u_xlat7.xyz;
            u_xlat7.xyz = clamp(u_xlat7.xyz, 0.0, 1.0);
            u_xlat14.xyz = u_xlat6.xyz * u_xlat7.xyz;
            u_xlat14.xyz = u_xlat14.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat6.xyz);
            u_xlat6.xyz = float3(float3(u._dispersion, u._dispersion, u._dispersion)) * u_xlat14.xyz + u_xlat6.xyz;
            u_xlat4 = u_xlat4 + u_xlat6;
            u_xlat4.xyz = u_xlat3.xyz * float3(float3(u._motion_stay, u._motion_stay, u._motion_stay)) + u_xlat4.xyz;
        }
        u_xlat0.x = float(int(u._motion_samples));
        u_xlat3 = u_xlat4 / u_xlat0.xxxx;
    }
    if(int(u._use_inner_mask) != 0) {
        u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat2 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat3;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat2 * u_xlat4 + u_xlat0;
        u_xlat1.x = u_xlat4.x * u_xlat0.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat0.w;
        __nv_out.xyz = u_xlat0.xyz;
    } else {
        __nv_out = u_xlat3;
    }
    return __nv_out;
    return __nv_out;
}
