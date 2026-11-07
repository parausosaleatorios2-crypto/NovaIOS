// ---------------------------------------------------------------------------
// Effect Stylize Lightstreak (NV)
// origem : assets/effects/nv-nodevideo-effect-stylize-lightstreak.xml
// id     : nv.effect.nodevideo-effect-stylize-lightstreak
// passes : 22
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_stylize_lightstreakParams {
    float _threshold;
    float _intensity;
    float _blur;
    float _stretch;
    float4 _tint;
};

// --- funcoes auxiliares do efeito
// ---- a ponte Nova <-> Node (tools/nodeluzes/gerar.py)
float2 nvUV;   // o in.vs_TEXCOORD0 dos programas do Node: o in.acScreenNorm, ou outro ponto que o passe escolhe
float3 nvLinear(float3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(0.04045, c)); }
float3 nvGama(float3 c) { return mix(c * 12.92, 1.055 * pow(c, float3(1.0 / 2.4)) - 0.055, step(0.0031308, c)); }
// O passe 0: a camada como o Node a guarda (pre-multiplicada, luz linear; o buffer `pre` e sRGB de 8 bits).
float4 nvCor(float4 c) { return float4(nvLinear(c.rgb), c.a); }
float4 nvEntrada() { float4 c = inputImg.sample(__nv_smp, in.acScreenNorm); return float4(nvLinear(c.rgb) * c.a, c.a); }
// A saída do Node (pre-multiplicada, linear, presa a 0..1 como o RT de 8 bits) para a cor reta do Nova. A luz que
// o Node soma acima do alfa (o brilho fora do recorte) vira alfa: a = max(alfa, r, g, b). NaN (0 x infinito na
// conta do Node) vira 0, como no RT de 8 bits dele; a escolha pelo bvec não faz conta com o NaN.
float4 nvSaida(float4 p) {
    p = mix(float4(0.0), min(p, float4(1.0)), greaterThanEqual(p, float4(0.0)));
    float a = max(p.a, max(p.r, max(p.g, p.b)));
    return a > 0.0 ? float4(nvGama(p.rgb / a), a) : float4(0.0);
}
// A máscara interna do Node (o editor de máscara dele) fica desligada, como no padrão.
#define _use_inner_mask 0
#define _b_clip_mask 0
#define _show_inner_mask 0
// O RenderCommand.DoGaussianBlur do Node (node-gaussian-blur.xml): na METADE da composição, meio-lado = quantidade x
// 0,0475 x a diagonal da composição (em px da metade), sigma = meio-lado x 0,4660. Aqui a mesma gaussiana em UV,
// separável, com no máximo 32 leituras de cada lado (o passo cresce com o sigma; o filtro linear cobre o meio).
float4 nvGauss(sampler2D t, float2 eixo, float quant) {
    float2 metade = 0.5 * eng.acTamanhoDaTela;
    float meio = quant * 0.0475 * length(eng.acTamanhoDaTela) * 0.4660;
    float sigmaUv = dot(eixo, float2(meio) / metade);
    float texel = dot(eixo, 1.0 / float2(int2(int(t.get_width()), int(t.get_height()))));
    if (sigmaUv < 0.05 * texel) return t.sample(__nv_smp, in.acScreenNorm);
    float passo = max(texel, 3.0 * sigmaUv / 32.0);
    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int i = -32; i <= 32; i++) {
        float d = float(i) * passo;
        if (abs(d) > 3.0 * sigmaUv + passo) continue;
        float w = exp(-0.5 * d * d / (sigmaUv * sigmaUv));
        soma += w * t.sample(__nv_smp, clamp(in.acScreenNorm + eixo * d, 0.0, 1.0));
        pesos += w;
    }
    return soma / pesos;
}
// A StreakPyramid do C# (Allocate(1)): o nível 0 = W x H (o pré-filtro); o nível i = (W >> i) x H enquanto
// W >> (i-1) >= 8 — a altura nunca cai. W = a largura em que o efeito roda (a do Node na exportação).
#define nvTela float2(int2(int(pre.get_width()), int(pre.get_height())))
int nvL() {
    int w = int2(int(pre.get_width()), int(pre.get_height())).x, l = 0;
    for (int i = 1; i < 16; i++) if ((w >> (i - 1)) >= 8) l = i;
    return min(l, 9);
}
// Os programas do Node andam 1/_ScreenSize por leitura em TODO nível: o rastro vem da largura baixa de cada nível
// (o filtro linear entre texels de 2^i px). O motor só reduz a largura até 1/4 (`pack`), então cada nível guarda, num
// buffer mais largo, a reta entre os centros dos texels do nível de verdade: o que o filtro linear do Node leria.
float nvLarg(int i) { return float(int2(int(pre.get_width()), int(pre.get_height())).x >> i); }
float2 nvCentros(int i, out float f) {
    float w = nvLarg(i);
    float p = in.acScreenNorm.x * w - 0.5, k = floor(p);
    f = p - k;
    return clamp(float2(k + 0.5, k + 1.5) / w, 0.5 / w, 1.0 - 0.5 / w);
}

// ---- programa 0 do Node: NodeVideo_Effect_Stylize_LightStreak_0.glsl
float3 p0_x0;
uint2 p0_xu0;
float3 p0_x1;
uint2 p0_xu4;
float p0_x6;
void p0_main(sampler2D _SourceTexture)
{
    p0_x0.xy = nvUV.xy * nvTela.xy;
    p0_xu0.xy = uint2(p0_x0.xy);
    p0_xu4.xy = p0_xu0.xy + uint2(uint(0u), 1u);
    p0_x0.xy = float2(p0_xu0.xy);
    p0_x0.xy = p0_x0.xy / nvTela.xy;
    p0_x1.xyz = _SourceTexture.sample(__nv_smp, p0_x0.xy).xyz;
    p0_x0.xy = float2(p0_xu4.xy);
    p0_x0.xy = p0_x0.xy / nvTela.xy;
    p0_x0.xyz = _SourceTexture.sample(__nv_smp, p0_x0.xy).xyz;
    p0_x0.xyz = p0_x0.xyz + p0_x1.xyz;
    p0_x0.xyz = p0_x0.xyz * float3(0.5, 0.5, 0.5);
    p0_x6 = max(p0_x0.z, p0_x0.y);
    p0_x6 = max(p0_x6, p0_x0.x);
    p0_x1.x = p0_x6 + (-u._threshold);
    p0_x6 = max(p0_x6, 9.99999975e-06);
    p0_x1.x = max(p0_x1.x, 0.0);
    p0_x6 = p0_x1.x / p0_x6;
    __nv_out.xyz = float3(p0_x6) * p0_x0.xyz;
    __nv_out.w = 1.0;
    return;
}

// ---- programa 1 do Node: NodeVideo_Effect_Stylize_LightStreak_1.glsl
float3 p1_x0;
float4 p1_x1;
float3 p1_x2;
float p1_x9;
void p1_main(sampler2D _InputTexture)
{
    p1_x0.z = nvUV.y;
    p1_x9 = float(1.0) / nvTela.x;
    p1_x0.xy = (-float2(p1_x9)) * float2(5.0, 3.0) + nvUV.xx;
    p1_x1.xyz = _InputTexture.sample(__nv_smp, p1_x0.xz).xyz;
    p1_x0.xyz = _InputTexture.sample(__nv_smp, p1_x0.yz).xyz;
    p1_x0.xyz = p1_x0.xyz * float3(2.0, 2.0, 2.0) + p1_x1.xyz;
    p1_x1.x = (-p1_x9) + nvUV.x;
    p1_x1.yw = nvUV.yy;
    p1_x2.xyz = _InputTexture.sample(__nv_smp, p1_x1.xy).xyz;
    p1_x0.xyz = p1_x2.xyz * float3(3.0, 3.0, 3.0) + p1_x0.xyz;
    p1_x1.z = p1_x9 + nvUV.x;
    p1_x2.xy = float2(p1_x9) * float2(3.0, 5.0) + nvUV.xx;
    p1_x1.xyz = _InputTexture.sample(__nv_smp, p1_x1.zw).xyz;
    p1_x0.xyz = p1_x1.xyz * float3(3.0, 3.0, 3.0) + p1_x0.xyz;
    p1_x2.z = nvUV.y;
    p1_x1.xyz = _InputTexture.sample(__nv_smp, p1_x2.xz).xyz;
    p1_x2.xyz = _InputTexture.sample(__nv_smp, p1_x2.yz).xyz;
    p1_x0.xyz = p1_x1.xyz * float3(2.0, 2.0, 2.0) + p1_x0.xyz;
    p1_x0.xyz = p1_x2.xyz + p1_x0.xyz;
    __nv_out.xyz = p1_x0.xyz * float3(0.0833333358, 0.0833333358, 0.0833333358);
    __nv_out.w = 1.0;
    return;
}

// ---- programa 2 do Node: NodeVideo_Effect_Stylize_LightStreak_2.glsl
float3 p2_x0;
float4 p2_x1;
float3 p2_x2;
float p2_x9;
void p2_main(sampler2D _InputTexture, sampler2D _HighTexture)
{
    p2_x0.xyz = _InputTexture.sample(__nv_smp, nvUV.xy).xyz;
    p2_x0.xyz = p2_x0.xyz * float3(0.5, 0.5, 0.5);
    p2_x9 = 1.5 / nvTela.x;
    p2_x1.x = (-p2_x9) + nvUV.x;
    p2_x1.z = p2_x9 + nvUV.x;
    p2_x1.yw = nvUV.yy;
    p2_x2.xyz = _InputTexture.sample(__nv_smp, p2_x1.xy).xyz;
    p2_x1.xyz = _InputTexture.sample(__nv_smp, p2_x1.zw).xyz;
    p2_x0.xyz = p2_x2.xyz * float3(0.25, 0.25, 0.25) + p2_x0.xyz;
    p2_x0.xyz = p2_x1.xyz * float3(0.25, 0.25, 0.25) + p2_x0.xyz;
    p2_x1.xyz = _HighTexture.sample(__nv_smp, nvUV.xy).xyz;
    p2_x0.xyz = p2_x0.xyz + (-p2_x1.xyz);
    __nv_out.xyz = float3(float3(u._stretch, u._stretch, u._stretch)) * p2_x0.xyz + p2_x1.xyz;
    __nv_out.w = 1.0;
    return;
}

// ---- programa 3 do Node: NodeVideo_Effect_Stylize_LightStreak_3.glsl
float3 p3_x0;
float4 p3_x1;
bool2 p3_xb1;
float4 p3_x2;
float4 p3_x3;
float4 p3_x4;
float4 p3_x5;
float p3_x18;
void p3_main(sampler2D _InputTexture)
{
    p3_x0.x = 1.5 / nvTela.x;
    p3_x1.x = (-p3_x0.x) + nvUV.x;
    p3_x1.z = p3_x0.x + nvUV.x;
    p3_x1.yw = nvUV.yy;
    p3_x0.xyz = _InputTexture.sample(__nv_smp, p3_x1.xy).xyz;
    p3_x2.xyz = _InputTexture.sample(__nv_smp, nvUV.xy).xyz;
    p3_x1.xyz = _InputTexture.sample(__nv_smp, p3_x1.zw).xyz;
    p3_x3.xyz = pre.sample(__nv_smp, nvUV.xy).xyz;
    p3_x2.xyz = p3_x2.xyz * float3(0.5, 0.5, 0.5);
    p3_x0.xyz = p3_x0.xyz * float3(0.25, 0.25, 0.25) + p3_x2.xyz;
    p3_x0.xyz = p3_x1.xyz * float3(0.25, 0.25, 0.25) + p3_x0.xyz;
    p3_x0.xyz = p3_x0.xyz * nvCor(u._tint).xyz;
    p3_x0.xyz = p3_x0.xyz * float3(u._intensity);
    p3_x0.xyz = p3_x0.xyz * float3(5.0, 5.0, 5.0) + p3_x3.xyz;
    if(int(_use_inner_mask) != 0) {
        p3_xb1.xy = equal(int4(int(_show_inner_mask), int(_b_clip_mask), int(_show_inner_mask), int(_show_inner_mask)), int4(1, 1, 0, 0)).xy;
        p3_x2.xyz = (p3_xb1.x) ? float3(1.0, 0.0, 1.0) : p3_x0.xyz;
        p3_x2.w = 1.0;
        p3_x4 = pre.sample(__nv_smp, nvUV.xy);
        p3_x5 = (-p3_x4) + float4(1.0, 1.0, 1.0, 1.0);
        p3_x3.w = 1.0;
        p3_x3 = p3_x3 * p3_x5;
        p3_x2 = p3_x2 * p3_x4 + p3_x3;
        p3_x18 = p3_x4.x * p3_x2.w;
        __nv_out.w = (p3_xb1.y) ? p3_x18 : p3_x2.w;
        __nv_out.xyz = p3_x2.xyz;
    } else {
        __nv_out.xyz = p3_x0.xyz;
        __nv_out.w = 1.0;
    }
    return;
}

fragment float4 fx_nv_nodevideo_effect_stylize_lightstreak(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_stylize_lightstreakParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pre [[texture(1)]],
    texture2d<float> blurH [[texture(2)]],
    texture2d<float> blurred [[texture(3)]],
    texture2d<float> mip0 [[texture(4)]],
    texture2d<float> d1 [[texture(5)]],
    texture2d<float> d2 [[texture(6)]],
    texture2d<float> d3 [[texture(7)]],
    texture2d<float> d4 [[texture(8)]],
    texture2d<float> d5 [[texture(9)]],
    texture2d<float> d6 [[texture(10)]],
    texture2d<float> d7 [[texture(11)]],
    texture2d<float> d8 [[texture(12)]],
    texture2d<float> d9 [[texture(13)]],
    texture2d<float> u1 [[texture(14)]],
    texture2d<float> ua [[texture(15)]],
    texture2d<float> ub [[texture(16)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    nvUV = in.acScreenNorm;
    if (eng.acPass == 0) { __nv_out = nvEntrada(); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = nvGauss(pre, float2(1.0, 0.0), u._blur); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = nvGauss(blurH, float2(0.0, 1.0), u._blur); return __nv_out; }
    if (eng.acPass == 3) { p0_main(blurred); return __nv_out; }
    if (eng.acPass == 4) { if (1 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(1, f); nvUV.x = c.x; p1_main(mip0); float4 a = __nv_out; nvUV.x = c.y; p1_main(mip0); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 5) { if (2 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(2, f); nvUV.x = c.x; p1_main(d1); float4 a = __nv_out; nvUV.x = c.y; p1_main(d1); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 6) { if (3 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(3, f); nvUV.x = c.x; p1_main(d2); float4 a = __nv_out; nvUV.x = c.y; p1_main(d2); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 7) { if (4 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(4, f); nvUV.x = c.x; p1_main(d3); float4 a = __nv_out; nvUV.x = c.y; p1_main(d3); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 8) { if (5 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(5, f); nvUV.x = c.x; p1_main(d4); float4 a = __nv_out; nvUV.x = c.y; p1_main(d4); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 9) { if (6 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(6, f); nvUV.x = c.x; p1_main(d5); float4 a = __nv_out; nvUV.x = c.y; p1_main(d5); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 10) { if (7 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(7, f); nvUV.x = c.x; p1_main(d6); float4 a = __nv_out; nvUV.x = c.y; p1_main(d6); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 11) { if (8 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(8, f); nvUV.x = c.x; p1_main(d7); float4 a = __nv_out; nvUV.x = c.y; p1_main(d7); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 12) { if (9 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(9, f); nvUV.x = c.x; p1_main(d8); float4 a = __nv_out; nvUV.x = c.y; p1_main(d8); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 13) { if (8 > nvL() - 1) { __nv_out = float4(0.0); return __nv_out; } if (8 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(8, f); nvUV.x = c.x; p2_main(d9, d8); float4 a = __nv_out; nvUV.x = c.y; p2_main(d9, d8); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 14) { if (7 > nvL() - 1) { __nv_out = float4(0.0); return __nv_out; } if (7 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(7, f); nvUV.x = c.x; if (7 == nvL() - 1) p2_main(d8, d7); else p2_main(ua, d7); float4 a = __nv_out; nvUV.x = c.y; if (7 == nvL() - 1) p2_main(d8, d7); else p2_main(ua, d7); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 15) { if (6 > nvL() - 1) { __nv_out = float4(0.0); return __nv_out; } if (6 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(6, f); nvUV.x = c.x; if (6 == nvL() - 1) p2_main(d7, d6); else p2_main(ub, d6); float4 a = __nv_out; nvUV.x = c.y; if (6 == nvL() - 1) p2_main(d7, d6); else p2_main(ub, d6); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 16) { if (5 > nvL() - 1) { __nv_out = float4(0.0); return __nv_out; } if (5 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(5, f); nvUV.x = c.x; if (5 == nvL() - 1) p2_main(d6, d5); else p2_main(ua, d5); float4 a = __nv_out; nvUV.x = c.y; if (5 == nvL() - 1) p2_main(d6, d5); else p2_main(ua, d5); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 17) { if (4 > nvL() - 1) { __nv_out = float4(0.0); return __nv_out; } if (4 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(4, f); nvUV.x = c.x; if (4 == nvL() - 1) p2_main(d5, d4); else p2_main(ub, d4); float4 a = __nv_out; nvUV.x = c.y; if (4 == nvL() - 1) p2_main(d5, d4); else p2_main(ub, d4); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 18) { if (3 > nvL() - 1) { __nv_out = float4(0.0); return __nv_out; } if (3 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(3, f); nvUV.x = c.x; if (3 == nvL() - 1) p2_main(d4, d3); else p2_main(ua, d3); float4 a = __nv_out; nvUV.x = c.y; if (3 == nvL() - 1) p2_main(d4, d3); else p2_main(ua, d3); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 19) { if (2 > nvL() - 1) { __nv_out = float4(0.0); return __nv_out; } if (2 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(2, f); nvUV.x = c.x; if (2 == nvL() - 1) p2_main(d3, d2); else p2_main(ub, d2); float4 a = __nv_out; nvUV.x = c.y; if (2 == nvL() - 1) p2_main(d3, d2); else p2_main(ub, d2); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 20) { if (1 > nvL() - 1) { __nv_out = float4(0.0); return __nv_out; } if (1 > nvL()) { __nv_out = float4(0.0); return __nv_out; } float f; float2 c = nvCentros(1, f); nvUV.x = c.x; if (1 == nvL() - 1) p2_main(d2, d1); else p2_main(ua, d1); float4 a = __nv_out; nvUV.x = c.y; if (1 == nvL() - 1) p2_main(d2, d1); else p2_main(ua, d1); __nv_out = mix(a, __nv_out, f); return __nv_out; }
    if (eng.acPass == 21) { if (nvL() < 2) p3_main(d1); else p3_main(u1); __nv_out = nvSaida(__nv_out); return __nv_out; }
    __nv_out = float4(0.0);
    return __nv_out;
}
