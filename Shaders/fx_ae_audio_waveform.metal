// ---------------------------------------------------------------------------
// Audio Waveform (AE)
// origem : assets/effects/ae-audio-waveform.xml
// id     : nova.effect.aeaudiowaveform
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_audio_waveformParams {
    float2 startPoint;
    float2 endPoint;
    float samples;
    float maxHeight;
    float duration;
    float offset;
    float thickness;
    float softness;
    float seed;
    float4 insideColor;
    float4 outsideColor;
    int channels;
    int display;
    int composite;
};

// --- funcoes auxiliares do efeito
// A largura da textura de pontos (`WaveformTexture.LARGURA`) e quantos pontos, no máximo, um pixel olha.
const int LARGURA = 256;
const int VIZINHOS = 64;

/** O texel `i` da textura de pontos, desempacotado: dois números de 16 bits. */
float2 par(int i) {
    float4 b = floor(ondaImg.read(uint2(int2(i % LARGURA, i / LARGURA)), uint(0)) * 255.0 + 0.5);
    return float2(b.r * 256.0 + b.g, b.b * 256.0 + b.a);
}

/** Quantos px o ponto fica do caminho: o valor de 16 bits vezes a altura, cortado para o zero. */
float altura(float bruto) { return trunc((bruto - 32768.0) / 65535.0 * u.maxHeight); }

float aoSegmento(float2 p, float2 a, float2 b) {
    float2 v = b - a;
    float l2 = dot(v, v);
    float t = l2 > 0.0 ? clamp(dot(p - a, v) / l2, 0.0, 1.0) : 0.0;
    return length(p - a - t * v);
}

float4 sobre(float4 baixo, float4 cima) {
    float a = cima.a + baixo.a * (1.0 - cima.a);
    if (a <= 0.0) return float4(0.0);
    return float4((cima.rgb * cima.a + baixo.rgb * baixo.a * (1.0 - cima.a)) / a, a);
}

fragment float4 fx_ae_audio_waveform(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_audio_waveformParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> ondaImg [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 fundo = u.composite ? inputImg.sample(__nv_smp, in.acScreenNorm) : float4(0.0);

    float2 cabecalho = par(0);
    int quantos = int(cabecalho.x + 0.5);
    int divisor = max(int(cabecalho.y + 0.5), 1);
    if (u.thickness <= 0.0 || quantos <= 0) { __nv_out = fundo; return __nv_out; }

    // Tudo em px da COMPOSIÇÃO: a prévia em meia resolução desenha o mesmo traço, menor.
    float2 tamanho = eng.acResolution / eng.acEscalaDePixel;
    float2 inicio = u.startPoint * tamanho;
    float2 caminho = u.endPoint * tamanho - inicio;
    float comprimento = length(caminho);
    // O AE trata a coordenada do ponto como o CENTRO do pixel: daí o meio px.
    float2 rel = in.acScreenNorm * tamanho - inicio - 0.5;

    float T = max(u.thickness, 1.0);
    float macio = 1.0 + u.softness * 0.01 * (T - 1.0);
    float alcance = 0.5 * (T + macio);
    bool linhas = u.display == 1;

    float d = 1.0e9;
    if (comprimento < 1.0e-6) {
        // Start e End no mesmo lugar: todos os pontos caem ali.
        if (!linhas || quantos > 1 || u.samples < 1.5) d = length(rel);
    } else {
        float2 ao = caminho / comprimento;
        float2 normal = float2(caminho.y, -caminho.x) / comprimento;
        float2 passo = caminho / float(divisor);
        float a = dot(rel, ao);
        float q = dot(rel, normal);

        if (abs(q) <= 0.5 * u.maxHeight + 1.0 + alcance) {
            float espaco = max(comprimento / float(divisor), 1.0e-4);
            float de = clamp(ceil((a - alcance) / espaco), -1.0, 70000.0);
            float ate = clamp(floor((a + alcance) / espaco), -2.0, 70000.0);
            int k0 = max(int(de) - (linhas ? 1 : 0), 0);
            int k1 = min(int(ate), quantos - (linhas ? 2 : 1));
            // Com milhares de amostras e traço grosso passam de VIZINHOS: aí o pixel olha um a cada `salto`.
            int salto = max((k1 - k0 + VIZINHOS) / VIZINHOS, 1);
            for (int i = 0; i < VIZINHOS; i++) {
                int k = k0 + i * salto;
                if (k > k1) break;
                float2 v = par(k + 1);
                float2 base = float(k) * passo;
                if (u.display == 0) {
                    d = min(d, aoSegmento(rel, base - altura(v.x) * normal, base - altura(v.y) * normal));
                } else if (u.display == 2) {
                    d = min(d, length(rel - base + altura(v.x) * normal));
                } else {
                    float seguinte = altura(par(k + 2).x);
                    d = min(d, aoSegmento(rel, base - altura(v.x) * normal, base + passo - seguinte * normal));
                }
            }
            // Uma amostra só, em linha: o AE liga o Start Point ao ponto.
            if (linhas && quantos == 1 && u.samples < 1.5) {
                d = min(d, aoSegmento(rel, float2(0.0), -altura(par(1).x) * normal));
            }
        }
    }

    // A régua do traço, medida: abaixo de 1 px ele é o de 1 px, mais transparente.
    float alfa = clamp(0.5 + (0.5 * T - d) / macio, 0.0, 1.0) * min(u.thickness, 1.0);
    float meia = max(0.5 * u.thickness, 2.0);
    float m0 = (meia - 0.5 * u.thickness) / (2.0 * meia);
    float3 cor = mix(u.insideColor.rgb, u.outsideColor.rgb, min(m0 + d / meia, 1.0 - m0));

    __nv_out = u.composite ? sobre(fundo, float4(cor, alfa)) : float4(cor, alfa);
    return __nv_out;
}
