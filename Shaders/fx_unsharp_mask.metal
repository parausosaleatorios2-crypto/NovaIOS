// ---------------------------------------------------------------------------
// Máscara de nitidez
// origem : assets/effects/unsharp-mask.xml
// id     : nova.effect.unsharpmask
// passes : 9
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct unsharp_maskParams {
    float amount;
    float radius;
    float threshold;
    int kernel;
};

// --- funcoes auxiliares do efeito
const int METADE = 16;                 // 33 amostras por eixo

/** O raio em px do BUFFER (a prévia reduzida encolhe junto). */
float raioPx() { return max(u.radius, 0.0) * eng.acEscalaDePixel; }

/** O σ do gaussiano, em px do buffer. Medido no Unsharp Mask do AE: 0,775 · Radius + 0,4. */
float sigmaPx() { return (0.775 * max(u.radius, 0.0) + 0.4) * eng.acEscalaDePixel; }

/** Até onde o desfoque alcança, em px: três σ no gaussiano, a meia-largura na caixa. */
float alcancePx() { return u.kernel == 1 ? raioPx() + 0.5 : 3.0 * sigmaPx(); }

/** Em que degrau o desfoque roda: 0 = resolução inteira, 1 = 1/4, 2 = 1/16. */
int degrau() {
    float a = alcancePx();
    return a <= 16.0 ? 0 : (a <= 64.0 ? 1 : 2);
}

/** O peso de uma amostra a `d` px (do buffer) do centro, que cobre `largura` px. */
float peso(float d, float largura) {
    if (u.kernel == 1) {
        // a parte do intervalo [d − largura/2, d + largura/2] que cai dentro da caixa
        float m = raioPx() + 0.5;
        return max(min(d + 0.5 * largura, m) - max(d - 0.5 * largura, -m), 0.0);
    }
    float s = sigmaPx();
    return exp(-0.5 * d * d / (s * s));
}

/** Um eixo do desfoque: 33 amostras de `fonte`, cujos texels valem `escala` px do buffer. */
float4 borrar(sampler2D fonte, float2 uv, float2 eixo, float escala) {
    float2 texel = 1.0 / float2(int2(int(fonte.get_width()), int(fonte.get_height())));
    // um texel por amostra; se o alcance pede mais que 16 texels, as amostras se afastam
    float passo = max(1.0, alcancePx() / escala / float(METADE));
    float4 soma = float4(0.0);
    float total = 0.0;
    for (int i = -METADE; i <= METADE; i++) {
        float t = float(i) * passo;
        float p = peso(t * escala, passo * escala);
        soma += fonte.sample(__nv_smp, uv + eixo * texel * t) * p;
        total += p;
    }
    return soma / max(total, 1e-6);
}

/** Reduz `fonte` a 1/4: a média dos 4 × 4 px que viram um (quatro leituras bilineares). */
float4 reduzir(sampler2D fonte, float2 uv) {
    float2 t = 1.0 / float2(int2(int(fonte.get_width()), int(fonte.get_height())));
    return 0.25 * (fonte.sample(__nv_smp, uv + t * float2(-1.0, -1.0)) + fonte.sample(__nv_smp, uv + t * float2(1.0, -1.0)) +
                   fonte.sample(__nv_smp, uv + t * float2(-1.0, 1.0)) + fonte.sample(__nv_smp, uv + t * float2(1.0, 1.0)));
}

fragment float4 fx_unsharp_mask(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant unsharp_maskParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> quarto [[texture(1)]],
    texture2d<float> dezesseis [[texture(2)]],
    texture2d<float> ah [[texture(3)]],
    texture2d<float> av [[texture(4)]],
    texture2d<float> bh [[texture(5)]],
    texture2d<float> bv [[texture(6)]],
    texture2d<float> ch [[texture(7)]],
    texture2d<float> cv [[texture(8)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    int d = degrau();
    if (eng.acPass == 0) { __nv_out = d >= 1 ? reduzir(inputImg, uv) : float4(0.0); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = d == 2 ? reduzir(quarto, uv) : float4(0.0); return __nv_out; }
    // Só o degrau em uso trabalha; os outros saem na primeira linha.
    if (eng.acPass == 2) { __nv_out = d == 0 ? borrar(inputImg, uv, float2(1.0, 0.0), 1.0) : float4(0.0); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = d == 0 ? borrar(ah, uv, float2(0.0, 1.0), 1.0) : float4(0.0); return __nv_out; }
    if (eng.acPass == 4) { __nv_out = d == 1 ? borrar(quarto, uv, float2(1.0, 0.0), 4.0) : float4(0.0); return __nv_out; }
    if (eng.acPass == 5) { __nv_out = d == 1 ? borrar(bh, uv, float2(0.0, 1.0), 4.0) : float4(0.0); return __nv_out; }
    if (eng.acPass == 6) { __nv_out = d == 2 ? borrar(dezesseis, uv, float2(1.0, 0.0), 16.0) : float4(0.0); return __nv_out; }
    if (eng.acPass == 7) { __nv_out = d == 2 ? borrar(ch, uv, float2(0.0, 1.0), 16.0) : float4(0.0); return __nv_out; }

    float4 original = inputImg.sample(__nv_smp, uv);
    float4 borrado = d == 0 ? av.sample(__nv_smp, uv) : (d == 1 ? bv.sample(__nv_smp, uv) : cv.sample(__nv_smp, uv));

    // O "detalhe": o que o desfoque perdeu. Onde a imagem já era lisa, isto é quase zero — é
    // assim que a máscara realça borda sem "chapar" áreas planas.
    float3 detalhe = original.rgb - borrado.rgb;

    // O limiar olha para a ENERGIA do detalhe (o maior desvio entre os três canais): abaixo
    // dele a diferença é ruído/granulação, e o pixel fica intocado.
    float energia = max(max(abs(detalhe.r), abs(detalhe.g)), abs(detalhe.b));
    float3 resultado = energia > u.threshold ? original.rgb + detalhe * u.amount : original.rgb;

    __nv_out = float4(clamp(resultado, 0.0, 1.0), original.a);
    return __nv_out;
}
