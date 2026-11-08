//
//  NovaBlend.metal
//  Os modos de mesclagem do After Effects, na ordem de BlendMode.allCases.
//  O estagio fixo do Metal so faz "over"; os 28 modos precisam de shader.
//

#include <metal_stdlib>
#include "NovaEngineUniforms.h"
using namespace metal;

struct BlendUniforms {
    int      mode;
    float    opacity;
    float4x4 layerToScreen;
    float2   layerSize;
    float2   screenSize;
};

inline float3 b_darken(float3 b, float3 s)     { return min(b, s); }
inline float3 b_multiply(float3 b, float3 s)   { return b * s; }
inline float3 b_colorBurn(float3 b, float3 s)  { return 1.0 - min(float3(1.0), (1.0 - b) / max(s, 1e-4)); }
inline float3 b_linearBurn(float3 b, float3 s) { return max(float3(0.0), b + s - 1.0); }
inline float3 b_lighten(float3 b, float3 s)    { return max(b, s); }
inline float3 b_screen(float3 b, float3 s)     { return b + s - b * s; }
inline float3 b_colorDodge(float3 b, float3 s) { return min(float3(1.0), b / max(1.0 - s, 1e-4)); }
inline float3 b_add(float3 b, float3 s)        { return min(float3(1.0), b + s); }
inline float3 b_overlay(float3 b, float3 s)    {
    return select(2.0*b*s, 1.0 - 2.0*(1.0-b)*(1.0-s), b > 0.5);
}
inline float3 b_hardLight(float3 b, float3 s)  { return b_overlay(s, b); }
inline float3 b_softLight(float3 b, float3 s)  {
    float3 d = select(((16.0*b - 12.0)*b + 4.0)*b, sqrt(b), b > 0.25);
    return select(b - (1.0 - 2.0*s)*b*(1.0-b), b + (2.0*s - 1.0)*(d - b), s > 0.5);
}
inline float3 b_vividLight(float3 b, float3 s) {
    return select(b_colorBurn(b, 2.0*s), b_colorDodge(b, 2.0*(s - 0.5)), s > 0.5);
}
inline float3 b_linearLight(float3 b, float3 s){ return clamp(b + 2.0*s - 1.0, 0.0, 1.0); }
inline float3 b_pinLight(float3 b, float3 s)   {
    return select(min(b, 2.0*s), max(b, 2.0*(s - 0.5)), s > 0.5);
}
inline float3 b_hardMix(float3 b, float3 s)    { return step(1.0, b + s); }
inline float3 b_difference(float3 b, float3 s) { return abs(b - s); }
inline float3 b_exclusion(float3 b, float3 s)  { return b + s - 2.0*b*s; }

inline float  b_lum(float3 c) { return dot(c, float3(0.3, 0.59, 0.11)); }
inline float3 b_setLum(float3 c, float l) {
    float d = l - b_lum(c);
    float3 r = c + d;
    float lo = min(r.r, min(r.g, r.b)), hi = max(r.r, max(r.g, r.b));
    float lu = b_lum(r);
    if (lo < 0.0) r = lu + (r - lu) * lu / max(lu - lo, 1e-4);
    if (hi > 1.0) r = lu + (r - lu) * (1.0 - lu) / max(hi - lu, 1e-4);
    return r;
}
inline float  b_sat(float3 c) { return max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b)); }
inline float3 b_setSat(float3 c, float s) {
    float mn = min(c.r, min(c.g, c.b)), mx = max(c.r, max(c.g, c.b));
    return (mx > mn) ? (c - mn) * s / (mx - mn) : float3(0.0);
}

// Indices = ordem de BlendMode.allCases no Swift.
// O fundo (`backdrop`) e uma copia da composicao antes desta camada, com alfa
// pre-multiplicado; o resultado SUBSTITUI o pixel (a GPU nao faz mescla fixa).
fragment float4 nova_blend_fragment(
    NovaVertexOut in [[stage_in]],
    constant BlendUniforms& u [[buffer(0)]],
    texture2d<float> src [[texture(0)]],
    texture2d<float> backdrop [[texture(1)]])
{
    constexpr sampler smp(filter::linear, address::clamp_to_edge);
    constexpr sampler bsm(filter::nearest, address::clamp_to_edge);

    float4 bp = backdrop.sample(bsm, in.uv);

    // Leva o pixel da tela para o espaco da camada.
    float2 screenPx = in.uv * u.screenSize;
    float4 local = u.layerToScreen * float4(screenPx, 0.0, 1.0);
    float2 uv = local.xy / max(u.layerSize, float2(1.0));
    if (any(uv < 0.0) || any(uv > 1.0)) { return bp; }

    float4 s = src.sample(smp, uv);
    s.a *= u.opacity;
    if (u.mode == 1) {   // dissolver: cada pixel aparece ou some conforme a opacidade
        float n = fract(sin(dot(floor(screenPx), float2(12.9898, 78.233))) * 43758.5453);
        s.a = n < s.a ? 1.0 : 0.0;
    }
    if (s.a <= 0.0) { return bp; }

    float3 b = bp.a > 0.0 ? bp.rgb / bp.a : float3(0.0);
    float3 c = s.rgb;
    switch (u.mode) {
        case  2: c = b_darken(b, s.rgb);     break;
        case  3: c = b_multiply(b, s.rgb);   break;
        case  4: c = b_colorBurn(b, s.rgb);  break;
        case  5: c = b_linearBurn(b, s.rgb); break;
        case  6: c = b_lum(s.rgb) < b_lum(b) ? s.rgb : b; break;   // cor mais escura
        case  7: c = b_add(b, s.rgb);        break;
        case  8: c = b_lighten(b, s.rgb);    break;
        case  9: c = b_screen(b, s.rgb);     break;
        case 10: c = b_colorDodge(b, s.rgb); break;
        case 11: c = b_add(b, s.rgb);        break;                // superexposicao linear
        case 12: c = b_lum(s.rgb) > b_lum(b) ? s.rgb : b; break;   // cor mais clara
        case 13: c = b_overlay(b, s.rgb);    break;
        case 14: c = b_softLight(b, s.rgb);  break;
        case 15: c = b_hardLight(b, s.rgb);  break;
        case 16: c = b_vividLight(b, s.rgb); break;
        case 17: c = b_linearLight(b, s.rgb);break;
        case 18: c = b_pinLight(b, s.rgb);   break;
        case 19: c = b_hardMix(b, s.rgb);    break;
        case 20: c = b_difference(b, s.rgb); break;
        case 21: c = b_exclusion(b, s.rgb);  break;
        case 22: c = max(float3(0.0), b - s.rgb); break;            // subtrair
        case 23: c = min(float3(1.0), b / max(s.rgb, 1e-4)); break; // dividir
        case 24: c = b_setLum(b_setSat(s.rgb, b_sat(b)), b_lum(b)); break;  // matiz
        case 25: c = b_setLum(b_setSat(b, b_sat(s.rgb)), b_lum(b)); break;  // saturacao
        case 26: c = b_setLum(s.rgb, b_lum(b)); break;                       // cor
        case 27: c = b_setLum(b, b_lum(s.rgb)); break;                       // luminosidade
        default: c = s.rgb; break;
    }
    // Onde nao ha fundo, a camada aparece como e.
    c = mix(s.rgb, c, bp.a);
    if (u.mode == 28) {   // adicionar alfa
        return float4(min(float3(1.0), c * s.a + bp.rgb), min(1.0, s.a + bp.a));
    }
    return float4(c * s.a + bp.rgb * (1.0 - s.a), s.a + bp.a * (1.0 - s.a));
}
