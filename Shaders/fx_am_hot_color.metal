// ---------------------------------------------------------------------------
// Cor Quente
// origem : assets/effects/am-hot-color.xml
// id     : nova.effect.am-hot-color
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_hot_colorParams {
    float color;
    float tint;
};

// --- funcoes auxiliares do efeito
// O fundo (a cena montada atrás da camada) no pixel da tela, pré-multiplicado (o do Anel).
static float3 fundoNoPixel() {
    int2 T = int2(int(comp.get_width()), int(comp.get_height()));
    int2 px = clamp(int2(floor(__nv_acTela(in.acScreenNorm) * float2(T))), int2(0), T - 1);
    float4 f = comp.read(uint2(px), uint(0));
    return f.rgb * f.a;
}

// A saída pré-multiplicada do AM (`q`, já em 8 bits) em cor reta — a do `am-sharpen.xml`: onde a cor passa do alfa, o
// menor alfa em que a cor reta cabe, com o fundo junto, dá na composição Normal o mesmo que a soma do AM.
static float4 paraReta(float4 q) {
    if (all(lessThanEqual(q.rgb, float3(q.a)))) return q.a > 0.0 ? float4(q.rgb / q.a, q.a) : float4(0.0);
    float3 d = fundoNoPixel();
    float3 sobra = q.rgb - d * q.a;
    float3 folga = 1.0 - d;
    float a = q.a;
    for (int i = 0; i < 3; i++) {
        if (sobra[i] > 0.0 && folga[i] > 0.0) a = max(a, sobra[i] / folga[i]);
    }
    a = min(a, 1.0);
    return a > 0.0 ? float4(clamp(d + sobra / a, 0.0, 1.0), a) : float4(0.0);
}

// k ÷ 255 com o arredondamento certo: o float EXATO que a textura de 8 bits devolve ao AM (ver `am-u.color-balance.xml`).
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

// Daqui até o fim do passe 0, o shader do AM com os nomes dele, na mesma ordem e na mesma precisão.
static float3 hsv2rgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

const float3x3 rgb2yuv = float3x3(
     0.299,     0.587,    0.114,
    -0.14713,  -0.28886,  0.436,
     0.615,    -0.51499, -0.10001
);

const float3x3 yuv2rgb = float3x3(
    1.0,  0.0,      1.13983,
    1.0, -0.39465, -0.58060,
    1.0,  2.03211,  0.0
);

fragment float4 fx_am_hot_color(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_hot_colorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    texture2d<float> quente [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        // A camada do AM chega pré-multiplicada EM 8 BITS, pelo mais perto (o premul do Android). No opaco a cor já é
        // o float da textura, bit a bit.
        float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
        float3 pre = c.rgb;
        if (c.a < 1.0) {
            float3 k = floor(c.rgb * c.a * 255.0 + 0.5);
            pre = float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
        }
        // Os parâmetros no `mediump` dos uniforms do AM.
        float3 cor = u.color;
        float3 tom = u.tint;

        float4 source = float4(pre, c.a);
        float luminance = dot(source.rgb, luminanceWeighting);

        float gamma = cor.z+1.0;
        luminance = pow(luminance,1.0/gamma);

        float hue = cor.x /360.;
        float sat = cor.y;
        float hue2 = tom.x /360.;
        float sat2 = tom.y;

        float3 darkColor =  hsv2rgb(float3(hue,sat,1.0));
        float3 baseColor =  hsv2rgb(float3(hue,sat,1.0));
        float3 lightColor =  hsv2rgb(float3(hue2,sat2,1.0));

        float cutoff = tom.z / 2.0 + 0.5;
        float3 blendColor = luminance < cutoff ? mix( darkColor, baseColor, luminance/cutoff) :  mix( baseColor, lightColor, (luminance-cutoff)/(1.-cutoff));

        float3 yuv = blendColor * rgb2yuv;
        yuv.x = luminance;
        yuv.yz *= luminance;
        blendColor = yuv * yuv2rgb;

        float shineStart = .85;
        float shineAmount = max(0.,luminance - shineStart) * (1./(1.-shineStart));
        shineAmount = shineAmount * shineAmount * sat;
        blendColor = mix( blendColor, float3(1.), shineAmount );

        // O corte em 0..1 é o do alvo de 8 bits do AM; escrito aqui para o projeto de 32 bits sair igual.
        __nv_out = clamp(float4(blendColor,1.0) * source.a, 0.0, 1.0);
        return __nv_out;
    }
    __nv_out = paraReta(quente.sample(__nv_smp, in.acScreenNorm));
    return __nv_out;
}
