// ---------------------------------------------------------------------------
// Time Warp RGB (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-time-warp-rgb.xml
// id     : nv.effect.nodevideo-rendercommand-time-warp-rgb
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_time_warp_rgbParams {
    float _r_shift;
    float _g_shift;
    float _b_shift;
};

// --- funcoes auxiliares do efeito
// Os RTs do Node: luz linear, cor pré-multiplicada.
static float3 nvLinear(float3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c)); }
static float3 nvGama(float3 l) { return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l)); }
static float4 nvNode(float4 c) { return float4(nvLinear(c.rgb) * c.a, c.a); }
static float4 nvNova(float4 p) {
    if (p.a <= 0.0) return float4(0.0);
    return float4(nvGama(clamp(p.rgb / p.a, 0.0, 1.0)), p.a);
}

// O quadro que o anel não tem chega 1x1 (a textura transparente do FrameHistory).
static bool nvTem(int2 tamanho) { return tamanho.x > 1 || tamanho.y > 1; }

// A camada `atras` quadros atrás; sem ele no anel, o mais novo que houver (até o de agora).
static float4 nvQuadro(int atras, float2 uv) {
    if (atras >= 10 && nvTem(int2(int(h10.get_width()), int(h10.get_height())))) return h10.sample(__nv_smp, uv);
    if (atras >= 9 && nvTem(int2(int(h9.get_width()), int(h9.get_height())))) return h9.sample(__nv_smp, uv);
    if (atras >= 8 && nvTem(int2(int(h8.get_width()), int(h8.get_height())))) return h8.sample(__nv_smp, uv);
    if (atras >= 7 && nvTem(int2(int(h7.get_width()), int(h7.get_height())))) return h7.sample(__nv_smp, uv);
    if (atras >= 6 && nvTem(int2(int(h6.get_width()), int(h6.get_height())))) return h6.sample(__nv_smp, uv);
    if (atras >= 5 && nvTem(int2(int(h5.get_width()), int(h5.get_height())))) return h5.sample(__nv_smp, uv);
    if (atras >= 4 && nvTem(int2(int(h4.get_width()), int(h4.get_height())))) return h4.sample(__nv_smp, uv);
    if (atras >= 3 && nvTem(int2(int(h3.get_width()), int(h3.get_height())))) return h3.sample(__nv_smp, uv);
    if (atras >= 2 && nvTem(int2(int(h2.get_width()), int(h2.get_height())))) return h2.sample(__nv_smp, uv);
    if (atras >= 1 && nvTem(int2(int(h1.get_width()), int(h1.get_height())))) return h1.sample(__nv_smp, uv);
    return inputImg.sample(__nv_smp, uv);
}

fragment float4 fx_nv_nodevideo_rendercommand_time_warp_rgb(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_time_warp_rgbParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> h1 [[texture(1)]],
    texture2d<float> h2 [[texture(2)]],
    texture2d<float> h3 [[texture(3)]],
    texture2d<float> h4 [[texture(4)]],
    texture2d<float> h5 [[texture(5)]],
    texture2d<float> h6 [[texture(6)]],
    texture2d<float> h7 [[texture(7)]],
    texture2d<float> h8 [[texture(8)]],
    texture2d<float> h9 [[texture(9)]],
    texture2d<float> h10 [[texture(10)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    int r = int(floor(u._r_shift + 0.5));
    int g = int(floor(u._g_shift + 0.5));
    int b = int(floor(u._b_shift + 0.5));
    int atraso = max(max(r, g), max(b, 0));   // o futuro que o anel não tem vira atraso da saída

    float4 TimeWarpR = nvNode(nvQuadro(atraso - r, uv));
    float4 TimeWarpG = nvNode(nvQuadro(atraso - g, uv));
    float4 TimeWarpB = nvNode(nvQuadro(atraso - b, uv));
    float4 TimeWarpOri = nvNode(nvQuadro(atraso, uv));

    // O programa do Node, conta por conta.
    float4 saida;
    saida.x = TimeWarpR.x;
    saida.y = TimeWarpG.y;
    saida.z = TimeWarpB.z;
    saida.w = TimeWarpOri.w;
    __nv_out = nvNova(clamp(saida, 0.0, 1.0));
    return __nv_out;
}
