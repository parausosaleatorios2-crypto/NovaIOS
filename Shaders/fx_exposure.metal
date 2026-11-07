// ---------------------------------------------------------------------------
// Exposição
// origem : assets/effects/exposure.xml
// id     : nova.effect.exposure
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct exposureParams {
    float stops;
    float offset;
    int rolloff;
    int espaco;
    float gama;
};

// --- funcoes auxiliares do efeito
// sRGB → luz linear. A parte reta perto do zero não é capricho: sem ela a
// curva tem derivada infinita na origem e o ruído da sombra explode.
static float3 paraLinear(float3 c) {
    return mix(
        c / 12.92,
        pow((c + 0.055) / 1.055, float3(2.4)),
        step(0.04045, c)
    );
}

static float3 paraSrgb(float3 c) {
    return mix(
        c * 12.92,
        1.055 * pow(c, float3(1.0 / 2.4)) - 0.055,
        step(0.0031308, c)
    );
}

fragment float4 fx_exposure(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant exposureParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    float3 cor = clamp(color.rgb, 0.0, 1.0);
    // Medido no After Effects: a "luz linear" de lá é a cor elevada a 2,4, sem o trecho reto do sRGB.
    float3 luz = u.espaco == 0 ? paraLinear(cor) : u.espaco == 1 ? pow(cor, float3(2.4)) : cor;

    // Um ponto de exposição é um FATOR DOIS. É por isso que a conta é uma
    // potência de dois, e não uma multiplicação direta pelo valor do slider.
    luz *= pow(2.0, u.stops);
    luz += u.offset;
    luz = max(luz, 0.0);
    if (u.gama != 1.0) luz = pow(luz, float3(1.0 / max(u.gama, 0.1)));

    if (u.rolloff) {
        // Compressão assintótica: abaixo de ~0,8 quase nada muda; daí para
        // cima a curva encosta em 1 sem nunca ultrapassar. Preserva a matiz
        // porque o mesmo fator é aplicado aos três canais, calculado sobre o
        // canal mais alto — comprimir cada canal por conta própria desbotaria
        // as cores saturadas.
        float maior = max(max(luz.r, luz.g), luz.b);
        if (maior > 0.8) {
            float excedente = maior - 0.8;
            float comprimido = 0.8 + excedente / (1.0 + excedente * 1.6);
            luz *= comprimido / maior;
        }
    }

    float3 saida = u.espaco == 0 ? paraSrgb(luz) : u.espaco == 1 ? pow(luz, float3(1.0 / 2.4)) : luz;
    __nv_out = float4(clamp(saida, 0.0, 1.0), color.a);
    return __nv_out;
}
