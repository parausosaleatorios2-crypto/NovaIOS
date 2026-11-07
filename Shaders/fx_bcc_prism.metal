// ---------------------------------------------------------------------------
// BCC Prism
// origem : assets/effects/bcc-prism.xml
// id     : nova.effect.bccprism
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bcc_prismParams {
    float sampleCount;
    float2 startPoint;
    float2 endPoint;
    float startDepth;
    float endDepth;
    float2 rotationCenter;
    float startAngle;
    float endAngle;
    float prismAmount;
    float4 shortColor;
    float4 midColor;
    float4 longColor;
    int outsidePattern;
    float mixWithOriginal;
};

// --- funcoes auxiliares do efeito
const float GRAU = 0.017453292;            // 0x1810301f0: π/180 em float, como o plugin
const int MAX_AMOSTRAS = 200;              // o máximo do Sample Count

// ---- a camada do AE no buffer (como no BCC Rays Textured) ---------------------------------------
int2 gBuf, gInicio;
int W, H;
bool dePe;

static void preparar() {
    gBuf = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 tam = clamp(int2(floor(eng.acCamada * float2(gBuf) + 0.5)), int2(1), gBuf);
    gInicio = (gBuf - tam) / 2;
    W = tam.x; H = tam.y;
    dePe = eng.acEntradaDePe == 1;
}

// Um <point> como o plugin o recebe: fração da camada, x da esquerda e y do ALTO.
static float2 fracao(float2 p) {
    float2 cb = __nv_acPontoNoBuffer(p) * float2(gBuf) - float2(gInicio);
    if (dePe) cb.y = float(H) - cb.y;
    return cb / float2(float(W), float(H));
}

// texture2DRect bilinear (medido no AE em 32 bpc) no sistema do GL do plugin: y para cima, a base da imagem na
// linha 0, a borda da CAMADA repetida (CLAMP_TO_EDGE da textura do plugin, que tem o tamanho da camada).
static float4 ler(float2 r) {
    float2 p = clamp(r, float2(0.5), float2(float(W), float(H)) - 0.5);
    if (!dePe) p.y = float(H) - p.y;
    return inputImg.sample(__nv_smp, (float2(gInicio) + p) / float2(gBuf));
}

// ---- as funções do shader do plugin, como estão lá ----------------------------------------------
static float bfxMod(float a, float b) {
    float ret = a - float(int(a / b)) * b;
    return ret >= 0.0 ? ret : ret + b;
}
static float2 outsideTexCoord(float2 transformed, float textureX, float textureY, bool mirrored) {
    float2 textureCoord;
    textureCoord.s = transformed.s / textureX;
    textureCoord.t = transformed.t / textureY;
    float texModx = floor(textureCoord.s);
    if (mirrored && bfxMod(texModx, 2.0) == 1.0) textureCoord.s = textureX - (transformed.s - textureX * texModx);
    else textureCoord.s = transformed.s - textureX * texModx;
    float texMody = floor(textureCoord.t);
    if (mirrored && bfxMod(texMody, 2.0) == 1.0) textureCoord.t = textureY - (transformed.t - textureY * texMody);
    else textureCoord.t = transformed.t - textureY * texMody;
    return textureCoord;
}

// O que o 0x180a56910/0x180a56d80 calculam antes de desenhar (as cores do prisma e a soma delas).
float3 gMin, gMid, gSoma, gPasso0, gPasso1;
int gMeio;
static void cores(int n) {
    float k = u.prismAmount * 0.0099999998;          // 0x181152c08
    gMin = (u.shortColor.rgb - float3(1.0)) * k + float3(1.0);
    gMid = (u.midColor.rgb - float3(1.0)) * k + float3(1.0);
    float3 maxc = (u.longColor.rgb - float3(1.0)) * k + float3(1.0);
    int m = n >> 1;
    gMeio = n / 2;
    gPasso0 = (gMid - gMin) * (1.0 / float(m));
    gPasso1 = (maxc - gMid) * (1.0 / float(n - m - 1));
    float3 a = gMin * float(m) + gPasso0 * (float((m - 1) * m) * 0.5);
    float3 b = gMid * float(n - m) + gPasso1 * (float((n - m - 1) * (n - m)) * 0.5);
    gSoma = a + b;
}
static float3 peso(int index) {
    float3 w = index < gMeio ? gMin + gPasso0 * float(index) : gMid + gPasso1 * float(index - gMeio);
    if (gSoma.r > 1.0) w.r *= 1.0 / gSoma.r;
    if (gSoma.g > 1.0) w.g *= 1.0 / gSoma.g;
    if (gSoma.b > 1.0) w.b *= 1.0 / gSoma.b;
    return w;
}

fragment float4 fx_bcc_prism(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bcc_prismParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar();
    int2 t = min(int2(floor(in.acScreenNorm * float2(gBuf))), gBuf - int2(1));
    int2 q = t - gInicio;
    if (any(lessThan(q, int2(0))) || any(greaterThanEqual(q, int2(W, H)))) {
        __nv_out = inputImg.read(uint2(t), uint(0));
        return __nv_out;
    }
    float4 orig = inputImg.read(uint2(t), uint(0));

    int n = clamp(int(u.sampleCount), 3, MAX_AMOSTRAS);     // o plugin trunca o valor
    if (eng.acRascunho == 1) n = min(n, 48);                  // na prévia em movimento: o espectro em menos degraus
    cores(n);
    float dw = float(W), dh = float(H);
    bool repetir = u.outsidePattern != 0, espelhar = u.outsidePattern == 2;

    // o pixel no sistema do plugin: gl_TexCoord = o centro do pixel, y para cima
    float2 textureCoord = float2(float(q.x) + 0.5, (dePe ? float(q.y) : float(H - 1 - q.y)) + 0.5);
    float2 s = fracao(u.startPoint), e = fracao(u.endPoint), c = fracao(u.rotationCenter);

    float2 halfSize = float2(0.5 * dw, 0.5 * dh);
    float2 startPos = float2(s.x * dw - halfSize.x, (1.0 - s.y) * dh - halfSize.y);
    float2 endPos = float2(e.x * dw - halfSize.x, (1.0 - e.y) * dh - halfSize.y);
    endPos += startPos;
    float2 center = float2(c.x * dw - halfSize.x, (1.0 - c.y) * dh - halfSize.y);
    float rotateGetPtr = u.startAngle * GRAU - 1.5708;
    float rotateEnd = u.endAngle * GRAU - 1.5708;
    float changeRate = 1.0 / float(n - 1);
    float currentAngle = rotateGetPtr;
    float angleChange = (rotateEnd - rotateGetPtr) * changeRate;
    float2 currentPos = startPos;
    float2 posChange = float2((endPos.x - startPos.x) * changeRate, (endPos.y - startPos.y) * changeRate);
    float scaleZ = 1.0 / max(u.startDepth, 0.001);
    float scaleZrate = (1.0 / max(u.endDepth, 0.001) - scaleZ) * changeRate;

    float4 prismColor = float4(0.0);
    for (int i = 0; i < MAX_AMOSTRAS; i++) {
        if (i >= n) break;
        float2 currentCenter = center - currentPos;
        float2 transformed;
        transformed.x = (textureCoord.x - currentPos.x - halfSize.x) / scaleZ - currentCenter.x;
        transformed.y = (textureCoord.y - currentPos.y - halfSize.y) / scaleZ - currentCenter.y;
        float cosa = cos(currentAngle);
        float sina = sin(currentAngle);
        float2 rotated;
        rotated.x = cosa * transformed.x - sina * transformed.y + currentCenter.x + currentPos.x + halfSize.x;
        rotated.y = sina * transformed.x + cosa * transformed.y + currentCenter.y + currentPos.y + halfSize.y;
        float4 currentColor = float4(0.0);
        if (repetir) {
            float2 m = outsideTexCoord(rotated, dw, dh, espelhar);
            if (m.x >= 0.0 && m.x < dw && m.y >= 0.0 && m.y < dh) currentColor = ler(m);
        } else if (rotated.x >= 0.0 && rotated.x < dw && rotated.y >= 0.0 && rotated.y < dh) {
            currentColor = ler(rotated);
        }
        currentColor.rgb *= currentColor.a;
        currentColor.rgb *= peso(i);
        currentColor.a /= float(n);
        prismColor += currentColor;
        scaleZ += scaleZrate;
        currentPos += posChange;
        currentAngle += angleChange;
    }
    if (prismColor.a > 1.0) prismColor.a = 1.0;

    // o FBO do plugin é de meia precisão (0x140B)
    prismColor = float4(unpackHalf2x16(packHalf2x16(prismColor.rg)), unpackHalf2x16(packHalf2x16(prismColor.ba)));

    // Mix with Original (0x180d3c5e0 com 1 − mix): na cor pré-multiplicada
    float mx = clamp(u.mixWithOriginal * 0.0099999998, 0.0, 1.0);
    float4 r = prismColor * (1.0 - mx) + float4(orig.rgb * orig.a, orig.a) * mx;
    __nv_out = r.a > 0.0 ? float4(clamp(r.rgb / r.a, 0.0, 1.0), r.a) : float4(0.0);
    return __nv_out;
}
