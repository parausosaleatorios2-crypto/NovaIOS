// ---------------------------------------------------------------------------
// Desfoque cruzado (Node)
// origem : assets/effects/node-cross-blur.xml
// id     : nova.effect.node-cross-blur
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct node_cross_blurParams {
    float samples;
    float2 radius;
};

// --- funcoes auxiliares do efeito
// k/255 pelo mais perto, montado nos bits do float: o valor exato que a textura de 8 bits devolve (o
// `floor(..)/255.0` vai pelo recíproco e erra o último bit — ver `am-color-balance.xml`).
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

float3 oitoBits3(float3 k) {
    return float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
}

float3 linear(float3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c));
}

float3 srgb(float3 l) {
    l = clamp(l, 0.0, 1.0);
    return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l));
}

// Os bytes que um RT sRGB de 8 bits guarda para esta cor linear.
float3 bytesSrgb(float3 l) {
    return floor(srgb(l) * 255.0 + 0.5);
}

// O texel exato de uma imagem do tamanho da tela no pixel de pé (a linha 0 é a base, como nos RTs do Node): no
// buffer de camada (`eng.acEntradaDePe` = 0, a linha 0 é o topo) a linha é espelhada. Lê a entrada para o RT de pé e o RT
// de pé para a saída — os dois espelhos se desfazem, e a conta do meio é a da tela.
float4 texelDePe(sampler2D img) {
    int2 T = int2(int(img.get_width()), int(img.get_height()));
    int2 p = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
    if (eng.acEntradaDePe != 1) p.y = T.y - 1 - p.y;
    return img.read(uint2(p), uint(0));
}

// O programa do Node, conta por conta (o `_SourceTex` é o `camadaRt`, os parâmetros com os nomes do Nova).
// [in.vs_TEXCOORD0]: o UV do Node (cresce para cima). Sem a máscara interna: o ramo `_use_inner_mask` == 0.
float4 crossBlur(float2 in.vs_TEXCOORD0) {
    // As trocas do Nova: o `_samples` é o inteiro do Node (o slider vira float no uniform; o `int()` corta para o
    // zero, o mesmo `fcvtzs` do `PFloat::SetShader`), e o `_radius` é o Raio como está.
    int _samples = int(u.samples);
    float2 _radius = u.radius;
    float4 u_xlat0;
    int u_xlati0;
    float4 u_xlat1;
    float4 u_xlat2;
    float4 u_xlat3;
    float4 u_xlat4;
    float4 u_xlat5;
    float u_xlat6;
    float u_xlat18;
    u_xlati0 = _samples + int(0xFFFFFFFFu);
    u_xlat0.x = float(u_xlati0);
    u_xlat1 = float4(_radius.x, _radius.x, _radius.y, _radius.y) * float4(1.0, 0.0, 0.0, 1.0);
    u_xlat2.x = float(0.0);
    u_xlat2.y = float(0.0);
    u_xlat2.z = float(0.0);
    u_xlat2.w = float(0.0);
    u_xlat6 = float(0.0);
    for(int u_xlati_loop_1 = int(0) ; u_xlati_loop_1<_samples ; u_xlati_loop_1++)
    {
        u_xlat18 = float(u_xlati_loop_1);
        u_xlat18 = u_xlat18 / u_xlat0.x;
        u_xlat18 = u_xlat18 + -0.5;
        u_xlat3.x = -abs(u_xlat18) * 2.0 + 1.0;
        u_xlat6 = u_xlat3.x * 2.0 + u_xlat6;
        u_xlat4 = u_xlat1 * float4(u_xlat18) + in.vs_TEXCOORD0.xyxy;
        u_xlat5 = camadaRt.sample(__nv_smp, u_xlat4.xy);
        u_xlat4 = camadaRt.sample(__nv_smp, u_xlat4.zw);
        u_xlat5 = u_xlat5 * u_xlat5;
        u_xlat4 = u_xlat4 * u_xlat4;
        u_xlat5 = u_xlat5 * u_xlat3.xxxx + u_xlat2;
        u_xlat2 = u_xlat4 * u_xlat3.xxxx + u_xlat5;
    }
    u_xlat0 = u_xlat2 / float4(u_xlat6);
    u_xlat0 = sqrt(u_xlat0);
    return u_xlat0;
}

fragment float4 fx_node_cross_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant node_cross_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> camadaRt [[texture(1)]],
    texture2d<float> saidaRt [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        // A camada como o RT dela no Node: a cor em luz linear vezes o alfa, de pé; a GPU guarda em sRGB.
        float4 c = texelDePe(inputImg);
        __nv_out = float4(linear(c.rgb) * c.a, c.a);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        // O RT da camada está de pé: o UV do Node é o da tela, nos dois casos (a cruz é simétrica e o Raio é um
        // tamanho, sem troca de Y). `Blend One Zero`: a saída como está (o alvo sRGB de 8 bits prende, como o do Node).
        __nv_out = crossBlur(in.acScreenNorm);
        return __nv_out;
    }

    // Os bytes do RT de saída do Node (a GPU decodificou ao ler; codificar de novo devolve o byte guardado), de volta
    // à orientação da entrada.
    float4 o = texelDePe(saidaRt);
    float3 kc = bytesSrgb(o.rgb);
    float ka = floor(o.a * 255.0 + 0.5);
    if (ka <= 0.0) {
        __nv_out = float4(0.0);
        return __nv_out;
    }
    if (ka >= 255.0) {
        __nv_out = float4(oitoBits3(kc), 1.0);
        return __nv_out;
    }
    // O Nova guarda reto: a cor linear guardada dividida pelo alfa, de volta ao sRGB (acima de 1 fica em 1).
    float a = oitoBits(ka);
    __nv_out = float4(srgb(min(linear(oitoBits3(kc)) / a, float3(1.0))), a);
    return __nv_out;
}
