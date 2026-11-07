// ---------------------------------------------------------------------------
// Desfoque gaussiano (Node)
// origem : assets/effects/node-gaussian-blur.xml
// id     : nova.effect.node-gaussian-blur
// passes : 6
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct node_gaussian_blurParams {
    float amount;
};

// --- funcoes auxiliares do efeito
// k/255 pelo mais perto, montado nos bits do float: o valor exato que a textura de 8 bits devolve (ver
// `node-fill-color.xml`).
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
// de pé para a saída — os dois espelhos se desfazem, e os programas do Node rodam como na tela.
static float4 texelDePe(sampler2D img) {
    int2 T = int2(int(img.get_width()), int(img.get_height()));
    int2 p = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
    if (eng.acEntradaDePe != 1) p.y = T.y - 1 - p.y;
    return img.read(uint2(p), uint(0));
}

// O programa 1 do Node (`_hblur`), conta por conta: a gaussiana na horizontal, na metade. `res` = `_resolution`.
static float4 passeHorizontal(float2 uv, float2 res) {
    float u_xlat0;
    float3 u_xlat1;
    float4 u_xlat2;
    float3 u_xlat3;
    float2 u_xlat4;
    float4 u_xlat5;
    float3 u_xlat6;
    bool u_xlatb6;
    float4 u_xlat7;
    float4 u_xlat8;
    float u_xlat9;
    float u_xlat10;
    float2 u_xlat18;
    float2 u_xlat22;
    float u_xlat24;
    float u_xlat28;
    float u_xlat30;
    u_xlat0 = res.x * 0.5;
    u_xlat9 = u.amount * 0.0474999994;
    u_xlat18.x = dot(res.xy, res.xy);
    u_xlat18.x = sqrt(u_xlat18.x);
    u_xlat9 = u_xlat18.x * u_xlat9;
    u_xlat0 = float(1.0) / u_xlat0;
    u_xlat18.xy = float2(u_xlat9) * float2(0.465990603, 1.16806519);
    u_xlat18.y = float(1.0) / u_xlat18.y;
    u_xlat18.x = u_xlat18.x * u_xlat18.x;
    u_xlat18.x = -0.5 / u_xlat18.x;
    u_xlat18.x = u_xlat18.x * 1.44269502;
    u_xlat18.x = exp2(u_xlat18.x);
    u_xlat1.z = u_xlat18.x * u_xlat18.x;
    u_xlat2 = downImg.sample(__nv_smp, uv);
    u_xlat2 = u_xlat18.yyyy * u_xlat2;
    u_xlat3.z = u_xlat1.z;
    u_xlat4.y = 0.0;
    u_xlat5 = u_xlat2;
    u_xlat22.xy = u_xlat18.yx;
    u_xlat28 = u_xlat18.y;
    u_xlat30 = 1.0;
    while (true) {
        u_xlatb6 = u_xlat9 < u_xlat30;
        if (u_xlatb6) { break; }
        u_xlat6.xy = float2(u_xlat30) + float2(1.0, 2.0);
        u_xlat1.xy = u_xlat22.xy;
        u_xlat3.xy = u_xlat1.yz * u_xlat1.xy;
        u_xlat24 = u_xlat3.x * 2.0 + u_xlat28;
        u_xlat22.xy = u_xlat3.yz * u_xlat3.xy;
        u_xlat28 = u_xlat22.x * 2.0 + u_xlat24;
        u_xlat1.x = u_xlat1.x * u_xlat1.y + u_xlat22.x;
        u_xlat10 = u_xlat22.x * u_xlat6.x;
        u_xlat10 = u_xlat30 * u_xlat3.x + u_xlat10;
        u_xlat10 = u_xlat10 / u_xlat1.x;
        u_xlat4.x = u_xlat0 * u_xlat10;
        u_xlat3.xy = (-u_xlat4.xy) + uv;
        u_xlat3.xy = clamp(u_xlat3.xy, 0.0, 1.0);
        u_xlat6.xz = u_xlat4.xy + uv;
        u_xlat6.xz = clamp(u_xlat6.xz, 0.0, 1.0);
        u_xlat7 = downImg.sample(__nv_smp, u_xlat3.xy);
        u_xlat7 = u_xlat7 * u_xlat1.xxxx + u_xlat5;
        u_xlat8 = downImg.sample(__nv_smp, u_xlat6.xz);
        u_xlat5 = u_xlat8 * u_xlat1.xxxx + u_xlat7;
        u_xlat30 = u_xlat6.y;
    }
    return u_xlat5 / float4(u_xlat28);
}

// O programa 2 do Node (`_vblur`), conta por conta: a gaussiana na vertical (o `hblur` está de pé, como no Node).
static float4 passeVertical(float2 uv, float2 res) {
    float4 u_xlat0;
    float2 u_xlat1;
    float4 u_xlat2;
    float4 u_xlat3;
    float3 u_xlat4;
    float4 u_xlat5;
    float3 u_xlat6;
    float4 u_xlat7;
    float4 u_xlat8;
    float2 u_xlat9;
    float u_xlat11;
    float2 u_xlat19;
    float u_xlat27;
    float u_xlat29;
    float u_xlat31;
    bool u_xlatb31;
    u_xlat0.x = u.amount * 0.0474999994;
    u_xlat9.x = dot(res.xy, res.xy);
    u_xlat9.x = sqrt(u_xlat9.x);
    u_xlat0.x = u_xlat9.x * u_xlat0.x;
    u_xlat9.x = res.y * 0.5;
    u_xlat1.y = float(1.0) / u_xlat9.x;
    u_xlat9.xy = u_xlat0.xx * float2(0.465990603, 1.16806519);
    u_xlat9.y = float(1.0) / u_xlat9.y;
    u_xlat9.x = u_xlat9.x * u_xlat9.x;
    u_xlat9.x = -0.5 / u_xlat9.x;
    u_xlat9.x = u_xlat9.x * 1.44269502;
    u_xlat9.x = exp2(u_xlat9.x);
    u_xlat2.z = u_xlat9.x * u_xlat9.x;
    u_xlat3 = hblur.sample(__nv_smp, uv);
    u_xlat3 = u_xlat9.yyyy * u_xlat3;
    u_xlat4.z = u_xlat2.z;
    u_xlat1.x = 0.0;
    u_xlat5 = u_xlat3;
    u_xlat19.xy = u_xlat9.yx;
    u_xlat27 = u_xlat9.y;
    u_xlat29 = 1.0;
    while (true) {
        u_xlatb31 = u_xlat0.x < u_xlat29;
        if (u_xlatb31) { break; }
        u_xlat6.xy = float2(u_xlat29) + float2(1.0, 2.0);
        u_xlat2.xy = u_xlat19.xy;
        u_xlat4.xy = u_xlat2.yz * u_xlat2.xy;
        u_xlat31 = u_xlat4.x * 2.0 + u_xlat27;
        u_xlat19.xy = u_xlat4.yz * u_xlat4.xy;
        u_xlat27 = u_xlat19.x * 2.0 + u_xlat31;
        u_xlat2.x = u_xlat2.x * u_xlat2.y + u_xlat19.x;
        u_xlat11 = u_xlat19.x * u_xlat6.x;
        u_xlat11 = u_xlat29 * u_xlat4.x + u_xlat11;
        u_xlat11 = u_xlat11 / u_xlat2.x;
        u_xlat4.xy = (-float2(u_xlat11)) * u_xlat1.xy + uv;
        u_xlat4.xy = clamp(u_xlat4.xy, 0.0, 1.0);
        u_xlat6.xz = float2(u_xlat11) * u_xlat1.xy + uv;
        u_xlat6.xz = clamp(u_xlat6.xz, 0.0, 1.0);
        u_xlat7 = hblur.sample(__nv_smp, u_xlat4.xy);
        u_xlat7 = u_xlat7 * u_xlat2.xxxx + u_xlat5;
        u_xlat8 = hblur.sample(__nv_smp, u_xlat6.xz);
        u_xlat5 = u_xlat8 * u_xlat2.xxxx + u_xlat7;
        u_xlat29 = u_xlat6.y;
    }
    u_xlat0 = u_xlat5 / float4(u_xlat27);
    // (o Node devolve a entrada com Quantidade <= 0; aqui esse passe nem roda — `skipIfZero`)
    return u_xlat0;
}

fragment float4 fx_node_gaussian_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant node_gaussian_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pre [[texture(1)]],
    texture2d<float> downImg [[texture(2)]],
    texture2d<float> hblur [[texture(3)]],
    texture2d<float> vblur [[texture(4)]],
    texture2d<float> saida [[texture(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // `_resolution`: o tamanho da composição (o RT cheio).
    float2 res = float2(int2(int(pre.get_width()), int(pre.get_height())));

    if (eng.acPass == 0) {
        // A camada como o RT do Node a guarda: a cor em luz linear vezes o alfa, de pé; a GPU guarda em sRGB.
        float4 c = texelDePe(inputImg);
        __nv_out = float4(linear(c.rgb) * c.a, c.a);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        // O programa 0 do Node: a metade, uma leitura no meio de 2 × 2 (em luz linear).
        __nv_out = pre.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }
    if (eng.acPass == 2) {
        __nv_out = passeHorizontal(in.acScreenNorm, res);
        return __nv_out;
    }
    if (eng.acPass == 3) {
        __nv_out = passeVertical(in.acScreenNorm, res);
        return __nv_out;
    }
    if (eng.acPass == 4) {
        // O programa 4 do Node (sem a máscara interna): de volta ao tamanho cheio pelo filtro linear, no RT sRGB.
        __nv_out = vblur.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }

    // Abaixo de 0,0001 o Node só copia a entrada para a saída: a camada como está.
    if (!(u.amount >= 0.0001)) {
        __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }
    // Os bytes do RT de saída do Node (a GPU decodificou ao ler; codificar de novo devolve o byte guardado), de volta
    // à orientação da entrada.
    float4 o = texelDePe(saida);
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
