// ---------------------------------------------------------------------------
// Repetir em volta
// origem : assets/effects/repeat-radial.xml
// id     : nova.effect.repeatradial
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct repeat_radialParams {
    float copies;
    int mode;
    float radius;
    float2 center;
    float startAngle;
    float arc;
    float lineAngle;
    float seed;
    float spin;
    int faceCenter;
    float shrink;
    float fade;
    int keepOriginal;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

float hash(float x) {
    return fract(sin(x * 127.1 + u.seed * 37.13) * 43758.5453);
}

float2 girar(float2 v, float rad) {
    float c = cos(rad);
    float s = sin(rad);
    return float2(v.x * c - v.y * s, v.x * s + v.y * c);
}

float4 sobre(float4 baixo, float4 cima) {
    float a = cima.a + baixo.a * (1.0 - cima.a);
    if (a <= 0.0) return float4(0.0);
    return float4((cima.rgb * cima.a + baixo.rgb * baixo.a * (1.0 - cima.a)) / a, a);
}

fragment float4 fx_repeat_radial(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant repeat_radialParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    int quantas = clamp(int(u.copies + 0.5), 1, 16);
    float2 meio = float2(u.center.x * eng.acAspect, u.center.y);
    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y);

    float4 montado = float4(0.0);
    float abertura = u.arc * PI / 180.0;
    float inicio = u.startAngle * PI / 180.0;

    // De trás para frente: a cópia 1 acaba por cima, que é a que se lê como "a
    // original" quando elas se cruzam.
    for (int i = 16; i >= 1; i--) {
        if (i > quantas) continue;
        float indice = float(i - 1);

        // Onde esta cópia está.
        float2 desloca;
        float giro = u.spin * PI / 180.0 * indice;

        if (u.mode == 0) {
            // O arco fechado (360°) divide por N; o arco aberto divide por N-1,
            // senão a primeira e a última cópia caem em cima uma da outra.
            float divisor = abertura >= 6.2 ? float(quantas) : max(float(quantas - 1), 1.0);
            float ang = inicio + abertura * indice / divisor;
            desloca = float2(cos(ang), sin(ang)) * u.radius;
            if (u.faceCenter) giro += ang + PI * 0.5;
        } else if (u.mode == 1) {
            float ang = u.lineAngle * PI / 180.0;
            desloca = float2(cos(ang), sin(ang)) * u.radius * indice;
        } else {
            desloca = float2(hash(indice * 3.7) - 0.5, hash(indice * 7.1) - 0.5) * u.radius * 2.0;
            giro += (hash(indice * 11.3) - 0.5) * 2.0 * PI * 0.15;
        }

        float escala = 1.0 + u.shrink * indice;
        if (abs(escala) < 0.02) continue;

        // A volta: tira o deslocamento, desfaz o giro, desfaz a escala.
        float2 local = girar(p - meio - desloca, -giro) / escala + meio;
        float2 uv = float2(local.x / max(eng.acAspect, 1e-4), local.y);

        // Fora do quadro não há camada — e sem este corte, o CLAMP_TO_EDGE
        // esticaria a borda da imagem por toda a tela.
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) continue;

        float4 copia = inputImg.sample(__nv_smp, uv);
        copia.a *= max(1.0 - u.fade * indice, 0.0);
        montado = sobre(montado, copia);
    }

    __nv_out = u.keepOriginal ? sobre(montado, original) : montado;
    return __nv_out;
}
