// ---------------------------------------------------------------------------
// Effect Star Glow (NV)
// origem : assets/effects/nv-nodevideo-effect-star-glow.xml
// id     : nv.effect.nodevideo-effect-star-glow
// passes : 39
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_star_glowParams {
    float _threshold;
    float _intensity;
    float _quality;
    float _blur;
    float _length;
    float _angle;
    float _streaks;
    int _blend_mode;
    float4 _composite_color;
};

// --- funcoes auxiliares do efeito
// ---- a ponte Nova <-> Node (tools/nodeluzes/gerar.py)
float2 nvUV;   // o in.vs_TEXCOORD0 dos programas do Node: o in.acScreenNorm, ou outro ponto que o passe escolhe
static float3 nvLinear(float3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(0.04045, c)); }
static float3 nvGama(float3 c) { return mix(c * 12.92, 1.055 * pow(c, float3(1.0 / 2.4)) - 0.055, step(0.0031308, c)); }
// O passe 0: a camada como o Node a guarda (pre-multiplicada, luz linear; o buffer `pre` e sRGB de 8 bits).
static float4 nvCor(float4 c) { return float4(nvLinear(c.rgb), c.a); }
static float4 nvEntrada() { float4 c = inputImg.sample(__nv_smp, in.acScreenNorm); return float4(nvLinear(c.rgb) * c.a, c.a); }
// A saída do Node (pre-multiplicada, linear, presa a 0..1 como o RT de 8 bits) para a cor reta do Nova. A luz que
// o Node soma acima do alfa (o brilho fora do recorte) vira alfa: a = max(alfa, r, g, b). NaN (0 x infinito na
// conta do Node) vira 0, como no RT de 8 bits dele; a escolha pelo bvec não faz conta com o NaN.
static float4 nvSaida(float4 p) {
    p = mix(float4(0.0), min(p, float4(1.0)), greaterThanEqual(p, float4(0.0)));
    float a = max(p.a, max(p.r, max(p.g, p.b)));
    return a > 0.0 ? float4(nvGama(p.rgb / a), a) : float4(0.0);
}
// A máscara interna do Node (o editor de máscara dele) fica desligada, como no padrão.
#define _use_inner_mask 0
#define _b_clip_mask 0
#define _show_inner_mask 0
// O AEStarGlow (XJINE StarGlow): RTs de (W / u._blur) x (H / u._blur), W x H a composição. Aqui os buffers ficam na
// metade (o u._blur mínimo, 2) e cada texel guarda o valor da célula da grade do Node em que cai (`nvCentro`); a leitura
// do Node (linear entre os centros das células) é refeita por `nvLe` quando a grade não é a do buffer.
float vs_TEXCOORD1;   // 4^(iteração - 1): o passo e o expoente do peso
float2 vs_TEXCOORD2;    // o passo em UV: 4^(it-1) x _offset / _resolution
#define _attenuation max(min(sqrt(u._length), 0.99), 1e-6)
static int nvN() { return clamp(int(u._streaks), 1, 6); }
static float2 nvGrade() { return max(floor(float2(int2(int(pre.get_width()), int(pre.get_height()))) / max(trunc(u._blur), 2.0)), float2(1.0)); }
static float2 nvCentro(float2 uv) { float2 g = nvGrade(); return (floor(uv * g) + 0.5) / g; }
static float4 nvLe(sampler2D t, float2 uv) {
    float2 g = nvGrade();
    int2 tam = int2(int(t.get_width()), int(t.get_height()));
    if (all(equal(g, float2(tam)))) return t.sample(__nv_smp, uv);
    float2 p = uv * g - 0.5, k = floor(p), f = p - k;
    float2 c0 = clamp((k + 0.5) / g, 0.5 / g, 1.0 - 0.5 / g), c1 = clamp((k + 1.5) / g, 0.5 / g, 1.0 - 0.5 / g);
    float2 tb = float2(tam);
    int2 m = tam - 1;
    float4 a = t.read(uint2(clamp(int2(c0 * tb), int2(0), m)), uint(0));
    float4 b = t.read(uint2(clamp(int2(float2(c1.x, c0.y) * tb), int2(0), m)), uint(0));
    float4 c = t.read(uint2(clamp(int2(float2(c0.x, c1.y) * tb), int2(0), m)), uint(0));
    float4 d = t.read(uint2(clamp(int2(c1 * tb), int2(0), m)), uint(0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}
// O raio k (1..N) do C#: ângulo = trunc(u._angle) + 360/N x k; _offset = AngleAxis(ângulo, frente) x Vector2.down.
static void nvRaio(int k, int it) {
    float a = radians(trunc(u._angle) + 360.0 / float(nvN()) * float(k));
    vs_TEXCOORD1 = exp2(2.0 * float(it - 1));
    vs_TEXCOORD2 = vs_TEXCOORD1 * float2(sin(a), -cos(a)) / eng.acTamanhoDaTela;
}

// ---- programa 0 do Node: NodeVideo_Effect_star_glow_1.glsl
float4 p0_x0;
float2 p0_x1;
static void p0_main()
{
    p0_x0 = pre.sample(__nv_smp, nvUV.xy);
    p0_x1.xy = float2(u._threshold, u._intensity) * float2(u._threshold, u._intensity);
    p0_x0 = (-p0_x1.xxxx) * p0_x1.xxxx + p0_x0;
    p0_x0 = max(p0_x0, float4(0.0, 0.0, 0.0, 0.0));
    p0_x0 = p0_x0 * p0_x1.yyyy;
    __nv_out = p0_x0 * float4(float4(u._intensity, u._intensity, u._intensity, u._intensity));
    return;
}

// ---- programa 1 do Node: NodeVideo_Effect_star_glow_2.glsl
float p1_x0;
float2 p1_x1;
float3 p1_x2;
float3 p1_x3;
int p1_xi7;
float p1_x10;
bool p1_xb10;
static void p1_main(sampler2D _blur_tex)
{
    p1_x0 = log2(abs(_attenuation));
    p1_x3.x = float(0.0);
    p1_x3.y = float(0.0);
    p1_x3.z = float(0.0);
    p1_x1.xy = nvUV.xy;
    for(int p1_xi_loop_1 = 0 ; p1_xi_loop_1<int(u._quality) ; p1_xi_loop_1++)
    {
        p1_x2.xyz = nvLe(_blur_tex, p1_x1.xy).xyz;
        p1_x10 = float(p1_xi_loop_1);
        p1_x10 = p1_x10 * vs_TEXCOORD1;
        p1_x10 = p1_x0 * p1_x10;
        p1_x10 = exp2(p1_x10);
        p1_x2.xyz = float3(p1_x10) * p1_x2.xyz;
        p1_x2.xyz = clamp(p1_x2.xyz, 0.0, 1.0);
        p1_x3.xyz = p1_x3.xyz + p1_x2.xyz;
        p1_x1.xy = p1_x1.xy + vs_TEXCOORD2.xy;
    }
    __nv_out.xyz = p1_x3.xyz;
    __nv_out.w = 1.0;
    return;
}

// ---- programa 2 do Node: NodeVideo_Effect_star_glow_3.glsl
static void p2_main(sampler2D _blur_tex)
{
    __nv_out = nvLe(_blur_tex, nvUV.xy);
    return;
}

// ---- programa 3 do Node: NodeVideo_Effect_star_glow_4.glsl
float4 p3_x0;
float4 p3_x1;
float p3_x2;
bool3 p3_xb2;
float4 p3_x3;
float4 p3_x4;
float4 p3_x5;
float p3_x14;
static void p3_main(sampler2D _composite_tex)
{
    p3_x0 = pre.sample(__nv_smp, nvUV.xy);
    p3_x1 = nvLe(_composite_tex, nvUV.xy);
    p3_xb2.xyz = equal(int4(int4(int(u._blend_mode), int(u._blend_mode), int(u._blend_mode), int(u._blend_mode))), int4(1, 3, 0, 0)).xyz;
    {
        bool3 hlslcc_orTemp = p3_xb2;
        hlslcc_orTemp.x = p3_xb2.y || p3_xb2.x;
        hlslcc_orTemp.y = p3_xb2.x || p3_xb2.z;
        p3_xb2 = hlslcc_orTemp;
    }
    p3_x14 = p3_x1.y + p3_x1.x;
    p3_x14 = p3_x1.z + p3_x14;
    p3_x14 = p3_x14 * 0.333299994;
    p3_x3.xyz = float3(p3_x14) * nvCor(u._composite_color).xyz;
    p3_x1.xyz = (p3_xb2.x) ? p3_x3.xyz : p3_x1.xyz;
    p3_x3 = p3_x0 + p3_x1;
    p3_x4 = p3_x3;
    p3_x4 = clamp(p3_x4, 0.0, 1.0);
    p3_x1 = p3_x0 * p3_x1;
    p3_x1 = clamp(p3_x1, 0.0, 1.0);
    p3_x1 = (-p3_x1) + p3_x3;
    p3_x1 = clamp(p3_x1, 0.0, 1.0);
    p3_x1 = (p3_xb2.y) ? p3_x4 : p3_x1;
    if(int(_use_inner_mask) != 0) {
        p3_xb2.xy = equal(int4(int(_show_inner_mask), int(_b_clip_mask), int(_show_inner_mask), int(_show_inner_mask)), int4(1, 1, 0, 0)).xy;
        p3_x3 = (p3_xb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : p3_x1;
        p3_x4 = pre.sample(__nv_smp, nvUV.xy);
        p3_x5 = (-p3_x4) + float4(1.0, 1.0, 1.0, 1.0);
        p3_x0 = p3_x0 * p3_x5;
        p3_x0 = p3_x3 * p3_x4 + p3_x0;
        p3_x2 = p3_x4.x * p3_x0.w;
        __nv_out.w = (p3_xb2.y) ? p3_x2 : p3_x0.w;
        __nv_out.xyz = p3_x0.xyz;
    } else {
        __nv_out = p3_x1;
    }
    return;
}

fragment float4 fx_nv_nodevideo_effect_star_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_star_glowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pre [[texture(1)]],
    texture2d<float> bright [[texture(2)]],
    texture2d<float> bA [[texture(3)]],
    texture2d<float> bB [[texture(4)]],
    texture2d<float> cA [[texture(5)]],
    texture2d<float> cB [[texture(6)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    nvUV = in.acScreenNorm;
    if (eng.acPass == 0) { __nv_out = nvEntrada(); return __nv_out; }
    if (eng.acPass == 1) { nvUV = nvCentro(in.acScreenNorm); p0_main(); return __nv_out; }
    if (eng.acPass == 2) { if (1 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(1, 1); nvUV = nvCentro(in.acScreenNorm); p1_main(bright); return __nv_out; }
    if (eng.acPass == 3) { if (1 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(1, 2); nvUV = nvCentro(in.acScreenNorm); p1_main(bA); return __nv_out; }
    if (eng.acPass == 4) { if (1 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(1, 3); nvUV = nvCentro(in.acScreenNorm); p1_main(bB); return __nv_out; }
    if (eng.acPass == 5) { if (1 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(1, 4); nvUV = nvCentro(in.acScreenNorm); p1_main(bA); return __nv_out; }
    if (eng.acPass == 6) { if (1 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(1, 5); nvUV = nvCentro(in.acScreenNorm); p1_main(bB); return __nv_out; }
    if (eng.acPass == 7) { nvUV = nvCentro(in.acScreenNorm); p2_main(bA); return __nv_out; }
    if (eng.acPass == 8) { if (2 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(2, 1); nvUV = nvCentro(in.acScreenNorm); p1_main(bright); return __nv_out; }
    if (eng.acPass == 9) { if (2 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(2, 2); nvUV = nvCentro(in.acScreenNorm); p1_main(bA); return __nv_out; }
    if (eng.acPass == 10) { if (2 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(2, 3); nvUV = nvCentro(in.acScreenNorm); p1_main(bB); return __nv_out; }
    if (eng.acPass == 11) { if (2 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(2, 4); nvUV = nvCentro(in.acScreenNorm); p1_main(bA); return __nv_out; }
    if (eng.acPass == 12) { if (2 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(2, 5); nvUV = nvCentro(in.acScreenNorm); p1_main(bB); return __nv_out; }
    if (eng.acPass == 13) { if (2 > nvN()) { __nv_out = cA.sample(__nv_smp, in.acScreenNorm); return __nv_out; } nvUV = nvCentro(in.acScreenNorm); p2_main(bA); float4 c = cA.sample(__nv_smp, in.acScreenNorm); __nv_out = __nv_out + c - __nv_out * c; return __nv_out; }
    if (eng.acPass == 14) { if (3 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(3, 1); nvUV = nvCentro(in.acScreenNorm); p1_main(bright); return __nv_out; }
    if (eng.acPass == 15) { if (3 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(3, 2); nvUV = nvCentro(in.acScreenNorm); p1_main(bA); return __nv_out; }
    if (eng.acPass == 16) { if (3 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(3, 3); nvUV = nvCentro(in.acScreenNorm); p1_main(bB); return __nv_out; }
    if (eng.acPass == 17) { if (3 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(3, 4); nvUV = nvCentro(in.acScreenNorm); p1_main(bA); return __nv_out; }
    if (eng.acPass == 18) { if (3 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(3, 5); nvUV = nvCentro(in.acScreenNorm); p1_main(bB); return __nv_out; }
    if (eng.acPass == 19) { if (3 > nvN()) { __nv_out = cB.sample(__nv_smp, in.acScreenNorm); return __nv_out; } nvUV = nvCentro(in.acScreenNorm); p2_main(bA); float4 c = cB.sample(__nv_smp, in.acScreenNorm); __nv_out = __nv_out + c - __nv_out * c; return __nv_out; }
    if (eng.acPass == 20) { if (4 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(4, 1); nvUV = nvCentro(in.acScreenNorm); p1_main(bright); return __nv_out; }
    if (eng.acPass == 21) { if (4 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(4, 2); nvUV = nvCentro(in.acScreenNorm); p1_main(bA); return __nv_out; }
    if (eng.acPass == 22) { if (4 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(4, 3); nvUV = nvCentro(in.acScreenNorm); p1_main(bB); return __nv_out; }
    if (eng.acPass == 23) { if (4 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(4, 4); nvUV = nvCentro(in.acScreenNorm); p1_main(bA); return __nv_out; }
    if (eng.acPass == 24) { if (4 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(4, 5); nvUV = nvCentro(in.acScreenNorm); p1_main(bB); return __nv_out; }
    if (eng.acPass == 25) { if (4 > nvN()) { __nv_out = cA.sample(__nv_smp, in.acScreenNorm); return __nv_out; } nvUV = nvCentro(in.acScreenNorm); p2_main(bA); float4 c = cA.sample(__nv_smp, in.acScreenNorm); __nv_out = __nv_out + c - __nv_out * c; return __nv_out; }
    if (eng.acPass == 26) { if (5 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(5, 1); nvUV = nvCentro(in.acScreenNorm); p1_main(bright); return __nv_out; }
    if (eng.acPass == 27) { if (5 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(5, 2); nvUV = nvCentro(in.acScreenNorm); p1_main(bA); return __nv_out; }
    if (eng.acPass == 28) { if (5 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(5, 3); nvUV = nvCentro(in.acScreenNorm); p1_main(bB); return __nv_out; }
    if (eng.acPass == 29) { if (5 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(5, 4); nvUV = nvCentro(in.acScreenNorm); p1_main(bA); return __nv_out; }
    if (eng.acPass == 30) { if (5 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(5, 5); nvUV = nvCentro(in.acScreenNorm); p1_main(bB); return __nv_out; }
    if (eng.acPass == 31) { if (5 > nvN()) { __nv_out = cB.sample(__nv_smp, in.acScreenNorm); return __nv_out; } nvUV = nvCentro(in.acScreenNorm); p2_main(bA); float4 c = cB.sample(__nv_smp, in.acScreenNorm); __nv_out = __nv_out + c - __nv_out * c; return __nv_out; }
    if (eng.acPass == 32) { if (6 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(6, 1); nvUV = nvCentro(in.acScreenNorm); p1_main(bright); return __nv_out; }
    if (eng.acPass == 33) { if (6 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(6, 2); nvUV = nvCentro(in.acScreenNorm); p1_main(bA); return __nv_out; }
    if (eng.acPass == 34) { if (6 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(6, 3); nvUV = nvCentro(in.acScreenNorm); p1_main(bB); return __nv_out; }
    if (eng.acPass == 35) { if (6 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(6, 4); nvUV = nvCentro(in.acScreenNorm); p1_main(bA); return __nv_out; }
    if (eng.acPass == 36) { if (6 > nvN()) { __nv_out = float4(0.0); return __nv_out; } nvRaio(6, 5); nvUV = nvCentro(in.acScreenNorm); p1_main(bB); return __nv_out; }
    if (eng.acPass == 37) { if (6 > nvN()) { __nv_out = cA.sample(__nv_smp, in.acScreenNorm); return __nv_out; } nvUV = nvCentro(in.acScreenNorm); p2_main(bA); float4 c = cA.sample(__nv_smp, in.acScreenNorm); __nv_out = __nv_out + c - __nv_out * c; return __nv_out; }
    if (eng.acPass == 38) { p3_main(cB); __nv_out = nvSaida(float4(__nv_out.rgb * __nv_out.a, __nv_out.a * __nv_out.a)); return __nv_out; }
    __nv_out = float4(0.0);
    return __nv_out;
}
