// ---------------------------------------------------------------------------
// Deslocamento turbulento
// origem : assets/effects/turbulent-displace.xml
// id     : nova.effect.turbulentdisplace
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct turbulent_displaceParams {
    int deslocamento;
    float quantidade;
    float tamanho;
    float2 offset;
    float complexidade;
    float evolucao;
    int cicloEvolucao;
    float revolucoes;
    float semente;
    int prender;
    int antialias;
};

// --- funcoes auxiliares do efeito
// <constantes> AS BASES, EM CENTÉSIMOS (exatas: 7913,17 = 791317/100). Ver gerar.py.
//
// Até 06/10/2026 eram duas tabelas de 154 números (14 bases × 11 oitavas, base·1,77ᵏ
// reduzida em double). Tabela grande lida com índice variável é o que mais pesa numa
// GPU de celular (o driver pode copiá-la para a memória de cada pixel). Agora a conta
// anda junto com a oitava, em [avancar]: 1,77 = 177/100, então a parte INTEIRA vai em
// inteiro exato e só a fração (< 2) vai em float — bate com a tabela (os 154 inteiros
// iguais, a fração a menos de 0,00004 de célula).
const int U_A = -179856;
const int V_A = 1762490;
const int U_B = -177856;
const int V_B = 1767890;
const int U_C = -179831;
const int V_C = 1762515;
const int U_D = -179881;
const int V_D = 1762515;
const int X_A = 791317;
const int X_B = 795017;
const int X_C = 791342;
const int Y_A = 971173;
const int Y_B = 972873;
const int Y_C = 971198;
// </constantes>

const uint LCG_A = 0x41C64E6Du;
const uint LCG_C = 0x3039u;
const int QUARTO = 5898240;          // 90° em 16.16

static float sorteio(uint s) { return float((s >> 16u) & 0x7FFFu) / 16384.0 - 1.0; }

static float bspline(float p0, float p1, float p2, float p3, float t) {
    float t2 = t * t;
    float t3 = t2 * t;
    float u = 1.0 - t;
    return 0.2 * (u * u * u * p0 + (3.0 * t3 - 6.0 * t2 + 4.0) * p1
                  + (-3.0 * t3 + 3.0 * t2 + 3.0 * t + 1.0) * p2 + t3 * p3);
}

/** A u.semente de um quarto de volta: a chave reduzida pelo período, como o plugin (C, com sinal). */
static uint sementeDaChave(uint chave, uint periodo) {
    int k = int(chave);
    uint m = k >= 0 ? uint(k) % periodo : (periodo - (0u - chave) % periodo) % periodo;
    return 0x0DAA96F5u - m * 0x145EB7C3u;
}

/** O valor n da grade (0..4095): a B-spline no tempo entre 4 sorteios. */
static float valorDaGrade(int n) {
    // A Evolution em 16.16, partida em quartos de volta inteiros + a fração.
    int e = int(round(u.evolucao * 65536.0));
    int q = int(floor(float(e) / float(QUARTO)));
    int resto = e - q * QUARTO;
    if (resto < 0) { q -= 1; resto += QUARTO; }
    if (resto >= QUARTO) { q += 1; resto -= QUARTO; }
    float fr = float(resto) / float(QUARTO);

    uint periodo = 0x7E900000u;   // 90 revoluções: o ciclo de sempre
    int rev = int(u.revolucoes + 0.5);
    if (u.cicloEvolucao && rev > 0) periodo = uint(rev) * 0x1680000u;
    uint c = uint(q) * uint(QUARTO) + uint(int(u.semente + 0.5));

    // O LCG avançado n + 1 passos de uma vez: x → A·x + C.
    uint A = 1u, C = 0u, a = LCG_A, b = LCG_C;
    uint passos = uint(n + 1);
    while (passos > 0u) {
        if ((passos & 1u) != 0u) { A = a * A; C = a * C + b; }
        b = a * b + b;
        a = a * a;
        passos >>= 1u;
    }
    float r[6];
    for (int j = 0; j < 6; j++) {
        uint s = sementeDaChave(c + uint(j - 2) * 0x5A0000u, periodo);
        r[j] = sorteio(A * s + C);
    }
    float t = sorteio(A * 0xBC8CB5u + C) + fr;
    if (t < 0.0) return bspline(r[0], r[1], r[2], r[3], t + 1.0);
    if (t > 1.0) return bspline(r[2], r[3], r[4], r[5], t - 1.0);
    return bspline(r[1], r[2], r[3], r[4], t);
}

// A grade no buffer: 24 bits por valor (RGB), na faixa ±1,25.
static float4 codifica(float v) {
    uint q = uint(clamp((v + 1.25) / 2.5, 0.0, 1.0) * 16777215.0 + 0.5);
    return float4(float(q >> 16u), float((q >> 8u) & 255u), float(q & 255u), 255.0) / 255.0;
}

// As 14 bases, na ordem dos índices que `fractal` recebe.
const int B_UA = 0; const int B_VA = 1; const int B_UB = 2; const int B_VB = 3; const int B_UC = 4; const int B_VC = 5;
const int B_UD = 6; const int B_VD = 7; const int B_XA = 8; const int B_XB = 9; const int B_XC = 10; const int B_YA = 11;
const int B_YB = 12; const int B_YC = 13;
static int centesimosDaBase(int b) {
    int bases[14] = int[14](U_A, V_A, U_B, V_B, U_C, V_C, U_D, V_D, X_A, X_B, X_C, Y_A, Y_B, Y_C);
    return bases[b];
}

static float G(int n) {
    float3 c = floor(grade.read(uint2(int2(n & 63, n >> 6)), uint(0)).rgb * 255.0 + 0.5);
    return (c.r * 65536.0 + c.g * 256.0 + c.b) / 16777215.0 * 2.5 - 1.25;
}

/** A grade em (a, b): o índice embaralhado do plugin, periódico em 4096 nos dois eixos. */
static float L(int a, int b) {
    a &= 4095;
    b &= 4095;
    return G(((((b >> 6) ^ a) & 63) << 6) + (((a >> 6) ^ b) & 63));
}

static float L1(int i) {
    i &= 4095;
    return G(((i & 63) << 6) + (((i ^ 0x440) >> 6) & 63));
}

static float suaviza(float f) { return clamp(f, 0.0, 1.0) * clamp(f, 0.0, 1.0) * (3.0 - 2.0 * clamp(f, 0.0, 1.0)); }

// m / 100 para m >= 0, SEM divisão inteira (cara na GPU, e era por oitava, por pixel):
// a estimativa em float erra no máximo ±2 (m < 2·10⁹), e o resto corrige para o exato.
static int div100(int m) {
    int q = int(float(m) * 0.01);
    int r = m - q * 100;
    if (r < 0) { q -= 1; r += 100; }
    if (r < 0) { q -= 1; r += 100; }
    if (r >= 100) { q += 1; r -= 100; }
    if (r >= 100) { q += 1; }
    return q;
}

// A parte constante de uma coordenada: inteiro (não reduzido; L() reduz) + fração em 0..1.
static void comecar(int centesimos, out int i, out float f) {
    int q = centesimos >= 0 ? div100(centesimos) : -div100(99 - centesimos);   // piso
    i = q;
    f = float(centesimos - q * 100) / 100.0;
}

// × 1,77 = × 177/100: o inteiro em aritmética inteira (cabe: |i| < 1,2·10⁷), a fração em
// float. Inteiros negativos (as bases U_*) vão pelo módulo, sem divisão de negativo
// (que o GLSL ES deixa por conta do driver).
static void avancar(inout int i, inout float f) {
    if (i >= 0) {
        int m = i * 177;
        int q = div100(m);
        float t = float(m - q * 100) / 100.0 + f * 1.77;
        float fl = floor(t);
        i = q + int(fl);
        f = t - fl;
    } else {
        int m = (-i) * 177;
        int q = div100(m);
        float t = f * 1.77 - float(m - q * 100) / 100.0;
        float fl = floor(t);
        i = int(fl) - q;
        f = t - fl;
    }
}

// A parte constante da base `b` na oitava `k`: o inteiro (mod 4096: a grade é periódica) em 12 bits e a fração
// em 20, nas linhas 64 a 66 da grade. Iguais em todo pixel: calculadas UMA vez, no passe 0.
static float4 codificaConstante(int i, float f) {
    uint ii = uint(i & 4095);
    uint q = min(uint(f * 1048576.0 + 0.5), 1048575u);
    return float4(float(ii >> 4u), float(((ii & 15u) << 4u) | (q >> 16u)), float((q >> 8u) & 255u), float(q & 255u)) / 255.0;
}
static void constante(int b, int k, out int i, out float f) {
    int e = b * 11 + k - 1;
    uint4 c = uint4(grade.read(uint2(int2(e & 63, 64 + (e >> 6))), uint(0)) * 255.0 + 0.5);
    i = int((c.r << 4u) | (c.g >> 4u));
    f = float(((c.g & 15u) << 16u) | (c.b << 8u) | c.a) / 1048576.0;
}

// A coordenada da oitava: a parte constante (i, f) mais a que varia com o pixel.
static void coordenada(int I, float F, float variavel, out int inteiro, out float fracao) {
    float x = F + variavel;
    float fl = floor(x);
    inteiro = I + int(fl);
    fracao = x - fl;
}

static float oitavaLinear(int Iu, float Fu, int Iv, float Fv, float2 var) {
    int i, j;
    float fu, fv;
    coordenada(Iu, Fu, var.x, i, fu);
    coordenada(Iv, Fv, var.y, j, fv);
    float su = suaviza(fu);
    float sv = suaviza(fv);
    return ((1.0 - su) * L(i, j) + su * L(i + 1, j)) * (1.0 - sv)
         + ((1.0 - su) * L(i, j + 1) + su * L(i + 1, j + 1)) * sv;
}

static float oitavaCubica(int Ix, float Fx, int Iy, float Fy, float2 var) {
    int a, b;
    float fx, fy;
    coordenada(Ix, Fx, var.x, a, fx);
    coordenada(Iy, Fy, var.y, b, fy);
    float l[4];
    for (int m = 0; m < 4; m++) {
        int y = b - 1 + m;
        l[m] = bspline(L(a - 1, y), L(a, y), L(a + 1, y), L(a + 2, y), fx);
    }
    return bspline(l[0], l[1], l[2], l[3], fy);
}

static float oitava1D(int I, float F, float var) {
    int i;
    float f;
    coordenada(I, F, var, i, f);
    float s = suaviza(f);
    return (1.0 - s) * L1(i) + s * L1(i + 1);
}

int OITAVAS;
float FRACAO;
// A faixa de oitavas que este passe soma (ver K_CORTE).
int K_DE;
int K_ATE;

/** O ruído fractal. `var` é a parte variável da coordenada SEM o 1,77ᵏ. */
static float fractal(bool cubico, int b1, int b2, float2 var) {
    float soma = 0.0;
    float amp = 0.25;
    float escala = 1.0;
    int i1, i2;
    float f1, f2;
    // Limite FIXO (11 oitavas no máximo) e saída por `break`.
    for (int k = 1; k <= 11; k++) {
        if (k > OITAVAS + 1) break;
        escala *= 1.77;
        float peso = k <= OITAVAS ? 1.0 : FRACAO;
        if (peso <= 0.0) break;
        if (k > K_ATE) break;
        if (k >= K_DE) {
            constante(b1, k, i1, f1);
            constante(b2, k, i2, f2);
            float v = cubico ? oitavaCubica(i1, f1, i2, f2, var * escala) : oitavaLinear(i1, f1, i2, f2, var * escala);
            soma += v * amp * peso;
        }
        amp *= 0.7;
    }
    return soma;
}

static float fractal1D(int base, float var) {
    float soma = 0.0;
    float amp = 0.25;
    float escala = 1.0;
    int i1;
    float f1;
    for (int k = 1; k <= 11; k++) {
        if (k > OITAVAS + 1) break;
        escala *= 1.77;
        float peso = k <= OITAVAS ? 1.0 : FRACAO;
        if (peso <= 0.0) break;
        if (k > K_ATE) break;
        if (k >= K_DE) {
            constante(base, k, i1, f1);
            soma += oitava1D(i1, f1, var * escala) * amp * peso;
        }
        amp *= 0.7;
    }
    return soma;
}

float ESC;          // pixels do buffer por pixel da camada
float AMT;          // u.deslocamento máximo, px do buffer
float ESCALA;       // a frequência: 0,5/Size (×0,3536 nos três primeiros modos)
int MODO;           // o código do AE: 1, 2, 3, 5, 6, 7, 9, 10, 11
float2 OFF;           // o Offset, px do buffer

static float fatorDaBorda(float d, float m) { return suaviza(d / m); }

int K_CORTE;        // oitavas 1..K_CORTE moram no campo (meia resolução)
float2 FATOR;         // pixels da camada por texel do campo

/** O u.deslocamento CRU (sem Pinning) das oitavas K_DE..K_ATE no pixel `p` (da camada cheia). */
static float2 ruidoBruto(float2 p) {
    float2 d = (p - OFF) / ESC * ESCALA;     // coordenada do ruído menos a constante
    float2 r;
    if (MODO == 1 || MODO == 5) {
        bool cub = MODO == 5;
        r.x = cub ? fractal(true, B_XA, B_YA, d) : fractal(false, B_UA, B_VA, float2(d.x - d.y, d.x + d.y));
        r.y = cub ? fractal(true, B_XB, B_YB, d) : fractal(false, B_UB, B_VB, float2(d.x - d.y, d.x + d.y));
    } else if (MODO <= 7) {
        bool cub = MODO >= 5;
        float2 uv = float2(d.x - d.y, d.x + d.y);
        float n0 = cub ? fractal(true, B_XA, B_YA, d) : fractal(false, B_UA, B_VA, uv);
        float gy = n0 - (cub ? fractal(true, B_XA, B_YC, d) : fractal(false, B_UD, B_VD, uv));
        float gx = n0 - (cub ? fractal(true, B_XC, B_YA, d) : fractal(false, B_UC, B_VC, uv));
        r = (MODO == 2 || MODO == 6) ? float2(gx, gy) : float2(-gy, gx);
    } else {
        float col = fractal1D(B_XA, d.x);
        float lin = fractal1D(B_YA, d.y);
        r = MODO == 9 ? float2(0.0, col) : (MODO == 10 ? float2(lin, 0.0) : float2(lin, col));
    }
    return r;
}

// O campo: dx e dy em 16 bits cada (RGBA8), na faixa ±2.
static float4 empacotaCampo(float2 r) {
    float2 q = floor(clamp((r + 2.0) / 4.0, 0.0, 1.0) * 65535.0 + 0.5);
    float2 alto = floor(q / 256.0);
    return float4(alto.x, q.x - alto.x * 256.0, alto.y, q.y - alto.y * 256.0) / 255.0;
}
static float2 lerCampo(int2 i) {
    float4 c = floor(campo.read(uint2(i), uint(0)) * 255.0 + 0.5);
    return float2(c.r * 256.0 + c.g, c.b * 256.0 + c.a) / 65535.0 * 4.0 - 2.0;
}
/** As oitavas grossas no pixel `p`: bilinear à mão (empacotado não se filtra). */
static float2 campoEm(float2 p) {
    float2 u = p / FATOR;
    float2 f = fract(u);
    int2 i = int2(floor(u));
    int2 m = int2(int(campo.get_width()), int(campo.get_height())) - 1;
    float2 a = lerCampo(clamp(i, int2(0), m));
    float2 b = lerCampo(clamp(i + int2(1, 0), int2(0), m));
    float2 c = lerCampo(clamp(i + int2(0, 1), int2(0), m));
    float2 e = lerCampo(clamp(i + int2(1, 1), int2(0), m));
    return mix(mix(a, b, f.x), mix(c, e, f.x), f.y);
}

/** O u.deslocamento (dx, dy) do ruído no pixel `p` (índice do buffer), já com o Pinning. */
static float2 ruidoDoPixel(float2 p) {
    // Tudo no campo (o caso dos padrões): nenhuma oitava sobra para o pixel.
    float2 r = K_DE <= OITAVAS || (K_DE == OITAVAS + 1 && FRACAO > 0.0) ? ruidoBruto(p) : float2(0.0);
    if (K_CORTE > 0) r += campoEm(p);

    int pin = u.prender == 0 ? 1 : (u.prender <= 7 ? u.prender + 2 : u.prender + 3);
    if (pin > 2) {
        bool trava = pin >= 10;
        int k = (pin - 3) % 8;
        bool esq = k == 0 || k == 2 || k == 3;
        bool dir = k == 0 || k == 2 || k == 4;
        bool cima = k == 0 || k == 1 || k == 5;
        bool baixo = k == 0 || k == 1 || k == 6;
        // A faixa: o maior u.deslocamento possível × 4/3, até a metade da camada.
        float soma = 0.0;
        float a = 0.25;
        for (int i = 0; i < OITAVAS; i++) { soma += a; a *= 0.7; }
        soma += a * FRACAO;
        float m = AMT * 4.0 / 3.0 * soma;
        float mx = min(m, eng.acResolution.x * 0.5);
        float my = min(m, eng.acResolution.y * 0.5);
        float W = eng.acResolution.x;
        float H = eng.acResolution.y;
        if (esq && p.x < mx) { float f = fatorDaBorda(p.x, mx); r.x *= f; if (trava) r.y *= f; }
        if (dir && p.x > W - mx - 1.0) { float f = suaviza(1.0 - (p.x - (W - mx - 1.0)) / mx); r.x *= f; if (trava) r.y *= f; }
        if (cima && p.y < my) { float f = fatorDaBorda(p.y, my); r.y *= f; if (trava) r.x *= f; }
        if (baixo && p.y > H - my - 1.0) { float f = suaviza(1.0 - (p.y - (H - my - 1.0)) / my); r.y *= f; if (trava) r.x *= f; }
    }
    return r;
}

// ---------------------------------------------------------------------------------------------------
// ANTIALIASING HIGH SEM CALCULAR O RUÍDO TRÊS VEZES (09/10/2026: "travando/crashando meu celular").
// A caixa precisa do esticamento — o u.deslocamento do pixel e o dos vizinhos da direita e de baixo —, e
// cada um custava o ruído inteiro: Twist Smoother com Complexity 10 levava 190 ms por quadro na GPU do
// PC (segundos num celular, que derruba o app). Agora o passe 2 calcula o u.deslocamento de cada pixel UMA
// vez e guarda (dx e dy em 16 bits, na faixa da soma das amplitudes); o passe final lê os três. O
// vizinho que cai fora da camada (a última coluna e a última linha) é calculado direto.
// ---------------------------------------------------------------------------------------------------
static float alcanceTotal() {
    float soma = 0.0, amp = 0.25;
    for (int k = 1; k <= 11; k++) {
        if (k > OITAVAS + 1) break;
        soma += amp * (k <= OITAVAS ? 1.0 : FRACAO);
        amp *= 0.7;
    }
    return max(soma * 2.5, 1e-6);   // gradiente (Bulge/Twist): até 2 · 1,25 por oitava
}
static float4 empacotaDesl(float2 r) {
    float2 q = floor(clamp((r / alcanceTotal() + 1.0) * 0.5, 0.0, 1.0) * 65535.0 + 0.5);
    float2 alto = floor(q / 256.0);
    return float4(alto.x, q.x - alto.x * 256.0, alto.y, q.y - alto.y * 256.0) / 255.0;
}
static float2 lerDesl(int2 i) {
    float4 c = floor(desl.read(uint2(i), uint(0)) * 255.0 + 0.5);
    return (float2(c.r * 256.0 + c.g, c.b * 256.0 + c.a) / 65535.0 * 2.0 - 1.0) * alcanceTotal();
}

static float4 texel(int x, int y) {
    int2 t = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    if (x < 0 || y < 0 || x >= t.x || y >= t.y) return float4(0.0);
    float4 c = inputImg.read(uint2(int2(x, y)), uint(0));
    return float4(c.rgb * c.a, c.a);
}

static float4 reto(float4 pm) { return pm.a > 0.0 ? float4(pm.rgb / pm.a, pm.a) : float4(0.0); }

/** Bilinear pré-multiplicada; o centro do pixel no inteiro, fora = transparente. */
static float4 bilinear(float2 P) {
    float2 f0 = floor(P);
    float2 f = P - f0;
    int x = int(f0.x);
    int y = int(f0.y);
    float4 c = mix(mix(texel(x, y), texel(x + 1, y), f.x), mix(texel(x, y + 1), texel(x + 1, y + 1), f.x), f.y);
    return reto(c);
}

static float cobertura(float centro, float raio, float i) {
    return max(min(centro + raio, i + 0.5) - max(centro - raio, i - 0.5), 0.0);
}

/** Bilinear pré-multiplicada (sem voltar à cor reta), para a caixa grande. */
static float4 bilinearPm(float2 P) {
    float2 f0 = floor(P);
    float2 f = P - f0;
    int x = int(f0.x);
    int y = int(f0.y);
    return mix(mix(texel(x, y), texel(x + 1, y), f.x), mix(texel(x, y + 1), texel(x + 1, y + 1), f.x), f.y);
}

/**
 * A caixa do Antialiasing High: a média dos pixels pela área coberta. Até 12 × 12 pixels, exata. Maior que
 * isso (esticamento forte: até 65 × 65 = 4225 leituras POR PIXEL — segundos por quadro num celular, que
 * derruba o app), a média de 12 × 12 leituras bilineares espalhadas pela caixa: a mesma média, a menos do
 * detalhe menor que um pixel (09/10/2026).
 */
static float4 caixa(float2 P, float2 raio) {
    int x0 = int(floor(P.x - raio.x + 0.5));
    int x1 = int(floor(P.x + raio.x + 0.5));
    int y0 = int(floor(P.y - raio.y + 0.5));
    int y1 = int(floor(P.y + raio.y + 0.5));
    float4 soma = float4(0.0);
    if ((x1 - x0 + 1) * (y1 - y0 + 1) > 144) {
        for (int j = 0; j < 12; j++) {
            float sy = P.y - raio.y + (float(j) + 0.5) * raio.y / 6.0;
            for (int i = 0; i < 12; i++) {
                float sx = P.x - raio.x + (float(i) + 0.5) * raio.x / 6.0;
                soma += bilinearPm(float2(sx, sy));
            }
        }
        return reto(soma / 144.0);
    }
    for (int y = y0; y <= y1; y++) {
        float wy = cobertura(P.y, raio.y, float(y));
        if (wy <= 0.0) continue;
        for (int x = x0; x <= x1; x++) {
            float wx = cobertura(P.x, raio.x, float(x));
            if (wx > 0.0) soma += texel(x, y) * (wx * wy);
        }
    }
    return reto(soma / (4.0 * raio.x * raio.y));
}

fragment float4 fx_turbulent_displace(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant turbulent_displaceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> grade [[texture(1)]],
    texture2d<float> campo [[texture(2)]],
    texture2d<float> desl [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        int2 o = int2(__nv_fragCoord.xy);
        if (o.x < 64 && o.y < 64) { __nv_out = codifica(valorDaGrade(o.y * 64 + o.x)); return __nv_out; }
        int e = (o.y - 64) * 64 + o.x;
        if (o.y < 64 || e >= 14 * 11) { __nv_out = float4(0.0); return __nv_out; }
        int i;
        float f;
        comecar(centesimosDaBase(e / 11), i, f);
        // Limite FIXO e saída por `break`, como nas oitavas.
        for (int k = 0; k < 11; k++) { if (k > e % 11) break; avancar(i, f); }
        __nv_out = codificaConstante(i, f);
        return __nv_out;
    }

    // A camada CHEIA: no passe do campo o alvo é a metade, e o Offset e o pixel são da cheia.
    float2 cheia = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    // De ponta a ponta: o texel 0 cai no pixel 0 e o último texel no ÚLTIMO pixel (com
    // `cheia / campo` o último pixel ficava fora do campo e a bilinear "chutava": 2 px de erro).
    // No passe 1 o campo é o ALVO, e o motor não liga a textura que está sendo escrita: o `int2(int(campo.get_width()), int(campo.get_height()))` dele
    // devolvia o u.tamanho de outra (a camada), o FATOR virava 1 e o campo saía com o ruído de outro lugar — o "ao
    // soltar o slider o efeito reseta" (26/10/2026): parado, Size acima de ~50 já usa o campo; no arraste, na
    // metade, só acima de ~90. O u.tamanho do alvo é o `eng.acResolution`.
    float2 tamanhoDoCampo = eng.acPass == 1 ? eng.acResolution : float2(int2(int(campo.get_width()), int(campo.get_height())));
    FATOR = max(cheia - 1.0, float2(1.0)) / max(tamanhoDoCampo - 1.0, float2(1.0));
    ESC = max(eng.acEscalaDePixel, 1e-4);
    int codigos[9] = int[9](1, 2, 3, 5, 6, 7, 9, 10, 11);
    MODO = codigos[clamp(u.deslocamento, 0, 8)];
    float tam = max(u.tamanho, 2.0);
    ESCALA = 0.5 / tam * (MODO <= 3 ? 0.35355339 : 1.0);
    AMT = u.quantidade * tam * 0.05 * ESC;
    OITAVAS = int(floor(u.complexidade));
    FRACAO = u.complexidade - float(OITAVAS);
    OFF = u.offset * cheia;
    // As oitavas com onda de 96 px ou mais (no plano girado do Turbulent, a mais curta)
    // vão para o campo. Com 48 o erro da bilinear chegava a 0,2 px; com 96 fica na casa do
    // centésimo (conferido contra o AE). A mesma conta nos dois passes: os mesmos uniforms.
    float limite = ESC / (ESCALA * 1.41421356 * 96.0);
    K_CORTE = limite >= 1.77 ? min(int(floor(log(limite) / log(1.77))), OITAVAS + 1) : 0;

    if (eng.acPass == 1) {
        K_DE = 1;
        K_ATE = K_CORTE;
        float2 pc = floor(__nv_fragCoord.xy) * FATOR;   // o pixel da camada cheia deste texel
        __nv_out = empacotaCampo(K_CORTE > 0 ? ruidoBruto(pc) : float2(0.0));
        return __nv_out;
    }
    K_DE = K_CORTE + 1;
    K_ATE = 11;

    float2 p = floor(in.acScreenNorm * eng.acResolution);
    if (eng.acPass == 2) { __nv_out = empacotaDesl(ruidoDoPixel(p)); return __nv_out; }

    // O ponto lido e, com o Antialiasing High, os dos vizinhos. UMA chamada ao ruído no passe (o compilador
    // copia o ruído fractal inteiro em cada chamada; com várias, a compilação pode travar o driver do
    // celular): com o Antialiasing High os três vêm do passe 2, menos o vizinho fora da camada.
    if (u.antialias == 0) {
        __nv_out = bilinear(p + AMT * ruidoDoPixel(p));
        return __nv_out;
    }
    int2 t = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float2 Q[3];
    for (int k = 0; k < 3; k++) {
        float2 q = p + (k == 1 ? float2(1.0, 0.0) : (k == 2 ? float2(0.0, 1.0) : float2(0.0)));
        int2 i = int2(q);
        Q[k] = q + AMT * (i.x < t.x && i.y < t.y ? lerDesl(i) : float2(0.0));
    }
    // O vizinho fora da camada (última coluna/linha): calculado direto — uma chamada, só na borda.
    bool foraX = int(p.x) + 1 >= t.x, foraY = int(p.y) + 1 >= t.y;
    if (foraX || foraY) {
        float2 q = p + (foraX ? float2(1.0, 0.0) : float2(0.0, 1.0));
        float2 Qf = q + AMT * ruidoDoPixel(q);
        if (foraX) Q[1] = Qf; else Q[2] = Qf;
        if (foraX && foraY) Q[2] = p + float2(0.0, 1.0) + (Qf - q);   // o canto: os dois vizinhos fora (raro)
    }
    // O esticamento: quanto o ponto lido anda de um pixel ao vizinho.
    float2 raio = clamp(0.5 * max(abs(Q[1] - Q[0]), abs(Q[2] - Q[0])), float2(0.5), float2(32.0));
    __nv_out = caixa(Q[0], raio);
    return __nv_out;
}
