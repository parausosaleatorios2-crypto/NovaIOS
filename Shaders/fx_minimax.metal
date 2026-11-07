// ---------------------------------------------------------------------------
// Mínimo e máximo
// origem : assets/effects/minimax.xml
// id     : nova.effect.minimax
// passes : 2  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct minimaxParams {
    int operation;
    float radius;
    int channel;
    int direction;
    int dontShrinkEdges;
};

// --- funcoes auxiliares do efeito
const int OP_MIN = 0;
const int OP_MAX = 1;
const int OP_MIN_MAX = 2;
const int OP_MAX_MIN = 3;

const int CANAL_COR = 0;
const int CANAL_ALFA_E_COR = 1;
const int CANAL_R = 2;
const int CANAL_G = 3;
const int CANAL_B = 4;
const int CANAL_ALFA = 5;

const int DIR_H = 1;
const int DIR_V = 2;

/** O teto do raio: o alcance de oito passos da cadeia ((3⁸ − 1) / 2), o teto de repetições do motor. */
const int RAIO_MAXIMO = 3280;

int2 buf;

/** O alcance da cadeia ANTES do passo `passo` (x) e o salto dele (y), pela regra gulosa do `Morfologia.kt`. */
int2 cadeia(int raio, int passo) {
    int alcance = 0;
    for (int k = 0; k < 8; k++) {
        int salto = max(min(2 * alcance + 1, raio - alcance), 0);
        if (k == passo) return int2(alcance, salto);
        alcance += salto;
    }
    return int2(alcance, 0);
}

/** Quanto o mundo de saída de uma fase cresce (+) ou encolhe (−) num eixo, pela regra do plugin (0x1800039e0). */
int mudanca(int r, bool eMin, bool duas) {
    if (r == 0) return 0;
    if (!eMin) return (duas || u.channel == CANAL_ALFA_E_COR || u.channel == CANAL_ALFA) ? r : 0;
    return (!u.dontShrinkEdges && u.channel == CANAL_ALFA_E_COR) ? -r : 0;
}

/** O retângulo (x0, y0, x1, y1; o fim fora) crescido de (dx, dy); o vazio continua vazio, como no plugin. */
int4 cresce(int4 q, int dx, int dy) {
    if (q.x >= q.z || q.y >= q.w) return int4(0);
    int4 n = int4(q.x - dx, q.y - dy, q.z + dx, q.w + dy);
    return (n.x < n.z && n.y < n.w) ? n : int4(0);
}

bool dentro(int2 p, int4 q) {
    return p.x >= q.x && p.x < q.z && p.y >= q.y && p.y < q.w;
}

float4 ler(int2 q) {
    int2 c = clamp(q, int2(0), buf - 1);
    return (eng.acPass == 0) ? inputImg.read(uint2(c), uint(0)) : morf.read(uint2(c), uint(0));
}

/**
 * O primeiro passo de um eixo numa fase lê a FONTE da fase: fora do mundo dela, 0 (a borda que encolhe) ou a beira
 * mais próxima (a que não encolhe). Na horizontal, a linha fora do mundo também é fora; na vertical a coluna fora
 * só sai no fim da fase (o mundo de saída não a tem).
 */
float4 lerDaFonte(int2 q, int2 p, int4 fonte, bool horizontal) {
    bool fora = horizontal
        ? (q.x < fonte.x || q.x >= fonte.z || p.y < fonte.y || p.y >= fonte.w)
        : (q.y < fonte.y || q.y >= fonte.w);
    if (!u.dontShrinkEdges) return fora ? float4(0.0) : ler(q);
    if (fonte.x >= fonte.z) return float4(0.0);
    int2 c = horizontal ? int2(clamp(q.x, fonte.x, fonte.z - 1), q.y) : int2(q.x, clamp(q.y, fonte.y, fonte.w - 1));
    return ler(c);
}

fragment float4 fx_minimax(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant minimaxParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> morf [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    buf = int2(eng.acResolution + 0.5);
    int2 p = int2(__nv_fragCoord.xy);
    bool horizontal = eng.acPass == 0;
    float4 centro = ler(p);

    // ---------------------------------------------------------- os raios (0x180003b40)
    // O controle é um slider de long no AE: o plugin lê o valor arredondado. A escala é a da prévia reduzida.
    int R = min(int(floor(max(u.radius, 0.0) + 0.5)), RAIO_MAXIMO);
    float esc = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
    int rs = int(floor(float(R) * esc + 0.5));
    int rx = u.direction == DIR_V ? 0 : rs;
    int ry = u.direction == DIR_H ? 0 : rs;
    if (rx == 0 && ry == 0) {
        __nv_out = centro;
        return __nv_out;
    }

    // ---------------------------------------------------------- a fase e o passo
    int voltas = max(eng.acIterationCount / 2, 1);
    int fase = min(eng.acIteration / voltas, 1);
    int passo = eng.acIteration - fase * voltas;
    bool duas = u.operation == OP_MIN_MAX || u.operation == OP_MAX_MIN;
    if (!duas && fase == 1) {
        __nv_out = centro;
        return __nv_out;
    }
    bool min1 = u.operation == OP_MIN || u.operation == OP_MIN_MAX;
    bool eMin = fase == 0 ? min1 : !min1;

    // ---------------------------------------------------------- os mundos (0x180003e80)
    // A fonte da primeira fase é a camada; a da segunda, o mundo de saída da primeira.
    int2 tam = clamp(int2(floor(eng.acCamada * float2(buf) + 0.5)), int2(1), buf);
    int2 ini = (buf - tam) / 2;
    int4 s1 = int4(ini, ini + tam);
    int4 o1 = cresce(s1, mudanca(rx, min1, duas), mudanca(ry, min1, duas));
    int4 o2 = cresce(o1, mudanca(rx, !min1, duas), mudanca(ry, !min1, duas));
    int4 fonte = fase == 0 ? s1 : o1;
    int4 saida = fase == 0 ? o1 : o2;

    // ---------------------------------------------------------- um passo da cadeia
    int r = horizontal ? rx : ry;
    int2 c = cadeia(r, passo);
    int salto = c.y;
    int alcance = c.x + salto;
    bool primeiro = passo == 0;

    float4 v = centro;
    if (salto > 0) {
        int2 d = horizontal ? int2(salto, 0) : int2(0, salto);
        float4 a, m, b;
        if (primeiro) {
            a = lerDaFonte(p - d, p, fonte, horizontal);
            m = lerDaFonte(p, p, fonte, horizontal);
            b = lerDaFonte(p + d, p, fonte, horizontal);
        } else {
            a = ler(p - d);
            m = centro;
            b = ler(p + d);
        }
        v = eMin ? min(m, min(a, b)) : max(m, max(a, b));
        // O Mínimo com a borda que encolhe: a janela que passa do mundo da fonte tem um 0 — que a beira presa do
        // buffer não guarda.
        if (eMin && !u.dontShrinkEdges) {
            int pe = horizontal ? p.x : p.y;
            int lo = horizontal ? fonte.x : fonte.y;
            int hi = horizontal ? fonte.z : fonte.w;
            if (pe - alcance < lo || pe + alcance >= hi) v = float4(0.0);
        }
    }

    // Os canais fora da escolha: a fonte (0 fora do mundo dela), copiada no começo da fase e depois carregada.
    float4 resto = centro;
    if (horizontal && primeiro && !dentro(p, fonte)) resto = float4(0.0);
    bool4 tocado = bool4(u.channel != CANAL_ALFA && u.channel != CANAL_G && u.channel != CANAL_B,
                         u.channel == CANAL_COR || u.channel == CANAL_ALFA_E_COR || u.channel == CANAL_G,
                         u.channel == CANAL_COR || u.channel == CANAL_ALFA_E_COR || u.channel == CANAL_B,
                         u.channel == CANAL_ALFA_E_COR || u.channel == CANAL_ALFA);
    float4 cor = mix(resto, v, tocado);

    // No fim da fase, fora do mundo de saída: transparente.
    if (!horizontal && passo == voltas - 1 && !dentro(p, saida)) cor = float4(0.0);
    __nv_out = cor;
    return __nv_out;
}
