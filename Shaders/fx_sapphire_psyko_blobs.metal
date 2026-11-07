// ---------------------------------------------------------------------------
// S_PsykoBlobs
// origem : assets/effects/sapphire-psyko-blobs.xml
// id     : nova.effect.spsykoblobs
// passes : 10
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_psyko_blobsParams {
    float noiseFrequency;
    float noiseFreqRelX;
    float noiseOctaves;
    float noiseSeed;
    float2 shift;
    float sourceBlur;
    float sourceScale;
    float freqColors;
    float freqRed;
    float freqGreen;
    float freqBlue;
    float phaseStart;
    float phaseSpeed;
    float phaseRed;
    float phaseGreen;
    float phaseBlue;
    float brightness;
    float4 color;
    float offset;
    float saturation;
    float scaleBySource;
    float scaleBySrcAmp;
    float mixWithSource;
    int inputOpacity;
    int outputOpacity;
};

// --- funcoes auxiliares do efeito
const float LARGURA_MAX = 720.0;

// Os sliders do Sapphire chegam em ponto fixo 16.16: os do `noise` truncados (medido no S_TexturePlasma), os outros
// arredondados (medido no S_PsykoStripes).
float q16(float v) { return floor(v * 65536.0) / 65536.0; }
float fixo(float v) { return floor(v * 65536.0 + 0.5) / 65536.0; }
// 2^k exato (o exp2 da GPU não garante).
float pot2(int k) { return as_type<float>((127 + k) << 23); }

// ---- a camada do AE no buffer --------------------------------------------------------------
int2 gT;          // o buffer
int2 gN;          // a camada do AE dentro dele, em px
int2 gInicio;     // o canto da camada no buffer
float gEscala;     // a prévia reduzida (o Source Blur é em px da composição)

void preparar() {
    gT = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gN = clamp(int2(floor(max(eng.acCamada, float2(0.001)) * float2(gT) + 0.5)), int2(1), gT);
    gInicio = (gT - gN) / 2;
    gEscala = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
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

// ---- o desfoque da fonte (o do S_PsykoStripes) ----------------------------------------------
int espelhar(int i, int n) {
    if (i >= 0 && i < n) return i;
    int p = 2 * n;
    i = i - (i / p) * p; if (i < 0) i += p;
    return i < n ? i : p - 1 - i;
}

int2 espelhado(int2 q) { return gInicio + int2(espelhar(q.x, gN.x), espelhar(q.y, gN.y)); }

// Input Opacity (medido): Normal (1) usa a cor pré-multiplicada; All Opaque (0) e As Premult (2), a reta.
float3 entrada(int2 p) {
    float4 s = inputImg.read(uint2(p), uint(0));
    return u.inputOpacity == 1 ? s.rgb * s.a : s.rgb;
}

float monochrome(float3 c) { return (0.3125 * c.r + 0.5 * c.g) + 0.1875 * c.b; }

// Medido: o Source Blur do AE já é a largura em px (subpixel ligado de fábrica no plugin).
float larguraPx() { return clamp(fixo(u.sourceBlur) * gEscala, 0.0, LARGURA_MAX); }

/** Uma das três caixas de um eixo (a conta do S_GlowAura): a que cresce leva as pontas com a fração. */
float caixa(int2 q, bool emX, int qual, bool deA) {
    float w = larguraPx();
    int a = int(floor(w));
    float f = w - float(a);
    int r = (a + 2 - qual) / 3;
    bool cresce = f > 0.0 && a - (a / 3) * 3 == qual;
    float soma = 0.0;
    for (int d = -r; d <= r; d++) {
        int2 p = espelhado(q + (emX ? int2(d, 0) : int2(0, d)));
        soma += lerFloat(deA ? ga.read(uint2(p), uint(0)) : gb.read(uint2(p), uint(0)));
    }
    float n = float(2 * r + 1);
    if (!cresce) return soma / n;
    int2 e = espelhado(q - (emX ? int2(r + 1, 0) : int2(0, r + 1)));
    int2 g = espelhado(q + (emX ? int2(r + 1, 0) : int2(0, r + 1)));
    float pontas = deA ? lerFloat(ga.read(uint2(e), uint(0))) + lerFloat(ga.read(uint2(g), uint(0))) : lerFloat(gb.read(uint2(e), uint(0))) + lerFloat(gb.read(uint2(g), uint(0)));
    return soma * ((1.0 - f) / n + f / (n + 2.0)) + pontas * (f / (n + 2.0));
}

fragment float4 fx_sapphire_psyko_blobs(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_psyko_blobsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> tabelas [[texture(1)]],
    texture2d<float> ruidoEstado [[texture(2)]],
    texture2d<float> assinatura [[texture(3)]],
    texture2d<float> ga [[texture(4)]],
    texture2d<float> gb [[texture(5)]])
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

    // ---- 2: bw = monochrome(fonte); 3..8: as três caixas em x e em y ----
    if (eng.acPass == 2) { __nv_out = fora ? float4(0.0) : gravarFloat(monochrome(entrada(t))); return __nv_out; }
    if (eng.acPass <= 8) {
        int k = eng.acPass - 2;
        float c = fora ? 0.0 : caixa(q, k <= 3, (k - 1) - ((k - 1) / 3) * 3, (k & 1) == 1);
        __nv_out = gravarFloat(c);
        return __nv_out;
    }

    // ---- 9: as manchas (da definição) ----
    float4 s = inputImg.read(uint2(t), uint(0));
    if (fora) { __nv_out = s; return __nv_out; }

    float n = lerFloat(ruidoEstado.read(uint2(t), uint(0)));
    float bw = lerFloat(ga.read(uint2(t), uint(0))) * fixo(u.sourceScale);
    float3 ph = fixo(u.phaseStart) + float3(fixo(u.phaseRed), fixo(u.phaseGreen), fixo(u.phaseBlue)) + fixo(u.phaseSpeed) * eng.acTime;
    float3 fq = fixo(u.freqColors) * float3(fixo(u.freqRed), fixo(u.freqGreen), fixo(u.freqBlue));
    float3 c = (0.5 + 0.5 * sin(6.2831853 * (fq * ((n + bw) - ph)))) * fixo(u.brightness) * (floor(u.color.rgb * 255.0 + 0.5) / 255.0);
    float lum = monochrome(c);
    float3 pic = lum + (c - lum) * fixo(u.saturation);
    float k = mix(1.0, min(1.0, bw * fixo(u.scaleBySrcAmp)), fixo(u.scaleBySource));
    float3 o = pic * k + fixo(u.offset);
    o = mix(o, entrada(t), fixo(u.mixWithSource));

    // Output Opacity (medido): Copy From Input = clip(saída) como cor reta com o alfa da fonte; All Opaque, opaco
    float a = u.outputOpacity == 0 ? 1.0 : s.a;
    __nv_out = float4(floor(clamp(o, 0.0, 1.0) * 255.0 + 0.5) / 255.0, a);
    return __nv_out;
}
