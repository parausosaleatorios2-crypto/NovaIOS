// ---------------------------------------------------------------------------
// S_BlurMoCurves
// origem : assets/effects/sapphire-blur-mo-curves.xml
// id     : nova.effect.sblurmocurves
// passes : 1
// gerado por glsl2msl.py e consertado a mao no iOS (fix_msl.py): globais passados as funcoes
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
#include "NovaGLSLCompat.h"
using namespace metal;

// iOS: o motor nao entrega os valores no fim do obturador; o fim e o instante atual.
#define centerFim (u.center)
#define shiftXFim (u.shiftX)
#define shiftYFim (u.shiftY)
#define zDistFim (u.zDist)
#define rotateFim (u.rotate)

struct sapphire_blur_mo_curvesParams {
    int mode;
    float2 center;
    float zDist;
    float rotate;
    float shiftX;
    float shiftY;
    float shutterDuration;
    float shutterShift;
    float exposureBias;
    float brightness;
    int wrapX;
    int wrapY;
};

// --- funcoes auxiliares do efeito
constant int MAX_PASSOS = 512;      // lá, 1000
constant int PASSOS_DO_RASCUNHO = 96;  // na prévia em movimento (`eng.acRascunho`, play/arraste); parado e na exportação, MAX_PASSOS

/** A borda de um índice de pixel: 0 nada, 1 ladrilho, 2 espelho em volta do índice 0 e do índice n (medido). */
static int dobrar(int i, int n, int modo) {
    // Dentro do quadro, ladrilho e espelho devolvem o próprio índice: sem a divisão inteira (0.569.0)
    if (i >= 0 && i < n) return i;
    if (modo == 1) { i = i - (i / n) * n; return i < 0 ? i + n : i; }
    if (modo == 2) {
        int p = 2 * n;
        int m = i - (i / p) * p;
        if (m < 0) m += p;
        if (m > n) m = p - m;
        return min(m, n - 1);
    }
    return i;
}

static float4 pixel(int2 i, constant EngineUniforms& eng, texture2d<float> inputImg) {
    // a conta é com a linha 0 no TOPO, como no plugin; numa cena de pé (camada de ajuste) ela é a base do buffer
    if (eng.acEntradaDePe.x == 1.0) i.y = int2(int(inputImg.get_width()), int(inputImg.get_height())).y - 1 - i.y;
    float4 c = inputImg.read(uint2(i), uint(0));
    return float4(c.rgb * c.a, c.a);
}

/** A fonte no ponto `p` (índices de pixel), bilinear — é o que o efeito faz quando nada se mexe. */
static float4 parado(float2 p, int2 T, constant EngineUniforms& eng, constant sapphire_blur_mo_curvesParams& u, texture2d<float> inputImg) {
    float2 b = floor(p), f = p - b;
    float4 soma = float4(0.0);
    for (int k = 0; k < 4; k++) {
        int2 i = int2(b) + int2(k & 1, k >> 1);
        if ((u.wrapX == 0 && (i.x < 0 || i.x >= T.x)) || (u.wrapY == 0 && (i.y < 0 || i.y >= T.y))) continue;
        float w = ((k & 1) == 1 ? f.x : 1.0 - f.x) * ((k >> 1) == 1 ? f.y : 1.0 - f.y);
        soma += w * pixel(int2(dobrar(i.x, T.x, u.wrapX), dobrar(i.y, T.y, u.wrapY)), eng, inputImg);
    }
    return soma;
}

/** Um ponto da reta: `iu` no eixo maior, `it` no menor (já escolhida a linha `tf` ou `tf + 1`). */
static float4 ponto(bool emx, int iu, int it, int tf, int2 T, constant EngineUniforms& eng, constant sapphire_blur_mo_curvesParams& u, texture2d<float> inputImg) {
    int nu = emx ? T.x : T.y, nt = emx ? T.y : T.x;
    int mu = emx ? u.wrapX : u.wrapY, mt = emx ? u.wrapY : u.wrapX;
    // a borda sem Wrap: no eixo maior o ponto tem de cair dentro; no menor, vale de −1 a n − 1, repetindo a borda
    if (mu == 0 && (iu < 0 || iu >= nu)) return float4(0.0);
    if (mt == 0 && (tf < -1 || tf >= nt)) return float4(0.0);
    iu = dobrar(iu, nu, mu);
    it = mt == 0 ? clamp(it, 0, nt - 1) : dobrar(it, nt, mt);
    return pixel(emx ? int2(iu, it) : int2(it, iu), eng, inputImg);
}

/**
 * O `blur_warp` do Sapphire com Subpixel (lido do código): a reta de `p0` a `p1` percorrida em passos
 * inteiros do eixo em que ela anda mais, com interpolação linear no outro.
 */
static float4 reta(float2 p0, float2 p1, int2 T, constant EngineUniforms& eng, constant sapphire_blur_mo_curvesParams& u, texture2d<float> inputImg) {
    float2 d = p1 - p0;
    if (d.x == 0.0 && d.y == 0.0) return parado(p0, T, eng, u, inputImg);
    bool emx = abs(d.x) >= abs(d.y);
    float u0 = emx ? p0.x : p0.y, u1 = emx ? p1.x : p1.y;
    float t0 = emx ? p0.y : p0.x, t1 = emx ? p1.y : p1.x;
    bool sobe = u1 > u0;
    float a = sobe ? floor(u0) : ceil(u0), b = sobe ? ceil(u1) : floor(u1);
    float fa = abs(u0 - a), fb = abs(b - u1), passo = sobe ? 1.0 : -1.0;
    int n = min(int(abs(b - a) + 0.5) + 1, 1000);
    float incl = (t1 - t0) / (u1 - u0);
    int teto = eng.acRascunho == 1 ? PASSOS_DO_RASCUNHO : MAX_PASSOS;
    int salto = (n + teto - 1) / teto;
    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int j = 0; j < MAX_PASSOS; j++) {
        int k = j * salto;
        if (k >= n) break;
        float uu = a + passo * float(k);
        float t = t0 + (uu - u0) * incl;
        // Exposure Bias (medido): o peso vai em linha reta de uma ponta à outra
        float w = u.exposureBias * float(n - k) + (1.0 - u.exposureBias) * float(k + 1);
        if (n == 1) w = 1.0;
        else {
            if (k == 0) w *= 1.0 - fa;
            if (k == n - 1) w *= 1.0 - fb;
        }
        float tf = floor(t), ft = t - tf;
        int iu = int(uu), it = int(tf);
        soma += w * mix(ponto(emx, iu, it, it, T, eng, u, inputImg), ponto(emx, iu, it + 1, it, T, eng, u, inputImg), ft);
        pesos += w;
    }
    return pesos > 0.0 ? soma / pesos : float4(0.0);
}

/** A coordenada dobrada para dentro do quadro: 1 ladrilho, 2 espelho (os ladrilhos ímpares, virados). */
static float antes(float c, float n, int modo) {
    if (modo == 1) return c - floor(c / n) * n;
    if (modo == 2) {
        float q = floor(c / n), r = c - q * n;
        return __nv_mod(q, 2.0) == 1.0 ? n - r : r;
    }
    return c;
}

/** `u.rotate v (graus / −360)` da definição: o giro que o AE mostra como horário. */
static float2 girar(float2 v, float graus) {
    float a = radians(graus), c = cos(a), s = sin(a);
    return float2(c * v.x + s * v.y, -s * v.x + c * v.y);
}

/** Da tela para a fonte (índices de pixel). */
static float2 paraAFonte(float2 p, float2 c, float z, float giro, float2 desloc) {
    return girar(p - c, giro) * z + c - desloc;
}

fragment float4 fx_sapphire_blur_mo_curves(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_blur_mo_curvesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float2 R = float2(T);
    float2 p = min(floor(in.acScreenNorm * R), R - 1.0);
    // o Center é um só (não tem "de" e "até"): o do meio do obturador; em índices, o centro do pixel i fica em i
    float2 c = mix(u.center, centerFim, 0.5) * R - 0.5;
    // Na camada de ajuste (e no grupo solto) a cena chega de pé: a linha 0 do buffer é a BASE. Sem virar, o Shift Y e
    // o giro saíam ao contrário do mesmo efeito numa camada (relato de 22/10/2026, o mesmo do S_Shake na 0.756).
    if (eng.acEntradaDePe.x == 1.0) {
        p.y = R.y - 1.0 - p.y;
        c.y = R.y - 1.0 - c.y;
    }
    float2 s0 = float2(u.shiftX, u.shiftY) * eng.acEscalaDePixel, s1 = float2(shiftXFim, shiftYFim) * eng.acEscalaDePixel;
    float z0 = max(u.zDist, 0.001), z1 = max(zDistFim, 0.001);
    float2 p0 = paraAFonte(p, c, z0, u.rotate, s0);
    float2 p1 = paraAFonte(p, c, z1, rotateFim, s1);
    if (u.mode == 1) {
        // Blur Only: metade da diferença para cada lado, sem transformar (o Z e o giro "de agora": o meio das pontas)
        float2 dv = girar((p1 - p0) * (0.5 / (0.5 * (z0 + z1))), -0.5 * (u.rotate + rotateFim));
        p0 = p - dv;
        p1 = p + dv;
    }
    // A borda no meio do borrão (lido do código e medido): ela é dobrada UMA vez, na ponta do fim do
    // obturador, e a reta sai dali com a mesma diferença — num ladrilho espelhado ela anda "ao contrário",
    // como lá. O que ainda cair fora é dobrado ponto a ponto.
    float2 q1 = float2(antes(p1.x, R.x, u.wrapX), antes(p1.y, R.y, u.wrapY));
    p0 = q1 + (p0 - p1);
    p1 = q1;
    float4 soma = reta(p0, p1, T, eng, u, inputImg) * u.brightness;      // medido: o Brightness multiplica o alfa também
    float alfa = min(soma.a, 1.0);
    __nv_out = alfa > 0.0 ? float4(min(soma.rgb / alfa, float3(1.0)), alfa) : float4(0.0);
    return __nv_out;
}
