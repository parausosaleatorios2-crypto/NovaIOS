// ---------------------------------------------------------------------------
// KO BandFill
// origem : assets/effects/bandfill.xml
// id     : nova.effect.bandfill
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bandfillParams {
    int geometry;
    float2 center;
    float rotation;
    float size;
    float divisions;
    float offset;
    float speed;
    float aspect;
    float points;
    int field;
    float progress;
    float startLine;
    float4 fillColor;
    float opacity;
    int blend;
    int rangeMode;
    float rangeStart;
    float rangeEnd;
    float feather;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

/** A coordenada da faixa, em faixas, num ponto (px do buffer, relativo ao Centro). */
static float coordenada(float2 d, float tam) {
    float th = radians(u.rotation);
    float c = cos(th);
    float s = sin(th);
    // Para o espaço da forma (a rotação do AE gira a forma no sentido horário).
    float2 u = float2(d.x * c + d.y * s, -d.x * s + d.y * c);
    float a = u.aspect / 100.0;
    float2 e = float2(u.x, u.y / a);
    if (u.geometry == 0) return -u.y / tam + 0.5;
    if (u.geometry == 1) return length(e) / tam;
    if (u.geometry == 2) return max(abs(e.x), abs(e.y)) / tam;
    if (u.geometry == 3) {
        float n = max(u.points, 3.0);
        float setor = 2.0 * PI / n;
        float ang = __nv_atan(u.x, -u.y);
        float m = __nv_mod(ang, setor) - 0.5 * setor;
        return length(u) * cos(m) / cos(PI / n) / tam;
    }
    float ang = __nv_mod(__nv_atan(u.x, -u.y), 2.0 * PI);
    return ang / (2.0 * PI) * u.divisions;
}

static float degrau(float d, float largura, float aa) {
    // Largura zero: borda seca, só com o antialias de um pixel.
    float w = max(largura, aa);
    return clamp(d / w + 0.5, 0.0, 1.0);
}

fragment float4 fx_bandfill(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bandfillParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 fonte = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 res = eng.acResolution;
    float esc = max(eng.acEscalaDePixel, 1e-4);
    float2 d = in.acScreenNorm * res - u.center * res;
    float tam = max(u.size, 1.0) * esc;

    float v = coordenada(d, tam);
    if (u.field == 1) v = -v;
    v -= u.offset + u.speed * eng.acTime;

    // Antialias: quanto v anda num pixel (o AE suaviza a borda em ~1 px).
    float aa = fwidth(v);
    if (u.geometry == 4) {
        // O ângulo salta de 360° para 0° em cima: a derivada dali é falsa. Um
        // segundo ângulo, que salta EMBAIXO, dá a derivada certa no meridiano de cima.
        float th = radians(u.rotation);
        float2 u = float2(d.x * cos(th) + d.y * sin(th), -d.x * sin(th) + d.y * cos(th));
        float outro = __nv_atan(u.x, -u.y) / (2.0 * PI) * u.divisions;
        aa = min(aa, fwidth(outro));
    }
    aa = max(aa, 1e-5);

    float k = floor(v);
    float f = v - k;

    float s = u.startLine / 100.0;
    float p = u.progress / 100.0;
    float F = u.feather / 100.0;
    float pl = F > 0.0 ? p * (1.0 + F) - 0.5 * F : p;
    float e0 = s * (1.0 - pl);
    float e1 = e0 + pl;

    float m = 0.0;
    if (p > 0.0) {
        m = min(degrau(f - e0, s * F, aa), degrau(e1 - f, (1.0 - s) * F, aa));
        // A faixa vizinha: o antialias da borda f = 0/1 precisa ver o outro lado.
        if (e0 <= aa && e1 >= 1.0 - aa) m = 1.0;
        if (u.rangeMode == 1 && (k < u.rangeStart - 0.5 || k > u.rangeEnd + 0.5)) m = 0.0;
    }
    m *= u.opacity / 100.0;

    // Cor reta (não pré-multiplicada), como o compositor deste motor espera.
    if (u.blend == 0) {
        __nv_out = float4(u.fillColor.rgb, m * fonte.a);
    } else if (u.blend == 1) {
        __nv_out = float4(mix(fonte.rgb, u.fillColor.rgb, m), fonte.a);
    } else if (u.blend == 2) {
        __nv_out = float4(fonte.rgb, fonte.a * m);
    } else {
        __nv_out = float4(fonte.rgb, fonte.a * (1.0 - m));
    }
    return __nv_out;
}
