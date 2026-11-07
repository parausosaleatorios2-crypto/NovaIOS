// ---------------------------------------------------------------------------
// Movimento com RGB Separado (Ultra Motion)
// origem : assets/effects/um-rgb-motion-split.xml
// id     : nova.effect.ultramotion.rgbmotionsplit
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_rgb_motion_splitParams {
    float len;
    float angle;
    float spread;
    float samples;
};

// --- funcoes auxiliares do efeito
static float canalDir(float2 uv, float ang, float l, int n, int ch) {
    float2 dir = float2(cos(ang), sin(ang));
    dir.x /= eng.acAspect;
    float soma = 0.0;
    for (int i = 0; i <= 32; i++) {
        if (i > n) break;
        float t = float(i) / float(n) - 0.5;
        soma += inputImg.sample(__nv_smp, uv + dir * l * t)[ch];
    }
    return soma / float(n + 1);
}

fragment float4 fx_um_rgb_motion_split(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_rgb_motion_splitParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (u.len <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); return __nv_out; }
    int n = clamp(int(u.samples), 4, 32);
    float base = radians(u.angle);
    float dA = radians(u.spread);
    float r = canalDir(in.acScreenNorm, base - dA, u.len, n, 0);
    float g = canalDir(in.acScreenNorm, base,       u.len, n, 1);
    float b = canalDir(in.acScreenNorm, base + dA, u.len, n, 2);
    float a = inputImg.sample(__nv_smp, in.acScreenNorm).a;
    __nv_out = float4(r, g, b, a);
    return __nv_out;
}
