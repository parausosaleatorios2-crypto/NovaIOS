// ---------------------------------------------------------------------------
// Tile Shift (NV)
// origem : assets/effects/nv-nodevideo-assetstore-tile-shift.xml
// id     : nv.effect.nodevideo-assetstore-tile-shift
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_tile_shiftParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _strength;
    float2 _offset;
    float _scale;
    float2 _stretch;
    float _rotation;
    float _rgb_shift;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat7;
bool u_xlatb7;
float2 u_xlat13;
bool u_xlatb19;

fragment float4 fx_nv_nodevideo_assetstore_tile_shift(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_tile_shiftParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> SourceTexMirror [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = in.acScreenNorm.x;
    u_xlat1.x = u_xlat1.x + -0.5;
    u_xlat7 = _resolution.x / _resolution.y;
    u_xlat1.x = u_xlat7 * u_xlat1.x;
    u_xlat1.y = (-in.acScreenNorm.y) + 0.5;
    u_xlat1.xy = u_xlat1.xy + (-float2(u._offset.x, u._offset.y));
    u_xlat13.x = u._rotation * 0.0174532998;
    u_xlat2.x = sin(u_xlat13.x);
    u_xlat3.x = cos(u_xlat13.x);
    u_xlat4.x = (-u_xlat3.x);
    u_xlat4.y = u_xlat2.x;
    u_xlat4.z = u_xlat3.x;
    u_xlat1.z = dot(u_xlat1.xy, u_xlat4.yz);
    u_xlat1.x = dot(u_xlat1.xy, u_xlat4.xy);
    u_xlat7 = u._scale * 0.100000001;
    u_xlat1.xz = u_xlat1.xz / float2(u_xlat7);
    u_xlat1.xz = u_xlat1.xz / u._stretch.yx;
    u_xlat2.x = floor(u_xlat1.z);
    u_xlat1.x = floor(u_xlat1.x);
    u_xlat2.yz = u_xlat1.xx + float2(3937.72485, -971.382019);
    u_xlat1.x = dot(u_xlat2.xy, float2(719.309998, 178.233002));
    u_xlat1.x = u_xlat1.x * 0.318471313;
    u_xlatb7 = u_xlat1.x>=(-u_xlat1.x);
    u_xlat1.x = fract(abs(u_xlat1.x));
    u_xlat1.x = (u_xlatb7) ? u_xlat1.x : (-u_xlat1.x);
    u_xlat1.x = u_xlat1.x * 3.1400001;
    u_xlat1.x = sin(u_xlat1.x);
    u_xlat1.x = u_xlat1.x * 33758.5469;
    u_xlat2.w = u_xlat2.x + 761.456787;
    u_xlat13.x = dot(u_xlat2.wz, float2(719.309998, 178.233002));
    u_xlat13.x = u_xlat13.x * 0.318471313;
    u_xlatb19 = u_xlat13.x>=(-u_xlat13.x);
    u_xlat13.x = fract(abs(u_xlat13.x));
    u_xlat13.x = (u_xlatb19) ? u_xlat13.x : (-u_xlat13.x);
    u_xlat13.x = u_xlat13.x * 3.1400001;
    u_xlat13.x = sin(u_xlat13.x);
    u_xlat1.z = u_xlat13.x * 33758.5469;
    u_xlat1.xy = fract(u_xlat1.xz);
    u_xlat1.xy = u_xlat1.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat1.xy + u_xlat1.xy;
    u_xlat13.xy = u_xlat1.xy * float2(u._strength) + in.acScreenNorm.xy;
    u_xlat2.xw = SourceTexMirror.sample(__nv_smp, u_xlat13.xy).xw;
    u_xlat13.x = (-u._strength) * u._rgb_shift + u._strength;
    u_xlat13.xy = u_xlat1.xy * u_xlat13.xx + in.acScreenNorm.xy;
    u_xlat2.y = SourceTexMirror.sample(__nv_smp, u_xlat13.xy).y;
    u_xlat13.x = u._strength * u._rgb_shift + u._strength;
    u_xlat1.xy = u_xlat1.xy * u_xlat13.xx + in.acScreenNorm.xy;
    u_xlat2.z = SourceTexMirror.sample(__nv_smp, u_xlat1.xy).z;
    u_xlat1 = u_xlat0.wwww * u_xlat2;
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
