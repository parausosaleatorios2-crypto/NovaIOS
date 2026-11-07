// ---------------------------------------------------------------------------
// YY_Ramp+
// origem : assets/effects/ae-yy-ramp.xml
// id     : nova.effect.yyramp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_yy_rampParams {
    float2 startPoint;
    float4 startColor;
    float startAlpha;
    float2 endPoint;
    float4 endColor;
    float endAlpha;
    float midpoint;
    float masterAlpha;
    int invertPoints;
    float rampScatter;
    int rampShape;
    int interpolation;
    int blendMode;
    int clipRgb;
};

// --- funcoes auxiliares do efeito
// Os índices do seletor (o menu do AE sem o separador do item 7).
const int NONE = 0, NORMAL = 1, MULTIPLY = 2, ADD = 3, SCREEN = 4, OVERLAY = 5, DARKEN = 6, COLOR_BURN = 7,
          LINEAR_BURN = 8, DARKER_COLOR = 9, LIGHTEN = 10, COLOR_DODGE = 11, LIGHTER_COLOR = 12, SOFT_LIGHT = 13,
          HARD_LIGHT = 14, LINEAR_LIGHT = 15, VIVID_LIGHT = 16, PIN_LIGHT = 17, HARD_MIX = 18, DIFFERENCE = 19,
          EXCLUSION = 20, SUBTRACT = 21, DIVIDE = 22, HUE = 23, SATURATION = 24, COLOR = 25, LUMINOSITY = 26,
          BEHIND = 27, STENCIL_ALPHA = 28;

const float3 LUMA = float3(0.299, 0.587, 0.114);
const float PI = 3.141592653589793;

// ---------- a rampa (FUN_180003520 do plugin) ----------

/** (int)u % 512 − 256 do hash do plugin: o resto com sinal do C, então o ruído pende para baixo. */
float ruido(int2 p, int semente) {
    uint u = uint(p.y) * uint(p.y) + uint(semente) + uint(p.x);   // em uint: o estouro dá a volta, como no int do C
    u = ((u >> 16u) ^ u) * 0x45d9f3bu;
    u = ((u >> 16u) ^ u) * 0x45d9f3bu;
    u = (u >> 16u) ^ u;
    int m = int(u & 511u);
    if ((u & 0x80000000u) != 0u && m != 0) m -= 512;
    return float(m - 256);
}

/** O t do pixel (canto em p, px da composição), antes da curva. */
float parametro(float2 d, float2 v, float l2, int forma) {
    if (forma == 1) return sqrt(dot(d, d) / l2);
    if (forma == 2) {
        if (d.x == 0.0 && d.y == 0.0) return 1.0;
        return __nv_mod((__nv_atan(d.y, d.x) - __nv_atan(v.y, v.x)) / (2.0 * PI) + 1.0, 1.0);
    }
    if (forma == 3) return abs(dot(d, v)) / l2;
    if (forma == 4) return (abs(v.y * d.x - v.x * d.y) + abs(dot(d, v))) / l2;
    return dot(d, v) / l2;
}

// ---------- os modos (os de camada do AE, como no cc-composite.xml; b = a camada, s = a rampa) ----------

float dodge(float b, float s) { return b <= 0.0 ? 0.0 : (s >= 1.0 ? 1.0 : min(1.0, b / (1.0 - s))); }
float burn(float b, float s)  { return b >= 1.0 ? 1.0 : (s <= 0.0 ? 0.0 : 1.0 - min(1.0, (1.0 - b) / s)); }
float dodgeC(float b, float s) { return s >= 1.0 ? 1.0 : (b <= 0.0 ? 0.0 : min(1.0, b / (1.0 - s))); }
float burnC(float b, float s)  { return s <= 0.0 ? 0.0 : (b >= 1.0 ? 1.0 : 1.0 - min(1.0, (1.0 - b) / s)); }

float macia(float b, float s) {
    if (s <= 0.5) return b - (1.0 - 2.0 * s) * b * (1.0 - b);
    float d = b <= 0.25 ? ((16.0 * b - 12.0) * b + 4.0) * b : sqrt(b);
    return b + (2.0 * s - 1.0) * (d - b);
}

/** Os separáveis, nas cores retas. */
float canal(int m, float b, float s) {
    if (m == MULTIPLY) return b * s;
    if (m == SCREEN) return 1.0 - (1.0 - b) * (1.0 - s);
    if (m == OVERLAY) return b <= 0.5 ? 2.0 * b * s : 1.0 - 2.0 * (1.0 - b) * (1.0 - s);
    if (m == DARKEN) return min(b, s);
    if (m == COLOR_BURN) return burn(b, s);
    if (m == LINEAR_BURN) return max(b + s - 1.0, 0.0);
    if (m == LIGHTEN) return max(b, s);
    if (m == COLOR_DODGE) return dodge(b, s);
    if (m == SOFT_LIGHT) return macia(b, s);
    if (m == HARD_LIGHT) return s <= 0.5 ? 2.0 * b * s : 1.0 - 2.0 * (1.0 - b) * (1.0 - s);
    if (m == LINEAR_LIGHT) return clamp(b + 2.0 * s - 1.0, 0.0, 1.0);          // medido (rodada 2)
    if (m == VIVID_LIGHT) return s <= 0.5 ? burnC(b, 2.0 * s) : dodgeC(b, 2.0 * s - 1.0);
    if (m == PIN_LIGHT) return s <= 0.5 ? min(b, 2.0 * s) : max(b, 2.0 * s - 1.0);
    if (m == HARD_MIX) return (s < 0.5 ? b + s >= 1.0 - 1e-6 : b + s > 1.0 + 1e-6) ? 1.0 : 0.0;
    if (m == DIFFERENCE) return abs(b - s);
    if (m == EXCLUSION) return b + s - 2.0 * b * s;
    if (m == SUBTRACT) return clamp(b - s, 0.0, 1.0);
    if (m == DIVIDE) return s > 0.0 ? min(b / s, 1.0) : (b > 0.0 ? 1.0 : 0.0);
    return s;
}

float3 cortarCor(float3 c) {
    float l = dot(c, LUMA), n = min(c.r, min(c.g, c.b)), x = max(c.r, max(c.g, c.b));
    if (n < 0.0) c = l + (c - l) * l / max(l - n, 1e-12);
    if (x > 1.0) c = l + (c - l) * (1.0 - l) / max(x - l, 1e-12);
    return c;
}
float3 comLuma(float3 c, float l) { return cortarCor(c + (l - dot(c, LUMA))); }
float satDe(float3 c) { return max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b)); }
float3 comSat(float3 c, float s) {
    float n = min(c.r, min(c.g, c.b)), x = max(c.r, max(c.g, c.b));
    return x > n ? (c - n) * s / (x - n) : float3(0.0);
}
/** Lighter/Darker Color: medido, a luminância ARREDONDADA a 8 bits. */
float luma8(float3 c) { return floor(dot(c, LUMA) * 255.0 + 0.5); }

float3 componente(int m, float3 b, float3 s) {
    if (m == HUE) return comLuma(comSat(s, satDe(b)), dot(b, LUMA));
    if (m == SATURATION) return comLuma(comSat(b, satDe(s)), dot(b, LUMA));
    if (m == COLOR) return comLuma(s, dot(b, LUMA));
    if (m == LUMINOSITY) return comLuma(b, dot(s, LUMA));
    if (m == LIGHTER_COLOR) return luma8(s) > luma8(b) ? s : b;
    return luma8(s) < luma8(b) ? s : b;     // DARKER_COLOR
}

/** A rampa (cs, as_) sobre a camada (cb, ab) no modo m; devolve a cor RETA e o alfa. */
float4 compor(int m, float3 cs, float as_, float3 cb, float ab) {
    if (m == NONE) return float4(cs, as_);
    float3 pb = cb * ab, ps = cs * as_;
    float uni = ab + as_ - ab * as_;
    float3 cor;
    float a = uni;
    if (m == STENCIL_ALPHA) return float4(cb, ab * as_);
    if (m == NORMAL) cor = ps + (1.0 - as_) * pb;
    else if (m == BEHIND) cor = pb + (1.0 - ab) * ps;
    else if (m == ADD) cor = min(pb + ps, float3(uni));                           // nas pré-multiplicadas
    else if (m == HUE || m == SATURATION || m == COLOR || m == LUMINOSITY || m == LIGHTER_COLOR || m == DARKER_COLOR) {
        // o fundo da fórmula é a CAMADA SOBRE A RAMPA (cor reta); a saída mistura esse fundo com ela pelo alfa da rampa
        float3 bl = uni > 0.0 ? (pb + (1.0 - ab) * ps) / uni : float3(0.0);
        cor = uni * mix(bl, clamp(componente(m, bl, cs), 0.0, 1.0), as_);
    }
    else {
        float3 f = float3(canal(m, cb.r, cs.r), canal(m, cb.g, cs.g), canal(m, cb.b, cs.b));
        cor = (1.0 - as_) * pb + (1.0 - ab) * ps + ab * as_ * clamp(f, 0.0, 1.0);
    }
    return float4(a > 0.0 ? clamp(cor / a, 0.0, 1.0) : float3(0.0), a);
}

fragment float4 fx_ae_yy_ramp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_yy_rampParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 pi = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
    float4 camada = floor(inputImg.read(uint2(pi), uint(0)) * 255.0 + 0.5) / 255.0;

    // Em px da composição, do canto do pixel; com a cena de pé (camada de ajuste) a linha 0 é a base:
    // o Angled giraria para o outro lado (e o ruído sairia espelhado) sem desvirar o y.
    int2 q = eng.acEntradaDePe == 1 ? int2(pi.x, T.y - 1 - pi.y) : pi;
    float2 lado = float2(T) / eng.acEscalaDePixel;
    float2 p = float2(q) / eng.acEscalaDePixel;
    float2 ini = u.startPoint * lado, fim = u.endPoint * lado;
    if (eng.acEntradaDePe == 1) { ini.y = lado.y - ini.y; fim.y = lado.y - fim.y; }

    // As cores em 8 bits e os alfas truncados de Master · Alpha (Invert Points troca cores e alfas).
    float4 c0 = float4(floor(u.startColor.rgb * 255.0 + 0.5), floor(u.masterAlpha * u.startAlpha / 10000.0 * 255.0 + 1e-4));
    float4 c1 = float4(floor(u.endColor.rgb * 255.0 + 0.5), floor(u.endAlpha * u.masterAlpha / 10000.0 * 255.0 + 1e-4));
    if (u.invertPoints) { float4 t0 = c0; c0 = c1; c1 = t0; }

    float2 v = fim - ini;
    float l2 = dot(v, v);
    float4 g;
    if (l2 == 0.0) {
        g = c1;                                                                  // início = fim: a cor do FIM
    } else {
        float2 d = p - ini;
        float t = parametro(d, v, l2, u.rampShape);
        float m = u.midpoint * 0.01;
        t = m < t ? 1.0 - ((1.0 - t) * 0.5) / (1.0 - m) : (t * 0.5) / m;
        if (u.rampScatter > 0.0) {
            int semente = int(u.rampScatter * u.rampScatter * 256.0);
            t += ruido(q, semente) * (u.rampScatter * 0.001 / sqrt(l2));
        }
        t = clamp(t, 0.0, 1.0);
        if (u.interpolation == 1) t = (1.0 - cos(t * PI)) * 0.5;
        g = floor((c1 - c0) * t + c0);
    }
    g /= 255.0;

    float4 r = compor(u.blendMode, g.rgb, g.a, camada.rgb, camada.a);
    if (u.clipRgb) r.a *= camada.a;                                                // Stencil Alpha da própria camada
    __nv_out = r.a > 0.0 ? r : float4(0.0);
    return __nv_out;
}
