// ---------------------------------------------------------------------------
// Time Slice (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-time-slice.xml
// id     : nv.effect.nodevideo-rendercommand-time-slice
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_time_sliceParams {
    float _slice_count;
    float _frame_offset;
    float _frame_interval;
    float _feather;
    float _slice_angle;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode

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

static int nvContagem() { return clamp(int(u._slice_count), 1, 30); }

// A faixa do pixel (o u_xlati0 do Node) e a fração dentro dela.
static int nvFaixa(float2 uv, out float fracao) {
    float2 p = (uv - 0.5) * _viewport_ratio.xy;
    float a = u._slice_angle * 0.0174532924;
    float x = float(nvContagem()) * (dot(float2(sin(a), cos(a)), p) + 0.5);
    fracao = fract(x);
    return int(floor(x));
}

// Quantos quadros atrás está a fatia k: t + (offset + intervalo x (k + 1 - c)) / FPS; o offset positivo (o futuro)
// vira atraso da saída inteira.
static int nvAtras(int k) {
    int c = nvContagem();
    int off = int(u._frame_offset);
    return int(u._frame_interval) * (c - 1 - k) - off + max(off, 0);
}

// Dos 12 mais novos: o quadro `atras` (até 12), ou o mais velho que houver até ele.
static float4 nvPerto(int atras, float2 uv) {
    if (atras >= 12 && nvTem(int2(int(h12.get_width()), int(h12.get_height())))) return h12.sample(__nv_smp, uv);
    if (atras >= 11 && nvTem(int2(int(h11.get_width()), int(h11.get_height())))) return h11.sample(__nv_smp, uv);
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

// Dos 13..23: o quadro `atras` (preso em 23) ou o mais velho que houver até o 13; sem nenhum, `perto`.
static float4 nvLonge(int atras, float2 uv, float4 perto) {
    if (atras >= 23 && nvTem(int2(int(h23.get_width()), int(h23.get_height())))) return h23.sample(__nv_smp, uv);
    if (atras >= 22 && nvTem(int2(int(h22.get_width()), int(h22.get_height())))) return h22.sample(__nv_smp, uv);
    if (atras >= 21 && nvTem(int2(int(h21.get_width()), int(h21.get_height())))) return h21.sample(__nv_smp, uv);
    if (atras >= 20 && nvTem(int2(int(h20.get_width()), int(h20.get_height())))) return h20.sample(__nv_smp, uv);
    if (atras >= 19 && nvTem(int2(int(h19.get_width()), int(h19.get_height())))) return h19.sample(__nv_smp, uv);
    if (atras >= 18 && nvTem(int2(int(h18.get_width()), int(h18.get_height())))) return h18.sample(__nv_smp, uv);
    if (atras >= 17 && nvTem(int2(int(h17.get_width()), int(h17.get_height())))) return h17.sample(__nv_smp, uv);
    if (atras >= 16 && nvTem(int2(int(h16.get_width()), int(h16.get_height())))) return h16.sample(__nv_smp, uv);
    if (atras >= 15 && nvTem(int2(int(h15.get_width()), int(h15.get_height())))) return h15.sample(__nv_smp, uv);
    if (atras >= 14 && nvTem(int2(int(h14.get_width()), int(h14.get_height())))) return h14.sample(__nv_smp, uv);
    if (atras >= 13 && nvTem(int2(int(h13.get_width()), int(h13.get_height())))) return h13.sample(__nv_smp, uv);
    return perto;
}

// O programa do Node para _cur_slice = cur, conta por conta (o peso da fonte no pixel).
static float nvPeso(int u_xlati0, float fracao, int cur) {
    float u_xlat3 = fracao + -1.0;
    float u_xlat6 = float(1.0) / (-u._feather);
    u_xlat3 = u_xlat6 * u_xlat3;
    u_xlat3 = clamp(u_xlat3, 0.0, 1.0);
    u_xlat6 = u_xlat3 * -2.0 + 3.0;
    u_xlat3 = u_xlat3 * u_xlat3;
    float u_xlat9 = u_xlati0 == cur ? 1.0 : 0.0;
    u_xlat3 = (-u_xlat6) * u_xlat3 + u_xlat9;
    u_xlat3 = u_xlat3 + 1.0;
    return (cur - 1 == u_xlati0) ? u_xlat3 : u_xlat9;
}

// Uma passada do Node: o shader (fonte x peso + RT x (1 - peso)) e a mistura SrcAlpha OneMinusSrcAlpha num RT de 8 bits.
static float4 nvPassada(float4 fonte, float4 rt, float peso) {
    float4 o = clamp(fonte * peso + rt * (1.0 - peso), 0.0, 1.0);
    return clamp(o * o.a + rt * (1.0 - o.a), 0.0, 1.0);
}

fragment float4 fx_nv_nodevideo_rendercommand_time_slice(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_time_sliceParams&  u    [[buffer(1)]],
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
    texture2d<float> h10 [[texture(10)]],
    texture2d<float> h11 [[texture(11)]],
    texture2d<float> h12 [[texture(12)]],
    texture2d<float> h13 [[texture(13)]],
    texture2d<float> h14 [[texture(14)]],
    texture2d<float> h15 [[texture(15)]],
    texture2d<float> h16 [[texture(16)]],
    texture2d<float> h17 [[texture(17)]],
    texture2d<float> h18 [[texture(18)]],
    texture2d<float> h19 [[texture(19)]],
    texture2d<float> h20 [[texture(20)]],
    texture2d<float> h21 [[texture(21)]],
    texture2d<float> h22 [[texture(22)]],
    texture2d<float> h23 [[texture(23)]],
    texture2d<float> perto0 [[texture(24)]],
    texture2d<float> perto1 [[texture(25)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float fracao;
    int s = nvFaixa(uv, fracao);
    int c = nvContagem();

    if (eng.acPass == 0) {
        __nv_out = nvPerto(nvAtras(s), uv);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        __nv_out = nvPerto(nvAtras(min(s + 1, c - 1)), uv);
        return __nv_out;
    }

    float4 saida = float4(0.0);
    if (s >= 0 && s < c) {
        // _cur_slice = s: a fatia do pixel
        float4 f0 = nvNode(nvLonge(nvAtras(s), uv, perto0.sample(__nv_smp, uv)));
        saida = nvPassada(f0, saida, nvPeso(s, fracao, s));
        // _cur_slice = s + 1: a suavização da seguinte
        if (s + 1 < c) {
            float4 f1 = nvNode(nvLonge(nvAtras(s + 1), uv, perto1.sample(__nv_smp, uv)));
            saida = nvPassada(f1, saida, nvPeso(s, fracao, s + 1));
        }
    }
    __nv_out = nvNova(saida);
    return __nv_out;
}
