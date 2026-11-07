// ---------------------------------------------------------------------------
// Desfoque direcional (Node)
// origem : assets/effects/node-directional-blur.xml
// id     : nova.effect.node-directional-blur
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct node_directional_blurParams {
    float radius;
    float direction;
    float dispersion;
    float samples;
    int turbulence;
    float evolution;
    float strength;
    float2 turbulenceScale;
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
float4 directionalBlur(float2 in.vs_TEXCOORD0) {
    // As duas trocas do Nova: o `_samples` é o inteiro do Node (o slider vira float no uniform; o `int()`
    // corta para o zero, o mesmo `fcvtzs` do `PFloat::SetShader`), e o `_enable_turbulence`, o 0/1 do `PBool`.
    int nAmostras = int(u.samples);
    int ligaTurbulencia = u.turbulence ? 1 : 0;
    float4 u_xlat0;
    bool u_xlatb0;
    float4 u_xlat1;
    float4 u_xlat2;
    bool3 u_xlatb2;
    float4 u_xlat3;
    float4 u_xlat4;
    float4 u_xlat5;
    float3 u_xlat6;
    float4 u_xlat7;
    float4 u_xlat8;
    float4 u_xlat9;
    bool4 u_xlatb9;
    float4 u_xlat10;
    float u_xlat11;
    int u_xlati11;
    float u_xlat12;
    int u_xlati13;
    float u_xlat23;
    float u_xlat24;
    bool u_xlatb24;
    float u_xlat33;
    float u_xlat35;

    u_xlatb0 = 0<ligaTurbulencia;
    if(u_xlatb0){
        u_xlat0.xy = in.vs_TEXCOORD0.xy * float2(u.turbulenceScale.x, u.turbulenceScale.y);
        u_xlat0.z = u.evolution;
        u_xlat33 = dot(u_xlat0.xyz, float3(0.333333343, 0.333333343, 0.333333343));
        u_xlat1.xyz = float3(u_xlat33) + u_xlat0.xyz;
        u_xlat1.xyz = floor(u_xlat1.xyz);
        u_xlat0.xyz = u_xlat0.xyz + (-u_xlat1.xyz);
        u_xlat33 = dot(u_xlat1.xyz, float3(0.166666672, 0.166666672, 0.166666672));
        u_xlat0.xyz = float3(u_xlat33) + u_xlat0.xyz;
        u_xlatb2.xyz = greaterThanEqual(u_xlat0.zxyz, u_xlat0.xyzx).xyz;
        u_xlat3.x = u_xlatb2.y ? float(1.0) : 0.0;
        u_xlat3.y = u_xlatb2.z ? float(1.0) : 0.0;
        u_xlat3.z = u_xlatb2.x ? float(1.0) : 0.0;
;
        u_xlat2.x = (u_xlatb2.x) ? float(0.0) : float(1.0);
        u_xlat2.y = (u_xlatb2.y) ? float(0.0) : float(1.0);
        u_xlat2.z = (u_xlatb2.z) ? float(0.0) : float(1.0);
        u_xlat4.xyz = min(u_xlat2.xyz, u_xlat3.xyz);
        u_xlat2.xyz = max(u_xlat2.yzx, u_xlat3.yzx);
        u_xlat3.xyz = u_xlat0.xyz + (-u_xlat4.xyz);
        u_xlat3.xyz = u_xlat3.xyz + float3(0.166666672, 0.166666672, 0.166666672);
        u_xlat5.xyz = u_xlat0.xyz + (-u_xlat2.zxy);
        u_xlat5.xyz = u_xlat5.xyz + float3(0.333333343, 0.333333343, 0.333333343);
        u_xlat6.xyz = u_xlat0.xyz + float3(-0.5, -0.5, -0.5);
        u_xlat7.xyz = u_xlat1.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat7.xyz = floor(u_xlat7.xyz);
        u_xlat1.xyz = (-u_xlat7.xyz) * float3(289.0, 289.0, 289.0) + u_xlat1.xyz;
        u_xlat7.x = float(0.0);
        u_xlat7.w = float(1.0);
        u_xlat7.y = u_xlat4.z;
        u_xlat7.z = u_xlat2.y;
        u_xlat7 = u_xlat1.zzzz + u_xlat7;
        u_xlat8 = u_xlat7 * u_xlat7;
        u_xlat7 = u_xlat8 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat7;
        u_xlat8 = u_xlat7 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat8 = floor(u_xlat8);
        u_xlat7 = (-u_xlat8) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat7;
        u_xlat7 = u_xlat1.yyyy + u_xlat7;
        u_xlat8.x = float(0.0);
        u_xlat8.w = float(1.0);
        u_xlat8.y = u_xlat4.y;
        u_xlat8.z = u_xlat2.x;
        u_xlat7 = u_xlat7 + u_xlat8;
        u_xlat8 = u_xlat7 * u_xlat7;
        u_xlat7 = u_xlat8 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat7;
        u_xlat8 = u_xlat7 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat8 = floor(u_xlat8);
        u_xlat7 = (-u_xlat8) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat7;
        u_xlat1 = u_xlat1.xxxx + u_xlat7;
        u_xlat2.x = float(0.0);
        u_xlat2.w = float(1.0);
        u_xlat2.y = u_xlat4.x;
        u_xlat1 = u_xlat1 + u_xlat2;
        u_xlat2 = u_xlat1 * u_xlat1;
        u_xlat1 = u_xlat2 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat1;
        u_xlat2 = u_xlat1 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat2 = floor(u_xlat2);
        u_xlat1 = (-u_xlat2) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat1;
        u_xlat2 = u_xlat1 * float4(0.0204081647, 0.0204081647, 0.0204081647, 0.0204081647);
        u_xlat2 = floor(u_xlat2);
        u_xlat1 = (-u_xlat2) * float4(49.0, 49.0, 49.0, 49.0) + u_xlat1;
        u_xlat2 = u_xlat1 * float4(0.142857149, 0.142857149, 0.142857149, 0.142857149);
        u_xlat2 = floor(u_xlat2);
        u_xlat1 = (-u_xlat2) * float4(7.0, 7.0, 7.0, 7.0) + u_xlat1;
        u_xlat2 = u_xlat2 * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
        u_xlat1 = u_xlat1.xzyw * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
        u_xlat4 = -abs(u_xlat2) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat4 = -abs(u_xlat1.xzwy) + u_xlat4.xywz;
        u_xlat7.xz = floor(u_xlat2.xy);
        u_xlat7.yw = floor(u_xlat1.xz);
        u_xlat7 = u_xlat7 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat8.xz = floor(u_xlat2.zw);
        u_xlat8.yw = floor(u_xlat1.yw);
        u_xlat8 = u_xlat8 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlatb9 = greaterThanEqual(float4(0.0, 0.0, 0.0, 0.0), u_xlat4.xywz);
        u_xlat9.x = (u_xlatb9.x) ? float(-1.0) : float(-0.0);
        u_xlat9.y = (u_xlatb9.y) ? float(-1.0) : float(-0.0);
        u_xlat9.z = (u_xlatb9.z) ? float(-1.0) : float(-0.0);
        u_xlat9.w = (u_xlatb9.w) ? float(-1.0) : float(-0.0);
        u_xlat10.xz = u_xlat2.xy;
        u_xlat10.yw = u_xlat1.xz;
        u_xlat7 = u_xlat7.zwxy * u_xlat9.yyxx + u_xlat10.zwxy;
        u_xlat1.xz = u_xlat2.zw;
        u_xlat1 = u_xlat8 * u_xlat9.zzww + u_xlat1;
        u_xlat2.xy = u_xlat7.zw;
        u_xlat2.z = u_xlat4.x;
        u_xlat33 = dot(u_xlat2.xyz, u_xlat2.xyz);
        u_xlat7.z = u_xlat4.y;
        u_xlat35 = dot(u_xlat7.xyz, u_xlat7.xyz);
        u_xlat8.xy = u_xlat1.xy;
        u_xlat8.z = u_xlat4.w;
        u_xlat1.x = dot(u_xlat8.xyz, u_xlat8.xyz);
        u_xlat4.xy = u_xlat1.zw;
        u_xlat12 = dot(u_xlat4.xyz, u_xlat4.xyz);
        u_xlat33 = rsqrt(u_xlat33);
        u_xlat23 = rsqrt(u_xlat35);
        u_xlat1.x = rsqrt(u_xlat1.x);
        u_xlat12 = rsqrt(u_xlat12);
        u_xlat2.xyz = float3(u_xlat33) * u_xlat2.xyz;
        u_xlat7.xyz = float3(u_xlat23) * u_xlat7.xyz;
        u_xlat1.xzw = u_xlat1.xxx * u_xlat8.xyz;
        u_xlat4.xyz = float3(u_xlat12) * u_xlat4.xyz;
        u_xlat8.x = dot(u_xlat0.xyz, u_xlat0.xyz);
        u_xlat8.y = dot(u_xlat3.xyz, u_xlat3.xyz);
        u_xlat8.z = dot(u_xlat5.xyz, u_xlat5.xyz);
        u_xlat8.w = dot(u_xlat6.xyz, u_xlat6.xyz);
        u_xlat8 = (-u_xlat8) + float4(0.600000024, 0.600000024, 0.600000024, 0.600000024);
        u_xlat8 = max(u_xlat8, float4(0.0, 0.0, 0.0, 0.0));
        u_xlat8 = u_xlat8 * u_xlat8;
        u_xlat8 = u_xlat8 * u_xlat8;
        u_xlat0.x = dot(u_xlat2.xyz, u_xlat0.xyz);
        u_xlat0.y = dot(u_xlat7.xyz, u_xlat3.xyz);
        u_xlat0.z = dot(u_xlat1.xzw, u_xlat5.xyz);
        u_xlat0.w = dot(u_xlat4.xyz, u_xlat6.xyz);
        u_xlat0.x = dot(u_xlat8, u_xlat0);
        u_xlat0.x = u_xlat0.x * 42.0;
    } else {
        u_xlat0.x = 1.0;
    }
    u_xlati11 = nAmostras + int(0xFFFFFFFFu);
    u_xlat11 = float(u_xlati11);
    u_xlat0.x = u_xlat0.x * u.strength;
    u_xlat0.x = u_xlat0.x * 90.0 + u.direction;
    u_xlat0.x = u_xlat0.x * 0.0174532942;
    u_xlat1.x = sin((-u_xlat0.x));
    u_xlat1.y = cos(u_xlat0.x);
    u_xlat0.xz = u_xlat1.xy * float2(float2(u.radius, u.radius));
    u_xlat33 = u.radius * u.dispersion;
    u_xlat1.x = float(0.0);
    u_xlat1.y = float(0.0);
    u_xlat1.z = float(0.0);
    u_xlat1.w = float(0.0);
    u_xlat2.x = float(0.0);
    for(int u_xlati_loop_1 = int(0) ; u_xlati_loop_1<nAmostras ; u_xlati_loop_1++)
    {
        u_xlat24 = float(u_xlati_loop_1);
        u_xlat24 = u_xlat24 / u_xlat11;
        u_xlat24 = u_xlat24 + -0.5;
        u_xlat35 = -abs(u_xlat24) * 2.0 + 1.0;
        u_xlat3.xy = u_xlat0.xz * float2(u_xlat24) + in.vs_TEXCOORD0.xy;
        u_xlat3 = camadaRt.sample(__nv_smp, u_xlat3.xy);
        u_xlat3 = float4(u_xlat35) * u_xlat3;
        u_xlat2.x = u_xlat35 + u_xlat2.x;
        u_xlat24 = (-u_xlat35) + 1.0;
        u_xlat4.z = u_xlat24 * 3.0 + -1.5;
        u_xlat4.y = -abs(u_xlat4.z) + 1.0;
        u_xlat4.x = (-u_xlat4.z);
        u_xlat4.xyz = u_xlat4.xyz;
        u_xlat4.xyz = clamp(u_xlat4.xyz, 0.0, 1.0);
        u_xlat4.xyz = u_xlat3.xyz * u_xlat4.xyz;
        u_xlat4.xyz = u_xlat4.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat3.xyz);
        u_xlat3.xyz = float3(u_xlat33) * u_xlat4.xyz + u_xlat3.xyz;
        u_xlat1 = u_xlat1 + u_xlat3;
    }
    u_xlat0 = u_xlat1 / u_xlat2.xxxx;
    return u_xlat0;
}

fragment float4 fx_node_directional_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant node_directional_blurParams&  u    [[buffer(1)]],
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
        // O RT da camada está de pé: o UV do Node é o da tela, nos dois casos. `Blend One Zero`: a saída como está
        // (o alvo sRGB de 8 bits prende, como o do Node).
        __nv_out = directionalBlur(in.acScreenNorm);
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
