// ---------------------------------------------------------------------------
// Realces e sombras
// origem : assets/effects/am-highlights-shadows.xml
// id     : nova.effect.am-highlights-shadows
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_highlights_shadowsParams {
    float highlights;
    float shadows;
};

// --- funcoes auxiliares do efeito
// k ÷ 255 com o arredondamento certo: o float EXATO que a textura de 8 bits devolve ao AM (ver `am-color-balance.xml`).
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

fragment float4 fx_am_highlights_shadows(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_highlights_shadowsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 camada = inputImg.sample(__nv_smp, in.acScreenNorm);
    float a = camada.a;
    // A camada do AM chega pré-multiplicada EM 8 BITS: arredondada aqui do mesmo jeito (o premul do Android). No
    // opaco a cor já é o float da textura, bit a bit.
    float3 p = camada.rgb;
    if (a < 1.0) {
        float3 k = floor(camada.rgb * a * 255.0 + 0.5);
        p = float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
    }

    // A conta do AM, na mesma ordem (o último bit muda com a ordem das somas) e na MESMA precisão: o `<shader>` dele
    // não pede `precision`, e aí o AM compila com `precision float` (`ssl/BI`, `ShaderPrecision.MEDIUM`) — no
    // celular, meia precisão (16 bits). Os parâmetros e as variáveis daqui levam o mesmo `mediump` (e o `result` dele
    // é `lowp`), variável por variável: um `precision` global vazaria para os efeitos da cor junta. A GPU do PC
    // ignora a precisão; o celular, não.
    float3 cor = p;
    float realces = u.highlights;
    float sombras = u.shadows;
    float brilho = dot(cor, float3(0.2126, 0.7152, 0.0722));
    // Preto e transparente: o AM divide 0 por 0, e o NaN vai para o buffer como 0.
    if (brilho == 0.0) {
        __nv_out = float4(0.0, 0.0, 0.0, a);
        return __nv_out;
    }

    float sombrasPresas = clamp(sombras, 1.0, 2.0);
    float sombra = clamp((pow(brilho, 1.0 / sombrasPresas) + (-0.76) * pow(brilho, 2.0 / sombrasPresas)) - brilho, 0.0, 1.0);
    float realce = clamp((1.0 - (pow(1.0 - brilho, 1.0 / (2.0 - realces)) + (-0.8) * pow(1.0 - brilho, 2.0 / (2.0 - realces)))) - brilho, -1.0, 0.0);
    float3 r = (brilho + sombra + realce) * (cor / brilho);

    float contrastado = ((brilho - 0.5) * 1.5) + 0.5;
    float paraBranco = contrastado * contrastado * contrastado;
    float alvoBranco = clamp(realces, 1.0, 2.0) - 1.0;
    r = mix(r, float3(1.0), paraBranco * alvoBranco);

    float inverso = 1.0 - contrastado;
    float paraPreto = inverso * inverso * inverso;
    float alvoPreto = 1.0 - clamp(sombras, 0.0, 1.0);
    r = mix(r, float3(0.0), paraPreto * alvoPreto);

    float3 saida = clamp(r, 0.0, 1.0);                             // o buffer de 8 bits do AM corta em 0 e 1
    __nv_out = a > 0.0 ? float4(min(saida / a, float3(1.0)), a) : float4(0.0);
    return __nv_out;
}
