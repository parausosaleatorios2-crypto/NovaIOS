// ---------------------------------------------------------------------------
// Desfoque Hexagonal (Ultra Motion)
// origem : assets/effects/um-hexagon-blur.xml
// id     : nova.effect.ultramotion.hexagonblur
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_hexagon_blurParams {
    float radius;
    float samples;
};

// --- funcoes auxiliares do efeito
static float4 varrer(sampler2D s, float2 uv, float2 dir, int n, float r) {
    float4 soma = float4(0.0);
    for (int i = 0; i <= 24; i++) {
        if (i > n) break;
        float t = float(i) / float(n);
        soma += s.sample(__nv_smp, uv + dir * r * t);
    }
    return soma / float(n + 1);
}

fragment float4 fx_um_hexagon_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_hexagon_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> passA [[texture(1)]],
    texture2d<float> passB [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int n = clamp(int(u.samples), 4, 24);
    float r = u.radius;

    if (eng.acPass == 0) {
        // direção 1: para baixo
        float2 d = float2(0.0, -1.0);
        d.x /= eng.acAspect;
        __nv_out = varrer(inputImg, in.acScreenNorm, d, n, r);
    } else if (eng.acPass == 1) {
        // direção 2: 60° no sentido horário do A
        float2 d = float2(sin(radians(60.0)), -cos(radians(60.0)));
        d.x /= eng.acAspect;
        __nv_out = varrer(passA, in.acScreenNorm, d, n, r);
    } else {
        // mistura: lado A (passA já tem d1) + lado B (passB tem d1+d2); juntar com uma terceira direção de passB
        float2 d = float2(-sin(radians(60.0)), -cos(radians(60.0)));
        d.x /= eng.acAspect;
        float4 lado1 = varrer(passA, in.acScreenNorm, d, n, r);
        float4 lado2 = varrer(passB, in.acScreenNorm, d, n, r);
        __nv_out = (lado1 + lado2) * 0.5;
    }
    return __nv_out;
}
