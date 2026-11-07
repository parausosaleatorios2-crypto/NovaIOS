// ---------------------------------------------------------------------------
// BCC Drop Shadow
// origem : assets/effects/bcc-drop-shadow.xml
// id     : nova.effect.bccdropshadow
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bcc_drop_shadowParams {
    float sourceOpacity;
    float shadowDistance;
    float shadowIntensity;
    float shadowAngle;
    float4 shadowColor;
    float shadowSoftness;
    float gamma;
};

// --- funcoes auxiliares do efeito
const int MARGEM = 256;            // = margin dos buffers
const float RAIO_A = 1.6633;       // R = RAIO_B + RAIO_A · Softness (medido: r2_32, r3_32, r4_16)
const float RAIO_B = 1.0019;
const float GRAUS = 0.017453292519943295;

float escala() { return eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0; }

// O deslocamento em px do buffer, y para baixo como no AE; com a cena de pé (a linha 0 é a base), o "para baixo" é
// para cima aqui.
float2 deslocamento() {
    float d = u.shadowDistance * escala();
    float t = u.shadowAngle * GRAUS;
    float2 v = float2(sin(t), -cos(t)) * d;
    return float2(v.x, eng.acEntradaDePe == 1 ? -v.y : v.y);
}

// O alfa da camada; fora do quadro, transparente.
float alfaDaCamada(int2 c) {
    int2 t = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    if (any(lessThan(c, int2(0))) || any(greaterThanEqual(c, t))) return 0.0;
    return inputImg.read(uint2(c), uint(0)).a;
}

// 24 bits fixos no RGB de um RGBA8 (o alfa da passada fica em [0, 1]).
float4 guardar(float v) {
    uint q = min(uint(clamp(v, 0.0, 1.0) * 16777216.0), 16777215u);
    return float4(float(q >> 16u), float((q >> 8u) & 255u), float(q & 255u), 255.0) / 255.0;
}
float abrir(sampler2D b, int2 c) {
    int2 p = c + MARGEM;
    int2 n = int2(int(b.get_width()), int(b.get_height()));
    if (any(lessThan(p, int2(0))) || any(greaterThanEqual(p, n))) return 0.0;
    uint3 k = uint3(floor(b.read(uint2(p), uint(0)).rgb * 255.0 + 0.5));
    return float((k.x << 16u) | (k.y << 8u) | k.z) / 16777216.0;
}

fragment float4 fx_bcc_drop_shadow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bcc_drop_shadowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> dsA [[texture(1)]],
    texture2d<float> dsB [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        // a máscara: o alfa em (c − deslocamento), bilinear
        float2 p = float2(int2(__nv_fragCoord.xy) - MARGEM) - deslocamento();
        float2 b = floor(p);
        float2 f = p - b;
        int2 i = int2(b);
        float m = mix(mix(alfaDaCamada(i), alfaDaCamada(i + int2(1, 0)), f.x),
                      mix(alfaDaCamada(i + int2(0, 1)), alfaDaCamada(i + int2(1, 1)), f.x), f.y);
        __nv_out = guardar(m);
        return __nv_out;
    }

    if (eng.acPass < 3) {
        // o triângulo do Pyramid: horizontal no passe 1 (lê dsA), vertical no 2 (lê dsB)
        int2 c = int2(__nv_fragCoord.xy) - MARGEM;
        int2 eixo = eng.acPass == 1 ? int2(1, 0) : int2(0, 1);
        float R = (RAIO_B + RAIO_A * u.shadowSoftness) * escala();
        int n = int(ceil(R)) - 1;
        float S = float(2 * n + 1) * R - float(n * (n + 1));
        float soma = 0.0;
        for (int k = -n; k <= n; k++) {
            float w = R - float(abs(k));
            soma += w * (eng.acPass == 1 ? abrir(dsA, c + eixo * k) : abrir(dsB, c + eixo * k));
        }
        __nv_out = guardar(soma / S);
        return __nv_out;
    }

    // A composição em 8 bits, como o AE (medido: r1_8 e r4_8, o alfa a até 1 nível com alfa parcial): o u.gamma em
    // float, a máscara arredondada a 8 bits, Intensity em 1/256, a sombra e a soma truncadas. O 1e-4 segura o
    // inteiro exato que a divisão da GPU devolve um tico abaixo.
    int2 c = int2(__nv_fragCoord.xy);
    float m = clamp(abrir(dsA, c), 0.0, 1.0);
    float g = max(u.gamma, 0.001);
    float m8 = floor(255.0 * pow(m, 1.0 / g) + 0.5);
    float i8 = floor(clamp(u.shadowIntensity, 0.0, 1.0) * 256.0 + 0.5) / 256.0;
    float s8 = floor(m8 * i8 + 1e-4);
    float3 cor = u.shadowColor.rgb;

    // a camada (reta) × Source Opacity por cima da sombra
    float4 l = inputImg.read(uint2(c), uint(0));
    float l8 = floor(floor(l.a * 255.0 + 0.5) * clamp(u.sourceOpacity, 0.0, 1.0) + 1e-4);
    float a8 = floor(l8 + s8 * (255.0 - l8) / 255.0 + 1e-4);
    float4 saida = a8 > 0.0 ? float4((l.rgb * l8 + cor * (a8 - l8)) / a8, a8 / 255.0) : float4(0.0);
    if (l8 == 0.0 && a8 > 0.0) saida.rgb = cor;
    __nv_out = clamp(saida, 0.0, 1.0);
    return __nv_out;
}
