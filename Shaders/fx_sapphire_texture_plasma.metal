// ---------------------------------------------------------------------------
// S_TexturePlasma
// origem : assets/effects/sapphire-texture-plasma.xml
// id     : nova.effect.stextureplasma
// passes : 16
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_texture_plasmaParams {
    float noiseFrequency;
    float noiseFreqRelX;
    float noiseOctaves;
    float noiseSeed;
    float addGradX;
    float addGradY;
    float layers;
    float threshold;
    float2 shift;
    float phaseStart;
    float phaseSpeed;
    float brightness;
    float4 color;
    float glowBrightness;
    float4 glowColor;
    float glowWidth;
    float glowWidthRed;
    float glowWidthGrn;
    float glowWidthBlue;
    float bgBrightness;
    int combine;
    int inputOpacity;
    int outputOpacity;
};

// --- funcoes auxiliares do efeito
const int BLOCO = 16;              // pixels por soma parcial do glow
const int RAIO_MAX = 1280;         // o maior raio de uma caixa (largura de um canal até 3840 px)

// O AE guarda os controles do Sapphire em passos de 1/65536 (truncados): 0,12 -> 0,1199951.
float q16(float v) { return floor(v * 65536.0) / 65536.0; }
// As cores valem em 8 bits (meio para cima).
float3 cor8(float3 c) { return floor(c * 255.0 + 0.5) / 255.0; }
// 2^k exato (o exp2 da GPU não garante).
float pot2(int k) { return as_type<float>((127 + k) << 23); }

// ---- a camada do AE no buffer --------------------------------------------------------------
int2 gT;          // o buffer
int2 gN;          // a camada do AE dentro dele, em px
int2 gInicio;     // o canto da camada no buffer

void preparar() {
    gT = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gN = clamp(int2(floor(max(eng.acCamada, float2(0.001)) * float2(gT) + 0.5)), int2(1), gT);
    gInicio = (gT - gN) / 2;
}

bool naCamada(int2 q) { return q.x >= 0 && q.y >= 0 && q.x < gN.x && q.y < gN.y; }

// ---------------------------------------------------------------------------------------------------------
// O hash do Sapphire (a tabela de assets/filmdamage/tabelas.png, linha 6: cada número de 32 bits em dois texels
// da mesma coluna, bytes 0-2 em RGB e o byte 3 no R da linha de baixo).
// ---------------------------------------------------------------------------------------------------------
uint ler32(int x, int linha) {
    uint3 a = uint3(floor(tabelas.read(uint2(int2(x, linha)), uint(0)).rgb * 255.0 + 0.5));
    uint b = uint(floor(tabelas.read(uint2(int2(x, linha + 1)), uint(0)).r * 255.0 + 0.5));
    return a.x | (a.y << 8) | (a.z << 16) | (b << 24);
}

uint rodadas(uint c) {
    for (int i = 0; i < 4; i++) c = (c >> 8) + ler32(int(c & 255u), 6);
    return c;
}

// O valor da grade: ((hash & 0x1fff) − 4096) / 4096, com a linha negada (o y do código cresce para baixo).
float valorDaLinha(uint linha, int coluna) {
    uint h = rodadas(linha + uint(coluna));
    return float(int(h & 0x1fffu) - 4096) * (1.0 / 4096.0);
}

// ---------------------------------------------------------------------------------------------------------
// O núcleo de k subdivisões da B-spline cúbica: K_k(d) = B4_n(d + 2(n − 1)) / n³, n = 2^k, B4_n(m) = de quantos
// jeitos m é a soma de 4 inteiros em 0..n−1 (simétrico em 2(n − 1); na metade de baixo, C(m+3, 3) − 4·C(m−n+3, 3)).
// ---------------------------------------------------------------------------------------------------------
float c3(float x) { return x >= 3.0 ? x * (x - 1.0) * (x - 2.0) * (1.0 / 6.0) : 0.0; }

float nucleo(int d, int k) {
    int n = 1 << k;
    int m = d + 2 * (n - 1);
    int topo = 4 * (n - 1);
    if (m < 0 || m > topo) return 0.0;
    m = min(m, topo - m);
    return (c3(float(m + 3)) - 4.0 * c3(float(m - n + 3))) * pot2(-3 * k);
}

// O laço do código num eixo: quantas subdivisões cabem (enquanto 2n − 3 ≤ lado) e o lo/hi/X0 do último nível.
struct Eixo { int L; float lo; float hi; int X0; };

Eixo eixo(int lado, float lo, float hi) {
    int X0 = int(floor(lo)) - 1;
    int X1 = int(ceil(hi)) + 1;
    if (X1 - X0 + 1 > lado) X1 = X0 + lado - 1;
    bool anda = hi - lo > 0.0;
    int L = 0;
    for (int k = 0; k < 30; k++) {
        if (!anda || 2 * (X1 - X0 + 1) - 3 > lado) break;
        lo += lo; hi += hi;
        X0 = int(floor(lo)) - 1;
        X1 = int(ceil(hi)) + 1;
        L++;
    }
    return Eixo(L, lo, hi, X0);
}

/**
 * A posição do pixel i (de n) no último nível: pos = ini + i·passo, SOMADA como no código — os pares acumulam
 * p += 2·passo em float32 e o ímpar é passo + p. Dentro de uma faixa de expoente o passo arredondado é constante
 * (no empate de meio ulp, o primeiro passo vai ao par e os outros ficam iguais), então dá para pular a faixa
 * inteira de uma vez. Devolve o ponto da grade (c) e a fração.
 */
void posicao(int i, int n, Eixo e, out int c, out float f) {
    int r = 2 * e.X0 + 1;
    float ini = (e.lo + e.lo) - float(r);
    float fim = (e.hi + e.hi) - float(r);
    float passo = (fim - ini) / float(n);
    float d = passo * 2.0;
    float P = ini;
    int m = i >> 1;
    const int TOPO = 1 << 24;
    for (int k = 0; k < 64 && m > 0; k++) {
        uint bits = as_type<uint>(P);
        int ex = int((bits >> 23) & 255u) - 127;
        int Pu = int((bits & 0x7fffffu) | 0x800000u);
        float x = d * pot2(23 - ex);
        float sf = floor(x);
        float fr = x - sf;
        int su = int(sf);
        if (fr == 0.5) {
            if ((Pu & 1) == 1) {
                int Pn = Pu + su + ((Pu + su) & 1);
                if (Pn >= TOPO) { P = P + d; m--; continue; }
                Pu = Pn; m--;
                if (m == 0) { P = float(Pu) * pot2(ex - 23); break; }
            }
            su += su & 1;
        } else if (fr > 0.5) su++;
        su = max(su, 1);
        int dentro = max(0, (TOPO - Pu + su - 1) / su - 1);
        if (m <= dentro) { P = float(Pu + m * su) * pot2(ex - 23); m = 0; }
        else { P = float(Pu + dentro * su) * pot2(ex - 23); m -= dentro; P = P + d; m--; }
    }
    float pos = (i & 1) == 0 ? P : passo + P;
    float fl = floor(pos);
    c = r + int(fl);
    f = pos - fl;
}

// Os 5 pesos (já interpolados entre c e c + 1) da grade do nível F − k, a partir do índice i0.
void pesos(int c, float f, int k, out int i0, out float w[5]) {
    int n = 1 << k;
    i0 = -((2 * (n - 1) - c) >> k);         // ceil((c − 2(n − 1)) / n)
    for (int u = 0; u < 5; u++) {
        int b = n * (i0 + u);
        w[u] = (1.0 - f) * nucleo(c - b, k) + f * nucleo(c + 1 - b, k);
    }
}

// O viés de um eixo: os 2⁻¹⁴ postos nos vértices (pontos pares) de cada nível, levados até o fim; os de antes do
// 0,5·v + 0,5 valem a metade.
float vies(int c, float f, int L) {
    int F = L + 1;
    float tot = 0.0;
    for (int l = 1; l <= F; l++) {
        int k = F - l;
        int n = 1 << k;
        float s = 0.0;
        for (int lado = 0; lado < 2; lado++) {
            int cc = c + lado;
            int t0 = -((2 * (n - 1) - cc) >> (k + 1));
            float soma = 0.0;
            for (int u = 0; u < 3; u++) soma += nucleo(cc - 2 * n * (t0 + u), k);
            s += (lado == 0 ? 1.0 - f : f) * soma;
        }
        tot += s * (l <= L ? 0.5 : 1.0);
    }
    return tot * (1.0 / 16384.0);
}

/** O `noise` do Sapphire (0..1) no pixel p (do canto de cima, na camada de W × H). */
float ruidoDoSapphire(int2 p, int W, int H) {
    float a = float(H) / float(W);
    float fx = (q16(u.noiseFrequency) * q16(u.noiseFreqRelX)) * 2.0;
    float fy = q16(u.noiseFrequency) * 2.0;
    int semente = int(4096.0 * q16(u.noiseSeed));
    int oitavas = int(clamp(floor(u.noiseOctaves + 0.5), 1.0, 10.0));
    float Nx = W > 4 ? min(abs(fx), float((W - 4) >> 1)) : 0.0;
    float Ny = H > 4 ? min(abs(fy), float(H - 4) / (2.0 * a)) : 0.0;
    // O Shift em unidades do Sapphire (a largura vale 2; y para baixo, como o código usa).
    float ox = (u.shift.x - 0.5) * 2.0;
    float oy = (u.shift.y - 0.5) * 2.0 * a;
    Eixo ex = eixo(W, (-1.0 - ox) * Nx, Nx * (1.0 - ox));
    Eixo ey = eixo(H, -(a + oy) * Ny, Ny * (a - oy));
    int cx, cy; float tx, ty;
    posicao(p.x, W, ex, cx, tx);
    posicao(p.y, H, ey, cy, ty);

    float soma = 0.0;
    int ultima = min(oitavas - 1, min(ex.L, ey.L));
    for (int o = 0; o <= ultima; o++) {
        int ix, iy;
        float wx[5], wy[5];
        pesos(cx, tx, ex.L + 1 - o, ix, wx);
        pesos(cy, ty, ey.L + 1 - o, iy, wy);
        uint sem = uint(semente ^ o);
        float s = 0.0;
        for (int v = 0; v < 5; v++) {
            if (wy[v] == 0.0) continue;
            uint linha = rodadas((uint(-(iy + v)) << 4) ^ sem);
            float sl = 0.0;
            for (int u = 0; u < 5; u++) {
                if (wx[u] == 0.0) continue;
                sl += wx[u] * valorDaLinha(linha, ix + u);
            }
            s += wy[v] * sl;
        }
        soma += s * pot2(-o);
    }
    return 0.5 * soma + 0.5 + vies(cx, tx, ex.L) + vies(cy, ty, ey.L);
}

/** O pic² do pixel p da camada (linha 0 em cima), com o `noise` n dele. */
float picAoQuadrado(int2 p, float n) {
    int W = gN.x, H = gN.y;
    // `xy`: x de −1 a 1 na largura, y para CIMA, no centro do pixel
    float x = (float(p.x) + 0.5) * 2.0 / float(W) - 1.0;
    float y = float(H) / float(W) - (float(p.y) + 0.5) * 2.0 / float(W);
    float fase = q16(u.phaseStart) + q16(u.phaseSpeed) * eng.acTime;
    float v = (x * q16(u.addGradX) + y * q16(u.addGradY) + n) * (q16(u.layers) * 2.0) + fase * 2.0;
    // bounce: a dobra em triângulo de período 2
    float m = v - 2.0 * floor(v * 0.5);
    float r = m > 1.0 ? 2.0 - m : m;
    float th = q16(u.threshold);
    float pic = clamp((r - th) / max(0.01, 1.0 - th), 0.0, 1.0);
    return pic * pic;
}

// ---- números em buffers de 8 bits ----------------------------------------------------------
// O float inteiro (os 4 bytes): a ida e a volta pelo RGBA8 são exatas.
float4 gravarFloat(float v) {
    uint u = as_type<uint>(v);
    return float4(float(u & 255u), float((u >> 8) & 255u), float((u >> 16) & 255u), float(u >> 24)) / 255.0;
}

float lerFloat(float4 c) {
    uint4 b = uint4(floor(c * 255.0 + 0.5));
    return as_type<float>(b.x | (b.y << 8) | (b.z << 16) | (b.w << 24));
}

float4 gravar24(float v) {
    float a = floor(clamp(v, 0.0, 1.0) * 16777215.0 + 0.5);
    float b0 = floor(a / 65536.0);
    float r = a - b0 * 65536.0;
    float b1 = floor(r / 256.0);
    return float4(b0, b1, r - b1 * 256.0, 255.0) / 255.0;
}

float ler24(float4 v) {
    float3 b = floor(v.rgb * 255.0 + 0.5);
    return (b.x * 65536.0 + b.y * 256.0 + b.z) / 16777215.0;
}

// Dois números de 0..1 em 16 bits cada (o erro de uma caixa fica em 1e-5; nas seis, ~0,05 nível no pior caso).
float4 gravar16(float a, float b) {
    float2 q = floor(clamp(float2(a, b), 0.0, 1.0) * 65535.0 + 0.5);
    float2 alto = floor(q / 256.0);
    return float4(alto.x, q.x - alto.x * 256.0, alto.y, q.y - alto.y * 256.0) / 255.0;
}

float2 ler16(float4 c) {
    float4 b = floor(c * 255.0 + 0.5);
    return float2(b.x * 256.0 + b.y, b.z * 256.0 + b.w) / 65535.0;
}

// ---- o ruído guardado entre quadros ----------------------------------------------------------
// O que muda o `noise`: se tudo isto é igual ao do quadro anterior, ele é copiado.
const int N_ASSINATURA = 10;

float assinado(int k) {
    if (k == 0) return u.noiseFrequency;
    if (k == 1) return u.noiseFreqRelX;
    if (k == 2) return u.noiseOctaves;
    if (k == 3) return u.noiseSeed;
    if (k == 4) return u.shift.x;
    if (k == 5) return u.shift.y;
    if (k == 6) return float(gN.x);
    if (k == 7) return float(gN.y);
    if (k == 8) return float(eng.acEntradaDePe);
    return 1.0;                              // 9: há assinatura (o estado novo vem zerado)
}

// Sem olhar o eng.acStateFresh: os dois estados são `memory="cache"` (o motor entrega o último escrito, com o tempo
// parado, andando ou pulando), e o estado que nunca foi escrito vem zerado — o 9 da assinatura não bate.
bool mesmaAssinatura() {
    for (int k = 0; k < N_ASSINATURA; k++) {
        if (lerFloat(assinatura.read(uint2(int2(k & 7, k >> 3)), uint(0))) != assinado(k)) return false;
    }
    return true;
}

// ---- o glow ----------------------------------------------------------------------------------
// A largura de cada canal em px do buffer, arredondada (meio para cima), e os raios das três caixas, da menor
// para a maior: (w + i) div 3.
int3 larguras() {
    float3 w = q16(u.glowWidth) * float3(q16(u.glowWidthRed), q16(u.glowWidthGrn), q16(u.glowWidthBlue));
    float e = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
    return int3(clamp(floor(w * e + 0.5), float3(0.0), float3(float(3 * RAIO_MAX))));
}

int3 raios(int qual) { return (larguras() + qual) / 3; }

// DOIS PIXELS POR TEXEL: os buffers do glow (sR.., fR.., gR..) têm um canal cada, e o texel (j, i) guarda os
// pixels (2j, i) e (2j + 1, i) da camada, em 16 bits cada, a partir do CANTO do buffer (não do gInicio). Cada
// leitura traz dois valores úteis — antes trazia um. Fora da camada (o pixel 2j + 1 de uma largura ímpar, os
// texels depois da metade), zero: a borda transparente corta a cada caixa.
int metade() { return (gN.x + 1) >> 1; }

// O texel j da entrada da caixa `etapa` (1..5) no canal c: o resultado da anterior (fR.. depois das etapas 0, 2,
// 4; gR.. depois das 1, 3).
float4 texelDaEntrada(int etapa, int c, int2 j) {
    if ((etapa & 1) == 1) {
        if (c == 0) return fR.read(uint2(j), uint(0));
        if (c == 1) return fG.read(uint2(j), uint(0));
        return fB.read(uint2(j), uint(0));
    }
    if (c == 0) return gR.read(uint2(j), uint(0));
    if (c == 1) return gG.read(uint2(j), uint(0));
    return gB.read(uint2(j), uint(0));
}

// O pixel p (de dentro da camada) da entrada: o pic² na 1ª caixa, o resultado da anterior nas outras.
float pixelDaEntrada(int etapa, int c, int2 p) {
    if (etapa == 0) return ler24(ruido.read(uint2(p + gInicio), uint(0)));
    float2 d = ler16(texelDaEntrada(etapa, c, int2(p.x >> 1, p.y)));
    return (p.x & 1) == 0 ? d.x : d.y;
}

// A soma de BLOCO pixels seguidos a partir de x (de dentro da camada), guardada no passe anterior como média.
float blocoEm(int etapa, int c, int x, int y) {
    int2 j = int2(x >> 1, y);
    float4 v = (etapa == 0 || c == 0) ? sR.read(uint2(j), uint(0)) : c == 1 ? sG.read(uint2(j), uint(0)) : sB.read(uint2(j), uint(0));
    float2 d = ler16(v);
    return ((x & 1) == 0 ? d.x : d.y) * float(BLOCO);
}

// As somas de BLOCO pixels seguidos (como média, para caber em 0..1) a partir dos dois pixels do texel j, em x:
// os BLOCO + 1 pixels vêm de BLOCO / 2 + 1 texels. Cada soma na ordem dos pixels.
float2 somasEmX(int etapa, int c, int2 j) {
    float s0 = 0.0, s1 = 0.0;
    if (etapa == 0) {
        int x0 = 2 * j.x;
        for (int k = 0; k <= BLOCO; k++) {
            int x = x0 + k;
            float v = x < gN.x ? ler24(ruido.read(uint2(int2(x, j.y) + gInicio), uint(0))) : 0.0;
            if (k < BLOCO) s0 += v;
            if (k > 0) s1 += v;
        }
    } else {
        for (int k = 0; k <= BLOCO / 2; k++) {
            float2 d = j.x + k < metade() ? ler16(texelDaEntrada(etapa, c, int2(j.x + k, j.y))) : float2(0.0);
            if (k < BLOCO / 2) { s0 += d.x; s0 += d.y; }
            if (k > 0) s1 += d.x;
            if (k < BLOCO / 2) s1 += d.y;
        }
    }
    return float2(s0, s1) * (1.0 / float(BLOCO));
}

// Em y, as duas colunas do texel andam juntas: cada leitura serve às duas.
float2 somasEmY(int etapa, int c, int2 j) {
    float2 s = float2(0.0);
    for (int k = 0; k < BLOCO; k++) {
        if (j.y + k < gN.y) s += ler16(texelDaEntrada(etapa, c, int2(j.x, j.y + k)));
    }
    return s * (1.0 / float(BLOCO));
}

// A caixa de raio r nos dois pixels do texel j, em x: a média de x − r .. x + r. Fora da camada vale zero, então
// só a parte de dentro é somada — em somas de BLOCO a partir do começo dela, e o que sobra (menos de BLOCO) pixel a
// pixel. O pixel da direita é a mesma janela andando um pixel: tira o que saiu, põe o que entrou.
float2 caixaEmX(int etapa, int c, int2 j, int r) {
    int N = gN.x;
    int x0 = 2 * j.x;
    int ini = max(x0 - r, 0);
    int fim = min(x0 + r, N - 1);
    int nb = (fim - ini + 1) / BLOCO;
    float s = 0.0;
    for (int b = 0; b < nb; b++) s += blocoEm(etapa, c, ini + b * BLOCO, j.y);
    int carregado = -1;
    float2 d = float2(0.0);
    for (int x = ini + nb * BLOCO; x <= fim; x++) {
        if (etapa == 0) { s += pixelDaEntrada(0, c, int2(x, j.y)); continue; }
        if ((x >> 1) != carregado) { carregado = x >> 1; d = ler16(texelDaEntrada(etapa, c, int2(carregado, j.y))); }
        s += (x & 1) == 0 ? d.x : d.y;
    }
    float largura = float(2 * r + 1);
    float2 media = float2(s / largura, 0.0);
    int x1 = x0 + 1;
    if (x1 < N) {
        if (max(x1 - r, 0) > ini) s -= pixelDaEntrada(etapa, c, int2(ini, j.y));
        if (min(x1 + r, N - 1) > fim) s += pixelDaEntrada(etapa, c, int2(fim + 1, j.y));
        media.y = s / largura;
    }
    return media;
}

// Em y, as duas colunas têm a mesma janela: os blocos e o que sobra servem às duas.
float2 caixaEmY(int etapa, int c, int2 j, int r) {
    int ini = max(j.y - r, 0);
    int fim = min(j.y + r, gN.y - 1);
    int nb = (fim - ini + 1) / BLOCO;
    float2 s = float2(0.0);
    for (int b = 0; b < nb; b++) {
        int2 k = int2(j.x, ini + b * BLOCO);
        s += ler16(c == 0 ? sR.read(uint2(k), uint(0)) : c == 1 ? sG.read(uint2(k), uint(0)) : sB.read(uint2(k), uint(0))) * float(BLOCO);
    }
    for (int y = ini + nb * BLOCO; y <= fim; y++) s += ler16(texelDaEntrada(etapa, c, int2(j.x, y)));
    return s / float(2 * r + 1);
}

// A luz no pixel q da camada: o canal c do resultado da última caixa (gR..).
float luzDoCanal(float4 v, int2 q) {
    float2 d = ler16(v);
    return (q.x & 1) == 0 ? d.x : d.y;
}

fragment float4 fx_sapphire_texture_plasma(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_texture_plasmaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> tabelas [[texture(1)]],
    texture2d<float> ruidoEstado [[texture(2)]],
    texture2d<float> assinatura [[texture(3)]],
    texture2d<float> ruido [[texture(4)]],
    texture2d<float> sR [[texture(5)]],
    texture2d<float> sG [[texture(6)]],
    texture2d<float> sB [[texture(7)]],
    texture2d<float> fR [[texture(8)]],
    texture2d<float> fG [[texture(9)]],
    texture2d<float> fB [[texture(10)]],
    texture2d<float> gR [[texture(11)]],
    texture2d<float> gG [[texture(12)]],
    texture2d<float> gB [[texture(13)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar();
    int2 t = min(int2(floor(in.acScreenNorm * float2(gT))), gT - int2(1));
    int2 q = t - gInicio;
    bool fora = !naCamada(q);
    // A linha da camada do AE (linha 0 em cima); a cena guardada de pé tem a linha 0 embaixo.
    int2 p = eng.acEntradaDePe == 1 ? int2(q.x, gN.y - 1 - q.y) : q;

    // ---- 0: o noise, ou a cópia do quadro anterior ----
    if (eng.acPass == 0) {
        if (fora) { __nv_out = float4(0.0); return __nv_out; }
        __nv_out = mesmaAssinatura() ? ruidoEstado.read(uint2(t), uint(0)) : gravarFloat(ruidoDoSapphire(p, gN.x, gN.y));
        return __nv_out;
    }

    // ---- 1: a assinatura (num estado pequeno, um número por pixel) ----
    if (eng.acPass == 1) {
        int2 a = int2(floor(in.acScreenNorm * float2(int2(int(assinatura.get_width()), int(assinatura.get_height())))));
        int k = a.y * 8 + a.x;
        __nv_out = (a.x < 8 && k < N_ASSINATURA) ? gravarFloat(assinado(k)) : float4(0.0);
        return __nv_out;
    }

    // ---- 2: o pic² ----
    if (eng.acPass == 2) {
        __nv_out = fora ? float4(0.0) : gravar24(picAoQuadrado(p, lerFloat(ruidoEstado.read(uint2(t), uint(0)))));
        return __nv_out;
    }

    // ---- 3..14: o glow, dois pixels por texel (`pack="2"`: o texel j é o par 2·j.x, 2·j.x + 1 da linha j.y) ----
    if (eng.acPass <= 14) {
        int2 j = int2(__nv_fragCoord.xy);
        if (2 * j.x >= gN.x || j.y >= gN.y) {
            __nv_out = float4(0.0); fragColor1 = float4(0.0); fragColor2 = float4(0.0);
            return __nv_out;
        }
        int etapa = (eng.acPass - 3) / 2;           // 0..5: x1, x2, x3, y1, y2, y3
        bool somas = ((eng.acPass - 3) & 1) == 0;   // o 1º passe da etapa faz as somas; o 2º, a caixa
        float2 r, g, b;
        if (somas && etapa == 0) {
            r = somasEmX(0, 0, j); g = r; b = r;  // o pic² é um só para os três canais
        } else if (somas) {
            r = etapa < 3 ? somasEmX(etapa, 0, j) : somasEmY(etapa, 0, j);
            g = etapa < 3 ? somasEmX(etapa, 1, j) : somasEmY(etapa, 1, j);
            b = etapa < 3 ? somasEmX(etapa, 2, j) : somasEmY(etapa, 2, j);
        } else {
            int3 k = raios(etapa < 3 ? etapa : etapa - 3);
            r = etapa < 3 ? caixaEmX(etapa, 0, j, k.x) : caixaEmY(etapa, 0, j, k.x);
            g = etapa < 3 ? caixaEmX(etapa, 1, j, k.y) : caixaEmY(etapa, 1, j, k.y);
            b = etapa < 3 ? caixaEmX(etapa, 2, j, k.z) : caixaEmY(etapa, 2, j, k.z);
        }
        float dentro = 2 * j.x + 1 < gN.x ? 1.0 : 0.0;
        __nv_out = gravar16(r.x, r.y * dentro);
        fragColor1 = gravar16(g.x, g.y * dentro);
        fragColor2 = gravar16(b.x, b.y * dentro);
        return __nv_out;
    }

    // ---- 15: a luz, o screen, a cor e a mistura (da definição; conferido no AE) ----
    float4 s = inputImg.read(uint2(t), uint(0));
    if (fora) { __nv_out = float4(0.0); return __nv_out; }
    float p2 = ler24(ruido.read(uint2(t), uint(0)));
    int2 tl = int2(q.x >> 1, q.y);
    float3 luz = q16(u.glowBrightness) > 0.0
        ? float3(luzDoCanal(gR.read(uint2(tl), uint(0)), q), luzDoCanal(gG.read(uint2(tl), uint(0)), q), luzDoCanal(gB.read(uint2(tl), uint(0)), q))
          * q16(u.glowBrightness) * cor8(u.glowColor.rgb)
        : float3(0.0);
    float3 tex = (1.0 - (1.0 - p2) * (1.0 - luz)) * q16(u.brightness) * cor8(u.color.rgb);

    // Input Opacity: Normal (1) mistura com a cor pré-multiplicada; All Opaque e As Premult, com a reta.
    float3 b = (u.inputOpacity == 1 ? s.rgb * s.a : s.rgb) * q16(u.bgBrightness);
    float3 c;
    if (u.combine == 1) c = tex * b;
    else if (u.combine == 2) c = tex + b;
    else if (u.combine == 3) c = 1.0 - (1.0 - tex) * (1.0 - b);
    else if (u.combine == 4) c = abs(tex - b);
    else if (u.combine == 5) c = mix(1.0 - 2.0 * (1.0 - tex) * (1.0 - b), 2.0 * tex * b, float3(lessThan(b, float3(0.5))));
    else c = tex;
    c = clamp(c, 0.0, 1.0);

    // Output Opacity: Copy From Input = a cor é a reta, com o alfa da fonte; All Opaque = opaco. Os níveis
    // arredondados como o AE de 8 bpc (a GPU não arredonda igual).
    __nv_out = float4(floor(c * 255.0 + 0.5) / 255.0, u.outputOpacity == 1 ? s.a : 1.0);
    return __nv_out;
}
