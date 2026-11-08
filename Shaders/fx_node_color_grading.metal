// ---------------------------------------------------------------------------
// Color Grading (Node)
// origem : assets/effects/node-color-grading.xml
// id     : nova.effect.node-color-grading
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct node_color_gradingParams {
    float4 gradacao;
    int editor;
    int toneMapping;
    float4 lift;
    float4 gamma;
    float4 gain;
    float temperature;
    float tint;
    float exposure;
    float4 colorFilter;
    float hueShift;
    float saturation;
    float contrast;
    int outputChannel;
    float rRed;
    float rGreen;
    float rBlue;
    float gRed;
    float gGreen;
    float gBlue;
    float bRed;
    float bGreen;
    float bBlue;
};

// --- funcoes auxiliares do efeito
// O `_PostExposure` do Node, calculado na CPU como lá (`GradacaoDoNode.posExposicao`).
uniform float gradacaoPosExposicao;

// k/255 pelo mais perto, montado nos bits do float (ver `node-manga.xml`).
static float oitoBits(float k) {
    uint n = uint(k);
    if (n == 0u) return 0.0;
    if (n == 255u) return 1.0;
    int j = 0;
    for (int i = 1; i < 8; i++) if (n >= (1u << uint(i))) j = i;
    int e = 31 - j;
    uint q = ((n << uint(e)) + 127u) / 255u;
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

static float3 bytesSrgb(float3 l) {
    return floor(srgb(l) * 255.0 + 0.5);
}

static float4 texelDePe(sampler2D img) {
    int2 T = int2(int(img.get_width()), int(img.get_height()));
    int2 p = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
    if (eng.acEntradaDePe != 1) p.y = T.y - 1 - p.y;
    return img.read(uint2(p), uint(0));
}

// `NodeVideo/RenderCommand/color_grading`, conta por conta (o `_SourceTex` é o `camadaRt`, o `_Lut3D` a `u.gradacao`).
// `_lut_space` = 0 (a LUT interna, em LogC), `_Lut3D_Params` = (1/33, 32), `_blend` = 1, sem a máscara interna.
static float4 colorGrading(float2 in.vs_TEXCOORD0) {
    const float _blend = 1.0;
    const float2 _Lut3D_Params = float2(1.0 / 33.0, 32.0);
    float _PostExposure = gradacaoPosExposicao;
    float4 u_xlat0;
    float4 u_xlat1;
    float4 u_xlat2;
    float u_xlat20;
    u_xlat0 = camadaRt.sample(__nv_smp, in.vs_TEXCOORD0.xy);
    u_xlat2.xyz = u_xlat0.xyz * float3(5.55555582, 5.55555582, 5.55555582) + float3(0.0479959995, 0.0479959995, 0.0479959995);
    u_xlat2.xyz = log2(u_xlat2.xyz);
    u_xlat2.yzw = u_xlat2.xyz * float3(0.0734997839, 0.0734997839, 0.0734997839) + float3(0.386036009, 0.386036009, 0.386036009);
    u_xlat2.yzw = clamp(u_xlat2.yzw, 0.0, 1.0);
    u_xlat2.x = u_xlat0.w * _PostExposure;
    u_xlat1 = u_xlat2.yzwx;
    u_xlat2.xyz = u_xlat1.xyz * _Lut3D_Params.yyy;
    u_xlat20 = _Lut3D_Params.x * 0.5;
    u_xlat2.xyz = u_xlat2.xyz * _Lut3D_Params.xxx + float3(u_xlat20);
    u_xlat2.xyz = gradacaoTex.sample(__nv_smp, u_xlat2.xyz).xyz;
    u_xlat1.xyz = u_xlat2.xyz;
    u_xlat1 = (-u_xlat0) + u_xlat1;
    u_xlat1 = float4(_blend) * u_xlat1 + u_xlat0;
    return u_xlat1;
}

fragment float4 fx_node_color_grading(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant node_color_gradingParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> camadaRt [[texture(1)]],
    texture2d<float> saidaRt [[texture(2)]],
    texture3d<float> gradacaoTex [[texture(3)]])
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
        float4 o = colorGrading(in.acScreenNorm);
        // O alvo de 8 bits prende a saída a 0..1 antes da mistura.
        o = clamp(o, 0.0, 1.0);
        // `Blend SrcAlpha Zero` no RT sRGB: a cor vezes o alfa (em linear) e o alfa vezes ele mesmo.
        __nv_out = float4(o.rgb * o.a, o.a * o.a);
        return __nv_out;
    }

    // Os bytes do RT de saída do Node, de volta à orientação da entrada e ao alfa reto do Nova.
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
    float a = oitoBits(ka);
    __nv_out = float4(srgb(min(linear(oitoBits3(kc)) / a, float3(1.0))), a);
    return __nv_out;
}
