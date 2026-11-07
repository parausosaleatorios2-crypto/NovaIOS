// ---------------------------------------------------------------------------
// CC Composite
// origem : assets/effects/cc-composite.xml
// id     : nova.effect.cccomposite
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct cc_compositeParams {
    float opacity;
    int compositeOriginal;
    int rgbOnly;
};

// --- funcoes auxiliares do efeito
// Os índices do menu (o do AE sem os separadores).
const int COPY = 0, BEHIND = 1, IN_FRONT = 2, DARKEN = 3, MULTIPLY = 4, LINEAR_BURN = 5, COLOR_BURN = 6,
          CLASSIC_BURN = 7, ADD = 8, LIGHTEN = 9, SCREEN = 10, LINEAR_DODGE = 11, COLOR_DODGE = 12,
          CLASSIC_DODGE = 13, OVERLAY = 14, SOFT_LIGHT = 15, HARD_LIGHT = 16, LINEAR_LIGHT = 17, VIVID_LIGHT = 18,
          PIN_LIGHT = 19, HARD_MIX = 20, DIFFERENCE = 21, CLASSIC_DIFFERENCE = 22, EXCLUSION = 23, HUE = 24,
          SATURATION = 25, COLOR = 26, LUMINOSITY = 27, STENCIL_ALPHA = 28, STENCIL_LUMA = 29,
          SILHOUETTE_ALPHA = 30, SILHOUETTE_LUMA = 31, ADD_ALPHA = 32, LUMINESCENT = 33;

const float3 LUMA = float3(0.299, 0.587, 0.114);

// O dodge/burn "novos" testam o fundo antes; os "Classic" (e o Vivid Light) testam o original antes.
static float dodge(float b, float s)  { return b <= 0.0 ? 0.0 : (s >= 1.0 ? 1.0 : min(1.0, b / (1.0 - s))); }
static float burn(float b, float s)   { return b >= 1.0 ? 1.0 : (s <= 0.0 ? 0.0 : 1.0 - min(1.0, (1.0 - b) / s)); }
static float dodgeC(float b, float s) { return s >= 1.0 ? 1.0 : (b <= 0.0 ? 0.0 : min(1.0, b / (1.0 - s))); }
static float burnC(float b, float s)  { return s <= 0.0 ? 0.0 : (b >= 1.0 ? 1.0 : 1.0 - min(1.0, (1.0 - b) / s)); }

static float macia(float b, float s) {
    if (s <= 0.5) return b - (1.0 - 2.0 * s) * b * (1.0 - b);
    float d = b <= 0.25 ? ((16.0 * b - 12.0) * b + 4.0) * b : sqrt(b);
    return b + (2.0 * s - 1.0) * (d - b);
}

/** Os separáveis, nas cores retas: b = o resultado (fundo), s = o original (por cima). */
static float canal(int m, float b, float s) {
    if (m == DARKEN) return min(b, s);
    if (m == MULTIPLY) return b * s;
    if (m == LINEAR_BURN) return max(b + s - 1.0, 0.0);
    if (m == COLOR_BURN) return burn(b, s);
    if (m == LIGHTEN) return max(b, s);
    if (m == SCREEN) return 1.0 - (1.0 - b) * (1.0 - s);
    if (m == LINEAR_DODGE || m == LINEAR_LIGHT) return min(b + s, 1.0);   // medido: "Linear Light" soma
    if (m == COLOR_DODGE) return dodge(b, s);
    if (m == OVERLAY) return b <= 0.5 ? 2.0 * b * s : 1.0 - 2.0 * (1.0 - b) * (1.0 - s);
    if (m == SOFT_LIGHT) return macia(b, s);
    if (m == HARD_LIGHT) return s <= 0.5 ? 2.0 * b * s : 1.0 - 2.0 * (1.0 - b) * (1.0 - s);
    if (m == VIVID_LIGHT) return s <= 0.5 ? burnC(b, 2.0 * s) : dodgeC(b, 2.0 * s - 1.0);
    if (m == PIN_LIGHT) return s <= 0.5 ? min(b, 2.0 * s) : max(b, 2.0 * s - 1.0);
    if (m == HARD_MIX) return (s < 0.5 ? b + s >= 1.0 - 1e-6 : b + s > 1.0 + 1e-6) ? 1.0 : 0.0;
    if (m == DIFFERENCE) return abs(b - s);
    if (m == EXCLUSION) return b + s - 2.0 * b * s;
    return s;
}

// Hue/Saturation/Color/Luminosity (as do W3C, luma 0,299/0,587/0,114).
static float3 cortarCor(float3 c) {
    float l = dot(c, LUMA), n = min(c.r, min(c.g, c.b)), x = max(c.r, max(c.g, c.b));
    if (n < 0.0) c = l + (c - l) * l / max(l - n, 1e-12);
    if (x > 1.0) c = l + (c - l) * (1.0 - l) / max(x - l, 1e-12);
    return c;
}
static float3 comLuma(float3 c, float l) { return cortarCor(c + (l - dot(c, LUMA))); }
static float satDe(float3 c) { return max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b)); }
static float3 comSat(float3 c, float s) {
    float n = min(c.r, min(c.g, c.b)), x = max(c.r, max(c.g, c.b));
    return x > n ? (c - n) * s / (x - n) : float3(0.0);
}
static float3 componente(int m, float3 b, float3 s) {
    if (m == HUE) return comLuma(comSat(s, satDe(b)), dot(b, LUMA));
    if (m == SATURATION) return comLuma(comSat(b, satDe(s)), dot(b, LUMA));
    if (m == COLOR) return comLuma(s, dot(b, LUMA));
    return comLuma(b, dot(s, LUMA));
}

fragment float4 fx_cc_composite(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant cc_compositeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> originalImg [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 res = inputImg.sample(__nv_smp, in.acScreenNorm);
    float4 org = originalImg.sample(__nv_smp, in.acScreenNorm);
    int m = u.compositeOriginal;
    float q = floor(clamp(u.opacity, 0.0, 1.0) * 32768.0 + 0.5) / 32768.0;
    float3 cb = res.rgb, cs = org.rgb;
    float ab = res.a, as_ = org.a * q;
    float3 pb = cb * ab, ps = cs * as_;
    float uni = ab + as_ - ab * as_;

    if (m == COPY) { __nv_out = float4(cs, u.rgbOnly ? ab : as_); return __nv_out; }

    float3 cor;
    float a = uni;
    bool deAlfa = false;
    if (m == BEHIND) cor = pb + (1.0 - ab) * ps;
    else if (m == IN_FRONT) cor = ps + (1.0 - as_) * pb;
    else if (m == ADD) cor = min(pb + ps, float3(uni));
    else if (m == CLASSIC_DIFFERENCE) cor = abs(pb - ps);
    else if (m == CLASSIC_DODGE) cor = min(float3(dodgeC(pb.r, ps.r), dodgeC(pb.g, ps.g), dodgeC(pb.b, ps.b)), float3(uni));
    else if (m == CLASSIC_BURN) {
        // burn nas cores pré-multiplicadas, com o original clareado pelo próprio alfa: s' = 1 − (1 − cs)·as
        float3 s2 = 1.0 - (1.0 - cs) * as_;
        float3 q2 = (ab - pb) / max(s2, float3(1e-12));
        cor = float3(s2.r <= 0.0 ? 0.0 : uni - min(uni, q2.r),
                   s2.g <= 0.0 ? 0.0 : uni - min(uni, q2.g),
                   s2.b <= 0.0 ? 0.0 : uni - min(uni, q2.b));
    }
    else if (m >= HUE && m <= LUMINOSITY) {
        // o fundo da fórmula é o RESULTADO SOBRE O ORIGINAL (cor reta); a saída mistura com ele pelo alfa do original
        float3 bl = uni > 0.0 ? (pb + (1.0 - ab) * ps) / uni : float3(0.0);
        cor = uni * mix(bl, clamp(componente(m, bl, cs), 0.0, 1.0), as_);
    }
    else if (m >= STENCIL_ALPHA && m <= SILHOUETTE_LUMA) {
        float k = (m == STENCIL_ALPHA || m == SILHOUETTE_ALPHA) ? as_ : dot(cs, LUMA) * as_;
        a = ab * ((m == STENCIL_ALPHA || m == STENCIL_LUMA) ? k : 1.0 - k);
        cor = cb * a;
        deAlfa = true;
    }
    else if (m == ADD_ALPHA) {
        float k = ab > 0.0 ? min(1.0, (1.0 - as_) / ab) : 0.0;
        cor = ps + pb * k;
        a = as_ + ab * k;
        deAlfa = true;
    }
    else if (m == LUMINESCENT) {
        cor = min(cs * q + pb * (1.0 - as_), float3(1.0));   // o original conta como já pré-multiplicado
        deAlfa = true;
    }
    else {
        float3 f = float3(canal(m, cb.r, cs.r), canal(m, cb.g, cs.g), canal(m, cb.b, cs.b));
        cor = (1.0 - as_) * pb + (1.0 - ab) * ps + ab * as_ * clamp(f, 0.0, 1.0);
    }

    float3 reto = a > 0.0 ? clamp(cor / a, 0.0, 1.0) : float3(0.0);
    // RGB Only: a cor da composição, o alfa do resultado — nos modos que SÃO de alfa não muda nada.
    if (u.rgbOnly && !deAlfa) a = ab;
    __nv_out = float4(reto, a);
    return __nv_out;
}
