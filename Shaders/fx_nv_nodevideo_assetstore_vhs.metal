// ---------------------------------------------------------------------------
// Vhs (NV)
// origem : assets/effects/nv-nodevideo-assetstore-vhs.xml
// id     : nv.effect.nodevideo-assetstore-vhs
// passes : 6
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_vhsParams {
    float _vignette;
    int _enable_vhs;
    float _blur;
    float _length;
    float _grain;
    float _scanline;
    float _scanline_speed;
    float3 _color_offset;
    int _enable_noises1;
    float _intensity1;
    float _size;
    int _enable_wave;
    float _width;
    float _speed;
    float _phase;
    int _enable_noises2;
    float _intensity2;
    float _speed2;
    float _phase2;
    float _continues;
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
#define _resolution eng.acTamanhoDaTela
// `_vhs_res` do C#: a composição ÷ (Desfoque + 1), divisão inteira.
#define _vhs_res float2(int2(eng.acTamanhoDaTela) / (int(u._blur) + 1))

// ---- a textura "noise" do Node (tools/nodepassesc/ruido_node.glsl, colada pelo montar.py) ----
// `sharedassets0` PathID 84 = `assets/textures/rgbanoise.png`, byte a byte: 256 × 256, sRGB, REPEAT, filtro Bilinear
// com 9 mips (no GL: LINEAR_MIPMAP_NEAREST). Os mips do Unity são a média 2 × 2 em luz LINEAR, guardada em sRGB (lidos
// do bundle: 0,25 nível de diferença, o arredondamento). A imagem do efeito entra no Nova crua (sem sRGB, sem mip, a
// linha 0 em cima); aqui: o nível 0 lido e decodificado à mão, os níveis 1–4 no atlas `ruidoMipA` (192 × 128) e os 5–8
// no `ruidoMipB` (16 × 8), refeitos por dois passes pequenos; o nível escolhido pela derivada, como a GPU.
const int2 nvMipOrigem[9] = int2[9](int2(0, 0), int2(0, 0), int2(128, 0), int2(128, 64), int2(128, 96),
                                      int2(0, 0), int2(8, 0), int2(12, 0), int2(14, 0));
// O texel (x, y) do nível L, com a linha 0 EMBAIXO (a do Unity), em luz linear.
float4 nvTexelRuido(int L, int2 p) {
    int s = 256 >> L;
    p = p & (s - 1);
    if (L == 0) {
        float4 c = ruidoNode.read(uint2(int2(p.x, 255 - p.y)), uint(0));
        return float4(nvLinear(c.rgb), c.a);
    }
    if (L <= 4) return ruidoMipA.read(uint2(nvMipOrigem[L] + p), uint(0));
    return ruidoMipB.read(uint2(nvMipOrigem[L] + p), uint(0));
}
// `_texture0.sample(__nv_smp, uv)` do Node.
float4 lerRuidoNode(float2 uv) {
    float2 dx = dfdx(uv) * 256.0, dy = dfdy(uv) * 256.0;
    float lambda = log2(max(max(length(dx), length(dy)), 1e-8));
    int L = lambda <= 0.5 ? 0 : min(int(ceil(lambda + 0.5)) - 1, 8);
    float s = float(256 >> L);
    float2 q = uv * s - 0.5;
    float2 f = fract(q);
    int2 b = int2(floor(q));
    float4 a00 = nvTexelRuido(L, b), a10 = nvTexelRuido(L, b + int2(1, 0));
    float4 a01 = nvTexelRuido(L, b + int2(0, 1)), a11 = nvTexelRuido(L, b + int2(1, 1));
    return mix(mix(a00, a10, f.x), mix(a01, a11, f.x), f.y);
}
// O passe que escreve `ruidoMipA`: os níveis 1–4, cada texel a média do bloco do nível 0 (até 16 × 16).
float4 nvMipRuidoA() {
    int2 p = int2(__nv_fragCoord.xy);
    int L = p.x < 128 ? 1 : (p.y < 64 ? 2 : (p.y < 96 ? 3 : (p.y < 112 ? 4 : 0)));
    if (L == 0 || (L > 1 && p.x >= 128 + (256 >> L))) return float4(0.0);
    int2 t = p - nvMipOrigem[L];
    int n = 1 << L;
    float4 soma = float4(0.0);
    for (int j = 0; j < 16; j++) {
        if (j >= n) break;
        for (int i = 0; i < 16; i++) {
            if (i >= n) break;
            soma += nvTexelRuido(0, t * n + int2(i, j));
        }
    }
    return soma / float(n * n);
}
// O passe que escreve `ruidoMipB`: os níveis 5–8, da média do bloco do nível 4.
float4 nvMipRuidoB() {
    int2 p = int2(__nv_fragCoord.xy);
    int L = p.x < 8 ? 5 : (p.x < 12 ? 6 : (p.x < 14 ? 7 : (p.x < 15 ? 8 : 0)));
    if (L == 0 || p.y >= (256 >> L)) return float4(0.0);
    int2 t = p - nvMipOrigem[L];
    int n = 1 << (L - 4);
    float4 soma = float4(0.0);
    for (int j = 0; j < 16; j++) {
        if (j >= n) break;
        for (int i = 0; i < 16; i++) {
            if (i >= n) break;
            soma += ruidoMipA.read(uint2(nvMipOrigem[4] + t * n + int2(i, j)), uint(0));
        }
    }
    return soma / float(n * n);
}
// ---- fim da textura "noise" ----

float4 lerPre(float2 uv) { return pre.sample(__nv_smp, uv); }
float4 lerBuff1(float2 uv) { return vhsBuff.sample(__nv_smp, uv); }

// `_vhs_buff2`: o VHSBuff2 com o VHS ligado; desligado, a própria camada.
float4 lerBuff2(float2 uv) {
    return u._enable_vhs ? vhsBuff2.sample(__nv_smp, uv) : pre.sample(__nv_smp, uv);
}

// O programa 0 do shader NodeVideo/AssetStore/vhs do Node, conta por conta (tools/nodepassesc/montar.py).
float4 vhsReduzir(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);
    float4 u_xlat0;
    float3 u_xlat1;
    int u_xlati1;
    uint u_xlatu1;
    bool2 u_xlatb1;
    float3 u_xlat2;
    int2 u_xlati2;
    uint u_xlatu2;
    bool2 u_xlatb2;
    float3 u_xlat3;
    float4 u_xlat4;
    float u_xlat6;
    int u_xlati6;
    uint u_xlatu6;
    float3 u_xlat7;
    int2 u_xlati7;
    uint u_xlatu7;
    bool u_xlatb7;
    float u_xlat10;
    uint u_xlatu11;
    uint u_xlatu12;
    bool2 u_xlatb12;
    float u_xlat15;
    bool u_xlatb15;
    float u_xlat16;
    int u_xlati16;
    uint u_xlatu16;
    bool u_xlatb16;
    uint u_xlatu17;

    u_xlat0.xy = in.vs_TEXCOORD0.xy * _resolution.xy;
    u_xlat10 = lerPre( in.vs_TEXCOORD0.xy).w;
    u_xlat0.xy = u_xlat0.xy / _vhs_res.xy;
    u_xlat1.xy = u_xlat0.xy + float2(-0.5, -0.5);
    u_xlatb1.xy = lessThan(abs(u_xlat1.xyxx), float4(0.5, 0.5, 0.0, 0.0)).xy;
    u_xlatb15 = u_xlatb1.y && u_xlatb1.x;
    if(u_xlatb15){
        u_xlatb1.x = 0<int(u._length);
        if(u_xlatb1.x){
            u_xlati1 = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu6 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu6 = uint(u_xlatu6 >> (1u & uint(0x1F)));
            u_xlatu11 =  uint(0 - int(u_xlatu6));
            u_xlati1 = int(uint(uint(u_xlati1) & 2147483648u));
            u_xlatu1 = (u_xlati1 != 0) ? u_xlatu11 : u_xlatu6;
            u_xlat1.x = float((-int(u_xlatu1)));
            u_xlat1.x = u_xlat1.x / _vhs_res.x;
            u_xlat1.y = 0.0;
            u_xlat1.xy = u_xlat0.xy + (-u_xlat1.xy);
            u_xlat1.xyz = lerPre( u_xlat1.xy).xyz;
            u_xlat1.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat1.xyz);
            u_xlati6 = int(u._length) + int(0xFFFFFFFFu);
            u_xlat6 = float(u_xlati6);
            u_xlat2.x = u_xlat6 * u_xlat1.x;
            u_xlat2.y = float(0.0);
            u_xlat2.z = float(0.0);
            u_xlat1.xyz = u_xlat2.xyz / float3(u_xlat6);
            u_xlat16 = float(int(u._length));
            u_xlat1.xyz = u_xlat1.xyz / float3(u_xlat16);
            u_xlat1.xyz = u_xlat1.xyz + u_xlat1.xyz;
            u_xlati16 = 1;
        } else {
            u_xlat1.x = float(0.0);
            u_xlat1.y = float(0.0);
            u_xlat1.z = float(0.0);
            u_xlati16 = int(0);
        }
        u_xlatb2.x = u_xlati16<int(u._length);
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 1;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFFEu));
            u_xlat4.y = float(1.0);
            u_xlat4.z = float(1.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 2;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 2;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFFDu));
            u_xlat4.y = float(2.0);
            u_xlat4.z = float(2.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 3;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 3;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFFCu));
            u_xlat4.y = float(3.0);
            u_xlat4.z = float(3.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 4;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 4;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFFBu));
            u_xlat4.y = float(4.0);
            u_xlat4.z = float(4.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 5;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 5;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFFAu));
            u_xlat4.y = float(5.0);
            u_xlat4.z = float(5.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 6;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 6;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFF9u));
            u_xlat4.y = float(6.0);
            u_xlat4.z = float(6.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 7;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 7;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFF8u));
            u_xlat4.y = float(7.0);
            u_xlat4.z = float(7.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 8;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 8;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFF7u));
            u_xlat4.y = float(8.0);
            u_xlat4.z = float(8.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 9;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 9;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFF6u));
            u_xlat4.y = float(9.0);
            u_xlat4.z = float(9.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 10;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 10;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFF5u));
            u_xlat4.y = float(10.0);
            u_xlat4.z = float(10.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 11;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 11;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFF4u));
            u_xlat4.y = float(11.0);
            u_xlat4.z = float(11.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 12;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 12;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFF3u));
            u_xlat4.y = float(12.0);
            u_xlat4.z = float(12.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 13;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 13;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFF2u));
            u_xlat4.y = float(13.0);
            u_xlat4.z = float(13.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 14;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 14;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFF1u));
            u_xlat4.y = float(14.0);
            u_xlat4.z = float(14.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 15;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 15;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFF0u));
            u_xlat4.y = float(15.0);
            u_xlat4.z = float(15.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 16;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 16;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFEFu));
            u_xlat4.y = float(16.0);
            u_xlat4.z = float(16.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 17;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 17;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFEEu));
            u_xlat4.y = float(17.0);
            u_xlat4.z = float(17.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 18;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 18;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFEDu));
            u_xlat4.y = float(18.0);
            u_xlat4.z = float(18.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 19;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 19;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFECu));
            u_xlat4.y = float(19.0);
            u_xlat4.z = float(19.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 20;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 20;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFEBu));
            u_xlat4.y = float(20.0);
            u_xlat4.z = float(20.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 21;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 21;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFEAu));
            u_xlat4.y = float(21.0);
            u_xlat4.z = float(21.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 22;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 22;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFE9u));
            u_xlat4.y = float(22.0);
            u_xlat4.z = float(22.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 23;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 23;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFE8u));
            u_xlat4.y = float(23.0);
            u_xlat4.z = float(23.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 24;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 24;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFE7u));
            u_xlat4.y = float(24.0);
            u_xlat4.z = float(24.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 25;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 25;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFE6u));
            u_xlat4.y = float(25.0);
            u_xlat4.z = float(25.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 26;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 26;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFE5u));
            u_xlat4.y = float(26.0);
            u_xlat4.z = float(26.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 27;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 27;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFE4u));
            u_xlat4.y = float(27.0);
            u_xlat4.z = float(27.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 28;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 28;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFE3u));
            u_xlat4.y = float(28.0);
            u_xlat4.z = float(28.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 29;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 29;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFE2u));
            u_xlat4.y = float(29.0);
            u_xlat4.z = float(29.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 30;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 30;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFE1u));
            u_xlat4.y = float(30.0);
            u_xlat4.z = float(30.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 31;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 31;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFE0u));
            u_xlat4.y = float(31.0);
            u_xlat4.z = float(31.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 32;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 32;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFDFu));
            u_xlat4.y = float(32.0);
            u_xlat4.z = float(32.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 33;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 33;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFDEu));
            u_xlat4.y = float(33.0);
            u_xlat4.z = float(33.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 34;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 34;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFDDu));
            u_xlat4.y = float(34.0);
            u_xlat4.z = float(34.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 35;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 35;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFDCu));
            u_xlat4.y = float(35.0);
            u_xlat4.z = float(35.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 36;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 36;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFDBu));
            u_xlat4.y = float(36.0);
            u_xlat4.z = float(36.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 37;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 37;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFDAu));
            u_xlat4.y = float(37.0);
            u_xlat4.z = float(37.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 38;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 38;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFD9u));
            u_xlat4.y = float(38.0);
            u_xlat4.z = float(38.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 39;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 39;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFD8u));
            u_xlat4.y = float(39.0);
            u_xlat4.z = float(39.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 40;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 40;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFD7u));
            u_xlat4.y = float(40.0);
            u_xlat4.z = float(40.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 41;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 41;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFD6u));
            u_xlat4.y = float(41.0);
            u_xlat4.z = float(41.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 42;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 42;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFD5u));
            u_xlat4.y = float(42.0);
            u_xlat4.z = float(42.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 43;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 43;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFD4u));
            u_xlat4.y = float(43.0);
            u_xlat4.z = float(43.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 44;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 44;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFD3u));
            u_xlat4.y = float(44.0);
            u_xlat4.z = float(44.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 45;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 45;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFD2u));
            u_xlat4.y = float(45.0);
            u_xlat4.z = float(45.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 46;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 46;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFD1u));
            u_xlat4.y = float(46.0);
            u_xlat4.z = float(46.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 47;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 47;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFD0u));
            u_xlat4.y = float(47.0);
            u_xlat4.z = float(47.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 48;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 48;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFCFu));
            u_xlat4.y = float(48.0);
            u_xlat4.z = float(48.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 49;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 49;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFCEu));
            u_xlat4.y = float(49.0);
            u_xlat4.z = float(49.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 50;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 50;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFCDu));
            u_xlat4.y = float(50.0);
            u_xlat4.z = float(50.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 51;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 51;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFCCu));
            u_xlat4.y = float(51.0);
            u_xlat4.z = float(51.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 52;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 52;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFCBu));
            u_xlat4.y = float(52.0);
            u_xlat4.z = float(52.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 53;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 53;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFCAu));
            u_xlat4.y = float(53.0);
            u_xlat4.z = float(53.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 54;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 54;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFC9u));
            u_xlat4.y = float(54.0);
            u_xlat4.z = float(54.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 55;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 55;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFC8u));
            u_xlat4.y = float(55.0);
            u_xlat4.z = float(55.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 56;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 56;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFC7u));
            u_xlat4.y = float(56.0);
            u_xlat4.z = float(56.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 57;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 57;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFC6u));
            u_xlat4.y = float(57.0);
            u_xlat4.z = float(57.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 58;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 58;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFC5u));
            u_xlat4.y = float(58.0);
            u_xlat4.z = float(58.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 59;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 59;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFC4u));
            u_xlat4.y = float(59.0);
            u_xlat4.z = float(59.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 60;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 60;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFC3u));
            u_xlat4.y = float(60.0);
            u_xlat4.z = float(60.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 61;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 61;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFC2u));
            u_xlat4.y = float(61.0);
            u_xlat4.z = float(61.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 62;
        }
        u_xlatb7 = u_xlati16<int(u._length);
        u_xlatb2.x = u_xlatb7 && u_xlatb2.x;
        if(u_xlatb2.x){
            u_xlati7.x = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu12 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu12 = uint(u_xlatu12 >> (1u & uint(0x1F)));
            u_xlatu17 =  uint(0 - int(u_xlatu12));
            u_xlati7.x = int(uint(uint(u_xlati7.x) & 2147483648u));
            u_xlatu7 = (u_xlati7.x != 0) ? u_xlatu17 : u_xlatu12;
            u_xlati7.x = (-int(u_xlatu7)) + 62;
            u_xlat7.x = float(u_xlati7.x);
            u_xlat3.x = u_xlat7.x / _vhs_res.x;
            u_xlat3.y = 0.0;
            u_xlat7.xy = u_xlat0.xy + (-u_xlat3.xy);
            u_xlat7.xyz = lerPre( u_xlat7.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat7.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat7.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat7.xyz);
            u_xlati7.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFC1u));
            u_xlat4.y = float(62.0);
            u_xlat4.z = float(62.0);
            u_xlat4.xw = float2(u_xlati7.yx);
            u_xlat7.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat7.xyz = u_xlat7.xyz / u_xlat4.www;
            u_xlat3.x = float(int(u._length));
            u_xlat7.xyz = u_xlat7.xyz / u_xlat3.xxx;
            u_xlat1.xyz = u_xlat7.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
            u_xlati16 = 63;
        }
        u_xlatb16 = u_xlati16<int(u._length);
        u_xlatb16 = u_xlatb16 && u_xlatb2.x;
        if(u_xlatb16){
            u_xlati16 = int(uint(uint(int(u._length)) ^ 2u));
            u_xlatu2 =  uint(max(int(u._length), (-int(u._length))));
            u_xlatu2 = uint(u_xlatu2 >> (1u & uint(0x1F)));
            u_xlatu7 =  uint(0 - int(u_xlatu2));
            u_xlati16 = int(uint(uint(u_xlati16) & 2147483648u));
            u_xlatu16 = (u_xlati16 != 0) ? u_xlatu7 : u_xlatu2;
            u_xlati16 = (-int(u_xlatu16)) + 63;
            u_xlat16 = float(u_xlati16);
            u_xlat2.x = u_xlat16 / _vhs_res.x;
            u_xlat2.y = 0.0;
            u_xlat2.xy = u_xlat0.xy + (-u_xlat2.xy);
            u_xlat2.xyz = lerPre( u_xlat2.xy).xyz;
            u_xlat3.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat2.xyz);
            u_xlat3.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat2.xyz);
            u_xlat3.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat2.xyz);
            u_xlati2.xy = int2(int2(int(u._length), int(u._length))) + int2(int(0xFFFFFFFFu), int(0xFFFFFFC0u));
            u_xlat4.y = float(63.0);
            u_xlat4.z = float(63.0);
            u_xlat4.xw = float2(u_xlati2.yx);
            u_xlat2.xyz = u_xlat3.xyz * u_xlat4.xyz;
            u_xlat2.xyz = u_xlat2.xyz / u_xlat4.www;
            u_xlat16 = float(int(u._length));
            u_xlat2.xyz = u_xlat2.xyz / float3(u_xlat16);
            u_xlat1.xyz = u_xlat2.xyz * float3(2.0, 2.0, 2.0) + u_xlat1.xyz;
        }
        u_xlat2.x = dot(float3(1.0, 1.0, 1.0), u_xlat1.xyz);
        u_xlat2.y = dot(float3(0.95599997, -0.272000015, -1.10599995), u_xlat1.xyz);
        u_xlat2.z = dot(float3(0.620999992, -0.647000015, 1.70299995), u_xlat1.xyz);
    }
    u_xlat1.xyz = (bool(u_xlatb15)) ? u_xlat2.xyz : float3(0.100000001, 0.100000001, 0.100000001);
    u_xlat15 = dot(float2(float2(eng.acTime, eng.acTime)), float2(u._scanline_speed));
    u_xlat15 = u_xlat15 + u_xlat0.y;
    u_xlat2.y = u_xlat15 * 0.100000001;
    u_xlat2.x = 0.0;
    u_xlat2.xy = u_xlat2.xy / float2(10.0, 10.0);
    u_xlat2.xy = u_xlat2.xy / float2(1.0, 1.0);
    u_xlatb12.xy = greaterThanEqual(u_xlat2.xyxy, (-u_xlat2.xyxy)).xy;
    u_xlat2.xy = fract(abs(u_xlat2.xy));
    {
        float3 hlslcc_movcTemp = u_xlat2;
        hlslcc_movcTemp.x = (u_xlatb12.x) ? u_xlat2.x : (-u_xlat2.x);
        hlslcc_movcTemp.y = (u_xlatb12.y) ? u_xlat2.y : (-u_xlat2.y);
        u_xlat2 = hlslcc_movcTemp;
    }
    u_xlat15 = lerRuidoNode( u_xlat2.xy).x;
    u_xlat15 = u_xlat15 + -0.400000006;
    u_xlat15 = u_xlat15 * 4.99999952;
    u_xlat15 = clamp(u_xlat15, 0.0, 1.0);
    u_xlat16 = u_xlat15 * -2.0 + 3.0;
    u_xlat15 = u_xlat15 * u_xlat15;
    u_xlat15 = u_xlat15 * u_xlat16;
    u_xlat15 = u._scanline * u_xlat15 + 1.0;
    u_xlat1.xyz = float3(u_xlat15) * u_xlat1.xyz;
    u_xlat0.xy = float2(float2(eng.acTime, eng.acTime)) * float2(59.6999969, 44.5) + u_xlat0.xy;
    u_xlatb2.xy = greaterThanEqual(u_xlat0.xyxx, (-u_xlat0.xyxx)).xy;
    u_xlat0.xy = fract(abs(u_xlat0.xy));
    {
        float4 hlslcc_movcTemp = u_xlat0;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? u_xlat0.x : (-u_xlat0.x);
        hlslcc_movcTemp.y = (u_xlatb2.y) ? u_xlat0.y : (-u_xlat0.y);
        u_xlat0 = hlslcc_movcTemp;
    }
    u_xlat0.xyw = lerRuidoNode( u_xlat0.xy).xyz;
    u_xlat0.xyw = float3(float3(u._grain, u._grain, u._grain)) * u_xlat0.xyw + float3(0.899999976, 0.899999976, 0.899999976);
    u_xlat0.xyw = u_xlat0.xyw * u_xlat1.xyz;
    u_xlat0.xyw = clamp(u_xlat0.xyw, 0.0, 1.0);
    u_xlat1.x = dot(float3(0.298999995, 0.596000016, 0.210999995), u_xlat0.xyw);
    u_xlat1.y = dot(float3(0.587000012, -0.273999989, -0.523000002), u_xlat0.xyw);
    u_xlat1.z = dot(float3(0.114, -0.321999997, 0.312000006), u_xlat0.xyw);
    u_xlat0.xyw = u._color_offset.xyz * float3(0.100000001, 0.100000001, 0.100000001) + u_xlat1.xyz;
    SV_Target0.x = dot(float3(1.0, 1.0, 1.0), u_xlat0.xyw);
    SV_Target0.y = dot(float3(0.95599997, -0.272000015, -1.10599995), u_xlat0.xyw);
    SV_Target0.z = dot(float3(0.620999992, -0.647000015, 1.70299995), u_xlat0.xyw);
    SV_Target0.w = u_xlat10;
    return SV_Target0;
    return SV_Target0;
}

// O programa 1 do shader NodeVideo/AssetStore/vhs do Node, conta por conta (tools/nodepassesc/montar.py).
float4 vhsAumentar(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);
    float4 u_xlat0;
    float4 u_xlat1;
    float u_xlat2;
    bool2 u_xlatb2;
    float4 u_xlat3;
    float4 u_xlat4;
    float4 u_xlat5;

    u_xlat0.xy = in.vs_TEXCOORD0.xy * _resolution.xy;
    u_xlat0.xy = u_xlat0.xy / _resolution.xy;
    u_xlat0.xy = u_xlat0.xy / _resolution.xy;
    u_xlat0.xy = u_xlat0.xy * _vhs_res.xy;
    u_xlat0 = lerBuff1( u_xlat0.xy);
    if(0 != 0) {
        u_xlat1 = lerPre( in.vs_TEXCOORD0.xy);
        u_xlatb2.xy = equal(int4(0, 0, 0, 0), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = lerPre( in.vs_TEXCOORD0.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat2 = u_xlat4.x * u_xlat1.w;
        SV_Target0.w = (u_xlatb2.y) ? u_xlat2 : u_xlat1.w;
        SV_Target0.xyz = u_xlat1.xyz;
    } else {
        SV_Target0 = u_xlat0;
    }
    return SV_Target0;
    return SV_Target0;
}

// O programa 2 do shader NodeVideo/AssetStore/vhs do Node, conta por conta (tools/nodepassesc/montar.py).
float4 vhsCompor(float2 in.vs_TEXCOORD0)
{
    float4 SV_Target0 = float4(0.0);
    float4 u_xlat0;
    float4 u_xlat1;
    bool u_xlatb1;
    float4 u_xlat2;
    int u_xlati2;
    uint u_xlatu2;
    bool2 u_xlatb2;
    float4 u_xlat3;
    bool2 u_xlatb3;
    float4 u_xlat4;
    float4 u_xlat5;
    float2 u_xlat6;
    bool u_xlatb6;
    float u_xlat7;
    float2 u_xlat8;
    float2 u_xlat13;
    int u_xlati14;
    float u_xlat18;
    int u_xlati18;
    uint u_xlatu18;
    float u_xlat20;

    u_xlat0.yz = in.vs_TEXCOORD0.xy * _resolution.xy;
    u_xlatb1 = 0<int(u._enable_wave);
    if(u_xlatb1){
        u_xlat1.x = eng.acTime + u._phase;
        u_xlat7 = u._width * 0.00999999978;
        u_xlat0.x = u_xlat1.x * u._speed;
        u_xlat1.x = dot(u_xlat0.xz, float2(12.9898005, 78.2330017));
        u_xlat1.x = sin(u_xlat1.x);
        u_xlat1.x = u_xlat1.x * 43758.5469;
        u_xlat1.x = fract(u_xlat1.x);
        u_xlat1.x = u_xlat1.x * u_xlat7;
        u_xlat7 = in.vs_TEXCOORD0.y * 2.10486722;
        u_xlat0.x = u_xlat0.x * 0.25 + u_xlat7;
        u_xlat2.x = cos(u_xlat0.x);
        u_xlat0.x = sin(u_xlat0.x);
        u_xlat0.x = u_xlat0.x / u_xlat2.x;
        u_xlat0.x = min(u_xlat0.x, 0.0);
        u_xlat0.x = u_xlat0.x * u_xlat1.x;
        u_xlat1.x = u_xlat1.x * 1.5;
        u_xlat1.y = float(0.0);
        u_xlat13.y = float(0.0);
        u_xlat1.xy = u_xlat1.xy + in.vs_TEXCOORD0.xy;
        u_xlat13.x = u_xlat0.x * 1.29999995;
        u_xlat1.xy = u_xlat13.xy + u_xlat1.xy;
        u_xlat1.xy = u_xlat1.xy * float2(1.005, 1.005);
        u_xlat1 = lerBuff2( u_xlat1.xy);
    } else {
        u_xlat1 = lerBuff2( in.vs_TEXCOORD0.xy);
    }
    u_xlatb2.xy = lessThan(int4(0, 0, 0, 0), int4(int(u._enable_noises1), int(u._enable_noises2), int(u._enable_noises1), int(u._enable_noises1))).xy;
    if(u_xlatb2.x){
        u_xlat0.x = u._size * 10.0;
        u_xlat0.x = _resolution.y / u_xlat0.x;
        u_xlat0.w = eng.acTime;
        u_xlat18 = dot(u_xlat0.wz, float2(12.9898005, 78.2330017));
        u_xlat18 = sin(u_xlat18);
        u_xlat18 = u_xlat18 * 43758.5469;
        u_xlat18 = fract(u_xlat18);
        u_xlat18 = u_xlat18 * eng.acTime;
        u_xlat18 = u_xlat18 * 1000.0 + u_xlat0.z;
        u_xlati18 = int(u_xlat18);
        u_xlat2.x = u._intensity1 * 4.0 + u_xlat0.x;
        u_xlati2 = int(u_xlat2.x);
        u_xlati14 = int(uint(uint(u_xlati18) & 2147483648u));
        u_xlatu18 =  uint(max(u_xlati18, (-u_xlati18)));
        u_xlatu2 =  uint(max(u_xlati2, (-u_xlati2)));
        {
            uint rem = u_xlatu18 % u_xlatu2;
            u_xlatu18 = rem;
        }
        u_xlatu2 =  uint(0 - int(u_xlatu18));
        u_xlatu18 = (u_xlati14 != 0) ? u_xlatu2 : u_xlatu18;
        u_xlat18 = float(int(u_xlatu18));
        u_xlat0.x = u_xlat18 / u_xlat0.x;
        u_xlat0.x = floor(u_xlat0.x);
        u_xlat3.x = float(0.0);
        u_xlat3.w = float(1.0);
        u_xlat3.y = eng.acTime * 100.0;
        u_xlat2.xz = _resolution.xy * in.vs_TEXCOORD0.xy + u_xlat3.xy;
        u_xlat2.xz = u_xlat2.xz / _resolution.xy;
        u_xlatb3.xy = greaterThanEqual(u_xlat2.xzxx, (-u_xlat2.xzxx)).xy;
        u_xlat2.xz = fract(abs(u_xlat2.xz));
        {
            float4 hlslcc_movcTemp = u_xlat2;
            hlslcc_movcTemp.x = (u_xlatb3.x) ? u_xlat2.x : (-u_xlat2.x);
            hlslcc_movcTemp.z = (u_xlatb3.y) ? u_xlat2.z : (-u_xlat2.z);
            u_xlat2 = hlslcc_movcTemp;
        }
        u_xlat2.xz = u_xlat2.xz * _resolution.xy;
        u_xlat2.xz = u_xlat2.xz / _resolution.xy;
        u_xlat18 = lerRuidoNode( u_xlat2.xz).x;
        u_xlat18 = log2(u_xlat18);
        u_xlat18 = u_xlat18 * 7.0;
        u_xlat18 = exp2(u_xlat18);
        u_xlat2.xzw = float3(u_xlat18) * u_xlat0.xxx + u_xlat1.xyz;
        u_xlat3.xyz = min(u_xlat2.xzw, float3(1.0, 1.0, 1.0));
        u_xlat0.xw = in.vs_TEXCOORD0.xy * float2(3.14159274, 3.14159274);
        u_xlat0.xw = sin(u_xlat0.xw);
        u_xlat0.x = (-u_xlat0.x) * u_xlat0.w + 1.0;
        u_xlat0.x = u_xlat0.x * u._vignette;
        u_xlat1 = (-u_xlat0.xxxx) * float4(0.200000003, 0.200000003, 0.200000003, 0.200000003) + u_xlat3;
    }
    if(u_xlatb2.y){
        u_xlat0.x = u._continues * 1000.0;
        u_xlat0.x = _resolution.y / u_xlat0.x;
        u_xlat6.xy = u_xlat0.yz / u_xlat0.xx;
        u_xlat6.xy = floor(u_xlat6.xy);
        u_xlat0.yz = u_xlat0.xx * u_xlat6.xy;
        u_xlat18 = eng.acTime + u._phase2;
        u_xlat18 = u_xlat18 * u._speed2;
        u_xlat2.x = u_xlat18 + u_xlat18;
        u_xlat2.xyz = u_xlat0.zzz * float3(0.00999999978, 0.0109999999, 0.50999999) + u_xlat2.xxx;
        u_xlat20 = floor(u_xlat2.x);
        u_xlat3.xyz = fract(u_xlat2.xyz);
        u_xlat4.xyz = u_xlat3.xyz * u_xlat3.xyz;
        u_xlat3.xyz = (-u_xlat3.xyz) * float3(2.0, 2.0, 2.0) + float3(3.0, 3.0, 3.0);
        u_xlat3.xyz = u_xlat3.xyz * u_xlat4.xyz;
        u_xlat2.xw = float2(u_xlat20) + float2(170.0, 171.0);
        u_xlat2.xw = sin(u_xlat2.xw);
        u_xlat2.xw = u_xlat2.xw * float2(43758.5469, 43758.5469);
        u_xlat2.xw = fract(u_xlat2.xw);
        u_xlat20 = (-u_xlat2.x) + u_xlat2.w;
        u_xlat2.x = u_xlat3.x * u_xlat20 + u_xlat2.x;
        u_xlat4 = u_xlat2.yyzz + float4(1000.0, 1000.0, 421.0, 421.0);
        u_xlat4 = floor(u_xlat4);
        u_xlat4 = u_xlat4 + float4(170.0, 171.0, 170.0, 171.0);
        u_xlat4 = sin(u_xlat4);
        u_xlat4 = u_xlat4 * float4(43758.5469, 43758.5469, 43758.5469, 43758.5469);
        u_xlat4 = fract(u_xlat4);
        u_xlat8.xy = (-u_xlat4.xz) + u_xlat4.yw;
        u_xlat8.xy = u_xlat3.yz * u_xlat8.xy + u_xlat4.xz;
        u_xlat2.x = u_xlat8.x * u_xlat2.x;
        u_xlat2.x = u_xlat8.y * u_xlat2.x;
        u_xlat0.x = u_xlat18 * 0.00999999978 + u_xlat0.y;
        u_xlat0 = u_xlat0.zxxz * float4(470.782715, 491.187103, 443.897491, 397.297302);
        u_xlat0 = fract(u_xlat0);
        u_xlat3 = u_xlat0.zwyx + float4(19.1900005, 19.1900005, 19.1900005, 19.1900005);
        u_xlat0.x = dot(u_xlat0, u_xlat3);
        u_xlat0.xy = u_xlat0.xx + u_xlat0.zw;
        u_xlat0.x = u_xlat0.y * u_xlat0.x;
        u_xlat0.x = fract(u_xlat0.x);
        u_xlat0.x = u_xlat0.x + 0.300000012;
        u_xlat0.x = u_xlat2.x * u_xlat0.x + 0.300000012;
        u_xlatb6 = u_xlat0.x<0.699999988;
        u_xlat0.x = u_xlat0.x * u._intensity2;
        u_xlat0.x = (u_xlatb6) ? 0.0 : u_xlat0.x;
        u_xlat1.xyz = u_xlat0.xxx + u_xlat1.xyz;
    }
    if(0 != 0) {
        u_xlat0 = lerPre( in.vs_TEXCOORD0.xy);
        u_xlatb2.xy = equal(int4(0, 0, 0, 0), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = lerPre( in.vs_TEXCOORD0.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat3 * u_xlat4 + u_xlat0;
        u_xlat2.x = u_xlat4.x * u_xlat0.w;
        SV_Target0.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat0.w;
        SV_Target0.xyz = u_xlat0.xyz;
    } else {
        SV_Target0 = u_xlat1;
    }
    return SV_Target0;
    return SV_Target0;
}

fragment float4 fx_nv_nodevideo_assetstore_vhs(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_vhsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pre [[texture(1)]],
    texture2d<float> vhsBuff [[texture(2)]],
    texture2d<float> vhsBuff2 [[texture(3)]],
    texture2d<float> ruidoNode [[texture(4)]],
    texture2d<float> ruidoMipA [[texture(5)]],
    texture2d<float> ruidoMipB [[texture(6)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = nvFonte(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = nvMipRuidoA(); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = nvMipRuidoB(); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = vhsReduzir(in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 4) { __nv_out = vhsAumentar(in.acScreenNorm); return __nv_out; }
    __nv_out = nvVolta(vhsCompor(nvUvDePe()));
    return __nv_out;
}
