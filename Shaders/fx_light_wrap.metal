// ---------------------------------------------------------------------------
// Envolver em luz (Light Wrap)
// origem : assets/effects/light-wrap.xml
// id     : nova.effect.lightwrap
// passes : 5
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct light_wrapParams {
    int view;
    int background;
    float bgBlur;
    float wrapWidth;
    float falloff;
    float intensity;
    float4 tint;
    float wrapSat;
    float lumBias;
    int applyMode;
    int linearWorkflow;
    float mixWithOriginal;
    int useMask;
    int useDirection;
    float lightAngle;
    float lightSpread;
};

// --- funcoes auxiliares do efeito
// Leituras de cada lado do centro. 12 + 1 + 12 = 25, espaçadas de um quarto de
// sigma: cobre 3 sigmas, que é onde a gaussiana acaba.
const int TAPS = 12;

// A altura de referência das medidas em pixel.
const float REFERENCIA = 1080.0;

const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

const float2 CANTOS[4] = float2[4](
    float2(-1.0, -1.0), float2(1.0, -1.0), float2(-1.0, 1.0), float2(1.0, 1.0)
);

/** sRGB para luz linear. Com o Linear Workflow desligado, não faz nada. */
static float3 aLinear(float3 c) {
    if (!u.linearWorkflow) return c;
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c));
}

/** Luz linear para sRGB. Com o Linear Workflow desligado, não faz nada. */
static float3 deLinear(float3 c) {
    if (!u.linearWorkflow) return c;
    c = max(c, float3(0.0));
    return mix(c * 12.92, 1.055 * pow(c, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), c));
}

/** Cor reta e codificada -> pré-multiplicada em luz (linear, se ligado). */
static float4 emLuz(float4 c) { return float4(aLinear(c.rgb) * c.a, c.a); }

/** Pré-multiplicada em luz -> cor RETA e codificada, que é o que os buffers guardam. */
static float4 empacotar(float4 pm) {
    float3 reto = pm.a > 0.0 ? pm.rgb / pm.a : float3(0.0);
    return float4(deLinear(reto), pm.a);
}

/** Sigma em fração da ALTURA, para uma largura em "pixels de 1080". Largura = 2 sigmas. */
static float sigmaDe(float px) { return px / REFERENCIA * 0.5; }

/**
 * O fundo na posição `uv` da camada, pré-multiplicado e em luz.
 *
 * Média de 4 leituras a +-1 pixel cheio (o alvo é 1/4): ao descer de resolução,
 * uma leitura só pularia pixels. `eng.acTela` leva a posição da camada para o lugar
 * dela na tela, que é onde o fundo está.
 */
static float4 fundoEm(float2 uv) {
    float2 d = eng.acTexelSize * 0.25;
    float4 soma = float4(0.0);
    for (int i = 0; i < 4; i++) {
        float2 t = __nv_acTela(uv + CANTOS[i] * d);
        float4 c = u.background == 0 ? backdropImg.sample(__nv_smp, t) : bgLayerImg.sample(__nv_smp, t);
        soma += emLuz(c);
    }
    return soma * 0.25;
}

/** O alfa do recorte em `uv`: o do conteúdo, vezes a cobertura da máscara. */
static float alfaEm(float2 uv) {
    float2 d = eng.acTexelSize * 0.25;
    float soma = 0.0;
    for (int i = 0; i < 4; i++) {
        float2 t = uv + CANTOS[i] * d;
        float a = inputImg.sample(__nv_smp, t).a;
        if (u.useMask) a *= maskImg.sample(__nv_smp, t).a;
        soma += a;
    }
    return soma * 0.25;
}

/**
 * Um passe do desfoque gaussiano separável.
 *
 * `passe` diz de onde ler: 0 = o fundo, 1 = o buffer do fundo, 2 = o alfa, 3 = o
 * buffer do alfa. O passo entre leituras é em fração da altura e vale um quarto de
 * sigma; na horizontal ele é dividido pela proporção, para ser o mesmo tamanho.
 * Devolve pré-multiplicado em luz; quem escreve no buffer chama `empacotar`.
 */
static float4 desfocar(int passe, float2 uv, float2 eixo, float sigma) {
    float passoAltura = 0.25 * sigma;
    float2 passo = float2(passoAltura / eng.acAspect, passoAltura) * eixo;

    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int i = -TAPS; i <= TAPS; i++) {
        float x = float(i) * 0.25;
        float w = exp(-0.5 * x * x);
        float2 p = uv + passo * float(i);

        float4 c;
        if (passe == 0) c = fundoEm(p);
        else if (passe == 1) c = emLuz(bgA.sample(__nv_smp, p));
        else if (passe == 2) c = float4(alfaEm(p));
        else c = aA.sample(__nv_smp, p);

        soma += c * w;
        pesos += w;
    }
    return soma / pesos;
}

/**
 * O peso da luz direcional neste pixel: 1 onde a borda olha para a luz, 0 onde
 * olha para o lado oposto. Sem `Directional`, 1 em todo lugar.
 *
 * A normal sai do gradiente do alfa borrado (por diferenças centrais de um texel
 * do buffer), virada para FORA. É levada para a tela por `eng.acTela` — dois pontos, o
 * pixel e um passo na direção da normal —, então a comparação com a luz é feita
 * no espaço em que a luz existe, e não no da camada.
 */
static float pesoDaDirecao(float2 uv) {
    if (!u.useDirection || u.lightSpread >= 359.0) return 1.0;

    float2 t = 1.0 / float2(int2(int(aB.get_width()), int(aB.get_height())));
    float gx = aB.sample(__nv_smp, uv + float2(t.x, 0.0)).r - aB.sample(__nv_smp, uv - float2(t.x, 0.0)).r;
    float gy = aB.sample(__nv_smp, uv + float2(0.0, t.y)).r - aB.sample(__nv_smp, uv - float2(0.0, t.y)).r;

    // O gradiente em pixels: du vale 1/largura e dv vale 1/altura. Com o alfa
    // decaindo para fora, a normal para fora é o gradiente com o sinal trocado.
    float2 g = float2(gx / (2.0 * t.x * eng.acAspect), gy / (2.0 * t.y));
    float2 nCamada = -g / max(length(g), 1e-6);

    float passo = 0.02;
    float2 duv = float2(nCamada.x / eng.acAspect, nCamada.y) * passo;
    float2 d = (__nv_acTela(uv + duv) - __nv_acTela(uv)) * float2(eng.acAspect, 1.0);
    float2 nTela = d / max(length(d), 1e-6);

    float angulo = radians(u.lightAngle);
    float2 aLuz = float2(cos(angulo), -sin(angulo));      // o y da tela cresce para baixo

    float metade = cos(radians(clamp(u.lightSpread, 1.0, 360.0)) * 0.5);
    return smoothstep(metade - 0.15, metade + 0.15, dot(nTela, aLuz));
}

/**
 * Enriquece (ou lava) a cor em volta do próprio brilho: `s=1` não mexe, acima
 * afasta os canais do cinza, abaixo aproxima. É o que tira o aspecto "lavado" da
 * luz — um contorno com a cor viva do fundo pertence à cena; um contorno cinza
 * parece um halo colado por cima.
 */
static float3 saturar(float3 c, float s) {
    return max(mix(float3(dot(c, LUMA)), c, s), 0.0);
}

/**
 * Ombro suave no lugar do corte reto em 1. Abaixo de 0,8 a luz passa igual;
 * acima, desliza para 1 sem nunca estourar. O corte reto (`clamp`) empilhava
 * tudo que passava de 1 no branco e achatava a cor do realce — o defeito que
 * fazia a luz forte virar uma mancha leitosa. Aqui o topo rola de mansinho e a
 * cor sobrevive.
 */
static float3 ombro(float3 c) {
    const float joelho = 0.8;
    float folga = 1.0 - joelho;                 // 0.2
    float3 alto = joelho + folga * (1.0 - exp(-(max(c, joelho) - joelho) / folga));
    return mix(c, alto, step(float3(joelho), c));
}

fragment float4 fx_light_wrap(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant light_wrapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> backdropImg [[texture(1)]],
    texture2d<float> bgLayerImg [[texture(2)]],
    texture2d<float> maskImg [[texture(3)]],
    texture2d<float> bgA [[texture(4)]],
    texture2d<float> bgB [[texture(5)]],
    texture2d<float> aA [[texture(6)]],
    texture2d<float> aB [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;

    if (eng.acPass == 0) { __nv_out = empacotar(desfocar(0, uv, float2(1.0, 0.0), sigmaDe(u.bgBlur))); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = empacotar(desfocar(1, uv, float2(0.0, 1.0), sigmaDe(u.bgBlur))); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = desfocar(2, uv, float2(1.0, 0.0), sigmaDe(u.wrapWidth)); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = desfocar(3, uv, float2(0.0, 1.0), sigmaDe(u.wrapWidth)); return __nv_out; }

    // ---- Passe final, em resolução cheia ----
    float4 fg = inputImg.sample(__nv_smp, uv);
    float cobertura = u.useMask ? maskImg.sample(__nv_smp, uv).a : 1.0;
    float alfa = fg.a * cobertura;

    // A faixa por dentro da borda. O ganho de 2 traz o pico de 0,5 para 1: ver o
    // cabeçalho.
    float alfaBorrado = aB.sample(__nv_smp, uv).r;
    float borda = alfa * clamp((1.0 - alfaBorrado) * 2.0, 0.0, 1.0);
    float faixa = pow(borda, max(u.falloff, 0.05)) * pesoDaDirecao(uv);

    // A luz: o fundo borrado, já em luz e multiplicado pelo próprio alfa (o que é
    // transparente não acende nada), tingido e com o viés de luminância. O viés
    // olha a claridade PERCEBIDA, que é a codificada — 0,5 é 0,5 nos dois modos.
    float4 fundo = bgB.sample(__nv_smp, uv);
    float3 luz = aLinear(fundo.rgb) * fundo.a;
    float claridade = dot(deLinear(luz), LUMA);
    luz = mix(luz, aLinear(u.tint.rgb) * dot(luz, LUMA), u.tint.a);

    float claro = smoothstep(0.15, 0.85, claridade);
    float peso = u.lumBias >= 0.0 ? mix(1.0, claro, u.lumBias) : mix(1.0, 1.0 - claro, -u.lumBias);
    // Enriquece a cor e rola o topo de mansinho, em vez de cortar reto em 1.
    luz = ombro(saturar(luz * peso * u.intensity, u.wrapSat));

    if (u.view == 1) { __nv_out = float4(deLinear(luz), faixa); return __nv_out; }
    if (u.view == 2) { __nv_out = float4(deLinear(luz * faixa), 1.0); return __nv_out; }

    // O modo: como a luz entra por cima do recorte.
    float3 base = aLinear(fg.rgb);
    float3 misturado;
    if (u.applyMode == 0) {
        misturado = 1.0 - (1.0 - base) * (1.0 - luz);                 // Screen
    } else if (u.applyMode == 1) {
        misturado = min(base + luz, float3(1.0));                       // Add
    } else if (u.applyMode == 2) {
        misturado = luz;                                              // Normal
    } else if (u.applyMode == 3) {
        misturado = max(base, luz);                                   // Lighten
    } else if (u.applyMode == 4) {
        misturado = (1.0 - 2.0 * luz) * base * base + 2.0 * luz * base; // Soft Light
    } else {
        misturado = mix(                                              // Overlay
            2.0 * base * luz,
            1.0 - 2.0 * (1.0 - base) * (1.0 - luz),
            step(0.5, base)
        );
    }

    float4 resultado = float4(deLinear(mix(base, misturado, faixa)), fg.a);
    __nv_out = mix(resultado, fg, u.mixWithOriginal);
    return __nv_out;
}
