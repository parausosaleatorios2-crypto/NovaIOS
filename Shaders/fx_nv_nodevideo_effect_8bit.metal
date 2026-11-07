// ---------------------------------------------------------------------------
// Effect 8Bit (NV)
// origem : assets/effects/nv-nodevideo-effect-8bit.xml
// id     : nv.effect.nodevideo-effect-8bit
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_8bitParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _Dithering;
    float _Downsampling;
    float _Opacity;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
// A paleta: no Node quem manda é o C# (AE8bit), que o conversor não leu. Aqui, 8 cores fixas (0.910.0):
// preto, branco, vermelho, verde, azul, amarelo, ciano e magenta. O _PaletteLab está no mesmo espaço em que o
// shader mede o pixel, e o _PaletteRGB sai do polinômio do fim exatamente na cor da paleta.
const float4 _PaletteLab[8] = float4[8](
    float4(0.000000, 0.000000, 0.000000, 0.0),
    float4(1.000000, 0.000000, 0.000000, 0.0),
    float4(0.742167, 0.118595, 0.044449, 0.0),
    float4(0.832900, -0.119291, 0.086311, 0.0),
    float4(0.731392, -0.003779, -0.114853, 0.0),
    float4(0.926321, -0.021422, 0.116286, 0.0),
    float4(0.859916, -0.075349, -0.044032, 0.0),
    float4(0.775400, 0.107526, -0.070557, 0.0));
const float4 _PaletteRGB[8] = float4[8](
    float4(0.000000, 0.000000, 0.000000, 1.0),
    float4(1.000000, 1.000000, 1.000000, 1.0),
    float4(0.944883, 0.537258, 0.537258, 1.0),
    float4(0.537258, 0.882901, 0.537258, 1.0),
    float4(0.537258, 0.647091, 0.944883, 1.0),
    float4(0.973871, 0.914612, 0.537258, 1.0),
    float4(0.537258, 0.882901, 0.944883, 1.0),
    float4(0.882901, 0.595398, 0.882901, 1.0));
float4 ImmCB_0[4];

float4 u_xlat0;
float4 u_xlat1;
int u_xlati1;
uint2 u_xlatu1;
bool u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat7;
int u_xlati7;
float2 u_xlat13;
bool u_xlatb13;
float u_xlat19;
static int int_bitfieldInsert(int base, int insert, int offset, int bits) {
    uint mask = uint(~(int(~0) << uint(bits)) << uint(offset));
    return int((uint(base) & ~mask) | ((uint(insert) << uint(offset)) & mask));
}

fragment float4 fx_nv_nodevideo_effect_8bit(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_8bitParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

ImmCB_0[0] = float4(-0.5,0.0,0.0,0.0);
ImmCB_0[1] = float4(0.0,0.0,0.0,0.0);
ImmCB_0[2] = float4(0.25,0.0,0.0,0.0);
ImmCB_0[3] = float4(-0.25,0.0,0.0,0.0);
    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.xy = in.acScreenNorm.xy * _resolution.xy;
    u_xlat13.x = float(int(u._Downsampling));
    u_xlat1.xy = u_xlat1.xy / u_xlat13.xx;
    u_xlatu1.xy = uint2(u_xlat1.xy);
    u_xlat2.xy = float2(u_xlatu1.xy);
    u_xlat2.xy = u_xlat2.xy + float2(0.5, 0.5);
    u_xlat13.xy = u_xlat13.xx * u_xlat2.xy;
    u_xlat13.xy = u_xlat13.xy / _resolution.xy;
    u_xlati7 = int(int_bitfieldInsert(0, int(u_xlatu1.y), 1 & int(0x1F), 1));
    u_xlati1 = int(int_bitfieldInsert(u_xlati7, int(u_xlatu1.x), 0 & int(0x1F), 1));
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat13.xy);
    u_xlat1.xyz = ImmCB_0[u_xlati1].xxx * float3(u._Dithering) + u_xlat2.xyz;
    u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
    u_xlat19 = dot(float3(0.412221462, 0.536332548, 0.0514459945), u_xlat1.xyz);
    u_xlat3.x = dot(float3(0.211903498, 0.680699527, 0.10739696), u_xlat1.xyz);
    u_xlat1.x = dot(float3(0.0883024633, 0.28171885, 0.629978716), u_xlat1.xyz);
    u_xlat4.x = log2(u_xlat19);
    u_xlat4.y = log2(u_xlat3.x);
    u_xlat4.z = log2(u_xlat1.x);
    u_xlat1.xyz = u_xlat4.xyz * float3(0.333333343, 0.333333343, 0.333333343);
    u_xlat1.xyz = exp2(u_xlat1.xyz);
    u_xlat3.x = dot(float3(0.210454255, 0.793617785, -0.00407204684), u_xlat1.xyz);
    u_xlat3.y = dot(float3(1.9779985, -2.42859221, 0.45059371), u_xlat1.xyz);
    u_xlat3.z = dot(float3(0.0259040371, 0.782771766, -0.808675766), u_xlat1.xyz);
    u_xlat1.xyz = u_xlat3.xyz + (-_PaletteLab[0].xyz);
    u_xlat1.x = dot(u_xlat1.xyz, u_xlat1.xyz);
    u_xlat7.xyz = u_xlat3.xyz + (-_PaletteLab[1].xyz);
    u_xlat7.x = dot(u_xlat7.xyz, u_xlat7.xyz);
    u_xlatb13 = u_xlat7.x<u_xlat1.x;
    u_xlat4.xyz = (bool(u_xlatb13)) ? _PaletteRGB[1].xyz : _PaletteRGB[0].xyz;
    u_xlat1.x = min(u_xlat7.x, u_xlat1.x);
    u_xlat7.xyz = u_xlat3.xyz + (-_PaletteLab[2].xyz);
    u_xlat7.x = dot(u_xlat7.xyz, u_xlat7.xyz);
    u_xlatb13 = u_xlat7.x<u_xlat1.x;
    u_xlat4.xyz = (bool(u_xlatb13)) ? _PaletteRGB[2].xyz : u_xlat4.xyz;
    u_xlat1.x = min(u_xlat7.x, u_xlat1.x);
    u_xlat7.xyz = u_xlat3.xyz + (-_PaletteLab[3].xyz);
    u_xlat7.x = dot(u_xlat7.xyz, u_xlat7.xyz);
    u_xlatb13 = u_xlat7.x<u_xlat1.x;
    u_xlat4.xyz = (bool(u_xlatb13)) ? _PaletteRGB[3].xyz : u_xlat4.xyz;
    u_xlat1.x = min(u_xlat7.x, u_xlat1.x);
    u_xlat7.xyz = u_xlat3.xyz + (-_PaletteLab[4].xyz);
    u_xlat7.x = dot(u_xlat7.xyz, u_xlat7.xyz);
    u_xlatb13 = u_xlat7.x<u_xlat1.x;
    u_xlat4.xyz = (bool(u_xlatb13)) ? _PaletteRGB[4].xyz : u_xlat4.xyz;
    u_xlat1.x = min(u_xlat7.x, u_xlat1.x);
    u_xlat7.xyz = u_xlat3.xyz + (-_PaletteLab[5].xyz);
    u_xlat7.x = dot(u_xlat7.xyz, u_xlat7.xyz);
    u_xlatb13 = u_xlat7.x<u_xlat1.x;
    u_xlat4.xyz = (bool(u_xlatb13)) ? _PaletteRGB[5].xyz : u_xlat4.xyz;
    u_xlat1.x = min(u_xlat7.x, u_xlat1.x);
    u_xlat7.xyz = u_xlat3.xyz + (-_PaletteLab[6].xyz);
    u_xlat7.x = dot(u_xlat7.xyz, u_xlat7.xyz);
    u_xlatb13 = u_xlat7.x<u_xlat1.x;
    u_xlat4.xyz = (bool(u_xlatb13)) ? _PaletteRGB[6].xyz : u_xlat4.xyz;
    u_xlat1.x = min(u_xlat7.x, u_xlat1.x);
    u_xlat7.xyz = u_xlat3.xyz + (-_PaletteLab[7].xyz);
    u_xlat7.x = dot(u_xlat7.xyz, u_xlat7.xyz);
    u_xlatb1 = u_xlat7.x<u_xlat1.x;
    u_xlat1.xyz = (bool(u_xlatb1)) ? _PaletteRGB[7].xyz : u_xlat4.xyz;
    u_xlat3.xyz = u_xlat1.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat3.xyz = u_xlat1.xyz * u_xlat3.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.xyz = u_xlat1.xyz * u_xlat3.xyz;
    u_xlat1 = (-u_xlat0) + u_xlat2;
    u_xlat1 = float4(float4(u._Opacity, u._Opacity, u._Opacity, u._Opacity)) * u_xlat1 + u_xlat0;
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
