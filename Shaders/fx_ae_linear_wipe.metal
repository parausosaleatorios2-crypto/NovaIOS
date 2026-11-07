// ---------------------------------------------------------------------------
// Linear Wipe (AE)
// origem : assets/effects/ae-linear-wipe.xml
// id     : nova.effect.aelinearwipe
// passes : 8
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_linear_wipeParams {
    float completion;
    float wipeAngle;
    float feather;
};

// --- funcoes auxiliares do efeito
// Calculados no Kotlin (model/LinearWipeDoAe.kt), em double, como o host do plugin.
uniform int lwModo;      // 0: Completion 0 (a camada como está); 1: transparente; 2: a cortina
uniform int lwDx;        // a reta em 16.16: visível quando y · lwDy + x · lwDx > lwLimite
uniform int lwDy;
uniform int lwLimite;
uniform int lwDx2;       // os meios passos (o canto do pixel) e os passos da subamostragem (1/16, truncados)
uniform int lwDy2;
uniform int lwDxo;
uniform int lwDyo;
uniform float lwRaio;    // o raio da caixa da Feather: Feather / 2,71
uniform int lwN;         // ceil(lwRaio); 0 = sem Feather

const int MARGEM = 256;  // = margin dos buffers

int2 gTam;   // a camada do AE no buffer
int2 gIni;   // o canto dela
bool gDePe;   // a linha 0 do buffer é a BASE da imagem (cena de pé)

void preparar() {
    int2 buf = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gTam = clamp(int2(floor(eng.acCamada * float2(buf) + 0.5)), int2(1), buf);
    gIni = (buf - gTam) / 2;
    gDePe = eng.acEntradaDePe == 1;
}

// O LinearWipeKernel no pixel b do buffer (dentro da camada): 1, 0 ou a fração da subamostragem.
float mascara(int2 b) {
    int x = b.x - gIni.x;
    int y = gDePe ? gIni.y + gTam.y - 1 - b.y : b.y - gIni.y;
    int t = y * lwDy + x * lwDx;
    bool dentro = t > lwLimite;
    t -= lwDx2 + lwDy2;
    bool c1 = dentro != (t > lwLimite);
    bool c2 = dentro != (t + lwDx > lwLimite);
    bool c3 = dentro != (t + lwDx + lwDy > lwLimite);
    bool c4 = dentro != (t + lwDy > lwLimite);
    if (!(c1 || c2 || c3 || c4)) return dentro ? 1.0 : 0.0;
    int k = 0;
    for (int i = 0; i < 16; i++) {
        for (int j = 0; j < 16; j++) {
            if (t > lwLimite) k++;
            t += lwDxo;
        }
        t -= lwDx;
        t += lwDyo;
    }
    // (k · 32768 + 128) / 256 / 32768, em float como o kernel (as potências de 2 são exatas)
    return (float(k) * 128.0 + 0.5) / 32768.0;
}

// 24 bits fixos no RGB de um RGBA8 (o valor fica em [0, 1]).
float4 guardar(float v) {
    uint q = min(uint(clamp(v, 0.0, 1.0) * 16777216.0), 16777215u);
    return float4(float(q >> 16u), float((q >> 8u) & 255u), float(q & 255u), 255.0) / 255.0;
}
uint abrirQ(sampler2D b, int2 c) {
    uint3 k = uint3(floor(b.read(uint2(c + MARGEM), uint(0)).rgb * 255.0 + 0.5));
    return (k.x << 16u) | (k.y << 8u) | k.z;
}
float abrir(sampler2D b, int2 c) { return float(abrirQ(b, c)) / 16777216.0; }

// O quadro que existe na entrada da passada p (1..6), em px do buffer, de gLo até gHi (fora): a camada, crescida n
// por passada já feita (as horizontais crescem na largura; as verticais, na altura, sobre o quadro já 3n mais
// largo), cortada na moldura.
int2 gLo;
int2 gHi;
void quadro(int p) {
    int h = min(p - 1, 3);
    int v = max(p - 4, 0);
    gLo = max(gIni - int2(h, v) * lwN, int2(-MARGEM));
    gHi = min(gIni + gTam + int2(h, v) * lwN, int2(int(inputImg.get_width()), int(inputImg.get_height())) + MARGEM);
}

uint anterior(int p, int2 c) { return (p % 2 == 1) ? abrirQ(lwA, c) : abrirQ(lwB, c); }

fragment float4 fx_ae_linear_wipe(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_linear_wipeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> lwA [[texture(1)]],
    texture2d<float> lwB [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar();
    int2 b = int2(__nv_fragCoord.xy);

    if (eng.acPass == 0) {
        // a máscara, na camada (fora dela não existe)
        int2 c = b - MARGEM;
        bool na = all(greaterThanEqual(c, gIni)) && all(lessThan(c, gIni + gTam));
        __nv_out = guardar(na ? mascara(c) : 0.0);
        return __nv_out;
    }
    if (eng.acPass < 7) {
        // uma passada da caixa (BoxBlurKernelFloatV2 com inRepeatEdgeB): a média só das amostras que existem —
        // o laço corre só por elas (com a Feather grande, o custo fica no tamanho do quadro, não no raio)
        int2 c = b - MARGEM;
        bool horizontal = eng.acPass < 4;
        int2 eixo = horizontal ? int2(1, 0) : int2(0, 1);
        quadro(eng.acPass);
        int ca = horizontal ? c.x : c.y;
        int cb = horizontal ? c.y : c.x;
        int loA = horizontal ? gLo.x : gLo.y;
        int hiA = horizontal ? gHi.x : gHi.y;
        int loB = horizontal ? gLo.y : gLo.x;
        int hiB = horizontal ? gHi.y : gHi.x;
        int n = lwN;
        int k0 = max(-n, loA - ca);
        int k1 = min(n, hiA - 1 - ca);
        if (cb < loB || cb >= hiB || k1 < k0) { __nv_out = guardar(0.0); return __nv_out; }
        float inv = float(n) - lwRaio;
        // A soma em INTEIROS (os 24 bits guardados, em duas metades de 12 que não estouram), arredondada uma vez
        // só: somada em float, a janela de 30 valores já errava o bastante para virar empates de 8 bits.
        uint alto = 0u;
        uint baixo = 0u;
        for (int k = k0; k <= k1; k++) {
            uint q = anterior(eng.acPass, c + eixo * k);
            alto += q >> 12u;
            baixo += q & 4095u;
        }
        float soma = (float(alto) * 4096.0 + float(baixo)) / 16777216.0;
        // as pontas (peso 1 − frac) só contam se existem
        uint pq = 0u;
        float noPeso = 0.0;
        if (k0 == -n) { pq += anterior(eng.acPass, c - eixo * n); noPeso += inv; }
        if (k1 == n) { pq += anterior(eng.acPass, c + eixo * n); noPeso += inv; }
        float pontas = float(pq) / 16777216.0;
        float peso = float(k1 - k0 + 1) - noPeso;
        __nv_out = guardar(peso > 0.0 ? (soma - pontas * inv) / peso : 0.0);
        return __nv_out;
    }

    float4 l = floor(inputImg.read(uint2(b), uint(0)) * 255.0 + 0.5) / 255.0;
    bool naCamada = all(greaterThanEqual(b, gIni)) && all(lessThan(b, gIni + gTam));
    if (lwModo == 0 || !naCamada) { __nv_out = l; return __nv_out; }
    if (lwModo == 1) { __nv_out = float4(0.0); return __nv_out; }
    float m = lwN == 0 ? mascara(b) : abrir(lwA, b);
    // o alfa vezes a máscara (float), e 8 bits como o AE: v·255 arredondado em float, + 0,5, para baixo. O `um`
    // impede o compilador de fundir o produto e a soma num fma.
    float um = float(min(eng.acIterationCount, 1));
    float a = clamp(l.a * m, 0.0, 1.0);
    __nv_out = float4(l.rgb, floor((a * 255.0) * um + 0.5) / 255.0);
    return __nv_out;
}
