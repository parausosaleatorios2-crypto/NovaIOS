// ---------------------------------------------------------------------------
// Rastreador de blobs (rastreio real)
// origem : assets/effects/blob-tracker-v2.xml
// id     : nova.effect.blobtrackerv2
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct blob_tracker_v2Params {
    int source;
    float4 keyColor;
    float hueStart;
    float hueEnd;
    float cut;
    float preBlur;
    float minArea;
    int boxStyle;
    float4 boxColor;
    float boxWidth;
    float cornerLen;
    float fillOpacity;
    float4 fillColor;
    float flicker;
    int marker;
    float markerSize;
    float4 markerColor;
    int showLabel;
    int labelData;
    float labelSize;
    float4 labelColor;
    int showTrail;
    float4 trailColor;
    float trailWidth;
    int topology;
    float4 connColor;
    float connWidth;
    int keypoints;
    float kpDensity;
    float kpSize;
    float4 kpColor;
    float softness;
    float maxArea;
    float padding;
    int debug;
};

// --- funcoes auxiliares do efeito
// ===========================================================================
//  A máscara: exatamente a mesma lógica da v1 (blob-tracker.xml)
// ===========================================================================
float lumaOf(float3 c) { return dot(c, float3(0.299, 0.587, 0.114)); }

// RGB -> HSV clássico (Sam Hocevar). Usado por saturação e faixa de matiz.
float3 rgb2hsv(float3 c) {
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 pp = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 qq = mix(float4(pp.xyw, c.r), float4(c.r, pp.yzx), step(pp.x, c.r));
    float dd = qq.x - min(qq.w, qq.y);
    float ee = 1.0e-10;
    return float3(abs(qq.z + (qq.w - qq.y) / (6.0 * dd + ee)), dd / (qq.x + ee), qq.x);
}

float4 probeAt(int2 px) {
    int2 res = int2(eng.acResolution);
    int2 lo = int2(0);
    int2 hi = res - 1;
    int r = int(floor(u.preBlur * 4.0 + 0.5));
    if (r <= 0) return probeImg.read(uint2(clamp(px, lo, hi)), uint(0));
    float4 acc = probeImg.read(uint2(clamp(px, lo, hi)), uint(0)) * 2.0;
    acc += probeImg.read(uint2(clamp(px + int2(r, 0), lo, hi)), uint(0));
    acc += probeImg.read(uint2(clamp(px - int2(r, 0), lo, hi)), uint(0));
    acc += probeImg.read(uint2(clamp(px + int2(0, r), lo, hi)), uint(0));
    acc += probeImg.read(uint2(clamp(px - int2(0, r), lo, hi)), uint(0));
    return acc / 6.0;
}

float matizNaFaixa(float h, float ini, float fim, float soft) {
    float dh = fract(h - ini);
    float largura = fract(fim - ini);
    if (largura <= 0.0) largura = 1.0;
    float edge = max(soft, 0.001);
    return 1.0 - smoothstep(largura - edge, largura, dh);
}

float mascaraEm(int2 px) {
    int2 res = int2(eng.acResolution);
    int2 lo = int2(0);
    int2 hi = res - 1;
    float4 c = probeAt(px);
    float lum = lumaOf(c.rgb);

    if (u.source == 0) return c.a;                              // Alfa
    if (u.source == 1) return lum * c.a;                        // Luz clara
    if (u.source == 2) return (1.0 - lum) * c.a;                // Luz escura
    if (u.source == 3) {                                        // O que NÃO é a cor-chave
        float dif = length(c.rgb - u.keyColor.rgb);
        return smoothstep(0.0, max(u.cut, 0.02) * 1.5 + u.softness * 0.5, dif) * c.a;
    }
    if (u.source == 4) return clamp((c.r - max(c.g, c.b)) * 2.0, 0.0, 1.0) * c.a;  // Vermelho
    if (u.source == 5) return clamp((c.g - max(c.r, c.b)) * 2.0, 0.0, 1.0) * c.a;  // Verde
    if (u.source == 6) return clamp((c.b - max(c.r, c.g)) * 2.0, 0.0, 1.0) * c.a;  // Azul

    if (u.source == 7) return rgb2hsv(c.rgb).y * c.a;                          // Saturação alta
    if (u.source == 8) return (1.0 - rgb2hsv(c.rgb).y) * step(0.05, lum) * c.a; // Saturação baixa
    if (u.source == 9) {                                                       // Faixa de matiz
        float3 hsv = rgb2hsv(c.rgb);
        return matizNaFaixa(hsv.x, u.hueStart, u.hueEnd, u.softness) * hsv.y * c.a;
    }
    if (u.source == 10) {                                                      // Borda
        float lx1 = lumaOf(probeAt(clamp(px + int2(1, 0), lo, hi)).rgb);
        float lx0 = lumaOf(probeAt(clamp(px - int2(1, 0), lo, hi)).rgb);
        float ly1 = lumaOf(probeAt(clamp(px + int2(0, 1), lo, hi)).rgb);
        float ly0 = lumaOf(probeAt(clamp(px - int2(0, 1), lo, hi)).rgb);
        return clamp(length(float2(lx1 - lx0, ly1 - ly0)) * 2.0, 0.0, 1.0) * c.a;
    }
    // 11: Movimento — diferença de luminância entre este quadro e o anterior.
    float lp = lumaOf(prevImg.read(uint2(clamp(px, lo, hi)), uint(0)).rgb);
    return clamp(abs(lum - lp) * 4.0, 0.0, 1.0) * c.a;
}

// ===========================================================================
//  Passe 0 — a máscara inteira, um valor por pixel (nada de pirâmide aqui:
//  quem reduz é a CPU, via ConnectedComponents, não este shader)
// ===========================================================================
float4 passeMascara(int2 t, int2 tam) {
    if (t.x >= tam.x || t.y >= tam.y) return float4(0.0);
    float m = mascaraEm(t);
    return float4(m, m, m, m); // os 4 canais iguais: BlobDetectionEngine lê 1 só.
}

// ===========================================================================
//  Desenho — primitivas (idênticas à v1: já testadas ali)
// ===========================================================================
float2 paraAltura(float2 uv) { return float2(uv.x * eng.acAspect, uv.y); }

float ruido(float x) { return fract(sin(x * 127.1 + 311.7) * 43758.5453); }

float4 sobre(float4 baixo, float4 cima) {
    float a = cima.a + baixo.a * (1.0 - cima.a);
    if (a <= 0.0) return float4(0.0);
    float3 rgb = (cima.rgb * cima.a + baixo.rgb * baixo.a * (1.0 - cima.a)) / a;
    return float4(rgb, a);
}

float caixaSdf(float2 p, float2 meio) {
    float2 d = abs(p) - meio;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float segmentoSdf(float2 p, float2 a, float2 b) {
    float2 pa = p - a;
    float2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-8), 0.0, 1.0);
    return length(pa - ba * h);
}

// ---------------------------------------------------------------- dígitos
int segMask(int d) {
    if (d == 0) return 63;
    if (d == 1) return 6;
    if (d == 2) return 91;
    if (d == 3) return 79;
    if (d == 4) return 102;
    if (d == 5) return 109;
    if (d == 6) return 125;
    if (d == 7) return 7;
    if (d == 8) return 127;
    return 111; // 9
}

float umSeg(float2 uv, float2 c, float2 meio, float aa) {
    return 1.0 - smoothstep(-aa, aa, caixaSdf(uv - c, meio));
}

float digito(float2 uv, int m, float aa) {
    float t = 0.12;
    float cov = 0.0;
    if ((m & 1) != 0)  cov = max(cov, umSeg(uv, float2(0.5, 0.10), float2(0.30, t), aa)); // a
    if ((m & 64) != 0) cov = max(cov, umSeg(uv, float2(0.5, 0.50), float2(0.30, t), aa)); // g
    if ((m & 8) != 0)  cov = max(cov, umSeg(uv, float2(0.5, 0.90), float2(0.30, t), aa)); // d
    if ((m & 32) != 0) cov = max(cov, umSeg(uv, float2(0.12, 0.30), float2(t, 0.22), aa)); // f
    if ((m & 2) != 0)  cov = max(cov, umSeg(uv, float2(0.88, 0.30), float2(t, 0.22), aa)); // b
    if ((m & 16) != 0) cov = max(cov, umSeg(uv, float2(0.12, 0.70), float2(t, 0.22), aa)); // e
    if ((m & 4) != 0)  cov = max(cov, umSeg(uv, float2(0.88, 0.70), float2(t, 0.22), aa)); // c
    return cov;
}

int contaDigitos(int v) {
    int n = 1;
    int x = v;
    for (int i = 0; i < 5; i++) { if (x >= 10) { x /= 10; n++; } }
    return n;
}

int pot10(int n) {
    int r = 1;
    for (int i = 0; i < 5; i++) { if (i < n) r *= 10; }
    return r;
}

void desenhaNumero(inout float4 hud, float2 org, float h, int valor, int maxD, float4 col, float2 p, float aa) {
    int nd = min(contaDigitos(valor), maxD);
    float dw = h * 0.60;
    float gap = h * 0.22;
    float total = float(nd) * dw + float(nd - 1) * gap;
    if (p.x < org.x - aa || p.x > org.x + total + aa) return;
    if (p.y < org.y - aa || p.y > org.y + h + aa) return;

    float aauv = (aa / max(h, 1e-4)) * 2.0;
    for (int k = 0; k < 5; k++) {
        if (k >= nd) break;
        float x0 = org.x + float(k) * (dw + gap);
        float2 uv = float2((p.x - x0) / dw, (p.y - org.y) / h);
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) continue;
        int place = nd - 1 - k;
        int dgt = (valor / pot10(place)) - (valor / pot10(place + 1)) * 10;
        float cov = digito(uv, segMask(dgt), aauv);
        hud = sobre(hud, float4(col.rgb, cov * col.a));
    }
}

// ---------------------------------------------------------------- letras x/y e ":"
// A fonte de 7 segmentos não tem diagonal — não dá pra fazer um "x". Estas letras
// são traçadas com segmentos de reta na mesma célula 0..1 dos dígitos, então
// alinham com eles. `tipo`: 0='x', 1='y', 2=':'.
float traco(float2 uv, float2 a, float2 b, float w, float aa) {
    return 1.0 - smoothstep(w - aa, w + aa, segmentoSdf(uv, a, b));
}

void desenhaGlifo(inout float4 hud, float2 org, float largura, float h, int tipo, float4 col, float2 p, float aa) {
    if (p.x < org.x - aa || p.x > org.x + largura + aa) return;
    if (p.y < org.y - aa || p.y > org.y + h + aa) return;
    float2 uv = float2((p.x - org.x) / largura, (p.y - org.y) / h);
    float aauv = (aa / max(h, 1e-4)) * 2.0;
    float w = 0.14;
    float cov = 0.0;
    if (tipo == 0) {                                   // x — duas diagonais
        cov = max(cov, traco(uv, float2(0.15, 0.18), float2(0.85, 0.90), w, aauv));
        cov = max(cov, traco(uv, float2(0.85, 0.18), float2(0.15, 0.90), w, aauv));
    } else if (tipo == 1) {                            // y — dois braços e a perna
        cov = max(cov, traco(uv, float2(0.15, 0.18), float2(0.50, 0.58), w, aauv));
        cov = max(cov, traco(uv, float2(0.85, 0.18), float2(0.50, 0.58), w, aauv));
        cov = max(cov, traco(uv, float2(0.50, 0.58), float2(0.32, 0.92), w, aauv));
    } else {                                           // : — dois pontos
        cov = max(cov, umSeg(uv, float2(0.5, 0.42), float2(0.11, 0.11), aauv));
        cov = max(cov, umSeg(uv, float2(0.5, 0.74), float2(0.11, 0.11), aauv));
    }
    hud = sobre(hud, float4(col.rgb, cov * col.a));
}

float larguraNumero(int valor, float dw, float gap, int maxD) {
    int nd = min(contaDigitos(valor), maxD);
    return float(nd) * dw + float(nd - 1) * gap;
}

// ===========================================================================
//  Leitura de blobBuf — o inverso exato de BlobDetectionEngine.codificar()
// ===========================================================================
const int PONTOS_DE_TRILHA = 5; // ver BlobDetectionEngine.PONTOS_DE_TRILHA — os dois têm que bater.
const int TEXELS_ESCALARES_POR_BLOB = 3;
const int TEXELS_POR_BLOB = TEXELS_ESCALARES_POR_BLOB + PONTOS_DE_TRILHA;
// Teto de custo do laço por pixel — ver o aviso no cabeçalho do arquivo. Caiu
// de 48 (a versão sem trilha) para 24 por causa do custo extra que a trilha
// e a MST somam por blob.
const int MAX_BLOBS = 24;

struct BlobLido {
    int id;
    float2 centroAltura;   // espaço-altura (paraAltura já aplicado)
    float2 meioAltura;     // meia-largura/meia-altura, espaço-altura
    float xPixelFrac;    // posição x normalizada crua (0..1) — para o rótulo "Coordenada X"
    float yPixelFrac;    // posição y normalizada crua (0..1) — para o rótulo "Coordenada X,Y"
    float areaFrac;      // área da bbox, fração da tela — para o rótulo "Área %"
    float confianca;
    bool nascido;
    float2 trilha[PONTOS_DE_TRILHA]; // espaço-altura, mais antigo primeiro
};

bool lerBlob(int slot, out BlobLido b) {
    int base = slot * TEXELS_POR_BLOB;
    int4 t0 = int4(blobBuf.read(uint2(int2(base + 0, 0)), uint(0)) * 255.0 + 0.5);
    int id = (t0.r << 8) | t0.g;
    if (id == 0) return false;

    int x16 = (t0.b << 8) | t0.a;
    int4 t1 = int4(blobBuf.read(uint2(int2(base + 1, 0)), uint(0)) * 255.0 + 0.5);
    int y16 = (t1.r << 8) | t1.g;
    int meiaLarguraB = t1.b;
    int meiaAlturaB = t1.a;
    int4 t2 = int4(blobBuf.read(uint2(int2(base + 2, 0)), uint(0)) * 255.0 + 0.5);
    int flagsConf = t2.r;

    float2 posNorm = float2(float(x16) / 65535.0, float(y16) / 65535.0);
    float2 meioNorm = float2(float(meiaLarguraB) / 255.0, float(meiaAlturaB) / 255.0);

    b.id = id;
    b.centroAltura = paraAltura(posNorm);
    b.meioAltura = paraAltura(meioNorm);
    b.xPixelFrac = posNorm.x;
    b.yPixelFrac = posNorm.y;
    b.areaFrac = (meioNorm.x * 2.0) * (meioNorm.y * 2.0);
    b.confianca = float(flagsConf & 127) / 127.0;
    b.nascido = (flagsConf & 128) != 0;

    for (int p = 0; p < PONTOS_DE_TRILHA; p++) {
        int4 tp = int4(blobBuf.read(uint2(int2(base + TEXELS_ESCALARES_POR_BLOB + p, 0)), uint(0)) * 255.0 + 0.5);
        int tx16 = (tp.r << 8) | tp.g;
        int ty16 = (tp.b << 8) | tp.a;
        b.trilha[p] = paraAltura(float2(float(tx16) / 65535.0, float(ty16) / 65535.0));
    }
    return true;
}

// ---------------------------------------------------------------- desenho de um blob
void desenhaBlob(inout float4 hud, BlobLido b, float2 p) {
    float aa = 1.5 / max(eng.acResolution.y, 1.0);
    float esp = u.boxWidth * 0.01;

    float2 pMin = b.centroAltura - b.meioAltura - float2(u.padding);
    float2 pMax = b.centroAltura + b.meioAltura + float2(u.padding);
    float2 meio = max((pMax - pMin) * 0.5, float2(1e-4));
    float2 centro = (pMin + pMax) * 0.5;

    // A confiança cai enquanto o blob está "coastando" (sem detecção, andando
    // pela previsão) — multiplicar a opacidade por ela faz o HUD desbotar
    // sozinho até o quadro em que o rastreador desiste de vez.
    float alfaBase = b.confianca;

    float d = caixaSdf(p - centro, meio);

    if (u.fillOpacity > 0.0) {
        float dentro = 1.0 - smoothstep(-aa, aa, d);
        hud = sobre(hud, float4(u.fillColor.rgb, dentro * u.fillOpacity * u.fillColor.a * alfaBase));
    }

    if (u.boxStyle != 2) {
        float borda = 1.0 - smoothstep(esp * 0.5 - aa, esp * 0.5 + aa, abs(d));
        if (u.boxStyle == 0) {
            float2 sobra = meio - abs(p - centro);
            float lado = u.cornerLen * min(meio.x, meio.y);
            borda *= 1.0 - smoothstep(lado - aa, lado + aa, max(sobra.x, sobra.y));
        }
        hud = sobre(hud, float4(u.boxColor.rgb, borda * u.boxColor.a * alfaBase));
    }

    if (u.marker != 0) {
        float2 rel = p - centro;
        float braco = u.markerSize;
        float alvo = 0.0;
        if (u.marker == 1 || u.marker == 3) {
            float haste = (1.0 - smoothstep(esp * 0.5 - aa, esp * 0.5 + aa, abs(rel.y))) *
                          (1.0 - smoothstep(braco - aa, braco + aa, abs(rel.x)));
            float vert = (1.0 - smoothstep(esp * 0.5 - aa, esp * 0.5 + aa, abs(rel.x))) *
                         (1.0 - smoothstep(braco - aa, braco + aa, abs(rel.y)));
            alvo = max(haste, vert);
        }
        if (u.marker == 2 || u.marker == 3) {
            float raio = u.marker == 3 ? braco * 0.55 : braco;
            float anel = 1.0 - smoothstep(esp * 0.5 - aa, esp * 0.5 + aa, abs(length(rel) - raio));
            alvo = max(alvo, anel);
        }
        hud = sobre(hud, float4(u.markerColor.rgb, alvo * u.markerColor.a * alfaBase));
    }

    if (u.showLabel) {
        float2 org = float2(pMin.x, max(pMin.y - u.labelSize * 1.35, aa));
        if (u.labelData == 3) {
            // Coordenada X,Y — "x:NNN  y:NNN", como nas referências.
            int vx = int(b.xPixelFrac * eng.acResolution.x);
            int vy = int(b.yPixelFrac * eng.acResolution.y);
            float h = u.labelSize;
            float dw = h * 0.60;
            float gap = h * 0.22;
            float lw = h * 0.55;   // largura de uma letra
            float cw = h * 0.34;   // largura do ":"
            float cur = org.x;
            desenhaGlifo(hud, float2(cur, org.y), lw, h, 0, u.labelColor, p, aa); cur += lw + gap * 0.5;   // x
            desenhaGlifo(hud, float2(cur, org.y), cw, h, 2, u.labelColor, p, aa); cur += cw + gap;         // :
            desenhaNumero(hud, float2(cur, org.y), h, vx, 5, u.labelColor, p, aa);
            cur += larguraNumero(vx, dw, gap, 5) + h * 0.55;                                           // espaço
            desenhaGlifo(hud, float2(cur, org.y), lw, h, 1, u.labelColor, p, aa); cur += lw + gap * 0.5;   // y
            desenhaGlifo(hud, float2(cur, org.y), cw, h, 2, u.labelColor, p, aa); cur += cw + gap;         // :
            desenhaNumero(hud, float2(cur, org.y), h, vy, 5, u.labelColor, p, aa);
        } else {
            int valor = b.id;
            int maxD = 5;
            if (u.labelData == 1) { valor = int(b.areaFrac * 10000.0 + 0.5); maxD = 4; }
            else if (u.labelData == 2) { valor = int(b.xPixelFrac * eng.acResolution.x); maxD = 5; }
            desenhaNumero(hud, org, u.labelSize, valor, maxD, u.labelColor, p, aa);
        }
    }
}

// ---------------------------------------------------------------- trilha
// Segmentos retos ligando os PONTOS_DE_TRILHA pontos, mais antigo→mais
// recente — sem reamostragem por Catmull-Rom (que existe, testada, em
// `CatmullRom.kt`): suavizar a curva no shader multiplicaria por ~4 o número
// de segmentos por blob, e o custo por pixel já é o maior risco não medido
// desta versão (ver o cabeçalho do arquivo). A cauda desbota: o segmento
// mais antigo é o mais transparente.
void desenhaTrilha(inout float4 hud, BlobLido b, float2 p) {
    float aa = 1.5 / max(eng.acResolution.y, 1.0);
    float w = u.trailWidth * 0.01;
    for (int i = 0; i < PONTOS_DE_TRILHA - 1; i++) {
        float d = segmentoSdf(p, b.trilha[i], b.trilha[i + 1]);
        float linha = 1.0 - smoothstep(w * 0.5 - aa, w * 0.5 + aa, d);
        float peso = float(i + 1) / float(PONTOS_DE_TRILHA - 1);
        hud = sobre(hud, float4(u.trailColor.rgb, linha * u.trailColor.a * peso * b.confianca));
    }
}

// ---------------------------------------------------------------- MST
// Lê as arestas de `blobBuf` — ver o cabeçalho do arquivo para o layout — e
// desenha uma linha reta entre os centros de cada par. `blobs`/`contagem`
// vêm do MESMO laço de leitura que já decodificou os blobs para desenhá-los,
// então isto não faz nenhuma leitura de textura a mais por blob, só por
// aresta.
const int MAX_ARESTAS = MAX_BLOBS;

void desenhaArestasMst(inout float4 hud, BlobLido blobs[MAX_BLOBS], int contagem, float2 p) {
    float aa = 1.5 / max(eng.acResolution.y, 1.0);
    float w = u.connWidth * 0.01;
    int base = (contagem + 1) * TEXELS_POR_BLOB; // +1: o bloco vazio de separação (ver o cabeçalho).

    for (int e = 0; e < MAX_ARESTAS; e++) {
        int4 te = int4(blobBuf.read(uint2(int2(base + e, 0)), uint(0)) * 255.0 + 0.5);
        if (te.r >= 255) break; // sentinela: fim das arestas.
        int de = te.r;
        int para = te.g;
        if (de < 0 || de >= contagem || para < 0 || para >= contagem) continue; // defensivo.
        float d = segmentoSdf(p, blobs[de].centroAltura, blobs[para].centroAltura);
        float linha = 1.0 - smoothstep(w * 0.5 - aa, w * 0.5 + aa, d);
        hud = sobre(hud, float4(u.connColor.rgb, linha * u.connColor.a));
    }
}

// ---------------------------------------------------------------- pontos-chave
// Uma cruz por célula de uma grade jitterada, onde a máscara passa do Threshold.
// Independe dos blobs (as caixas seguem os blobs; isto não) — é a "chuva de
// keypoints" das referências. Cada pixel olha só a PRÓPRIA célula: é UMA leitura
// de máscara a mais por pixel (ver o aviso de custo no cabeçalho), e a cruz é
// presa ao tamanho da célula para não recortar na borda dela.
void desenhaKeypoints(inout float4 hud, float2 p, float aa) {
    float2 uvn = in.acScreenNorm;
    float cols = mix(14.0, 90.0, clamp(u.kpDensity, 0.0, 1.0));
    float2 grade = float2(cols, max(cols / eng.acAspect, 1.0));
    float2 cel = floor(uvn * grade);

    // Liga só parte das células, para não virar uma grade perfeita.
    if (ruido(cel.x * 131.0 + cel.y * 17.3) < 0.30) return;

    float2 jit = float2(ruido(cel.x * 12.9 + cel.y * 78.2), ruido(cel.x * 39.3 + cel.y * 11.1));
    float2 centroN = (cel + 0.2 + 0.6 * jit) / grade;
    if (mascaraEm(int2(centroN * eng.acResolution)) <= u.cut) return;

    float2 rel = p - paraAltura(centroN);
    float s = eng.acAspect / cols;                 // lado da célula em espaço-altura
    float braco = min(u.kpSize, s * 0.42);       // não deixa a cruz passar da célula
    float esp = u.boxWidth * 0.01;
    float haste = (1.0 - smoothstep(esp * 0.5 - aa, esp * 0.5 + aa, abs(rel.y))) *
                  (1.0 - smoothstep(braco - aa, braco + aa, abs(rel.x)));
    float vert = (1.0 - smoothstep(esp * 0.5 - aa, esp * 0.5 + aa, abs(rel.x))) *
                 (1.0 - smoothstep(braco - aa, braco + aa, abs(rel.y)));
    hud = sobre(hud, float4(u.kpColor.rgb, max(haste, vert) * u.kpColor.a));
}

// ===========================================================================
//  main
// ===========================================================================

fragment float4 fx_blob_tracker_v2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant blob_tracker_v2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> prevImg [[texture(1)]],
    texture2d<float> maskBuf [[texture(2)]],
    texture2d<float> blobBuf [[texture(3)]],
    texture2d<float> probeImg [[texture(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 t = int2(__nv_fragCoord.xy);
    int2 tam = int2(eng.acResolution);

    if (eng.acPass == 0) { __nv_out = passeMascara(t, tam); return __nv_out; }
    // O passe 1 é de ANÁLISE: o EffectPipeline nunca roda este branch de
    // verdade (ele substitui o passe inteiro por CPU — ver o cabeçalho do
    // arquivo). Este preenchimento existe só para o shader ficar bem-formado
    // caso algum caminho o execute por engano.
    if (eng.acPass == 1) { __nv_out = float4(0.0); return __nv_out; }

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    if (u.debug == 1) {
        float m = mascaraEm(int2(in.acScreenNorm * eng.acResolution));
        float dentro = step(u.cut, m);
        float3 pint = mix(float3(0.05, 0.05, 0.08), float3(1.0, 0.25, 0.6), dentro);
        __nv_out = float4(mix(original.rgb * 0.25, pint, 0.75), max(original.a, dentro));
        return __nv_out;
    }

    float2 p = paraAltura(in.acScreenNorm);
    float4 hud = float4(0.0);

    // Uma leitura só de blobBuf por blob: o array local é reusado para a
    // MST (que referencia blobs por índice, não em sequência) e para o
    // desenho — sem isso, cada aresta pediria decodificar os dois blobs
    // dela de novo.
    BlobLido blobs[MAX_BLOBS];
    int contagem = 0;
    for (int slot = 0; slot < MAX_BLOBS; slot++) {
        if (!lerBlob(slot, blobs[contagem])) break; // sentinela: acabaram os blobs desta linha.
        contagem++;
    }

    // Conexões por baixo de tudo — o mesmo motivo do v1: uma linha por cima
    // da caixa do outro lado esconderia a própria caixa.
    if (u.topology == 1) desenhaArestasMst(hud, blobs, contagem, p);

    for (int i = 0; i < contagem; i++) {
        if (u.showTrail) desenhaTrilha(hud, blobs[i], p);
        desenhaBlob(hud, blobs[i], p);
    }

    if (u.keypoints) desenhaKeypoints(hud, p, 1.5 / max(eng.acResolution.y, 1.0));

    if (u.flicker > 0.0) {
        float degrau = floor(eng.acTime * 12.0);
        float cintila = 1.0
            - u.flicker * 0.22 * ruido(degrau * 1.7)
            - u.flicker * 0.65 * step(0.9, ruido(degrau + 5.1));
        hud.a *= clamp(cintila, 0.0, 1.0);
    }

    if (u.debug == 2) { __nv_out = sobre(float4(0.02, 0.02, 0.03, 1.0), hud); return __nv_out; }

    __nv_out = sobre(original, hud);
    return __nv_out;
}
