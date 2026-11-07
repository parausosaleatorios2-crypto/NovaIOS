// ---------------------------------------------------------------------------
// Trocar uma cor
// origem : assets/effects/replace-color.xml
// id     : nova.effect.replacecolor
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct replace_colorParams {
    float4 from;
    float4 to;
    float tolerance;
    float softness;
    float lumaWeight;
    int showMask;
};

// --- funcoes auxiliares do efeito
// RGB → HSV. O `h` volta em voltas (0..1), e é por isso que a diferença de
// matiz precisa da correção de volta inteira lá embaixo.
static float3 paraHsv(float3 c) {
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

static float3 paraRgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

fragment float4 fx_replace_color(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant replace_colorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    float3 pixel = paraHsv(clamp(color.rgb, 0.0, 1.0));
    float3 alvo = paraHsv(clamp(u.from.rgb, 0.0, 1.0));
    float3 nova = paraHsv(clamp(u.to.rgb, 0.0, 1.0));

    // Matiz é um CÍRCULO: 0,99 e 0,01 são vizinhos, não opostos. Sem esta
    // correção, o vermelho — que fica exatamente na emenda — seria o único
    // tom que o efeito não conseguiria selecionar.
    float dh = abs(pixel.x - alvo.x);
    dh = min(dh, 1.0 - dh) * 2.0;

    float ds = abs(pixel.y - alvo.y);
    float dl = abs(pixel.z - alvo.z) * clamp(u.lumaWeight, 0.0, 1.0);

    // Cinza não tem matiz: num pixel sem saturação o `h` é ruído. Pesar a
    // diferença de matiz pela saturação do pixel evita que o efeito agarre as
    // áreas neutras da imagem.
    float pesoMatiz = min(pixel.y, alvo.y) * 2.0;
    float distancia = length(float3(dh * pesoMatiz, ds, dl));

    float tol = max(u.tolerance, 0.0001);
    float suave = max(u.softness * tol, 0.0001);
    float selecao = 1.0 - smoothstep(tol - suave, tol + suave, distancia);

    if (u.showMask) {
        __nv_out = float4(float3(selecao), color.a);
        return __nv_out;
    }

    // A cor nova entra pela matiz e pela saturação; o brilho é o do pixel. É
    // isso que preserva a dobra do tecido e o realce.
    float3 trocada = paraRgb(float3(nova.x, nova.y * (pixel.y / max(alvo.y, 0.001)), pixel.z));

    __nv_out = float4(mix(color.rgb, clamp(trocada, 0.0, 1.0), selecao), color.a);
    return __nv_out;
}
