// ---------------------------------------------------------------------------
// Construtor de grade
// origem : assets/effects/grid-builder.xml
// id     : nova.effect.gridbuilder
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct grid_builderParams {
    int shape;
    float count;
    float cellSize;
    float columns;
    float spacingX;
    float spacingY;
    float radius;
    float2 center;
    float opacity;
    int pathShape;
    float pathHeight;
    float polygonPoints;
    float pathProgress;
    float pathSpread;
    float trimStart;
    float trimEnd;
    float focus;
    int morphTo;
    float morphAmount;
    int orientation;
    float gridRotation;
    float twistX;
    float twistY;
    float twistZ;
    float stagger;
    int staggerAxis;
    float scaleFront;
    float scaleBack;
    int scaleMode;
    float scaleDirection;
    float rippleFocus;
    float scaleFalloff;
    float zDepth;
    float zAnchor;
    float shuffle;
    float randomOffset;
    float randomSeed;
    int proxOn;
    float2 proxPoint;
    float proxRadius;
    float proxFalloff;
    float proxScale;
    float proxOpacity;
    float proxPush;
    float proxLift;
};

// --- funcoes auxiliares do efeito
const float FOCO = 1.3889;          // o zoom da câmera padrão do AE (50 mm), em larguras do quadro
const int MAXIMO = 100;             // o teto de cópias
const int CAMADAS = 6;              // quantas cópias sobrepostas num mesmo pixel são compostas
const float PI = 3.14159265358979;

// O que vale para o quadro inteiro (montado uma vez no main).
float2 R;                 // o tamanho da camada, em px
float N;                // quantas cópias
float gRot;             // o giro da formação, em rad
float colunas;
float2 espaco;            // px
float raioPx;           // px
float2 raioDoCaminho;     // px
float3x3 giroDaEsfera;      // a esfera girada até a cópia em foco

// ---------------------------------------------------------------------------------- sorteio

static uint misturar(uint x) { x ^= x >> 16; x *= 0x7feb352dU; x ^= x >> 15; x *= 0x846ca68bU; x ^= x >> 16; return x; }
/** Um número de 0 a 1 para o par (a, b) de inteiros não negativos. */
static float acaso(float a, float b) {
    return float(misturar(uint(a) * 0x9E3779B9U + misturar(uint(b) + 0x1234567U)) >> 8) / 16777216.0;
}

// ---------------------------------------------------------------------------------- formações

static float3x3 girarX(float a) { float c = cos(a), s = sin(a); return float3x3(1.0, 0.0, 0.0, 0.0, c, s, 0.0, -s, c); }
static float3x3 girarY(float a) { float c = cos(a), s = sin(a); return float3x3(c, 0.0, -s, 0.0, 1.0, 0.0, s, 0.0, c); }
static float3x3 girarZ(float a) { float c = cos(a), s = sin(a); return float3x3(c, s, 0.0, -s, c, 0.0, 0.0, 0.0, 1.0); }
/** O resto de `a / b` para inteiros guardados em float (o `mod` da GPU erra em múltiplos exatos). */
static float resto(float a, float b) { return a - b * floor((a + 0.5) / b); }
static float2 girar2(float2 p, float a) { float c = cos(a), s = sin(a); return float2(p.x * c - p.y * s, p.x * s + p.y * c); }

/** O ponto `u` (0..1) do caminho, sem o giro da formação — as quatro formas prontas da extensão. */
static float2 pontoDoCaminho(float u) {
    float2 s = raioDoCaminho;
    if (u.pathShape == 0) {
        float a = u * 2.0 * PI - PI / 2.0;
        return float2(cos(a), sin(a)) * s;
    }
    if (u.pathShape == 1) {
        if (s.x + s.y <= 0.0) return float2(0.0);
        float pX = s.x / (2.0 * (s.x + s.y)), pY = s.y / (2.0 * (s.x + s.y));
        if (u < pX) return float2(-s.x + (u / pX) * 2.0 * s.x, -s.y);
        if (u < pX + pY) return float2(s.x, -s.y + ((u - pX) / pY) * 2.0 * s.y);
        if (u < 2.0 * pX + pY) return float2(s.x - ((u - pX - pY) / pX) * 2.0 * s.x, s.y);
        return float2(-s.x, s.y - ((u - 2.0 * pX - pY) / pY) * 2.0 * s.y);
    }
    if (u.pathShape == 2) {
        float P = max(3.0, floor(u.polygonPoints + 0.5));
        float seg = u * P, idx = floor(seg), f = seg - idx;
        float a1 = idx * 2.0 * PI / P - PI / 2.0, a2 = (idx + 1.0) * 2.0 * PI / P - PI / 2.0;
        return mix(float2(cos(a1), sin(a1)) * s, float2(cos(a2), sin(a2)) * s, f);
    }
    // a estrela de cinco pontas (a ponta de dentro na metade do raio)
    float seg = u * 10.0, idx = floor(seg), f = seg - idx;
    float r1 = resto(idx, 2.0) < 0.5 ? 1.0 : 0.5, r2 = resto(idx + 1.0, 2.0) < 0.5 ? 1.0 : 0.5;
    float a1 = idx * PI / 5.0 - PI / 2.0, a2 = (idx + 1.0) * PI / 5.0 - PI / 2.0;
    return mix(float2(cos(a1), sin(a1)) * s * r1, float2(cos(a2), sin(a2)) * s * r2, f);
}

/** Onde a cópia `i` está no caminho (0..1), já com Espalhar, Andar e o trecho Começo–Fim. */
static float noCaminho(float i, float mais) {
    float bruto = (i / N) * (u.pathSpread / 100.0) + u.pathProgress / 100.0 + mais;
    return u.trimStart / 100.0 + __nv_mod(bruto, 1.0) * (u.trimEnd - u.trimStart) / 100.0;
}

/** Um ponto da esfera de Fibonacci de `N` pontos (raio 1), antes do giro até o foco. */
static float3 naEsfera(float i) {
    float phi = acos(1.0 - 2.0 * (i + 0.5) / N);
    float theta = PI * (1.0 + sqrt(5.0)) * i;
    return float3(cos(theta) * sin(phi), cos(phi), sin(theta) * sin(phi));
}

/** O quatérnio (w, x, y, z) que leva a direção `v` para a frente (0, 0, -1). */
static float4 ateAFrente(float3 v) {
    float ang = acos(clamp(-v.z, -1.0, 1.0));
    float2 eixo = float2(-v.y, v.x);
    float len = length(eixo);
    eixo = len > 0.0001 ? eixo / len : float2(1.0, 0.0);
    return float4(cos(ang / 2.0), eixo * sin(ang / 2.0), 0.0);
}

/** A esfera gira para a cópia em foco ficar de frente; valor quebrado = a meio caminho entre duas. */
static float3x3 montarGiroDaEsfera() {
    float F = clamp(u.focus - 1.0, 0.0, N - 1.0);
    float a = floor(F), b = min(N - 1.0, a + 1.0), t = F - a;
    float4 qA = ateAFrente(naEsfera(a)), qB = ateAFrente(naEsfera(b));
    float d = dot(qA, qB);
    if (d < 0.0) { d = -d; qB = -qB; }
    float4 q;
    if (d > 0.9999) q = mix(qA, qB, t);
    else { float th = acos(d), s = sin(th); q = (sin((1.0 - t) * th) * qA + sin(t * th) * qB) / s; }
    q /= length(q);
    float w = q.x, x = q.y, y = q.z, z = q.w;
    return float3x3(
        1.0 - 2.0 * y * y - 2.0 * z * z, 2.0 * x * y + 2.0 * z * w, 2.0 * x * z - 2.0 * y * w,
        2.0 * x * y - 2.0 * z * w, 1.0 - 2.0 * x * x - 2.0 * z * z, 2.0 * y * z + 2.0 * x * w,
        2.0 * x * z + 2.0 * y * w, 2.0 * y * z - 2.0 * x * w, 1.0 - 2.0 * x * x - 2.0 * y * y);
}

/** O lugar da cópia `i` na formação `f`, em px a partir do centro (sem profundidade nem sorteio). */
static float3 lugar(int f, float i) {
    if (f == 0) {
        float linhas = max(ceil(N / colunas), 1.0);
        float2 d = (float2(resto(i, colunas), floor((i + 0.5) / colunas)) - (float2(colunas, linhas) - 1.0) / 2.0) * espaco;
        return float3(girar2(d, gRot), 0.0);
    }
    if (f == 1) {
        float a = resto(i, colunas) * (2.0 * PI / colunas) + gRot - PI / 2.0;
        return float3(cos(a), sin(a), 0.0) * raioPx;
    }
    if (f == 2) {
        float3 p = giroDaEsfera * (naEsfera(i) * raioPx);
        return float3(girar2(p.xy, gRot), p.z);
    }
    return float3(girar2(pontoDoCaminho(noCaminho(i, 0.0)), gRot), 0.0);
}

/** A profundidade por cópia (a esfera não tem: ela já é o Z). */
static float fundo(int f, float i) { return f == 2 ? 0.0 : (i - (floor(u.zAnchor + 0.5) - 1.0)) * u.zDepth / 100.0 * R.x; }

/** Quanto a cópia `i` está "no fim" (0 = começo, 1 = fim) para a escala por posição — a conta de cada formação. */
static float posicaoNaEscala(int f, float i, float3 p) {
    float t = N > 1.0 ? i / (N - 1.0) : 0.0;
    float F = clamp(u.scaleFalloff, 0.0, 100.0) / 100.0;
    if (u.scaleMode == 1) {
        float dir = radians(u.scaleDirection + 90.0);
        float2 v = float2(cos(dir), sin(dir));
        float proj = dot(p.xy, v), maxProj;
        if (f == 0) {
            float2 meio = (float2(colunas, max(ceil(N / colunas), 1.0)) - 1.0) / 2.0 * espaco;
            maxProj = abs(meio.x * cos(dir - gRot)) + abs(meio.y * sin(dir - gRot));
        } else if (f == 3) {
            maxProj = length(raioDoCaminho * v);
        } else {
            maxProj = raioPx;
        }
        if (maxProj <= 0.0) maxProj = 1.0;
        float x = (proj / maxProj + 1.0) / 2.0;
        if (f == 0) {
            float W = max(0.01, F * 2.0);
            t = (x - (1.0 - W)) / W;
        } else {
            float ini, fim;
            if (F <= 0.01) { ini = 0.99; fim = 1.0; }
            else if (F >= 0.99) { ini = -0.1; fim = 0.0; }
            else if (F < 0.5) { ini = 1.0 - F * 2.0; fim = 1.0; }
            else { ini = 0.0; fim = 1.0 - (F - 0.5) * 2.0; }
            t = (x - ini) / (fim - ini);
        }
    } else if (u.scaleMode == 2) {
        float alvo = clamp(u.rippleFocus - 1.0, 0.0, N - 1.0);
        float a = floor(alvo), b = min(N - 1.0, a + 1.0);
        float3 foco = mix(lugar(f, a), lugar(f, b), alvo - a);
        if (f == 3) {
            // medido: no caminho a onda mede a distância com as cópias espalhadas de ponta a ponta
            // (i / (N - 1)), sem o trecho Começo–Fim — não no lugar onde elas estão desenhadas
            float passo = (u.pathSpread / 100.0) / max(N - 1.0, 1.0), ini = u.pathProgress / 100.0;
            float2 fa = pontoDoCaminho(__nv_mod(a * passo + ini, 1.0)), fb = pontoDoCaminho(__nv_mod(b * passo + ini, 1.0));
            foco = float3(girar2(mix(fa, fb, alvo - a), gRot), 0.0);
            p = float3(girar2(pontoDoCaminho(__nv_mod(i * passo + ini, 1.0)), gRot), 0.0);
        }
        float maior;
        if (f == 0) maior = length((float2(colunas, max(ceil(N / colunas), 1.0)) - 1.0) * espaco) / 2.0;
        else if (f == 3) maior = length(raioDoCaminho);
        else maior = raioPx;
        float maxD = max(0.001, F * maior * 2.0);
        float amt = 1.0 - clamp(distance(p, foco) / maxD, 0.0, 1.0);
        t = 1.0 - amt * amt * (3.0 - 2.0 * amt);
    }
    t = clamp(t, 0.0, 1.0);
    if (f == 0) return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
    if (f == 1) return t;
    return t * t * (3.0 - 2.0 * t);
}

/** Para onde a cópia está virada ANTES do giro dela: as colunas são os eixos X, Y e Z da cópia. */
static float3x3 base(int f, float i, float3 p, float3x3 daCamera) {
    if (u.orientation == 1) return daCamera;
    if (u.orientation == 0) return float3x3(1.0);
    if (f == 2) {
        // esfera: "Para o centro" olha para dentro, "Seguir a formação" para fora
        float3 dir = u.orientation == 3 ? -p : p;
        float len = length(dir);
        float3 z = len > 0.0 ? dir / len : float3(0.0, 0.0, 1.0);
        float3 cima = abs(z.y) > 0.999 ? float3(0.0, 0.0, 1.0) : float3(0.0, 1.0, 0.0);
        float3 x = cross(cima, z);
        float lx = length(x);
        x = lx > 0.0 ? x / lx : float3(1.0, 0.0, 0.0);
        return float3x3(x, cross(z, x), z);
    }
    float ang;
    if (f == 3 && u.orientation == 3) {
        // caminho: a cópia acompanha a direção do traço
        float2 a = girar2(pontoDoCaminho(noCaminho(i, 0.0)), gRot);
        float2 b = girar2(pontoDoCaminho(noCaminho(i, 0.001)), gRot);
        if (a == b) a = girar2(pontoDoCaminho(noCaminho(i, -0.001)), gRot);
        ang = __nv_atan(b.y - a.y, b.x - a.x);
    } else if (f == 0 && u.orientation == 3) {
        return float3x3(1.0);
    } else {
        ang = __nv_atan(p.y, p.x) + PI / 2.0;
    }
    float c = cos(ang), s = sin(ang);
    return float3x3(c, s, 0.0, -s, c, 0.0, 0.0, 0.0, 1.0);
}

// ---------------------------------------------------------------------------------- imagem

static float4 imagem(int qual, float2 uv) {
    if (qual == 1) return imagem2.sample(__nv_smp, uv);
    if (qual == 2) return imagem3.sample(__nv_smp, uv);
    if (qual == 3) return imagem4.sample(__nv_smp, uv);
    if (qual == 4) return imagem5.sample(__nv_smp, uv);
    return inputImg.sample(__nv_smp, uv);
}

/** A imagem `qual` no ponto `uv`, pré-multiplicada, com a média de `n × n` toques quando ela está reduzida. */
static float4 amostra(int qual, float2 uv, float2 passo, int n) {
    float4 soma = float4(0.0);
    for (int a = 0; a < 3; a++) {
        if (a >= n) break;
        for (int b = 0; b < 3; b++) {
            if (b >= n) break;
            float2 q = uv + (float2(float(a), float(b)) + 0.5 - float(n) / 2.0) * passo / float(n);
            float4 c = imagem(qual, clamp(q, 0.0, 1.0));
            soma += float4(c.rgb * c.a, c.a);
        }
    }
    return soma / float(n * n);
}

// ---------------------------------------------------------------------------------- câmera

/** O raio do pixel `uv`: de onde sai e para onde vai, em px da camada (X direita, Y baixo, Z para longe). */
static void raio(float2 uv, out float3 o, out float3 d) {
    if (eng.acCamera3D == 1) {
        float2 tela = __nv_acTela(uv);
        float4 longe = eng.acCameraInvVP * float4(tela.x * 2.0 - 1.0, 1.0 - tela.y * 2.0, 1.0, 1.0);
        o = eng.acCameraOlho * eng.acEscalaDePixel;
        d = (longe.xyz / longe.w - eng.acCameraOlhoNova) * eng.acEscalaDePixel;
    } else {
        o = float3(0.5 * R, -FOCO * R.x);
        d = float3(uv * R, 0.0) - o;
    }
}

fragment float4 fx_grid_builder(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant grid_builderParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> imagem2 [[texture(1)]],
    texture2d<float> imagem3 [[texture(2)]],
    texture2d<float> imagem4 [[texture(3)]],
    texture2d<float> imagem5 [[texture(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    R = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    N = clamp(floor(u.count + 0.5), 1.0, float(MAXIMO));
    gRot = radians(u.gridRotation);
    colunas = max(1.0, floor(u.columns + 0.5));
    espaco = float2(u.spacingX * R.x, u.spacingY * R.y) / 100.0;
    raioPx = u.radius / 100.0 * R.x;
    raioDoCaminho = raioPx * float2(1.0, u.pathHeight / 100.0);
    giroDaEsfera = float3x3(1.0);

    int formaA = u.shape;
    int formaB = u.morphTo == 0 ? u.shape : u.morphTo - 1;
    float vira = u.morphTo == 0 || formaB == formaA ? 0.0 : clamp(u.morphAmount / 100.0, 0.0, 1.0);
    if (formaA == 2 || (vira > 0.0 && formaB == 2)) giroDaEsfera = montarGiroDaEsfera();

    // As imagens em rodízio: a camada, e as outras que foram escolhidas.
    int quais[5];
    int nImagens = 1;
    quais[0] = 0;
    if (int2(int(imagem2.get_width()), int(imagem2.get_height())).x > 1) { quais[nImagens] = 1; nImagens++; }
    if (int2(int(imagem3.get_width()), int(imagem3.get_height())).x > 1) { quais[nImagens] = 2; nImagens++; }
    if (int2(int(imagem4.get_width()), int(imagem4.get_height())).x > 1) { quais[nImagens] = 3; nImagens++; }
    if (int2(int(imagem5.get_width()), int(imagem5.get_height())).x > 1) { quais[nImagens] = 4; nImagens++; }

    // Embaralhar: uma permutação das vagas (Fisher–Yates), como na extensão.
    int vaga[MAXIMO];
    int n = int(N);
    float emb = floor(u.shuffle + 0.5);
    if (emb > 0.0 && n > 1) {
        for (int a = 0; a < MAXIMO; a++) vaga[a] = a;
        for (int a = MAXIMO - 1; a > 0; a--) {
            if (a >= n) continue;
            int b = min(int(floor(acaso(emb, float(a)) * float(a + 1))), a);
            int t = vaga[a]; vaga[a] = vaga[b]; vaga[b] = t;
        }
    }

    float3 o, d, o2, dx;
    raio(uv, o, d);
    raio(uv + float2(1.0 / R.x, 0.0), o2, dx);
    float porPixel = length(dx - d);            // quanto o raio abre de um pixel para o vizinho
    float3 dn = normalize(d);

    // Os eixos da câmera (para "Para a câmera"): sem câmera, a vista é de frente.
    float3x3 daCamera = float3x3(1.0);
    if (eng.acCamera3D == 1) {
        float3 a, b, c, lixo;
        raio(float2(0.5, 0.5), lixo, a);
        raio(float2(0.5, 0.5) + float2(1.0 / R.x, 0.0), lixo, b);
        raio(float2(0.5, 0.5) + float2(0.0, 1.0 / R.y), lixo, c);
        float3 z = normalize(a), x = normalize(b - a);
        x = normalize(x - z * dot(x, z));
        daCamera = float3x3(x, cross(z, x), z);
    }

    float3 centro = float3(u.center * R, 0.0);
    float3 pontoProx = float3(u.proxPoint * R, 0.0) - centro;
    float2 celula = R * u.cellSize / 100.0;        // o tamanho de uma cópia com escala 100%
    float3 eixos = float3(
        u.staggerAxis == 0 || u.staggerAxis == 1 || u.staggerAxis == 4 || u.staggerAxis == 5 ? 1.0 : 0.0,
        u.staggerAxis == 0 || u.staggerAxis == 2 || u.staggerAxis == 4 || u.staggerAxis == 6 ? 1.0 : 0.0,
        u.staggerAxis == 0 || u.staggerAxis == 3 || u.staggerAxis == 5 || u.staggerAxis == 6 ? 1.0 : 0.0);

    float ts[CAMADAS];
    float4 cs[CAMADAS];
    for (int k = 0; k < CAMADAS; k++) { ts[k] = 1e30; cs[k] = float4(0.0); }

    for (int c = 0; c < MAXIMO; c++) {
        if (c >= n) break;
        float i = emb > 0.0 && n > 1 ? float(vaga[c]) : float(c);

        // o lugar
        float3 pA = lugar(formaA, i);
        pA.z += fundo(formaA, i);
        float3 p = pA;
        float3 pB = pA;
        if (vira > 0.0) {
            pB = lugar(formaB, i);
            pB.z += fundo(formaB, i);
            p = mix(pA, pB, vira);
        }
        if (u.randomOffset > 0.0) {
            float chave = floor(u.randomSeed + 0.5) * 131.0 + 7.0;
            p += (float3(acaso(chave, i * 3.0), acaso(chave, i * 3.0 + 1.0), acaso(chave, i * 3.0 + 2.0)) - 0.5) * u.randomOffset / 100.0 * R.x;
        }

        // a escala por posição
        float m = 1.0;
        if (u.scaleFront != 0.0 || u.scaleBack != 0.0) {
            float t = posicaoNaEscala(formaA, i, pA);
            if (vira > 0.0) t = mix(t, posicaoNaEscala(formaB, i, pB), vira);
            m = max(1.0 + (1.0 - t) * u.scaleFront / 100.0 + t * u.scaleBack / 100.0, 0.0);
        }
        float opac = u.opacity / 100.0;

        // a proximidade
        if (u.proxOn) {
            float alcance = max(u.proxRadius / 100.0 * R.x, 0.001);
            float dist = distance(p, pontoProx);
            float perto = 1.0 - smoothstep(alcance * (1.0 - u.proxFalloff / 100.0) - 0.0001, alcance, dist);
            m = max(m * (1.0 + perto * u.proxScale / 100.0), 0.0);
            opac *= clamp(1.0 + perto * u.proxOpacity / 100.0, 0.0, 1.0);
            float3 para = p - pontoProx;
            float lp = length(para.xy);
            if (lp > 0.0001) p.xy += para.xy / lp * perto * u.proxPush / 100.0 * R.x;
            p.z -= perto * u.proxLift / 100.0 * R.x;
        }
        if (m <= 0.0 || opac <= 0.0) continue;

        // longe do raio? nem monta o giro
        float3 mundo = centro + p;
        float3 ate = mundo - o;
        float aoLongo = dot(ate, dn);
        float alcanceDaCopia = 0.5 * length(celula) * m + 2.0;
        if (dot(ate, ate) - aoLongo * aoLongo > alcanceDaCopia * alcanceDaCopia) continue;

        // para onde a cópia está virada
        float3x3 B = base(formaA, i, p, daCamera);
        if (vira > 0.0) {
            float3x3 B2 = base(formaB, i, p, daCamera);
            float3 z = normalize(mix(B[2], B2[2], vira));
            float3 x = mix(B[0], B2[0], vira);
            x = normalize(x - z * dot(x, z));
            B = float3x3(x, cross(z, x), z);
        }
        float degrau = N > 1.0 ? i / (N - 1.0) : 0.0;
        float3 g = radians(float3(u.twistX, u.twistY, u.twistZ) + u.stagger * eixos * degrau);
        float3x3 F = B * (girarZ(g.z) * girarY(g.y) * girarX(g.x));

        // o raio no plano da cópia
        float den = dot(d, F[2]);
        if (abs(den) < 1e-7) continue;
        float t = dot(ate, F[2]) / den;
        if (t <= 0.0) continue;
        float3 q = o + d * t - mundo;
        float2 local = float2(dot(q, F[0]), dot(q, F[1]));
        float2 tam = celula * m;
        float px = t * porPixel;                                   // um pixel da tela, em px do mundo, ali
        float2 borda = clamp((0.5 * tam - abs(local)) / max(px, 1e-4) + 0.5, 0.0, 1.0);
        float cobre = borda.x * borda.y;
        if (cobre <= 0.0) continue;

        float2 uvC = local / tam + 0.5;
        float reduz = px / max(u.cellSize / 100.0 * m, 1e-4);        // texels da imagem por pixel da tela
        int toques = reduz > 3.0 ? 3 : reduz > 1.3 ? 2 : 1;
        float4 cor = amostra(quais[c - (c / nImagens) * nImagens], uvC, float2(reduz) / R, toques) * cobre * opac;
        if (cor.a <= 0.002) continue;

        // guarda entre as mais próximas (no empate, a primeira cópia fica por cima)
        for (int k = 0; k < CAMADAS; k++) {
            if (t < ts[k]) {
                for (int j = CAMADAS - 1; j > k; j--) { ts[j] = ts[j - 1]; cs[j] = cs[j - 1]; }
                ts[k] = t; cs[k] = cor;
                break;
            }
        }
    }

    // da frente para trás
    float4 saida = float4(0.0);
    for (int k = 0; k < CAMADAS; k++) saida += cs[k] * (1.0 - saida.a);
    __nv_out = saida.a > 0.0 ? float4(saida.rgb / saida.a, saida.a) : float4(0.0);
    return __nv_out;
}
