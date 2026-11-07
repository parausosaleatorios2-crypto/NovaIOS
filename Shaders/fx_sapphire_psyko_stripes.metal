// ---------------------------------------------------------------------------
// S_PsykoStripes
// origem : assets/effects/sapphire-psyko-stripes.xml
// id     : nova.effect.spsykostripes
// passes : 8
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_psyko_stripesParams {
    float stripeDir;
    float stripeMag;
    float sourceBlur;
    float sourceScale;
    float freqColors;
    float freqRed;
    float freqGreen;
    float freqBlue;
    float phaseStart;
    float phaseSpeed;
    float phaseRed;
    float phaseGreen;
    float phaseBlue;
    float brightness;
    float4 color;
    float offset;
    float saturation;
    float scaleBySource;
    float scaleBySrcAmp;
    float mixWithSource;
    int inputOpacity;
    int outputOpacity;
};

// --- funcoes auxiliares do efeito
const float LARGURA_MAX = 720.0;

// Os sliders do Sapphire chegam em ponto fixo 16.16.
float fixo(float v) { return floor(v * 65536.0 + 0.5) / 65536.0; }

int2 gT;          // o buffer
int2 gN;          // a camada do AE dentro dele, em px
int2 gInicio;     // o canto da camada no buffer
float gEscala;     // a prévia reduzida (o Source Blur é em px da composição)

void preparar() {
    gT = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gN = clamp(int2(floor(max(eng.acCamada, float2(0.001)) * float2(gT) + 0.5)), int2(1), gT);
    gInicio = (gT - gN) / 2;
    gEscala = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
}

int espelhar(int i, int n) {
    if (i >= 0 && i < n) return i;
    int p = 2 * n;
    i = i - (i / p) * p; if (i < 0) i += p;
    return i < n ? i : p - 1 - i;
}

int2 naCamada(int2 q) { return gInicio + int2(espelhar(q.x, gN.x), espelhar(q.y, gN.y)); }

float4 guardar(float f) {
    uint b = as_type<uint>(f);
    return float4(float(b & 255u), float((b >> 8u) & 255u), float((b >> 16u) & 255u), float(b >> 24u)) / 255.0;
}

float lido(float4 c) {
    uint4 b = uint4(floor(c * 255.0 + 0.5));
    return as_type<float>(b.r | (b.g << 8u) | (b.b << 16u) | (b.a << 24u));
}

// Input Opacity (medido): Normal (1) usa a cor pré-multiplicada; All Opaque (0) e As Premult (2), a reta.
float3 entrada(int2 p) {
    float4 s = inputImg.read(uint2(p), uint(0));
    return u.inputOpacity == 1 ? s.rgb * s.a : s.rgb;
}

float monochrome(float3 c) { return (0.3125 * c.r + 0.5 * c.g) + 0.1875 * c.b; }

// Medido: o Source Blur do AE já é a largura em px (subpixel ligado de fábrica no plugin).
float larguraPx() { return clamp(fixo(u.sourceBlur) * gEscala, 0.0, LARGURA_MAX); }

/** Uma das três caixas de um eixo (a conta do S_GlowAura): a que cresce leva as pontas com a fração. */
float caixa(int2 q, bool emX, int qual, bool deA) {
    float w = larguraPx();
    int a = int(floor(w));
    float f = w - float(a);
    int r = (a + 2 - qual) / 3;
    bool cresce = f > 0.0 && a - (a / 3) * 3 == qual;
    float soma = 0.0;
    for (int d = -r; d <= r; d++) {
        int2 p = naCamada(q + (emX ? int2(d, 0) : int2(0, d)));
        soma += lido(deA ? ga.read(uint2(p), uint(0)) : gb.read(uint2(p), uint(0)));
    }
    float n = float(2 * r + 1);
    if (!cresce) return soma / n;
    int2 e = naCamada(q - (emX ? int2(r + 1, 0) : int2(0, r + 1)));
    int2 g = naCamada(q + (emX ? int2(r + 1, 0) : int2(0, r + 1)));
    float pontas = deA ? lido(ga.read(uint2(e), uint(0))) + lido(ga.read(uint2(g), uint(0))) : lido(gb.read(uint2(e), uint(0))) + lido(gb.read(uint2(g), uint(0)));
    return soma * ((1.0 - f) / n + f / (n + 2.0)) + pontas * (f / (n + 2.0));
}

fragment float4 fx_sapphire_psyko_stripes(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_psyko_stripesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> ga [[texture(1)]],
    texture2d<float> gb [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar();
    int2 t = min(int2(floor(in.acScreenNorm * float2(gT))), gT - int2(1));
    int2 q = t - gInicio;
    bool fora = any(lessThan(q, int2(0))) || any(greaterThanEqual(q, gN));

    if (eng.acPass == 0) { __nv_out = fora ? float4(0.0) : guardar(monochrome(entrada(t))); return __nv_out; }
    if (eng.acPass <= 6) {
        float c = fora ? 0.0 : caixa(q, eng.acPass <= 3, (eng.acPass - 1) - ((eng.acPass - 1) / 3) * 3, (eng.acPass & 1) == 1);
        __nv_out = guardar(c);
        return __nv_out;
    }

    float4 s = inputImg.read(uint2(t), uint(0));
    if (fora) { __nv_out = s; return __nv_out; }

    float bw = lido(ga.read(uint2(t), uint(0))) * fixo(u.sourceScale);
    float3 ph = fixo(u.phaseStart) + float3(fixo(u.phaseRed), fixo(u.phaseGreen), fixo(u.phaseBlue)) + fixo(u.phaseSpeed) * eng.acTime;
    // polar_to_xy(dir / 360, mag); o ângulo do AE chega com o sinal trocado
    float ang = -fixo(u.stripeDir) * 0.017453292519943295;
    float2 grad = fixo(u.stripeMag) * float2(cos(ang), sin(ang));
    // xy do Sapphire: −1..1 na largura da camada, y para cima (a linha 0 do buffer é o topo, de pé é a base)
    float meia = float(gN.x) * 0.5;
    float linha = eng.acEntradaDePe == 1 ? float(gN.y - 1 - q.y) : float(q.y);
    float2 xy = float2((float(q.x) + 0.5 - meia) / meia, (float(gN.y) * 0.5 - (linha + 0.5)) / meia);
    float3 fq = fixo(u.freqColors) * float3(fixo(u.freqRed), fixo(u.freqGreen), fixo(u.freqBlue));
    float3 c = (0.5 + 0.5 * sin(6.2831853 * (fq * (bw + dot(xy, grad) - ph)))) * fixo(u.brightness) * (floor(u.color.rgb * 255.0 + 0.5) / 255.0);
    float lum = monochrome(c);
    float3 pic = lum + (c - lum) * fixo(u.saturation);
    float k = mix(1.0, min(1.0, bw * fixo(u.scaleBySrcAmp)), fixo(u.scaleBySource));
    float3 o = pic * k + fixo(u.offset);
    o = mix(o, entrada(t), fixo(u.mixWithSource));

    // Output Opacity (medido): Copy From Input = clip(saída) como cor reta com o alfa da fonte; All Opaque, opaco
    float a = u.outputOpacity == 0 ? 1.0 : s.a;
    __nv_out = float4(floor(clamp(o, 0.0, 1.0) * 255.0 + 0.5) / 255.0, a);
    return __nv_out;
}
