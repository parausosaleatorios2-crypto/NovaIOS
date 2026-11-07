// ---------------------------------------------------------------------------
// Espelho (Node)
// origem : assets/effects/node-mirror.xml
// id     : nova.effect.node-mirror
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct node_mirrorParams {
    float2 reflectionCenter;
    float reflectionAngle;
    int invert;
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
float4 mirror(float2 in.vs_TEXCOORD0, float2 _reflection_center) {
    // [_reflection_center]: no UV do Node (ver o `main`). O `_viewport_ratio` do `RCEffect::Render` é o
    // `eng.acProporcaoDoNode`, feito na CPU como o Node faz. O Bool chega como o `SetGlobalInt` do Node: 0 ou 1.
    float _reflection_angle = u.reflectionAngle;
    int _invert = u.invert ? 1 : 0;
    float2 _viewport_ratio = eng.acProporcaoDoNode;
    float4 u_xlat0;
    float4 u_xlat1;
    bool2 u_xlatb1;
    float4 u_xlat2;
    float2 u_xlat12;
    bool2 u_xlatb12;
    float2 u_xlat13;
    float u_xlat18;
    bool u_xlatb18;
    u_xlat0.xy = in.vs_TEXCOORD0.xy + float2(-0.5, -0.5);
    u_xlat12.xy = _reflection_center.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat13.xy = float2(float2(_reflection_angle, _reflection_angle)) * float2(0.0174532942, 360.0);
    u_xlat2.x = cos(u_xlat13.x);
    u_xlat13.x = sin((-u_xlat13.x));
    u_xlat2.xy = u_xlat2.xx * float2(-0.5, 0.5);
    u_xlat2.zw = u_xlat13.xx * float2(-0.5, 0.5);
    u_xlat2 = u_xlat12.xyxy * float4(_viewport_ratio.x, _viewport_ratio.y, _viewport_ratio.x, _viewport_ratio.y) + u_xlat2.xzyw;
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y) + (-u_xlat2.xy);
    u_xlat12.xy = (-u_xlat2.xy) + u_xlat2.zw;
    u_xlat13.x = dot(u_xlat0.xy, u_xlat12.xy);
    u_xlat2.x = dot(u_xlat12.xy, u_xlat12.xy);
    u_xlat13.x = u_xlat13.x / u_xlat2.x;
    u_xlat0.xy = (-u_xlat13.xx) * u_xlat12.xy + u_xlat0.xy;
    u_xlatb12.x = u_xlat13.y>=(-u_xlat13.y);
    u_xlat12.xy = (u_xlatb12.x) ? float2(360.0, 0.00277777785) : float2(-360.0, -0.00277777785);
    u_xlat18 = u_xlat12.y * _reflection_angle;
    u_xlat18 = fract(u_xlat18);
    u_xlat12.x = u_xlat18 * u_xlat12.x;
    u_xlatb18 = 90.0<abs(u_xlat12.x);
    u_xlatb12.x = abs(u_xlat12.x)<270.0;
    u_xlatb12.x = u_xlatb12.x && u_xlatb18;
    u_xlat13.xy = (int(_invert) != 0) ? float2(-1.0, 1.0) : float2(1.0, -1.0);
    u_xlat12.x = (u_xlatb12.x) ? u_xlat13.y : u_xlat13.x;
    u_xlatb18 = abs(u_xlat0.y)<9.99999975e-05;
    u_xlat13.xy = u_xlat12.xx * (-u_xlat0.yx);
    u_xlat12.x = (u_xlatb18) ? u_xlat13.y : u_xlat13.x;
    u_xlat12.x = u_xlat12.x * 100000.0;
    u_xlat12.x = clamp(u_xlat12.x, 0.0, 1.0);
    u_xlat0.xy = u_xlat0.xy * u_xlat12.xx;
    u_xlat0.xy = (-u_xlat0.xy) * float2(2.0, 2.0) + u_xlat1.xy;
    u_xlat0.xy = u_xlat0.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
    u_xlatb12.xy = lessThan(u_xlat0.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb1.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.xyxx).xy;
    u_xlatb12.x = u_xlatb12.x || u_xlatb1.x;
    u_xlatb12.x = u_xlatb12.y || u_xlatb12.x;
    u_xlatb12.x = u_xlatb1.y || u_xlatb12.x;
    u_xlat1 = camadaRt.sample(__nv_smp, u_xlat0.xy);
    u_xlat0.x = (u_xlatb12.x) ? 0.0 : 1.0;
    u_xlat0 = u_xlat0.xxxx * u_xlat1;
    return u_xlat0;
}

fragment float4 fx_node_mirror(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant node_mirrorParams&  u    [[buffer(1)]],
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
        // O RT da camada está de pé: o UV do Node é o da tela, nos dois casos. O Centro chega na tela de pé (o UV do
        // Node) quando a entrada é de pé; no buffer de camada, no Y para baixo do buffer: vira 1 − Y.
        // `Blend One Zero`: a saída como está (o alvo sRGB de 8 bits prende, como o do Node).
        float2 centro = eng.acEntradaDePe == 1 ? u.reflectionCenter : float2(u.reflectionCenter.x, 1.0 - u.reflectionCenter.y);
        __nv_out = mirror(in.acScreenNorm, centro);
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
