// ---------------------------------------------------------------------------
// Directional Blur (AE)
// origem : assets/effects/ae-directional-blur.xml
// id     : nova.effect.aedirectionalblur
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_directional_blurParams {
    float direction;
    float blurLength;
};

// --- funcoes auxiliares do efeito
// Calculados no Kotlin (model/DirectionalBlurDoAe.kt), em double, como o host do plugin.
uniform int dbAtivo;      // 0: Blur Length 0 (o AE devolve a camada)
uniform int dbEixoH;      // 1: o desfoque corre na horizontal (as "linhas" do cisalhamento são as colunas)
uniform float dbS;        // tan φ
uniform float dbBase;     // OffX: |tan φ| · linhas quando tan φ < 0
uniform float dbOffLinha; // OffY: ceil(L · |cos θ|) + 5
uniform int dbDIda;       // trunc(−tan φ · OffY): o deslocamento inteiro do quadro cisalhado
uniform float dbRaio;     // o raio da caixa, R / 2,71
uniform int dbLargura;    // ceil(|tan φ| · linhas): quanto o quadro cisalhado é mais largo

const int MARGEM = 256;   // = margin dos buffers

int2 gTam;       // a camada do AE no buffer
int2 gIni;       // o canto dela
bool gDePe;       // a linha 0 do buffer é a BASE da imagem (cena de pé)
int gLinhas;      // quantas linhas tem a camada no eixo do cisalhamento
int gLargura;     // e quantas colunas
int gN;           // ceil(raio)
int gExt;         // 3 · ceil(raio): quanto a caixa cresce de cada lado

void preparar() {
    int2 buf = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gTam = clamp(int2(floor(eng.acCamada * float2(buf) + 0.5)), int2(1), buf);
    gIni = (buf - gTam) / 2;
    gDePe = eng.acEntradaDePe == 1;
    gLinhas = dbEixoH == 1 ? gTam.x : gTam.y;
    gLargura = dbEixoH == 1 ? gTam.y : gTam.x;
    gN = int(ceil(dbRaio));
    gExt = 3 * gN;
}

// (coluna, linha) no eixo do cisalhamento, na orientação do AE (linha 0 = o topo da camada) <-> buffer
int2 noBuffer(int a, int l) {
    int2 p = dbEixoH == 1 ? int2(l, a) : int2(a, l);
    return int2(gIni.x + p.x, gDePe ? gIni.y + gTam.y - 1 - p.y : gIni.y + p.y);
}
int2 doBuffer(int2 b) {
    int2 p = int2(b.x - gIni.x, gDePe ? gIni.y + gTam.y - 1 - b.y : b.y - gIni.y);
    return dbEixoH == 1 ? int2(p.y, p.x) : p;
}

// A camada (reta, k / 255 exato); fora dela, transparente.
float4 entrada(int a, int l) {
    if (a < 0 || a >= gLargura || l < 0 || l >= gLinhas) return float4(0.0);
    return floor(inputImg.read(uint2(noBuffer(a, l)), uint(0)) * 255.0 + 0.5) / 255.0;
}

// A leitura do kernel do AE numa linha, na posição p: o filtro bilinear (fração em 1/256) no meio, a
// borda vezes o peso exato entre −1 e 0 (e entre W−1 e W), zero fora.
float4 cisalhada(int l, float p) {
    if (l < 0 || l >= gLinhas) return float4(0.0);
    float w1 = float(gLargura - 1);
    if (p >= 0.0 && p <= w1) {
        float i0 = floor(p);
        float f = floor((p - i0) * 256.0 + 0.5) / 256.0;
        int i = int(i0);
        return entrada(i, l) * (1.0 - f) + entrada(min(i + 1, gLargura - 1), l) * f;
    }
    if (p < 0.0 && p > -1.0) return entrada(0, l) * (1.0 + p);
    if (p > w1 && p <= float(gLargura)) return entrada(gLargura - 1, l) * (float(gLargura) - p);
    return float4(0.0);
}

// srcX do kernel de ida: (tx − dx) − OffX − (y + OffY) · s, em float32 e nesta ordem
float posIda(int t, int l) {
    float a = float(t - dbDIda) - dbBase;
    return a - (float(l) + dbOffLinha) * dbS;
}

// o da volta: −OffX, OffY − ext, −s, lido na linha l + ext do quadro desfocado
float posVolta(int a, int l) {
    float x = float(a + dbDIda) + dbBase;
    return x + (float(l + gExt) + (dbOffLinha - float(gExt))) * dbS;
}

// Onde a linha l do quadro cisalhado mora no buffer: a coluna T do AE fica em T − K(l).
int desloc(int l) { return int(floor(posVolta(0, l))); }

// 16 bits fixos em dois RGBA8
float4 ler16(sampler2D alto, sampler2D baixo, int u, int l) {
    int2 b = noBuffer(u, l) + MARGEM;
    int2 n = int2(int(alto.get_width()), int(alto.get_height()));
    if (any(lessThan(b, int2(0))) || any(greaterThanEqual(b, n))) return float4(0.0);
    float4 h = floor(alto.read(uint2(b), uint(0)) * 255.0 + 0.5);
    float4 lo = floor(baixo.read(uint2(b), uint(0)) * 255.0 + 0.5);
    return (h * 256.0 + lo) / 65535.0;
}
void gravar16(float4 v) {
    float4 q = floor(clamp(v, 0.0, 1.0) * 65535.0 + 0.5);
    float4 h = floor(q / 256.0);
    __nv_out = h / 255.0;
    fragColor1 = (q - h * 256.0) / 255.0;
}

// O valor da linha j na coluna T do quadro que a passada lê: na 1ª, o cisalhamento na hora (e
// pré-multiplicado); nas outras, o buffer da passada anterior.
float4 linhaAnterior(int passada, int t, int j, int largura) {
    if (passada == 0) {
        if (t < 0 || t >= largura) return float4(0.0);
        float4 c = cisalhada(j, posIda(t, j));
        return float4(c.rgb * c.a, c.a);
    }
    int u = t - desloc(j);
    return passada == 1 ? ler16(dbA, dbA2, u, j) : ler16(dbB, dbB2, u, j);
}

fragment float4 fx_ae_directional_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_directional_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> dbA [[texture(1)]],
    texture2d<float> dbA2 [[texture(2)]],
    texture2d<float> dbB [[texture(3)]],
    texture2d<float> dbB2 [[texture(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar();
    if (dbAtivo == 0) {
        if (eng.acPass == 3) __nv_out = inputImg.read(uint2(int2(__nv_fragCoord.xy)), uint(0));
        return __nv_out;
    }
    int largura = gLargura + dbLargura;   // o quadro cisalhado: colunas 0 .. largura − 1

    if (eng.acPass < 3) {
        // uma passada da caixa, na coluna T = u + K(l) do quadro cisalhado
        int2 ul = doBuffer(int2(__nv_fragCoord.xy) - MARGEM);
        int u = ul.x, l = ul.y;
        int t = u + desloc(l);
        float inv = float(gN) - dbRaio;
        float peso = float(2 * gN + 1) - 2.0 * inv;
        float4 inteira = float4(0.0);
        for (int j = l - gN; j <= l + gN; j++) inteira += linhaAnterior(eng.acPass, t, j, largura);
        float4 pontas = float4(0.0);
        if (inv != 0.0) pontas = linhaAnterior(eng.acPass, t, l - gN, largura) + linhaAnterior(eng.acPass, t, l + gN, largura);
        float4 num = inteira - pontas * inv;
        if (eng.acPass < 2) {
            float4 m = num / peso;
            gravar16(float4(m.rgb, clamp(m.a, 0.0, 1.0)));
        } else {
            // a última: reta
            float ap = num.a;
            if (peso != 0.0 && ap > 1.0 / 4096.0) gravar16(float4(num.rgb / ap, clamp(num.a / peso, 0.0, 1.0)));
            else gravar16(float4(0.0));
        }
        return __nv_out;
    }

    // o cisalhamento de volta, lendo a 3ª passada
    int2 al = doBuffer(int2(__nv_fragCoord.xy));
    int a = al.x, l = al.y;
    float p = posVolta(a, l);
    int k = desloc(l);
    float w1 = float(largura - 1);
    float4 c = float4(0.0);
    if (p >= 0.0 && p <= w1) {
        float i0 = floor(p);
        float f = floor((p - i0) * 256.0 + 0.5) / 256.0;
        int i = int(i0);
        c = ler16(dbA, dbA2, i - k, l) * (1.0 - f) + ler16(dbA, dbA2, min(i + 1, largura - 1) - k, l) * f;
    } else if (p < 0.0 && p > -1.0) {
        c = ler16(dbA, dbA2, -k, l) * (1.0 + p);
    } else if (p > w1 && p <= float(largura)) {
        c = ler16(dbA, dbA2, largura - 1 - k, l) * (float(largura) - p);
    }
    // 8 bits como o AE (`floor(v·255 + 0,5)`), aqui: a GPU converte com viés próprio (a da AMD arredonda o x,5 para
    // baixo em 1 de cada 7 pixels)
    __nv_out = floor(clamp(c, 0.0, 1.0) * 255.0 + 0.5) / 255.0;
    return __nv_out;
}
