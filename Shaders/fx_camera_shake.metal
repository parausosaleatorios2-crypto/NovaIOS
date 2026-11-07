// ---------------------------------------------------------------------------
// Tremor de câmera
// origem : assets/effects/camera-shake.xml
// id     : nova.effect.camera-shake
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct camera_shakeParams {
    float amountX;
    float amountY;
    float rotateAmount;
    float frequency;
    float roughness;
    float seed;
};

// --- funcoes auxiliares do efeito
/**
 * Tremor em 1D: soma de 3 senos de frequências irracionalmente relacionadas,
 * mais uma componente rápida pra aspereza. Média zero, amplitude ~1.
 */
float tremor1D(float t, float faseInicial) {
    float s = float(u.seed) * 0.37 + faseInicial;
    float a = sin(t * 1.0 + s * 1.7);
    float b = sin(t * 1.618 + s * 3.1) * 0.6;
    float c = sin(t * 2.414 + s * 5.9) * 0.4;
    float aspero = sin(t * 7.0 + s * 11.3) * u.roughness * 0.3;
    return (a + b + c + aspero) / 2.3;   // normaliza aproximadamente a [-1, 1]
}

fragment float4 fx_camera_shake(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant camera_shakeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float t = eng.acTime * u.frequency;

    // Translação: X e Y com fases diferentes pra não casarem.
    float2 translacao = float2(
        tremor1D(t, 0.0) * u.amountX,
        tremor1D(t, 13.7) * u.amountY
    );

    // Giro: ângulo tremendo em volta do centro da tela.
    float ang = radians(tremor1D(t, 7.3) * u.rotateAmount);
    float cosA = cos(ang);
    float sinA = sin(ang);

    float2 centro = float2(0.5, 0.5);
    float2 relativo = in.acScreenNorm - centro;
    float2 girado = float2(relativo.x * cosA - relativo.y * sinA,
                       relativo.x * sinA + relativo.y * cosA);
    float2 uv = girado + centro + translacao;

    __nv_out = inputImg.sample(__nv_smp, uv);
    return __nv_out;
}
