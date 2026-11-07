// ---------------------------------------------------------------------------
// Effect Stylize Glow (NV)
// origem : assets/effects/nv-nodevideo-effect-stylize-glow.xml
// id     : nv.effect.nodevideo-effect-stylize-glow
// passes : 17
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_stylize_glowParams {
    float _BloomScattering;
    float _BloomThreshold_x;
    float _BloomThreshold_y;
    float _BloomIntensity;
    float4 _glow_color;
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
// O C# (UpdateRenderBuffers + PrepareScattering): RTs a partir da METADE da composição; com t = max(w/2, h/2),
// logh = Espalhamento (preso a 1..10) + log2(t) - 10, N = floor(logh) (no mínimo 1) descidas, e _BloomSpread =
// logh + 0,5 - N (0,5 com logh <= 1). Aqui pelo tamanho do buffer em que o efeito roda (a mesma conta na exportação;
// na prévia reduzida o brilho fica do mesmo tamanho na tela) e N preso a 7 (o motor desce até 1/256).
float nvLogh() { float2 t = floor(float2(int2(int(pre.get_width()), int(pre.get_height()))) / 2.0); return clamp(u._BloomScattering, 1.0, 10.0) + log2(max(t.x, t.y)) - 10.0; }
int nvN() { return clamp(int(floor(nvLogh())), 1, 7); }
float nvSpread() { float l = nvLogh(); return l > 1.0 ? l + 0.5 - floor(l) : 0.5; }
#define _BloomSpread nvSpread()
// O _BloomThreshold do Node é um Vector2 de faixa (o mínimo e o máximo do brilho que entra).
#define _BloomThreshold float2(u._BloomThreshold_x, u._BloomThreshold_y)

// ---- programa 0 do Node: NodeVideo_Effect_Stylize_Glow_0.glsl
float4 p0_x0;
float4 p0_x1;
float4 p0_x2;
float4 p0_x3;
float4 p0_x4;
float4 p0_x5;
float4 p0_x6;
float4 p0_x7;
float4 p0_x8;
float4 p0_x9;
float4 p0_x10;
float4 p0_x11;
float4 p0_x12;
float p0_x15;
float p0_x40;
void p0_main()
{
    p0_x0.xy = (-(1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())))).xy) * float2(0.0, 0.899999976) + nvUV.xy;
    p0_x0 = pre.sample(__nv_smp, p0_x0.xy);
    p0_x1 = (1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())))).xyxy * float4(-0.899999976, -0.899999976, 0.899999976, -0.899999976) + nvUV.xyxy;
    p0_x2 = pre.sample(__nv_smp, p0_x1.xy);
    p0_x1 = pre.sample(__nv_smp, p0_x1.zw);
    p0_x3.xy = (-(1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())))).xy) * float2(0.899999976, 0.0) + nvUV.xy;
    p0_x3 = pre.sample(__nv_smp, p0_x3.xy);
    p0_x4 = pre.sample(__nv_smp, nvUV.xy);
    p0_x5 = p0_x3 + p0_x4;
    p0_x2 = p0_x2 + p0_x5;
    p0_x2 = p0_x0 + p0_x2;
    p0_x5 = (1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())))).xyxy * float4(0.899999976, 0.899999976, -1.45000005, 0.449999988) + nvUV.xyxy;
    p0_x6 = pre.sample(__nv_smp, p0_x5.xy);
    p0_x5 = pre.sample(__nv_smp, p0_x5.zw);
    p0_x7 = (1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())))).xyxy * float4(-0.899999976, 0.899999976, 0.0, 0.899999976) + nvUV.xyxy;
    p0_x8 = pre.sample(__nv_smp, p0_x7.zw);
    p0_x7 = pre.sample(__nv_smp, p0_x7.xy);
    p0_x7 = p0_x8 + p0_x7;
    p0_x6 = p0_x6 + p0_x8;
    p0_x6 = p0_x4 + p0_x6;
    p0_x3 = p0_x3 + p0_x7;
    p0_x3 = p0_x4 + p0_x3;
    p0_x3 = p0_x3 * float4(0.0208333004, 0.0208333004, 0.0208333004, 0.0208333004);
    p0_x7 = (1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())))).xyxy * float4(1.45000005, 0.449999988, 0.899999976, 0.0) + nvUV.xyxy;
    p0_x8 = pre.sample(__nv_smp, p0_x7.zw);
    p0_x7 = pre.sample(__nv_smp, p0_x7.xy);
    p0_x6 = p0_x6 + p0_x8;
    p0_x4 = p0_x4 + p0_x8;
    p0_x0 = p0_x0 + p0_x4;
    p0_x0 = p0_x1 + p0_x0;
    p0_x1 = (1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())))).xyxy * float4(-0.449999988, 0.449999988, 0.449999988, 0.449999988) + nvUV.xyxy;
    p0_x4 = pre.sample(__nv_smp, p0_x1.xy);
    p0_x1 = pre.sample(__nv_smp, p0_x1.zw);
    p0_x8 = p0_x1 + p0_x4;
    p0_x9 = (1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())))).xyxy * float4(-1.45000005, -0.449999988, -0.449999988, -0.449999988) + nvUV.xyxy;
    p0_x10 = pre.sample(__nv_smp, p0_x9.zw);
    p0_x9 = pre.sample(__nv_smp, p0_x9.xy);
    p0_x8 = p0_x8 + p0_x10;
    p0_x11 = (1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())))).xyxy * float4(0.449999988, -0.449999988, 1.45000005, -0.449999988) + nvUV.xyxy;
    p0_x12 = pre.sample(__nv_smp, p0_x11.xy);
    p0_x11 = pre.sample(__nv_smp, p0_x11.zw);
    p0_x8 = p0_x8 + p0_x12;
    p0_x3 = p0_x8 * float4(0.0833332986, 0.0833332986, 0.0833332986, 0.0833332986) + p0_x3;
    p0_x3 = p0_x6 * float4(0.0208333004, 0.0208333004, 0.0208333004, 0.0208333004) + p0_x3;
    p0_x2 = p0_x2 * float4(0.0208333004, 0.0208333004, 0.0208333004, 0.0208333004) + p0_x3;
    p0_x0 = p0_x0 * float4(0.0208333004, 0.0208333004, 0.0208333004, 0.0208333004) + p0_x2;
    p0_x2 = (1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())))).xyxy * float4(-1.45000005, 1.45000005, -0.449999988, 1.45000005) + nvUV.xyxy;
    p0_x3 = pre.sample(__nv_smp, p0_x2.xy);
    p0_x2 = pre.sample(__nv_smp, p0_x2.zw);
    p0_x3 = p0_x2 + p0_x3;
    p0_x3 = p0_x5 + p0_x3;
    p0_x5 = p0_x4 + p0_x5;
    p0_x5 = p0_x9 + p0_x5;
    p0_x6 = p0_x10 + p0_x9;
    p0_x5 = p0_x10 + p0_x5;
    p0_x9 = p0_x10 + p0_x12;
    p0_x3 = p0_x4 + p0_x3;
    p0_x0 = p0_x3 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p0_x0;
    p0_x3 = (1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())))).xyxy * float4(0.449999988, 1.45000005, 1.45000005, 1.45000005) + nvUV.xyxy;
    p0_x10 = pre.sample(__nv_smp, p0_x3.xy);
    p0_x3 = pre.sample(__nv_smp, p0_x3.zw);
    p0_x3 = p0_x3 + p0_x10;
    p0_x2 = p0_x2 + p0_x10;
    p0_x2 = p0_x4 + p0_x2;
    p0_x2 = p0_x1 + p0_x2;
    p0_x0 = p0_x2 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p0_x0;
    p0_x2 = p0_x1 + p0_x3;
    p0_x1 = p0_x7 + p0_x1;
    p0_x2 = p0_x7 + p0_x2;
    p0_x0 = p0_x2 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p0_x0;
    p0_x0 = p0_x5 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p0_x0;
    p0_x0 = p0_x8 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p0_x0;
    p0_x1 = p0_x12 + p0_x1;
    p0_x2 = p0_x11 + p0_x12;
    p0_x1 = p0_x11 + p0_x1;
    p0_x0 = p0_x1 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p0_x0;
    p0_x1 = (1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())))).xyxy * float4(-1.45000005, -1.45000005, -0.449999988, -1.45000005) + nvUV.xyxy;
    p0_x3 = pre.sample(__nv_smp, p0_x1.xy);
    p0_x1 = pre.sample(__nv_smp, p0_x1.zw);
    p0_x3 = p0_x3 + p0_x6;
    p0_x3 = p0_x1 + p0_x3;
    p0_x1 = p0_x1 + p0_x9;
    p0_x0 = p0_x3 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p0_x0;
    p0_x3 = (1.0 / float2(int2(int(pre.get_width()), int(pre.get_height())))).xyxy * float4(0.449999988, -1.45000005, 1.45000005, -1.45000005) + nvUV.xyxy;
    p0_x4 = pre.sample(__nv_smp, p0_x3.xy);
    p0_x3 = pre.sample(__nv_smp, p0_x3.zw);
    p0_x1 = p0_x1 + p0_x4;
    p0_x2 = p0_x2 + p0_x4;
    p0_x2 = p0_x3 + p0_x2;
    p0_x0 = p0_x1 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p0_x0;
    p0_x0 = p0_x2 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p0_x0;
    p0_x1.x = dot(p0_x0.xyz, p0_x0.xyz);
    p0_x1.x = rsqrt(p0_x1.x);
    p0_x1.xyz = p0_x0.xyz * p0_x1.xxx;
    p0_x1.xyz = p0_x1.xyz * _BloomThreshold.yyy;
    p0_x2.xyz = max(p0_x0.xyz, float3(0.0, 0.0, 0.0));
    p0_x1.xyz = min(p0_x1.xyz, p0_x2.xyz);
    p0_x1.xyz = p0_x1.xyz * float3(0.908999979, 0.908999979, 0.908999979);
    p0_x40 = max(p0_x1.z, p0_x1.y);
    p0_x40 = max(p0_x40, p0_x1.x);
    p0_x2.x = p0_x40 + (-_BloomThreshold.x);
    p0_x40 = max(p0_x40, 9.99999975e-05);
    p0_x15 = p0_x2.x + 9.99999975e-05;
    p0_x15 = max(p0_x15, 0.0);
    p0_x15 = min(p0_x15, 0.000199999995);
    p0_x15 = p0_x15 * p0_x15;
    p0_x15 = p0_x15 * 2000.00012;
    p0_x2.x = max(p0_x2.x, p0_x15);
    p0_x1.xyz = p0_x1.xyz * p0_x2.xxx;
    p0_x1.xyz = p0_x1.xyz / float3(p0_x40);
    p0_x0.xyz = max(p0_x1.xyz, float3(0.0, 0.0, 0.0));
    __nv_out = p0_x0 * nvCor(u._glow_color);
    return;
}

// ---- programa 1 do Node: NodeVideo_Effect_Stylize_Glow_1.glsl
float4 p1_x0;
float4 p1_x1;
float4 p1_x2;
float4 p1_x3;
float4 p1_x4;
float4 p1_x5;
float4 p1_x6;
float4 p1_x7;
float4 p1_x8;
float4 p1_x9;
float4 p1_x10;
float4 p1_x11;
float4 p1_x12;
void p1_main(sampler2D _BloomTex)
{
    p1_x0.xy = (-(1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xy) * float2(0.0, 0.899999976) + nvUV.xy;
    p1_x0 = _BloomTex.sample(__nv_smp, p1_x0.xy);
    p1_x1 = (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xyxy * float4(-0.899999976, -0.899999976, 0.899999976, -0.899999976) + nvUV.xyxy;
    p1_x2 = _BloomTex.sample(__nv_smp, p1_x1.xy);
    p1_x1 = _BloomTex.sample(__nv_smp, p1_x1.zw);
    p1_x3.xy = (-(1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xy) * float2(0.899999976, 0.0) + nvUV.xy;
    p1_x3 = _BloomTex.sample(__nv_smp, p1_x3.xy);
    p1_x4 = _BloomTex.sample(__nv_smp, nvUV.xy);
    p1_x5 = p1_x3 + p1_x4;
    p1_x2 = p1_x2 + p1_x5;
    p1_x2 = p1_x0 + p1_x2;
    p1_x5 = (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xyxy * float4(0.899999976, 0.899999976, -1.45000005, 0.449999988) + nvUV.xyxy;
    p1_x6 = _BloomTex.sample(__nv_smp, p1_x5.xy);
    p1_x5 = _BloomTex.sample(__nv_smp, p1_x5.zw);
    p1_x7 = (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xyxy * float4(-0.899999976, 0.899999976, 0.0, 0.899999976) + nvUV.xyxy;
    p1_x8 = _BloomTex.sample(__nv_smp, p1_x7.zw);
    p1_x7 = _BloomTex.sample(__nv_smp, p1_x7.xy);
    p1_x7 = p1_x8 + p1_x7;
    p1_x6 = p1_x6 + p1_x8;
    p1_x6 = p1_x4 + p1_x6;
    p1_x3 = p1_x3 + p1_x7;
    p1_x3 = p1_x4 + p1_x3;
    p1_x3 = p1_x3 * float4(0.0208333004, 0.0208333004, 0.0208333004, 0.0208333004);
    p1_x7 = (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xyxy * float4(1.45000005, 0.449999988, 0.899999976, 0.0) + nvUV.xyxy;
    p1_x8 = _BloomTex.sample(__nv_smp, p1_x7.zw);
    p1_x7 = _BloomTex.sample(__nv_smp, p1_x7.xy);
    p1_x6 = p1_x6 + p1_x8;
    p1_x4 = p1_x4 + p1_x8;
    p1_x0 = p1_x0 + p1_x4;
    p1_x0 = p1_x1 + p1_x0;
    p1_x1 = (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xyxy * float4(-0.449999988, 0.449999988, 0.449999988, 0.449999988) + nvUV.xyxy;
    p1_x4 = _BloomTex.sample(__nv_smp, p1_x1.xy);
    p1_x1 = _BloomTex.sample(__nv_smp, p1_x1.zw);
    p1_x8 = p1_x1 + p1_x4;
    p1_x9 = (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xyxy * float4(-1.45000005, -0.449999988, -0.449999988, -0.449999988) + nvUV.xyxy;
    p1_x10 = _BloomTex.sample(__nv_smp, p1_x9.zw);
    p1_x9 = _BloomTex.sample(__nv_smp, p1_x9.xy);
    p1_x8 = p1_x8 + p1_x10;
    p1_x11 = (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xyxy * float4(0.449999988, -0.449999988, 1.45000005, -0.449999988) + nvUV.xyxy;
    p1_x12 = _BloomTex.sample(__nv_smp, p1_x11.xy);
    p1_x11 = _BloomTex.sample(__nv_smp, p1_x11.zw);
    p1_x8 = p1_x8 + p1_x12;
    p1_x3 = p1_x8 * float4(0.0833332986, 0.0833332986, 0.0833332986, 0.0833332986) + p1_x3;
    p1_x3 = p1_x6 * float4(0.0208333004, 0.0208333004, 0.0208333004, 0.0208333004) + p1_x3;
    p1_x2 = p1_x2 * float4(0.0208333004, 0.0208333004, 0.0208333004, 0.0208333004) + p1_x3;
    p1_x0 = p1_x0 * float4(0.0208333004, 0.0208333004, 0.0208333004, 0.0208333004) + p1_x2;
    p1_x2 = (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xyxy * float4(-1.45000005, 1.45000005, -0.449999988, 1.45000005) + nvUV.xyxy;
    p1_x3 = _BloomTex.sample(__nv_smp, p1_x2.xy);
    p1_x2 = _BloomTex.sample(__nv_smp, p1_x2.zw);
    p1_x3 = p1_x2 + p1_x3;
    p1_x3 = p1_x5 + p1_x3;
    p1_x5 = p1_x4 + p1_x5;
    p1_x5 = p1_x9 + p1_x5;
    p1_x6 = p1_x10 + p1_x9;
    p1_x5 = p1_x10 + p1_x5;
    p1_x9 = p1_x10 + p1_x12;
    p1_x3 = p1_x4 + p1_x3;
    p1_x0 = p1_x3 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p1_x0;
    p1_x3 = (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xyxy * float4(0.449999988, 1.45000005, 1.45000005, 1.45000005) + nvUV.xyxy;
    p1_x10 = _BloomTex.sample(__nv_smp, p1_x3.xy);
    p1_x3 = _BloomTex.sample(__nv_smp, p1_x3.zw);
    p1_x3 = p1_x3 + p1_x10;
    p1_x2 = p1_x2 + p1_x10;
    p1_x2 = p1_x4 + p1_x2;
    p1_x2 = p1_x1 + p1_x2;
    p1_x0 = p1_x2 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p1_x0;
    p1_x2 = p1_x1 + p1_x3;
    p1_x1 = p1_x7 + p1_x1;
    p1_x2 = p1_x7 + p1_x2;
    p1_x0 = p1_x2 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p1_x0;
    p1_x0 = p1_x5 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p1_x0;
    p1_x0 = p1_x8 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p1_x0;
    p1_x1 = p1_x12 + p1_x1;
    p1_x2 = p1_x11 + p1_x12;
    p1_x1 = p1_x11 + p1_x1;
    p1_x0 = p1_x1 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p1_x0;
    p1_x1 = (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xyxy * float4(-1.45000005, -1.45000005, -0.449999988, -1.45000005) + nvUV.xyxy;
    p1_x3 = _BloomTex.sample(__nv_smp, p1_x1.xy);
    p1_x1 = _BloomTex.sample(__nv_smp, p1_x1.zw);
    p1_x3 = p1_x3 + p1_x6;
    p1_x3 = p1_x1 + p1_x3;
    p1_x1 = p1_x1 + p1_x9;
    p1_x0 = p1_x3 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p1_x0;
    p1_x3 = (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xyxy * float4(0.449999988, -1.45000005, 1.45000005, -1.45000005) + nvUV.xyxy;
    p1_x4 = _BloomTex.sample(__nv_smp, p1_x3.xy);
    p1_x3 = _BloomTex.sample(__nv_smp, p1_x3.zw);
    p1_x1 = p1_x1 + p1_x4;
    p1_x2 = p1_x2 + p1_x4;
    p1_x2 = p1_x3 + p1_x2;
    p1_x0 = p1_x1 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p1_x0;
    __nv_out = p1_x2 * float4(0.00923329964, 0.00923329964, 0.00923329964, 0.00923329964) + p1_x0;
    return;
}

// ---- programa 2 do Node: NodeVideo_Effect_Stylize_Glow_2.glsl
float4 p2_x0;
float4 p2_x1;
float4 p2_x2;
float4 p2_x3;
float4 p2_x4;
float4 p2_x5;
float2 p2_x14;
void p2_main(sampler2D _BloomTex, sampler2D _HigherMipBloomTex)
{
    p2_x0.xy = (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xy * float2(float2(_BloomSpread, _BloomSpread)) + nvUV.xy;
    p2_x0 = _BloomTex.sample(__nv_smp, p2_x0.xy);
    p2_x1.xy = (-(1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xy) * float2(float2(_BloomSpread, _BloomSpread)) + nvUV.xy;
    p2_x1 = _BloomTex.sample(__nv_smp, p2_x1.xy);
    p2_x2 = _BloomTex.sample(__nv_smp, nvUV.xy);
    p2_x3.xy = float2(float2(_BloomSpread, _BloomSpread)) * (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xy;
    p2_x4 = (-p2_x3.xyxy) * float4(0.0, 1.0, 1.0, 0.0) + nvUV.xyxy;
    p2_x5 = _BloomTex.sample(__nv_smp, p2_x4.xy);
    p2_x4 = _BloomTex.sample(__nv_smp, p2_x4.zw);
    p2_x5 = p2_x5 * float4(0.0799999982, 0.0799999982, 0.0799999982, 0.0799999982);
    p2_x2 = p2_x2 * float4(0.159999996, 0.159999996, 0.159999996, 0.159999996) + p2_x5;
    p2_x2 = p2_x4 * float4(0.0799999982, 0.0799999982, 0.0799999982, 0.0799999982) + p2_x2;
    p2_x4 = p2_x3.xyxy * float4(1.0, 0.0, 0.0, 1.0) + nvUV.xyxy;
    p2_x5 = _BloomTex.sample(__nv_smp, p2_x4.xy);
    p2_x4 = _BloomTex.sample(__nv_smp, p2_x4.zw);
    p2_x2 = p2_x5 * float4(0.0799999982, 0.0799999982, 0.0799999982, 0.0799999982) + p2_x2;
    p2_x2 = p2_x4 * float4(0.0799999982, 0.0799999982, 0.0799999982, 0.0799999982) + p2_x2;
    p2_x1 = p2_x1 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p2_x2;
    p2_x2 = p2_x3.xyxy * float4(1.0, -1.0, -1.0, 1.0) + nvUV.xyxy;
    p2_x4 = _BloomTex.sample(__nv_smp, p2_x2.xy);
    p2_x2 = _BloomTex.sample(__nv_smp, p2_x2.zw);
    p2_x1 = p2_x4 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p2_x1;
    p2_x1 = p2_x2 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p2_x1;
    p2_x0 = p2_x0 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p2_x1;
    p2_x1 = p2_x3.xyxy * float4(0.0, 2.0, 2.0, 0.0) + nvUV.xyxy;
    p2_x2 = _BloomTex.sample(__nv_smp, p2_x1.xy);
    p2_x1 = _BloomTex.sample(__nv_smp, p2_x1.zw);
    p2_x0 = p2_x2 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p2_x0;
    p2_x0 = p2_x1 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p2_x0;
    p2_x1 = p2_x3.xyxy * float4(0.0, -2.0, -2.0, 0.0) + nvUV.xyxy;
    p2_x2 = _BloomTex.sample(__nv_smp, p2_x1.xy);
    p2_x1 = _BloomTex.sample(__nv_smp, p2_x1.zw);
    p2_x0 = p2_x2 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p2_x0;
    p2_x0 = p2_x1 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p2_x0;
    p2_x1 = p2_x3.xyxy * float4(-2.0, 1.0, -1.0, 2.0) + nvUV.xyxy;
    p2_x2 = _BloomTex.sample(__nv_smp, p2_x1.xy);
    p2_x1 = _BloomTex.sample(__nv_smp, p2_x1.zw);
    p2_x0 = p2_x2 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p2_x0;
    p2_x0 = p2_x1 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p2_x0;
    p2_x1 = p2_x3.xyxy * float4(1.0, 2.0, 2.0, 1.0) + nvUV.xyxy;
    p2_x2 = _BloomTex.sample(__nv_smp, p2_x1.xy);
    p2_x1 = _BloomTex.sample(__nv_smp, p2_x1.zw);
    p2_x0 = p2_x2 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p2_x0;
    p2_x0 = p2_x1 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p2_x0;
    p2_x1 = p2_x3.xyxy * float4(2.0, -1.0, 1.0, -2.0) + nvUV.xyxy;
    p2_x2 = _BloomTex.sample(__nv_smp, p2_x1.xy);
    p2_x1 = _BloomTex.sample(__nv_smp, p2_x1.zw);
    p2_x0 = p2_x2 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p2_x0;
    p2_x0 = p2_x1 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p2_x0;
    p2_x1 = p2_x3.xyxy * float4(-1.0, -2.0, -2.0, -1.0) + nvUV.xyxy;
    p2_x2 = _BloomTex.sample(__nv_smp, p2_x1.xy);
    p2_x1 = _BloomTex.sample(__nv_smp, p2_x1.zw);
    p2_x0 = p2_x2 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p2_x0;
    p2_x0 = p2_x1 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p2_x0;
    p2_x1 = p2_x3.xyxy * float4(-2.0, 2.0, 2.0, -2.0) + nvUV.xyxy;
    p2_x2 = _BloomTex.sample(__nv_smp, p2_x1.xy);
    p2_x1 = _BloomTex.sample(__nv_smp, p2_x1.zw);
    p2_x0 = p2_x2 * float4(0.00999999978, 0.00999999978, 0.00999999978, 0.00999999978) + p2_x0;
    p2_x2.xy = p2_x3.xy * float2(2.0, 2.0) + nvUV.xy;
    p2_x14.xy = p2_x3.xy * float2(-2.0, -2.0) + nvUV.xy;
    p2_x3 = _BloomTex.sample(__nv_smp, p2_x14.xy);
    p2_x2 = _BloomTex.sample(__nv_smp, p2_x2.xy);
    p2_x0 = p2_x2 * float4(0.00999999978, 0.00999999978, 0.00999999978, 0.00999999978) + p2_x0;
    p2_x0 = p2_x1 * float4(0.00999999978, 0.00999999978, 0.00999999978, 0.00999999978) + p2_x0;
    p2_x0 = p2_x3 * float4(0.00999999978, 0.00999999978, 0.00999999978, 0.00999999978) + p2_x0;
    p2_x1 = _HigherMipBloomTex.sample(__nv_smp, nvUV.xy);
    __nv_out = p2_x0 + p2_x1;
    return;
}

// ---- programa 3 do Node: NodeVideo_Effect_Stylize_Glow_3.glsl
float4 p3_x0;
float4 p3_x1;
float4 p3_x2;
bool2 p3_xb2;
float4 p3_x3;
float4 p3_x4;
float4 p3_x5;
float2 p3_x12;
void p3_main(sampler2D _BloomTex)
{
    p3_x0.xy = float2(float2(_BloomSpread, _BloomSpread)) * (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xy;
    p3_x1 = _BloomTex.sample(__nv_smp, nvUV.xy);
    p3_x2 = (-p3_x0.xyxy) * float4(0.0, 1.0, 1.0, 0.0) + nvUV.xyxy;
    p3_x3 = _BloomTex.sample(__nv_smp, p3_x2.xy);
    p3_x3 = p3_x3 * float4(0.0799999982, 0.0799999982, 0.0799999982, 0.0799999982);
    p3_x1 = p3_x1 * float4(0.159999996, 0.159999996, 0.159999996, 0.159999996) + p3_x3;
    p3_x2 = _BloomTex.sample(__nv_smp, p3_x2.zw);
    p3_x1 = p3_x2 * float4(0.0799999982, 0.0799999982, 0.0799999982, 0.0799999982) + p3_x1;
    p3_x2 = p3_x0.xyxy * float4(1.0, 0.0, 0.0, 1.0) + nvUV.xyxy;
    p3_x3 = _BloomTex.sample(__nv_smp, p3_x2.xy);
    p3_x1 = p3_x3 * float4(0.0799999982, 0.0799999982, 0.0799999982, 0.0799999982) + p3_x1;
    p3_x2 = _BloomTex.sample(__nv_smp, p3_x2.zw);
    p3_x1 = p3_x2 * float4(0.0799999982, 0.0799999982, 0.0799999982, 0.0799999982) + p3_x1;
    p3_x12.xy = (-(1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xy) * float2(float2(_BloomSpread, _BloomSpread)) + nvUV.xy;
    p3_x2 = _BloomTex.sample(__nv_smp, p3_x12.xy);
    p3_x1 = p3_x2 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p3_x1;
    p3_x2 = p3_x0.xyxy * float4(1.0, -1.0, -1.0, 1.0) + nvUV.xyxy;
    p3_x3 = _BloomTex.sample(__nv_smp, p3_x2.xy);
    p3_x1 = p3_x3 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p3_x1;
    p3_x2 = _BloomTex.sample(__nv_smp, p3_x2.zw);
    p3_x1 = p3_x2 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p3_x1;
    p3_x12.xy = (1.0 / float2(int2(int(_BloomTex.get_width()), int(_BloomTex.get_height())))).xy * float2(float2(_BloomSpread, _BloomSpread)) + nvUV.xy;
    p3_x2 = _BloomTex.sample(__nv_smp, p3_x12.xy);
    p3_x1 = p3_x2 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p3_x1;
    p3_x2 = p3_x0.xyxy * float4(0.0, 2.0, 2.0, 0.0) + nvUV.xyxy;
    p3_x3 = _BloomTex.sample(__nv_smp, p3_x2.xy);
    p3_x1 = p3_x3 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p3_x1;
    p3_x2 = _BloomTex.sample(__nv_smp, p3_x2.zw);
    p3_x1 = p3_x2 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p3_x1;
    p3_x2 = p3_x0.xyxy * float4(0.0, -2.0, -2.0, 0.0) + nvUV.xyxy;
    p3_x3 = _BloomTex.sample(__nv_smp, p3_x2.xy);
    p3_x1 = p3_x3 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p3_x1;
    p3_x2 = _BloomTex.sample(__nv_smp, p3_x2.zw);
    p3_x1 = p3_x2 * float4(0.0399999991, 0.0399999991, 0.0399999991, 0.0399999991) + p3_x1;
    p3_x2 = p3_x0.xyxy * float4(-2.0, 1.0, -1.0, 2.0) + nvUV.xyxy;
    p3_x3 = _BloomTex.sample(__nv_smp, p3_x2.xy);
    p3_x1 = p3_x3 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p3_x1;
    p3_x2 = _BloomTex.sample(__nv_smp, p3_x2.zw);
    p3_x1 = p3_x2 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p3_x1;
    p3_x2 = p3_x0.xyxy * float4(1.0, 2.0, 2.0, 1.0) + nvUV.xyxy;
    p3_x3 = _BloomTex.sample(__nv_smp, p3_x2.xy);
    p3_x1 = p3_x3 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p3_x1;
    p3_x2 = _BloomTex.sample(__nv_smp, p3_x2.zw);
    p3_x1 = p3_x2 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p3_x1;
    p3_x2 = p3_x0.xyxy * float4(2.0, -1.0, 1.0, -2.0) + nvUV.xyxy;
    p3_x3 = _BloomTex.sample(__nv_smp, p3_x2.xy);
    p3_x1 = p3_x3 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p3_x1;
    p3_x2 = _BloomTex.sample(__nv_smp, p3_x2.zw);
    p3_x1 = p3_x2 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p3_x1;
    p3_x2 = p3_x0.xyxy * float4(-1.0, -2.0, -2.0, -1.0) + nvUV.xyxy;
    p3_x3 = _BloomTex.sample(__nv_smp, p3_x2.xy);
    p3_x1 = p3_x3 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p3_x1;
    p3_x2 = _BloomTex.sample(__nv_smp, p3_x2.zw);
    p3_x1 = p3_x2 * float4(0.0199999996, 0.0199999996, 0.0199999996, 0.0199999996) + p3_x1;
    p3_x2 = p3_x0.xyxy * float4(-2.0, 2.0, 2.0, -2.0) + nvUV.xyxy;
    p3_x3 = _BloomTex.sample(__nv_smp, p3_x2.xy);
    p3_x1 = p3_x3 * float4(0.00999999978, 0.00999999978, 0.00999999978, 0.00999999978) + p3_x1;
    p3_x12.xy = p3_x0.xy * float2(2.0, 2.0) + nvUV.xy;
    p3_x3 = _BloomTex.sample(__nv_smp, p3_x12.xy);
    p3_x1 = p3_x3 * float4(0.00999999978, 0.00999999978, 0.00999999978, 0.00999999978) + p3_x1;
    p3_x2 = _BloomTex.sample(__nv_smp, p3_x2.zw);
    p3_x1 = p3_x2 * float4(0.00999999978, 0.00999999978, 0.00999999978, 0.00999999978) + p3_x1;
    p3_x0.xy = p3_x0.xy * float2(-2.0, -2.0) + nvUV.xy;
    p3_x0 = _BloomTex.sample(__nv_smp, p3_x0.xy);
    p3_x0 = p3_x0 * float4(0.00999999978, 0.00999999978, 0.00999999978, 0.00999999978) + p3_x1;
    p3_x1 = pre.sample(__nv_smp, nvUV.xy);
    p3_x0 = p3_x0 * float4(float4(u._BloomIntensity, u._BloomIntensity, u._BloomIntensity, u._BloomIntensity)) + p3_x1;
    if(int(_use_inner_mask) != 0) {
        p3_xb2.xy = equal(int4(int(_show_inner_mask), int(_b_clip_mask), int(_show_inner_mask), int(_show_inner_mask)), int4(1, 1, 0, 0)).xy;
        p3_x3 = (p3_xb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : p3_x0;
        p3_x4 = pre.sample(__nv_smp, nvUV.xy);
        p3_x5 = (-p3_x4) + float4(1.0, 1.0, 1.0, 1.0);
        p3_x1 = p3_x1 * p3_x5;
        p3_x1 = p3_x3 * p3_x4 + p3_x1;
        p3_x2.x = p3_x4.x * p3_x1.w;
        __nv_out.w = (p3_xb2.y) ? p3_x2.x : p3_x1.w;
        __nv_out.xyz = p3_x1.xyz;
    } else {
        __nv_out = p3_x0;
    }
    return;
}

fragment float4 fx_nv_nodevideo_effect_stylize_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_stylize_glowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pre [[texture(1)]],
    texture2d<float> ds0 [[texture(2)]],
    texture2d<float> ds1 [[texture(3)]],
    texture2d<float> ds2 [[texture(4)]],
    texture2d<float> ds3 [[texture(5)]],
    texture2d<float> ds4 [[texture(6)]],
    texture2d<float> ds5 [[texture(7)]],
    texture2d<float> ds6 [[texture(8)]],
    texture2d<float> ds7 [[texture(9)]],
    texture2d<float> up0 [[texture(10)]],
    texture2d<float> up1 [[texture(11)]],
    texture2d<float> up2 [[texture(12)]],
    texture2d<float> up3 [[texture(13)]],
    texture2d<float> up4 [[texture(14)]],
    texture2d<float> up5 [[texture(15)]],
    texture2d<float> up6 [[texture(16)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    nvUV = in.acScreenNorm;
    if (eng.acPass == 0) { __nv_out = nvEntrada(); return __nv_out; }
    if (eng.acPass == 1) { p0_main(); return __nv_out; }
    if (eng.acPass == 2) { if (1 > nvN()) { __nv_out = float4(0.0); return __nv_out; } p1_main(ds0); return __nv_out; }
    if (eng.acPass == 3) { if (2 > nvN()) { __nv_out = float4(0.0); return __nv_out; } p1_main(ds1); return __nv_out; }
    if (eng.acPass == 4) { if (3 > nvN()) { __nv_out = float4(0.0); return __nv_out; } p1_main(ds2); return __nv_out; }
    if (eng.acPass == 5) { if (4 > nvN()) { __nv_out = float4(0.0); return __nv_out; } p1_main(ds3); return __nv_out; }
    if (eng.acPass == 6) { if (5 > nvN()) { __nv_out = float4(0.0); return __nv_out; } p1_main(ds4); return __nv_out; }
    if (eng.acPass == 7) { if (6 > nvN()) { __nv_out = float4(0.0); return __nv_out; } p1_main(ds5); return __nv_out; }
    if (eng.acPass == 8) { if (7 > nvN()) { __nv_out = float4(0.0); return __nv_out; } p1_main(ds6); return __nv_out; }
    if (eng.acPass == 9) { if (7 > nvN()) { __nv_out = float4(0.0); return __nv_out; } p2_main(ds7, ds6); return __nv_out; }
    if (eng.acPass == 10) { int n = nvN(); if (6 > n) { __nv_out = float4(0.0); return __nv_out; } if (6 == n) p2_main(ds6, ds5); else p2_main(up6, ds5); return __nv_out; }
    if (eng.acPass == 11) { int n = nvN(); if (5 > n) { __nv_out = float4(0.0); return __nv_out; } if (5 == n) p2_main(ds5, ds4); else p2_main(up5, ds4); return __nv_out; }
    if (eng.acPass == 12) { int n = nvN(); if (4 > n) { __nv_out = float4(0.0); return __nv_out; } if (4 == n) p2_main(ds4, ds3); else p2_main(up4, ds3); return __nv_out; }
    if (eng.acPass == 13) { int n = nvN(); if (3 > n) { __nv_out = float4(0.0); return __nv_out; } if (3 == n) p2_main(ds3, ds2); else p2_main(up3, ds2); return __nv_out; }
    if (eng.acPass == 14) { int n = nvN(); if (2 > n) { __nv_out = float4(0.0); return __nv_out; } if (2 == n) p2_main(ds2, ds1); else p2_main(up2, ds1); return __nv_out; }
    if (eng.acPass == 15) { int n = nvN(); if (1 > n) { __nv_out = float4(0.0); return __nv_out; } if (1 == n) p2_main(ds1, ds0); else p2_main(up1, ds0); return __nv_out; }
    if (eng.acPass == 16) { p3_main(up0); __nv_out = nvSaida(__nv_out); return __nv_out; }
    __nv_out = float4(0.0);
    return __nv_out;
}
