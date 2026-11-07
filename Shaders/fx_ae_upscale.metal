// ---------------------------------------------------------------------------
// Detail-preserving Upscale (AE)
// origem : assets/effects/ae-upscale.xml
// id     : nova.effect.aeupscale
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_upscaleParams {
    float scale;
    float reduceNoise;
    float detail;
    int alphaMode;
};

// --- funcoes auxiliares do efeito
// (dy, dx) dos candidatos, na orientação do AE (linha 0 = o topo): DAT_18001f330
const int2 CAND[37] = int2[37](
    int2(0, 0), int2(0, 1), int2(1, 0), int2(0, -1), int2(-1, 0), int2(1, 1), int2(1, -1), int2(-1, -1),
    int2(-1, 1), int2(0, 2), int2(2, 0), int2(0, -2), int2(-2, 0), int2(1, 2), int2(1, -2), int2(-1, -2),
    int2(-1, 2), int2(2, 1), int2(2, -1), int2(-2, -1), int2(-2, 1), int2(2, 2), int2(2, -2), int2(-2, -2),
    int2(-2, 2), int2(0, 3), int2(3, 0), int2(0, -3), int2(-3, 0), int2(1, 3), int2(-1, 3), int2(3, 1),
    int2(3, -1), int2(1, -3), int2(-1, -3), int2(-3, -1), int2(-3, 1));

// O peso de cada distância: DAT_18001f000 (exp(−i/20) com 4 casas; as duas últimas, 1e−5)
const float PESO[201] = float[201](
    1.0, 0.951200008, 0.904799998, 0.860700011, 0.818700016, 0.778800011, 0.740800023, 0.704699993, 0.670300007,
    0.637600005, 0.60650003, 0.576900005, 0.548799992, 0.522000015, 0.496600002, 0.47240001, 0.449299991,
    0.427399993, 0.406599998, 0.386700004, 0.367900014, 0.349900007, 0.332899988, 0.316599995, 0.301200002,
    0.286500007, 0.272500008, 0.259200007, 0.246600002, 0.234599993, 0.223100007, 0.212200001, 0.201900005,
    0.192000002, 0.182699993, 0.173800007, 0.165299997, 0.157199994, 0.149599999, 0.142299995, 0.135299996,
    0.128700003, 0.122500002, 0.116499998, 0.110799998, 0.105400003, 0.100299999, 0.0953999981, 0.0907000005,
    0.0863000005, 0.0820999965, 0.0781000033, 0.0742999986, 0.0706999972, 0.0671999976, 0.0639000013, 0.060800001,
    0.0577999987, 0.0549999997, 0.0522999987, 0.0498000011, 0.0474000014, 0.0450000018, 0.0428999998, 0.0408000015,
    0.0388000011, 0.0368999988, 0.0351000018, 0.0333999991, 0.0317000002, 0.0302000009, 0.0286999997, 0.0273000002,
    0.0260000005, 0.0247000009, 0.0234999992, 0.0223999992, 0.0212999992, 0.0201999992, 0.0193000007, 0.0183000006,
    0.0174000002, 0.0165999997, 0.0157999992, 0.0149999997, 0.0142999999, 0.0136000002, 0.0129000004, 0.0122999996,
    0.0116999997, 0.0110999998, 0.0105999997, 0.0100999996, 0.00960000046, 0.00910000037, 0.00870000012,
    0.00820000004, 0.00779999979, 0.0074, 0.00710000005, 0.00669999979, 0.00639999984, 0.00609999988, 0.00579999993,
    0.00549999997, 0.00520000001, 0.00499999989, 0.00469999993, 0.00449999981, 0.00430000015, 0.00410000002,
    0.00389999989, 0.0037, 0.00350000011, 0.00329999998, 0.00319999992, 0.00300000003, 0.00289999996, 0.00270000007,
    0.00260000001, 0.00249999994, 0.00240000011, 0.00219999999, 0.00209999993, 0.00200000009, 0.00190000003,
    0.00179999997, 0.00170000002, 0.00170000002, 0.00159999996, 0.00150000001, 0.00139999995, 0.00139999995, 0.0013,
    0.00120000006, 0.00120000006, 0.00109999999, 0.00109999999, 0.00100000005, 0.00100000005, 0.000899999985,
    0.000899999985, 0.00079999998, 0.00079999998, 0.000699999975, 0.000699999975, 0.000699999975, 0.000600000028,
    0.000600000028, 0.000600000028, 0.000600000028, 0.000500000024, 0.000500000024, 0.000500000024, 0.000500000024,
    0.00039999999, 0.00039999999, 0.00039999999, 0.00039999999, 0.00039999999, 0.000300000014, 0.000300000014,
    0.000300000014, 0.000300000014, 0.000300000014, 0.000300000014, 0.000199999995, 0.000199999995, 0.000199999995,
    0.000199999995, 0.000199999995, 0.000199999995, 0.000199999995, 0.000199999995, 0.000199999995, 0.000199999995,
    0.000199999995, 9.99999975e-05, 9.99999975e-05, 9.99999975e-05, 9.99999975e-05, 9.99999975e-05, 9.99999975e-05,
    9.99999975e-05, 9.99999975e-05, 9.99999975e-05, 9.99999975e-05, 9.99999975e-05, 9.99999975e-05, 9.99999975e-05,
    9.99999975e-05, 9.99999975e-05, 9.99999975e-05, 9.99999975e-05, 9.99999975e-05, 9.99999975e-05, 9.99999975e-05,
    9.99999975e-05, 9.99999975e-05, 9.99999975e-06, 9.99999975e-06);

// As tomadas do K a −2..2 (a de −3 pesa 0), em float como na tabela do plugin
const float K1 = 0.10824360698461533;
const float K2 = -0.03143749386072159;

int2 gTam;    // a camada do AE no buffer
int2 gIni;    // o canto dela
bool gDePe;    // a linha 0 do buffer é a BASE da imagem

static void preparar() {
    int2 buf = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gTam = clamp(int2(floor(eng.acCamada * float2(buf) + 0.5)), int2(1), buf);
    gIni = (buf - gTam) / 2;
    gDePe = eng.acEntradaDePe == 1;
}

// (x, y) do AE (y = 0 no topo da camada) <-> buffer
static int2 noBuffer(int2 a) { return int2(gIni.x + a.x, gDePe ? gIni.y + gTam.y - 1 - a.y : gIni.y + a.y); }
static int2 doBuffer(int2 b) { return int2(b.x - gIni.x, gDePe ? gIni.y + gTam.y - 1 - b.y : b.y - gIni.y); }

// A fonte: a cor reta em k / 255 exato
static float4 fonte(int2 a) { return floor(inputImg.read(uint2(noBuffer(a)), uint(0)) * 255.0 + 0.5) / 255.0; }

// O float32 exato em quatro RGBA8: o byte k de cada canal no k-ésimo buffer (do mais baixo ao mais alto)
static uint4 byteDe(sampler2D t, int2 b) { return uint4(floor(t.read(uint2(b), uint(0)) * 255.0 + 0.5)); }
static float4 ler32(sampler2D b0, sampler2D b1, sampler2D b2, sampler2D b3, int2 a) {
    int2 b = noBuffer(a);
    return as_type<float>(byteDe(b0, b) | (byteDe(b1, b) << 8u) | (byteDe(b2, b) << 16u) | (byteDe(b3, b) << 24u));
}
static float4 kFonte(int2 a) { return ler32(upA, upB, upC, upD, a); }
static float4 doMeio(int2 a) { return ler32(upE, upF, upG, upH, a); }
static void gravar32(float4 v) {
    uint4 u = as_type<uint>(v);
    __nv_out = float4(u & 255u) / 255.0;
    fragColor1 = float4((u >> 8u) & 255u) / 255.0;
    fragColor2 = float4((u >> 16u) & 255u) / 255.0;
    fragColor3 = float4(u >> 24u) / 255.0;
}

static float pesoK(int d) { int m = abs(d); return m == 0 ? 1.0 : (m == 1 ? K1 : K2); }

// K numa imagem (0 = a fonte, 1 = o resultado do passo 2): horizontal (Σ w·c / Σ w das tomadas dentro), depois
// vertical, em float
static float4 kDe(int qual, int2 a) {
    float4 soma = float4(0.0);
    float pv = 0.0;
    for (int dy = -2; dy <= 2; dy++) {
        int y = a.y + dy;
        if (y < 0 || y >= gTam.y) continue;
        float4 linha = float4(0.0);
        float ph = 0.0;
        for (int dx = -2; dx <= 2; dx++) {
            int x = a.x + dx;
            if (x < 0 || x >= gTam.x) continue;
            float w = pesoK(dx);
            float4 c = qual == 0 ? fonte(int2(x, y)) : doMeio(int2(x, y));
            linha += w * c;
            ph += w;
        }
        float w = pesoK(dy);
        soma += w * (linha * (1.0 / ph));
        pv += w;
    }
    return soma * (1.0 / pv);
}

fragment float4 fx_ae_upscale(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_upscaleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> upA [[texture(1)]],
    texture2d<float> upB [[texture(2)]],
    texture2d<float> upC [[texture(3)]],
    texture2d<float> upD [[texture(4)]],
    texture2d<float> upE [[texture(5)]],
    texture2d<float> upF [[texture(6)]],
    texture2d<float> upG [[texture(7)]],
    texture2d<float> upH [[texture(8)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar();
    int2 b = int2(__nv_fragCoord.xy);
    int2 a = doBuffer(b);
    bool dentro = all(greaterThanEqual(a, int2(0))) && all(lessThan(a, gTam));
    if (u.reduceNoise <= 0.0 || !dentro) {
        if (eng.acPass == 2) __nv_out = inputImg.read(uint2(b), uint(0));
        else gravar32(float4(0.0));
        return __nv_out;
    }

    if (eng.acPass == 0) {
        gravar32(kDe(0, a));
        return __nv_out;
    }

    if (eng.acPass == 1) {
        float4 cur = kFonte(a);
        // o miolo: x de 12 a W − 11, y de 12 a H − 11
        if (a.x < 12 || a.y < 12 || a.x > gTam.x - 11 || a.y > gTam.y - 11) {
            gravar32(cur);
            return __nv_out;
        }
        // σ e os candidatos (FUN_18000eb30 e FUN_180002790)
        float n = u.reduceNoise / 100.0;
        float m = n > 0.5 ? (n > 0.8 ? n : (n - 0.5) * 2.0 + 0.2) : n * 2.0 * 0.2;
        float sigma = m * 0.05;
        int nc = min(1 + int(pow(sigma / 0.05, 0.25) * 37.0), 37);
        if (eng.acRascunho == 1) nc = min(nc, 13);
        float k = 12.5 / sigma / 75.0;
        bool alfaJunto = u.alphaMode == 0;

        // o trecho 5×5 de K(fonte) em volta do pixel
        float4 ref[25];
        for (int j = 0; j < 25; j++) ref[j] = kFonte(a + int2(j % 5 - 2, j / 5 - 2));

        float3 acc = float3(0.0);
        float soma = 0.0, accA = 0.0, somaA = 0.0;
        for (int i = 0; i < 37; i++) {
            if (i >= nc) break;
            int2 o = CAND[i].yx * (i <= 12 ? 1 : 2);   // (dx, dy)
            int2 c = a + o;
            float ssd = 0.0, ssdA = 0.0;
            for (int j = 0; j < 25; j++) {
                float4 d = ref[j] - fonte(c + int2(j % 5 - 2, j / 5 - 2));
                ssd += dot(d.rgb, d.rgb);
                ssdA += d.a * d.a;
            }
            float4 v = fonte(c);
            float w = PESO[int(min(ssd * k, 10.0) * 20.0)];
            acc += w * v.rgb;
            soma += w;
            if (alfaJunto) {
                float wa = PESO[int(min(3.0 * ssdA * k, 10.0) * 20.0)];
                accA += wa * v.a;
                somaA += wa;
            }
        }
        float3 rgb = (cur.rgb * 10.0 + soma * (acc / (soma + 1e-9))) / (soma + 10.0);
        float al = alfaJunto ? (cur.a * 10.0 + somaA * (accA / (somaA + 1e-9))) / (somaA + 10.0) : cur.a;
        gravar32(float4(rgb, al));
        return __nv_out;
    }

    // K de novo e 8 bits; o alfa no Bicubic é o da camada
    float4 r = floor(clamp(kDe(1, a), 0.0, 1.0) * 255.0 + 0.5) / 255.0;
    if (u.alphaMode != 0) r.a = fonte(a).a;
    __nv_out = r;
    return __nv_out;
}
