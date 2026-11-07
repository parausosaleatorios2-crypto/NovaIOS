// ---------------------------------------------------------------------------
// Flare Volumétrico
// origem : assets/effects/god-rays.xml
// id     : nova.effect.godrays
// passes : 9
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct god_raysParams {
    float2 lightPos;
    float lightIntensity;
    float4 lightColor;
    float lightRadius;
    float density;
    float rayLength;
    float threshold;
    float glowAmount;
    float glowRadius;
    float noiseAmount;
    float noiseSpeed;
    int occluder;
    int quality;
    int view;
    float lightFalloff;
    float temperature;
    float saturation;
    int sourceMode;
    float rayIntensity;
    float decay;
    int attenuation;
    float softness;
    float scattering;
    float anisotropy;
    float noiseScale;
    float noiseContrast;
    float noiseSeed;
    float glowThreshold;
    float glowFalloff;
    float occlusionStrength;
    float occlusionSoftness;
    int light2On;
    float2 light2Pos;
    float light2Intensity;
    float4 light2Color;
    float light2Radius;
};

// --- funcoes auxiliares do efeito
const int MAX_AMOSTRAS = 128;
const float HDR_MAX = 40.0;

const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

// ---------------------------------------------------------------- cor e luz

static float3 aLinear(float3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c));
}

static float3 deLinear(float3 c) {
    c = max(c, float3(0.0));
    return mix(c * 12.92, 1.055 * pow(c, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), c));
}

/**
 * Luz linear em qualquer valor (até ~40) para o que cabe num buffer de 8 bits.
 * `x/(1+x)` comprime a faixa inteira em 0..1; o gama por cima dá mais degraus
 * para os valores baixos, onde a cauda escura de um halo mora.
 */
static float3 empacotar(float3 x) {
    x = clamp(x, float3(0.0), float3(HDR_MAX));
    return pow(x / (1.0 + x), float3(1.0 / 2.2));
}

static float3 desempacotar(float3 e) {
    float3 y = pow(e, float3(2.2));
    return y / max(float3(1.0) - y, float3(0.002));
}

/** A cor da luz: a cor escolhida, esquentada ou esfriada, e com a saturação. */
static float3 corDaLuz(float4 c) {
    float3 rgb = aLinear(c.rgb);
    rgb *= float3(1.0 + 0.30 * u.temperature, 1.0 + 0.04 * u.temperature, 1.0 - 0.38 * u.temperature);
    float claridade = dot(rgb, LUMA);
    return max(mix(float3(claridade), rgb, u.saturation), float3(0.0));
}

// ---------------------------------------------------------------- ruído

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float ruidoDeValor(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

/** Três oitavas: nuvem grande com detalhe miúdo. Volta em 0..1. */
static float fbm(float2 p) {
    float soma = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 3; i++) {
        soma += amp * ruidoDeValor(p);
        p = p * 2.03 + 17.7;
        amp *= 0.5;
    }
    return soma / 0.875;
}

/** Ruído de gradiente entrelaçado: o jitter dos passos. Fixo no espaço, não pisca. */
static float jitterDoPixel(float2 p) {
    return fract(52.9829189 * fract(dot(p, float2(0.06711056, 0.00583715))));
}

// ---------------------------------------------------------------- a marcha

static int amostras() {
    int n = u.quality == 0 ? 16 : (u.quality == 1 ? 32 : (u.quality == 2 ? 64 : 128));
    // na prévia em movimento (`eng.acRascunho`, play/arraste), no máximo a qualidade Média
    return eng.acRascunho == 1 ? min(n, 32) : n;
}

/** O peso do caminho: t = 0 no pixel, t = 1 no fim do raio. Vale 1 no pixel. */
static float atenuar(float t) {
    if (u.attenuation == 0) return max(1.0 - t * u.decay * 0.5, 0.0);                        // Linear
    if (u.attenuation == 1) return 1.0 - smoothstep(0.0, 1.0, min(t * u.decay * 0.5, 1.0));  // Smooth
    if (u.attenuation == 2) return exp(-t * u.decay);                                        // Exponential
    return 1.0 / (1.0 + t * u.decay * 2.0);                                                // Inverse
}

/** O disco da fonte: cheio no centro, zero na borda do raio. Não depende da imagem. */
static float disco(float2 p, float2 luz, float raio) {
    float d = length((p - luz) * float2(eng.acAspect, 1.0)) / max(raio, 0.002);
    return pow(clamp(1.0 - d, 0.0, 1.0), max(u.lightFalloff, 0.1));
}

/** De 0 (passa tudo) a 1 (bloqueia). A maciez abre a rampa entre os dois. */
static float oclusao(float o) {
    float s = clamp(u.occlusionSoftness, 0.0, 1.0);
    return smoothstep(0.5 - 0.5 * s, 0.5 + 0.5 * s + 0.001, o);
}

/**
 * A fase de espalhamento de Henyey-Greenstein, normalizada para valer 1 na
 * direção da fonte. O ângulo é o entre a direção de visão do pixel e a da fonte,
 * numa câmera de 45° de meio campo — assim a fonte pode estar fora da tela.
 */
static float fase(float2 uv, float2 luz) {
    float2 esc = float2(eng.acAspect, 1.0);
    float3 vp = normalize(float3((uv - 0.5) * esc, 1.0));
    float3 vl = normalize(float3((luz - 0.5) * esc, 1.0));
    float cosT = dot(vp, vl);
    float g = clamp(u.anisotropy, -0.95, 0.95);
    float hg = (1.0 - g * g) / pow(1.0 + g * g - 2.0 * g * cosT, 1.5);
    float hg1 = (1.0 - g * g) / pow(1.0 + g * g - 2.0 * g, 1.5);
    return mix(1.0, clamp(hg / hg1, 0.0, 4.0), clamp(u.scattering, 0.0, 1.0));
}

/**
 * A luz que chega a `uv` vinda de `luz`, em luz linear, SEM a cor.
 *
 * `textureLod` e não `texture`: dentro de laço com saída antecipada as derivadas
 * que escolhem o mipmap não são definidas. Os buffers não têm mipmap.
 */
static float3 marchar(float2 uv, float2 luz, float intLuz, float raioLuz, float jitter, int n) {
    float2 raio = (luz - uv) * u.rayLength;
    // A oclusão é uma profundidade óptica: a luz que passa por uma espessura de
    // objeto cai como exp(-espessura * k). Cada passo cobre 1/n do caminho, então
    // o k por passo é dividido por n — o mesmo pilar bloqueia o mesmo tanto com 16
    // passos e com 128. (A forma antiga, `1 - força * 32/n` por passo, deixava
    // passar 15% com 16 passos e 0,3% com 32: dependia de quantos passos caíam no
    // objeto, e não da espessura dele.) Força 1 = 48: um objeto que cobre 10% do
    // caminho deixa passar ~1%.
    float bloqueioPorPasso = u.occlusionStrength * 48.0 / float(n);

    float3 soma = float3(0.0);
    float transmitancia = 1.0;

    for (int i = 0; i < MAX_AMOSTRAS; i++) {
        if (i >= n) break;

        float t = (float(i) + jitter) / float(n);
        float2 p = uv + raio * t;

        float3 emissao = float3(0.0);
        float bloqueio = 0.0;

        // Fora da tela não há imagem: só a fonte, que é fórmula. É isso que deixa a
        // luz ficar além da borda e os raios entrarem no quadro.
        if (p.x >= 0.0 && p.x <= 1.0 && p.y >= 0.0 && p.y <= 1.0) {
            float4 e = emis.sample(__nv_smp, p, level(0.0));
            if (u.sourceMode != 2) emissao = e.rgb;
            bloqueio = e.a;
        }
        if (u.sourceMode != 1) emissao += float3(disco(p, luz, raioLuz) * intLuz);

        // A poeira: sutil por padrão, e ancorada no espaço (não na direção do raio),
        // que é o que desenha as tiras de partículas ao longo dos feixes.
        float poeira = mix(1.0 - u.noiseAmount, 1.0,
                           noiseT.sample(__nv_smp, clamp(p, 0.0, 1.0), level(0.0)).r);

        soma += emissao * (atenuar(t) * transmitancia * poeira);

        // O que está aqui bloqueia a luz de tudo que vem DEPOIS (mais perto da fonte).
        if (u.occluder != 0) {
            transmitancia *= exp(-oclusao(bloqueio) * bloqueioPorPasso);
        }
    }

    return soma / float(n) * fase(uv, luz);
}

/** Os raios em `uv`: as duas luzes, cada uma com a sua cor. */
static float3 raiosEm(float2 uv) {
    int n = amostras();
    float jitter = jitterDoPixel(__nv_fragCoord.xy);

    float3 total = marchar(uv, u.lightPos, u.lightIntensity, u.lightRadius, jitter, n) * corDaLuz(u.lightColor);
    if (u.light2On) {
        total += marchar(uv, u.light2Pos, u.light2Intensity, u.light2Radius, jitter, n) * corDaLuz(u.light2Color);
    }
    return total * (u.rayIntensity * u.density);
}

// ---------------------------------------------------------------- o brilho em várias escalas

/**
 * O primeiro nível do brilho: para cada pixel do buffer de 1/4, a média de um
 * bloco de 4x4 pixels da imagem cheia, com o LIMIAR aplicado em cada um deles.
 *
 * O limiar vem ANTES da média, e é o que importa: uma faísca de 2x2 pixels lida
 * por filtro bilinear já chega com metade do brilho, cai abaixo do limiar e some.
 * Aplicando por pixel e tirando a média depois, ela vira uma mancha fraca — a luz
 * que tinha continua tendo. `texelFetch` para o filtro do hardware não misturar
 * os vizinhos antes.
 *
 * O bloco começa em `4 * índice do pixel`, e não em "onde o UV cai": os buffers
 * têm o tamanho arredondado para baixo, e o UV daria um bloco deslocado — pixels
 * contados duas vezes e outros nunca. Pelo índice, cada pixel da imagem cheia
 * pertence a exatamente um bloco.
 */
static float3 primeiroNivel() {
    int2 tam = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 base = int2(__nv_fragCoord.xy) * 4;
    float3 soma = float3(0.0);
    for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
            float4 c = inputImg.read(uint2(clamp(base + int2(x, y), int2(0), tam - int2(1))), uint(0));
            float l = dot(c.rgb, LUMA);
            float m = smoothstep(u.glowThreshold, u.glowThreshold + 0.25, l);
            soma += aLinear(c.rgb) * (m * c.a);
        }
    }
    return soma / 16.0;
}

/** Um texel de um nível do brilho, já em luz linear. `nivel` diz de qual buffer ler. */
static float3 texelDoNivel(int nivel, int2 i, int2 tam) {
    i = clamp(i, int2(0), tam - int2(1));
    float3 e;
    if (nivel == 2) e = g1.read(uint2(i), uint(0)).rgb;
    else if (nivel == 3) e = g2.read(uint2(i), uint(0)).rgb;
    else e = g3.read(uint2(i), uint(0)).rgb;
    return desempacotar(e);
}

/**
 * Tenda 3x3 sobre o nível anterior (o dobro da resolução): cada nível dobra o
 * alcance do anterior.
 *
 * ## Por que texelFetch, e por que o índice
 *
 * Duas coisas fazem uma fonte pequena perder energia ao descer a pirâmide, e uma
 * simulação em numpy mediu as duas (um ponto perdia 83% de uma vez):
 *
 * 1. **O filtro bilinear do hardware médio de valores CODIFICADOS.** O buffer guarda
 *    a luz comprimida (`x^0,45`), e a média de `{e, 0}` nesse espaço decodifica para
 *    ~21% da energia, não 50%. Aqui cada texel é lido sozinho, decodificado, e só
 *    então entra na média — em luz linear, que é onde média conserva energia.
 * 2. **O UV põe a leitura fora do canto.** Os buffers têm o tamanho arredondado para
 *    baixo (67 linhas viram 33), e a posição por UV deixa de cair entre quatro
 *    texels. Pelo ÍNDICE do pixel (`2j`, o começo do bloco 2x2 dele), cada texel de
 *    origem pertence a exatamente um bloco, qualquer que seja o arredondamento.
 *
 * As nove médias de 2x2 ficam a dois texels uma da outra, e emendam sem buraco e
 * sem sobra: a energia passa inteira de um nível ao seguinte. O raio do brilho, por
 * isso, não mora aqui: ele desloca o PESO entre as escalas, na composição.
 */
static float3 proximoNivel(int nivel) {
    int2 tam = nivel == 2 ? int2(int(g1.get_width()), int(g1.get_height())) : (nivel == 3 ? int2(int(g2.get_width()), int(g2.get_height())) : int2(int(g3.get_width()), int(g3.get_height())));
    int2 centro = int2(__nv_fragCoord.xy) * 2;

    float3 soma = float3(0.0);
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float w = (x == 0 ? 2.0 : 1.0) * (y == 0 ? 2.0 : 1.0);
            int2 o = centro + int2(x, y) * 2;
            float3 bloco = texelDoNivel(nivel, o, tam)
                       + texelDoNivel(nivel, o + int2(1, 0), tam)
                       + texelDoNivel(nivel, o + int2(0, 1), tam)
                       + texelDoNivel(nivel, o + int2(1, 1), tam);
            soma += bloco * (0.25 * w);
        }
    }
    return soma / 16.0;
}

/** O halo da própria fonte, por fórmula: entra na tela mesmo com a fonte fora dela. */
static float3 haloDe(float2 uv, float2 luz, float inten, float raio, float3 cor) {
    float d = length((uv - luz) * float2(eng.acAspect, 1.0));
    float r = max(raio, 0.01);
    float h = 0.9 * exp(-pow(d / (r * 1.5), 2.0))
            + 0.35 * exp(-pow(d / (r * 5.0), 2.0))
            + 0.12 * exp(-pow(d / (r * 16.0), 2.0));
    return cor * (h * inten * 0.5);
}

fragment float4 fx_god_rays(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant god_raysParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> noiseT [[texture(1)]],
    texture2d<float> emis [[texture(2)]],
    texture2d<float> rayH [[texture(3)]],
    texture2d<float> rayQ [[texture(4)]],
    texture2d<float> g1 [[texture(5)]],
    texture2d<float> g2 [[texture(6)]],
    texture2d<float> g3 [[texture(7)]],
    texture2d<float> g4 [[texture(8)]],
    texture2d<float> occLayerImg [[texture(9)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;

    // ---- 0: o mapa de poeira ----
    if (eng.acPass == 0) {
        float2 p = float2(uv.x * eng.acAspect, uv.y) * u.noiseScale
               + float2(u.noiseSeed * 7.31, u.noiseSeed * 3.17)
               + float2(0.9, 0.35) * (eng.acTime * u.noiseSpeed);
        float n = fbm(p);
        n = clamp((n - 0.5) * u.noiseContrast + 0.5, 0.0, 1.0);
        __nv_out = float4(float3(n), 1.0);
        return __nv_out;
    }

    // ---- 1: a extração — o brilho que vira raio, e a oclusão ----
    // Bloco de 2x2 pixels da imagem cheia, com o limiar aplicado em CADA um antes da
    // média (ver `primeiroNivel`: um ponto brilhante pequeno não pode sumir no filtro).
    if (eng.acPass == 1) {
        int2 tam = int2(int(inputImg.get_width()), int(inputImg.get_height()));
        int2 base = int2(__nv_fragCoord.xy) * 2;      // o bloco pelo ÍNDICE do pixel: ver `primeiroNivel`
        float3 emissao = float3(0.0);
        float escuro = 0.0;
        for (int y = 0; y < 2; y++) {
            for (int x = 0; x < 2; x++) {
                float4 c = inputImg.read(uint2(clamp(base + int2(x, y), int2(0), tam - int2(1))), uint(0));
                float lumaE = dot(c.rgb, LUMA);
                float mascara = smoothstep(u.threshold, u.threshold + max(u.softness, 0.001), lumaE);
                emissao += aLinear(c.rgb) * (mascara * c.a);
                escuro += c.a * (1.0 - smoothstep(0.0, max(u.threshold, 0.05), lumaE));
            }
        }
        emissao *= 0.25;

        float bloqueio = 0.0;
        if (u.occluder == 1) {
            bloqueio = escuro * 0.25;
        } else if (u.occluder == 2) {
            bloqueio = occLayerImg.sample(__nv_smp, uv).a;
        }
        // Linear, SEM `empacotar`: a emissão da imagem nunca passa de 1, e guardada em
        // luz linear o filtro bilinear da marcha faz a média certa entre dois texels.
        // Codificada, a média de {e, 0} decodifica para ~21% da energia, não 50%: um
        // ponto brilhante pequeno perderia quase toda a luz conforme os raios andam.
        __nv_out = float4(emissao, bloqueio);
        return __nv_out;
    }

    // ---- 2 e 3: os raios, em 1/2 (Balanced, Quality, Ultra) ou em 1/4 (Performance) ----
    if (eng.acPass == 2) {
        if (u.quality == 0) { __nv_out = float4(0.0); return __nv_out; }
        __nv_out = float4(empacotar(raiosEm(uv)), 1.0);
        return __nv_out;
    }
    if (eng.acPass == 3) {
        if (u.quality != 0) { __nv_out = float4(0.0); return __nv_out; }
        __nv_out = float4(empacotar(raiosEm(uv)), 1.0);
        return __nv_out;
    }

    // ---- 4 a 7: o brilho, quatro escalas ----
    if (eng.acPass == 4) { __nv_out = float4(empacotar(primeiroNivel()), 1.0); return __nv_out; }
    if (eng.acPass == 5) { __nv_out = float4(empacotar(proximoNivel(2)), 1.0); return __nv_out; }
    if (eng.acPass == 6) { __nv_out = float4(empacotar(proximoNivel(3)), 1.0); return __nv_out; }
    if (eng.acPass == 7) { __nv_out = float4(empacotar(proximoNivel(4)), 1.0); return __nv_out; }

    // ---- 8: a composição, em resolução cheia ----
    float4 base = inputImg.sample(__nv_smp, uv);

    float3 raios;
    if (u.quality == 0) raios = desempacotar(rayQ.sample(__nv_smp, uv).rgb);
    else raios = desempacotar(rayH.sample(__nv_smp, uv).rgb);

    // As quatro escalas: pequeno e intenso até grande e atmosférico. O falloff
    // decide o quanto cada uma pesa; 0,5 dá 1, 0,55, 0,30, 0,17 — a proporção da spec.
    // O RAIO multiplica o peso da escala k por raio^k, e depois os pesos são
    // renormalizados para somar o mesmo que antes: raio maior tira energia das
    // escalas pequenas e a põe nas grandes, sem mudar o brilho total do halo.
    float k = u.glowFalloff * 1.2;
    float r = u.glowRadius;
    float w1 = 1.0;
    float w2 = exp(-k) * r;
    float w3 = exp(-2.0 * k) * r * r;
    float w4 = exp(-3.0 * k) * r * r * r;
    float somaOriginal = 1.0 + exp(-k) + exp(-2.0 * k) + exp(-3.0 * k);
    float normal = somaOriginal / (w1 + w2 + w3 + w4);
    float3 brilho = desempacotar(g1.sample(__nv_smp, uv).rgb) * (w1 * normal)
                + desempacotar(g2.sample(__nv_smp, uv).rgb) * (w2 * normal)
                + desempacotar(g3.sample(__nv_smp, uv).rgb) * (w3 * normal)
                + desempacotar(g4.sample(__nv_smp, uv).rgb) * (w4 * normal);
    brilho *= u.glowAmount;

    // O halo das fontes, por fórmula (a fonte pode estar fora da tela).
    if (u.sourceMode != 1) {
        brilho += haloDe(uv, u.lightPos, u.lightIntensity, u.lightRadius, corDaLuz(u.lightColor)) * u.glowAmount;
        if (u.light2On) {
            brilho += haloDe(uv, u.light2Pos, u.light2Intensity, u.light2Radius, corDaLuz(u.light2Color)) * u.glowAmount;
        }
    }

    if (u.view == 1) { __nv_out = float4(deLinear(1.0 - exp(-raios)), 1.0); return __nv_out; }
    if (u.view == 2) { __nv_out = float4(deLinear(1.0 - exp(-brilho)), 1.0); return __nv_out; }

    // A luz é somada à imagem gastando só o espaço que falta até o branco:
    // 1 - (1 - imagem) * exp(-luz). Em pré-multiplicado, para a luz aparecer
    // também fora do conteúdo (num texto, num recorte, num fundo transparente).
    float3 luz = raios + brilho;
    float3 pm = aLinear(base.rgb) * base.a;
    float3 acende = 1.0 - exp(-luz);
    float3 pmSaida = pm + acende - pm * acende;
    float acendeAlfa = max(max(acende.r, acende.g), acende.b);
    float alfa = base.a + acendeAlfa * (1.0 - base.a);
    float3 reto = alfa > 0.0 ? pmSaida / alfa : float3(0.0);

    __nv_out = float4(deLinear(reto), alfa);
    return __nv_out;
}
