// ---------------------------------------------------------------------------
// S_Sharpen
// origem : assets/effects/sapphire-sharpen.xml
// id     : nova.effect.ssharpen
// passes : 25
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_sharpenParams {
    float sharpenAmp;
    float edgeThreshold;
    float smallDetailSize;
    float scaleTiny;
    float scaleSmall;
    float scaleMedium;
    float scaleLarge;
    float sharpenLuma;
    float sharpenChroma;
    float sharpenRed;
    float sharpenGreen;
    float sharpenBlue;
};

// --- funcoes auxiliares do efeito
const int PASSOS_MAX = 80;          // até onde a janela anda para cada lado (raio máximo do nível large)
const float3 BRILHO = float3(5.0, 8.0, 3.0) / 16.0;      // o `monochrome` do Sapphire (medido)

int2 TAM;
bool JUNTO;                         // Sharpen Luma = Sharpen Chroma: o RGB junto; senão, brilho e cor em separado

static float3 fonte(int2 p) { return inputImg.read(uint2(clamp(p, int2(0), TAM - 1)), uint(0)).rgb; }

/**
 * Os três números com que os passes trabalham. Junto: R, G, B. Separado: o brilho e a cor (fonte −
 * brilho) do vermelho e do azul — a do verde sai das outras duas, porque 5·Cr + 8·Cg + 3·Cb = 0.
 */
static float3 trabalho(float3 rgb) {
    if (JUNTO) return rgb;
    float l = dot(rgb, BRILHO);
    return float3(l, rgb.r - l, rgb.b - l);
}

/** A cor (R, G, B) a partir de (·, Cr, Cb). */
static float3 corInteira(float3 t) { return float3(t.y, -(5.0 * t.y + 3.0 * t.z) / 8.0, t.z); }

/**
 * Um valor intermediário num texel RGBA8: (valor − fonte), que é pequeno quase sempre, com raiz
 * quadrada (mais precisão perto de zero) em 10 bits por número — 8 no RGB e os 2 de baixo no alfa.
 */
static float4 guardar(float3 valor, float3 s) {
    float3 x = clamp(valor - s, -1.0, 1.0);
    int3 q = int3(floor((sign(x) * sqrt(abs(x)) * 0.5 + 0.5) * 1023.0 + 0.5));
    return float4(float3(q >> 2), float((q.r & 3) | ((q.g & 3) << 2) | ((q.b & 3) << 4))) / 255.0;
}

static float3 abrir(float4 t, float3 s) {
    int4 b = int4(t * 255.0 + 0.5);
    int3 q = (b.rgb << 2) | int3(b.a & 3, (b.a >> 2) & 3, (b.a >> 4) & 3);
    float3 e = float3(q) / 1023.0 * 2.0 - 1.0;
    return s + e * abs(e);
}

/** A imagem que este passe filtra: a fonte no primeiro de cada nível, senão o passe anterior. */
static float3 atual(int2 p, float3 rgbDaFonte, int j) {
    float3 s = trabalho(rgbDaFonte);
    if (j == 0) return s;
    int2 q = clamp(p, int2(0), TAM - 1);
    return abrir((j & 1) == 1 ? t1.read(uint2(q), uint(0)) : t2.read(uint2(q), uint(0)), s);
}

/**
 * Quanto dois pixels vizinhos se afastam no domínio transformado: 1, mais a diferença da FONTE (somada
 * nos três canais) vezes sigma / (Edge Threshold · 3). x vale para o primeiro número do passe e y para
 * os outros dois: junto é a mesma distância (a do RGB); separado, a do brilho e a da cor.
 */
static float2 afastamento(float3 a, float3 b, float k) {
    if (JUNTO) { float3 d = abs(a - b); return float2(1.0 + k * (d.r + d.g + d.b)); }
    float la = dot(a, BRILHO), lb = dot(b, BRILHO);
    float3 d = abs((a - la) - (b - lb));
    return float2(1.0 + k * 3.0 * abs(la - lb), 1.0 + k * (d.r + d.g + d.b));
}

/**
 * Uma passada no caminho JUNTO (Sharpen Luma = Sharpen Chroma, o padrão). Lá a distância é uma só (a do RGB), então
 * as duas janelas do caminho separado andariam iguais, passo a passo: aqui anda UMA, com os três números. As mesmas
 * contas, na mesma ordem (0.660.0: até a 0.659 este caminho levava as duas, com a contabilidade em dobro).
 */
static float3 passadaJunta(int2 p, float3 vC, float3 rgbC, int j, float n, float fracao, float k, int2 passo, int limite, int aqui) {
    float3 soma = vC;
    float cont = 1.0;
    float3 pontaE = vC, pontaD = vC;
    float distE = 0.0, distD = 0.0;
    for (int lado = 0; lado < 2; lado++) {
        float3 antes = rgbC;
        float d = 0.0;
        for (int i = 1; i <= PASSOS_MAX; i++) {
            int pos = lado == 0 ? aqui - i : aqui + i;
            if (pos < 0 || pos >= limite) break;
            int2 q = lado == 0 ? p - passo * i : p + passo * i;
            float3 rgbQ = fonte(q);
            float3 dif = abs(rgbQ - antes);
            d += 1.0 + k * (dif.r + dif.g + dif.b);
            // fica quem está a até n de distância (inclusive); passou, a janela desse lado fecha
            if (!(d <= n)) break;
            float3 v = atual(q, rgbQ, j);
            soma += v; cont += 1.0;
            if (lado == 0) { pontaE = v; distE = d; } else { pontaD = v; distD = d; }
            antes = rgbQ;
        }
    }
    float3 fora = soma / float3(cont);
    // A média de dentro (raio n − 1): o plugin tira no máximo UM pixel de cada ponta. Para n ≤ 2 é o próprio pixel.
    float3 dentro = vC;
    if (n > 2.0) {
        float3 s2 = soma; float c2 = cont;
        if (distE > n - 1.0) { s2 -= pontaE; c2 -= 1.0; }
        if (distD > n - 1.0) { s2 -= pontaD; c2 -= 1.0; }
        if (c2 > 0.0) dentro = s2 / float3(c2);
    }
    return dentro + (fora - dentro) * fracao;
}

fragment float4 fx_sapphire_sharpen(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_sharpenParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> t1 [[texture(1)]],
    texture2d<float> t2 [[texture(2)]],
    texture2d<float> f0 [[texture(3)]],
    texture2d<float> f1 [[texture(4)]],
    texture2d<float> f2 [[texture(5)]],
    texture2d<float> f3 [[texture(6)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    TAM = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    JUNTO = u.sharpenLuma == u.sharpenChroma;
    int2 p = int2(min(floor(in.acScreenNorm * float2(TAM)), float2(TAM) - 1.0));
    float3 rgbC = fonte(p);
    float3 sC = trabalho(rgbC);
    float sigma0 = 0.5 * u.smallDetailSize * eng.acEscalaDePixel;

    if (eng.acPass < 24) {
        int nivel = eng.acPass / 6, j = eng.acPass - nivel * 6, iteracao = j / 2;
        float sigma = sigma0 * exp2(float(nivel));
        // Lido do plugin: r_i = 3 · sigma · 2^(N−1−i) / √(4^N − 1), N = 3; a iteração só roda se r > 1.
        float r = 3.0 * sigma * exp2(float(2 - iteracao)) / 7.93725393;
        if (r <= 1.0) {
            // A iteração não roda: o passe só leva adiante o que já está gravado, e guardar(abrir(texel)) é o
            // próprio texel — vai direto (0.660.0). No primeiro passe do nível é a fonte: a diferença zero.
            __nv_out = j == 0 ? guardar(sC, sC) : ((j & 1) == 1 ? t1.read(uint2(p), uint(0)) : t2.read(uint2(p), uint(0)));
            return __nv_out;
        }
        float3 vC = atual(p, rgbC, j);
        float n = floor(r) + 1.0, fracao = r - floor(r);
        float k = sigma / (max(u.edgeThreshold, 1e-6) * 3.0);
        bool vertical = (j & 1) == 1;
        int2 passo = vertical ? int2(0, 1) : int2(1, 0);
        int limite = vertical ? TAM.y : TAM.x, aqui = vertical ? p.y : p.x;
        if (JUNTO) {
            __nv_out = guardar(passadaJunta(p, vC, rgbC, j, n, fracao, k, passo, limite, aqui), sC);
            return __nv_out;
        }

        // O caminho separado: duas janelas andam juntas, a do brilho (x) e a da cor (y).
        float3 soma = vC;
        float2 cont = float2(1.0);
        float3 pontaE = vC, pontaD = vC;
        float2 distE = float2(0.0), distD = float2(0.0);
        for (int lado = 0; lado < 2; lado++) {
            float3 antes = rgbC;
            float2 d = float2(0.0);
            bool2 vivo = bool2(true);
            for (int i = 1; i <= PASSOS_MAX; i++) {
                int pos = lado == 0 ? aqui - i : aqui + i;
                if (pos < 0 || pos >= limite) break;
                int2 q = lado == 0 ? p - passo * i : p + passo * i;
                float3 rgbQ = fonte(q);
                d += afastamento(rgbQ, antes, k);
                // fica quem está a até n de distância (inclusive); passou, a janela desse lado fecha
                vivo = bool2(vivo.x && d.x <= n, vivo.y && d.y <= n);
                if (!vivo.x && !vivo.y) break;
                float3 v = atual(q, rgbQ, j);
                if (vivo.x) {
                    soma.x += v.x; cont.x += 1.0;
                    if (lado == 0) { pontaE.x = v.x; distE.x = d.x; } else { pontaD.x = v.x; distD.x = d.x; }
                }
                if (vivo.y) {
                    soma.yz += v.yz; cont.y += 1.0;
                    if (lado == 0) { pontaE.yz = v.yz; distE.y = d.y; } else { pontaD.yz = v.yz; distD.y = d.y; }
                }
                antes = rgbQ;
            }
        }
        float3 fora = soma / cont.xyy;
        // A média de dentro (raio n − 1): o plugin tira no máximo UM pixel de cada ponta. Para n ≤ 2 é o próprio pixel.
        float3 dentro = vC;
        if (n > 2.0) {
            float3 s2 = soma; float2 c2 = cont;
            if (distE.x > n - 1.0) { s2.x -= pontaE.x; c2.x -= 1.0; }
            if (distD.x > n - 1.0) { s2.x -= pontaD.x; c2.x -= 1.0; }
            if (distE.y > n - 1.0) { s2.yz -= pontaE.yz; c2.y -= 1.0; }
            if (distD.y > n - 1.0) { s2.yz -= pontaD.yz; c2.y -= 1.0; }
            if (c2.x > 0.0) dentro.x = s2.x / c2.x;
            if (c2.y > 0.0) dentro.yz = s2.yz / c2.y;
        }
        __nv_out = guardar(dentro + (fora - dentro) * fracao, sC);
        return __nv_out;
    }

    // ---- a soma: a base (F3) mais cada nível de detalhe pela sua curva ----
    float3 F0 = abrir(f0.read(uint2(p), uint(0)), sC), F1 = abrir(f1.read(uint2(p), uint(0)), sC);
    float3 F2 = abrir(f2.read(uint2(p), uint(0)), sC), F3 = abrir(f3.read(uint2(p), uint(0)), sC);
    float3 det[4] = float3[4](sC - F0, F0 - F1, F1 - F2, F2 - F3);
    float escala[4] = float[4](u.scaleTiny, u.scaleSmall, u.scaleMedium, u.scaleLarge);
    float3 saida;
    if (JUNTO) {
        // Lido do plugin: com Luma = Chroma os dois são ignorados e entram só Amp e Red/Green/Blue.
        saida = F3;
        for (int i = 0; i < 4; i++) {
            float3 a = ((escala[i] - 1.0) * u.sharpenAmp * float3(u.sharpenRed, u.sharpenGreen, u.sharpenBlue) + 1.0) * 2.125;
            saida += tanh(a * det[i] * 0.5);
        }
    } else {
        // O brilho e a cor, cada um com o seu ganho; somam-se no fim. Red/Green/Blue não entram (como lá).
        float brilho = F3.x;
        float3 cor = corInteira(F3);
        for (int i = 0; i < 4; i++) {
            float g = (escala[i] - 1.0) * u.sharpenAmp;
            brilho += tanh((g * u.sharpenLuma + 1.0) * 2.125 * det[i].x * 0.5);
            cor += tanh((g * u.sharpenChroma + 1.0) * 2.125 * corInteira(det[i]) * 0.5);
        }
        saida = brilho + cor;
    }
    __nv_out = float4(clamp(saida, 0.0, 1.0), inputImg.read(uint2(p), uint(0)).a);
    return __nv_out;
}
