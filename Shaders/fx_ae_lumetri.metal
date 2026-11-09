// ---------------------------------------------------------------------------
// Lumetri Color
// origem : assets/effects/ae-lumetri.xml
// id     : nova.effect.aelumetri
// passes : 1
// Escrito a mao (base do glsl2msl.py + o resto do Lumetri do AE no iOS)
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
#include "NovaLut.h"
using namespace metal;

struct ae_lumetriParams {
    float4 lutDeEntrada;
    float4 look;
    float intensidade;
    float temperatura;
    float matiz;
    float exposicao;
    float contraste;
    float realces;
    float sombras;
    float brancos;
    float pretos;
    float saturacao;
    float filmeDesbotado;
    float nitidez;
    float vibracao;
    float saturacaoCriativa;
    float4 tomSombras;
    float4 tomRealces;
    float equilibrioTom;
    float vinheta;
    float vinhetaMeio;
    float vinhetaRedondeza;
    float vinhetaDifusao;
};

static float lum_luma(float3 c) { return dot(c, float3(0.2126, 0.7152, 0.0722)); }

// --- funcoes auxiliares do efeito
// Medir a interpolação no AE e trocar se for a trilinear (ver o cabeçalho).
constant bool TETRAEDRICA = true;

fragment float4 fx_ae_lumetri(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_lumetriParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture3d<float> lutDeEntradaTex [[texture(1)]],
    texture3d<float> lookTex [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float4 fonte = inputImg.read(uint2(int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0))), uint(0));
    float3 c = fonte.rgb;

    // Sharpen (Creative): mascara de nitidez com os 4 vizinhos.
    if (abs(u.nitidez) > 0.01) {
        int2 px = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
        float3 viz = float3(0.0);
        viz += inputImg.read(uint2(clamp(px + int2( 1, 0), int2(0), T - 1))).rgb;
        viz += inputImg.read(uint2(clamp(px + int2(-1, 0), int2(0), T - 1))).rgb;
        viz += inputImg.read(uint2(clamp(px + int2( 0, 1), int2(0), T - 1))).rgb;
        viz += inputImg.read(uint2(clamp(px + int2( 0,-1), int2(0), T - 1))).rgb;
        c = max(c + (c - viz * 0.25) * (u.nitidez / 100.0) * 1.5, 0.0);
    }

    // Basic Correction: o LUT de entrada, antes de tudo.
    c = nova_lut3d(lutDeEntradaTex, c);

    // Basic Correction: balanco de branco (Temperature / Tint).
    {
        float t = u.temperatura / 100.0, m = u.matiz / 100.0;
        c *= float3(1.0 + 0.30 * t + 0.10 * m, 1.0 - 0.20 * m, 1.0 - 0.30 * t + 0.10 * m);
    }
    // Exposure (em stops) e Contrast.
    c *= exp2(u.exposicao);
    c = max((c - 0.5) * (1.0 + u.contraste / 100.0) + 0.5, 0.0);
    // Highlights / Shadows / Whites / Blacks (pesos por faixa de luma).
    {
        float l = clamp(lum_luma(c), 0.0, 1.0);
        float pr = (1.0 - l) * (1.0 - l) * (1.0 - l);
        float so = smoothstep(0.0, 0.5, l) * (1.0 - smoothstep(0.25, 0.6, l)) + (1.0 - smoothstep(0.0, 0.45, l)) * 0.5;
        float re = smoothstep(0.4, 0.75, l) * (1.0 - smoothstep(0.85, 1.0, l)) + smoothstep(0.55, 1.0, l) * 0.5;
        float br = l * l * l;
        float d = u.pretos / 100.0 * 0.25 * pr + u.sombras / 100.0 * 0.30 * so
                + u.realces / 100.0 * 0.30 * re + u.brancos / 100.0 * 0.25 * br;
        c = max(c + d, 0.0);
    }
    // Saturation (Basic).
    c = max(mix(float3(lum_luma(c)), c, u.saturacao / 100.0), 0.0);

    // Creative: o Look, misturado pela Intensidade.
    // `lookTipo` (embutido do AM: 0 = sem Look). Aqui o motor sempre entrega uma
    // LUT 3D (identidade quando nao ha Look), entao misturar e seguro.
    {
        float3 comLook = nova_lut3d(lookTex, c);
        c = mix(c, comLook, clamp(u.intensidade, 0.0, 200.0) / 100.0);
    }

    // Creative: Faded Film (levanta os pretos e tira o contraste).
    {
        float f = clamp(u.filmeDesbotado, 0.0, 100.0) / 100.0;
        c = mix(c, c * 0.82 + 0.12, f);
    }
    // Vibrance: satura mais as cores pouco saturadas.
    {
        float mx = max(c.r, max(c.g, c.b)), mn = min(c.r, min(c.g, c.b));
        float s0 = mx - mn;
        float k = u.vibracao / 100.0 * (1.0 - s0);
        c = max(mix(float3(lum_luma(c)), c, 1.0 + k), 0.0);
    }
    // Creative Saturation.
    c = max(mix(float3(lum_luma(c)), c, u.saturacaoCriativa / 100.0), 0.0);
    // Shadow Tint / Highlight Tint com o Tint Balance.
    {
        float l = clamp(lum_luma(c), 0.0, 1.0);
        float eq = u.equilibrioTom / 100.0;
        float ws = clamp(1.0 - l - eq * 0.5, 0.0, 1.0), wh = clamp(l - eq * 0.5 * -1.0, 0.0, 1.0);
        c += (u.tomSombras.rgb - 0.5019608) * ws * 0.8 + (u.tomRealces.rgb - 0.5019608) * wh * 0.8;
        c = max(c, 0.0);
    }
    // Vignette.
    if (abs(u.vinheta) > 0.001) {
        float2 res = float2(T);
        float2 q = (in.acScreenNorm - 0.5) * 2.0;
        float r = u.vinhetaRedondeza / 100.0;
        q.x *= mix(1.0, res.x / res.y, clamp(r, 0.0, 1.0));
        float d = (r < 0.0) ? max(abs(q.x), abs(q.y)) * (-r) + length(q) * (1.0 + r) : length(q);
        float meio = mix(0.2, 1.4, u.vinhetaMeio / 100.0);
        float fe = max(u.vinhetaDifusao / 100.0, 0.01) * 0.9;
        float w = smoothstep(meio - fe, meio + fe, d);
        float amt = clamp(u.vinheta / 5.0, -1.0, 1.0);
        c = (amt < 0.0) ? c * (1.0 + amt * w) : mix(c, float3(1.0), amt * w);
    }

    __nv_out = float4(clamp(c, 0.0, 1.0), fonte.a);
    return __nv_out;
}
