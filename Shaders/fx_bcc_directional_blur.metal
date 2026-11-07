// ---------------------------------------------------------------------------
// BCC Directional Blur
// origem : assets/effects/bcc-directional-blur.xml
// id     : nova.effect.bccdirectionalblur
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bcc_directional_blurParams {
    float blurAmount;
    float angle;
    float thin;
};

// --- funcoes auxiliares do efeito
// float32(3.141593 / 180): a constante de graus do plugin. Com π/180 exato o traço a 45° sai de 1 px;
// o AE dá o padrão de uma tangente de 1,0000001 (tools/bccdirectionalblur/benchmark, "45 graus").
const float GRAUS = 0.017453294;
const int CABECALHO = 1;                // texels de cabeçalho no buffer do núcleo
const int ENTRADAS_DO_RASCUNHO = 128;   // na prévia em movimento (`eng.acRascunho`), quantas entradas do núcleo a soma lê
const int MEIA_MAXIMA = 2000;

// Cosseno, seno e tangente EXATOS (os do ucrtbase.dll, que é quem o plugin chama) para todo Angle inteiro de −360
// a 720: `assets/bccdb/graus.png`, uma linha por grau, 12 bytes = 3 float32 (tools/bccdirectionalblur/benchmark/
// gerar_tabela.py). O desenho do traço depende do último bit desses números, e a GPU não devolve os mesmos.
const int TABELA_DE = -360;
const int TABELA_ATE = 720;

float daTabela(int linha, int k) {          // o k-ésimo float32 da linha
    int b = 4 * k;
    int3 t0 = int3(graus.read(uint2(int2(b / 3, linha)), uint(0)).rgb * 255.0 + 0.5);
    int3 t1 = int3(graus.read(uint2(int2(b / 3 + 1, linha)), uint(0)).rgb * 255.0 + 0.5);
    int o = b - (b / 3) * 3;
    int v[6] = int[6](t0.r, t0.g, t0.b, t1.r, t1.g, t1.b);
    uint bits = uint(v[o]) | (uint(v[o + 1]) << 8) | (uint(v[o + 2]) << 16) | (uint(v[o + 3]) << 24);
    return as_type<float>(bits);
}

int2 gT;                 // o quadro, em px
float gC;                 // 1 / (2 σ²)
int gMeia0;               // a meia-largura do laço (antes da escada e dos cortes)
int gMeia;                // a final
int gN;                   // 2 · meia − 1
bool gPente; int gPasso; float gFrac;
float gCs, gSn, gTg;
int gW2, gH2, gCx, gCy;
bool gEmPe, gVale;

int cru(int j) { return int(exp(-float(j * j) * gC) * 100.0); }
int bruto(int j) { return j >= gMeia0 ? 0 : cru(j); }

// trunc(a · (1 − f) + float(b) · f) como o plugin faz: o segundo produto em float, a soma em double.
// Aqui em inteiros: (1 − f) é múltiplo de 2^-24.
int misturar(int a, int b, float f) {
    float um = 1.0 - f;
    int qn = a * int(um * 16777216.0);
    int inteiro = qn >> 24;
    int resto = qn & 16777215;
    float p = float(b) * f;
    float pi = floor(p);
    int vai = (resto > 0 && (p - pi) >= float(16777216 - resto) / 16777216.0) ? 1 : 0;
    return inteiro + int(pi) + vai;
}

// A escada de 100 níveis (só com mais de 100 pesos).
int nivel(int k) {
    if (k <= 0) return 100;
    if (k >= 100) return 0;
    float x = float(k) * float(gMeia0);
    x = x * 0.01;
    int i0 = int(x);
    return misturar(bruto(i0), bruto(i0 + 1), x - float(i0));
}

int escada(int j) {
    int v = bruto(j);
    if (gMeia0 <= 100) return v;
    // o primeiro nível k com v > (nível[k] + nível[k + 1]) / 2. A varredura começa do 0: os níveis NÃO descem
    // sempre (a mistura de dois pesos iguais às vezes trunca um a menos), e um nível "baixo demais" lá atrás decide.
    int k = 0;
    int a = nivel(k);
    for (int i = 0; i < 100; i++) {
        if (k >= 100) break;
        int b = nivel(k + 1);
        if (v > (a + b) / 2) return a;
        a = b;
        k++;
    }
    return 0;
}

// O núcleo 1D final: a escada e o pente do Thin.
int nucleo1d(int i) {
    int j = i - (gMeia - 1);
    if (j < 0) j = -j;
    int q = escada(j);
    if (!gPente) return q;
    int a = (j % gPasso) == 0 ? q : 0;
    int b = (j % (gPasso + 1)) == 0 ? q : 0;
    float x = float(a) * (1.0 - gFrac);
    float y = float(b) * gFrac;
    return int(x + y);
}

// O 1D numa posição quebrada.
int em(float t) {
    if (!(t > -1.0)) return 0;
    if (t > float(gN)) return 0;
    if (t < 0.0) return int((t + 1.0) * float(nucleo1d(0)));
    if (t > float(gN - 1)) return int(float(nucleo1d(gN - 1)) * (float(gN) - t));
    float ft = floor(t);
    int i = int(ft);
    return misturar(nucleo1d(i), i + 1 < gN ? nucleo1d(i + 1) : 0, t - ft);
}

// trunc(k · d) exato, com 0 < d <= 1 e k de 0 a 100 (no plugin, em double).
int vezes(int k, float d) {
    if (k == 0 || !(d > 0.0)) return 0;
    int s = 0;
    for (int i = 0; i < 7; i++) {
        if (d >= 0.5) break;
        d *= 2.0;
        s++;
    }
    if (d < 0.5) return 0;
    return (k * int(d * 16777216.0)) >> (24 + s);
}

void preparar() {
    gT = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gVale = false;
    float escala = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
    float r = u.blurAmount * escala;
    if (!(r > 0.0)) return;
    gC = 1.0 / ((r + r) * r);

    // a meia-largura: o primeiro j >= 1 com peso menor que 1 (perto de σ · √(2 ln 100))
    gMeia0 = MEIA_MAXIMA;
    int j = max(int(r * 3.0348544) - 3, 1);
    for (int i = 0; i < 12; i++) {
        if (j >= MEIA_MAXIMA) break;
        if (cru(j) < 1) { gMeia0 = j; break; }
        j++;
    }
    gMeia = gMeia0;
    for (int i = 0; i < 64; i++) {
        if (gMeia < 1 || escada(gMeia - 1) != 0) break;
        gMeia--;
    }
    gMeia = min(gMeia, gT.x / 2 - 1);
    gMeia = max(1, min(gMeia, gT.y / 2 - 1));
    gN = 2 * gMeia - 1;
    if (gN <= 1) return;

    // o Thin: o passo das amostras (no render final o plugin não impõe o mínimo de 3)
    float passo = escala * u.thin;
    passo = passo + 1.0;
    passo = min(float(gN - 1), passo);
    gPente = passo > 1.0;
    if (gPente) {
        passo = min(float(gMeia - 1), passo);
        gPasso = int(passo);
        gFrac = passo - float(gPasso);
        if (gPasso < 1) gPente = false;
    }

    float g = u.angle - 90.0;
    if (u.angle == floor(u.angle) && u.angle >= float(TABELA_DE) && u.angle <= float(TABELA_ATE) && int2(int(graus.get_width()), int(graus.get_height())).y > TABELA_ATE - TABELA_DE) {
        int linha = int(u.angle) - TABELA_DE;
        gCs = daTabela(linha, 0);
        gSn = daTabela(linha, 1);
        gTg = daTabela(linha, 2);
    } else {
        float th = g * GRAUS;
        gCs = cos(th);
        gSn = sin(th);
        gTg = abs(gCs) > 0.001 ? tan(th) : gSn * 1000.0;
    }
    gW2 = max(int(float(gN + 1) * abs(gCs)), 2) + 1;
    gH2 = max(int(float(gN + 1) * abs(gSn)), 2) + 1;
    if (gH2 % 2 == 0) gH2++;
    if (gW2 % 2 == 0) gW2++;
    gH2 = min(gH2, (gT.y - 1) / 2);
    gW2 = min(gW2, (gT.x - 1) / 2);
    gCy = gH2 / 2;
    gCx = gW2 / 2;
    gEmPe = gH2 > gW2;
    gVale = gH2 >= 1 && gW2 >= 1;
}

// O peso da célula (linha r, coluna c) da grade, a uma distância d (< 1) do traço.
int celula(int r, int c, float d) {
    float a1 = float(c - gCx) * gCs;
    float a2 = gSn * float(r - gCy);
    float t = a1 + a2;
    t = t + float(gMeia - 1);
    int v = em(t);
    if (gEmPe) v = vezes(v, 1.0 - d);
    if (v == 0 && r == gCy && c == gCx) v = 1;      // o centro leva pelo menos 1
    return v;
}

// A entrada i do núcleo: os dois pesos e onde começam (em relação ao centro).
void entrada(int i, out int wa, out int wb, out int inicio) {
    wa = 0;
    wb = 0;
    if (!gEmPe) {
        float yl = float(i - gCx) * gTg;
        yl = yl + float(gCy);
        int base = int(floor(yl));
        inicio = base - gCy;
        for (int q = 0; q < 2; q++) {
            int r = base + q;
            if (r < 0 || r >= gH2) continue;
            float d = abs(float(r) - yl);
            if (d >= 1.0) continue;
            int v = celula(r, i, d);
            if (q == 0) wa = v; else wb = v;
        }
    } else {
        float inv = 1.0 / gTg;
        float xl = float(i - gCy) * inv;
        xl = xl + float(gCx);
        int base = int(floor(xl));
        inicio = base - gCx;
        for (int q = 0; q < 2; q++) {
            int c = base + q;
            if (c < 0 || c >= gW2) continue;
            float d = abs(float(c) - xl);
            if (d >= 1.0) continue;
            int v = celula(i, c, d);
            if (q == 0) wa = v; else wb = v;
        }
    }
}

// A soma pesada -> o nível: M = 2^23 / soma, deslocar 23 bits, devolvendo o resto (× 256) quando cabe.
int dividir(int acc, int soma) {
    int m = 8388608 / soma;
    int resto = 8388608 - m * soma;
    if (resto <= 32767) return (acc * m + resto * 256) >> 23;
    return acc / soma;
}

// piso((alto · 65536 + baixo) / a), exato: a soma pesada pelo alfa não cabe em 32 bits (vai em duas palavras).
// O quociente é um nível (0 a 255): a conta em float acha o candidato e o resto em inteiros acerta.
int dividirLongo(int alto, int baixo, int a) {
    alto += baixo >> 16;
    baixo = baixo & 65535;
    int q = clamp(int((float(alto) * 65536.0 + float(baixo)) / float(a)), 0, 255);
    int aAlto = a >> 16;
    int aBaixo = a & 65535;
    for (int i = 0; i < 4; i++) {
        int resto = (alto - q * aAlto) * 65536 + (baixo - q * aBaixo);
        if (resto < 0) q--;
        else if (resto >= a) q++;
        else break;
    }
    return clamp(q, 0, 255);
}

float4 bytes2(int v) { return float4(float(v / 256), float(v % 256), 0.0, 255.0) / 255.0; }
int ler2(float4 v) { return int(v.r * 255.0 + 0.5) * 256 + int(v.g * 255.0 + 0.5); }

fragment float4 fx_bcc_directional_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bcc_directional_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> nucleo [[texture(1)]],
    texture2d<float> graus [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        // ---- o núcleo: texel 0 = quantas entradas e se o traço está em pé; depois, 2 texels por entrada
        int2 alvo = int2(eng.acResolution);
        int2 p = min(int2(floor(in.acScreenNorm * eng.acResolution)), alvo - int2(1));
        int idx = p.y * alvo.x + p.x;
        __nv_out = float4(0.0, 0.0, 0.0, 1.0);
        int2 quadro = int2(int(inputImg.get_width()), int(inputImg.get_height()));
        if (idx > CABECALHO + max(quadro.x, quadro.y) + 2) return __nv_out;
        preparar();
        int n = gVale ? (gEmPe ? gH2 : gW2) : 0;
        if (CABECALHO + 2 * n > alvo.x * alvo.y) n = 0;
        if (idx == 0) {
            __nv_out = float4(float(n / 256), float(n % 256), gEmPe ? 255.0 : 0.0, 255.0) / 255.0;
            return __nv_out;
        }
        int e = (idx - CABECALHO) / 2;
        if (e >= n) return __nv_out;
        int wa, wb, inicio;
        entrada(e, wa, wb, inicio);
        if ((idx - CABECALHO) % 2 == 0) __nv_out = float4(float(wa), float(wb), 0.0, 255.0) / 255.0;
        else __nv_out = bytes2(inicio + 2048);
        return __nv_out;
    }

    // ---- a soma
    gT = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 t = min(int2(floor(in.acScreenNorm * float2(gT))), gT - int2(1));
    float4 s = inputImg.read(uint2(t), uint(0));
    int2 ts = int2(int(nucleo.get_width()), int(nucleo.get_height()));
    float4 cab = nucleo.read(uint2(int2(0)), uint(0));
    int n = ler2(cab);
    if (n < 1) {
        __nv_out = s;
        return __nv_out;
    }
    bool emPe = cab.b > 0.5;
    int centro = n / 2;
    // O rascunho do play/arraste: até ~128 entradas, de `salto` em `salto`, passando pelo centro.
    int salto = eng.acRascunho == 1 ? max(1, (n + ENTRADAS_DO_RASCUNHO - 1) / ENTRADAS_DO_RASCUNHO) : 1;

    int den = 0;
    int accA = 0;
    int3 accC = int3(0);
    int3 accAlto = int3(0);       // Σ peso · alfa · cor, em duas palavras de 16 bits
    int3 accBaixo = int3(0);
    for (int i = centro % salto; i < n; i += salto) {
        int e = CABECALHO + 2 * i;
        float4 w = nucleo.read(uint2(int2(e % ts.x, e / ts.x)), uint(0));
        int wa = int(w.r * 255.0 + 0.5);
        int wb = int(w.g * 255.0 + 0.5);
        if (wa == 0 && wb == 0) continue;
        int inicio = ler2(nucleo.read(uint2(int2((e + 1) % ts.x, (e + 1) / ts.x)), uint(0))) - 2048;
        for (int q = 0; q < 2; q++) {
            int wq = q == 0 ? wa : wb;
            if (wq == 0) continue;
            // saída(x) = Σ peso(d) · fonte(x + d), com d = (dx, dy) e a linha crescendo para baixo
            int2 d = emPe ? int2(inicio + q, i - centro) : int2(i - centro, inicio + q);
            int2 p = t + d;
            if (p.x < 0 || p.y < 0 || p.x >= gT.x || p.y >= gT.y) continue;
            int4 c = int4(inputImg.read(uint2(p), uint(0)) * 255.0 + 0.5);
            den += wq;
            accA += wq * c.a;
            accC += wq * c.rgb;
            int3 pa = (wq * c.a) * c.rgb;
            accAlto += pa >> 16;
            accBaixo += pa & 65535;
        }
    }
    if (den == 0) {
        __nv_out = s;
        return __nv_out;
    }
    int a = dividir(accA, den);
    float3 cor;
    if (a == 0) cor = float3(0.0);
    else if (accA == 255 * den) cor = float3(float(dividir(accC.r, den)), float(dividir(accC.g, den)), float(dividir(accC.b, den)));
    else cor = float3(float(dividirLongo(accAlto.r, accBaixo.r, accA)), float(dividirLongo(accAlto.g, accBaixo.g, accA)),
                    float(dividirLongo(accAlto.b, accBaixo.b, accA)));
    __nv_out = float4(cor, float(a)) / 255.0;
    return __nv_out;
}
