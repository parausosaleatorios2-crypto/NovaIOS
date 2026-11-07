// ---------------------------------------------------------------------------
// Wave Warp (AE)
// origem : assets/effects/ae-wave-warp.xml
// id     : nova.effect.aewavewarp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_wave_warpParams {
    int waveType;
    float waveHeight;
    float waveWidth;
    float direction;
    float waveSpeed;
    int pinning;
    float phase;
    int antialiasing;
};

// --- funcoes auxiliares do efeito
// ------------------------------------------------------------------ inteiros

// 64 bits sem sinal em (alto, baixo); os com sinal em complemento de dois.
static uint2 mul64(uint a, uint b) {
    uint a0 = a & 0xFFFFu, a1 = a >> 16, b0 = b & 0xFFFFu, b1 = b >> 16;
    uint p00 = a0 * b0, p01 = a0 * b1, p10 = a1 * b0, p11 = a1 * b1;
    uint meio = (p00 >> 16) + (p01 & 0xFFFFu) + (p10 & 0xFFFFu);
    return uint2(p11 + (p01 >> 16) + (p10 >> 16) + (meio >> 16), (p00 & 0xFFFFu) | (meio << 16));
}
static uint2 soma64(uint2 a, uint2 b) {
    uint baixo = a.y + b.y;
    return uint2(a.x + b.x + (baixo < a.y ? 1u : 0u), baixo);
}
static uint2 neg64(uint2 a) { return soma64(uint2(~a.x, ~a.y), uint2(0u, 1u)); }
static uint2 de32(int a) { return uint2(a < 0 ? 0xFFFFFFFFu : 0u, uint(a)); }
static bool menor64(uint2 a, uint2 b) { return a.x < b.x || (a.x == b.x && a.y < b.y); }     // sem sinal

/** n / d e o resto, com d < 65536 (a divisão longa em 16 bits). */
static uint2 div64(uint2 n, uint d, out uint r) {
    uint t = n.x >> 16;                 uint q3 = t / d; t = ((t % d) << 16) | (n.x & 0xFFFFu);
    uint q2 = t / d; t = ((t % d) << 16) | (n.y >> 16);
    uint q1 = t / d; t = ((t % d) << 16) | (n.y & 0xFFFFu);
    uint q0 = t / d; r = t % d;
    return uint2((q3 << 16) | q2, (q1 << 16) | q0);
}

/** trunc(a · b / 65536), com |a| < 2^31 e |b| ≤ 65536 — o produto vai a 47 bits, como no double do plugin. */
static int corte16(int a, int b) {
    uint2 p = mul64(uint(abs(a)), uint(abs(b)));
    int m = int((p.x << 16) | (p.y >> 16));
    return (a < 0) != (b < 0) ? -m : m;
}

/** O ponto fixo 16.16 que o AE daria ao valor (arredonda, meio para longe do zero). O valor chega em float: um
 *  494,8 vira 494,79998 — com até 4 casas decimais, a conta volta ao decimal antes de converter. */
static int fixo(float v) {
    float m = abs(v);
    float i = floor(m);
    float f = m - i;
    float l = floor(f * 10000.0 + 0.5);
    int r;
    if (abs(f * 10000.0 - l) < 0.002 && i < 32768.0) {
        int li = int(l);
        r = int(i) * 65536 + (2 * li * 4096 + 625) / 1250;
    } else {
        r = int(floor(m * 65536.0 + 0.5));
    }
    return v < 0.0 ? -r : r;
}

static int rndf(float v) { return int(v < 0.0 ? ceil(v - 0.5) : floor(v + 0.5)); }

// ------------------------------------------------------------------ as tabelas

static int3 bytes(int x, int y) { return int3(tabelas.read(uint2(int2(x, y)), uint(0)).rgb * 255.0 + 0.5); }
static int tres(int x, int y) { int3 b = bytes(x, y); return b.r | (b.g << 8) | (b.b << 16); }

/** A onda do tipo `t` (0..8) no índice i, em 16.16. */
static int onda(int t, int i) { return tres(i, t) - 65536; }

/** |valor|·2^53 (64 bits) e o sinal, da direção em graus inteiros. */
static uint2 dupla(int x, int y, out bool negativo) {
    int3 a = bytes(x, y), b = bytes(x + 1, y), c = bytes(x + 2, y);
    negativo = c.g == 1;
    return uint2(uint(b.g | (b.b << 8) | (c.r << 16)), uint(a.r | (a.g << 8) | (a.b << 16) | (b.r << 24)));
}

/** rnd(2^39 · |valor| / d) para o valor dado por M = |valor|·2^53: floor((M + 2^13·d) / 2^14 / d). d < 2^33. */
static int passoExato(uint2 M, uint2 d) {
    uint2 u = soma64(M, uint2((d.x << 13) | (d.y >> 19), d.y << 13));
    uint2 u14 = uint2(u.x >> 14, (u.y >> 14) | (u.x << 18));
    float aprox = (float(u14.x) * 4294967296.0 + float(u14.y)) / (float(d.x) * 4294967296.0 + float(d.y));
    int q = int(floor(aprox));
    for (int k = 0; k < 3; k++) {      // corrige o float: q·d <= u14 < (q+1)·d
        uint2 qd = soma64(mul64(uint(q), d.y), uint2(uint(q) * d.x, 0u));
        if (menor64(u14, qd)) { q -= 1; continue; }
        uint2 q1d = soma64(qd, d);
        if (!menor64(u14, q1d)) { q += 1; continue; }
        break;
    }
    return q;
}

// ------------------------------------------------------------------ o efeito

fragment float4 fx_ae_wave_warp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_wave_warpParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> tabelas [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 buf = int2(eng.acResolution + 0.5);
    int2 aqui = int2(floor(in.acScreenNorm * eng.acResolution));
    // A camada do AE dentro do buffer (a mídia encaixada; texto, forma e sólido: a composição inteira): o efeito do AE
    // roda no tamanho DELA — a fixação (¼ do lado) e o "fora da camada = transparente" são dela.
    int2 tam = clamp(int2(floor(eng.acCamada * float2(buf) + 0.5)), int2(1), buf);
    int2 inicio = (buf - tam) / 2;
    int2 local = aqui - inicio;
    if (any(lessThan(local, int2(0))) || any(greaterThanEqual(local, tam))) {
        __nv_out = inputImg.read(uint2(aqui), uint(0));     // fora da camada: no AE não há camada aqui
        return __nv_out;
    }
    // A conta é na orientação da IMAGEM (a linha 0 é o topo, como no plugin). Numa cena guardada de pé (camada de
    // ajuste, grupo solto) a linha 0 do buffer é a BASE.
    bool dePe = eng.acEntradaDePe == 1;
    int2 pix = int2(local.x, dePe ? tam.y - 1 - local.y : local.y);
    int AA = u.antialiasing + 2;
    float escala = eng.acEscalaDePixel;
    bool inteira = abs(escala - 1.0) < 1.0e-6;

    // os parâmetros em 16.16, como o plugin os recebe
    int hraw = fixo(u.waveHeight);
    int wraw = max(fixo(u.waveWidth), 1);
    int draw = fixo(u.direction);
    int vraw = fixo(u.waveSpeed);
    int fraw = fixo(u.phase);

    // a direção: as quatro constantes do plugin (deslocamento e passos)
    int dxu, dyu, passoX, passoY;
    if (inteira && (draw & 0xFFFF) == 0) {
        int g = draw >> 16;
        g -= 360 * int(floor(float(g) / 360.0));          // o % do GLSL ES é indefinido com negativo
        int y = 9 + g / 64, x0 = (g % 64) * 8;
        dxu = tres(x0, y) - 65536;
        dyu = tres(x0 + 1, y) - 65536;
        uint2 d = mul64(uint(wraw), uint(AA));
        bool ns, nc;
        uint2 S = dupla(x0 + 2, y, ns);
        uint2 C = dupla(x0 + 5, y, nc);
        passoY = passoExato(S, d) * (ns ? -1 : 1);
        passoX = passoExato(C, d) * (nc ? -1 : 1);
    } else {
        float a = (float(draw) - 5898240.0) / 65536.0 * 0.017453292519943295;
        float s = sin(a), c = cos(a);
        float k = 128.0 / (float(wraw) / 65536.0);
        dxu = rndf(escala * s * 65536.0);
        dyu = rndf(escala * c * 65536.0);
        passoY = rndf(k * s / escala / float(AA) * 65536.0);
        passoX = rndf(k * c / escala / float(AA) * 65536.0);
    }
    int dispX = corte16(hraw, dxu);
    int dispY = -corte16(hraw, dyu);

    // a fase em 1/65536 de entrada: F = fase·65536 − 256·Wave Speed·65536·t, guardada como parte inteira (64 bits) e
    // "tem fração". Com fps inteiro e o quadro inteiro, t = n / fps EXATO (como o AE); senão, float.
    uint2 Fi;
    bool fracao;
    float fps = eng.acFrameDuration > 0.0 ? 1.0 / eng.acFrameDuration : 0.0;
    float fpsI = floor(fps + 0.5);
    float nf = floor(eng.acTime * fpsI + 0.5);
    if (fpsI >= 1.0 && fpsI < 65536.0 && abs(fps - fpsI) < 1.0e-3 && abs(eng.acTime * fpsI - nf) < 1.0e-2 && nf >= 0.0) {
        uint r;
        uint2 Q = div64(mul64(256u * uint(abs(vraw)), uint(nf)), uint(fpsI), r);
        fracao = r > 0u;
        Fi = vraw >= 0 ? soma64(de32(fraw), neg64(soma64(Q, uint2(0u, fracao ? 1u : 0u)))) : soma64(de32(fraw), Q);
    } else {
        float F = float(fraw) - 256.0 * float(vraw) * eng.acTime;
        float fl = floor(F);
        fracao = F > fl;
        Fi = de32(int(fl));
    }

    // a fixação: o código do menu do AE (com os separadores) e as quedas (¼ do lado, na grade de pontos)
    int codigo = u.pinning < 3 ? u.pinning + 1 : (u.pinning < 7 ? u.pinning + 2 : u.pinning + 3);
    bool esq = codigo == 5 || codigo == 2 || codigo == 11;
    bool topo = codigo == 6 || codigo == 2 || codigo == 10;
    bool dir = codigo == 7 || codigo == 2 || codigo == 11;
    bool base = codigo == 8 || codigo == 2 || codigo == 10;
    bool centro = codigo == 3;
    int Wg = tam.x * AA, Hg = tam.y * AA;
    int qx = Wg / 4, qy = Hg / 4;
    int qq = qx * qx;

    int t = u.waveType;
    int passo = 65536 / AA;
    int somaA = 0;
    int3 somaCA = int3(0);
    for (int j = 0; j < 4; j++) {
        if (j >= AA) break;
        int linha = pix.y * AA + j;
        int fy = 65536;
        if (!centro) {
            if (topo && linha < qy && qy > 0) fy = (linha * 65536) / qy;
            else if (base && linha >= Hg - qy - 1 && qy > 0) fy = ((Hg - linha - 1) * 65536) / qy;
        }
        for (int i = 0; i < 4; i++) {
            if (i >= AA) break;
            int col = pix.x * AA + i;
            // o índice: trunc((acc + F) / 65536), os 8 bits de baixo (acc dá a volta em 32 bits, como no plugin)
            uint acc = uint(linha) * uint(passoY) + uint(col + 1) * uint(passoX);
            uint2 X = soma64(de32(int(acc)), Fi);
            int alto = int(X.x);
            int ind;
            if (alto >= 0x8000 || alto < -0x8000) {
                ind = 0;                                   // fora do int32 do plugin: cvttsd2si dá 0x80000000
            } else if (alto >= 0) {
                ind = int((X.y & 0xFFFFFFu) >> 16);
            } else {
                uint y = (0u - X.y - (fracao ? 1u : 0u)) & 0xFFFFFFu;
                ind = (256 - int(y >> 16)) & 255;
            }
            int v = onda(t, ind);

            int fx = 65536;
            if (centro) {
                int dx = col - (Wg >> 1), dy = linha - (Hg >> 1);
                int d2 = dx * dx + dy * dy;
                if (d2 < qq && qq > 0) {
                    // floor(d2 · 65536 / qq), exato: o float dá o palpite e os inteiros corrigem
                    uint2 alvo = mul64(uint(d2), 65536u);
                    int f = int(floor(float(d2) / float(qq) * 65536.0));
                    for (int k = 0; k < 3; k++) {
                        if (menor64(alvo, mul64(uint(f), uint(qq)))) { f -= 1; continue; }
                        if (!menor64(alvo, mul64(uint(f + 1), uint(qq)))) { f += 1; continue; }
                        break;
                    }
                    fx = f;
                }
            } else {
                if (esq && col < qx && qx > 0) fx = (col * 65536) / qx;
                else if (dir && col >= Wg - qx - 1 && qx > 0) fx = ((Wg - col - 1) * 65536) / qx;
            }

            int ox = corte16(corte16(-corte16(dispX, v), fx), fy);
            int oy = corte16(corte16(-corte16(dispY, v), fx), fy);
            int X16 = int(uint(col) * uint(passo) - uint(ox) - 0x7FFFu);
            int Y16 = int(uint(pix.y) * 65536u + uint(j) * uint(passo) - uint(oy) - 0x7FFFu);
            int2 p = int2((X16 + 0x8000) >> 16, (Y16 + 0x8000) >> 16);
            if (p.x < 0 || p.y < 0 || p.x >= tam.x || p.y >= tam.y) continue;
            int2 noBuffer = inicio + int2(p.x, dePe ? tam.y - 1 - p.y : p.y);
            int4 c = int4(inputImg.read(uint2(noBuffer), uint(0)) * 255.0 + 0.5);
            somaA += c.a;
            somaCA += c.rgb * c.a;
        }
    }
    int n = AA * AA;
    int a = (2 * somaA + n) / (2 * n);
    if (somaA == 0) { __nv_out = float4(0.0); return __nv_out; }
    int3 cor = (2 * somaCA + somaA) / (2 * somaA);
    __nv_out = float4(float3(cor), float(a)) / 255.0;
    return __nv_out;
}
