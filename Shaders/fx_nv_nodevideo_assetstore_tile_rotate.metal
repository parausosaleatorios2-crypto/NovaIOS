// ---------------------------------------------------------------------------
// Tile Rotate (NV)
// origem : assets/effects/nv-nodevideo-assetstore-tile-rotate.xml
// id     : nv.effect.nodevideo-assetstore-tile-rotate
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_tile_rotateParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _strength;
    float2 _offset;
    float _rotation;
    float _angle;
    float2 _scale;
    float _seed;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat7;
bool2 u_xlatb13;
bool2 u_xlatb14;
float u_xlat19;
bool u_xlatb19;

fragment float4 fx_nv_nodevideo_assetstore_tile_rotate(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_tile_rotateParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = in.acScreenNorm.x;
    u_xlat1.x = u_xlat1.x + -0.5;
    u_xlat7.xy = _resolution.xy / _resolution.yx;
    u_xlat1.x = u_xlat7.x * u_xlat1.x;
    u_xlat1.y = (-in.acScreenNorm.y) + 0.5;
    u_xlat1.xy = u_xlat1.xy + (-float2(u._offset.x, u._offset.y));
    u_xlat2.xyz = float3(u._angle, u._scale.x, u._scale.y) * float3(0.0174532998, 10.0, 10.0);
    u_xlat3.x = sin(u_xlat2.x);
    u_xlat4.x = cos(u_xlat2.x);
    u_xlat5.x = cos((-u_xlat2.x));
    u_xlat2.x = sin((-u_xlat2.x));
    u_xlat4.y = u_xlat3.x;
    u_xlat1.w = dot(u_xlat1.xy, u_xlat4.xy);
    u_xlat4.z = u_xlat2.x;
    u_xlat1.x = dot(u_xlat1.yx, u_xlat4.xz);
    u_xlat1.xy = u_xlat2.zy * u_xlat1.xw;
    u_xlat3.x = floor(u_xlat1.y);
    u_xlat1.x = floor(u_xlat1.x);
    u_xlat3.y = u._seed * 3937.72485 + u_xlat1.x;
    u_xlat7.x = dot(u_xlat3.xy, float2(719.309998, 178.233002));
    u_xlat7.x = u_xlat7.x * 0.318471313;
    u_xlatb19 = u_xlat7.x>=(-u_xlat7.x);
    u_xlat7.x = fract(abs(u_xlat7.x));
    u_xlat7.x = (u_xlatb19) ? u_xlat7.x : (-u_xlat7.x);
    u_xlat7.x = u_xlat7.x * 3.1400001;
    u_xlat7.x = sin(u_xlat7.x);
    u_xlat7.x = u_xlat7.x * 33758.5469;
    u_xlat1.y = fract(u_xlat7.x);
    u_xlat1.xy = u_xlat1.xy + float2(0.5, -0.5);
    u_xlat7.x = u_xlat1.y * u._strength;
    u_xlat7.x = u_xlat7.x * 12.5663605;
    u_xlat7.x = u._rotation * 0.0174532998 + u_xlat7.x;
    u_xlat19 = u_xlat3.x + 0.5;
    u_xlat2.x = u_xlat19 / u_xlat2.y;
    u_xlat2.y = u_xlat1.x / u_xlat2.z;
    u_xlat4.w = u_xlat5.x;
    u_xlat3.x = dot(u_xlat2.yx, u_xlat4.zw);
    u_xlat3.y = dot(u_xlat2.xy, u_xlat4.yw);
    u_xlat1.xw = u_xlat3.xy + float2(u._offset.x, u._offset.y);
    u_xlat2.xy = u_xlat1.xw * u_xlat7.yy + float2(0.5, 0.5);
    u_xlat2.z = (-u_xlat2.y) + 1.0;
    u_xlat1.xz = (-u_xlat2.xz) + in.acScreenNorm.xy;
    u_xlat3.x = sin(u_xlat7.x);
    u_xlat4.x = cos(u_xlat7.x);
    u_xlat5.x = sin((-u_xlat7.x));
    u_xlat5.y = u_xlat4.x;
    u_xlat5.z = u_xlat3.x;
    u_xlat3.x = dot(u_xlat1.xz, u_xlat5.yz);
    u_xlat3.y = dot(u_xlat1.xz, u_xlat5.xy);
    u_xlat1.xy = u_xlat2.xz + u_xlat3.xy;
    u_xlatb13.xy = lessThan(u_xlat1.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlat2.xy = fract(u_xlat1.xy);
    u_xlatb14.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat1.xyxy).xy;
    u_xlat3.xy = (-u_xlat2.xy) + float2(1.0, 1.0);
    {
        float4 hlslcc_movcTemp = u_xlat1;
        hlslcc_movcTemp.x = (u_xlatb14.x) ? u_xlat3.x : u_xlat1.x;
        hlslcc_movcTemp.y = (u_xlatb14.y) ? u_xlat3.y : u_xlat1.y;
        u_xlat1 = hlslcc_movcTemp;
    }
    {
        float4 hlslcc_movcTemp = u_xlat1;
        hlslcc_movcTemp.x = (u_xlatb13.x) ? u_xlat2.x : u_xlat1.x;
        hlslcc_movcTemp.y = (u_xlatb13.y) ? u_xlat2.y : u_xlat1.y;
        u_xlat1 = hlslcc_movcTemp;
    }
    u_xlat1 = inputImg.sample(__nv_smp, u_xlat1.xy);
    u_xlat1 = u_xlat0.wwww * u_xlat1;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
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
