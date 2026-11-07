// ---------------------------------------------------------------------------
// Audio Spectrum (AE)
// origem : assets/effects/ae-audio-spectrum.xml
// id     : nova.effect.aeaudiospectrum
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_audio_spectrumParams {
    float2 startPoint;
    float2 endPoint;
    float startFreq;
    float endFreq;
    float bands;
    float maxHeight;
    float duration;
    float offset;
    float thickness;
    float softness;
    float4 insideColor;
    float4 outsideColor;
    int blendColors;
    float hue;
    int dynamicHue;
    int colorSymmetry;
    int display;
    int side;
    int averaging;
    int composite;
};

// --- funcoes auxiliares do efeito
// A largura da textura de faixas (`SpectrumAeTexture.LARGURA`) e quantas faixas, no máximo, um pixel olha.
const int LARGURA = 256;
const int VIZINHOS = 48;

static float4 texel(int i) { return floor(faixasImg.read(uint2(int2(i % LARGURA, i / LARGURA)), uint(0)) * 255.0 + 0.5); }

/** A altura da faixa em px: 24 bits de 0 a 1, vezes Maximum Height. */
static float alturaDa(int b) {
    float4 t = texel(1 + 3 * b);
    return (t.r * 65536.0 + t.g * 256.0 + t.b) / 16777215.0 * u.maxHeight;
}

static float aoSegmento(float2 p, float2 a, float2 b) {
    float2 v = b - a;
    float l2 = dot(v, v);
    float t = l2 > 0.0 ? clamp(dot(p - a, v) / l2, 0.0, 1.0) : 0.0;
    return length(p - a - t * v);
}

static float4 sobre(float4 baixo, float4 cima) {
    float a = cima.a + baixo.a * (1.0 - cima.a);
    if (a <= 0.0) return float4(0.0);
    return float4((cima.rgb * cima.a + baixo.rgb * baixo.a * (1.0 - cima.a)) / a, a);
}

// A régua do traço (a do Audio Waveform) e o que já foi desenhado neste pixel.
float T, macio, meia, m0;
float jaAlfa = 0.0, jaDistancia = 1.0e9;
float3 jaCor = float3(0.0);

/** Junta ao pixel o traço da faixa `b`, que passa a `d` px dele. */
static void traco(float d, int b) {
    float a = clamp(0.5 + (0.5 * T - d) / macio, 0.0, 1.0) * min(u.thickness, 1.0);
    if (a <= 0.0) return;
    float3 c = mix(texel(2 + 3 * b).rgb, texel(3 + 3 * b).rgb, min(m0 + d / meia, 1.0 - m0)) / 255.0;
    if (u.blendColors) {
        // cada traço novo entra POR TRÁS do que já está
        float novo = jaAlfa + a * (1.0 - jaAlfa);
        jaCor = (jaCor * jaAlfa + c * a * (1.0 - jaAlfa)) / novo;
        jaAlfa = novo;
    } else if (d < jaDistancia) {
        // vale o traço mais próximo
        jaDistancia = d; jaAlfa = a; jaCor = c;
    }
}

/** Para que lado vai a faixa `b` nos modos Analog: A sobe (−1), B desce (+1); com os dois, alternam. */
static float lado(int b) { return u.side == 0 ? -1.0 : (u.side == 1 ? 1.0 : ((b & 1) == 1 ? 1.0 : -1.0)); }

fragment float4 fx_ae_audio_spectrum(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_audio_spectrumParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> faixasImg [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 fundo = u.composite ? inputImg.sample(__nv_smp, in.acScreenNorm) : float4(0.0);

    float4 cabecalho = texel(0);
    int quantas = int(cabecalho.r * 256.0 + cabecalho.g + 0.5);
    if (u.thickness <= 0.0 || quantas <= 0) { __nv_out = fundo; return __nv_out; }

    // Tudo em px da COMPOSIÇÃO; o AE trata a coordenada do ponto como o CENTRO do pixel (daí o meio px).
    float2 tamanho = eng.acResolution / eng.acEscalaDePixel;
    float2 inicio = u.startPoint * tamanho;
    float2 caminho = u.endPoint * tamanho - inicio;
    float comprimento = length(caminho);
    float2 rel = in.acScreenNorm * tamanho - inicio - 0.5;

    T = max(u.thickness, 1.0);
    macio = 1.0 + u.softness * 0.01 * (T - 1.0);
    meia = max(0.5 * u.thickness, 2.0);
    m0 = (meia - 0.5 * u.thickness) / (2.0 * meia);
    float alcance = 0.5 * (T + macio);
    bool linhas = u.display == 1;

    bool reta = comprimento > 1.0e-6 && quantas > 1;
    float2 ao = reta ? caminho / comprimento : float2(1.0, 0.0);
    // altura positiva DESCE quando o caminho vai da esquerda para a direita
    float2 normal = comprimento > 1.0e-6 ? float2(-caminho.y, caminho.x) / comprimento : float2(0.0);
    float2 passo = quantas > 1 ? caminho / float(quantas - 1) : float2(0.0);

    int k0 = linhas ? 1 : 0;
    int k1 = quantas - 1;
    bool perto = true;
    if (reta) {
        float a = dot(rel, ao);
        float espaco = max(comprimento / float(quantas - 1), 1.0e-4);
        k0 = max(int(clamp(ceil((a - alcance) / espaco), -1.0, 5000.0)), k0);
        k1 = min(int(clamp(floor((a + alcance) / espaco), -2.0, 5000.0)) + (linhas ? 1 : 0), k1);
        perto = abs(dot(rel, normal)) <= u.maxHeight + alcance;
    }

    if (perto) {
        // Com milhares de faixas e traço grosso passam de VIZINHOS: aí o pixel olha uma a cada `salto`.
        int salto = max((k1 - k0 + VIZINHOS) / VIZINHOS, 1);
        for (int i = 0; i < VIZINHOS; i++) {
            int b = k0 + i * salto;
            if (b > k1) break;
            float2 base = float(b) * passo;
            float h = alturaDa(b);
            if (u.display == 0) {
                traco(aoSegmento(rel, base - (u.side == 1 ? 0.0 : h) * normal, base + (u.side == 0 ? 0.0 : h) * normal), b);
            } else if (u.display == 2) {
                // com os dois lados, o ponto de baixo é desenhado primeiro
                if (u.side != 0) traco(length(rel - base - h * normal), b);
                if (u.side != 1) traco(length(rel - base + h * normal), b);
            } else {
                float anterior = alturaDa(b - 1);
                traco(aoSegmento(rel, base - passo + lado(b - 1) * anterior * normal, base + lado(b) * h * normal), b);
            }
        }
        // Uma faixa só, em linha: o AE desenha um ponto.
        if (linhas && quantas == 1) traco(length(rel - lado(0) * alturaDa(0) * normal), 0);
    }

    float4 desenho = float4(jaCor, jaAlfa);
    __nv_out = u.composite ? sobre(fundo, desenho) : desenho;
    return __nv_out;
}
