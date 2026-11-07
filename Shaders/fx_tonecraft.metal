// ---------------------------------------------------------------------------
// ToneCraft
// origem : assets/effects/tonecraft.xml
// id     : nova.effect.tonecraft
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct tonecraftParams {
    int shape;
    float cellSize;
    float dotScale;
    float offsetX;
    float offsetY;
    float rotation;
    float contrast;
    float mixAmount;
    int invert;
    int transparentBg;
    int colorScheme;
    float gradientAmount;
    float2 gradientStart;
    float2 gradientEnd;
    float4 startColor;
    float4 endColor;
    int shape1;
    int shape2;
    int shape3;
    int shape4;
    int shape5;
    float softness;
    float highlightDetail;
    float paperTint;
    float blackWear;
};

// --- funcoes auxiliares do efeito
// Medidos no plugin (tools/tonecraft/benchmark):
const float RAIO = 0.64;              // o "raio" do ponto de tom 1, em células
const float BORDA = 0.0704;            // a largura da borda suave (smoothstep), em células
const float BORDA_SOFT = 0.0036;  // quanto cada ponto de Softness soma a ela
const uint SAKURA[128] = uint[128](0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 3221225472u, 3u, 3758096384u, 7u, 4026531840u, 15u, 4160749568u, 63u, 4278190080u, 255u, 4286578688u, 511u, 4290772992u, 1023u, 4292870144u, 2047u, 4292870144u, 2047u, 4293918720u, 2047u, 4293918720u, 4095u, 4293918720u, 4095u, 4293918720u, 2047u, 4292870144u, 460799u, 4293130240u, 2082815u, 4293918208u, 8385535u, 4292869888u, 8387583u, 4290772736u, 16776703u, 4294967168u, 67108607u, 4286578656u, 134217471u, 4278190072u, 536870783u, 4244635644u, 1073741759u, 4194303996u, 1073741727u, 4093640696u, 536870863u, 1677721592u, 536870854u, 3892314096u, 268435431u, 4160487408u, 268427247u, 4287627248u, 268431871u, 4177526768u, 134217503u, 4294967280u, 134217727u, 4294967264u, 134217727u, 4294967264u, 134217727u, 4244635616u, 134217503u, 4162846656u, 67107871u, 4152885120u, 33546735u, 4026400256u, 8331255u, 939458560u, 65516u, 2147467264u, 262142u, 2080370688u, 1048542u, 2113927168u, 2097086u, 2130704384u, 2097022u, 2130705408u, 4194174u, 2147482624u, 4194302u, 4294966272u, 4194303u, 4294966272u, 4194303u, 4294966272u, 4194303u, 4294966272u, 4194303u, 4294966272u, 4194303u, 2147481600u, 2097150u, 2147479552u, 1048574u, 2147479552u, 1048574u, 2147475456u, 524286u, 1073733632u, 524284u, 536862720u, 524280u, 536862720u, 524280u, 134201344u, 262112u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u);
const uint CORACAO[128] = uint[128](0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 8372224u, 261632u, 67106816u, 2097088u, 134216704u, 4194272u, 536870400u, 8388592u, 1073741568u, 33554428u, 1073741696u, 33554428u, 2147483584u, 67108862u, 4294967264u, 134217727u, 4294967264u, 134217727u, 4294967280u, 268435455u, 4294967280u, 268435455u, 4294967280u, 268435455u, 4294967280u, 268435455u, 4294967288u, 536870911u, 4294967288u, 536870911u, 4294967288u, 536870911u, 4294967288u, 536870911u, 4294967280u, 268435455u, 4294967280u, 268435455u, 4294967280u, 268435455u, 4294967280u, 268435455u, 4294967264u, 134217727u, 4294967264u, 134217727u, 4294967264u, 134217727u, 4294967232u, 67108863u, 4294967232u, 67108863u, 4294967168u, 33554431u, 4294967040u, 16777215u, 4294967040u, 16777215u, 4294966784u, 8388607u, 4294966272u, 4194303u, 4294965248u, 2097151u, 4294963200u, 1048575u, 4294959104u, 524287u, 4294950912u, 262143u, 4294934528u, 131071u, 4294901760u, 65535u, 4294836224u, 32767u, 4294705152u, 16383u, 4294443008u, 8191u, 4293918720u, 4095u, 4292870144u, 2047u, 4286578688u, 511u, 4278190080u, 255u, 4261412864u, 127u, 4227858432u, 63u, 4160749568u, 31u, 3758096384u, 7u, 3221225472u, 3u, 2147483648u, 1u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u);

static float2 tamanho() { return float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))); }

static float2x2 giro(float graus) {
    float a = radians(graus), c = cos(a), s = sin(a);
    return float2x2(c, s, -s, c);
}

/** O ângulo (graus) da tela `k`: 0 no mono; no CMYK cada tinta tem o seu (medidos; não há tela de preto). */
static float anguloDaTela(int k) {
    float a = u.rotation;
    if (u.colorScheme == 1) a += k == 0 ? -23.0 : k == 1 ? 100.0 : 136.0;
    return a;
}

static float lado() { return max(u.cellSize, 2.0) * eng.acEscalaDePixel; }

/** Do pixel da camada para o espaço da grade da tela `k` (as divisas das células passam pelo centro do quadro). */
static float2 paraGrade(float2 p, int k) {
    return giro(-anguloDaTela(k)) * (p - 0.5 * tamanho() - float2(u.offsetX, u.offsetY) * eng.acEscalaDePixel);
}
static float2 daGrade(float2 q, int k) {
    return giro(anguloDaTela(k)) * q + 0.5 * tamanho() + float2(u.offsetX, u.offsetY) * eng.acEscalaDePixel;
}

/** As tintas (C, M, Y) da cor; no mono só a primeira conta: o brilho (Rec.709, medido). */
static float4 tintas(float4 c) {
    float3 rgb = c.rgb;                                   // medido: o plugin lê a cor e ignora o alfa
    if (u.colorScheme == 0) return float4(dot(rgb, float3(0.2126, 0.7152, 0.0722)), 0.0, 0.0, 1.0);
    float3 cmy = 1.0 - rgb;
    return float4(cmy, 0.0);
}

static float tintaEm(float2 px, int k);

/**
 * O tom da célula que contém `p`, na tela `k`. Medido (com uma fonte de um bloco preto por célula): o
 * plugin NÃO faz a média da célula — lê 9 pixels dela, o do centro e os oito a ±d em cada eixo, com
 * d = 0,3 célula até o teto de 12.0 px. Fora do quadro conta como papel.
 */
static float mediaDaCelula(float2 p, int k) {
    float c = lado();
    float2 R = tamanho();
    float2 q = paraGrade(p, k);
    float2 centro = (floor(q / c) + 0.5) * c;
    float d = min(0.3 * c, 12.0 * eng.acEscalaDePixel);
    float soma = 0.0;
    for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++) {
        soma += tintaEm(floor(daGrade(centro + float2(float(i), float(j)) * d, k)) + 0.5, k);
    }
    soma /= 9.0;
    return u.colorScheme == 0 ? 1.0 - soma : soma;
}

/** A tinta (0..1) que a tela `k` lê no pixel `px` da camada; fora do quadro é papel. */
static float tintaEm(float2 px, int k) {
    float2 R = tamanho();
    if (px.x < 0.0 || px.y < 0.0 || px.x > R.x || px.y > R.y) return 0.0;
    float4 t = tintas(inputImg.sample(__nv_smp, px / R));
    return k == 0 ? (u.colorScheme == 0 ? 1.0 - t.x : t.x) : k == 1 ? t.y : t.z;
}

/**
 * A Linha não é por célula (medido): ao longo dela o tom é lido pixel a pixel — três leituras na fileira
 * do centro, em x e a ±d. Por isso a espessura varia de forma contínua.
 */
static float valorDaLinha(float2 q, float centroY, int k) {
    float d = min(0.3 * lado(), 12.0 * eng.acEscalaDePixel);
    float soma = 0.0;
    for (int i = -1; i <= 1; i++) soma += tintaEm(floor(daGrade(float2(q.x + float(i) * d, centroY), k)) + 0.5, k);
    soma /= 3.0;
    return u.colorScheme == 0 ? 1.0 - soma : soma;
}

/** O tom (0 = sem ponto, 1 = ponto cheio) a partir do valor guardado. */
static float tom(float v) {
    float d = u.colorScheme == 0 ? 1.0 - v : v;
    if (u.invert) d = 1.0 - d;
    d = clamp(0.5 + (d - 0.5) * u.contrast / 100.0, 0.0, 1.0);
    return max(d, 0.0);
}

static float texel(int qual, float2 t) {
    if (t.x < 0.0 || t.y < 0.0 || t.x > 63.0 || t.y > 63.0) return 0.0;
    int ix = int(t.x), i = int(t.y) * 2 + (ix >> 5);
    uint palavra = qual == 0 ? SAKURA[i] : CORACAO[i];
    return float((palavra >> uint(ix & 31)) & 1u);
}

/** A sakura e o coração são bitmaps de 64 × 64 no plugin (um texel = s / 31,5), lidos com filtro linear. */
static float bit(int qual, float2 x, float s) {
    float2 u = x / (s / 31.5) + 32.0 - 0.5;
    float2 t = floor(u), f = u - t;
    float v = mix(mix(texel(qual, t), texel(qual, t + float2(1.0, 0.0)), f.x),
                  mix(texel(qual, t + float2(0.0, 1.0)), texel(qual, t + float2(1.0, 1.0)), f.x), f.y);
    return clamp((v - 0.5) * 1.0 + 0.5, 0.0, 1.0);
}

static float sdEstrela(float2 p, float r, float rf) {
    // (a estrela de 5 pontas do Inigo Quilez: r = raio de fora, rf = razão do de dentro)
    const float2 k1 = float2(0.809016994375, -0.587785252292);
    const float2 k2 = float2(-k1.x, k1.y);
    p.x = abs(p.x);
    p -= 2.0 * max(dot(k1, p), 0.0) * k1;
    p -= 2.0 * max(dot(k2, p), 0.0) * k2;
    p.x = abs(p.x);
    p.y -= r;
    float2 ba = rf * float2(-k1.y, k1.x) - float2(0.0, 1.0);
    float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
    return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}

static float sdHexagono(float2 p, float r) {
    const float3 k = float3(-0.866025404, 0.5, 0.577350269);
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= float2(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

static float sdTriangulo(float2 p, float r) {
    // equilátero de ponta para BAIXO na tela, raio circunscrito r (a "distância" é a das três retas)
    return max(-p.y, 0.8660254 * abs(p.x) + 0.5 * p.y) - 0.5 * r;
}

static float sdCaixa(float2 p, float2 b) {
    float2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

static float hash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

/** A distância ao dígito de 7 segmentos `n` (0–9), em unidades de s. */
static float sdDigito(float2 p, int n) {
    // segmentos: a (cima), b (dir. cima), c (dir. baixo), d (baixo), e (esq. baixo), f (esq. cima), g (meio)
    const int SEG[10] = int[10](63, 6, 91, 79, 102, 109, 125, 7, 127, 111);
    int m = SEG[n];
    float d = 1e3;
    float2 h = float2(0.36, 0.02), v = float2(0.02, 0.26);
    if ((m & 1) != 0) d = min(d, sdCaixa(p - float2(0.0, -0.76), h));
    if ((m & 2) != 0) d = min(d, sdCaixa(p - float2(0.52, -0.5 * 0.76), v));
    if ((m & 4) != 0) d = min(d, sdCaixa(p - float2(0.52, 0.5 * 0.76), v));
    if ((m & 8) != 0) d = min(d, sdCaixa(p - float2(0.0, 0.76), h));
    if ((m & 16) != 0) d = min(d, sdCaixa(p - float2(-0.52, 0.5 * 0.76), v));
    if ((m & 32) != 0) d = min(d, sdCaixa(p - float2(-0.52, -0.5 * 0.76), v));
    if ((m & 64) != 0) d = min(d, sdCaixa(p, h));
    return d;
}

/** Quanto do pixel o ponto de forma `f` e tamanho `s` (px) cobre; `x` = px a partir do centro da célula. */
static float ponto(int f, float2 x, float s, float w, float2 celula) {
    if (s <= 0.0 && f != 2) return 0.0;      // (a Linha nunca some: no branco sobra o fio da borda suave)
    float dist, a = 0.5;                 // a: onde a borda suave fica em relação ao contorno (0,5 = centrada)
    if (f == 0) dist = length(x) - s;
    else if (f == 1) { dist = max(abs(x.x), abs(x.y)) - s; a = 0.5; }
    else if (f == 2) { dist = abs(x.y) - s; a = 0.0; }
    else if (f == 3) { dist = length(x) - s * (0.65 + 0.35 * cos(5.0 * __nv_atan(x.y, x.x))); a = 0.5; }
    else if (f == 4) { dist = sdEstrela(float2(x.x, -x.y), s * 1.0, 0.382); a = 0.5; }
    else if (f == 5) { dist = sdHexagono(x, s * 0.8660254); a = 0.5; }
    else if (f == 6) return bit(0, x, s);
    else if (f == 7) { dist = sdDigito(x / s, int(floor(hash(celula) * 10.0))) * s; a = 0.2; w *= 1.2; }
    else if (f == 8) { dist = sdTriangulo(x, s); a = 0.5; }
    else if (f == 9) return bit(1, x, s);
    else { dist = sdCaixa(x, float2(s, 0.2203 * s)); a = 0.5; }      // o traço do Mixed Shape
    return 1.0 - smoothstep(-w * a, w * (1.0 - a), dist);
}

/**
 * A forma da célula. Mixed Shape (medido): as casas LIGADAS se revezam na diagonal — com duas ligadas o
 * período é 2, com cinco é 5; nenhuma ligada = a forma principal em tudo.
 */
static int formaDa(float2 ij, int k) {
    int casas[5] = int[5](u.shape1, u.shape2, u.shape3, u.shape4, u.shape5);
    int ligadas = 0;
    for (int i = 0; i < 5; i++) if (casas[i] != 0) ligadas++;
    if (ligadas == 0) return u.shape;
    int vez = int(__nv_mod(ij.x + ij.y + 0.0, float(ligadas))), f = 0;
    for (int i = 0; i < 5; i++) if (casas[i] != 0) { if (vez == 0) { f = casas[i]; break; } vez--; }
    // na lista do Mixed Shape a 3ª forma não é a Linha inteira, é um traço curto
    return f == 3 ? 10 : f - 1;
}

/** A cobertura da tela `k` no pixel `p`. */
static float tela(float2 p, int k) {
    float c = lado();
    float2 q = paraGrade(p, k);
    float2 ij0 = floor(q / c);
    float w = max(c * (BORDA + BORDA_SOFT * u.softness), 1.0 * eng.acEscalaDePixel);
    float m = 0.0;
    for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++) {
        float2 ij = ij0 + float2(float(i), float(j));
        float2 centro = (ij + 0.5) * c;
        int f = formaDa(ij, k);
        float2 noQuadro = daGrade(centro, k), R = tamanho();
        float v;
        if (f == 2) {
            if (i != 0) continue;                    // a Linha atravessa as células: basta a coluna do pixel
            v = valorDaLinha(q, centro.y, k);
        } else if (noQuadro.x < 1.0 || noQuadro.y < 1.0 || noQuadro.x > R.x - 1.0 || noQuadro.y > R.y - 1.0) {
            v = mediaDaCelula(noQuadro, k);          // célula com o centro fora do quadro: não está no buffer
        } else {
            float4 g = media.sample(__nv_smp, noQuadro / R);
            v = k == 0 ? g.x : k == 1 ? g.y : g.z;
        }
        float s = RAIO * c * tom(v) * u.dotScale / 100.0;
        m = min(m + ponto(f, q - centro, s, w, ij), 1.0);
    }
    return m;
}

fragment float4 fx_tonecraft(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant tonecraftParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> media [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float2 R = tamanho();
    float2 p = uv * R;
    if (eng.acPass == 0) {
        if (u.colorScheme == 0) { __nv_out = float4(mediaDaCelula(p, 0), 0.0, 0.0, 1.0); return __nv_out; }
        __nv_out = float4(mediaDaCelula(p, 0), mediaDaCelula(p, 1), mediaDaCelula(p, 2), 1.0);
        return __nv_out;
    }
    float4 orig = inputImg.sample(__nv_smp, uv);

    // o papel: branco, com o gradiente por cima
    float3 papel = float3(1.0);
    float2 A = u.gradientStart * R, B = u.gradientEnd * R;
    float t = clamp(dot(p - A, B - A) / max(dot(B - A, B - A), 1e-6), 0.0, 1.0);
    papel = mix(papel, mix(u.startColor.rgb, u.endColor.rgb, t), u.gradientAmount / 100.0);

    // Black Wear (medido): um ruído por pixel tira tinta — 40% dos pixels ficam cheios, o resto perde até 70%
    float ruido = hash(floor(p / eng.acEscalaDePixel) + 0.5);
    float falha = 1.0 - u.blackWear / 100.0 * 0.7 * max(ruido - 0.4, 0.0) / 0.6;

    float3 cor; float cobre;
    if (u.colorScheme == 0) {
        cobre = tela(p, 0);
        cor = papel * (1.0 - cobre * falha);
    } else {
        // CMYK (medido): três telas — ciano, magenta e amarelo — multiplicadas; o alfa do Transparent BG é a média
        float3 cmy = float3(tela(p, 0), tela(p, 1), tela(p, 2));
        cor = papel * (1.0 - cmy * falha);
        cobre = dot(cmy, float3(1.0 / 3.0));
    }
    float4 saida;
    if (u.transparentBg) {
        // medido: o alfa vira a própria tinta e a cor continua a do quadro com papel (a borda sai clara)
        saida = float4(cor, cobre);
    } else {
        // Paper Tint (medido): puxa para o bege na medida em que a cor é clara (média dos canais) — o preto não muda
        cor = mix(cor, float3(0.92, 0.84, 0.66), u.paperTint / 100.0 * dot(cor, float3(1.0 / 3.0)));
        saida = float4(cor, orig.a);       // medido: o alfa da saída é o da camada
    }
    // Highlight Detail (medido): não mexe nos pontos — soma um ruído fino de ±4% ao quadro
    saida.rgb = clamp(saida.rgb + (hash(floor(p / eng.acEscalaDePixel) + 17.5) - 0.5) * 2.0 * 0.04 * u.highlightDetail / 100.0, 0.0, 1.0);
    __nv_out = mix(orig, saida, u.mixAmount / 100.0);
    return __nv_out;
}
