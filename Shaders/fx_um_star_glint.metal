// ---------------------------------------------------------------------------
// Cintilação Estelar (Ultra Motion)
// origem : assets/effects/um-star-glint.xml
// id     : nova.effect.ultramotion.starglint
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_star_glintParams {
    float threshold;
    float reach;
    float points;
    float rotation;
    float intensity;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

static float3 amostrar(float2 uv, float2 dir, float len) {
    float3 soma = float3(0.0);
    float pt = 0.0;
    for (int i = 0; i <= 32; i++) {
        float t = float(i) / 32.0;
        float w = pow(1.0 - t, 1.5);
        float3 c = inputImg.sample(__nv_smp, uv + dir * len * t).rgb;
        // o parâmetro len vem da chamada abaixo

        float l = dot(c, LUMA);
        float k = smoothstep(u.threshold, u.threshold + 0.1, l);
        soma += c * k * w;
        pt += w;
    }
    return soma / pt;
}

fragment float4 fx_um_star_glint(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_star_glintParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    int n = clamp(int(u.points), 2, 8);
    float base = radians(u.rotation);
    float3 somaStreak = float3(0.0);
    for (int i = 0; i < 8; i++) {
        if (i >= n) break;
        float ang = base + 3.14159 * float(i) / float(n);
        float2 dir = float2(cos(ang), sin(ang));
        dir.x /= eng.acAspect;
        somaStreak += amostrar(in.acScreenNorm, dir, u.reach) + amostrar(in.acScreenNorm, -dir, u.reach);
    }
    __nv_out = float4(orig.rgb + somaStreak * u.intensity / float(n), orig.a);
    return __nv_out;
}
