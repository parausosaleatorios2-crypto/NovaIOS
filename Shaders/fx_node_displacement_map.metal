// ---------------------------------------------------------------------------
// Mapa de deslocamento (Node)
// origem : assets/effects/node-displacement-map.xml
// id     : nova.effect.node-displacement-map
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct node_displacement_mapParams {
    float maxHorizontal;
    float maxVertical;
    int keepEdge;
    int fromCenter;
    int useForHorizontal;
    int useForVertical;
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
// buffer de camada (`eng.acEntradaDePe` = 0, a linha 0 é o topo) a linha é espelhada. Lê a entrada e o mapa para os RTs de
// pé e o RT de pé para a saída — os espelhos se desfazem, e a conta do meio é a da tela.
float4 texelDePe(sampler2D img) {
    int2 T = int2(int(img.get_width()), int(img.get_height()));
    int2 p = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
    if (eng.acEntradaDePe != 1) p.y = T.y - 1 - p.y;
    return img.read(uint2(p), uint(0));
}

// O programa do Node, conta por conta (o `_displacement_source` é o `mapaRt`, o `_SourceTex` é o `camadaRt`).
// [uvNode]: o UV do Node (cresce para cima) — os RTs estão de pé, é o da tela.
float4 deslocar(float2 uvNode) {
    float4 u_xlat0;
    bool u_xlatb1;
    float2 u_xlat2;
    bool2 u_xlatb2;
    float4 u_xlat3;
    float4 u_xlat4;
    float u_xlat6;
    float u_xlat7;
    bool2 u_xlatb7;
    float2 u_xlat12;
    bool2 u_xlatb12;
    float u_xlat13;
    bool u_xlatb13;
    float2 u_xlat14;
    bool2 u_xlatb14;
    float u_xlat18;
    float u_xlat19;
    u_xlat0 = mapaRt.sample(__nv_smp, in.acScreenNorm).yzwx;
    u_xlatb1 = u.keepEdge;
    if (u.useForHorizontal == 0) {
        u_xlat2.x = u_xlat0.w;
    } else {
        u_xlatb7.x = u.useForHorizontal == 1;
        if (u_xlatb7.x) {
            u_xlat2.x = u_xlat0.x;
        } else {
            u_xlatb7.x = u.useForHorizontal == 2;
            if (u_xlatb7.x) {
                u_xlat2.x = u_xlat0.y;
            } else {
                u_xlatb7.x = u.useForHorizontal == 3;
                if (u_xlatb7.x) {
                    u_xlat2.x = u_xlat0.z;
                } else {
                    u_xlatb7.x = u.useForHorizontal == 4;
                    if (u_xlatb7.x) {
                        u_xlat2.x = dot(u_xlat0.wxy, float3(0.300000012, 0.589999974, 0.109999999));
                    } else {
                        u_xlatb7.x = u_xlat0.x >= u_xlat0.y;
                        u_xlat7 = u_xlatb7.x ? 1.0 : float(0.0);
                        u_xlat3.xy = u_xlat0.yx;
                        u_xlat3.z = float(-1.0);
                        u_xlat3.w = float(0.666666687);
                        u_xlat4.xy = u_xlat0.xy + (-u_xlat3.xy);
                        u_xlat4.z = float(1.0);
                        u_xlat4.w = float(-1.0);
                        u_xlat3 = float4(u_xlat7) * u_xlat4 + u_xlat3;
                        u_xlatb7.x = u_xlat0.w >= u_xlat3.x;
                        u_xlat7 = u_xlatb7.x ? 1.0 : float(0.0);
                        u_xlat4.xyz = u_xlat3.xyw;
                        u_xlat4.w = u_xlat0.w;
                        u_xlat3.xyw = u_xlat4.wyx;
                        u_xlat3 = (-u_xlat4) + u_xlat3;
                        u_xlat3 = float4(u_xlat7) * u_xlat3 + u_xlat4;
                        u_xlat7 = min(u_xlat3.y, u_xlat3.w);
                        u_xlat7 = (-u_xlat7) + u_xlat3.x;
                        u_xlat13 = (-u_xlat3.y) + u_xlat3.w;
                        u_xlat19 = u_xlat7 * 6.0 + 1.00000001e-10;
                        u_xlat13 = u_xlat13 / u_xlat19;
                        u_xlat13 = u_xlat13 + u_xlat3.z;
                        u_xlatb14.xy = equal(int4(u.useForHorizontal), int4(5, 6, 5, 6)).xy;
                        u_xlat19 = u_xlat3.x + 1.00000001e-10;
                        u_xlat7 = u_xlat7 / u_xlat19;
                        u_xlat7 = (u_xlatb14.y) ? u_xlat3.x : u_xlat7;
                        u_xlat2.x = (u_xlatb14.x) ? abs(u_xlat13) : u_xlat7;
                    }
                }
            }
        }
    }
    u_xlatb7.x = u.fromCenter;
    if (u.useForVertical == 0) {
        u_xlat2.y = u_xlat0.w;
    } else {
        u_xlatb13 = u.useForVertical == 1;
        if (u_xlatb13) {
            u_xlat2.y = u_xlat0.x;
        } else {
            u_xlatb13 = u.useForVertical == 2;
            if (u_xlatb13) {
                u_xlat2.y = u_xlat0.y;
            } else {
                u_xlatb13 = u.useForVertical == 3;
                if (u_xlatb13) {
                    u_xlat2.y = u_xlat0.z;
                } else {
                    u_xlatb13 = u.useForVertical == 4;
                    if (u_xlatb13) {
                        u_xlat2.y = dot(u_xlat0.wxy, float3(0.300000012, 0.589999974, 0.109999999));
                    } else {
                        u_xlatb13 = u_xlat0.x >= u_xlat0.y;
                        u_xlat13 = u_xlatb13 ? 1.0 : float(0.0);
                        u_xlat3.xy = u_xlat0.yx;
                        u_xlat3.z = float(-1.0);
                        u_xlat3.w = float(0.666666687);
                        u_xlat4.xy = u_xlat0.xy + (-u_xlat3.xy);
                        u_xlat4.z = float(1.0);
                        u_xlat4.w = float(-1.0);
                        u_xlat3 = float4(u_xlat13) * u_xlat4 + u_xlat3;
                        u_xlatb13 = u_xlat0.w >= u_xlat3.x;
                        u_xlat13 = u_xlatb13 ? 1.0 : float(0.0);
                        u_xlat0.xyz = u_xlat3.xyw;
                        u_xlat3.xyw = u_xlat0.wyx;
                        u_xlat3 = (-u_xlat0) + u_xlat3;
                        u_xlat0 = float4(u_xlat13) * u_xlat3 + u_xlat0;
                        u_xlat13 = min(u_xlat0.y, u_xlat0.w);
                        u_xlat13 = u_xlat0.x + (-u_xlat13);
                        u_xlat6 = (-u_xlat0.y) + u_xlat0.w;
                        u_xlat18 = u_xlat13 * 6.0 + 1.00000001e-10;
                        u_xlat6 = u_xlat6 / u_xlat18;
                        u_xlat6 = u_xlat6 + u_xlat0.z;
                        u_xlatb12.xy = equal(int4(u.useForVertical), int4(5, 6, 5, 6)).xy;
                        u_xlat19 = u_xlat0.x + 1.00000001e-10;
                        u_xlat13 = u_xlat13 / u_xlat19;
                        u_xlat0.x = (u_xlatb12.y) ? u_xlat0.x : u_xlat13;
                        u_xlat2.y = (u_xlatb12.x) ? abs(u_xlat6) : u_xlat0.x;
                    }
                }
            }
        }
    }
    u_xlat0.xy = u_xlat2.xy + float2(-0.5, -0.5);
    u_xlat0.xy = (u_xlatb7.x) ? u_xlat2.xy : u_xlat0.xy;
    u_xlat0.xy = float2(u.maxHorizontal, u.maxVertical) * u_xlat0.xy + uvNode;
    u_xlat12.xy = u_xlat0.xy + float2(-0.5, -0.5);
    u_xlat12.xy = u_xlat12.xy * float2(1.00100005, 1.00100005) + float2(0.5, 0.5);
    u_xlatb7.xy = lessThan(u_xlat12.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb2.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat12.xyxx).xy;
    u_xlat14.xy = fract(u_xlat12.xy);
    u_xlat14.xy = (-u_xlat14.xy) + float2(1.0, 1.0);
    u_xlat2.x = (u_xlatb2.x) ? u_xlat14.x : u_xlat12.x;
    u_xlat2.y = (u_xlatb2.y) ? u_xlat14.y : u_xlat12.y;
    {
        float2 hlslcc_movcTemp = u_xlat12;
        hlslcc_movcTemp.x = (u_xlatb7.x) ? (-u_xlat12.x) : u_xlat2.x;
        hlslcc_movcTemp.y = (u_xlatb7.y) ? (-u_xlat12.y) : u_xlat2.y;
        u_xlat12 = hlslcc_movcTemp;
    }
    u_xlat12.xy = u_xlat12.xy + float2(-0.5, -0.5);
    u_xlat12.xy = u_xlat12.xy * float2(0.999000967, 0.999000967) + float2(0.5, 0.5);
    u_xlat0.xy = (bool(u_xlatb1)) ? u_xlat12.xy : u_xlat0.xy;
    return camadaRt.sample(__nv_smp, u_xlat0.xy);
}

fragment float4 fx_node_displacement_map(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant node_displacement_mapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> mapImg [[texture(1)]],
    texture2d<float> camadaRt [[texture(2)]],
    texture2d<float> mapaRt [[texture(3)]],
    texture2d<float> saidaRt [[texture(4)]])
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
        // O mapa, igual (o RT da camada escolhida; sem nenhuma, a própria camada).
        float4 m = texelDePe(mapImg);
        __nv_out = float4(linear(m.rgb) * m.a, m.a);
        return __nv_out;
    }
    if (eng.acPass == 2) {
        // Os RTs estão de pé: o UV do Node é o da tela, nos dois casos.
        __nv_out = deslocar(in.acScreenNorm);
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
