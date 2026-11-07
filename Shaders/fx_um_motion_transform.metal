// ---------------------------------------------------------------------------
// Transformação em Movimento (Ultra Motion)
// origem : assets/effects/um-motion-transform.xml
// id     : nova.effect.ultramotion.motiontransform
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_motion_transformParams {
    float dx;
    float dy;
    float scale;
    float rotate;
    float samples;
};

fragment float4 fx_um_motion_transform(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_motion_transformParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int n = clamp(int(u.samples), 4, 48);
    float4 soma = float4(0.0);
    for (int i = 0; i <= 48; i++) {
        if (i > n) break;
        float t = float(i) / float(n) - 0.5;
        float ang = radians(u.rotate) * t;
        float c = cos(ang), s = sin(ang);
        float2 p = in.acScreenNorm - float2(0.5);
        p.x *= eng.acAspect;
        p = float2(p.x * c - p.y * s, p.x * s + p.y * c);
        p *= (1.0 + u.scale * t);
        p.x /= eng.acAspect;
        float2 u = p + float2(0.5) + float2(u.dx, u.dy) * t;
        soma += inputImg.sample(__nv_smp, u);
    }
    __nv_out = soma / float(n + 1);
    return __nv_out;
}
