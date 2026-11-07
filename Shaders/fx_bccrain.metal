// ---------------------------------------------------------------------------
// BCC Rain
// origem : assets/effects/bccrain.xml
// id     : nova.effect.bccrain
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bccrainParams {
    float rainAmount;
    float rainAngle;
    float rainSpeed;
    float rainDepth;
    float blur;
    float2 panXY;
    float randomSeed;
    float4 color;
    float size;
    float opacity;
    float brightnessVariance;
    int dropShape;
    float lifespan;
    float tileWidth;
    float speedVariance;
    float directionVariance;
};

// --- funcoes auxiliares do efeito
const int CAMADAS = 6;

static float h2(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

/** A largura do quadro, em pixels do buffer: é a régua do plugin. */
static float largura() { return eng.acResolution.x; }
/** A linha da gota tem ~1 px da COMPOSIÇÃO em qualquer resolução (σ 0,46: a energia medida de um risco). */
static float sigmaDaLinha() { return 0.46 * eng.acEscalaDePixel; }
/** O Blur cresce com a largura, mas devagar (medido em 640, 1280 e 1618: (L/640)^0,72). */
static float sigmaDoBlur() {
    return u.blur * (0.7 + 0.42 * exp(-u.blur / 2.5)) * pow(largura() / (640.0 * eng.acEscalaDePixel), 0.72) * eng.acEscalaDePixel;
}

/** Uma camada de riscos paralelos: (brilho × opacidade, opacidade) no pixel. */
static float2 camada(float2 px, float n) {
    float L = largura();
    float sem = u.randomSeed * 0.713 + n * 37.0;
    // Direction Variance: ±valor/2,7 graus (desvio medido 3,2° / 8,6° / 16,5° com 15 / 45 / 90), uma fatia por camada.
    float fatia = ((n + h2(float2(n, sem + 3.0))) / float(CAMADAS)) * 2.0 - 1.0;
    float ang = radians(u.rainAngle + u.directionVariance / 2.7 * fatia);
    float2 d = float2(sin(ang), cos(ang));                 // para onde a gota cai
    float2 o = float2(d.y, -d.x);
    float ao = dot(px, d), at = dot(px, o);

    float fatorDeTamanho = u.size < 0.0 ? 1.0 + u.size / 100.0 : pow(1.0 + u.size / 100.0, 4.2);
    float passo = u.rainSpeed * L / 3360.0;              // pixels por quadro de 1/30 s
    // 6 × Amount gotas por quadro 16:9 (= 10,67 × Amount por L²) com a velocidade de fábrica. O que
    // é fixo é quantas NASCEM por segundo: mais rápidas, menos gotas no quadro ao mesmo tempo.
    float densidade = 10.67 * u.rainAmount * min(120.0 / max(u.tileWidth, 1.0), 1.15) * 300.0 / max(u.rainSpeed, 10.0) / (L * L);
    // Chuva inclinada demora mais para cruzar o quadro: mais gotas à vista (medido em 45° e 75°).
    densidade *= pow(max(cos(radians(u.rainAngle)), 0.05), -0.8) / pow(cos(radians(15.0)), -0.8);
    float periodo = max(0.25 * L, 1.6 * passo * 1.6 * fatorDeTamanho);
    float faixa = 0.02 * L;
    float p = densidade * faixa * periodo / float(CAMADAS);
    if (p > 1.0) { faixa = max(faixa / p, 2.0 * eng.acEscalaDePixel); p = 1.0; }

    float2 soma = float2(0.0);
    float s0 = sigmaDaLinha();
    for (int k = -1; k <= 1; k++) {
        float f = floor(at / faixa) + float(k);
        float u = h2(float2(f, sem));
        // Profundidade: perto = mais rápido e comprido; Speed Variance: até 80% mais lento.
        float escala = 1.0 / (1.0 + u.rainDepth / 200.0 * (-0.28 + 0.6 * pow(u, 0.75)));
        float variacao = max(1.0 + u.speedVariance / 200.0 * (-0.9 + 1.1 * h2(float2(f, sem + 5.0))), 0.05);
        escala *= variacao;
        float vel = passo * escala * 30.0;             // px/s
        float comp = max(passo * escala * fatorDeTamanho, 0.0) + 1.2 * eng.acEscalaDePixel;
        float s = ao - vel * eng.acTime + h2(float2(f, sem + 9.0)) * periodo;
        float c = floor(s / periodo);
        if (h2(float2(f * 1.31 + c * 7.77, sem + c)) >= p / sqrt(variacao)) continue;   // as lentas ficam mais tempo no quadro
        float centro = (c + 0.5) * periodo + (h2(float2(c, f + sem)) - 0.5) * max(periodo - comp, 0.0);
        float t = (s - centro) / (0.5 * comp);         // −1 = a ponta de cima, +1 = a de baixo
        float bordaPx = (1.0 - abs(t)) * 0.5 * comp;
        if (bordaPx <= -1.0) continue;
        float aoLongo = u.dropShape == 0 ? clamp(bordaPx + 0.5, 0.0, 1.0) : clamp(1.0 - abs(t), 0.0, 1.0);
        float x = at - (f + 0.5 + (h2(float2(f, c + sem + 2.0)) - 0.5) * 0.7) * faixa;
        float perfil = exp(-0.5 * x * x / (s0 * s0)) * aoLongo;
        float brilho = 1.0 - clamp(-u.brightnessVariance, 0.0, 100.0) / 100.0 * h2(float2(c + 0.5, f + sem));
        soma = max(soma, perfil * float2(brilho, 1.0));
    }
    return soma;
}

static float4 borrar(bool deChuva, float2 eixo) {
    float sigma = sigmaDoBlur();
    float2 uv = in.acScreenNorm;
    if (sigma < 0.05) return deChuva ? chuva.sample(__nv_smp, uv) : bh.sample(__nv_smp, uv);
    float passo = max(1.0, ceil(3.0 * sigma / 20.0));
    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int n = -20; n <= 20; n++) {
        float dd = float(n) * passo;
        if (abs(dd) > 3.0 * sigma + 0.5) continue;
        float w = exp(-0.5 * dd * dd / (sigma * sigma));
        float2 q = uv + eixo * dd * eng.acTexelSize;
        soma += w * (deChuva ? chuva.sample(__nv_smp, q) : bh.sample(__nv_smp, q));
        pesos += w;
    }
    return soma / max(pesos, 1e-6);
}

fragment float4 fx_bccrain(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bccrainParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> chuva [[texture(1)]],
    texture2d<float> bh [[texture(2)]],
    texture2d<float> bv [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    if (eng.acPass == 0) {
        float2 px = (uv - (u.panXY - float2(0.5, 1.0))) * eng.acResolution;
        // As gotas nascem ~0,17·L acima do quadro e vivem `u.lifespan` quadros de queda.
        float alcance = -0.17 * largura() + u.rainSpeed * largura() / 3360.0 * u.lifespan * cos(radians(u.rainAngle));
        float2 soma = float2(0.0);
        if (u.rainAmount > 0.0 && u.rainSpeed > 0.0 && px.y < alcance) {
            for (int n = 0; n < CAMADAS; n++) {
                float2 c = camada(px, float(n));
                soma = soma + c * (1.0 - soma.y);       // uma gota por cima da outra
            }
        }
        // Guardado com folga: o borrão espalha, e o pico de uma linha de 1 px cabe em 8 bits.
        __nv_out = float4(soma.x, 0.0, 0.0, soma.y);
        return __nv_out;
    }
    if (eng.acPass == 1) { __nv_out = borrar(true, float2(1.0, 0.0)); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = borrar(false, float2(0.0, 1.0)); return __nv_out; }

    float4 fonte = inputImg.sample(__nv_smp, uv);
    float4 g = bv.sample(__nv_smp, uv);
    float op = pow(clamp(u.opacity / 100.0, 0.0, 1.0), 0.77);
    float a = clamp(g.a * op, 0.0, 1.0);
    __nv_out = float4(clamp(fonte.rgb * (1.0 - a) + u.color.rgb * g.r * op, 0.0, 1.0), fonte.a);
    return __nv_out;
}
