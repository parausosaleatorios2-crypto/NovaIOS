// ---------------------------------------------------------------------------
// Chroma key
// origem : assets/effects/chroma-key.xml
// id     : nova.effect.chromakey
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct chroma_keyParams {
    float4 keyColor;
    float tolerance;
    float softness;
    float spill;
    int showMatte;
};

// --- funcoes auxiliares do efeito
static float2 chroma(float3 rgb) {
    float cb = -0.168736 * rgb.r - 0.331264 * rgb.g + 0.5 * rgb.b;
    float cr =  0.5 * rgb.r - 0.418688 * rgb.g - 0.081312 * rgb.b;
    return float2(cb, cr);
}

static float luma(float3 rgb) {
    return dot(rgb, float3(0.299, 0.587, 0.114));
}

fragment float4 fx_chroma_key(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant chroma_keyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Saturação da cor escolhida: ~0,53 no verde puro, 0 em preto/cinza/branco.
    // Até 0,05 o brilho conta inteiro; de 0,15 para cima não conta nada.
    float2 keyChroma = chroma(u.keyColor.rgb);
    float lumaWeight = 1.0 - smoothstep(0.05, 0.15, length(keyChroma));

    // Não chamar de `distance`: sombrearia a função nativa distance() para o
    // resto do shader. É legal em GLSL, mas basta alguém acrescentar uma linha
    // que a use para o arquivo parar de compilar sem motivo óbvio.
    float lumaGap = (luma(color.rgb) - luma(u.keyColor.rgb)) * lumaWeight;
    float chromaGap = length(float3(chroma(color.rgb) - keyChroma, lumaGap));

    // smoothstep dá a rampa de transparência. Sem essa rampa a borda do recorte
    // fica serrilhada como recorte de tesoura.
    float alpha = smoothstep(u.tolerance, u.tolerance + u.softness + 0.001, chromaGap);

    float3 rgb = color.rgb;

    // Vazamento: o verde do fundo reflete na pessoa e tinge a borda do cabelo.
    // A correção puxa o canal dominante do fundo para a média dos outros dois —
    // é o truque padrão, barato e convincente. Fundo sem cor não tinge nada:
    // com preto o "canal dominante" caía no verde e tirava verde da imagem toda.
    if (u.spill > 0.0 && lumaWeight < 1.0) {
        float keyStrength = max(max(u.keyColor.r, u.keyColor.g), u.keyColor.b);
        if (u.keyColor.g >= keyStrength) {
            float limit = (rgb.r + rgb.b) * 0.5;
            rgb.g = mix(rgb.g, min(rgb.g, limit), u.spill);
        } else if (u.keyColor.b >= keyStrength) {
            float limit = (rgb.r + rgb.g) * 0.5;
            rgb.b = mix(rgb.b, min(rgb.b, limit), u.spill);
        } else {
            float limit = (rgb.g + rgb.b) * 0.5;
            rgb.r = mix(rgb.r, min(rgb.r, limit), u.spill);
        }
    }

    // Ver o recorte em preto e branco é como se ajusta tolerância de verdade:
    // o alvo é fundo 100% preto e sujeito 100% branco, sem cinza no meio.
    if (u.showMatte) {
        __nv_out = float4(float3(alpha), 1.0);
        return __nv_out;
    }

    __nv_out = float4(rgb, color.a * alpha);
    return __nv_out;
}
