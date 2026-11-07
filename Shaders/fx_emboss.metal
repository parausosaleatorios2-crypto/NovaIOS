// ---------------------------------------------------------------------------
// Relevo
// origem : assets/effects/emboss.xml
// id     : nova.effect.emboss
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct embossParams {
    float angle;
    float relief;
    float contrast;
    float keepColor;
};

// --- funcoes auxiliares do efeito
float lumaAt(float2 uv) {
    return dot(inputImg.sample(__nv_smp, clamp(uv, 0.0, 1.0)).rgb, float3(0.299, 0.587, 0.114));
}

fragment float4 fx_emboss(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant embossParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    float rad = radians(u.angle);
    float2 axis = float2(cos(rad), sin(rad)) * u.relief * eng.acEscalaDePixel * eng.acTexelSize;

    // A diferença entre os dois lados é a inclinação. Positiva = a superfície
    // sobe na direção da luz, então clareia.
    float slope = (lumaAt(in.acScreenNorm + axis) - lumaAt(in.acScreenNorm - axis)) * u.contrast;

    // Base cinza médio: é o valor neutro que faz a área plana desaparecer, em
    // vez de virar preto. Com "manter a cor" em 1 o relevo é somado à imagem.
    float3 base = mix(float3(0.5), color.rgb, u.keepColor);
    float3 carved = clamp(base + slope, 0.0, 1.0);

    __nv_out = float4(carved, color.a);
    return __nv_out;
}
