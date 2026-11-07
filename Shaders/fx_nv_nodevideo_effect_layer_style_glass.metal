// ---------------------------------------------------------------------------
// Effect Layer Style Glass (NV)
// origem : assets/effects/nv-nodevideo-effect-layer-style-glass.xml
// id     : nv.effect.nodevideo-effect-layer-style-glass
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_layer_style_glassParams {
    float _glass_radius;
    float _glass_angle;
    float _glass_intensity;
    float _glass_elevation;
    float4 _glass_diffuse_color;
    float4 _glass_specular_color;
    float _glass_refraction;
    float _glass_shine;
    float _glass_specular;
    float _glass_fill;
};

// --- funcoes auxiliares do efeito
// ---- comum aos portes de classe C# do Node (tools/nodepassesc/comum.glsl, colado pelo montar.py) ----
// Os RTs do Node: cor PRÉ-multiplicada em luz LINEAR, sRGB de 8 bits, de pé (a linha 0 é a base). O Nova guarda a
// camada reta, em gama; no buffer de camada (`eng.acEntradaDePe` = 0) a linha 0 é o topo.
static float3 nvLinear(float3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c));
}
static float3 nvSrgb(float3 l) {
    l = clamp(l, 0.0, 1.0);
    return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l));
}
// O UV do Node (Y para cima) do pixel que este passe escreve na saída do Nova.
static float2 nvUvDePe() {
    return eng.acEntradaDePe == 1 ? in.acScreenNorm : float2(in.acScreenNorm.x, 1.0 - in.acScreenNorm.y);
}
// O texel da camada em `uv` do Node (de pé), como o RT do Node o guarda: linear × alfa.
static float4 nvFonte(float2 uv) {
    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 p = int2(clamp(floor(uv * float2(T)), float2(0.0), float2(T) - 1.0));
    if (eng.acEntradaDePe != 1) p.y = T.y - 1 - p.y;
    float4 c = inputImg.read(uint2(p), uint(0));
    return float4(nvLinear(c.rgb) * c.a, c.a);
}
// A camada lida com filtro linear em `uv` do Node, como o `_SourceTex.sample(__nv_smp, uv)` dele (o filtro em luz linear, a
// borda presa).
static float4 nvFonteFiltrada(float2 uv) {
    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float2 q = uv * float2(T) - 0.5;
    float2 f = fract(q);
    int2 b = int2(floor(q));
    float4 a00 = nvFonte((float2(b) + 0.5) / float2(T));
    float4 a10 = nvFonte((float2(b + int2(1, 0)) + 0.5) / float2(T));
    float4 a01 = nvFonte((float2(b + int2(0, 1)) + 0.5) / float2(T));
    float4 a11 = nvFonte((float2(b + int2(1, 1)) + 0.5) / float2(T));
    return mix(mix(a00, a10, f.x), mix(a01, a11, f.x), f.y);
}
// O RT de saída do Node (pré-multiplicado, linear, preso em 0..1 pelo ARGB32) de volta à cor reta em gama do Nova.
static float4 nvVolta(float4 o) {
    o = clamp(o, 0.0, 1.0);
    if (o.a <= 0.0) return float4(0.0);
    return float4(nvSrgb(o.rgb / o.a), o.a);
}
// ---- fim do comum ----
// O tamanho dos RTs do Node (o do buffer).
#define _resolution float2(int2(int(pre.get_width()), int(pre.get_height())))

// A cor de um controle como o Unity a entrega num projeto linear.
static float4 nvCor(float4 c) { return float4(nvLinear(c.rgb), c.a); }

// O fundo como o RT da composição no Node (linear × alfa), no pixel de `uv` do Node.
static float4 nvFundo(float2 uv) {
    int2 T = int2(int(fundo.get_width()), int(fundo.get_height()));
    int2 p = int2(clamp(floor(uv * float2(T)), float2(0.0), float2(T) - 1.0));
    if (eng.acEntradaDePe != 1) p.y = T.y - 1 - p.y;
    float4 c = fundo.read(uint2(p), uint(0));
    return float4(nvLinear(c.rgb) * c.a, c.a);
}

static float4 lerPre(float2 uv) { return pre.sample(__nv_smp, uv); }
static float4 lerComp(float2 uv) { return compNode.sample(__nv_smp, uv); }
static float4 lerDistVidro(float2 uv) { return distVidro.sample(__nv_smp, uv); }

// O programa 0 do shader NodeVideo/Effect/layer_style_glass do Node, conta por conta (tools/nodepassesc/montar.py).
static float4 distanciaVidro(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);
    float3 u_xlat0;
    int u_xlati0;
    float4 u_xlat1;
    int u_xlati1;
    bool u_xlatb1;
    float u_xlat2;
    float u_xlat3;
    float u_xlat4;
    bool u_xlatb4;
    int u_xlati5;
    float u_xlat6;
    int u_xlati6;
    float u_xlat7;
    bool u_xlatb7;
    float u_xlat8;
    bool u_xlatb8;
    float u_xlat9;

    u_xlat0.x = u._glass_radius * 100.0;
    u_xlat3 = dot(_resolution.xy, _resolution.xy);
    u_xlat3 = sqrt(u_xlat3);
    u_xlat0.x = u_xlat3 * u_xlat0.x;
    u_xlat0.xy = u_xlat0.xx * float2(0.000690533954, 0.00138106791);
    u_xlati0 = int(u_xlat0.x);
    u_xlati0 = max(u_xlati0, 1);
    u_xlati6 = 0 - u_xlati0;
    u_xlat9 = float(1.0) / _resolution.x;
    u_xlat1.yw = in.vs_TEXCOORD0.yy;
    u_xlat2 = 16383.0;
    for(int u_xlati_loop_1 = u_xlati6 ; u_xlati_loop_1<0 ; u_xlati_loop_1++)
    {
        u_xlat8 = float(u_xlati_loop_1);
        u_xlat1.x = u_xlat8 * u_xlat9 + in.vs_TEXCOORD0.x;
        u_xlat1.x = lerPre( u_xlat1.xy).w;
        u_xlatb1 = u_xlat1.x<0.00300000003;
        u_xlat1.x = (u_xlatb1) ? abs(u_xlat8) : u_xlat0.y;
        u_xlat2 = min(u_xlat1.x, u_xlat2);
    }
    u_xlat6 = 16383.0;
    for(int u_xlati_loop_2 = 0 ; u_xlati_loop_2<u_xlati0 ; u_xlati_loop_2++)
    {
        u_xlat4 = float(u_xlati_loop_2);
        u_xlat1.z = u_xlat4 * u_xlat9 + in.vs_TEXCOORD0.x;
        u_xlat7 = lerPre( u_xlat1.zw).w;
        u_xlatb7 = u_xlat7<0.00300000003;
        u_xlat4 = (u_xlatb7) ? abs(u_xlat4) : u_xlat0.y;
        u_xlat6 = min(u_xlat6, u_xlat4);
    }
    u_xlat0.xy = float2(u_xlat2) * float2(6.10388815e-05, 0.0155649148);
    u_xlat0.xy = fract(u_xlat0.xy);
    SV_Target0.x = (-u_xlat0.y) * 0.00392156886 + u_xlat0.x;
    u_xlat0.xz = float2(u_xlat6) * float2(6.10388815e-05, 0.0155649148);
    u_xlat0.xz = fract(u_xlat0.xz);
    SV_Target0.z = (-u_xlat0.z) * 0.00392156886 + u_xlat0.x;
    SV_Target0.yw = u_xlat0.yz;
    return SV_Target0;
    return SV_Target0;
}

// O programa 1 do shader NodeVideo/Effect/layer_style_glass do Node, conta por conta (tools/nodepassesc/montar.py).
static float4 vidro(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);
    float4 u_xlat0;
    float4 u_xlat1;
    bool2 u_xlatb1;
    float4 u_xlat2;
    int u_xlati2;
    bool u_xlatb2;
    float4 u_xlat3;
    float4 u_xlat4;
    bool u_xlatb4;
    float4 u_xlat5;
    float4 u_xlat6;
    float3 u_xlat7;
    float3 u_xlat8;
    float u_xlat9;
    float u_xlat10;
    float u_xlat14;
    int u_xlati15;
    float2 u_xlat16;
    float u_xlat21;
    float u_xlat22;
    int u_xlati22;
    float u_xlat24;

    u_xlat0.xw = (-float2(u._glass_shine, u._glass_elevation));
    u_xlat0.x = u_xlat0.x + 1.0;
    u_xlat0.x = u_xlat0.x * u._glass_intensity;
    u_xlat1.x = u._glass_shine * u._glass_intensity;
    u_xlat8.xy = float2(u._glass_radius, u._glass_angle) * float2(100.0, 0.0174532998);
    u_xlat22 = dot(_resolution.xy, _resolution.xy);
    u_xlat22 = sqrt(u_xlat22);
    u_xlat8.x = u_xlat22 * u_xlat8.x;
    u_xlat8.x = u_xlat8.x * 0.000690533954;
    u_xlati22 = int(u_xlat8.x);
    u_xlati22 = max(u_xlati22, 1);
    u_xlati2 = 0 - u_xlati22;
    u_xlat9 = float(1.0) / _resolution.y;
    u_xlat0.y = cos(u_xlat8.y);
    u_xlat0.z = sin((-u_xlat8.y));
    u_xlat3.xz = in.vs_TEXCOORD0.xx;
    u_xlat16.x = float(16383.0);
    u_xlat16.y = float(16383.0);
    for(int u_xlati_loop_1 = u_xlati2 ; u_xlati_loop_1<0 ; u_xlati_loop_1++)
    {
        u_xlat4.x = float(u_xlati_loop_1);
        u_xlat3.y = u_xlat4.x * u_xlat9 + in.vs_TEXCOORD0.y;
        u_xlat5 = lerDistVidro( u_xlat3.xy);
        u_xlat10 = dot(u_xlat5.xy, float2(1.0, 0.00392156886));
        u_xlat6.y = u_xlat10 * 16383.0;
        u_xlat10 = dot(u_xlat5.zw, float2(1.0, 0.00392156886));
        u_xlat6.x = u_xlat10 * 16383.0;
        u_xlat6.z = abs(u_xlat4.x);
        u_xlat10 = dot(u_xlat6.yz, u_xlat6.yz);
        u_xlat10 = sqrt(u_xlat10);
        u_xlat4.x = dot(u_xlat6.xz, u_xlat6.xz);
        u_xlat4.x = sqrt(u_xlat4.x);
        u_xlat16.x = min(u_xlat16.x, u_xlat10);
        u_xlat16.y = min(u_xlat16.y, u_xlat4.x);
    }
    u_xlat3.x = float(16383.0);
    u_xlat3.y = float(16383.0);
    for(int u_xlati_loop_2 = 0 ; u_xlati_loop_2<u_xlati22 ; u_xlati_loop_2++)
    {
        u_xlat2.x = float(u_xlati_loop_2);
        u_xlat3.w = u_xlat2.x * u_xlat9 + in.vs_TEXCOORD0.y;
        u_xlat4 = lerDistVidro( u_xlat3.zw);
        u_xlat24 = dot(u_xlat4.xy, float2(1.0, 0.00392156886));
        u_xlat5.y = u_xlat24 * 16383.0;
        u_xlat24 = dot(u_xlat4.zw, float2(1.0, 0.00392156886));
        u_xlat5.x = u_xlat24 * 16383.0;
        u_xlat5.z = abs(u_xlat2.x);
        u_xlat2.x = dot(u_xlat5.yz, u_xlat5.yz);
        u_xlat2.x = sqrt(u_xlat2.x);
        u_xlat24 = dot(u_xlat5.xz, u_xlat5.xz);
        u_xlat24 = sqrt(u_xlat24);
        u_xlat3.x = min(u_xlat2.x, u_xlat3.x);
        u_xlat3.y = min(u_xlat24, u_xlat3.y);
    }
    u_xlat3 = u_xlat3.xxyy;
    u_xlat4 = lerPre( in.vs_TEXCOORD0.xy);
    u_xlat3 = u_xlat3 / u_xlat8.xxxx;
    u_xlat3 = clamp(u_xlat3, 0.0, 1.0);
    u_xlat5 = u_xlat3.yyww * float4(-2.0, -2.0, -2.0, -2.0) + float4(3.0, 3.0, 3.0, 3.0);
    u_xlat3 = u_xlat3 * u_xlat3;
    u_xlat3 = u_xlat3 * u_xlat5;
    u_xlat8.xy = u_xlat16.xy / u_xlat8.xx;
    u_xlat8.xy = clamp(u_xlat8.xy, 0.0, 1.0);
    u_xlat2.xy = u_xlat8.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
    u_xlat8.xy = u_xlat8.xy * u_xlat8.xy;
    u_xlat8.xy = u_xlat8.xy * u_xlat2.xy;
    u_xlat8.xyz = u_xlat8.yyy * float3(1.0, -1.0, -1.0) + (-u_xlat8.xxx);
    u_xlat8.xyz = u_xlat3.xyx * float3(-1.0, 1.0, -1.0) + u_xlat8.xyz;
    u_xlat8.xyz = u_xlat3.zzw * float3(1.0, 1.0, -1.0) + u_xlat8.xyz;
    u_xlat8.xyz = u_xlat8.xyz * float3(0.25, 0.25, 0.25);
    u_xlat2.xy = u_xlat8.xy * float2(u._glass_refraction) + in.vs_TEXCOORD0.xy;
    u_xlat2 = lerComp( u_xlat2.xy);
    u_xlat3.x = dot(u_xlat8.xyz, u_xlat8.xyz);
    u_xlat3.x = rsqrt(u_xlat3.x);
    u_xlat8.xyz = u_xlat8.xyz * u_xlat3.xxx;
    u_xlat3.x = dot(u_xlat0.yzw, u_xlat0.yzw);
    u_xlat3.x = rsqrt(u_xlat3.x);
    u_xlat7.xyz = u_xlat0.yzw * u_xlat3.xxx;
    u_xlat7.x = dot(u_xlat8.xyz, u_xlat7.xyz);
    u_xlat14 = u._glass_specular * 10.0;
    u_xlat21 = log2(u_xlat7.x);
    u_xlat14 = u_xlat21 * u_xlat14;
    u_xlat14 = exp2(u_xlat14);
    u_xlat8.xyz = nvCor(u._glass_specular_color).xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat8.xyz = nvCor(u._glass_specular_color).xyz * u_xlat8.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat8.xyz = u_xlat8.xyz * nvCor(u._glass_specular_color).xyz;
    u_xlat3.xyz = nvCor(u._glass_diffuse_color).xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat3.xyz = nvCor(u._glass_diffuse_color).xyz * u_xlat3.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat3.xyz = u_xlat3.xyz * nvCor(u._glass_diffuse_color).xyz;
    u_xlat5.xyz = float3(u_xlat14) * u_xlat8.xyz;
    u_xlat5.w = u_xlat14 * nvCor(u._glass_specular_color).w;
    u_xlat1 = u_xlat1.xxxx * u_xlat5;
    u_xlat5 = u_xlat4.wwww * u_xlat1;
    u_xlat3.xyz = u_xlat7.xxx * u_xlat3.xyz;
    u_xlat3.w = u_xlat7.x * nvCor(u._glass_diffuse_color).w;
    u_xlat0 = u_xlat0.xxxx * u_xlat3;
    u_xlat3 = u_xlat4.wwww * u_xlat0;
    u_xlat6 = u_xlat4 * float4(float4(u._glass_fill, u._glass_fill, u._glass_fill, u._glass_fill));
    u_xlat2 = u_xlat4.wwww * u_xlat2;
    u_xlat0.x = (-u_xlat4.w) * u._glass_fill + 1.0;
    u_xlat2 = u_xlat2 * u_xlat0.xxxx + u_xlat6;
    u_xlat0.x = (-u_xlat0.w) * u_xlat4.w + 1.0;
    u_xlat0 = u_xlat2 * u_xlat0.xxxx + u_xlat3;
    u_xlat1.x = (-u_xlat1.w) * u_xlat4.w + 1.0;
    u_xlat0 = u_xlat0 * u_xlat1.xxxx + u_xlat5;
    if(0 != 0) {
        u_xlatb1.xy = equal(int4(0, 0, 0, 0), int4(1, 1, 0, 0)).xy;
        u_xlat2 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat3 = lerPre( in.vs_TEXCOORD0.xy);
        u_xlat5 = (-u_xlat3) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat4 = u_xlat4 * u_xlat5;
        u_xlat2 = u_xlat2 * u_xlat3 + u_xlat4;
        u_xlat1.x = u_xlat3.x * u_xlat2.w;
        SV_Target0.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat2.w;
        SV_Target0.xyz = u_xlat2.xyz;
    } else {
        SV_Target0 = u_xlat0;
    }
    return SV_Target0;
    return SV_Target0;
}

fragment float4 fx_nv_nodevideo_effect_layer_style_glass(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_layer_style_glassParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> fundo [[texture(1)]],
    texture2d<float> pre [[texture(2)]],
    texture2d<float> compNode [[texture(3)]],
    texture2d<float> distVidro [[texture(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = nvFonte(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = nvFundo(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = distanciaVidro(in.acScreenNorm); return __nv_out; }
    __nv_out = nvVolta(vidro(nvUvDePe()));
    return __nv_out;
}
