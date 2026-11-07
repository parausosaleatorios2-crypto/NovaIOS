// ---------------------------------------------------------------------------
// Effect Layer Styles2 (NV)
// origem : assets/effects/nv-nodevideo-effect-layer-styles2.xml
// id     : nv.effect.nodevideo-effect-layer-styles2
// passes : 13
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_layer_styles2Params {
    int _fill_type;
    int _fill_blend_mode;
    float4 _fill_color;
    float2 _fill_center;
    int _gradient_type;
    float4 _gradient_color1;
    float4 _gradient_color2;
    int _gradient_axis;
    float _gradient_start;
    float2 _gradient_offset;
    float _gradient_rotation;
    int _outline_enabled;
    float _outline_size;
    float4 _outline_inner_color;
    float4 _outline_outer_color;
    int _glow_enabled;
    float4 _glow_color;
    float _glow_radius;
    float _glow_intensity;
    int _glow_inner_enabled;
    float4 _glow_inner_color;
    float _glow_inner_radius;
    float _glow_inner_intensity;
    int _shadow_enabled;
    float4 _shadow_color;
    float2 _shadow_offset;
    float _shadow_blur;
    float _shadow_intensity;
    float _shadow_opacity;
    int _long_shadow_enabled;
    float4 _long_shadow_color;
    float _long_shadow_angle;
    float _long_shadow_length;
    float _long_shadow_blur;
    float _long_shadow_fade;
    int _bevel_enabled;
    float _bevel_radius;
    float4 _bevel_specular_color;
    float4 _bevel_diffuse_color;
    float _bevel_specular_intensity;
    float _bevel_diffuse_intensity;
    float _bevel_specular_angle;
    float _bevel_diffuse_angle;
    int _glass_enabled;
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
float3 nvLinear(float3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c));
}
float3 nvSrgb(float3 l) {
    l = clamp(l, 0.0, 1.0);
    return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l));
}
// O UV do Node (Y para cima) do pixel que este passe escreve na saída do Nova.
float2 nvUvDePe() {
    return eng.acEntradaDePe == 1 ? in.acScreenNorm : float2(in.acScreenNorm.x, 1.0 - in.acScreenNorm.y);
}
// O texel da camada em `uv` do Node (de pé), como o RT do Node o guarda: linear × alfa.
float4 nvFonte(float2 uv) {
    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 p = int2(clamp(floor(uv * float2(T)), float2(0.0), float2(T) - 1.0));
    if (eng.acEntradaDePe != 1) p.y = T.y - 1 - p.y;
    float4 c = inputImg.read(uint2(p), uint(0));
    return float4(nvLinear(c.rgb) * c.a, c.a);
}
// A camada lida com filtro linear em `uv` do Node, como o `_SourceTex.sample(__nv_smp, uv)` dele (o filtro em luz linear, a
// borda presa).
float4 nvFonteFiltrada(float2 uv) {
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
float4 nvVolta(float4 o) {
    o = clamp(o, 0.0, 1.0);
    if (o.a <= 0.0) return float4(0.0);
    return float4(nvSrgb(o.rgb / o.a), o.a);
}
// ---- fim do comum ----
// O tamanho dos RTs do Node (o do buffer; ver o cabeçalho).
#define _resolution float2(int2(int(pre.get_width()), int(pre.get_height())))
#define _old_version 0
// `_blur_amount` do DoGaussianBlur da sombra: Desfoque × 0,4 (projeto novo).
#define _blur_amount (u._shadow_blur * 0.400000006)

// A cor de um controle como o Unity a entrega num projeto linear.
float4 nvCor(float4 c) { return float4(nvLinear(c.rgb), c.a); }

// O fundo como o RT da composição no Node (linear × alfa), no pixel de `uv` do Node.
float4 nvFundo(float2 uv) {
    int2 T = int2(int(fundo.get_width()), int(fundo.get_height()));
    int2 p = int2(clamp(floor(uv * float2(T)), float2(0.0), float2(T) - 1.0));
    if (eng.acEntradaDePe != 1) p.y = T.y - 1 - p.y;
    float4 c = fundo.read(uint2(p), uint(0));
    return float4(nvLinear(c.rgb) * c.a, c.a);
}

float4 lerPre(float2 uv) { return pre.sample(__nv_smp, uv); }
float4 lerDesfMeio(float2 uv) { return desfMeio.sample(__nv_smp, uv); }
float4 lerDesfH(float2 uv) { return desfH.sample(__nv_smp, uv); }
float4 lerDesfV(float2 uv) { return desfV.sample(__nv_smp, uv); }
// `_bluredTex`: abaixo de 0,0001 o DoGaussianBlur só copia a camada.
float4 lerDesfeito(float2 uv) { return _blur_amount < 9.99999975e-05 ? pre.sample(__nv_smp, uv) : desfeito.sample(__nv_smp, uv); }
float4 lerDistContorno(float2 uv) { return distContorno.sample(__nv_smp, uv); }
float4 lerDistChanfro(float2 uv) { return distChanfro.sample(__nv_smp, uv); }
float4 lerDistBrilho(float2 uv) { return distBrilho.sample(__nv_smp, uv); }
float4 lerDistBrilhoInt(float2 uv) { return distBrilhoInt.sample(__nv_smp, uv); }
float4 lerEstilizada(float2 uv) { return estilizada.sample(__nv_smp, uv); }
float4 lerComp(float2 uv) { return compNode.sample(__nv_smp, uv); }
float4 lerDistVidro(float2 uv) { return distVidro.sample(__nv_smp, uv); }

// O programa 0 do shader NodeVideo/Effect/gaussian_blur_auto do Node, conta por conta (tools/nodepassesc/montar.py).
float4 desfReduzir(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);


    SV_Target0 = lerPre( in.vs_TEXCOORD0.xy);
    return SV_Target0;
    return SV_Target0;
}

// O programa 1 do shader NodeVideo/Effect/gaussian_blur_auto do Node, conta por conta (tools/nodepassesc/montar.py).
float4 desfHorizontal(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);
    float u_xlat0;
    float3 u_xlat1;
    float4 u_xlat2;
    float3 u_xlat3;
    float2 u_xlat4;
    float4 u_xlat5;
    float3 u_xlat6;
    bool u_xlatb6;
    float4 u_xlat7;
    float4 u_xlat8;
    float u_xlat9;
    float u_xlat10;
    float2 u_xlat18;
    float2 u_xlat22;
    float u_xlat24;
    float u_xlat28;
    float u_xlat30;

    u_xlat0 = _resolution.x * 0.5;
    u_xlat9 = _blur_amount * 0.0474999994;
    u_xlat18.x = dot(_resolution.xy, _resolution.xy);
    u_xlat18.x = sqrt(u_xlat18.x);
    u_xlat9 = u_xlat18.x * u_xlat9;
    u_xlat0 = float(1.0) / u_xlat0;
    u_xlat18.xy = float2(u_xlat9) * float2(0.465990603, 1.16806519);
    u_xlat18.y = float(1.0) / u_xlat18.y;
    u_xlat18.x = u_xlat18.x * u_xlat18.x;
    u_xlat18.x = -0.5 / u_xlat18.x;
    u_xlat18.x = u_xlat18.x * 1.44269502;
    u_xlat18.x = exp2(u_xlat18.x);
    u_xlat1.z = u_xlat18.x * u_xlat18.x;
    u_xlat2 = lerDesfMeio( in.vs_TEXCOORD0.xy);
    u_xlat2 = u_xlat18.yyyy * u_xlat2;
    u_xlat3.z = u_xlat1.z;
    u_xlat4.y = 0.0;
    u_xlat5 = u_xlat2;
    u_xlat22.xy = u_xlat18.yx;
    u_xlat28 = u_xlat18.y;
    u_xlat30 = 1.0;
    while(true){
        u_xlatb6 = u_xlat9<u_xlat30;
        if(u_xlatb6){break;}
        u_xlat6.xy = float2(u_xlat30) + float2(1.0, 2.0);
        u_xlat1.xy = u_xlat22.xy;
        u_xlat3.xy = u_xlat1.yz * u_xlat1.xy;
        u_xlat24 = u_xlat3.x * 2.0 + u_xlat28;
        u_xlat22.xy = u_xlat3.yz * u_xlat3.xy;
        u_xlat28 = u_xlat22.x * 2.0 + u_xlat24;
        u_xlat1.x = u_xlat1.x * u_xlat1.y + u_xlat22.x;
        u_xlat10 = u_xlat22.x * u_xlat6.x;
        u_xlat10 = u_xlat30 * u_xlat3.x + u_xlat10;
        u_xlat10 = u_xlat10 / u_xlat1.x;
        u_xlat4.x = u_xlat0 * u_xlat10;
        u_xlat3.xy = (-u_xlat4.xy) + in.vs_TEXCOORD0.xy;
        u_xlat3.xy = clamp(u_xlat3.xy, 0.0, 1.0);
        u_xlat6.xz = u_xlat4.xy + in.vs_TEXCOORD0.xy;
        u_xlat6.xz = clamp(u_xlat6.xz, 0.0, 1.0);
        u_xlat7 = lerDesfMeio( u_xlat3.xy);
        u_xlat7 = u_xlat7 * u_xlat1.xxxx + u_xlat5;
        u_xlat8 = lerDesfMeio( u_xlat6.xz);
        u_xlat5 = u_xlat8 * u_xlat1.xxxx + u_xlat7;
        u_xlat30 = u_xlat6.y;
    }
    SV_Target0 = u_xlat5 / float4(u_xlat28);
    return SV_Target0;
    return SV_Target0;
}

// O programa 2 do shader NodeVideo/Effect/gaussian_blur_auto do Node, conta por conta (tools/nodepassesc/montar.py).
float4 desfVertical(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);
    float4 u_xlat0;
    float2 u_xlat1;
    bool u_xlatb1;
    float4 u_xlat2;
    float4 u_xlat3;
    float3 u_xlat4;
    float4 u_xlat5;
    float3 u_xlat6;
    float4 u_xlat7;
    float4 u_xlat8;
    float2 u_xlat9;
    float u_xlat11;
    float2 u_xlat19;
    float u_xlat27;
    float u_xlat29;
    float u_xlat31;
    bool u_xlatb31;

    u_xlat0.x = _blur_amount * 0.0474999994;
    u_xlat9.x = dot(_resolution.xy, _resolution.xy);
    u_xlat9.x = sqrt(u_xlat9.x);
    u_xlat0.x = u_xlat9.x * u_xlat0.x;
    u_xlat9.x = _resolution.y * 0.5;
    u_xlat1.y = float(1.0) / u_xlat9.x;
    u_xlat9.xy = u_xlat0.xx * float2(0.465990603, 1.16806519);
    u_xlat9.y = float(1.0) / u_xlat9.y;
    u_xlat9.x = u_xlat9.x * u_xlat9.x;
    u_xlat9.x = -0.5 / u_xlat9.x;
    u_xlat9.x = u_xlat9.x * 1.44269502;
    u_xlat9.x = exp2(u_xlat9.x);
    u_xlat2.z = u_xlat9.x * u_xlat9.x;
    u_xlat3 = lerDesfH( in.vs_TEXCOORD0.xy);
    u_xlat3 = u_xlat9.yyyy * u_xlat3;
    u_xlat4.z = u_xlat2.z;
    u_xlat1.x = 0.0;
    u_xlat5 = u_xlat3;
    u_xlat19.xy = u_xlat9.yx;
    u_xlat27 = u_xlat9.y;
    u_xlat29 = 1.0;
    while(true){
        u_xlatb31 = u_xlat0.x<u_xlat29;
        if(u_xlatb31){break;}
        u_xlat6.xy = float2(u_xlat29) + float2(1.0, 2.0);
        u_xlat2.xy = u_xlat19.xy;
        u_xlat4.xy = u_xlat2.yz * u_xlat2.xy;
        u_xlat31 = u_xlat4.x * 2.0 + u_xlat27;
        u_xlat19.xy = u_xlat4.yz * u_xlat4.xy;
        u_xlat27 = u_xlat19.x * 2.0 + u_xlat31;
        u_xlat2.x = u_xlat2.x * u_xlat2.y + u_xlat19.x;
        u_xlat11 = u_xlat19.x * u_xlat6.x;
        u_xlat11 = u_xlat29 * u_xlat4.x + u_xlat11;
        u_xlat11 = u_xlat11 / u_xlat2.x;
        u_xlat4.xy = (-float2(u_xlat11)) * u_xlat1.xy + in.vs_TEXCOORD0.xy;
        u_xlat4.xy = clamp(u_xlat4.xy, 0.0, 1.0);
        u_xlat6.xz = float2(u_xlat11) * u_xlat1.xy + in.vs_TEXCOORD0.xy;
        u_xlat6.xz = clamp(u_xlat6.xz, 0.0, 1.0);
        u_xlat7 = lerDesfH( u_xlat4.xy);
        u_xlat7 = u_xlat7 * u_xlat2.xxxx + u_xlat5;
        u_xlat8 = lerDesfH( u_xlat6.xz);
        u_xlat5 = u_xlat8 * u_xlat2.xxxx + u_xlat7;
        u_xlat29 = u_xlat6.y;
    }
    u_xlat0 = u_xlat5 / float4(u_xlat27);
    u_xlatb1 = 0.0>=_blur_amount;
    u_xlat2 = lerPre( in.vs_TEXCOORD0.xy);
    SV_Target0 = (bool(u_xlatb1)) ? u_xlat2 : u_xlat0;
    return SV_Target0;
    return SV_Target0;
}

// O programa 3 do shader NodeVideo/Effect/gaussian_blur_auto do Node, conta por conta (tools/nodepassesc/montar.py).
float4 desfVoltar(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);


    SV_Target0 = lerDesfV( in.vs_TEXCOORD0.xy);
    return SV_Target0;
    return SV_Target0;
}

// O programa 0 do shader NodeVideo/Effect/layer_styles2 do Node, conta por conta (tools/nodepassesc/montar.py).
float4 distanciaContorno(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);
    float2 u_xlat0;
    float u_xlat1;
    float4 u_xlat2;
    bool4 u_xlatb2;
    float2 u_xlat4;
    int u_xlati6;
    float u_xlat8;
    bool u_xlatb8;
    int u_xlati9;
    int u_xlati10;

    u_xlat0.x = min(_resolution.y, _resolution.x);
    u_xlat0.x = u_xlat0.x * u._outline_size;
    u_xlat0.xy = u_xlat0.xx * float2(0.100000001, 0.200000003);
    u_xlati6 = int(u_xlat0.x);
    u_xlati6 = max(u_xlati6, 1);
    u_xlati9 = 0 - u_xlati6;
    u_xlat1 = float(1.0) / _resolution.x;
    u_xlat2.y = in.vs_TEXCOORD0.y;
    u_xlat4.x = float(16383.0);
    u_xlat4.y = float(16383.0);
    for(int u_xlati_loop_1 = u_xlati9 ; u_xlati_loop_1<u_xlati6 ; u_xlati_loop_1++)
    {
        u_xlat8 = float(u_xlati_loop_1);
        u_xlat2.x = u_xlat8 * u_xlat1 + in.vs_TEXCOORD0.x;
        u_xlat2.x = lerPre( u_xlat2.xy).w;
        u_xlatb2.w = 0.0<u_xlat2.x;
        u_xlatb2.x = u_xlat2.x<0.00300000003;
        u_xlat2.x = (u_xlatb2.x) ? abs(float(u_xlat8)) : u_xlat0.y;
        u_xlat2.w = (u_xlatb2.w) ? abs(float(u_xlat8)) : u_xlat0.y;
        u_xlat4.xy = min(u_xlat4.xy, u_xlat2.wx);
    }
    SV_Target0.xy = u_xlat4.xy / u_xlat0.xx;
    SV_Target0.zw = float2(0.0, 1.0);
    return SV_Target0;
    return SV_Target0;
}

// O programa 1 do shader NodeVideo/Effect/layer_styles2 do Node, conta por conta (tools/nodepassesc/montar.py).
float4 distanciaChanfro(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);
    float3 u_xlat0;
    int u_xlati0;
    float4 u_xlat1;
    int u_xlati1;
    bool u_xlatb1;
    float u_xlat2;
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

    u_xlat0.x = min(_resolution.y, _resolution.x);
    u_xlat0.x = u_xlat0.x * u._bevel_radius;
    u_xlat0.xy = u_xlat0.xx * float2(0.100000001, 0.200000003);
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

// O programa 2 do shader NodeVideo/Effect/layer_styles2 do Node, conta por conta (tools/nodepassesc/montar.py).
float4 distanciaBrilho(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);
    float u_xlat0;
    float u_xlat1;
    float4 u_xlat2;
    bool4 u_xlatb2;
    float u_xlat3;
    float2 u_xlat4;
    int u_xlati6;
    float u_xlat8;
    bool u_xlatb8;
    int u_xlati9;
    int u_xlati10;

    u_xlat0 = min(_resolution.y, _resolution.x);
    u_xlat0 = u_xlat0 * u._glow_radius;
    u_xlat3 = u_xlat0 * 0.5;
    u_xlati6 = int(u_xlat3);
    u_xlati6 = max(u_xlati6, 1);
    u_xlati9 = 0 - u_xlati6;
    u_xlat1 = float(1.0) / _resolution.x;
    u_xlat2.y = in.vs_TEXCOORD0.y;
    u_xlat4.x = float(16383.0);
    u_xlat4.y = float(16383.0);
    for(int u_xlati_loop_1 = u_xlati9 ; u_xlati_loop_1<u_xlati6 ; u_xlati_loop_1++)
    {
        u_xlat8 = float(u_xlati_loop_1);
        u_xlat2.x = u_xlat8 * u_xlat1 + in.vs_TEXCOORD0.x;
        u_xlat2.x = lerPre( u_xlat2.xy).w;
        u_xlatb2.w = 0.0<u_xlat2.x;
        u_xlatb2.x = u_xlat2.x<0.00300000003;
        u_xlat2.x = (u_xlatb2.x) ? abs(float(u_xlat8)) : float(u_xlat0);
        u_xlat2.w = (u_xlatb2.w) ? abs(float(u_xlat8)) : float(u_xlat0);
        u_xlat4.xy = min(u_xlat4.xy, u_xlat2.wx);
    }
    SV_Target0.xy = u_xlat4.xy / float2(u_xlat3);
    SV_Target0.zw = float2(0.0, 1.0);
    return SV_Target0;
    return SV_Target0;
}

// O programa 3 do shader NodeVideo/Effect/layer_styles2 do Node, conta por conta (tools/nodepassesc/montar.py).
float4 distanciaBrilhoInterno(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);
    float u_xlat0;
    float u_xlat1;
    float4 u_xlat2;
    bool4 u_xlatb2;
    float u_xlat3;
    float2 u_xlat4;
    int u_xlati6;
    float u_xlat8;
    bool u_xlatb8;
    int u_xlati9;
    int u_xlati10;

    u_xlat0 = min(_resolution.y, _resolution.x);
    u_xlat0 = u_xlat0 * u._glow_inner_radius;
    u_xlat3 = u_xlat0 * 0.5;
    u_xlati6 = int(u_xlat3);
    u_xlati6 = max(u_xlati6, 1);
    u_xlati9 = 0 - u_xlati6;
    u_xlat1 = float(1.0) / _resolution.x;
    u_xlat2.y = in.vs_TEXCOORD0.y;
    u_xlat4.x = float(16383.0);
    u_xlat4.y = float(16383.0);
    for(int u_xlati_loop_1 = u_xlati9 ; u_xlati_loop_1<u_xlati6 ; u_xlati_loop_1++)
    {
        u_xlat8 = float(u_xlati_loop_1);
        u_xlat2.x = u_xlat8 * u_xlat1 + in.vs_TEXCOORD0.x;
        u_xlat2.x = lerPre( u_xlat2.xy).w;
        u_xlatb2.w = 0.0<u_xlat2.x;
        u_xlatb2.x = u_xlat2.x<0.00300000003;
        u_xlat2.x = (u_xlatb2.x) ? abs(float(u_xlat8)) : float(u_xlat0);
        u_xlat2.w = (u_xlatb2.w) ? abs(float(u_xlat8)) : float(u_xlat0);
        u_xlat4.xy = min(u_xlat4.xy, u_xlat2.wx);
    }
    SV_Target0.xy = u_xlat4.xy / float2(u_xlat3);
    SV_Target0.zw = float2(0.0, 1.0);
    return SV_Target0;
    return SV_Target0;
}

// O programa 4 do shader NodeVideo/Effect/layer_styles2 do Node, conta por conta (tools/nodepassesc/montar.py).
float4 estilos(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);
    float4 u_xlat0;
    float4 u_xlat1;
    bool4 u_xlatb1;
    float4 u_xlat2;
    float4 u_xlat3;
    int u_xlati3;
    bool u_xlatb3;
    float4 u_xlat4;
    int u_xlati4;
    float4 u_xlat5;
    int u_xlati5;
    bool4 u_xlatb5;
    float3 u_xlat6;
    bool2 u_xlatb6;
    float4 u_xlat7;
    float3 u_xlat8;
    float u_xlat10;
    int u_xlati10;
    float3 u_xlat12;
    float3 u_xlat13;
    int u_xlati13;
    bool u_xlatb13;
    float3 u_xlat14;
    float2 u_xlat19;
    int u_xlati19;
    bool u_xlatb19;
    float2 u_xlat21;
    int u_xlati21;
    float2 u_xlat22;
    bool u_xlatb22;
    float u_xlat23;
    float u_xlat24;
    bool u_xlatb24;
    float u_xlat28;
    int u_xlati28;
    bool u_xlatb28;
    float u_xlat30;
    int u_xlati30;
    bool u_xlatb30;
    float u_xlat31;
    bool u_xlatb31;
    float u_xlat32;
    bool u_xlatb32;

    u_xlat0 = lerPre( in.vs_TEXCOORD0.xy);
    u_xlatb1.x = u._fill_type==1;
    if(u_xlatb1.x){
        u_xlat1.xyz = nvCor(u._fill_color).xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
        u_xlat1.xyz = nvCor(u._fill_color).xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
        u_xlat1.xyz = u_xlat1.xyz * nvCor(u._fill_color).xyz;
        u_xlat2.w = u_xlat0.w * nvCor(u._fill_color).w;
        u_xlat1.xyz = max(u_xlat1.xyz, float3(0.0, 0.0, 0.0));
        u_xlat1.xyz = log2(u_xlat1.xyz);
        u_xlat1.xyz = u_xlat1.xyz * float3(0.416666657, 0.416666657, 0.416666657);
        u_xlat1.xyz = exp2(u_xlat1.xyz);
        u_xlat1.xyz = u_xlat1.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
        u_xlat1.xyz = max(u_xlat1.xyz, float3(0.0, 0.0, 0.0));
        u_xlat3.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
        u_xlat3.xyz = log2(u_xlat3.xyz);
        u_xlat3.xyz = u_xlat3.xyz * float3(0.416666657, 0.416666657, 0.416666657);
        u_xlat3.xyz = exp2(u_xlat3.xyz);
        u_xlat3.xyz = u_xlat3.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
        u_xlat3.xyz = max(u_xlat3.xyz, float3(0.0, 0.0, 0.0));
        if(u._fill_blend_mode == 0) {
            u_xlat28 = (-u_xlat0.w) * nvCor(u._fill_color).w + 1.0;
            u_xlat4.xyz = u_xlat3.xyz * float3(u_xlat28);
            u_xlat4.xyz = u_xlat1.xyz * u_xlat2.www + u_xlat4.xyz;
            u_xlati28 = int(0xFFFFFFFFu);
        } else {
            u_xlatb30 = u._fill_blend_mode==1;
            if(u_xlatb30){
                u_xlat30 = dot(in.vs_TEXCOORD0.xy, float2(12.9898005, 78.2330017));
                u_xlat30 = sin(u_xlat30);
                u_xlat30 = u_xlat30 * 43758.5469;
                u_xlat30 = fract(u_xlat30);
                u_xlatb30 = u_xlat2.w<u_xlat30;
                u_xlat4.xyz = (bool(u_xlatb30)) ? u_xlat3.xyz : u_xlat1.xyz;
                u_xlati28 = int(0xFFFFFFFFu);
            } else {
                u_xlatb30 = u._fill_blend_mode==2;
                if(u_xlatb30){
                    u_xlat5.xyz = u_xlat2.www * u_xlat3.xyz;
                    u_xlat4.xyz = min(u_xlat1.xyz, u_xlat5.xyz);
                    u_xlati28 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb30 = u._fill_blend_mode==3;
                    if(u_xlatb30){
                        u_xlat4.xyz = u_xlat1.xyz * u_xlat3.xyz;
                        u_xlati28 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb30 = u._fill_blend_mode==4;
                        if(u_xlatb30){
                            u_xlat5.xyz = (-u_xlat3.xyz) * u_xlat2.www + float3(1.0, 1.0, 1.0);
                            u_xlat5.xyz = u_xlat5.xyz / u_xlat1.xyz;
                            u_xlat4.xyz = (-u_xlat5.xyz) + float3(1.0, 1.0, 1.0);
                            u_xlati28 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb30 = u._fill_blend_mode==5;
                            if(u_xlatb30){
                                u_xlat5.xyz = u_xlat1.xyz + u_xlat3.xyz;
                                u_xlat4.xyz = u_xlat5.xyz + float3(-1.0, -1.0, -1.0);
                                u_xlati28 = int(0xFFFFFFFFu);
                            } else {
                                u_xlatb30 = u._fill_blend_mode==6;
                                if(u_xlatb30){
                                    u_xlat5.xyz = u_xlat2.www * u_xlat3.xyz;
                                    u_xlat6.xyz = u_xlat1.xyz * float3(0.212599993, 0.715200007, 0.0722000003);
                                    u_xlat30 = dot(u_xlat6.xyz, u_xlat6.xyz);
                                    u_xlat30 = sqrt(u_xlat30);
                                    u_xlat6.xyz = u_xlat5.xyz * float3(0.212599993, 0.715200007, 0.0722000003);
                                    u_xlat31 = dot(u_xlat6.xyz, u_xlat6.xyz);
                                    u_xlat31 = sqrt(u_xlat31);
                                    u_xlatb30 = u_xlat31<u_xlat30;
                                    u_xlat4.xyz = (bool(u_xlatb30)) ? u_xlat5.xyz : u_xlat1.xyz;
                                    u_xlati28 = int(0xFFFFFFFFu);
                                } else {
                                    u_xlatb30 = u._fill_blend_mode==7;
                                    if(u_xlatb30){
                                        u_xlat4.xyz = max(u_xlat1.xyz, u_xlat3.xyz);
                                        u_xlati28 = int(0xFFFFFFFFu);
                                    } else {
                                        u_xlatb30 = u._fill_blend_mode==8;
                                        if(u_xlatb30){
                                            u_xlat5.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
                                            u_xlat6.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                            u_xlat4.xyz = (-u_xlat5.xyz) * u_xlat6.xyz + float3(1.0, 1.0, 1.0);
                                            u_xlati28 = int(0xFFFFFFFFu);
                                        } else {
                                            u_xlatb30 = u._fill_blend_mode==9;
                                            if(u_xlatb30){
                                                u_xlat5.xyz = u_xlat2.www * u_xlat3.xyz;
                                                u_xlat6.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                                u_xlat4.xyz = u_xlat5.xyz / u_xlat6.xyz;
                                                u_xlati28 = int(0xFFFFFFFFu);
                                            } else {
                                                u_xlatb30 = u._fill_blend_mode==10;
                                                if(u_xlatb30){
                                                    u_xlat4.xyz = u_xlat3.xyz * u_xlat2.www + u_xlat1.xyz;
                                                    u_xlati28 = int(0xFFFFFFFFu);
                                                } else {
                                                    u_xlatb30 = u._fill_blend_mode==11;
                                                    if(u_xlatb30){
                                                        u_xlat5.xyz = u_xlat2.www * u_xlat3.xyz;
                                                        u_xlat6.xyz = u_xlat1.xyz * float3(0.212599993, 0.715200007, 0.0722000003);
                                                        u_xlat30 = dot(u_xlat6.xyz, u_xlat6.xyz);
                                                        u_xlat30 = sqrt(u_xlat30);
                                                        u_xlat6.xyz = u_xlat5.xyz * float3(0.212599993, 0.715200007, 0.0722000003);
                                                        u_xlat31 = dot(u_xlat6.xyz, u_xlat6.xyz);
                                                        u_xlat31 = sqrt(u_xlat31);
                                                        u_xlatb30 = u_xlat31<u_xlat30;
                                                        u_xlat4.xyz = (bool(u_xlatb30)) ? u_xlat1.xyz : u_xlat5.xyz;
                                                        u_xlati28 = int(0xFFFFFFFFu);
                                                    } else {
                                                        u_xlatb30 = u._fill_blend_mode==12;
                                                        if(u_xlatb30){
                                                            u_xlatb5.xyz = lessThan(u_xlat3.xyzx, float4(0.5, 0.5, 0.5, 0.0)).xyz;
                                                            u_xlat6.xyz = u_xlat3.xyz + u_xlat3.xyz;
                                                            u_xlat6.xyz = u_xlat1.xyz * u_xlat6.xyz;
                                                            u_xlat7.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                                            u_xlat7.xyz = u_xlat7.xyz + u_xlat7.xyz;
                                                            u_xlat8.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
                                                            u_xlat7.xyz = (-u_xlat7.xyz) * u_xlat8.xyz + float3(1.0, 1.0, 1.0);
                                                            u_xlat4.x = (u_xlatb5.x) ? u_xlat6.x : u_xlat7.x;
                                                            u_xlat4.y = (u_xlatb5.y) ? u_xlat6.y : u_xlat7.y;
                                                            u_xlat4.z = (u_xlatb5.z) ? u_xlat6.z : u_xlat7.z;
                                                            u_xlati28 = int(0xFFFFFFFFu);
                                                        } else {
                                                            u_xlatb30 = u._fill_blend_mode==13;
                                                            if(u_xlatb30){
                                                                u_xlat5.xyz = u_xlat1.xyz * u_xlat3.xyz;
                                                                u_xlat6.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
                                                                u_xlat7.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                                                u_xlat7.xyz = (-u_xlat6.xyz) * u_xlat7.xyz + float3(1.0, 1.0, 1.0);
                                                                u_xlat7.xyz = u_xlat3.xyz * u_xlat7.xyz;
                                                                u_xlat4.xyz = u_xlat6.xyz * u_xlat5.xyz + u_xlat7.xyz;
                                                                u_xlati28 = int(0xFFFFFFFFu);
                                                            } else {
                                                                u_xlatb30 = u._fill_blend_mode==14;
                                                                if(u_xlatb30){
                                                                    u_xlatb5.xyz = lessThan(float4(0.5, 0.5, 0.5, 0.0), u_xlat1.xyzx).xyz;
                                                                    u_xlat6.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
                                                                    u_xlat7.xyz = u_xlat1.xyz + float3(-0.5, -0.5, -0.5);
                                                                    u_xlat7.xyz = (-u_xlat7.xyz) * float3(2.0, 2.0, 2.0) + float3(1.0, 1.0, 1.0);
                                                                    u_xlat6.xyz = (-u_xlat6.xyz) * u_xlat7.xyz + float3(1.0, 1.0, 1.0);
                                                                    u_xlat6.xyz = min(u_xlat6.xyz, float3(1.0, 1.0, 1.0));
                                                                    u_xlat7.xyz = u_xlat1.xyz + u_xlat1.xyz;
                                                                    u_xlat7.xyz = u_xlat3.xyz * u_xlat7.xyz;
                                                                    u_xlat7.xyz = min(u_xlat7.xyz, float3(1.0, 1.0, 1.0));
                                                                    u_xlat4.x = (u_xlatb5.x) ? u_xlat6.x : u_xlat7.x;
                                                                    u_xlat4.y = (u_xlatb5.y) ? u_xlat6.y : u_xlat7.y;
                                                                    u_xlat4.z = (u_xlatb5.z) ? u_xlat6.z : u_xlat7.z;
                                                                    u_xlati28 = int(0xFFFFFFFFu);
                                                                } else {
                                                                    u_xlatb30 = u._fill_blend_mode==15;
                                                                    if(u_xlatb30){
                                                                        u_xlatb5.xyz = greaterThanEqual(float4(0.5, 0.5, 0.5, 0.0), u_xlat1.xyzx).xyz;
                                                                        u_xlat6.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
                                                                        u_xlat7.xyz = u_xlat1.xyz + u_xlat1.xyz;
                                                                        u_xlat6.xyz = u_xlat6.xyz / u_xlat7.xyz;
                                                                        u_xlat6.xyz = (-u_xlat6.xyz) + float3(1.0, 1.0, 1.0);
                                                                        u_xlat6.xyz = max(u_xlat6.xyz, float3(0.0, 0.0, 0.0));
                                                                        u_xlat7.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                                                        u_xlat7.xyz = u_xlat7.xyz + u_xlat7.xyz;
                                                                        u_xlat7.xyz = u_xlat3.xyz / u_xlat7.xyz;
                                                                        u_xlat7.xyz = min(u_xlat7.xyz, float3(1.0, 1.0, 1.0));
                                                                        u_xlat4.x = (u_xlatb5.x) ? u_xlat6.x : u_xlat7.x;
                                                                        u_xlat4.y = (u_xlatb5.y) ? u_xlat6.y : u_xlat7.y;
                                                                        u_xlat4.z = (u_xlatb5.z) ? u_xlat6.z : u_xlat7.z;
                                                                        u_xlati28 = int(0xFFFFFFFFu);
                                                                    } else {
                                                                        u_xlatb30 = u._fill_blend_mode==16;
                                                                        if(u_xlatb30){
                                                                            u_xlatb5.xyz = greaterThanEqual(float4(0.5, 0.5, 0.5, 0.0), u_xlat1.xyzx).xyz;
                                                                            u_xlat6.xyz = u_xlat1.xyz * float3(2.0, 2.0, 2.0) + u_xlat3.xyz;
                                                                            u_xlat6.xyz = u_xlat6.xyz + float3(-1.0, -1.0, -1.0);
                                                                            u_xlat7.xyz = u_xlat1.xyz + float3(-0.5, -0.5, -0.5);
                                                                            u_xlat7.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat3.xyz;
                                                                            u_xlat4.x = (u_xlatb5.x) ? u_xlat6.x : u_xlat7.x;
                                                                            u_xlat4.y = (u_xlatb5.y) ? u_xlat6.y : u_xlat7.y;
                                                                            u_xlat4.z = (u_xlatb5.z) ? u_xlat6.z : u_xlat7.z;
                                                                            u_xlati28 = int(0xFFFFFFFFu);
                                                                        } else {
                                                                            u_xlatb30 = u._fill_blend_mode==17;
                                                                            if(u_xlatb30){
                                                                                u_xlatb5.xyz = lessThan(float4(0.5, 0.5, 0.5, 0.0), u_xlat1.xyzx).xyz;
                                                                                u_xlat6.xyz = u_xlat1.xyz + float3(-0.5, -0.5, -0.5);
                                                                                u_xlat6.xyz = u_xlat6.xyz + u_xlat6.xyz;
                                                                                u_xlat6.xyz = max(u_xlat3.xyz, u_xlat6.xyz);
                                                                                u_xlat7.xyz = u_xlat1.xyz + u_xlat1.xyz;
                                                                                u_xlat7.xyz = min(u_xlat3.xyz, u_xlat7.xyz);
                                                                                u_xlat4.x = (u_xlatb5.x) ? u_xlat6.x : u_xlat7.x;
                                                                                u_xlat4.y = (u_xlatb5.y) ? u_xlat6.y : u_xlat7.y;
                                                                                u_xlat4.z = (u_xlatb5.z) ? u_xlat6.z : u_xlat7.z;
                                                                                u_xlati28 = int(0xFFFFFFFFu);
                                                                            } else {
                                                                                u_xlatb30 = u._fill_blend_mode==18;
                                                                                if(u_xlatb30){
                                                                                    u_xlat5.xyz = u_xlat1.xyz + u_xlat3.xyz;
                                                                                    u_xlatb5.xyz = lessThan(u_xlat5.xyzx, float4(1.0, 1.0, 1.0, 0.0)).xyz;
                                                                                    u_xlat4.x = (u_xlatb5.x) ? float(0.0) : float(1.0);
                                                                                    u_xlat4.y = (u_xlatb5.y) ? float(0.0) : float(1.0);
                                                                                    u_xlat4.z = (u_xlatb5.z) ? float(0.0) : float(1.0);
                                                                                    u_xlati28 = int(0xFFFFFFFFu);
                                                                                } else {
                                                                                    u_xlatb30 = u._fill_blend_mode==19;
                                                                                    if(u_xlatb30){
                                                                                        u_xlat4.xyz = u_xlat3.xyz * u_xlat2.www + (-u_xlat1.xyz);
                                                                                        u_xlat4.xyz = abs(u_xlat4.xyz);
                                                                                        u_xlati28 = int(0xFFFFFFFFu);
                                                                                    } else {
                                                                                        u_xlatb30 = u._fill_blend_mode==20;
                                                                                        if(u_xlatb30){
                                                                                            u_xlat5.xyz = u_xlat3.xyz * u_xlat2.www + float3(-0.5, -0.5, -0.5);
                                                                                            u_xlat5.xyz = u_xlat5.xyz + u_xlat5.xyz;
                                                                                            u_xlat6.xyz = u_xlat1.xyz + float3(-0.5, -0.5, -0.5);
                                                                                            u_xlat4.xyz = (-u_xlat5.xyz) * u_xlat6.xyz + float3(0.5, 0.5, 0.5);
                                                                                            u_xlati28 = int(0xFFFFFFFFu);
                                                                                        } else {
                                                                                            u_xlatb30 = u._fill_blend_mode==21;
                                                                                            if(u_xlatb30){
                                                                                                u_xlat4.xyz = (-u_xlat1.xyz) + u_xlat3.xyz;
                                                                                                u_xlati28 = int(0xFFFFFFFFu);
                                                                                            } else {
                                                                                                u_xlatb30 = u._fill_blend_mode==22;
                                                                                                if(u_xlatb30){
                                                                                                    u_xlat5.xyz = u_xlat2.www * u_xlat3.xyz;
                                                                                                    u_xlat4.xyz = u_xlat5.xyz / u_xlat1.xyz;
                                                                                                    u_xlati28 = int(0xFFFFFFFFu);
                                                                                                } else {
                                                                                                    u_xlatb30 = u._fill_blend_mode==23;
                                                                                                    if(u_xlatb30){
                                                                                                        u_xlat30 = min(u_xlat1.y, u_xlat1.x);
                                                                                                        u_xlat30 = min(u_xlat1.z, u_xlat30);
                                                                                                        u_xlat31 = max(u_xlat1.y, u_xlat1.x);
                                                                                                        u_xlat31 = max(u_xlat1.z, u_xlat31);
                                                                                                        u_xlat30 = (-u_xlat30) + u_xlat31;
                                                                                                        u_xlatb5.x = 9.99999975e-05<u_xlat30;
                                                                                                        u_xlat14.x = min(u_xlat3.y, u_xlat3.x);
                                                                                                        u_xlat14.x = min(u_xlat3.z, u_xlat14.x);
                                                                                                        u_xlat23 = max(u_xlat3.y, u_xlat3.x);
                                                                                                        u_xlat23 = max(u_xlat3.z, u_xlat23);
                                                                                                        u_xlat14.x = (-u_xlat14.x) + u_xlat23;
                                                                                                        u_xlatb32 = float4(0.0, 0.0, 0.0, 0.0)!=float4(u_xlat23);
                                                                                                        u_xlat14.x = u_xlat14.x / u_xlat23;
                                                                                                        u_xlat14.x = u_xlatb32 ? u_xlat14.x : float(0.0);
                                                                                                        u_xlat14.x = u_xlat23 * u_xlat14.x;
                                                                                                        u_xlat30 = u_xlat14.x / u_xlat30;
                                                                                                        u_xlat31 = (-u_xlat31) * u_xlat30 + u_xlat23;
                                                                                                        u_xlat14.xyz = u_xlat1.xyz * float3(u_xlat30) + float3(u_xlat31);
                                                                                                        u_xlat4.xyz = (u_xlatb5.x) ? u_xlat14.xyz : u_xlat3.xyz;
                                                                                                        u_xlati28 = int(0xFFFFFFFFu);
                                                                                                    } else {
                                                                                                        u_xlatb30 = u._fill_blend_mode==24;
                                                                                                        if(u_xlatb30){
                                                                                                            u_xlat30 = min(u_xlat3.y, u_xlat3.x);
                                                                                                            u_xlat30 = min(u_xlat3.z, u_xlat30);
                                                                                                            u_xlat31 = max(u_xlat3.y, u_xlat3.x);
                                                                                                            u_xlat31 = max(u_xlat3.z, u_xlat31);
                                                                                                            u_xlat30 = (-u_xlat30) + u_xlat31;
                                                                                                            u_xlatb5.x = 9.99999975e-05<u_xlat30;
                                                                                                            u_xlat14.x = min(u_xlat1.y, u_xlat1.x);
                                                                                                            u_xlat14.x = min(u_xlat1.z, u_xlat14.x);
                                                                                                            u_xlat23 = max(u_xlat1.y, u_xlat1.x);
                                                                                                            u_xlat23 = max(u_xlat1.z, u_xlat23);
                                                                                                            u_xlat14.x = (-u_xlat14.x) + u_xlat23;
                                                                                                            u_xlatb32 = float4(0.0, 0.0, 0.0, 0.0)!=float4(u_xlat23);
                                                                                                            u_xlat14.x = u_xlat14.x / u_xlat23;
                                                                                                            u_xlat14.x = u_xlatb32 ? u_xlat14.x : float(0.0);
                                                                                                            u_xlat14.x = u_xlat31 * u_xlat14.x;
                                                                                                            u_xlat30 = u_xlat14.x / u_xlat30;
                                                                                                            u_xlat14.x = (-u_xlat30) + 1.0;
                                                                                                            u_xlat14.x = u_xlat31 * u_xlat14.x;
                                                                                                            u_xlat14.xyz = u_xlat3.xyz * float3(u_xlat30) + u_xlat14.xxx;
                                                                                                            u_xlat4.xyz = (u_xlatb5.x) ? u_xlat14.xyz : float3(u_xlat31);
                                                                                                            u_xlati28 = int(0xFFFFFFFFu);
                                                                                                        } else {
                                                                                                            u_xlat5.xyz = u_xlat2.www * u_xlat3.xyz;
                                                                                                            u_xlat6.x = dot(float3(0.298999995, 0.587000012, 0.114), u_xlat5.xyz);
                                                                                                            u_xlat6.y = dot(float3(-0.147129998, -0.288859993, 0.43599999), u_xlat1.xyz);
                                                                                                            u_xlat6.z = dot(float3(0.61500001, -0.514989972, -0.10001), u_xlat1.xyz);
                                                                                                            u_xlat7.x = dot(float2(1.0, 1.13982999), u_xlat6.xz);
                                                                                                            u_xlat7.y = dot(float3(1.0, -0.394650012, -0.580600023), u_xlat6.xyz);
                                                                                                            u_xlat7.z = dot(float2(1.0, 2.03210998), u_xlat6.xy);
                                                                                                            u_xlatb6.xy = equal(int4(int4(u._fill_blend_mode, u._fill_blend_mode, u._fill_blend_mode, u._fill_blend_mode)), int4(25, 26, 0, 0)).xy;
                                                                                                            u_xlat8.x = dot(float3(0.298999995, 0.587000012, 0.114), u_xlat1.xyz);
                                                                                                            u_xlat8.y = dot(float3(-0.147129998, -0.288859993, 0.43599999), u_xlat5.xyz);
                                                                                                            u_xlat8.z = dot(float3(0.61500001, -0.514989972, -0.10001), u_xlat5.xyz);
                                                                                                            u_xlat5.x = dot(float2(1.0, 1.13982999), u_xlat8.xz);
                                                                                                            u_xlat5.y = dot(float3(1.0, -0.394650012, -0.580600023), u_xlat8.xyz);
                                                                                                            u_xlat5.z = dot(float2(1.0, 2.03210998), u_xlat8.xy);
                                                                                                            u_xlat4.xyz = (u_xlatb6.x) ? u_xlat7.xyz : u_xlat5.xyz;
                                                                                                            u_xlati28 = int(uint((uint(u_xlatb6.y) * 0xffffffffu) | (uint(u_xlatb6.x) * 0xffffffffu)));
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        u_xlat30 = (-u_xlat0.w) * nvCor(u._fill_color).w + 1.0;
        u_xlat3.xyz = u_xlat3.xyz * float3(u_xlat30);
        u_xlat1.xyz = u_xlat1.xyz * u_xlat2.www + u_xlat3.xyz;
        u_xlat1.xyz = (int(u_xlati28) != 0) ? u_xlat4.xyz : u_xlat1.xyz;
        u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
        u_xlat3.xyz = u_xlat1.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
        u_xlat3.xyz = u_xlat1.xyz * u_xlat3.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
        u_xlat2.xyz = u_xlat1.xyz * u_xlat3.xyz;
    } else {
        u_xlatb1.x = u._fill_type==2;
        if(u_xlatb1.x){
            u_xlat1.xy = in.vs_TEXCOORD0.yx + float2(-0.5, -0.5);
            u_xlat19.xy = float2(u._fill_center.y, u._fill_center.x) + float2(-0.5, -0.5);
            u_xlat1.xy = (-u_xlat19.xy) + u_xlat1.xy;
            u_xlat1.xy = u_xlat1.xy * float2(eng.acProporcaoDoNode.y, eng.acProporcaoDoNode.x);
            u_xlat19.x = u._gradient_rotation * 0.0174532942;
            u_xlat3.x = sin(u_xlat19.x);
            u_xlat4.x = cos(u_xlat19.x);
            u_xlat19.xy = u_xlat1.xy * u_xlat3.xx;
            u_xlat3.x = u_xlat1.y * u_xlat4.x + (-u_xlat19.x);
            u_xlat3.y = u_xlat1.x * u_xlat4.x + u_xlat19.y;
            u_xlat1.xy = u_xlat3.xy + float2(u._gradient_offset.x, u._gradient_offset.y);
            u_xlat1.z = u._gradient_start + -0.5;
            u_xlat1.w = 0.5;
            u_xlat3.xyz = (u._gradient_axis != 0) ? u_xlat1.zwy : u_xlat1.zwx;
            u_xlatb19 = u._gradient_type==1;
            u_xlat4.xy = abs(u_xlat1.xy);
            u_xlat4.z = u._gradient_start * 0.5;
            u_xlat4.w = 0.5;
            u_xlat4.xyz = (u._gradient_axis != 0) ? u_xlat4.zwy : u_xlat4.zwx;
            u_xlat1.x = dot(u_xlat1.xy, u_xlat1.xy);
            u_xlat5.z = sqrt(u_xlat1.x);
            u_xlat5.x = u._gradient_start * 0.707106769;
            u_xlat5.y = 0.707106769;
            u_xlat1.xyz = (bool(u_xlatb19)) ? u_xlat4.xyz : u_xlat5.xyz;
            u_xlat1.xyz = (u._gradient_type != 0) ? u_xlat1.xyz : u_xlat3.xyz;
            u_xlatb28 = u_xlat1.z>=u_xlat1.x;
            u_xlatb3 = u_xlat1.x==u_xlat1.y;
            u_xlat1.xy = (-u_xlat1.xx) + u_xlat1.zy;
            u_xlat1.x = u_xlat1.x / u_xlat1.y;
            u_xlat12.xyz = (-nvCor(u._gradient_color1).xyz) + nvCor(u._gradient_color2).xyz;
            u_xlat1.xyz = u_xlat1.xxx * u_xlat12.xyz + nvCor(u._gradient_color1).xyz;
            u_xlat1.xyz = (bool(u_xlatb3)) ? nvCor(u._gradient_color2).xyz : u_xlat1.xyz;
            u_xlat1.xyz = (bool(u_xlatb28)) ? u_xlat1.xyz : nvCor(u._gradient_color1).xyz;
            u_xlat3.xyz = u_xlat1.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
            u_xlat3.xyz = u_xlat1.xyz * u_xlat3.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
            u_xlat1.xyz = u_xlat1.xyz * u_xlat3.xyz;
            u_xlat1.xyz = max(u_xlat1.xyz, float3(0.0, 0.0, 0.0));
            u_xlat1.xyz = log2(u_xlat1.xyz);
            u_xlat1.xyz = u_xlat1.xyz * float3(0.416666657, 0.416666657, 0.416666657);
            u_xlat1.xyz = exp2(u_xlat1.xyz);
            u_xlat1.xyz = u_xlat1.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
            u_xlat1.xyz = max(u_xlat1.xyz, float3(0.0, 0.0, 0.0));
            u_xlat3.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
            u_xlat3.xyz = log2(u_xlat3.xyz);
            u_xlat3.xyz = u_xlat3.xyz * float3(0.416666657, 0.416666657, 0.416666657);
            u_xlat3.xyz = exp2(u_xlat3.xyz);
            u_xlat3.xyz = u_xlat3.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
            u_xlat3.xyz = max(u_xlat3.xyz, float3(0.0, 0.0, 0.0));
            if(u._fill_blend_mode == 0) {
                u_xlat28 = (-u_xlat0.w) + 1.0;
                u_xlat4.xyz = u_xlat3.xyz * float3(u_xlat28);
                u_xlat4.xyz = u_xlat1.xyz * u_xlat0.www + u_xlat4.xyz;
                u_xlati28 = int(0xFFFFFFFFu);
            } else {
                u_xlatb30 = u._fill_blend_mode==1;
                if(u_xlatb30){
                    u_xlat30 = dot(in.vs_TEXCOORD0.xy, float2(12.9898005, 78.2330017));
                    u_xlat30 = sin(u_xlat30);
                    u_xlat30 = u_xlat30 * 43758.5469;
                    u_xlat30 = fract(u_xlat30);
                    u_xlatb30 = u_xlat0.w<u_xlat30;
                    u_xlat4.xyz = (bool(u_xlatb30)) ? u_xlat3.xyz : u_xlat1.xyz;
                    u_xlati28 = int(0xFFFFFFFFu);
                } else {
                    u_xlatb30 = u._fill_blend_mode==2;
                    if(u_xlatb30){
                        u_xlat5.xyz = u_xlat0.www * u_xlat3.xyz;
                        u_xlat4.xyz = min(u_xlat1.xyz, u_xlat5.xyz);
                        u_xlati28 = int(0xFFFFFFFFu);
                    } else {
                        u_xlatb30 = u._fill_blend_mode==3;
                        if(u_xlatb30){
                            u_xlat4.xyz = u_xlat1.xyz * u_xlat3.xyz;
                            u_xlati28 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb30 = u._fill_blend_mode==4;
                            if(u_xlatb30){
                                u_xlat5.xyz = (-u_xlat3.xyz) * u_xlat0.www + float3(1.0, 1.0, 1.0);
                                u_xlat5.xyz = u_xlat5.xyz / u_xlat1.xyz;
                                u_xlat4.xyz = (-u_xlat5.xyz) + float3(1.0, 1.0, 1.0);
                                u_xlati28 = int(0xFFFFFFFFu);
                            } else {
                                u_xlatb30 = u._fill_blend_mode==5;
                                if(u_xlatb30){
                                    u_xlat5.xyz = u_xlat1.xyz + u_xlat3.xyz;
                                    u_xlat4.xyz = u_xlat5.xyz + float3(-1.0, -1.0, -1.0);
                                    u_xlati28 = int(0xFFFFFFFFu);
                                } else {
                                    u_xlatb30 = u._fill_blend_mode==6;
                                    if(u_xlatb30){
                                        u_xlat5.xyz = u_xlat0.www * u_xlat3.xyz;
                                        u_xlat6.xyz = u_xlat1.xyz * float3(0.212599993, 0.715200007, 0.0722000003);
                                        u_xlat30 = dot(u_xlat6.xyz, u_xlat6.xyz);
                                        u_xlat30 = sqrt(u_xlat30);
                                        u_xlat6.xyz = u_xlat5.xyz * float3(0.212599993, 0.715200007, 0.0722000003);
                                        u_xlat31 = dot(u_xlat6.xyz, u_xlat6.xyz);
                                        u_xlat31 = sqrt(u_xlat31);
                                        u_xlatb30 = u_xlat31<u_xlat30;
                                        u_xlat4.xyz = (bool(u_xlatb30)) ? u_xlat5.xyz : u_xlat1.xyz;
                                        u_xlati28 = int(0xFFFFFFFFu);
                                    } else {
                                        u_xlatb30 = u._fill_blend_mode==7;
                                        if(u_xlatb30){
                                            u_xlat4.xyz = max(u_xlat1.xyz, u_xlat3.xyz);
                                            u_xlati28 = int(0xFFFFFFFFu);
                                        } else {
                                            u_xlatb30 = u._fill_blend_mode==8;
                                            if(u_xlatb30){
                                                u_xlat5.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
                                                u_xlat6.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                                u_xlat4.xyz = (-u_xlat5.xyz) * u_xlat6.xyz + float3(1.0, 1.0, 1.0);
                                                u_xlati28 = int(0xFFFFFFFFu);
                                            } else {
                                                u_xlatb30 = u._fill_blend_mode==9;
                                                if(u_xlatb30){
                                                    u_xlat5.xyz = u_xlat0.www * u_xlat3.xyz;
                                                    u_xlat6.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                                    u_xlat4.xyz = u_xlat5.xyz / u_xlat6.xyz;
                                                    u_xlati28 = int(0xFFFFFFFFu);
                                                } else {
                                                    u_xlatb30 = u._fill_blend_mode==10;
                                                    if(u_xlatb30){
                                                        u_xlat4.xyz = u_xlat3.xyz * u_xlat0.www + u_xlat1.xyz;
                                                        u_xlati28 = int(0xFFFFFFFFu);
                                                    } else {
                                                        u_xlatb30 = u._fill_blend_mode==11;
                                                        if(u_xlatb30){
                                                            u_xlat5.xyz = u_xlat0.www * u_xlat3.xyz;
                                                            u_xlat6.xyz = u_xlat1.xyz * float3(0.212599993, 0.715200007, 0.0722000003);
                                                            u_xlat30 = dot(u_xlat6.xyz, u_xlat6.xyz);
                                                            u_xlat30 = sqrt(u_xlat30);
                                                            u_xlat6.xyz = u_xlat5.xyz * float3(0.212599993, 0.715200007, 0.0722000003);
                                                            u_xlat31 = dot(u_xlat6.xyz, u_xlat6.xyz);
                                                            u_xlat31 = sqrt(u_xlat31);
                                                            u_xlatb30 = u_xlat31<u_xlat30;
                                                            u_xlat4.xyz = (bool(u_xlatb30)) ? u_xlat1.xyz : u_xlat5.xyz;
                                                            u_xlati28 = int(0xFFFFFFFFu);
                                                        } else {
                                                            u_xlatb30 = u._fill_blend_mode==12;
                                                            if(u_xlatb30){
                                                                u_xlatb5.xyz = lessThan(u_xlat3.xyzx, float4(0.5, 0.5, 0.5, 0.0)).xyz;
                                                                u_xlat6.xyz = u_xlat3.xyz + u_xlat3.xyz;
                                                                u_xlat6.xyz = u_xlat1.xyz * u_xlat6.xyz;
                                                                u_xlat7.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                                                u_xlat7.xyz = u_xlat7.xyz + u_xlat7.xyz;
                                                                u_xlat8.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
                                                                u_xlat7.xyz = (-u_xlat7.xyz) * u_xlat8.xyz + float3(1.0, 1.0, 1.0);
                                                                u_xlat4.x = (u_xlatb5.x) ? u_xlat6.x : u_xlat7.x;
                                                                u_xlat4.y = (u_xlatb5.y) ? u_xlat6.y : u_xlat7.y;
                                                                u_xlat4.z = (u_xlatb5.z) ? u_xlat6.z : u_xlat7.z;
                                                                u_xlati28 = int(0xFFFFFFFFu);
                                                            } else {
                                                                u_xlatb30 = u._fill_blend_mode==13;
                                                                if(u_xlatb30){
                                                                    u_xlat5.xyz = u_xlat1.xyz * u_xlat3.xyz;
                                                                    u_xlat6.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
                                                                    u_xlat7.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                                                    u_xlat7.xyz = (-u_xlat6.xyz) * u_xlat7.xyz + float3(1.0, 1.0, 1.0);
                                                                    u_xlat7.xyz = u_xlat3.xyz * u_xlat7.xyz;
                                                                    u_xlat4.xyz = u_xlat6.xyz * u_xlat5.xyz + u_xlat7.xyz;
                                                                    u_xlati28 = int(0xFFFFFFFFu);
                                                                } else {
                                                                    u_xlatb30 = u._fill_blend_mode==14;
                                                                    if(u_xlatb30){
                                                                        u_xlatb5.xyz = lessThan(float4(0.5, 0.5, 0.5, 0.0), u_xlat1.xyzx).xyz;
                                                                        u_xlat6.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
                                                                        u_xlat7.xyz = u_xlat1.xyz + float3(-0.5, -0.5, -0.5);
                                                                        u_xlat7.xyz = (-u_xlat7.xyz) * float3(2.0, 2.0, 2.0) + float3(1.0, 1.0, 1.0);
                                                                        u_xlat6.xyz = (-u_xlat6.xyz) * u_xlat7.xyz + float3(1.0, 1.0, 1.0);
                                                                        u_xlat6.xyz = min(u_xlat6.xyz, float3(1.0, 1.0, 1.0));
                                                                        u_xlat7.xyz = u_xlat1.xyz + u_xlat1.xyz;
                                                                        u_xlat7.xyz = u_xlat3.xyz * u_xlat7.xyz;
                                                                        u_xlat7.xyz = min(u_xlat7.xyz, float3(1.0, 1.0, 1.0));
                                                                        u_xlat4.x = (u_xlatb5.x) ? u_xlat6.x : u_xlat7.x;
                                                                        u_xlat4.y = (u_xlatb5.y) ? u_xlat6.y : u_xlat7.y;
                                                                        u_xlat4.z = (u_xlatb5.z) ? u_xlat6.z : u_xlat7.z;
                                                                        u_xlati28 = int(0xFFFFFFFFu);
                                                                    } else {
                                                                        u_xlatb30 = u._fill_blend_mode==15;
                                                                        if(u_xlatb30){
                                                                            u_xlatb5.xyz = greaterThanEqual(float4(0.5, 0.5, 0.5, 0.0), u_xlat1.xyzx).xyz;
                                                                            u_xlat6.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
                                                                            u_xlat7.xyz = u_xlat1.xyz + u_xlat1.xyz;
                                                                            u_xlat6.xyz = u_xlat6.xyz / u_xlat7.xyz;
                                                                            u_xlat6.xyz = (-u_xlat6.xyz) + float3(1.0, 1.0, 1.0);
                                                                            u_xlat6.xyz = max(u_xlat6.xyz, float3(0.0, 0.0, 0.0));
                                                                            u_xlat7.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
                                                                            u_xlat7.xyz = u_xlat7.xyz + u_xlat7.xyz;
                                                                            u_xlat7.xyz = u_xlat3.xyz / u_xlat7.xyz;
                                                                            u_xlat7.xyz = min(u_xlat7.xyz, float3(1.0, 1.0, 1.0));
                                                                            u_xlat4.x = (u_xlatb5.x) ? u_xlat6.x : u_xlat7.x;
                                                                            u_xlat4.y = (u_xlatb5.y) ? u_xlat6.y : u_xlat7.y;
                                                                            u_xlat4.z = (u_xlatb5.z) ? u_xlat6.z : u_xlat7.z;
                                                                            u_xlati28 = int(0xFFFFFFFFu);
                                                                        } else {
                                                                            u_xlatb30 = u._fill_blend_mode==16;
                                                                            if(u_xlatb30){
                                                                                u_xlatb5.xyz = greaterThanEqual(float4(0.5, 0.5, 0.5, 0.0), u_xlat1.xyzx).xyz;
                                                                                u_xlat6.xyz = u_xlat1.xyz * float3(2.0, 2.0, 2.0) + u_xlat3.xyz;
                                                                                u_xlat6.xyz = u_xlat6.xyz + float3(-1.0, -1.0, -1.0);
                                                                                u_xlat7.xyz = u_xlat1.xyz + float3(-0.5, -0.5, -0.5);
                                                                                u_xlat7.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat3.xyz;
                                                                                u_xlat4.x = (u_xlatb5.x) ? u_xlat6.x : u_xlat7.x;
                                                                                u_xlat4.y = (u_xlatb5.y) ? u_xlat6.y : u_xlat7.y;
                                                                                u_xlat4.z = (u_xlatb5.z) ? u_xlat6.z : u_xlat7.z;
                                                                                u_xlati28 = int(0xFFFFFFFFu);
                                                                            } else {
                                                                                u_xlatb30 = u._fill_blend_mode==17;
                                                                                if(u_xlatb30){
                                                                                    u_xlatb5.xyz = lessThan(float4(0.5, 0.5, 0.5, 0.0), u_xlat1.xyzx).xyz;
                                                                                    u_xlat6.xyz = u_xlat1.xyz + float3(-0.5, -0.5, -0.5);
                                                                                    u_xlat6.xyz = u_xlat6.xyz + u_xlat6.xyz;
                                                                                    u_xlat6.xyz = max(u_xlat3.xyz, u_xlat6.xyz);
                                                                                    u_xlat7.xyz = u_xlat1.xyz + u_xlat1.xyz;
                                                                                    u_xlat7.xyz = min(u_xlat3.xyz, u_xlat7.xyz);
                                                                                    u_xlat4.x = (u_xlatb5.x) ? u_xlat6.x : u_xlat7.x;
                                                                                    u_xlat4.y = (u_xlatb5.y) ? u_xlat6.y : u_xlat7.y;
                                                                                    u_xlat4.z = (u_xlatb5.z) ? u_xlat6.z : u_xlat7.z;
                                                                                    u_xlati28 = int(0xFFFFFFFFu);
                                                                                } else {
                                                                                    u_xlatb30 = u._fill_blend_mode==18;
                                                                                    if(u_xlatb30){
                                                                                        u_xlat5.xyz = u_xlat1.xyz + u_xlat3.xyz;
                                                                                        u_xlatb5.xyz = lessThan(u_xlat5.xyzx, float4(1.0, 1.0, 1.0, 0.0)).xyz;
                                                                                        u_xlat4.x = (u_xlatb5.x) ? float(0.0) : float(1.0);
                                                                                        u_xlat4.y = (u_xlatb5.y) ? float(0.0) : float(1.0);
                                                                                        u_xlat4.z = (u_xlatb5.z) ? float(0.0) : float(1.0);
                                                                                        u_xlati28 = int(0xFFFFFFFFu);
                                                                                    } else {
                                                                                        u_xlatb30 = u._fill_blend_mode==19;
                                                                                        if(u_xlatb30){
                                                                                            u_xlat4.xyz = u_xlat3.xyz * u_xlat0.www + (-u_xlat1.xyz);
                                                                                            u_xlat4.xyz = abs(u_xlat4.xyz);
                                                                                            u_xlati28 = int(0xFFFFFFFFu);
                                                                                        } else {
                                                                                            u_xlatb30 = u._fill_blend_mode==20;
                                                                                            if(u_xlatb30){
                                                                                                u_xlat5.xyz = u_xlat3.xyz * u_xlat0.www + float3(-0.5, -0.5, -0.5);
                                                                                                u_xlat5.xyz = u_xlat5.xyz + u_xlat5.xyz;
                                                                                                u_xlat6.xyz = u_xlat1.xyz + float3(-0.5, -0.5, -0.5);
                                                                                                u_xlat4.xyz = (-u_xlat5.xyz) * u_xlat6.xyz + float3(0.5, 0.5, 0.5);
                                                                                                u_xlati28 = int(0xFFFFFFFFu);
                                                                                            } else {
                                                                                                u_xlatb30 = u._fill_blend_mode==21;
                                                                                                if(u_xlatb30){
                                                                                                    u_xlat4.xyz = (-u_xlat1.xyz) + u_xlat3.xyz;
                                                                                                    u_xlati28 = int(0xFFFFFFFFu);
                                                                                                } else {
                                                                                                    u_xlatb30 = u._fill_blend_mode==22;
                                                                                                    if(u_xlatb30){
                                                                                                        u_xlat5.xyz = u_xlat0.www * u_xlat3.xyz;
                                                                                                        u_xlat4.xyz = u_xlat5.xyz / u_xlat1.xyz;
                                                                                                        u_xlati28 = int(0xFFFFFFFFu);
                                                                                                    } else {
                                                                                                        u_xlatb30 = u._fill_blend_mode==23;
                                                                                                        if(u_xlatb30){
                                                                                                            u_xlat30 = min(u_xlat1.y, u_xlat1.x);
                                                                                                            u_xlat30 = min(u_xlat1.z, u_xlat30);
                                                                                                            u_xlat31 = max(u_xlat1.y, u_xlat1.x);
                                                                                                            u_xlat31 = max(u_xlat1.z, u_xlat31);
                                                                                                            u_xlat30 = (-u_xlat30) + u_xlat31;
                                                                                                            u_xlatb5.x = 9.99999975e-05<u_xlat30;
                                                                                                            u_xlat14.x = min(u_xlat3.y, u_xlat3.x);
                                                                                                            u_xlat14.x = min(u_xlat3.z, u_xlat14.x);
                                                                                                            u_xlat23 = max(u_xlat3.y, u_xlat3.x);
                                                                                                            u_xlat23 = max(u_xlat3.z, u_xlat23);
                                                                                                            u_xlat14.x = (-u_xlat14.x) + u_xlat23;
                                                                                                            u_xlatb32 = float4(0.0, 0.0, 0.0, 0.0)!=float4(u_xlat23);
                                                                                                            u_xlat14.x = u_xlat14.x / u_xlat23;
                                                                                                            u_xlat14.x = u_xlatb32 ? u_xlat14.x : float(0.0);
                                                                                                            u_xlat14.x = u_xlat23 * u_xlat14.x;
                                                                                                            u_xlat30 = u_xlat14.x / u_xlat30;
                                                                                                            u_xlat31 = (-u_xlat31) * u_xlat30 + u_xlat23;
                                                                                                            u_xlat14.xyz = u_xlat1.xyz * float3(u_xlat30) + float3(u_xlat31);
                                                                                                            u_xlat4.xyz = (u_xlatb5.x) ? u_xlat14.xyz : u_xlat3.xyz;
                                                                                                            u_xlati28 = int(0xFFFFFFFFu);
                                                                                                        } else {
                                                                                                            u_xlatb30 = u._fill_blend_mode==24;
                                                                                                            if(u_xlatb30){
                                                                                                                u_xlat30 = min(u_xlat3.y, u_xlat3.x);
                                                                                                                u_xlat30 = min(u_xlat3.z, u_xlat30);
                                                                                                                u_xlat31 = max(u_xlat3.y, u_xlat3.x);
                                                                                                                u_xlat31 = max(u_xlat3.z, u_xlat31);
                                                                                                                u_xlat30 = (-u_xlat30) + u_xlat31;
                                                                                                                u_xlatb5.x = 9.99999975e-05<u_xlat30;
                                                                                                                u_xlat14.x = min(u_xlat1.y, u_xlat1.x);
                                                                                                                u_xlat14.x = min(u_xlat1.z, u_xlat14.x);
                                                                                                                u_xlat23 = max(u_xlat1.y, u_xlat1.x);
                                                                                                                u_xlat23 = max(u_xlat1.z, u_xlat23);
                                                                                                                u_xlat14.x = (-u_xlat14.x) + u_xlat23;
                                                                                                                u_xlatb32 = float4(0.0, 0.0, 0.0, 0.0)!=float4(u_xlat23);
                                                                                                                u_xlat14.x = u_xlat14.x / u_xlat23;
                                                                                                                u_xlat14.x = u_xlatb32 ? u_xlat14.x : float(0.0);
                                                                                                                u_xlat14.x = u_xlat31 * u_xlat14.x;
                                                                                                                u_xlat30 = u_xlat14.x / u_xlat30;
                                                                                                                u_xlat14.x = (-u_xlat30) + 1.0;
                                                                                                                u_xlat14.x = u_xlat31 * u_xlat14.x;
                                                                                                                u_xlat14.xyz = u_xlat3.xyz * float3(u_xlat30) + u_xlat14.xxx;
                                                                                                                u_xlat4.xyz = (u_xlatb5.x) ? u_xlat14.xyz : float3(u_xlat31);
                                                                                                                u_xlati28 = int(0xFFFFFFFFu);
                                                                                                            } else {
                                                                                                                u_xlat5.xyz = u_xlat0.www * u_xlat3.xyz;
                                                                                                                u_xlat6.x = dot(float3(0.298999995, 0.587000012, 0.114), u_xlat5.xyz);
                                                                                                                u_xlat6.y = dot(float3(-0.147129998, -0.288859993, 0.43599999), u_xlat1.xyz);
                                                                                                                u_xlat6.z = dot(float3(0.61500001, -0.514989972, -0.10001), u_xlat1.xyz);
                                                                                                                u_xlat7.x = dot(float2(1.0, 1.13982999), u_xlat6.xz);
                                                                                                                u_xlat7.y = dot(float3(1.0, -0.394650012, -0.580600023), u_xlat6.xyz);
                                                                                                                u_xlat7.z = dot(float2(1.0, 2.03210998), u_xlat6.xy);
                                                                                                                u_xlatb6.xy = equal(int4(int4(u._fill_blend_mode, u._fill_blend_mode, u._fill_blend_mode, u._fill_blend_mode)), int4(25, 26, 0, 0)).xy;
                                                                                                                u_xlat8.x = dot(float3(0.298999995, 0.587000012, 0.114), u_xlat1.xyz);
                                                                                                                u_xlat8.y = dot(float3(-0.147129998, -0.288859993, 0.43599999), u_xlat5.xyz);
                                                                                                                u_xlat8.z = dot(float3(0.61500001, -0.514989972, -0.10001), u_xlat5.xyz);
                                                                                                                u_xlat5.x = dot(float2(1.0, 1.13982999), u_xlat8.xz);
                                                                                                                u_xlat5.y = dot(float3(1.0, -0.394650012, -0.580600023), u_xlat8.xyz);
                                                                                                                u_xlat5.z = dot(float2(1.0, 2.03210998), u_xlat8.xy);
                                                                                                                u_xlat4.xyz = (u_xlatb6.x) ? u_xlat7.xyz : u_xlat5.xyz;
                                                                                                                u_xlati28 = int(uint((uint(u_xlatb6.y) * 0xffffffffu) | (uint(u_xlatb6.x) * 0xffffffffu)));
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            u_xlat30 = (-u_xlat0.w) + 1.0;
            u_xlat3.xyz = u_xlat3.xyz * float3(u_xlat30);
            u_xlat1.xyz = u_xlat1.xyz * u_xlat0.www + u_xlat3.xyz;
            u_xlat1.xyz = (int(u_xlati28) != 0) ? u_xlat4.xyz : u_xlat1.xyz;
            u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
            u_xlat3.xyz = u_xlat1.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
            u_xlat3.xyz = u_xlat1.xyz * u_xlat3.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
            u_xlat2.xyz = u_xlat1.xyz * u_xlat3.xyz;
        } else {
            u_xlat2.xyz = u_xlat0.xyz;
        }
        u_xlat2.w = u_xlat0.w;
    }
    u_xlatb1.x = 0<int(u._bevel_enabled);
    if(u_xlatb1.x){
        u_xlat1.x = min(_resolution.y, _resolution.x);
        u_xlat1.x = u_xlat1.x * u._bevel_radius;
        u_xlat1.x = u_xlat1.x * 0.100000001;
        u_xlati10 = int(u_xlat1.x);
        u_xlati10 = max(u_xlati10, 1);
        u_xlati19 = 0 - u_xlati10;
        u_xlat28 = float(1.0) / _resolution.y;
        u_xlat3.xy = float2(u._bevel_specular_angle, u._bevel_diffuse_angle) * float2(0.0174532998, 0.0174532998);
        u_xlat4.xy = cos(u_xlat3.xy);
        u_xlat3.xy = sin((-u_xlat3.xy));
        u_xlat5.xz = in.vs_TEXCOORD0.xx;
        u_xlat6.x = float(16383.0);
        u_xlat6.y = float(16383.0);
        for(int u_xlati_loop_1 = u_xlati19 ; u_xlati_loop_1<0 ; u_xlati_loop_1++)
        {
            u_xlat24 = float(u_xlati_loop_1);
            u_xlat5.y = u_xlat24 * u_xlat28 + in.vs_TEXCOORD0.y;
            u_xlat7 = lerDistChanfro( u_xlat5.xy);
            u_xlat14.x = dot(u_xlat7.xy, float2(1.0, 0.00392156886));
            u_xlat8.y = u_xlat14.x * 16383.0;
            u_xlat14.x = dot(u_xlat7.zw, float2(1.0, 0.00392156886));
            u_xlat8.x = u_xlat14.x * 16383.0;
            u_xlat8.z = abs(u_xlat24);
            u_xlat14.x = dot(u_xlat8.yz, u_xlat8.yz);
            u_xlat14.x = sqrt(u_xlat14.x);
            u_xlat24 = dot(u_xlat8.xz, u_xlat8.xz);
            u_xlat24 = sqrt(u_xlat24);
            u_xlat6.x = min(u_xlat14.x, u_xlat6.x);
            u_xlat6.y = min(u_xlat24, u_xlat6.y);
        }
        u_xlat5.x = float(16383.0);
        u_xlat5.y = float(16383.0);
        for(int u_xlati_loop_2 = 0 ; u_xlati_loop_2<u_xlati10 ; u_xlati_loop_2++)
        {
            u_xlat30 = float(u_xlati_loop_2);
            u_xlat5.w = u_xlat30 * u_xlat28 + in.vs_TEXCOORD0.y;
            u_xlat7 = lerDistChanfro( u_xlat5.zw);
            u_xlat32 = dot(u_xlat7.xy, float2(1.0, 0.00392156886));
            u_xlat8.y = u_xlat32 * 16383.0;
            u_xlat32 = dot(u_xlat7.zw, float2(1.0, 0.00392156886));
            u_xlat8.x = u_xlat32 * 16383.0;
            u_xlat8.z = abs(u_xlat30);
            u_xlat30 = dot(u_xlat8.yz, u_xlat8.yz);
            u_xlat30 = sqrt(u_xlat30);
            u_xlat32 = dot(u_xlat8.xz, u_xlat8.xz);
            u_xlat32 = sqrt(u_xlat32);
            u_xlat5.x = min(u_xlat30, u_xlat5.x);
            u_xlat5.y = min(u_xlat32, u_xlat5.y);
        }
        u_xlat5 = u_xlat5.xxyy;
        u_xlat5 = u_xlat5 / u_xlat1.xxxx;
        u_xlat5 = clamp(u_xlat5, 0.0, 1.0);
        u_xlat7 = u_xlat5.yyww * float4(-2.0, -2.0, -2.0, -2.0) + float4(3.0, 3.0, 3.0, 3.0);
        u_xlat5 = u_xlat5 * u_xlat5;
        u_xlat5 = u_xlat5 * u_xlat7;
        u_xlat1.xy = u_xlat6.xy / u_xlat1.xx;
        u_xlat1.xy = clamp(u_xlat1.xy, 0.0, 1.0);
        u_xlat19.xy = u_xlat1.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
        u_xlat1.xy = u_xlat1.xy * u_xlat1.xy;
        u_xlat1.xy = u_xlat1.xy * u_xlat19.xy;
        u_xlat1.xyz = u_xlat1.yyy * float3(1.0, -1.0, -1.0) + (-u_xlat1.xxx);
        u_xlat1.xyz = u_xlat5.xyx * float3(-1.0, 1.0, -1.0) + u_xlat1.xyz;
        u_xlat1.xyz = u_xlat5.zzw * float3(1.0, 1.0, -1.0) + u_xlat1.xyz;
        u_xlat1.xyz = u_xlat1.xyz * float3(0.25, 0.25, 0.25);
        u_xlat28 = dot(u_xlat1.xyz, u_xlat1.xyz);
        u_xlat28 = rsqrt(u_xlat28);
        u_xlat1.xyz = float3(u_xlat28) * u_xlat1.xyz;
        u_xlat4.z = u_xlat3.x;
        u_xlat4.w = -2.0;
        u_xlat28 = dot(u_xlat4.xzw, u_xlat4.xzw);
        u_xlat28 = rsqrt(u_xlat28);
        u_xlat4.xzw = float3(u_xlat28) * u_xlat4.xzw;
        u_xlat19.x = dot(u_xlat1.xyz, u_xlat4.xzw);
        u_xlat19.x = log2(u_xlat19.x);
        u_xlat19.x = u_xlat19.x * 35.0;
        u_xlat19.x = exp2(u_xlat19.x);
        u_xlat3.z = u_xlat4.y;
        u_xlat28 = dot(u_xlat3.yz, u_xlat3.yz);
        u_xlat28 = rsqrt(u_xlat28);
        u_xlat3.xy = float2(u_xlat28) * u_xlat3.zy;
        u_xlat1.x = dot(u_xlat1.xy, u_xlat3.xy);
        u_xlat3 = u_xlat19.xxxx * nvCor(u._bevel_specular_color);
        u_xlat3 = u_xlat3 * float4(u._bevel_specular_intensity);
        u_xlat4 = u_xlat2.wwww * u_xlat3;
        u_xlat1 = u_xlat1.xxxx * nvCor(u._bevel_diffuse_color);
        u_xlat1 = u_xlat1 * float4(float4(u._bevel_diffuse_intensity, u._bevel_diffuse_intensity, u._bevel_diffuse_intensity, u._bevel_diffuse_intensity));
        u_xlat5 = u_xlat2.wwww * u_xlat1;
        u_xlat1.x = (-u_xlat1.w) * u_xlat2.w + 1.0;
        u_xlat1 = u_xlat2 * u_xlat1.xxxx + u_xlat5;
        u_xlat3.x = (-u_xlat3.w) * u_xlat2.w + 1.0;
        u_xlat2 = u_xlat1 * u_xlat3.xxxx + u_xlat4;
    }
    u_xlatb1.x = 0<int(u._outline_enabled);
    if(u_xlatb1.x){
        u_xlat1.x = min(_resolution.y, _resolution.x);
        u_xlat1.x = u_xlat1.x * u._outline_size;
        u_xlat1.x = u_xlat1.x * 0.100000001;
        u_xlati10 = int(u_xlat1.x);
        u_xlati10 = max(u_xlati10, 1);
        u_xlati19 = 0 - u_xlati10;
        u_xlat28 = float(1.0) / _resolution.y;
        u_xlat3.x = in.vs_TEXCOORD0.x;
        u_xlat21.x = float(2.0);
        u_xlat21.y = float(2.0);
        for(int u_xlati_loop_3 = u_xlati19 ; u_xlati_loop_3<u_xlati10 ; u_xlati_loop_3++)
        {
            u_xlat13.x = float(u_xlati_loop_3);
            u_xlat3.y = u_xlat13.x * u_xlat28 + in.vs_TEXCOORD0.y;
            u_xlat5.yz = lerDistContorno( u_xlat3.xy).xy;
            u_xlat5.x = abs(u_xlat13.x) / u_xlat1.x;
            u_xlat12.x = dot(u_xlat5.xy, u_xlat5.xy);
            u_xlat12.x = sqrt(u_xlat12.x);
            u_xlat13.x = dot(u_xlat5.xz, u_xlat5.xz);
            u_xlat13.x = sqrt(u_xlat13.x);
            u_xlat21.y = min(u_xlat21.y, u_xlat13.x);
            u_xlat21.x = min(u_xlat12.x, u_xlat21.x);
        }
        u_xlat1.x = 1.5 / u_xlat1.x;
        u_xlat1.x = (-u_xlat1.x) + 1.0;
        u_xlat10 = (-u_xlat1.x) + 1.0;
        u_xlat1.xz = (-u_xlat1.xx) + u_xlat21.xy;
        u_xlat10 = float(1.0) / u_xlat10;
        u_xlat1.xy = float2(u_xlat10) * u_xlat1.xz;
        u_xlat1.xy = clamp(u_xlat1.xy, 0.0, 1.0);
        u_xlat19.xy = u_xlat1.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
        u_xlat1.xy = u_xlat1.xy * u_xlat1.xy;
        u_xlat1.xy = u_xlat1.xy * u_xlat19.xy;
        u_xlat3 = u_xlat1.xxxx * (-nvCor(u._outline_outer_color)) + nvCor(u._outline_outer_color);
        u_xlat3 = u_xlat3 * nvCor(u._outline_outer_color).wwww;
        u_xlat1 = u_xlat1.yyyy * (-nvCor(u._outline_inner_color)) + nvCor(u._outline_inner_color);
        u_xlat1 = u_xlat2.wwww * u_xlat1;
        u_xlat4 = u_xlat1 * nvCor(u._outline_inner_color).wwww;
        u_xlat1.x = (-u_xlat2.w) + 1.0;
        u_xlat3 = u_xlat3 * u_xlat1.xxxx + u_xlat2;
        u_xlat1.x = (-u_xlat1.w) * nvCor(u._outline_inner_color).w + 1.0;
        u_xlat2 = u_xlat3 * u_xlat1.xxxx + u_xlat4;
    }
    if(int(u._glow_inner_enabled) != 0) {
        u_xlat1.x = min(_resolution.y, _resolution.x);
        u_xlat1.x = u_xlat1.x * u._glow_inner_radius;
        u_xlat10 = u_xlat1.x * 0.5;
        u_xlati19 = int(u_xlat10);
        u_xlati19 = max(u_xlati19, 1);
        u_xlati28 = 0 - u_xlati19;
        u_xlat3.x = float(1.0) / _resolution.y;
        u_xlat4.x = in.vs_TEXCOORD0.x;
        u_xlat12.x = 16383.0;
        for(int u_xlati_loop_4 = u_xlati28 ; u_xlati_loop_4<u_xlati19 ; u_xlati_loop_4++)
        {
            u_xlat30 = float(u_xlati_loop_4);
            u_xlat4.y = u_xlat30 * u_xlat3.x + in.vs_TEXCOORD0.y;
            u_xlat13.x = lerDistBrilhoInt( u_xlat4.xy).y;
            u_xlat5.x = u_xlat10 * u_xlat13.x;
            u_xlat5.y = abs(u_xlat30);
            u_xlat30 = dot(u_xlat5.xy, u_xlat5.xy);
            u_xlat30 = sqrt(u_xlat30);
            u_xlat12.x = min(u_xlat30, u_xlat12.x);
        }
        u_xlat19.x = u_xlat1.x * 0.5 + 0.50999999;
        u_xlat10 = u._glow_inner_intensity * u_xlat10 + -0.50999999;
        u_xlat10 = (-u_xlat19.x) + u_xlat10;
        u_xlat19.x = (-u_xlat19.x) + u_xlat12.x;
        u_xlat10 = float(1.0) / u_xlat10;
        u_xlat10 = u_xlat10 * u_xlat19.x;
        u_xlat10 = clamp(u_xlat10, 0.0, 1.0);
        u_xlat19.x = u_xlat10 * -2.0 + 3.0;
        u_xlat10 = u_xlat10 * u_xlat10;
        u_xlat10 = u_xlat10 * u_xlat19.x;
        u_xlat3.xyz = u_xlat2.www * nvCor(u._glow_inner_color).xyz;
        u_xlat3.w = u_xlat2.w;
        u_xlat10 = u_xlat10 * nvCor(u._glow_inner_color).w;
        u_xlat3 = (-u_xlat2) + u_xlat3;
        u_xlat3 = float4(u_xlat10) * u_xlat3 + u_xlat2;
        u_xlatb1.x = u_xlat1.x<0.00999999978;
        u_xlat2 = (u_xlatb1.x) ? u_xlat2 : u_xlat3;
    }
    u_xlatb1.x = 0<int(u._glow_enabled);
    if(u_xlatb1.x){
        u_xlat1.x = min(_resolution.y, _resolution.x);
        u_xlat1.x = u_xlat1.x * u._glow_radius;
        u_xlat10 = u_xlat1.x * 0.5;
        u_xlati19 = int(u_xlat10);
        u_xlati19 = max(u_xlati19, 1);
        u_xlati28 = 0 - u_xlati19;
        u_xlat3.x = float(1.0) / _resolution.y;
        u_xlat4.x = in.vs_TEXCOORD0.x;
        u_xlat12.x = float(16383.0);
        u_xlat12.y = float(16383.0);
        for(int u_xlati_loop_5 = u_xlati28 ; u_xlati_loop_5<u_xlati19 ; u_xlati_loop_5++)
        {
            u_xlat22.x = float(u_xlati_loop_5);
            u_xlat4.y = u_xlat22.x * u_xlat3.x + in.vs_TEXCOORD0.y;
            u_xlat13.xz = lerDistBrilho( u_xlat4.xy).xy;
            u_xlat5.xy = float2(u_xlat10) * u_xlat13.xz;
            u_xlat5.z = abs(u_xlat22.x);
            u_xlat13.x = dot(u_xlat5.xz, u_xlat5.xz);
            u_xlat13.y = dot(u_xlat5.yz, u_xlat5.yz);
            u_xlat13.xy = sqrt(u_xlat13.xy);
            u_xlat12.xy = min(u_xlat12.xy, u_xlat13.yx);
        }
        u_xlat19.xy = u_xlat12.xy / float2(u_xlat10);
        u_xlat19.x = u_xlat19.x + 0.5;
        u_xlat19.x = (-u_xlat19.y) + u_xlat19.x;
        u_xlatb1.xw = lessThan(u_xlat1.xxxx, float4(0.00600000005, 0.0, 0.0, 0.00999999978)).xw;
        u_xlat3.xyz = nvCor(u._glow_color).www * nvCor(u._glow_color).xyz;
        u_xlat3.w = nvCor(u._glow_color).w;
        u_xlat10 = 1.5 / u_xlat10;
        u_xlat10 = (-u_xlat10) + 1.0;
        u_xlat4.x = (-u_xlat19.x) + 1.0;
        u_xlat13.x = (-u_xlat10) * u._glow_intensity + 1.0;
        u_xlat10 = (-u_xlat10) * u._glow_intensity + u_xlat4.x;
        u_xlat4.x = float(1.0) / u_xlat13.x;
        u_xlat10 = u_xlat10 * u_xlat4.x;
        u_xlat10 = clamp(u_xlat10, 0.0, 1.0);
        u_xlat4.x = u_xlat10 * -2.0 + 3.0;
        u_xlat10 = u_xlat10 * u_xlat10;
        u_xlat10 = u_xlat10 * u_xlat4.x;
        u_xlat3 = float4(u_xlat10) * (-u_xlat3) + u_xlat3;
        u_xlat3 = (u_xlatb1.x) ? float4(0.0, 0.0, 0.0, 0.0) : u_xlat3;
        u_xlat3.w = u_xlat3.w * nvCor(u._glow_color).w;
        u_xlat1.x = (-u_xlat2.w) + 1.0;
        u_xlat3 = u_xlat3 * u_xlat1.xxxx + u_xlat2;
        u_xlatb1.x = 9.99999975e-05>=u_xlat19.x;
        u_xlatb1.x = u_xlatb1.x || u_xlatb1.w;
        u_xlat2 = (u_xlatb1.x) ? u_xlat2 : u_xlat3;
    }
    u_xlatb1.x = 0<int(u._shadow_enabled);
    if(u_xlatb1.x){
        u_xlat1.xy = in.vs_TEXCOORD0.xy + float2(-0.5, -0.5);
        u_xlat1.xy = (-float2(u._shadow_offset.x, u._shadow_offset.y)) * float2(0.0199999996, 0.0199999996) + u_xlat1.xy;
        u_xlat1.xy = u_xlat1.xy + float2(0.5, 0.5);
        u_xlat1.x = lerDesfeito( u_xlat1.xy).w;
        u_xlat10 = min(u._shadow_intensity, 0.99000001);
        u_xlatb19 = 0<_old_version;
        u_xlat28 = u_xlat1.x * u._shadow_intensity;
        u_xlat10 = (-u_xlat10) + 1.0;
        u_xlat1.x = log2(u_xlat1.x);
        u_xlat1.x = u_xlat1.x * u_xlat10;
        u_xlat1.x = exp2(u_xlat1.x);
        u_xlat1.x = u_xlat1.x * u._shadow_opacity;
        u_xlat1.xyz = (bool(u_xlatb19)) ? float3(u_xlat28) : u_xlat1.xxx;
        u_xlat1.w = (-u_xlat2.w) + 1.0;
        u_xlat3.xyz = u_xlat1.www * nvCor(u._shadow_color).xyz;
        u_xlat3.w = u_xlat1.z * u_xlat1.z;
        u_xlat1 = u_xlat1 * u_xlat3;
        u_xlat2 = u_xlat2 * u_xlat2.wwww + u_xlat1;
    }
    u_xlatb1.x = 0<int(u._long_shadow_enabled);
    if(u_xlatb1.x){
        u_xlat1.xy = float2(1.0, 1.0) / _resolution.xy;
        u_xlat19.x = u._long_shadow_angle * 0.0174532998;
        u_xlat28 = cos(u_xlat19.x);
        u_xlat3.x = u_xlat28 * u._long_shadow_length;
        u_xlat19.x = sin((-u_xlat19.x));
        u_xlat4.y = u_xlat19.x * u._long_shadow_length;
        u_xlatb19 = _resolution.x<_resolution.y;
        u_xlat21.xy = _resolution.xy / _resolution.yx;
        u_xlat3.y = u_xlat21.x * u_xlat4.y;
        u_xlat4.x = u_xlat21.y * u_xlat3.x;
        u_xlat19.xy = (bool(u_xlatb19)) ? u_xlat3.xy : u_xlat4.xy;
        u_xlat1.xy = u_xlat19.xy / u_xlat1.xy;
        u_xlat1.x = dot(u_xlat1.xy, u_xlat1.xy);
        u_xlat1.x = sqrt(u_xlat1.x);
        u_xlat1.x = max(u_xlat1.x, 1.00999999);
        u_xlat1.x = min(u_xlat1.x, 500.01001);
        u_xlati10 = int(u_xlat1.x);
        u_xlati3 = u_xlati10 + int(0xFFFFFFFFu);
        u_xlat3.x = float(u_xlati3);
        u_xlat12.x = (-u._long_shadow_blur) + 1.0;
        u_xlat21.x = float(0.0);
        u_xlat30 = float(0.0);
        u_xlati4 = u_xlati10;
        for(int u_xlati_loop_6 = 1 ; u_xlati_loop_6<u_xlati10 ; u_xlati_loop_6++)
        {
            u_xlat22.x = float(u_xlati_loop_6);
            u_xlat22.x = u_xlat22.x / u_xlat3.x;
            u_xlat22.xy = (-u_xlat19.xy) * u_xlat22.xx + in.vs_TEXCOORD0.xy;
            u_xlatb5.xy = greaterThanEqual(u_xlat22.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
            u_xlatb5.zw = greaterThanEqual(float4(0.0, 0.0, 1.0, 1.0), u_xlat22.xxxy).zw;
            u_xlat5.x = u_xlatb5.x ? float(1.0) : 0.0;
            u_xlat5.y = u_xlatb5.y ? float(1.0) : 0.0;
            u_xlat5.z = u_xlatb5.z ? float(1.0) : 0.0;
            u_xlat5.w = u_xlatb5.w ? float(1.0) : 0.0;
;
            u_xlat5.x = u_xlat5.z * u_xlat5.x;
            u_xlat5.x = u_xlat5.y * u_xlat5.x;
            u_xlat5.x = u_xlat5.w * u_xlat5.x;
            u_xlat22.x = lerPre( u_xlat22.xy).w;
            u_xlat22.x = u_xlat5.x * u_xlat22.x;
            u_xlat21.x = max(u_xlat21.x, u_xlat22.x);
            u_xlatb31 = 0.5<u_xlat22.x;
            u_xlati5 = min(u_xlati_loop_6, u_xlati4);
            u_xlati4 = (u_xlatb31) ? u_xlati5 : u_xlati4;
            u_xlat22.x = u_xlat12.x * u_xlat22.x;
            u_xlat31 = u_xlat22.x * 0.25;
            u_xlat22.x = (-u_xlat22.x) * 0.25 + 1.0;
            u_xlat30 = u_xlat30 * u_xlat22.x + u_xlat31;
        }
        u_xlat10 = (-u_xlat30) + u_xlat21.x;
        u_xlat10 = u_xlat12.x * u_xlat10 + u_xlat30;
        u_xlat19.x = float(u_xlati4);
        u_xlat1.x = trunc(u_xlat1.x);
        u_xlat1.x = u_xlat19.x / u_xlat1.x;
        u_xlat1.x = (-u_xlat1.x) * u._long_shadow_fade + 1.0;
        u_xlat3 = u_xlat1.xxxx * nvCor(u._long_shadow_color);
        u_xlat4 = float4(u_xlat10) * u_xlat3;
        u_xlat1 = (-u_xlat3) * float4(u_xlat10) + u_xlat0;
        u_xlat1 = u_xlat0.wwww * u_xlat1 + u_xlat4;
        u_xlat3.x = (-u_xlat2.w) + 1.0;
        u_xlat1 = u_xlat1 * u_xlat3.xxxx;
        u_xlat2 = u_xlat2 * u_xlat2.wwww + u_xlat1;
    }
    if(0 != 0) {
        u_xlatb1.xy = equal(int4(0, 0, 0, 0), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat2;
        u_xlat4 = lerPre( in.vs_TEXCOORD0.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat3 * u_xlat4 + u_xlat0;
        u_xlat1.x = u_xlat4.x * u_xlat0.w;
        SV_Target0.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat0.w;
        SV_Target0.xyz = u_xlat0.xyz;
    } else {
        SV_Target0 = u_xlat2;
    }
    return SV_Target0;
    return SV_Target0;
}

// O programa 0 do shader NodeVideo/Effect/layer_style_glass do Node, conta por conta (tools/nodepassesc/montar.py).
float4 distanciaVidro(float2 in.vs_TEXCOORD0)
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
        u_xlat1.x = lerEstilizada( u_xlat1.xy).w;
        u_xlatb1 = u_xlat1.x<0.00300000003;
        u_xlat1.x = (u_xlatb1) ? abs(u_xlat8) : u_xlat0.y;
        u_xlat2 = min(u_xlat1.x, u_xlat2);
    }
    u_xlat6 = 16383.0;
    for(int u_xlati_loop_2 = 0 ; u_xlati_loop_2<u_xlati0 ; u_xlati_loop_2++)
    {
        u_xlat4 = float(u_xlati_loop_2);
        u_xlat1.z = u_xlat4 * u_xlat9 + in.vs_TEXCOORD0.x;
        u_xlat7 = lerEstilizada( u_xlat1.zw).w;
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
float4 vidro(float2 in.vs_TEXCOORD0)
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
    u_xlat4 = lerEstilizada( in.vs_TEXCOORD0.xy);
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

fragment float4 fx_nv_nodevideo_effect_layer_styles2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_layer_styles2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> fundo [[texture(1)]],
    texture2d<float> pre [[texture(2)]],
    texture2d<float> desfMeio [[texture(3)]],
    texture2d<float> desfH [[texture(4)]],
    texture2d<float> desfV [[texture(5)]],
    texture2d<float> desfeito [[texture(6)]],
    texture2d<float> distContorno [[texture(7)]],
    texture2d<float> distChanfro [[texture(8)]],
    texture2d<float> distBrilho [[texture(9)]],
    texture2d<float> distBrilhoInt [[texture(10)]],
    texture2d<float> estilizada [[texture(11)]],
    texture2d<float> compNode [[texture(12)]],
    texture2d<float> distVidro [[texture(13)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = nvFonte(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = desfReduzir(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = desfHorizontal(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = desfVertical(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 4) { __nv_out = desfVoltar(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 5) { __nv_out = distanciaContorno(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 6) { __nv_out = distanciaChanfro(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 7) { __nv_out = distanciaBrilho(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 8) { __nv_out = distanciaBrilhoInterno(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 9) { __nv_out = estilos(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 10) { __nv_out = nvFundo(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 11) { __nv_out = distanciaVidro(in.acScreenNorm); return __nv_out; }
    // Com o vidro, a mistura da camada é a do RenderGlass; sem ele, a saída do passe 4.
    __nv_out = nvVolta(u._glass_enabled ? vidro(nvUvDePe()) : estilos(nvUvDePe()));
    return __nv_out;
}
