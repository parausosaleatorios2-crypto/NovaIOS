// ---------------------------------------------------------------------------
// Desfoque radial (Node)
// origem : assets/effects/node-ray-blur.xml
// id     : nova.effect.node-ray-blur
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct node_ray_blurParams {
    float amount;
    float2 startPos;
    float brightness;
    float samples;
    float dispersion;
    int turbulence;
    float evolution;
    float2 turbulenceScale;
    float strength;
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
float4 rayBlur(float2 in.vs_TEXCOORD0, float2 inicio) {
    // [inicio]: o `_start_pos` do Node, no UV dele (ver o `main`). As duas trocas do Nova: o `_samples` é o
    // inteiro do Node (o slider vira float no uniform; o `int()` corta para o zero, o mesmo `fcvtzs` do
    // `PFloat::SetShader`), e o `_enable_turbulence`, o 0/1 do `PBool`.
    int nAmostras = int(u.samples);
    int ligaTurbulencia = u.turbulence ? 1 : 0;
    float4 u_xlat0;
    float4 u_xlat1;
    float4 u_xlat2;
    bool2 u_xlatb2;
    float4 u_xlat3;
    float4 u_xlat4;
    float4 u_xlat5;
    float4 u_xlat6;
    bool u_xlatb6;
    float3 u_xlat7;
    bool u_xlatb7;
    float4 u_xlat8;
    float u_xlat16;
    int u_xlati16;
    float2 u_xlat18;
    bool u_xlatb18;
    float2 u_xlat19;
    bool u_xlatb19;
    float2 u_xlat20;
    int u_xlati23;
    bool u_xlatb27;
    int u_xlati32;

    u_xlat0.xy = (-in.vs_TEXCOORD0.xy) + inicio.xy;
    u_xlatb18 = 0<ligaTurbulencia;
    if(u_xlatb18){
        u_xlat18.xy = in.vs_TEXCOORD0.xy + float2(-0.5, -0.5);
        u_xlat1.xy = u_xlat18.xy * u.turbulenceScale.xy + float2(0.5, 0.5);
        u_xlat1.z = u.evolution;
        u_xlat18.x = dot(u_xlat1.xz, float2(0.366025418, 0.366025418));
        u_xlat18.xy = u_xlat18.xx + u_xlat1.xz;
        u_xlat18.xy = floor(u_xlat18.xy);
        u_xlat1.xw = (-u_xlat18.xy) + u_xlat1.xz;
        u_xlat2.x = dot(u_xlat18.xy, float2(0.211324871, 0.211324871));
        u_xlat1.xw = u_xlat1.xw + u_xlat2.xx;
        u_xlatb2.x = u_xlat1.w<u_xlat1.x;
        u_xlat3 = u_xlat1.xwxw + float4(0.211324871, 0.211324871, -0.577350259, -0.577350259);
        u_xlat2 = (u_xlatb2.x) ? float4(0.0, 1.0, -1.0, -0.0) : float4(1.0, 0.0, -0.0, -1.0);
        u_xlat3.xy = u_xlat2.zw + u_xlat3.xy;
        u_xlat4.xy = u_xlat18.xy * float2(0.00346020772, 0.00346020772);
        u_xlat4.xy = floor(u_xlat4.xy);
        u_xlat18.xy = (-u_xlat4.xy) * float2(289.0, 289.0) + u_xlat18.xy;
        u_xlat4.x = float(0.0);
        u_xlat4.z = float(1.0);
        u_xlat4.y = u_xlat2.x;
        u_xlat4.xyz = u_xlat18.yyy + u_xlat4.xyz;
        u_xlat5.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat4.xyz = u_xlat5.xyz * float3(34.0, 34.0, 34.0) + u_xlat4.xyz;
        u_xlat5.xyz = u_xlat4.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat5.xyz = floor(u_xlat5.xyz);
        u_xlat4.xyz = (-u_xlat5.xyz) * float3(289.0, 289.0, 289.0) + u_xlat4.xyz;
        u_xlat4.xyz = u_xlat18.xxx + u_xlat4.xyz;
        u_xlat2.x = float(0.0);
        u_xlat2.z = float(1.0);
        u_xlat2.xyz = u_xlat2.xyz + u_xlat4.xyz;
        u_xlat4.xyz = u_xlat2.xyz * u_xlat2.xyz;
        u_xlat2.xyz = u_xlat4.xyz * float3(34.0, 34.0, 34.0) + u_xlat2.xyz;
        u_xlat4.xyz = u_xlat2.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat4.xyz = floor(u_xlat4.xyz);
        u_xlat2.xyz = (-u_xlat4.xyz) * float3(289.0, 289.0, 289.0) + u_xlat2.xyz;
        u_xlat4.x = dot(u_xlat1.xw, u_xlat1.xw);
        u_xlat4.y = dot(u_xlat3.xy, u_xlat3.xy);
        u_xlat4.z = dot(u_xlat3.zw, u_xlat3.zw);
        u_xlat4.xyz = (-u_xlat4.xyz) + float3(0.5, 0.5, 0.5);
        u_xlat4.xyz = max(u_xlat4.xyz, float3(0.0, 0.0, 0.0));
        u_xlat4.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat4.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat2.xyz = u_xlat2.xyz * float3(0.024390243, 0.024390243, 0.024390243);
        u_xlat2.xyz = fract(u_xlat2.xyz);
        u_xlat5.xyz = u_xlat2.xyz * float3(2.0, 2.0, 2.0) + float3(-1.0, -1.0, -1.0);
        u_xlat6.xyz = abs(u_xlat5.xyz) + float3(-0.5, -0.5, -0.5);
        u_xlat2.xyz = u_xlat2.xyz * float3(2.0, 2.0, 2.0) + float3(-0.5, -0.5, -0.5);
        u_xlat2.xyz = floor(u_xlat2.xyz);
        u_xlat2.xyz = (-u_xlat2.xyz) + u_xlat5.xyz;
        u_xlat5.xyz = u_xlat6.xyz * u_xlat6.xyz;
        u_xlat5.xyz = u_xlat2.xyz * u_xlat2.xyz + u_xlat5.xyz;
        u_xlat5.xyz = (-u_xlat5.xyz) * float3(0.853734732, 0.853734732, 0.853734732) + float3(1.79284286, 1.79284286, 1.79284286);
        u_xlat4.xyz = u_xlat4.xyz * u_xlat5.xyz;
        u_xlat18.x = u_xlat1.w * u_xlat6.x;
        u_xlat5.x = u_xlat2.x * u_xlat1.x + u_xlat18.x;
        u_xlat18.xy = u_xlat3.yw * u_xlat6.yz;
        u_xlat5.yz = u_xlat2.yz * u_xlat3.xz + u_xlat18.xy;
        u_xlat18.x = dot(u_xlat4.xyz, u_xlat5.xyz);
        u_xlat18.x = u_xlat18.x * u.strength;
        u_xlat0.x = u_xlat18.x * 130.0 + u_xlat0.x;
        u_xlat18.x = dot(u_xlat1.yz, float2(0.366025418, 0.366025418));
        u_xlat18.xy = u_xlat18.xx + u_xlat1.yz;
        u_xlat18.xy = floor(u_xlat18.xy);
        u_xlat1.xy = (-u_xlat18.xy) + u_xlat1.yz;
        u_xlat19.x = dot(u_xlat18.xy, float2(0.211324871, 0.211324871));
        u_xlat1.xy = u_xlat19.xx + u_xlat1.xy;
        u_xlatb19 = u_xlat1.y<u_xlat1.x;
        u_xlat2 = u_xlat1.xyxy + float4(0.211324871, 0.211324871, -0.577350259, -0.577350259);
        u_xlat3 = (bool(u_xlatb19)) ? float4(0.0, 1.0, -1.0, -0.0) : float4(1.0, 0.0, -0.0, -1.0);
        u_xlat2.xy = u_xlat2.xy + u_xlat3.zw;
        u_xlat19.xy = u_xlat18.xy * float2(0.00346020772, 0.00346020772);
        u_xlat19.xy = floor(u_xlat19.xy);
        u_xlat18.xy = (-u_xlat19.xy) * float2(289.0, 289.0) + u_xlat18.xy;
        u_xlat4.x = float(0.0);
        u_xlat4.z = float(1.0);
        u_xlat4.y = u_xlat3.x;
        u_xlat4.xyz = u_xlat18.yyy + u_xlat4.xyz;
        u_xlat5.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat4.xyz = u_xlat5.xyz * float3(34.0, 34.0, 34.0) + u_xlat4.xyz;
        u_xlat5.xyz = u_xlat4.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat5.xyz = floor(u_xlat5.xyz);
        u_xlat4.xyz = (-u_xlat5.xyz) * float3(289.0, 289.0, 289.0) + u_xlat4.xyz;
        u_xlat4.xyz = u_xlat18.xxx + u_xlat4.xyz;
        u_xlat3.x = float(0.0);
        u_xlat3.z = float(1.0);
        u_xlat3.xyz = u_xlat3.xyz + u_xlat4.xyz;
        u_xlat4.xyz = u_xlat3.xyz * u_xlat3.xyz;
        u_xlat3.xyz = u_xlat4.xyz * float3(34.0, 34.0, 34.0) + u_xlat3.xyz;
        u_xlat4.xyz = u_xlat3.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat4.xyz = floor(u_xlat4.xyz);
        u_xlat3.xyz = (-u_xlat4.xyz) * float3(289.0, 289.0, 289.0) + u_xlat3.xyz;
        u_xlat4.x = dot(u_xlat1.xy, u_xlat1.xy);
        u_xlat4.y = dot(u_xlat2.xy, u_xlat2.xy);
        u_xlat4.z = dot(u_xlat2.zw, u_xlat2.zw);
        u_xlat4.xyz = (-u_xlat4.xyz) + float3(0.5, 0.5, 0.5);
        u_xlat4.xyz = max(u_xlat4.xyz, float3(0.0, 0.0, 0.0));
        u_xlat4.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat4.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat3.xyz = u_xlat3.xyz * float3(0.024390243, 0.024390243, 0.024390243);
        u_xlat3.xyz = fract(u_xlat3.xyz);
        u_xlat5.xyz = u_xlat3.xyz * float3(2.0, 2.0, 2.0) + float3(-1.0, -1.0, -1.0);
        u_xlat6.xyz = abs(u_xlat5.xyz) + float3(-0.5, -0.5, -0.5);
        u_xlat3.xyz = u_xlat3.xyz * float3(2.0, 2.0, 2.0) + float3(-0.5, -0.5, -0.5);
        u_xlat3.xyz = floor(u_xlat3.xyz);
        u_xlat3.xyz = (-u_xlat3.xyz) + u_xlat5.xyz;
        u_xlat5.xyz = u_xlat6.xyz * u_xlat6.xyz;
        u_xlat5.xyz = u_xlat3.xyz * u_xlat3.xyz + u_xlat5.xyz;
        u_xlat5.xyz = (-u_xlat5.xyz) * float3(0.853734732, 0.853734732, 0.853734732) + float3(1.79284286, 1.79284286, 1.79284286);
        u_xlat4.xyz = u_xlat4.xyz * u_xlat5.xyz;
        u_xlat18.x = u_xlat1.y * u_xlat6.x;
        u_xlat1.x = u_xlat3.x * u_xlat1.x + u_xlat18.x;
        u_xlat18.xy = u_xlat2.yw * u_xlat6.yz;
        u_xlat1.yz = u_xlat3.yz * u_xlat2.xz + u_xlat18.xy;
        u_xlat18.x = dot(u_xlat4.xyz, u_xlat1.xyz);
        u_xlat18.x = u_xlat18.x * u.strength;
        u_xlat0.y = u_xlat18.x * 130.0 + u_xlat0.y;
    }
    u_xlat18.x = float(nAmostras);
    u_xlat0.xy = u_xlat0.xy / u_xlat18.xx;
    u_xlat1 = camadaRt.sample(__nv_smp, in.vs_TEXCOORD0.xy);
    u_xlat2.xy = u_xlat0.xy * float2(u.amount) + in.vs_TEXCOORD0.xy;
    u_xlatb27 = nAmostras==2;
    u_xlat3 = u_xlat1 * float4(float4(u.brightness, u.brightness, u.brightness, u.brightness));
    u_xlat3 = (bool(u_xlatb27)) ? u_xlat3 : u_xlat1;
    u_xlat20.xy = (-float2(u.amount)) + float2(1.0, 2.0);
    u_xlat4 = u_xlat3;
    u_xlat5.xy = u_xlat2.xy;
    u_xlati23 = nAmostras;
    for(int u_xlati_loop_1 = 1 ; u_xlati_loop_1<u_xlati23 ; u_xlati_loop_1++)
    {
        u_xlat6 = camadaRt.sample(__nv_smp, u_xlat5.xy);
        u_xlat7.x = float(u_xlati_loop_1);
        u_xlati16 = u_xlati23 + int(0xFFFFFFFFu);
        u_xlat16 = float(u_xlati16);
        u_xlat7.x = u_xlat7.x / u_xlat16;
        u_xlat7.z = u_xlat7.x * 3.0 + -1.5;
        u_xlat7.y = -abs(u_xlat7.z) + 1.0;
        u_xlat7.x = (-u_xlat7.z);
        u_xlat7.xyz = u_xlat7.xyz;
        u_xlat7.xyz = clamp(u_xlat7.xyz, 0.0, 1.0);
        u_xlat7.xyz = u_xlat6.xyz * u_xlat7.xyz;
        u_xlat7.xyz = u_xlat7.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat6.xyz);
        u_xlat6.xyz = float3(float3(u.dispersion, u.dispersion, u.dispersion)) * u_xlat7.xyz + u_xlat6.xyz;
        u_xlatb7 = u_xlati23==2;
        u_xlat8 = u_xlat6 * u_xlat20.xxxx + u_xlat4;
        u_xlat6 = u_xlat6 * float4(float4(u.brightness, u.brightness, u.brightness, u.brightness)) + u_xlat4;
        u_xlat4 = (bool(u_xlatb7)) ? u_xlat8 : u_xlat6;
        u_xlat5.xy = u_xlat0.xy * float2(u.amount) + u_xlat5.xy;
    }
    u_xlat2 = u_xlat4 / u_xlat20.yyyy;
    u_xlat3 = u_xlat4 / u_xlat18.xxxx;
    u_xlat0 = (bool(u_xlatb27)) ? u_xlat2 : u_xlat3;
    return u_xlat0;
}

fragment float4 fx_node_ray_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant node_ray_blurParams&  u    [[buffer(1)]],
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
        // O RT da camada está de pé: o UV do Node é o da tela, nos dois casos. A Posição inicial chega na tela de pé
        // (o UV do Node) quando a entrada é de pé; no buffer de camada, no Y para baixo do buffer: vira 1 − Y.
        // `Blend One Zero`: a saída como está (o alvo sRGB de 8 bits prende, como o do Node).
        float2 inicio = eng.acEntradaDePe == 1 ? u.startPos : float2(u.startPos.x, 1.0 - u.startPos.y);
        __nv_out = rayBlur(in.acScreenNorm, inicio);
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
