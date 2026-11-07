// ---------------------------------------------------------------------------
// Coordenadas polares (Node)
// origem : assets/effects/node-polar-coordinates.xml
// id     : nova.effect.node-polar-coordinates
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct node_polar_coordinatesParams {
    int conversionType;
    float interpolation;
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
float4 polarCoordinates(float2 in.vs_TEXCOORD0) {
    // O `_viewport_ratio` do `RCEffect::Render` é o `eng.acProporcaoDoNode`, feito na CPU como o Node faz. O Enum chega
    // como o inteiro do Node (0 ou 1), o Float por `SetGlobalFloat`.
    float2 _viewport_ratio = eng.acProporcaoDoNode;
    int _conversion_type = u.conversionType;
    float _interpolation = u.interpolation;
    float4 u_xlat0;
    float4 u_xlat1;
    bool2 u_xlatb1;
    float2 u_xlat2;
    float2 u_xlat6;
    bool u_xlatb6;
    bool2 u_xlatb12;
    float u_xlat13;
    float u_xlat18;
    bool u_xlatb18;
    bool u_xlatb19;
    u_xlat0.xy = float2(_viewport_ratio.y, _viewport_ratio.x) * float2(0.5, 0.5);
    u_xlat6.xy = in.vs_TEXCOORD0.yx * float2(_viewport_ratio.y, _viewport_ratio.x) + (-u_xlat0.xy);
    u_xlat18 = dot(u_xlat6.xy, u_xlat6.xy);
    u_xlat18 = sqrt(u_xlat18);
    u_xlat0.x = u_xlat18 / u_xlat0.x;
    u_xlat1.y = (-u_xlat0.x) + 1.0;
    u_xlat0.x = min(abs(u_xlat6.y), abs(u_xlat6.x));
    u_xlat18 = max(abs(u_xlat6.y), abs(u_xlat6.x));
    u_xlat18 = float(1.0) / u_xlat18;
    u_xlat0.x = u_xlat18 * u_xlat0.x;
    u_xlat18 = u_xlat0.x * u_xlat0.x;
    u_xlat13 = u_xlat18 * 0.0208350997 + -0.0851330012;
    u_xlat13 = u_xlat18 * u_xlat13 + 0.180141002;
    u_xlat13 = u_xlat18 * u_xlat13 + -0.330299497;
    u_xlat18 = u_xlat18 * u_xlat13 + 0.999866009;
    u_xlat13 = u_xlat18 * u_xlat0.x;
    u_xlatb19 = abs(u_xlat6.y)<abs(u_xlat6.x);
    u_xlat13 = u_xlat13 * -2.0 + 1.57079637;
    u_xlat13 = u_xlatb19 ? u_xlat13 : float(0.0);
    u_xlat0.x = u_xlat0.x * u_xlat18 + u_xlat13;
    u_xlatb18 = u_xlat6.y<(-u_xlat6.y);
    u_xlat18 = u_xlatb18 ? -3.14159274 : float(0.0);
    u_xlat0.x = u_xlat18 + u_xlat0.x;
    u_xlat18 = min(u_xlat6.y, u_xlat6.x);
    u_xlat6.x = max(u_xlat6.y, u_xlat6.x);
    u_xlatb12.x = u_xlat18<(-u_xlat18);
    u_xlatb6 = u_xlat6.x>=(-u_xlat6.x);
    u_xlatb6 = u_xlatb6 && u_xlatb12.x;
    u_xlat0.x = (u_xlatb6) ? (-u_xlat0.x) : u_xlat0.x;
    u_xlat0.xy = u_xlat0.xx + float2(-1.57079637, 4.71238899);
    u_xlatb12.x = u_xlat0.x<0.0;
    u_xlat0.x = (u_xlatb12.x) ? u_xlat0.y : u_xlat0.x;
    u_xlat1.x = u_xlat0.x * 0.159154937;
    u_xlat0.xy = in.vs_TEXCOORD0.xy * float2(6.28318548, -1.0) + float2(-3.14159274, 1.0);
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat2.x = cos(u_xlat0.x);
    u_xlat0.x = sin(u_xlat0.x);
    u_xlat2.x = u_xlat0.y * u_xlat2.x;
    u_xlat2.y = u_xlat0.x * u_xlat0.y;
    u_xlat0.xy = u_xlat2.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
    u_xlat0.xy = (_conversion_type != 0) ? u_xlat0.xy : u_xlat1.xy;
    u_xlat0.xy = u_xlat0.xy + (-in.vs_TEXCOORD0.xy);
    u_xlat0.xy = float2(float2(_interpolation, _interpolation)) * u_xlat0.xy + in.vs_TEXCOORD0.xy;
    u_xlatb12.xy = lessThan(u_xlat0.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb1.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.xyxx).xy;
    u_xlatb12.x = u_xlatb12.x || u_xlatb1.x;
    u_xlatb12.x = u_xlatb12.y || u_xlatb12.x;
    u_xlatb12.x = u_xlatb1.y || u_xlatb12.x;
    u_xlat1 = camadaRt.sample(__nv_smp, u_xlat0.xy);
    u_xlat0.x = (u_xlatb12.x) ? 0.0 : 1.0;
    u_xlat1.w = u_xlat0.x * u_xlat1.w;
    return u_xlat1;
}

fragment float4 fx_node_polar_coordinates(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant node_polar_coordinatesParams&  u    [[buffer(1)]],
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
        // `Blend One Zero`: a saída como está (o alvo sRGB de 8 bits prende, como o do Node).
        __nv_out = polarCoordinates(in.acScreenNorm);
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
