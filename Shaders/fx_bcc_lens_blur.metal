// ---------------------------------------------------------------------------
// BCC Lens Blur
// origem : assets/effects/bcc-lens-blur.xml
// id     : nova.effect.bcclensblur
// passes : 10
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bcc_lens_blurParams {
    int quality;
    float irisScale;
    float scaleX;
    float scaleY;
    float gamma;
    int irisShape;
    float irisCurvature;
    float irisRotation;
    float bokeh;
    float bokehShading;
};

// --- funcoes auxiliares do efeito
// ---- constantes do ajuste (tools/bcclensblur/benchmark/ajustar.py; gerar.py as escreve aqui) ----
const float K_B0 = 8.2085;          // Bokeh < 0: onde o miolo começa a esvaziar
const float K_B1 = 204.8659;
const float K_BP = 1.1773;          // Bokeh > 0: o quanto a íris encolhe
const float K_E_POS = 20.9801;    // Bokeh Shading -> expoente da rampa
const float K_E_NEG = 20.5;
const float K_AA1R = 0.0832;      // maciez extra da borda, em fração do raio: Quality 1
const float K_AA3R = 0.0308;      // e as outras
const float K_R0 = 0.0468;          // a borda fica este tanto (px) por dentro do raio nominal
const float PI = 3.14159265359;
const int MEIA_MAX = 16;          // a íris é somada numa grade de até 33 x 33 pontos; maior que isso, num buffer reduzido

/** A distância do centro à borda da íris na direção `th` (sem a rotação), para raio 1. */
float raioDaBorda(float th, int lados, float curva) {
    if (lados < 3) return 1.0;
    float setor = 2.0 * PI / float(lados);
    // um vértice aponta para a esquerda (180 graus); `a` é o ângulo medido do meio do lado mais próximo
    float a = __nv_mod(th - PI, setor) - 0.5 * setor;
    float apot = cos(0.5 * setor);
    if (curva < 1e-4) return apot / cos(a);
    // Medido: cada lado é um arco pelos dois vértices, com o centro a apótema · (1 − 100 / curvatura) do meio.
    float d = apot * (1.0 - 100.0 / curva);
    float s = sin(0.5 * setor);
    float rho2 = (apot * 100.0 / curva) * (apot * 100.0 / curva) + s * s;
    float disc = d * cos(a) * d * cos(a) - (d * d - rho2);
    return disc >= 0.0 ? max(d * cos(a) + sqrt(disc), 0.0) : 0.0;
}

/** O peso (sem normalizar) da íris no deslocamento `d`, em pixels do quadro. `maciez` = meia largura da borda. */
float pesoDaIris(float2 d, float R, float maciez) {
    float2 q = d / (float2(u.scaleX, u.scaleY) * 0.01);
    float r = length(q);
    float th = __nv_atan(q.y, q.x) - radians(u.irisRotation);
    float rb = raioDaBorda(th, u.irisShape == 0 ? 0 : u.irisShape + 2, max(u.irisCurvature, 0.0)) * R;
    float w = clamp((rb - r) / (2.0 * maciez) + 0.5, 0.0, 1.0);
    if (w <= 0.0 || u.bokeh == 0.0) return w;
    // Medido: o perfil do Bokeh é circular (r / R), mesmo quando a íris é um polígono.
    float u = r / max(R, 1e-6);
    float e = u.bokehShading >= 0.0 ? 1.0 + u.bokehShading / K_E_POS : 1.0 / (1.0 - u.bokehShading / K_E_NEG);
    if (u.bokeh < 0.0) {
        float perfil;
        if (u.bokeh > -10.0) perfil = 1.0 - (-u.bokeh / 10.0) * (1.0 - clamp(u, 0.0, 1.0));
        else { float u0 = (-u.bokeh - K_B0) / K_B1; perfil = clamp((min(u, 1.0) - u0) / (1.0 - u0), 0.0, 1.0); }
        return w * pow(perfil, e);
    }
    float u1 = max(1.0 - pow(u.bokeh / 200.0, K_BP), 1e-3);
    return w * clamp(1.0 - pow(clamp(u / u1, 0.0, 1.0), e), 0.0, 1.0);
}

/** Espelha o índice na borda (medido: o BCC espelha o quadro, repetindo o pixel da borda). */
int espelhar(int i, int n) {
    int p = 2 * n;
    i = i - (i / p) * p; if (i < 0) i += p;
    return i < n ? i : p - 1 - i;
}

/** Em que buffer a íris cabe na grade: 0 = o quadro inteiro, 1 = metade, 2 = um quarto... */
int nivelDaIris(float meiaLargura) {
    int t = 0;
    float m = meiaLargura;
    // Na prévia em movimento, a íris numa grade de até 17 x 17 pontos: um nível abaixo, um quarto das somas.
    float maximo = eng.acRascunho == 1 ? float(MEIA_MAX) * 0.5 : float(MEIA_MAX);
    for (int i = 0; i < 4; i++) { if (m > maximo) { m *= 0.5; t++; } }
    return t;
}

float4 lerNivel(int nivel, int2 p) {
    if (nivel == 0) return inputImg.read(uint2(p), uint(0));
    if (nivel == 1) return d1.read(uint2(p), uint(0));
    if (nivel == 2) return d2.read(uint2(p), uint(0));
    if (nivel == 3) return d3.read(uint2(p), uint(0));
    return d4.read(uint2(p), uint(0));
}

int2 tamanhoDoNivel(int nivel) {
    if (nivel == 0) return int2(int(inputImg.get_width()), int(inputImg.get_height()));
    if (nivel == 1) return int2(int(d1.get_width()), int(d1.get_height()));
    if (nivel == 2) return int2(int(d2.get_width()), int(d2.get_height()));
    if (nivel == 3) return int2(int(d3.get_width()), int(d3.get_height()));
    return int2(int(d4.get_width()), int(d4.get_height()));
}

/** A média de um bloco do nível de cima, feita na luz do Gamma (é nela que a íris soma). */
float4 reduzir(int deCima, float2 uv, float g) {
    int2 tam = tamanhoDoNivel(deCima);
    float2 c = uv * float2(tam);
    int2 base = int2(floor(c - 0.5));
    float4 soma = float4(0.0);
    for (int j = 0; j < 2; j++) for (int i = 0; i < 2; i++) {
        float4 t = lerNivel(deCima, clamp(base + int2(i, j), int2(0), tam - 1));
        soma += float4(pow(t.rgb, float3(g)), t.a);
    }
    soma *= 0.25;
    return float4(pow(soma.rgb, float3(1.0 / g)), soma.a);
}

// A grade da íris vai de −MEIA_GRADE a +MEIA_GRADE pontos em cada eixo.
const int MEIA_GRADE = MEIA_MAX + 8;

/** Quantos pontos de cada lado a soma da íris anda no nível de `passo` px do quadro por pixel. */
int meiaGrade(float meiaLargura, float passo) {
    int n = int(ceil(meiaLargura / passo));
    return n > MEIA_GRADE ? MEIA_GRADE : n;
}

/**
 * O peso da íris no ponto (i, j) da grade do nível de `passo` px. Medido: o BCC desenha a íris por COBERTURA DE
 * ÁREA. Numa íris de poucos pontos (ou achatada pelo Scale) cada ponto da grade é dividido em até 8 x 8; de 8
 * pontos de raio em diante, um só basta.
 */
float pesoDoPonto(int i, int j, float passo, float R, float maciez) {
    float2 emPontos = R * float2(u.scaleX, u.scaleY) * 0.01 / passo;
    int2 sub = int2(clamp(ceil(8.0 / max(emPontos, float2(1.0))), float2(1.0), float2(8.0)));
    float m = max(maciez, 0.5 * passo / float(max(sub.x, sub.y)) * min(min(u.scaleX, u.scaleY), 100.0) * 0.01 + 1e-3);
    // a saída em x soma a entrada em x − d com o peso da íris em d
    float w = 0.0;
    for (int b = 0; b < sub.y; b++) for (int a = 0; a < sub.x; a++) {
        // Íris mais fina que o ponto (Scale Y em 1%, por exemplo): os pontos se espalham só por onde ela
        // existe — o que sobra é o peso de cada coluna, proporcional à altura da íris ali.
        float2 dentro = ((float2(float(a), float(b)) + 0.5) / float2(sub) - 0.5) * min(float2(1.0), 2.1 * emPontos);
        w += pesoDaIris((dentro - float2(float(i), float(j))) * passo, R, m);
    }
    return w;
}

/*
 * A TABELA DOS PESOS (0.569.0). O peso de um ponto da grade não depende do pixel: calculado em CADA pixel (o
 * `atan`, os cossenos e a curvatura da borda, até 8 x 8 vezes por ponto), ele era a maior parte do desfoque. Agora
 * o passe 4 o calcula uma vez por quadro, num buffer de 64 x 64 (o ponto (i, j) no texel (i, j) + MEIA_GRADE), e
 * guarda o FLOAT inteiro nos quatro bytes do texel: volta bit a bit, e a soma sai igual à de antes.
 */
float4 bytesDoFloat(float x) {
    uint b = as_type<uint>(x);
    return float4(uint4(b & 255u, (b >> 8) & 255u, (b >> 16) & 255u, b >> 24)) / 255.0;
}

float floatDosBytes(float4 c) {
    uint4 o = uint4(floor(c * 255.0 + 0.5));
    return as_type<float>(o.x | (o.y << 8) | (o.z << 16) | (o.w << 24));
}

/** A soma da íris em volta do pixel `p` do nível `nivel` (cada pixel dele vale `passo` pixels do quadro). */
float4 somarIris(int nivel, int2 p, float R, float meiaLargura, float maciez, float g) {
    int2 tam = tamanhoDoNivel(nivel);
    float passo = float(int2(int(inputImg.get_width()), int(inputImg.get_height())).x) / float(tam.x);
    int n = meiaGrade(meiaLargura, passo);
    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int j = -n; j <= n; j++) for (int i = -n; i <= n; i++) {
        float w = floatDosBytes(pesosDaIris.read(uint2(int2(i, j) + MEIA_GRADE), uint(0)));
        if (w <= 0.0) continue;
        // o espelho (com divisão inteira) só para o ponto que cai fora do nível
        int2 q = p + int2(i, j);
        if (any(lessThan(q, int2(0))) || any(greaterThanEqual(q, tam))) q = int2(espelhar(q.x, tam.x), espelhar(q.y, tam.y));
        float4 t = lerNivel(nivel, q);
        soma += w * float4(pow(t.rgb, float3(g)), t.a);
        pesos += w;
    }
    if (pesos <= 0.0) return lerNivel(nivel, p);
    soma /= pesos;
    return float4(pow(soma.rgb, float3(1.0 / g)), soma.a);
}

/** Um buffer reduzido lido com interpolação bilinear feita à mão (não depende do filtro da textura). */
float4 ampliar(int nivel, float2 uv) {
    int2 tam = nivel == 1 ? int2(int(g1.get_width()), int(g1.get_height())) : nivel == 2 ? int2(int(g2.get_width()), int(g2.get_height())) : nivel == 3 ? int2(int(g3.get_width()), int(g3.get_height())) : int2(int(g4.get_width()), int(g4.get_height()));
    float2 c = uv * float2(tam) - 0.5;
    int2 b = int2(floor(c));
    float2 f = c - float2(b);
    float4 v[4];
    for (int k = 0; k < 4; k++) {
        int2 q = clamp(b + int2(k & 1, k >> 1), int2(0), tam - 1);
        v[k] = nivel == 1 ? g1.read(uint2(q), uint(0)) : nivel == 2 ? g2.read(uint2(q), uint(0)) : nivel == 3 ? g3.read(uint2(q), uint(0)) : g4.read(uint2(q), uint(0));
    }
    return mix(mix(v[0], v[1], f.x), mix(v[2], v[3], f.x), f.y);
}

fragment float4 fx_bcc_lens_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bcc_lens_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> d1 [[texture(1)]],
    texture2d<float> d2 [[texture(2)]],
    texture2d<float> d3 [[texture(3)]],
    texture2d<float> d4 [[texture(4)]],
    texture2d<float> g1 [[texture(5)]],
    texture2d<float> g2 [[texture(6)]],
    texture2d<float> g3 [[texture(7)]],
    texture2d<float> g4 [[texture(8)]],
    texture2d<float> pesosDaIris [[texture(9)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 TAM = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float g = clamp(u.gamma, 10.0, 1000.0) * 0.01;
    // Medido: o raio é Iris Scale · maior lado do quadro / 750.
    float R = u.irisScale * float(max(TAM.x, TAM.y)) / 750.0;
    float maciez = (u.quality == 0 ? K_AA1R : K_AA3R) * R;
    float meiaLargura = R * max(u.scaleX, u.scaleY) * 0.01 * (u.irisCurvature > 100.0 ? 1.4 : 1.0) + 2.0 * maciez + 1.0;
    R = max(R - K_R0, 1e-3);
    int nivel = nivelDaIris(meiaLargura);
    bool nada = u.irisScale * float(max(TAM.x, TAM.y)) / 750.0 < 0.3;

    // passes 0 a 3: o quadro pela metade, um quarto, um oitavo, um dezesseis avos
    if (eng.acPass < 4) {
        __nv_out = (nada || nivel <= eng.acPass) ? float4(0.0) : reduzir(eng.acPass, in.acScreenNorm, g);
        return __nv_out;
    }
    // passe 4: a tabela dos pesos da íris, para o nível em que ela é somada
    if (eng.acPass == 4) {
        if (nada) { __nv_out = float4(0.0); return __nv_out; }
        int2 ij = int2(__nv_fragCoord.xy) - MEIA_GRADE;
        float passo = float(TAM.x) / float(tamanhoDoNivel(nivel).x);
        int n = meiaGrade(meiaLargura, passo);
        __nv_out = any(greaterThan(abs(ij), int2(n))) ? float4(0.0) : bytesDoFloat(pesoDoPonto(ij.x, ij.y, passo, R, maciez));
        return __nv_out;
    }
    // passes 5 a 8: a íris somada no buffer em que ela cabe (os outros ficam vazios)
    if (eng.acPass < 9) {
        int t = eng.acPass - 4;
        if (nada || nivel != t) { __nv_out = float4(0.0); return __nv_out; }
        int2 tam = tamanhoDoNivel(t);
        int2 p = int2(min(floor(in.acScreenNorm * float2(tam)), float2(tam) - 1.0));
        __nv_out = somarIris(t, p, R, meiaLargura, maciez, g);
        return __nv_out;
    }
    // passe 9: a saída
    int2 p = int2(min(floor(in.acScreenNorm * float2(TAM)), float2(TAM) - 1.0));
    if (nada) { __nv_out = inputImg.read(uint2(p), uint(0)); return __nv_out; }
    __nv_out = nivel == 0 ? somarIris(0, p, R, meiaLargura, maciez, g) : ampliar(nivel, in.acScreenNorm);
    return __nv_out;
}
