// ---------------------------------------------------------------------------
// Effect Layer Styles (NV)
// origem : assets/effects/nv-nodevideo-effect-layer-styles.xml
// id     : nv.effect.nodevideo-effect-layer-styles
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_layer_stylesParams {
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
    int _shadow_enabled;
    float2 _shadow_offset;
    float4 _shadow_color;
    int _outline_enabled;
    float _outline_size;
    float4 _outline_color;
    int _glow_enabled;
    float _glow_sample_distance;
    float _glow_outter;
    float _glow_inner;
    float4 _glow_color;
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
// O tamanho do RT do Node (o do buffer).
#define _resolution float2(int2(int(pre.get_width()), int(pre.get_height())))

// A cor de um controle como o Unity a entrega num projeto linear.
static float4 nvCor(float4 c) { return float4(nvLinear(c.rgb), c.a); }

static float4 lerPre(float2 uv) { return pre.sample(__nv_smp, uv); }

// O programa 0 do shader NodeVideo/Effect/layer_styles do Node, conta por conta (tools/nodepassesc/montar.py).
static float4 estilos(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);
    float4 u_xlat0;
    float4 u_xlat1;
    bool2 u_xlatb1;
    float4 u_xlat2;
    float4 u_xlat3;
    int u_xlati3;
    bool u_xlatb3;
    float4 u_xlat4;
    float4 u_xlat5;
    bool3 u_xlatb5;
    float3 u_xlat6;
    bool2 u_xlatb6;
    float3 u_xlat7;
    float3 u_xlat8;
    float3 u_xlat10;
    int u_xlati10;
    bool u_xlatb10;
    float3 u_xlat12;
    float u_xlat13;
    float3 u_xlat14;
    float2 u_xlat19;
    bool u_xlatb19;
    int u_xlati21;
    int u_xlati22;
    float u_xlat23;
    float u_xlat28;
    int u_xlati28;
    bool u_xlatb28;
    float u_xlat30;
    bool u_xlatb30;
    float u_xlat31;
    bool u_xlatb31;
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
    u_xlatb1.x = int(u._outline_enabled)==1;
    if(u_xlatb1.x){
        u_xlat1.x = u._outline_size * 0.100000001;
        u_xlat10.x = float(0.0);
        u_xlat19.x = float(0.0);
        for(int u_xlati_loop_1 = int(0) ; u_xlati_loop_1<32 ; u_xlati_loop_1++)
        {
            u_xlat19.x = u_xlat19.x + 0.196349546;
            u_xlat3.x = sin(u_xlat19.x);
            u_xlat4.x = cos(u_xlat19.x);
            u_xlat4.x = u_xlat1.x * u_xlat4.x;
            u_xlat4.y = u_xlat1.x * u_xlat3.x;
            u_xlat3.xy = u_xlat4.xy / float2(eng.acProporcaoDoNode.x, eng.acProporcaoDoNode.y);
            u_xlat3.xy = u_xlat3.xy + in.vs_TEXCOORD0.xy;
            u_xlat3.xy = clamp(u_xlat3.xy, 0.0, 1.0);
            u_xlat3.x = lerPre( u_xlat3.xy).w;
            u_xlat10.x = u_xlat10.x + u_xlat3.x;
        }
        u_xlat10.x = u_xlat10.x;
        u_xlat10.x = clamp(u_xlat10.x, 0.0, 1.0);
        u_xlat1.w = u_xlat10.x * nvCor(u._outline_color).w;
        u_xlat3.xyz = nvCor(u._outline_color).xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
        u_xlat3.xyz = nvCor(u._outline_color).xyz * u_xlat3.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
        u_xlat1.xyz = u_xlat3.xyz * nvCor(u._outline_color).xyz;
        u_xlat3 = (-u_xlat1) + u_xlat2;
        u_xlat2 = u_xlat0.wwww * u_xlat3 + u_xlat1;
    }
    u_xlatb1.x = int(u._glow_enabled)==1;
    u_xlatb10 = int(u._outline_enabled)!=1;
    u_xlatb1.x = u_xlatb10 && u_xlatb1.x;
    if(u_xlatb1.x){
        u_xlat1.x = float(int(u._glow_sample_distance));
        u_xlat10.x = u_xlat1.x * 0.5;
        u_xlati10 = int(u_xlat10.x);
        u_xlatb19 = u_xlat0.w>=0.5;
        u_xlat28 = (u_xlatb19) ? 0.5 : -0.5;
        u_xlati3 = 0 - u_xlati10;
        u_xlat12.x = u_xlat1.x;
        for(int u_xlati_loop_2 = u_xlati3 ; u_xlati_loop_2<u_xlati10 ; u_xlati_loop_2++)
        {
            u_xlat4.x = float(u_xlati_loop_2);
            u_xlat30 = u_xlat12.x;
            for(int u_xlati_loop_3 = u_xlati3 ; u_xlati_loop_3<u_xlati10 ; u_xlati_loop_3++)
            {
                u_xlat4.y = float(u_xlati_loop_3);
                u_xlat5.xy = u_xlat4.xy / _resolution.xy;
                u_xlat5.xy = u_xlat5.xy + in.vs_TEXCOORD0.xy;
                u_xlat31 = lerPre( u_xlat5.xy).w;
                u_xlatb31 = u_xlat31>=0.5;
                u_xlat31 = (u_xlatb31) ? 0.5 : -0.5;
                u_xlat31 = u_xlat28 * u_xlat31;
                u_xlatb31 = u_xlat31<0.0;
                u_xlat13 = dot(u_xlat4.xy, u_xlat4.xy);
                u_xlat13 = sqrt(u_xlat13);
                u_xlat13 = min(u_xlat30, u_xlat13);
                u_xlat30 = (u_xlatb31) ? u_xlat13 : u_xlat30;
            }
            u_xlat12.x = u_xlat30;
        }
        u_xlat10.x = max(u_xlat12.x, 0.0);
        u_xlat10.x = min(u_xlat1.x, u_xlat10.x);
        u_xlat1.x = u_xlat10.x / u_xlat1.x;
        u_xlat1.x = (u_xlatb19) ? (-u_xlat1.x) : u_xlat1.x;
        u_xlat1.x = u_xlat1.x * 0.5 + 0.5;
        u_xlat1.xy = (-u_xlat1.xx) + float2(1.0, 0.5);
        u_xlat19.x = u._glow_inner * 0.5;
        u_xlat28 = (-u._glow_outter) * 0.5 + 0.5;
        u_xlat3.x = (-u_xlat28) + 0.5;
        u_xlat1.x = (-u_xlat28) + u_xlat1.x;
        u_xlat28 = float(1.0) / u_xlat3.x;
        u_xlat1.x = u_xlat28 * u_xlat1.x;
        u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
        u_xlat28 = u_xlat1.x * -2.0 + 3.0;
        u_xlat1.x = u_xlat1.x * u_xlat1.x;
        u_xlat1.x = u_xlat1.x * u_xlat28;
        u_xlat3.w = u_xlat1.x * u_xlat1.x;
        u_xlat4.xyz = u_xlat3.www * nvCor(u._glow_color).xyz;
        u_xlat5.xyz = u_xlat4.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
        u_xlat5.xyz = u_xlat4.xyz * u_xlat5.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
        u_xlat3.xyz = u_xlat4.xyz * u_xlat5.xyz;
        u_xlat1.x = float(1.0) / u_xlat19.x;
        u_xlat1.x = u_xlat1.x * u_xlat1.y;
        u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
        u_xlat10.x = u_xlat1.x * -2.0 + 3.0;
        u_xlat1.x = u_xlat1.x * u_xlat1.x;
        u_xlat1.x = u_xlat1.x * u_xlat10.x;
        u_xlat1.x = u_xlat1.x * u_xlat1.x;
        u_xlat4 = u_xlat2 + (-u_xlat3);
        u_xlat2 = u_xlat1.xxxx * u_xlat4 + u_xlat3;
    }
    u_xlatb1.x = int(u._shadow_enabled)==1;
    if(u_xlatb1.x){
        u_xlat1.xy = (-float2(u._shadow_offset.x, u._shadow_offset.y)) * float2(0.0199999996, 0.0199999996) + in.vs_TEXCOORD0.xy;
        u_xlat1.x = lerPre( u_xlat1.xy).w;
        u_xlat10.xyz = nvCor(u._shadow_color).xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
        u_xlat10.xyz = nvCor(u._shadow_color).xyz * u_xlat10.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
        u_xlat3.xyz = u_xlat10.xyz * nvCor(u._shadow_color).xyz;
        u_xlat3.w = u_xlat1.x * nvCor(u._shadow_color).w;
        u_xlat1 = u_xlat2.wwww * u_xlat2;
        u_xlat4.x = (-u_xlat2.w) + 1.0;
        u_xlat3 = u_xlat3 * u_xlat4.xxxx;
        u_xlat2 = max(u_xlat1, u_xlat3);
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

fragment float4 fx_nv_nodevideo_effect_layer_styles(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_layer_stylesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pre [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = nvFonte(in.acScreenNorm); return __nv_out; }
    __nv_out = nvVolta(estilos(nvUvDePe()));
    return __nv_out;
}
