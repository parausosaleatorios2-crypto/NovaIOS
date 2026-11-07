// ---------------------------------------------------------------------------
// Varredura de Luminosidade
// origem : assets/effects/am-glow-scan.xml
// id     : nova.effect.am-glow-scan
// passes : 7
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_glow_scanParams {
    float threshold;
    float radius;
    float power;
    float strength;
    float4 fillColor;
    float blend;
    float fill;
    float alpha;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

// O float que a textura de 8 bits devolve para o nível k (k/255 arredondado como o hardware), montado pelos bits: gravado
// num alvo de 8 bits volta a ser k em qualquer GPU (o `oitoBits` do Equilíbrio de cor).
float oitoBits(float k) {
    uint n = uint(k);
    if (n == 0u) return 0.0;
    if (n == 255u) return 1.0;
    int j = 0;                                                    // o bit mais alto de n
    for (int i = 1; i < 8; i++) if (n >= (1u << uint(i))) j = i;
    int e = 31 - j;
    uint q = ((n << uint(e)) + 127u) / 255u;                      // entre 2^23 e 2^24
    return as_type<float>((uint(150 - e) << 23) + (q - 0x800000u));
}

// A gaussiana de meio-lado `lado` (em pixels de `img`) no eixo `passo`, na mesma ordem de contas do Gaussian do AM (a
// do `am-gaussian-blur.xml`): os pesos tirados um do outro por multiplicação e duas amostras juntas numa leitura.
float4 desfocar(sampler2D img, float2 passo, float2 st, float lado) {
    if (u.strength <= 0.0) return float4(0.0);
    float sigma = lado / 2.14596602;
    float3 g;
    g.x = 1.0 / (sqrt(2.0 * PI) * sigma);
    g.y = exp(-0.5 / (sigma * sigma));
    g.z = g.y * g.y;
    float4 soma = float4(0.0);
    float total = 0.0;
    soma += img.sample(__nv_smp, st) * g.x;
    total += g.x;
    for (float i = 1.0; i <= lado; i += 2.0) {
        float d0 = i;
        float d1 = i + 1.0;
        g.xy *= g.yz;
        total += 2.0 * g.x;
        float p0 = g.x;
        g.xy *= g.yz;
        total += 2.0 * g.x;
        float p1 = g.x;
        float par = p0 + p1;
        float d = (d0 * p0 + d1 * p1) / par;
        float2 stL = st - d * passo;
        float2 stR = st + d * passo;
        soma += img.sample(__nv_smp, stL) * par;
        soma += img.sample(__nv_smp, stR) * par;
    }
    return soma / total;
}

// O meio-lado: Suavização ÷ 2 × 1,14 ÷ 4 ÷ 3 da diagonal da imagem CHEIA (o `eng.acPreviewSize` do AM).
float ladoDoDesfoque() {
    return u.strength / 2.0 * 1.14 / 4.0 / 3.0 * length(float2(int2(int(pre.get_width()), int(pre.get_height()))));
}

// O corte que o alvo de 8 bits do AM faz ao gravar: 0..1, e NaN vira 0. Escrito para o projeto de 32 bits sair igual e
// para o NaN não depender do `clamp` (indefinido com NaN): a comparação com NaN é falsa e cai no 0.
float4 corteDoAlvo(float4 c) {
    float4 r;
    for (int i = 0; i < 4; i++) r[i] = c[i] > 0.0 ? min(c[i], 1.0) : 0.0;
    return r;
}

fragment float4 fx_am_glow_scan(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_glow_scanParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pre [[texture(1)]],
    texture2d<float> downImg [[texture(2)]],
    texture2d<float> blurH [[texture(3)]],
    texture2d<float> blurV [[texture(4)]],
    texture2d<float> hblur [[texture(5)]],
    texture2d<float> varredura [[texture(6)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // Na tela a entrada chega de pé (t = 0 embaixo, como no AM): "para cima" é +t. Deitada, vira para baixo.
    float cima = eng.acEntradaDePe == 1 ? 1.0 : -1.0;

    if (eng.acPass == 0) {
        // A camada do AM chega pré-multiplicada EM 8 BITS, pelo mais perto (o premul do Android); no opaco a cor já é o
        // float da textura, bit a bit.
        float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
        float3 p = c.rgb;
        if (c.a < 1.0) {
            float3 k = floor(c.rgb * c.a * 255.0 + 0.5);
            p = float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
        }
        __nv_out = float4(p, c.a);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        __nv_out = pre.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }
    if (eng.acPass == 2) {
        float2 passo = float2(1.0 / float2(int2(int(downImg.get_width()), int(downImg.get_height()))).x, 0.0);
        __nv_out = desfocar(downImg, passo, in.acScreenNorm, ladoDoDesfoque());
        return __nv_out;
    }
    if (eng.acPass == 3) {
        // O passo aponta para CIMA e a soma do par fica na mesma ordem da do AM (o de baixo primeiro).
        float2 passo = float2(0.0, cima / float2(int2(int(blurH.get_width()), int(blurH.get_height()))).y);
        float4 r = desfocar(blurH, passo, in.acScreenNorm, ladoDoDesfoque());
        // Suavização 0: o Gaussian do AM lê a entrada dele (a camada) aqui (na meia resolução: a média de 2 × 2).
        __nv_out = u.strength <= 0.0 ? pre.sample(__nv_smp, in.acScreenNorm) : r;
        return __nv_out;
    }
    if (eng.acPass == 4) {
        __nv_out = blurV.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }
    if (eng.acPass == 5) {
        // A conta do Glow Scan do AM, na mesma ordem, com as MESMAS expressões: onde o GLSL não define a resposta
        // (`pow(0, 0)`, e o 0 ÷ 0 do Raio 0, que leva `pow(x, NaN)`), cada GPU dá aqui o que dá lá.
        float4 baseColor = hblur.sample(__nv_smp, in.acScreenNorm);
        float4 mainColor = pre.sample(__nv_smp, in.acScreenNorm) * u.fill;
        float luma = dot(baseColor.rgb, luminanceWeighting);
        float adjThreshold = u.threshold * (1.0 + u.radius) - u.radius;
        if (luma >= adjThreshold && luma <= adjThreshold + u.radius) {
            float halfRadius = u.radius*0.5;
            float linearPos = abs((luma - adjThreshold - halfRadius)/halfRadius);
            // `pow(0, 0)` (Pena 0, ou o meio exato da faixa, num canal 0) é indefinido no GLSL: fica a MESMA expressão do
            // AM, para cada GPU dar aqui o que dá lá (a do PC dá 1).
            float4 glow = pow(mix(baseColor, u.fillColor*luma, u.blend*0.99), float4(u.power) * pow(linearPos, 2.0));
            mainColor = mix(mainColor, baseColor + glow, u.alpha);
        }
        __nv_out = corteDoAlvo(mainColor);
        return __nv_out;
    }

    // A saída do AM (já em 8 bits) em cor reta. A cor nunca passa do alfa (ver o cabeçalho): o `min` só guarda.
    float4 q = varredura.sample(__nv_smp, in.acScreenNorm);
    __nv_out = q.a > 0.0 ? float4(min(q.rgb / q.a, float3(1.0)), q.a) : float4(0.0);
    return __nv_out;
}
