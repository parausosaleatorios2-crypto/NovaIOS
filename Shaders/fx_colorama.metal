// ---------------------------------------------------------------------------
// Colorama
// origem : assets/effects/colorama.xml
// id     : nova.effect.colorama
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct coloramaParams {
    int getPhase;
    float phaseShift;
    float velocidade;
    float repeticoes;
    int ciclo;
    int addPhaseFrom;
    int addMode;
    int modify;
    int modifyAlpha;
    int changeEmpty;
    int matchMode;
    float4 matchColor;
    float matchTolerance;
    float matchSoftness;
    int maskMode;
    int compositeOver;
};

// --- funcoes auxiliares do efeito
// ============================================================================
//  OS ATRIBUTOS DE COR
// ============================================================================

float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

/** HSL: matiz 0..1 (0 = vermelho), saturação e luminosidade. */
float3 paraHsl(float3 c) {
    float maior = max(c.r, max(c.g, c.b));
    float menor = min(c.r, min(c.g, c.b));
    float l = (maior + menor) * 0.5;
    float d = maior - menor;
    if (d < 1e-5) return float3(0.0, 0.0, l);
    float s = l > 0.5 ? d / (2.0 - maior - menor) : d / (maior + menor);
    float h;
    if (maior == c.r) h = (c.g - c.b) / d + (c.g < c.b ? 6.0 : 0.0);
    else if (maior == c.g) h = (c.b - c.r) / d + 2.0;
    else h = (c.r - c.g) / d + 4.0;
    return float3(h / 6.0, s, l);
}

float canalDaMatiz(float p, float q, float t) {
    t = t - floor(t);
    if (t < 1.0 / 6.0) return p + (q - p) * 6.0 * t;
    if (t < 0.5) return q;
    if (t < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
    return p;
}

float3 deHsl(float3 hsl) {
    if (hsl.y < 1e-5) return float3(hsl.z);
    float q = hsl.z < 0.5 ? hsl.z * (1.0 + hsl.y) : hsl.z + hsl.y - hsl.z * hsl.y;
    float p = 2.0 * hsl.z - q;
    return float3(
        canalDaMatiz(p, q, hsl.x + 1.0 / 3.0),
        canalDaMatiz(p, q, hsl.x),
        canalDaMatiz(p, q, hsl.x - 1.0 / 3.0));
}

/** A fase de um pixel pelo atributo escolhido (a lista do "Get Phase From"). */
float faseDe(float4 c, int atributo) {
    if (atributo == 0) return (c.r + c.g + c.b) / 3.0;   // Intensity: a média simples (o print)
    if (atributo == 1) return c.r;
    if (atributo == 2) return c.g;
    if (atributo == 3) return c.b;
    if (atributo == 4) return paraHsl(c.rgb).x;
    if (atributo == 5) return paraHsl(c.rgb).z;
    if (atributo == 6) return paraHsl(c.rgb).y;
    if (atributo == 7) return max(c.r, max(c.g, c.b));
    if (atributo == 8) return c.a;
    return 0.0;                                           // Zero
}

// ============================================================================
//  A RODA
// ============================================================================

/** A cor da roda em t (0 = topo, começo; 1 = topo, fim). */
float4 naRoda(float t) {
    float x = clamp(t, 0.0, 1.0) * 256.0;
    int i = min(int(floor(x)), 255);
    float f = x - float(i);
    return mix(u.ciclo.read(uint2(int2(i, 0)), uint(0)), u.ciclo.read(uint2(int2(i + 1, 0)), uint(0)), f);
}

fragment float4 fx_colorama(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant coloramaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> addPhaseLayer [[texture(1)]],
    texture2d<float> maskLayer [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    float fase = faseDe(original, u.getPhase);

    // ------------------------------------------------ a segunda fase
    // Sem camada escolhida o motor entrega uma textura 1×1 (empty="transparent"):
    // aí não há segunda fase.
    if (int2(int(addPhaseLayer.get_width()), int(addPhaseLayer.get_height())).x > 1) {
        float outra = faseDe(addPhaseLayer.sample(__nv_smp, in.acScreenNorm), u.addPhaseFrom);
        if (u.addMode == 0) fase = fase + outra;                           // Wrap: dá a volta
        else if (u.addMode == 1) fase = min(fase + outra, 1.0);             // Clamp
        else if (u.addMode == 2) fase = (fase + outra) * 0.5;               // Average
        else fase = 1.0 - (1.0 - fase) * (1.0 - outra);                   // Screen
    }

    // ------------------------------------------------ a volta na roda
    // O Phase Shift positivo leva o começo no sentido horário; "Girar com o
    // tempo" é o mesmo giro andando sozinho.
    float voltas = fase * u.repeticoes + u.phaseShift / 360.0 + u.velocidade * eng.acTime;
    float t = voltas - floor(voltas);
    // Uma volta inteira e exata (o branco, com uma repetição) é o FIM da roda,
    // e não o começo de novo: numa rampa, o branco tem que ficar branco.
    if (t == 0.0 && voltas > 0.0) t = 1.0;
    float4 nova = naRoda(t);

    // ------------------------------------------------ o que a cor nova troca
    float3 cor = original.rgb;
    if (u.modify == 1) {
        cor = nova.rgb;
    } else if (u.modify == 2) {
        cor.r = nova.r;
    } else if (u.modify == 3) {
        cor.g = nova.g;
    } else if (u.modify == 4) {
        cor.b = nova.b;
    } else if (u.modify >= 5 && u.modify <= 7) {
        float3 a = paraHsl(original.rgb);
        float3 b = paraHsl(nova.rgb);
        if (u.modify == 5) a.x = b.x;
        if (u.modify == 6) a.z = b.z;
        if (u.modify == 7) a.y = b.y;
        cor = deHsl(a);
    } else if (u.modify == 8) {
        // Value: o maior canal vira o da cor nova, e a cor mantém a proporção.
        float v = max(original.r, max(original.g, original.b));
        float vNovo = max(nova.r, max(nova.g, nova.b));
        cor = v > 1e-5 ? original.rgb * (vNovo / v) : float3(vNovo);
    }

    float alfa = original.a;
    if (u.modifyAlpha) {
        alfa = u.changeEmpty ? nova.a : original.a * nova.a;
    }

    // ------------------------------------------------ em quais pixels
    float quanto = 1.0;
    if (u.matchMode > 0) {
        float d;
        if (u.matchMode == 1) {
            d = distance(original.rgb, u.matchColor.rgb) / sqrt(3.0);
        } else if (u.matchMode == 2) {
            float dh = abs(paraHsl(original.rgb).x - paraHsl(u.matchColor.rgb).x);
            d = min(dh, 1.0 - dh) * 2.0;
        } else {
            // Chroma: a cor sem a luz (os eixos de cor do YIQ), boa para foto:
            // a sombra de uma calça azul continua azul.
            float2 a = float2(dot(original.rgb, float3(0.596, -0.274, -0.322)), dot(original.rgb, float3(0.211, -0.523, 0.312)));
            float2 b = float2(dot(u.matchColor.rgb, float3(0.596, -0.274, -0.322)), dot(u.matchColor.rgb, float3(0.211, -0.523, 0.312)));
            d = clamp(distance(a, b) / 1.2, 0.0, 1.0);
        }
        quanto = 1.0 - smoothstep(u.matchTolerance, u.matchTolerance + u.matchSoftness + 0.0001, d);
    }
    if (u.maskMode > 0 && int2(int(maskLayer.get_width()), int(maskLayer.get_height())).x > 1) {
        float4 m = maskLayer.sample(__nv_smp, in.acScreenNorm);
        float v = u.maskMode <= 2 ? luma(m.rgb) * m.a : m.a;
        if (u.maskMode == 2 || u.maskMode == 4) v = 1.0 - v;
        quanto *= v;
    }

    // ------------------------------------------------ a saída
    // Composite Over Layer desligado: só os pixels modificados aparecem.
    if (u.compositeOver) {
        __nv_out = float4(mix(original.rgb, clamp(cor, 0.0, 1.0), quanto), mix(original.a, alfa, quanto));
    } else {
        __nv_out = float4(clamp(cor, 0.0, 1.0), alfa * quanto);
    }
    return __nv_out;
}
