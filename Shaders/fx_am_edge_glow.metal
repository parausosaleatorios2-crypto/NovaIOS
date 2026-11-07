// ---------------------------------------------------------------------------
// Brilho de Borda
// origem : assets/effects/am-edge-glow.xml
// id     : nova.effect.am-edge-glow
// passes : 8
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_edge_glowParams {
    float smoothing;
    float threshold;
    int invert;
    float strength;
    float spread;
    float4 fillColor;
    float blend;
    float gamma;
    float brightness;
    float4 tintColor;
    float tint;
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

// O Y BT.709 de um ponto da camada pré-multiplicada, escrito como o findedges do AM.
float luz(float2 st) {
    return dot(float3(1.), pre.sample(__nv_smp, st).rgb*luminanceWeighting);
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

// O meio-lado: Borrão ÷ 2 × 1,14 ÷ 4 ÷ 3 da diagonal da imagem CHEIA (o `eng.acPreviewSize` do AM).
float ladoDoDesfoque() {
    return u.strength / 2.0 * 1.14 / 4.0 / 3.0 * length(float2(int2(int(pre.get_width()), int(pre.get_height()))));
}

// O fundo (a cena montada atrás da camada) no pixel da tela, pré-multiplicado (o do Anel).
float3 fundoNoPixel() {
    int2 T = int2(int(comp.get_width()), int(comp.get_height()));
    int2 px = clamp(int2(floor(__nv_acTela(in.acScreenNorm) * float2(T))), int2(0), T - 1);
    float4 f = comp.read(uint2(px), uint(0));
    return f.rgb * f.a;
}

// A saída pré-multiplicada do AM (`q`, já em 8 bits) em cor reta; onde a cor passa do alfa, com o fundo (o `paraReta`
// do Anel e do Sharpen: o menor alfa que dá a mesma soma na composição Normal com qualquer opacidade).
float4 paraReta(float4 q) {
    if (all(lessThanEqual(q.rgb, float3(q.a)))) return q.a > 0.0 ? float4(q.rgb / q.a, q.a) : float4(0.0);
    float3 d = fundoNoPixel();
    float3 sobra = q.rgb - d * q.a;
    float3 folga = 1.0 - d;
    float a = q.a;
    for (int i = 0; i < 3; i++) {
        // Canal com o fundo cheio (1): lá e aqui a soma fica em 1 com qualquer alfa, então ele não pede nada.
        if (sobra[i] > 0.0 && folga[i] > 0.0) a = max(a, sobra[i] / folga[i]);
    }
    a = min(a, 1.0);
    return a > 0.0 ? float4(clamp(d + sobra / a, 0.0, 1.0), a) : float4(0.0);
}

fragment float4 fx_am_edge_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_edge_glowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    texture2d<float> pre [[texture(2)]],
    texture2d<float> edge [[texture(3)]],
    texture2d<float> downImg [[texture(4)]],
    texture2d<float> blurH [[texture(5)]],
    texture2d<float> blurV [[texture(6)]],
    texture2d<float> hblur [[texture(7)]],
    texture2d<float> brilho [[texture(8)]])
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
        // O findedges-edgeglow do AM, na mesma ordem de contas (n é o vizinho de CIMA, como no t do AM).
        float2 st = in.acScreenNorm;
        float2 fragSize = float2(1.)/float2(int2(int(pre.get_width()), int(pre.get_height()))) * u.smoothing;
        float w  = luz(float2(st.x - fragSize.x, st.y));
        float e  = luz(float2(st.x + fragSize.x, st.y));
        float n  = luz(float2(st.x, st.y + cima * fragSize.y));
        float s  = luz(float2(st.x, st.y - cima * fragSize.y));
        float nw = luz(float2(st.x - fragSize.x, st.y + cima * fragSize.y));
        float ne = luz(float2(st.x + fragSize.x, st.y + cima * fragSize.y));
        float sw = luz(float2(st.x - fragSize.x, st.y - cima * fragSize.y));
        float se = luz(float2(st.x + fragSize.x, st.y - cima * fragSize.y));

        float v = nw * 3. + n * 10. + ne * 3. + sw * -3. + s * -10. + se * -3.;
        float h = nw * -3. + w * -10. + sw * -3. + ne * 3. + e * 10. + se * 3.;
        float g = clamp(sqrt(h*h + v*v)-u.threshold, 0., 1.);

        float4 texColor = pre.sample(__nv_smp, st);
        __nv_out = u.invert ? float4(1.-g,1.-g,1.-g,1.) * texColor.a : float4(g,g,g,1.) * texColor;
        return __nv_out;
    }
    if (eng.acPass == 2) {
        __nv_out = edge.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }
    if (eng.acPass == 3) {
        float2 passo = float2(1.0 / float2(int2(int(downImg.get_width()), int(downImg.get_height()))).x, 0.0);
        __nv_out = desfocar(downImg, passo, in.acScreenNorm, ladoDoDesfoque());
        return __nv_out;
    }
    if (eng.acPass == 4) {
        // O passo aponta para CIMA e a soma do par fica na mesma ordem da do AM (o de baixo primeiro).
        float2 passo = float2(0.0, cima / float2(int2(int(blurH.get_width()), int(blurH.get_height()))).y);
        float4 r = desfocar(blurH, passo, in.acScreenNorm, ladoDoDesfoque());
        // Borrão 0: o Gaussian do AM lê a entrada dele (o `edge`) aqui (na meia resolução: a média de 2 × 2).
        __nv_out = u.strength <= 0.0 ? edge.sample(__nv_smp, in.acScreenNorm) : r;
        return __nv_out;
    }
    if (eng.acPass == 5) {
        __nv_out = blurV.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }
    if (eng.acPass == 6) {
        // A mistura do Edge Glow do AM, na mesma ordem. O corte em 0..1 é o do alvo de 8 bits; escrito para o projeto
        // de 32 bits sair igual.
        float3x3 rgb2yuv = float3x3(
             0.299,     0.587,    0.114,
            -0.14713,  -0.28886,  0.436,
             0.615,    -0.51499, -0.10001
        );
        float3x3 yuv2rgb = float3x3(
            1.0,  0.0,      1.13983,
            1.0, -0.39465, -0.58060,
            1.0,  2.03211,  0.0
        );

        float4 glow = hblur.sample(__nv_smp, in.acScreenNorm);
        float4 base = pre.sample(__nv_smp, in.acScreenNorm);
        // Brilho de alfa 0: no AM, 0 ÷ 0 leva o pixel inteiro a NaN, gravado como 0.
        if (glow.a == 0.0) {
            __nv_out = float4(0.0);
            return __nv_out;
        }
        glow.rgb /= glow.a;
        glow.rgb = pow(glow.rgb, float3(max(0.0001,3.-u.spread)));
        if (base.a > 0.0) {
            base.rgb /= base.a;
            base.rgb = pow(base.rgb,float3(1.0/u.gamma));
            base.rgb = ((base.rgb * rgb2yuv) + float3(u.brightness,0.,0.)) * yuv2rgb;
            base.rgb = clamp(base.rgb, 0.0, 1.0);
        } else {
            // Camada de alfa 0: no AM o NaN de 0 ÷ 0 sai do corte em 0..1 como 0.
            base.rgb = float3(0.0);
        }
        float lum = dot(luminanceWeighting, glow.rgb);
        float fill = 1.0;
        glow.rgb *= glow.a;
        base.rgb *= base.a;
        float4 r = (mix(base,base*u.tintColor,u.tint)*fill)
            + mix(glow * mix(lum,1.,fill), u.fillColor*lum, max(clamp(u.blend, 0.0, 1.0)*(1.-lum),u.blend-1.0));
        __nv_out = clamp(r, 0.0, 1.0);
        return __nv_out;
    }

    __nv_out = paraReta(brilho.sample(__nv_smp, in.acScreenNorm));
    return __nv_out;
}
