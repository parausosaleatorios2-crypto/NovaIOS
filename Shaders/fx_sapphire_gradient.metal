// ---------------------------------------------------------------------------
// S_Gradient
// origem : assets/effects/sapphire-gradient.xml
// id     : nova.effect.sgradient
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_gradientParams {
    float2 start;
    float2 end;
    float4 startColor;
    float4 endColor;
    int swapColors;
    float brightness;
    float addNoise;
    float smoothCurve;
    float bgBrightness;
    int combine;
    int outputOpacity;
};

// --- funcoes auxiliares do efeito
static float sorteio(float2 p) {
    float3 q = fract(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

fragment float4 fx_sapphire_gradient(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_gradientParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 pi = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
    float4 fonte = inputImg.read(uint2(pi), uint(0));

    // Da definição do efeito: a posição ao longo da reta Start -> End (0 no início, 1 no fim), no espaço da CAMADA
    // (o centro do pixel levado a ela, em unidades com a proporção dela; a escala comum some na divisão).
    float2 L = float2(eng.acAspect, 1.0);
    float2 q = eng.acBufferNoPonto((float2(pi) + 0.5) / float2(T)) * L;
    float2 a = u.start * L, d = u.end * L - a;
    float linear = dot(q - a, d) / max(dot(d, d), 1e-12);
    float suave = (1.0 - cos(3.14159265 * clamp(linear, 0.0, 1.0))) * 0.5;
    // Com ruído, fora da reta vale o linear (sem prender), para o ruído poder agir nas pontas.
    float alvo = u.addNoise > 0.0 ? (linear > 0.5 ? max(linear, suave) : min(linear, suave)) : suave;
    float g = mix(linear, alvo, clamp(u.smoothCurve, 0.0, 1.0));

    // Medido: as cores valem em 8 bits.
    float3 c0 = floor(u.startColor.rgb * 255.0 + 0.5) / 255.0, c1 = floor(u.endColor.rgb * 255.0 + 0.5) / 255.0;
    if (u.swapColors) { float3 t = c0; c0 = c1; c1 = t; }
    if (u.addNoise > 0.0) {
        float3 dc = abs(c0 - c1);
        g += u.addNoise / (256.0 * max(0.001, max(dc.r, max(dc.g, dc.b)))) * (sorteio(float2(pi)) - 0.5);
    }
    float3 tex = mix(c0, c1, clamp(g, 0.0, 1.0)) * u.brightness;

    float3 b = fonte.rgb * fonte.a * u.bgBrightness;
    float3 cor;
    if (u.combine == 1) cor = tex * b;
    else if (u.combine == 2) cor = tex + b;
    else if (u.combine == 3) cor = 1.0 - (1.0 - tex) * (1.0 - b);
    else if (u.combine == 4) cor = abs(tex - b);
    else if (u.combine == 5) cor = mix(1.0 - 2.0 * (1.0 - tex) * (1.0 - b), 2.0 * tex * b, float3(lessThan(b, float3(0.5))));
    else cor = tex;

    // Medido: em "Normal" a saída leva o alfa da fonte (a cor reta é a própria conta).
    __nv_out = float4(clamp(cor, 0.0, 1.0), u.outputOpacity == 0 ? 1.0 : fonte.a);
    return __nv_out;
}
