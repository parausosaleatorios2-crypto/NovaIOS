// ---------------------------------------------------------------------------
// Mangá (Node)
// origem : assets/effects/node-manga.xml
// id     : nova.effect.node-manga
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct node_mangaParams {
    float intensity;
};

// --- funcoes auxiliares do efeito
// k/255 pelo mais perto, montado nos bits do float: o valor exato que a textura de 8 bits devolve (o
// `floor(..)/255.0` vai pelo recíproco e erra o último bit — ver `am-color-balance.xml`).
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

static float3 linear(float3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c));
}

static float3 srgb(float3 l) {
    l = clamp(l, 0.0, 1.0);
    return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l));
}

// Os bytes que um RT sRGB de 8 bits guarda para esta cor linear.
static float3 bytesSrgb(float3 l) {
    return floor(srgb(l) * 255.0 + 0.5);
}

// O texel exato de uma imagem do tamanho da tela no pixel de pé (a linha 0 é a base, como nos RTs do Node): no
// buffer de camada (`eng.acEntradaDePe` = 0, a linha 0 é o topo) a linha é espelhada. Lê a entrada para o RT de pé e o RT
// de pé para a saída — os dois espelhos se desfazem, e a conta do meio é a da tela.
static float4 texelDePe(sampler2D img) {
    int2 T = int2(int(img.get_width()), int(img.get_height()));
    int2 p = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
    if (eng.acEntradaDePe != 1) p.y = T.y - 1 - p.y;
    return img.read(uint2(p), uint(0));
}

// O programa do Node, conta por conta (o `_SourceTex` é o `camadaRt`, o `_intensity` é o `u.intensity`).
// [in.vs_TEXCOORD0]: o UV do Node (cresce para cima). Sem a máscara interna: o ramo `_use_inner_mask` == 0.
static float4 manga(float2 in.vs_TEXCOORD0) {
    float4 u_xlat0;
    float3 u_xlat1;
    float4 u_xlat2;
    bool2 u_xlatb2;
    float4 u_xlat3;
    float4 u_xlat4;
    float u_xlat7;
    bool u_xlatb7;
    float u_xlat8;
    float u_xlat13;
    float u_xlat14;
    float u_xlat19;
    float u_xlat20;
    u_xlat0 = camadaRt.sample(__nv_smp, in.vs_TEXCOORD0.xy);
    u_xlat1.x = u.intensity * 0.125 + -0.200000018;
    u_xlat1.x = u_xlat0.x + (-u_xlat1.x);
    u_xlat1.x = u_xlat1.x * 3.33333349;
    u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
    u_xlat7 = u_xlat1.x * -2.0 + 3.0;
    u_xlat1.x = u_xlat1.x * u_xlat1.x;
    u_xlat13 = u_xlat1.x * u_xlat7;
    u_xlat19 = 2136.28125 / u.intensity;
    u_xlat19 = u_xlat19 * 1.66666663;
    u_xlat2.xy = in.vs_TEXCOORD0.xy * float2(0.707106411, 0.707106411);
    u_xlat2.x = u_xlat2.y + u_xlat2.x;
    u_xlat2.x = u_xlat19 * u_xlat2.x;
    u_xlat2.x = cos(u_xlat2.x);
    u_xlat2.x = u_xlat2.x * 0.25 + 0.5;
    u_xlat8 = in.vs_TEXCOORD0.x * 0.707106411 + (-u_xlat2.y);
    u_xlat19 = u_xlat19 * u_xlat8;
    u_xlat19 = cos(u_xlat19);
    u_xlat19 = u_xlat19 * 0.25 + u_xlat2.x;
    u_xlatb2.x = 0.300000012<u_xlat13;
    u_xlat1.x = u_xlat7 * u_xlat1.x + u_xlat19;
    u_xlat1.x = (u_xlatb2.x) ? u_xlat1.x : u_xlat13;
    u_xlat2 = in.vs_TEXCOORD0.xyxy + float4(-0.00390625, -0.00390625, 0.00390625, -0.00390625);
    u_xlat3 = camadaRt.sample(__nv_smp, u_xlat2.xy);
    u_xlat7 = dot(u_xlat3, float4(0.300000012, 0.589999974, 0.109999999, 0.25));
    u_xlat2 = camadaRt.sample(__nv_smp, u_xlat2.zw);
    u_xlat13 = dot(u_xlat2, float4(0.300000012, 0.589999974, 0.109999999, 0.25));
    u_xlat2 = in.vs_TEXCOORD0.xyxy + float4(-0.00390625, 0.0, -0.00390625, 0.00390625);
    u_xlat3 = camadaRt.sample(__nv_smp, u_xlat2.xy);
    u_xlat2.x = dot(u_xlat3, float4(0.300000012, 0.589999974, 0.109999999, 0.25));
    u_xlat3 = camadaRt.sample(__nv_smp, u_xlat2.zw);
    u_xlat8 = dot(u_xlat3, float4(0.300000012, 0.589999974, 0.109999999, 0.25));
    u_xlat3 = in.vs_TEXCOORD0.xyxy + float4(0.0, 0.00390625, 0.00390625, 0.00390625);
    u_xlat4 = camadaRt.sample(__nv_smp, u_xlat3.xy);
    u_xlat14 = dot(u_xlat4, float4(0.300000012, 0.589999974, 0.109999999, 0.25));
    u_xlat3 = camadaRt.sample(__nv_smp, u_xlat3.zw);
    u_xlat20 = dot(u_xlat3, float4(0.300000012, 0.589999974, 0.109999999, 0.25));
    u_xlat3.x = u_xlat13 + u_xlat20;
    u_xlat3.x = u_xlat2.x * 2.0 + u_xlat3.x;
    u_xlat3.x = (-u_xlat7) + u_xlat3.x;
    u_xlat2.x = (-u_xlat2.x) * 2.0 + u_xlat3.x;
    u_xlat2.x = (-u_xlat8) + u_xlat2.x;
    u_xlat8 = u_xlat14 * 2.0 + u_xlat8;
    u_xlat8 = u_xlat20 + u_xlat8;
    u_xlat8 = (-u_xlat7) + u_xlat8;
    u_xlat7 = (-u_xlat7) * 2.0 + u_xlat8;
    u_xlat7 = (-u_xlat13) + u_xlat7;
    u_xlat7 = u_xlat7 * u_xlat7;
    u_xlat7 = u_xlat2.x * u_xlat2.x + u_xlat7;
    u_xlatb7 = 0.0399999991<u_xlat7;
    u_xlat7 = u_xlatb7 ? -1.0 : float(0.0);
    u_xlat1.x = u_xlat7 * u_xlat19 + u_xlat1.x;
    u_xlat1.z = u_xlat0.w;
    return u_xlat1.xxxz;
}

fragment float4 fx_node_manga(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant node_mangaParams&  u    [[buffer(1)]],
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
        // O RT da camada está de pé: o UV do Node é o da tela, nos dois casos.
        float4 o = manga(in.acScreenNorm);
        // O alvo de 8 bits prende a saída a 0..1 antes da mistura (e o NaN da Intensidade 0 vai a 0).
        o = clamp(o, 0.0, 1.0);
        if (isnan(o.r)) o.rgb = float3(0.0);
        // `Blend SrcAlpha Zero` no RT sRGB: a cor vezes o alfa (em linear) e o alfa vezes ele mesmo.
        __nv_out = float4(o.rgb * o.a, o.a * o.a);
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
