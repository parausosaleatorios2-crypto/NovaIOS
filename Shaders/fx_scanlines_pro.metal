// ---------------------------------------------------------------------------
// Scanlines Pro
// origem : assets/effects/scanlines-pro.xml
// id     : nova.effect.scanlinespro
// passes : 5
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct scanlines_proParams {
    int patternMode;
    float intensity;
    float lineCount;
    float thickness;
    float spacing;
    float softness;
    float angle;
    float speed;
    float glow;
    float noiseAmt;
    float rgbShift;
    float vignette;
    float mixAmt;
    int beamModel;
    int lineStyle;
    float phase;
    float beamSharpness;
    float beamExpansion;
    float beamSpot;
    float gapBrightness;
    float4 lineColor;
    float lineBrightness;
    float keepBrightness;
    float shiftR;
    float shiftG;
    float shiftB;
    float rollAmount;
    float rollSpeed;
    float imageOffset;
    float lineNoise;
    float noiseScale;
    float noiseSpeed;
    int noiseType;
    int noiseMono;
    float blockSize;
    float flicker;
    float bandAmount;
    float bandWidth;
    float bandSpeed;
    float bandSoftness;
    int interlace;
    float interlaceRate;
    float interlaceAmount;
    float persistence;
    int persistenceMode;
    float waveAmount;
    float waveScale;
    float waveSpeed;
    float lineDistort;
    float jitter;
    float tearAmount;
    float tearFrequency;
    float tearSpeed;
    int maskType;
    float maskStrength;
    float maskSize;
    float customMaskSize;
    float convergence;
    int subpixelFilter;
    float curvatureX;
    float colorBleed;
    float sourceBlur;
    float frameAmount;
    float frameRoundness;
    int curvatureModel;
    int screenAspect;
    float overscan;
    float tiltX;
    float tiltY;
    float reflectionAmount;
    float reflectionScale;
    int reflectionMirror;
    float glassSheen;
    int glowMode;
    float glowRadius;
    float glowThreshold;
    float4 glowColor;
    int glowSpill;
    float vignetteRoundness;
    float vignetteSize;
    float vignetteSoftness;
    float4 vignetteColor;
    float brightness;
    float contrast;
    float gammaValue;
    float saturationAmt;
    float4 tintColor;
    float tintAmount;
    int maskSource;
    int maskInvert;
    float maskFeather;
    float gradientAngle;
    float gradientPosition;
    float audioAmount;
    int audioTarget;
    float audioSensitivity;
    int quality;
    int view;
};

// --- funcoes auxiliares do efeito
// ============================================================================
//  FERRAMENTAS
// ============================================================================

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

// Hash sem seno: estável nas GPUs de celular, onde `sin` de número grande
// perde precisão e o ruído vira faixas. Técnica pública conhecida.
float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

/** Ruído de valor, contínuo, de 0 a 1. */
float ruidoSuave(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float luma(float3 c) { return dot(c, LUMA); }

/** A imagem, pré-multiplicada: a cor dos transparentes nunca vaza. */
float4 amostraP(float2 uv) {
    float4 c = inputImg.sample(__nv_smp, clamp(uv, 0.0, 1.0));
    return float4(c.rgb * c.a, c.a);
}

float3 semPreMultiplicar(float4 c) {
    return c.a > 0.0001 ? clamp(c.rgb / c.a, 0.0, 4.0) : float3(0.0);
}

// ============================================================================
//  A MÚSICA (item 51)
// ============================================================================

/**
 * O grave do instante, de 0 a 1.
 *
 * As três primeiras faixas do espectro (por oitava, a partir de 40 Hz) são o
 * bumbo e o baixo — é o que marca a batida num edit. O motor já dá ataque
 * imediato e queda suave; aqui é só média e sensibilidade.
 */
float nivelDoSom() {
    float s = somImg.sample(__nv_smp, float2(0.04, 0.5)).r
            + somImg.sample(__nv_smp, float2(0.10, 0.5)).r
            + somImg.sample(__nv_smp, float2(0.17, 0.5)).r;
    return clamp(s / 3.0 * u.audioSensitivity, 0.0, 1.0);
}

/** Quanto a música empurra o alvo `alvo` agora. 5 = "Everything". */
float reage(int alvo) {
    if (u.audioAmount <= 0.0) return 0.0;
    if (u.audioTarget != alvo && u.audioTarget != 5) return 0.0;
    return nivelDoSom() * u.audioAmount;
}

// ============================================================================
//  A GEOMETRIA DA TELA
// ============================================================================

bool foraDaTela(float2 uv) {
    return uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0;
}

/** A proporção do tubo: a da camada, ou uma das clássicas. */
float proporcaoDaTela() {
    if (u.screenAspect == 1) return 4.0 / 3.0;
    if (u.screenAspect == 2) return 16.0 / 9.0;
    if (u.screenAspect == 3) return 1.0;
    if (u.screenAspect == 4) return 21.0 / 9.0;
    return eng.acAspect;
}

/** O tamanho da tela dentro da camada (0..1 em cada eixo), centrada. */
float2 tamanhoDaTela() {
    float a = proporcaoDaTela();
    return a < eng.acAspect ? float2(a / max(eng.acAspect, 0.0001), 1.0) : float2(1.0, eng.acAspect / max(a, 0.0001));
}

float3x3 girar(float ax, float ay) {
    float cx = cos(ax);
    float sx = sin(ax);
    float cy = cos(ay);
    float sy = sin(ay);
    float3x3 rx = float3x3(1.0, 0.0, 0.0, 0.0, cx, sx, 0.0, -sx, cx);
    float3x3 ry = float3x3(cy, 0.0, -sy, 0.0, 1.0, 0.0, sy, 0.0, cy);
    return ry * rx;
}

/**
 * ============================================================================
 *  A GEOMETRIA DA TELA (itens 33, 34 e o "3D screen curvature" do item 89)
 * ============================================================================
 *
 * Recebe a UV da camada e devolve, em `xy`, de onde ler a IMAGEM, e em `zw`,
 * o ponto na superfície da TELA (0..1; fora disso é a caixa da TV).
 *
 * Três modelos:
 *
 *  - **Barrel**: a conta barata de sempre — a coordenada é empurrada para fora
 *    quanto mais longe do centro no outro eixo;
 *  - **Spherical 3D / Cylindrical 3D**: um raio sai do olho, atravessa o pixel
 *    e bate na superfície do tubo (uma esfera ou um cilindro vertical, com a
 *    inclinação aplicada), e a posição na tela é o comprimento de ARCO até o
 *    centro. É a curvatura de um vidro de verdade, que também é o que deixa
 *    inclinar o tubo sem a imagem "descolar" dele.
 *
 * A inclinação vale nos três: no Barrel, o raio bate primeiro num plano
 * inclinado e o estufamento vem depois.
 */
float4 geometria(float2 uvDaCamada) {
    float2 tamanho = tamanhoDaTela();
    float a = proporcaoDaTela();
    float2 q = ((uvDaCamada - 0.5) / tamanho) * 2.0;   // -1..1 dentro da tela

    bool temInclinacao = abs(u.tiltX) + abs(u.tiltY) > 0.001;
    bool modelo3D = u.curvatureModel > 0 && max(u.curvatureX, u.curvatureX) > 0.0;

    float2 s = q;
    if (temInclinacao || modelo3D) {
        float distancia = 2.4;
        float3 origem = float3(0.0);
        float3 direcao = normalize(float3(q.x * a, q.y, distancia));
        float3x3 inversa = girar(-radians(u.tiltY), -radians(u.tiltX));
        float3 pivo = float3(0.0, 0.0, distancia);
        float3 o = inversa * (origem - pivo);
        float3 d = inversa * direcao;

        if (modelo3D) {
            float c = (u.curvatureModel == 2 ? u.curvatureX : max(u.curvatureX, u.curvatureX)) * 0.9;
            float raio = max(a, 1.0) * 1.2 / max(c, 0.001);
            float3 centro = float3(0.0, 0.0, raio);
            float3 oc = o - centro;
            if (u.curvatureModel == 2) {
                // Cilindro de eixo vertical: só X e Z contam.
                float2 oc2 = oc.xz;
                float2 d2 = d.xz;
                float qa = dot(d2, d2);
                float qb = dot(oc2, d2);
                float qc = dot(oc2, oc2) - raio * raio;
                float disc = qb * qb - qa * qc;
                if (disc < 0.0) return float4(-1.0);
                float t = (-qb - sqrt(disc)) / max(qa, 1e-6);
                float3 h = o + t * d;
                s = float2(raio * asin(clamp(h.x / raio, -1.0, 1.0)) / a, h.y);
            } else {
                float qb = dot(oc, d);
                float qc = dot(oc, oc) - raio * raio;
                float disc = qb * qb - qc;
                if (disc < 0.0) return float4(-1.0);
                float t = -qb - sqrt(disc);
                float3 h = o + t * d;
                s = float2(raio * asin(clamp(h.x / raio, -1.0, 1.0)) / a,
                         raio * asin(clamp(h.y / raio, -1.0, 1.0)));
            }
        } else {
            // Plano inclinado.
            if (abs(d.z) < 1e-5) return float4(-1.0);
            float t = -o.z / d.z;
            if (t <= 0.0) return float4(-1.0);
            float3 h = o + t * d;
            s = float2(h.x / a, h.y);
        }
    }

    if (!modelo3D && (u.curvatureX > 0.0 || u.curvatureX > 0.0)) {
        float2 b = s;
        s.x = b.x * (1.0 + u.curvatureX * 0.3 * b.y * b.y);
        s.y = b.y * (1.0 + u.curvatureX * 0.3 * b.x * b.x);
    }

    float2 local = s * 0.5 + 0.5;                                   // na superfície da tela
    float2 naCamada = (local - 0.5) * tamanho + 0.5;                // de volta na camada
    float2 conteudo = (naCamada - 0.5) / (1.0 + u.overscan) + 0.5;    // a imagem, com u.overscan
    return float4(conteudo, local);
}

/** Da superfície da tela para a imagem — o mesmo caminho do fim de [geometria]. */
float2 conteudoDoLocal(float2 local) {
    float2 naCamada = (local - 0.5) * tamanhoDaTela() + 0.5;
    return (naCamada - 0.5) / (1.0 + u.overscan) + 0.5;
}

/**
 * A coordenada do padrão: a altura da camada vale 1, o X é corrigido pela
 * proporção (item 6) e o conjunto é girado. É nela que as linhas nascem — e,
 * como ela vem da UV JÁ curvada, as linhas acompanham o vidro (item 34).
 */
float2 coordDoPadrao(float2 uv) {
    float2 p = uv - 0.5;
    p.x *= proporcaoDaTela();
    float a = radians(u.angle);
    float s = sin(a);
    float c = cos(a);
    return float2(c * p.x + s * p.y, -s * p.x + c * p.y);
}

/** O caminho de volta, para amostrar o centro de uma célula no modo Squares. */
float2 uvDoPadrao(float2 p) {
    float a = radians(u.angle);
    float s = sin(a);
    float c = cos(a);
    float2 q = float2(c * p.x - s * p.y, s * p.x + c * p.y);
    q.x /= max(proporcaoDaTela(), 0.0001);
    return q + 0.5;
}

// ============================================================================
//  A LINHA
// ============================================================================

/**
 * O perfil de UMA linha (itens 9, 12 e 35).
 *
 * `y` é a coordenada em "linhas"; `meia` é meia espessura, em fração do período;
 * `fw` é quanto `y` anda por pixel — a frequência real do padrão na tela.
 *
 * Os três modelos: Hard Digital (degrau, só com o antisserrilhado), Soft
 * (transição suave) e Beam CRT (a linha é o perfil de um feixe de luz).
 *
 * Quando a linha fica menor que uns dois pixels, nenhum perfil sobrevive — vira
 * moiré e cintila em movimento. Nesse ponto o padrão é trocado pela MÉDIA dele
 * (a fração acesa do período), que é o que o olho veria de longe.
 */
float perfil(float y, float meia, float fw) {
    float d = abs(fract(y) - 0.5);
    float m;
    if (u.beamModel == 0) {
        m = 1.0 - smoothstep(meia - fw * 0.5, meia + fw * 0.5, d);
    } else if (u.beamModel == 1) {
        m = 1.0 - smoothstep(meia, meia + u.softness * 0.5 + fw, d);
    } else if (u.beamModel == 2) {
        float potencia = mix(1.6, 9.0, u.beamSharpness);
        m = exp(-pow(d / max(meia, 0.001), potencia));
        // O feixe também precisa do antisserrilhado na borda.
        m = mix(m, 1.0 - smoothstep(meia - fw, meia + fw, d), clamp(fw * 2.0, 0.0, 1.0) * 0.5);
    } else {
        // Gaussian Spot: gaussiana de verdade, com o desvio crescendo junto com a
        // meia espessura (que já cresce com o brilho — ver Beam Expansion). O
        // `u.beamSharpness` estreita o miolo sem mudar o alcance.
        float sigma = max(meia, 0.001) * mix(0.9, 0.55, u.beamSharpness);
        m = exp(-0.5 * (d * d) / (sigma * sigma));
        m = mix(m, 1.0 - smoothstep(meia - fw, meia + fw, d), clamp(fw * 2.0, 0.0, 1.0) * 0.5);
    }
    float cobertura = clamp(meia * 2.0, 0.0, 1.0);
    return mix(m, cobertura, smoothstep(0.3, 0.7, fw));
}

/** O perfil, supersampleado nos modos de qualidade alta (item 60). */
float perfilAA(float y, float meia, float dx, float dy, float fw) {
    if (u.quality < 2) return perfil(y, meia, fw);
    float soma = perfil(y + dx * 0.25 + dy * 0.25, meia, fw)
               + perfil(y - dx * 0.25 + dy * 0.25, meia, fw)
               + perfil(y + dx * 0.25 - dy * 0.25, meia, fw)
               + perfil(y - dx * 0.25 - dy * 0.25, meia, fw);
    if (u.quality == 3) {
        soma += perfil(y, meia, fw) * 2.0;
        return soma / 6.0;
    }
    return soma * 0.25;
}

/**
 * O ruído DA LINHA (itens 18 e 19): a linha falha em trechos, e não a imagem.
 * Ao longo de X, por fileira, trocando com o tempo.
 */
float ruidoDaLinha(float x, float fileira, float quadro) {
    if (u.noiseType == 1) {
        float bloco = floor(x * 40.0 / max(u.noiseScale, 0.1));
        return hash21(float2(bloco, fileira * 1.7 + quadro));
    }
    return ruidoSuave(float2(x * 12.0 * u.noiseScale, fileira * 1.7 + quadro * 0.37));
}

// ============================================================================
//  A MÁSCARA DE FÓSFORO (itens 26 a 28)
// ============================================================================

/**
 * A estrutura dos subpixels, em pixels da tela, com o brilho médio devolvido.
 *
 * Sem a compensação, uma máscara que acende um canal por vez tira dois terços
 * da luz, e a imagem inteira escurece — o "coloquei uma grade por cima". A
 * divisão pela média faz a máscara REDISTRIBUIR a luz, e não apagá-la.
 */
float3 fosforo(float2 px, int tipo, float forca) {
    if (tipo == 0 || forca <= 0.0) return float3(1.0);
    float lado = max(u.maskSize, 1.0);
    float apagado = 1.0 - forca;
    float3 m = float3(1.0);

    if (tipo == 1) {
        // Tiras RGB verticais, degrau.
        float f = fract(px.x / (lado * 3.0));
        m = f < 0.3333 ? float3(1.0, apagado, apagado)
          : f < 0.6667 ? float3(apagado, 1.0, apagado)
          : float3(apagado, apagado, 1.0);
    } else if (tipo == 2) {
        // Tríade: as fileiras andam meia tríade, como favo.
        float fileira = floor(px.y / (lado * 2.0));
        float f = fract((px.x + __nv_mod(fileira, 2.0) * lado * 1.5) / (lado * 3.0));
        m = f < 0.3333 ? float3(1.0, apagado, apagado)
          : f < 0.6667 ? float3(apagado, 1.0, apagado)
          : float3(apagado, apagado, 1.0);
    } else if (tipo == 3) {
        // Grade de abertura: as mesmas tiras, com cada uma acesa no meio e
        // apagando para as bordas (o fio da grade).
        float3 fase = float3(0.0, 1.0, 2.0);
        float3 onda = 0.5 + 0.5 * cos(TAU * (px.x / lado - fase) / 3.0);
        m = apagado + (1.0 - apagado) * onda * onda;
    } else if (tipo == 4) {
        // Pontos redondos, cada célula de um canal.
        float2 celula = floor(px / lado);
        float2 dentro = fract(px / lado) - 0.5;
        float ponto = 1.0 - smoothstep(0.3, 0.5, length(dentro));
        int canal = int(__nv_mod(celula.x + mod(celula.y, 2.0) * 1.0, 3.0));
        float3 cor = canal == 0 ? float3(1.0, 0.0, 0.0) : canal == 1 ? float3(0.0, 1.0, 0.0) : float3(0.0, 0.0, 1.0);
        m = mix(float3(apagado), float3(1.0), cor * ponto);
    } else if (tipo == 6) {
        // A máscara própria: a camada escolhida, em ladrilho de Custom Mask
        // Size pixels. O padrão é qualquer um, então a média (a compensação de
        // brilho) vem de nove pontos do ladrilho. Sem camada escolhida
        // (empty="transparent": chega 1×1 e transparente), sem máscara — em
        // vez de uma tela preta ou da própria camada em miniatura.
        float4 media9 = float4(0.0);
        for (int j = 0; j < 3; j++) {
            for (int i = 0; i < 3; i++) {
                float4 t9 = mascaraPropria.sample(__nv_smp, (float2(float(i), float(j)) + 0.5) / 3.0);
                media9 += float4(t9.rgb * t9.a, t9.a);
            }
        }
        media9 /= 9.0;
        if (media9.a < 0.004) return float3(1.0);
        float4 t = mascaraPropria.sample(__nv_smp, fract(px / max(u.customMaskSize, 1.0)));
        m = mix(float3(1.0), t.rgb * t.a, forca);
        float mediaPropria = mix(1.0, dot(media9.rgb, float3(1.0 / 3.0)), forca);
        return m * mix(1.0, 1.0 / max(mediaPropria, 0.05), 0.85);
    } else {
        // Máscara de sombra em tijolo: tiras curtas, fileiras deslocadas e um
        // vão escuro entre elas.
        float fileira = floor(px.y / (lado * 3.0));
        float x = px.x + __nv_mod(fileira, 2.0) * lado * 1.5;
        float f = fract(x / (lado * 3.0));
        m = f < 0.3333 ? float3(1.0, apagado, apagado)
          : f < 0.6667 ? float3(apagado, 1.0, apagado)
          : float3(apagado, apagado, 1.0);
        float vao = fract(px.y / (lado * 3.0));
        m *= mix(1.0, apagado, smoothstep(0.8, 0.95, vao));
    }

    float media = (m.r + m.g + m.b) / 3.0;
    return m * mix(1.0, 1.0 / max(media, 0.001), 0.85);
}

// ============================================================================
//  PASSE 0 — A TELA
// ============================================================================

/**
 * Cinco amostras em tenda, na horizontal, cobrindo uma tríade inteira
 * (`lado` é a largura de UMA tira, em px). Pesos 1-2-3-2-1.
 */
float4 tenda(float2 uv, float lado) {
    float2 h = float2(lado * 0.6 * eng.acTexelSize.x, 0.0);
    return (amostraP(uv) * 3.0
          + (amostraP(uv - h) + amostraP(uv + h)) * 2.0
          + (amostraP(uv - h * 2.0) + amostraP(uv + h * 2.0))) / 9.0;
}

float4 passeDaTela() {
    float2 uvOriginal = in.acScreenNorm;
    float4 geo = geometria(uvOriginal);
    float2 uv = geo.xy;
    float2 local = geo.zw;
    bool fora = foraDaTela(local);

    float tempo = eng.acTime;
    float quadroDoRuido = floor(tempo * 24.0 * u.noiseSpeed);

    // ------------------------------------------------ o SINAL (itens 39 a 42)
    float distorcao = reage(4);
    float onda = u.waveAmount + distorcao * 0.5;
    if (onda > 0.0) {
        uv.x += sin(uv.y * u.waveScale * TAU + tempo * u.waveSpeed * TAU) * onda * 0.012;
    }
    float fileiraDoSinal = floor(local.y * u.lineCount);
    if (u.jitter > 0.0 || distorcao > 0.0) {
        uv.x += (hash21(float2(fileiraDoSinal, floor(tempo * 30.0))) - 0.5) * (u.jitter + distorcao * 0.5) * 0.012;
    }
    if (u.tearAmount > 0.0) {
        float faixa = floor(uv.y * u.tearFrequency);
        float momento = floor(tempo * u.tearSpeed);
        if (hash21(float2(faixa, momento)) > 1.0 - u.tearAmount * 0.45) {
            uv.x += (hash11(faixa * 7.13 + momento) - 0.5) * u.tearAmount * 0.18;
        }
    }

    // ------------------------------------------------ o padrão, antes da fonte
    float espaco = 1.0 + u.spacing;
    float linhasPorAltura = u.lineCount / espaco;
    // As linhas moram na SUPERFÍCIE da tela, e não na imagem: com u.overscan a
    // imagem cresce e as linhas ficam; com o vidro curvo, elas curvam junto.
    // O sinal (onda, tremor, rasgo) desloca a imagem, não a tela.
    float2 p = coordDoPadrao(local);

    // No modo Squares a tela vira pixels visíveis: a cor vem do centro da célula.
    float2 uvDaFonte = uv;
    if (u.patternMode == 2) {
        float celula = 1.0 / linhasPorAltura;
        float2 centro = (floor(p / celula) + 0.5) * celula;
        uvDaFonte = conteudoDoLocal(uvDoPadrao(centro)) + (uv - geo.xy);
    }

    // ------------------------------------------------ a FONTE (itens 43 e 44)
    float rgbTotal = u.rgbShift + reage(3);
    float4 c;
    if (u.sourceBlur > 0.0) {
        float2 d = eng.acTexelSize * u.sourceBlur;
        c = amostraP(uvDaFonte) * 0.4
          + (amostraP(uvDaFonte + float2(d.x, 0.0)) + amostraP(uvDaFonte - float2(d.x, 0.0))
           + amostraP(uvDaFonte + float2(0.0, d.y)) + amostraP(uvDaFonte - float2(0.0, d.y))) * 0.15;
    } else {
        c = amostraP(uvDaFonte);
    }

    /*
     * O VERMELHO E O AZUL LIDOS FORA DO LUGAR, por dois motivos que se somam:
     *
     *  - Image Offset / RGB Shift: o desalinhamento de sinal, na horizontal;
     *  - Convergence: os três feixes do tubo erram mais nas bordas que no meio,
     *    então o erro cresce com a distância ao centro da tela.
     */
    float2 deslocamentoRB = float2((u.imageOffset + rgbTotal * 2.0) * eng.acTexelSize.x, 0.0);
    if (u.convergence > 0.0) {
        deslocamentoRB += (local - 0.5) * u.convergence * 0.012;
    }

    /*
     * SUBPIXEL FILTERING, com máscara de tiras (RGB Stripe, Aperture Grille, e
     * a do TV CRT). Sem ele, a imagem inteira aparece por baixo da máscara, com
     * todo o detalhe dela correndo dentro de cada tira. Com ele, cada tira de
     * fósforo acende INTEIRA, com a cor que a imagem tem em volta do centro da
     * própria tira: é a imagem redesenhada na resolução do tubo, três amostras
     * por tríade, e não uma grade posta por cima. Com Mask Size grande é o
     * visual do tubo visto de perto; o preço é o detalhe mais fino que uma
     * tríade, que o tubo de verdade também não mostra.
     *
     * "Em volta" é um filtro da largura da tríade, e não um ponto só: com um
     * ponto, um risco mais fino que a tríade acende o vermelho e o verde, erra
     * o azul, e vira uma fileira de pontinhos amarelos.
     */
    int tipoParaSubpixel = u.maskType != 0 ? u.maskType : (u.patternMode == 3 ? 3 : 0);
    bool porSubpixel = u.subpixelFilter && (tipoParaSubpixel == 1 || tipoParaSubpixel == 3)
        && u.maskStrength > 0.0 && u.maskSize >= 1.5;
    if (porSubpixel) {
        float lado = max(u.maskSize, 1.0);
        float centroDaTira = tipoParaSubpixel == 1 ? 0.5 : 0.0;
        float3 canal = float3(0.0, 1.0, 2.0) + centroDaTira;
        float3 n = floor((__nv_fragCoord.x / lado - canal) / 3.0 + 0.5);
        float3 dx = (lado * (3.0 * n + canal) - __nv_fragCoord.x) * eng.acTexelSize.x;
        float4 r = tenda(uvDaFonte + deslocamentoRB + float2(dx.r, 0.0), lado);
        float4 g = tenda(uvDaFonte + float2(dx.g, 0.0), lado);
        float4 b = tenda(uvDaFonte - deslocamentoRB + float2(dx.b, 0.0), lado);
        c = float4(r.r, g.g, b.b, max(g.a, max(r.a, b.a)));
    } else if (abs(deslocamentoRB.x) + abs(deslocamentoRB.y) > 0.0) {
        float4 vermelho = amostraP(uvDaFonte + deslocamentoRB);
        float4 azul = amostraP(uvDaFonte - deslocamentoRB);
        c = float4(vermelho.r, c.g, azul.b, max(c.a, max(vermelho.a, azul.a)));
    }

    // Gaussian Spot: o ponto claro se espalha na horizontal (o feixe é um ponto,
    // não uma linha fina), e só nas altas.
    if (u.beamModel == 3 && u.beamSpot > 0.0) {
        float2 h = float2(eng.acTexelSize.x * (1.0 + u.beamSpot * 3.0), 0.0);
        float4 espalhado = (amostraP(uvDaFonte - h) + amostraP(uvDaFonte + h)) * 0.5;
        float claro = smoothstep(0.25, 0.9, luma(semPreMultiplicar(c)));
        c = mix(c, espalhado, u.beamSpot * claro * 0.6);
    }

    /*
     * A PERSISTÊNCIA DO FÓSFORO (itens 37 e 38).
     *
     * Phosphor Trail: o fósforo que estava aceso demora a apagar. Cada canal
     * fica com o MAIOR entre o agora e os quadros anteriores já esmaecidos — e
     * por isso uma imagem parada não muda nada (o anterior é igual ao atual), e
     * só o que se mexe deixa rastro.
     *
     * Temporal Smooth: a média com os anteriores, presos à vizinhança do valor
     * atual. A prisão é o que rejeita o fantasma: um pixel que mudou de verdade
     * (um corte, um objeto passando) não carrega o passado junto.
     */
    if (u.persistence > 0.0) {
        float4 a1 = anterior1.sample(__nv_smp, clamp(uvDaFonte, 0.0, 1.0));
        float4 a2 = anterior2.sample(__nv_smp, clamp(uvDaFonte, 0.0, 1.0));
        float4 p1 = float4(a1.rgb * a1.a, a1.a);
        float4 p2 = float4(a2.rgb * a2.a, a2.a);
        // Sem o quadro (o primeiro depois de pular no tempo), o anel entrega
        // transparente: vale o atual, para a média não puxar para o preto.
        if (a1.a <= 0.0) p1 = c;
        if (a2.a <= 0.0) p2 = p1;
        if (u.persistenceMode == 0) {
            c = max(c, max(p1 * u.persistence, p2 * u.persistence * u.persistence));
        } else {
            float4 janela = float4(0.08);
            float4 q1 = clamp(p1, c - janela, c + janela);
            float4 q2 = clamp(p2, c - janela, c + janela);
            c = mix(c, (q1 + q2) * 0.5, u.persistence * 0.7);
        }
    }

    if (u.colorBleed > 0.0) {
        float2 o = float2(eng.acTexelSize.x * (1.5 + u.colorBleed * 3.0), 0.0);
        float4 espalhado = amostraP(uvDaFonte - o) * 0.25 + c * 0.5 + amostraP(uvDaFonte + o) * 0.25;
        if (u.quality == 3) {
            espalhado = espalhado * 0.7
                      + (amostraP(uvDaFonte - o * 2.0) + amostraP(uvDaFonte + o * 2.0)) * 0.15;
        }
        // Só nas altas: é o fósforo claro que espalha (item 66).
        float quanto = u.colorBleed * smoothstep(0.3, 0.85, luma(semPreMultiplicar(c)));
        c = mix(c, espalhado, quanto);
    }

    float alfa = c.a;
    float3 cor = semPreMultiplicar(c);

    // ------------------------------------------------ preparo da cor (item 45)
    cor = max(cor * u.brightness, 0.0);
    cor = (cor - 0.5) * u.contrast + 0.5;
    cor = pow(max(cor, 0.0), float3(1.0 / max(u.gammaValue, 0.01)));
    float l = luma(cor);
    cor = max(mix(float3(l), cor, u.saturationAmt), 0.0);
    l = luma(cor);

    // ------------------------------------------------ as linhas
    float fase = u.phase + tempo * u.speed;
    float y = p.y * u.lineCount / espaco;
    if (u.lineDistort > 0.0 || distorcao > 0.0) {
        float torto = ruidoSuave(float2(p.x * 6.0 * u.noiseScale, floor(y) * 0.7 + tempo * 3.0)) - 0.5;
        y += torto * (u.lineDistort + distorcao * 0.5) * 1.2;
    }
    y += fase;

    float dx = dfdx(y);
    float dy = dfdy(y);
    float fw = abs(dx) + abs(dy);

    // Beam Expansion: nas altas o feixe engorda e o vão fecha.
    float meia = 0.5 * u.thickness / espaco;
    meia += (0.5 - meia) * clamp(l * u.beamExpansion * 1.4, 0.0, 1.0);

    // Fase por canal (itens 15 e 16): o desalinhamento fixo e o rolar animado.
    float rolar = u.rollAmount;
    float3 desvio = float3(u.shiftR + rgbTotal * 0.33, u.shiftG, u.shiftB - rgbTotal * 0.33);
    if (rolar > 0.0) {
        desvio += rolar * 0.5 * float3(
            sin(tempo * u.rollSpeed * 2.0),
            sin(tempo * u.rollSpeed * 2.0 + 2.094),
            sin(tempo * u.rollSpeed * 2.0 + 4.188));
    }

    float3 linha;
    bool porCanal = abs(desvio.r) + abs(desvio.g) + abs(desvio.b) > 0.0001;
    if (porCanal) {
        linha = float3(
            perfilAA(y + desvio.r, meia, dx, dy, fw),
            perfilAA(y + desvio.g, meia, dx, dy, fw),
            perfilAA(y + desvio.b, meia, dx, dy, fw));
    } else {
        linha = float3(perfilAA(y, meia, dx, dy, fw));
    }

    // Cross e Squares: o mesmo padrão no outro eixo, multiplicado (item 25).
    if (u.patternMode == 1 || u.patternMode == 2) {
        float yv = p.x * u.lineCount / espaco + fase;
        float dxv = dfdx(yv);
        float dyv = dfdy(yv);
        float fwv = abs(dxv) + abs(dyv);
        linha *= perfilAA(yv, meia, dxv, dyv, fwv);
    }

    // O ruído da linha: trechos que falham.
    float fileira = floor(y);
    if (u.lineNoise > 0.0) {
        float n = ruidoDaLinha(p.x, fileira, quadroDoRuido);
        linha *= mix(1.0 - u.lineNoise, 1.0, n);
    }

    // A faixa de varredura (item 22): uma região mais forte, rolando.
    float faixa = 0.0;
    if (u.bandAmount > 0.0) {
        float centroDaFaixa = fract(tempo * u.bandSpeed * 0.25 + 0.5);
        float dist = abs(fract(uvOriginal.y - centroDaFaixa + 0.5) - 0.5);
        float meiaFaixa = u.bandWidth * 0.5;
        faixa = 1.0 - smoothstep(meiaFaixa * (1.0 - u.bandSoftness), meiaFaixa + 0.0001, dist);
        linha = mix(linha, float3(1.0), faixa * u.bandAmount * 0.5);
    }

    // Entrelaçado (item 36): o campo que não é o da vez fica mais escuro.
    if (u.interlace > 0) {
        float taxa = u.interlace == 1 ? 30.0 : u.interlace == 2 ? 60.0 : u.interlaceRate;
        float campo = __nv_mod(floor(tempo * taxa), 2.0);
        if (abs(__nv_mod(fileira, 2.0) - campo) < 0.5) linha *= 1.0 - u.interlaceAmount * 0.6;
    }

    // ------------------------------------------------ linha + imagem (item 13)
    float intens = clamp(u.intensity * (1.0 + reage(0)), 0.0, 1.0);
    float nivelDoVao = mix(1.0, u.gapBrightness, intens);
    float cobertura = clamp(meia * 2.0, 0.0, 1.0);
    if (u.patternMode == 1 || u.patternMode == 2) cobertura *= cobertura;

    float3 resultado;
    float media;
    if (u.lineStyle == 0) {
        resultado = cor * mix(float3(nivelDoVao), float3(1.0), linha);
        media = mix(nivelDoVao, 1.0, cobertura);
    } else if (u.lineStyle == 1) {
        resultado = cor + u.lineColor.rgb * u.lineColor.a * linha * intens * u.lineBrightness;
        media = 1.0;
    } else {
        resultado = cor * mix(float3(nivelDoVao), float3(1.0), linha);
        resultado += cor * linha * u.lineBrightness * intens * 0.6;
        media = mix(nivelDoVao, 1.0, cobertura) + u.lineBrightness * intens * 0.6 * cobertura;
    }
    // Keep Brightness: devolve a luz que as linhas tiraram, com teto.
    resultado *= mix(1.0, 1.0 / clamp(media, 0.35, 3.0), u.keepBrightness);

    // ------------------------------------------------ fósforo
    int tipoDaMascara = u.maskType;
    float forcaDaMascara = u.maskStrength;
    if (tipoDaMascara == 0 && u.patternMode == 3) { tipoDaMascara = 3; forcaDaMascara = 0.45; }
    if (tipoDaMascara == 0 && u.patternMode == 4) { tipoDaMascara = 5; forcaDaMascara = 0.45; }
    // A máscara some quando o fósforo fica menor que um pixel e meio: é moiré,
    // não estrutura (item 35).
    forcaDaMascara *= smoothstep(1.0, 1.5, u.maskSize);
    resultado *= fosforo(__nv_fragCoord.xy, tipoDaMascara, forcaDaMascara);

    // ------------------------------------------------ ruído da imagem (itens 17 e 20)
    float ruidoTotal = u.noiseAmt + reage(2) * 0.5;
    float3 grao = float3(0.5);
    if (ruidoTotal > 0.0) {
        float2 celula = u.noiseType == 1
            ? floor(__nv_fragCoord.xy / max(u.blockSize, 1.0))
            : floor(__nv_fragCoord.xy / max(u.noiseScale, 0.1));
        if (u.noiseMono) {
            grao = float3(hash21(celula + quadroDoRuido * 13.1));
        } else {
            grao = float3(
                hash21(celula + quadroDoRuido * 13.1),
                hash21(celula + quadroDoRuido * 13.1 + 71.3),
                hash21(celula + quadroDoRuido * 13.1 + 143.9));
        }
        // Mais nos meios-tons, como grão de verdade.
        float peso = 0.35 + 2.6 * l * (1.0 - l);
        resultado += (grao - 0.5) * ruidoTotal * 0.6 * peso;
    }

    // ------------------------------------------------ o tempo (item 21)
    if (u.flicker > 0.0) {
        float oscilacao = sin(tempo * TAU * 9.3) * 0.35 + (ruidoSuave(float2(tempo * 14.0, 3.1)) - 0.5) * 1.3;
        resultado *= 1.0 + oscilacao * u.flicker * 0.3;
    }
    resultado *= 1.0 + faixa * u.bandAmount * 0.35;

    resultado = max(resultado, 0.0);

    /*
     * AS ALTAS SEM MUDAR DE COR.
     *
     * A linha acesa passa de 1 (é luz concentrada), e cortar cada canal no 1
     * separado muda o TOM: um amarelo forte, com o vermelho batendo no teto e o
     * verde ainda subindo, vira amarelo-esverdeado. Aqui o pico é comprimido e
     * os três canais descem juntos, na mesma proporção.
     */
    float pico = max(resultado.r, max(resultado.g, resultado.b));
    if (pico > 0.8) {
        float novoPico = 0.8 + 0.2 * (1.0 - exp(-(pico - 0.8) / 0.2));
        resultado *= novoPico / pico;
    }
    if (fora) alfa = 0.0;

    // ------------------------------------------------ os modos de ver (item 76)
    if (u.view == 1) return float4(float3(dot(linha, float3(1.0 / 3.0))), 1.0);
    if (u.view == 2) return float4(grao, 1.0);
    if (u.view == 3) return float4(linha, 1.0);
    if (u.view == 6) {
        float2 xadrez = floor(local * 16.0);
        float casa = __nv_mod(xadrez.x + xadrez.y, 2.0);
        return float4(fora ? float3(0.2, 0.0, 0.0) : float3(casa * 0.6 + 0.2), 1.0);
    }
    if (u.view == 7) return float4(float3(l), 1.0);

    return float4(clamp(resultado, 0.0, 1.0) * alfa, alfa);
}

// ============================================================================
//  PASSES 1 A 3 — O BRILHO, EM RESOLUÇÃO REDUZIDA (itens 29, 30 e 67)
// ============================================================================

/** O que passa do limiar, já linearizado (o quadrado é o gama 2 aproximado). */
float3 brilhante(float2 uv) {
    float4 t = tela.sample(__nv_smp, uv);
    float3 cor = t.rgb;
    float w = smoothstep(u.glowThreshold, u.glowThreshold + 0.3, luma(cor));
    return cor * cor * w;
}

float3 desfocar(sampler2D fonteDoDesfoque, float2 uv, float raio) {
    float2 o = eng.acTexelSize * raio;
    float3 soma = fonteDoDesfoque.sample(__nv_smp, uv).rgb * 0.25;
    soma += (fonteDoDesfoque.sample(__nv_smp, uv + float2(o.x, 0.0)).rgb
           + fonteDoDesfoque.sample(__nv_smp, uv - float2(o.x, 0.0)).rgb
           + fonteDoDesfoque.sample(__nv_smp, uv + float2(0.0, o.y)).rgb
           + fonteDoDesfoque.sample(__nv_smp, uv - float2(0.0, o.y)).rgb) * 0.125;
    soma += (fonteDoDesfoque.sample(__nv_smp, uv + o).rgb
           + fonteDoDesfoque.sample(__nv_smp, uv - o).rgb
           + fonteDoDesfoque.sample(__nv_smp, uv + float2(o.x, -o.y)).rgb
           + fonteDoDesfoque.sample(__nv_smp, uv + float2(-o.x, o.y)).rgb) * 0.0625;
    return soma;
}

// ============================================================================
//  PASSE 4 — JUNTAR
// ============================================================================

/** Onde o efeito age (item 49), de 0 a 1. */
float ondeAplicar(float2 uv, float4 original) {
    float m = 1.0;
    float f = max(u.maskFeather, 0.001);
    if (u.maskSource == 1) {
        m = smoothstep(0.5 - f * 0.5, 0.5 + f * 0.5, luma(original.rgb));
    } else if (u.maskSource == 2) {
        m = smoothstep(0.0, f, original.a);
    } else if (u.maskSource == 3) {
        float4 camada = maskLayerImg.sample(__nv_smp, uv);
        m = luma(camada.rgb) * camada.a;
    } else if (u.maskSource == 4) {
        float a = radians(u.gradientAngle);
        float2 q = uv - 0.5;
        q.x *= eng.acAspect;
        float t = dot(q, float2(cos(a), sin(a))) + 0.5;
        m = smoothstep(u.gradientPosition - f * 0.5, u.gradientPosition + f * 0.5, t);
    } else if (u.maskSource == 5) {
        float2 q = uv - 0.5;
        q.x *= eng.acAspect;
        m = 1.0 - smoothstep(u.gradientPosition - f * 0.5, u.gradientPosition + f * 0.5, length(q) * 1.4);
    }
    return u.maskInvert ? 1.0 - m : m;
}

float4 juntar() {
    float2 uv = in.acScreenNorm;
    float4 base = tela.sample(__nv_smp, uv);

    if (u.view == 1 || u.view == 2 || u.view == 3 || u.view == 6 || u.view == 7) return base;

    // ------------------------------------------------ o brilho
    float forcaDoBrilho = u.glow * (1.0 + reage(1) * 2.0);
    float3 brilho = float3(0.0);
    if (forcaDoBrilho > 0.0) {
        float3 pequeno = desfocar(brilhoA, uv, u.glowRadius * 0.75);
        float3 medio = brilhoB.sample(__nv_smp, uv).rgb;
        float3 grande = brilhoC.sample(__nv_smp, uv).rgb;
        float3 multi = pequeno;
        if (u.quality >= 1) multi += medio * 0.45;
        if (u.quality >= 2) multi += grande * 0.18;

        if (u.glowMode == 0) {
            // Glow Lines: o brilho sai das próprias linhas — um desfoque curto
            // na direção que as atravessa, e um pouco de atmosfera por cima.
            float a = radians(u.angle);
            float2 normal = float2(-sin(a), cos(a)) / float2(max(eng.acAspect, 0.0001), 1.0);
            float2 passo = normal * (0.5 / max(u.lineCount, 1.0)) * u.glowRadius;
            float3 nasLinhas = brilhante(uv) * 0.4
                + (brilhante(uv + passo) + brilhante(uv - passo)) * 0.2
                + (brilhante(uv + passo * 2.0) + brilhante(uv - passo * 2.0)) * 0.1;
            brilho = nasLinhas * 1.6 + multi * 0.35;
        } else {
            brilho = multi;
        }
        brilho *= forcaDoBrilho * u.glowColor.rgb;
    }

    if (u.view == 4) return float4(sqrt(brilho), 1.0);

    // Soma no linear e volta: o brilho em gama somaria "leitoso" (item 72).
    float3 lin = base.rgb * base.rgb;
    float alfa = base.a;
    if (u.glowSpill) {
        lin += brilho;
        alfa = max(alfa, clamp(luma(brilho) * 1.5, 0.0, 1.0));
    } else {
        lin += brilho * base.a;
    }
    // Segura as altas em vez de estourar (item 73).
    lin = lin / (1.0 + max(lin - 1.0, 0.0));
    float3 cor = sqrt(lin);

    float4 geo = geometria(uv);
    float2 local = geo.zw;
    bool fora = foraDaTela(local);

    // ------------------------------------------------ o vidro (item 89)
    if (!fora && (u.reflectionAmount > 0.0 || u.glassSheen > 0.0)) {
        float2 r = local;
        if (u.reflectionMirror) r.x = 1.0 - r.x;
        r = (r - 0.5) / max(u.reflectionScale, 0.01) + 0.5;
        float3 vidro = float3(0.0);
        if (u.reflectionAmount > 0.0 && !foraDaTela(r)) {
            float4 refl = reflexo.sample(__nv_smp, r);
            // Reflexo aparece onde a tela está escura: onde ela brilha, a luz
            // dela vence a do quarto.
            float escuro = 1.0 - luma(cor / max(alfa, 0.0001)) * 0.8;
            vidro += refl.rgb * refl.a * u.reflectionAmount * 0.45 * escuro;
        }
        if (u.glassSheen > 0.0) {
            // O lustro: uma mancha larga vinda de cima à esquerda e a borda
            // acendendo de raspão.
            float2 d = local - float2(0.3, 0.2);
            float mancha = exp(-dot(d, d) * 6.0) * 0.5;
            float2 q = abs(local - 0.5) * 2.0;
            float borda = pow(max(q.x, q.y), 6.0) * 0.35;
            vidro += float3(mancha + borda) * u.glassSheen * 0.35;
        }
        // Tela (screen) em pré-multiplicado: nunca passa do alfa.
        cor += clamp(vidro, 0.0, 1.0) * max(alfa - cor, 0.0);
    }

    // ------------------------------------------------ vinheta (item 32)
    if (u.vignette > 0.0) {
        float2 q = abs(local - 0.5) * 2.0;
        float potencia = mix(8.0, 2.0, u.vignetteRoundness);
        float d = pow(pow(q.x, potencia) + pow(q.y, potencia), 1.0 / potencia);
        float v = smoothstep(u.vignetteSize, u.vignetteSize + u.vignetteSoftness, d) * u.vignette * u.vignetteColor.a;
        cor = mix(cor, u.vignetteColor.rgb * alfa, v);
    }

    // ------------------------------------------------ moldura (item 69)
    if (u.frameAmount > 0.0) {
        // A caixa da TV: a tela encolhe um pouco para dentro de um aro de
        // cantos redondos, e o que sobra (inclusive o que o vidro curvo empurrou
        // para fora, e as faixas de uma tela 4:3 numa camada deitada) é o
        // plástico escuro — que, ao contrário da tela, cobre a camada inteira.
        float2 q = abs(local - 0.5) * 2.0 * (1.0 + u.frameAmount * 0.08);
        float raio = max(u.frameRoundness * 0.3, 0.001);
        float2 dentro = max(q - (1.0 - raio), 0.0);
        float borda = length(dentro) - raio;
        float moldura = max(smoothstep(-0.006, 0.006, borda), fora ? 1.0 : 0.0);
        float quanto = moldura * clamp(u.frameAmount * 3.0, 0.0, 1.0);
        float4 original0 = inputImg.sample(__nv_smp, uv);
        float alfaDaCaixa = max(alfa, original0.a);
        cor = mix(cor, float3(0.035, 0.035, 0.045) * alfaDaCaixa, quanto);
        alfa = mix(alfa, alfaDaCaixa, quanto);
    }

    // ------------------------------------------------ tinta
    /*
     * Colorir pela luminância, e não multiplicar: multiplicar um amarelo por
     * azul dá VERDE, e o "monitor neon" saía esverdeado. Aqui o claro vira a
     * cor escolhida e o escuro continua escuro — a tela de uma cor só.
     */
    if (u.tintAmount > 0.0) {
        float3 tinta = u.tintColor.rgb / max(luma(u.tintColor.rgb), 0.2);
        cor = mix(cor, luma(cor) * tinta, u.tintAmount);
    }

    // ------------------------------------------------ onde e quanto (itens 48 e 49)
    float4 original = inputImg.sample(__nv_smp, uv);
    float quanto = clamp(u.mixAmt, 0.0, 1.0) * ondeAplicar(uv, original);
    if (u.view == 5) return float4(float3(quanto), 1.0);

    float4 efeito = float4(clamp(cor, 0.0, max(alfa, 0.0001)), alfa);
    float4 originalP = float4(original.rgb * original.a, original.a);
    float4 saida = mix(originalP, efeito, quanto);
    return float4(semPreMultiplicar(saida), saida.a);
}

fragment float4 fx_scanlines_pro(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant scanlines_proParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> tela [[texture(1)]],
    texture2d<float> brilhoA [[texture(2)]],
    texture2d<float> brilhoB [[texture(3)]],
    texture2d<float> brilhoC [[texture(4)]],
    texture2d<float> anterior1 [[texture(5)]],
    texture2d<float> anterior2 [[texture(6)]],
    texture2d<float> mascaraPropria [[texture(7)]],
    texture2d<float> reflexo [[texture(8)]],
    texture2d<float> maskLayerImg [[texture(9)]],
    texture2d<float> somImg [[texture(10)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = passeDaTela(); return __nv_out; }

    if (eng.acPass == 1) {
        // Redução para 1/4 com quatro amostras bilineares: cada uma já é a média
        // de 2×2 pixels da tela, então as quatro cobrem 4×4 sem pular nada.
        float2 t = eng.acTexelSize * 0.25;
        float3 soma = brilhante(in.acScreenNorm + float2(-t.x, -t.y))
                  + brilhante(in.acScreenNorm + float2( t.x, -t.y))
                  + brilhante(in.acScreenNorm + float2(-t.x,  t.y))
                  + brilhante(in.acScreenNorm + float2( t.x,  t.y));
        __nv_out = float4(soma * 0.25, 1.0);
        return __nv_out;
    }

    if (eng.acPass == 2) { __nv_out = float4(desfocar(brilhoA, in.acScreenNorm, 1.5 * u.glowRadius), 1.0); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = float4(desfocar(brilhoB, in.acScreenNorm, 1.5 * u.glowRadius), 1.0); return __nv_out; }

    __nv_out = juntar();
    return __nv_out;
}
