// ---------------------------------------------------------------------------
// Cor de preenchimento (Node)
// origem : assets/effects/node-fill-color.xml
// id     : nova.effect.node-fill-color
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct node_fill_colorParams {
    float4 fillColor;
    int fillBlend;
};

// --- funcoes auxiliares do efeito
// k/255 pelo mais perto, montado nos bits do float: o valor exato que a textura de 8 bits devolve (ver
// `node-displacement-map.xml`).
static float oitoBits(float k) {
    uint n = uint(k);
    if (n == 0u) return 0.0;
    if (n == 255u) return 1.0;
    int j = 0;                                                    // o bit mais alto de n
    for (int i = 1; i < 8; i++) if (n >= (1u << uint(i))) j = i;
    int e = 31 - j;
    uint q = ((n << uint(e)) + 127u) / 255u;                      // entre 2^23 e 2^24
    return as_type<float>((uint(150 - e) << 23) + (q - 0x800000u));
}

static float3 oitoBits3(float3 k) {
    return float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
}

// O sRGB do GLES nos dois sentidos: o RT sRGB do Node converte para luz linear ao ler e de volta ao escrever.
static float3 linear(float3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c));
}

static float3 srgb(float3 l) {
    l = clamp(l, 0.0, 1.0);
    return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l));
}

// Os bytes que o RT sRGB de 8 bits guarda para esta cor linear.
static float3 bytesSrgb(float3 l) {
    return floor(srgb(l) * 255.0 + 0.5);
}

fragment float4 fx_node_fill_color(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant node_fill_colorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float4 c = inputImg.read(uint2(int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0))), uint(0));

    // A camada como o RT do Node a guarda: pré-multiplicada em luz linear, nos 8 bits do sRGB. No opaco é a cor
    // linear do próprio byte.
    float3 s = c.a >= 1.0 ? linear(c.rgb) : linear(oitoBits3(bytesSrgb(linear(c.rgb) * c.a)));
    float sa = c.a;

    // A cor do parâmetro chega crua e passa pelo GammaToLinearSpace do Unity, na ordem de contas do shader do Node.
    float3 f = u.fillColor.rgb * 0.305306017 + 0.682171106;
    f = u.fillColor.rgb * f + 0.0125228781;
    f = f * u.fillColor.rgb;

    float4 o;
    if (u.fillBlend == 1) {
        o = float4(s * f, sa * u.fillColor.a);
    } else if (u.fillBlend == 2) {
        o = float4(s + f, sa * (sa + u.fillColor.a));
    } else {
        o = float4(f, sa * u.fillColor.a);
    }
    // Num alvo de 8 bits a saída é presa a 0..1 antes da mistura.
    o = clamp(o, 0.0, 1.0);

    // `Blend SrcAlpha Zero` no RT sRGB: a cor vezes o alfa (em linear) e o alfa vezes ele mesmo, em 8 bits.
    float3 kc = bytesSrgb(o.rgb * o.a);
    float ka = floor(o.a * o.a * 255.0 + 0.5);
    if (ka <= 0.0) {
        __nv_out = float4(0.0);
        return __nv_out;
    }
    if (ka >= 255.0) {
        __nv_out = float4(oitoBits3(kc), 1.0);
        return __nv_out;
    }
    // O Nova guarda reto: a cor linear guardada dividida pelo alfa, de volta ao sRGB. Acima de 1 (a borda que o Node
    // guarda mais clara que o próprio alfa) fica em 1.
    float a = oitoBits(ka);
    __nv_out = float4(srgb(min(linear(oitoBits3(kc)) / a, float3(1.0))), a);
    return __nv_out;
}
