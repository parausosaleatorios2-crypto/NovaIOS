// ---------------------------------------------------------------------------
// Espelho e caleidoscópio
// origem : assets/effects/mirror.xml
// id     : nova.effect.mirror
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct mirrorParams {
    int mode;
    float slices;
    float2 center;
    float rotation;
};

// --- funcoes auxiliares do efeito
const float TAU = 6.28318530718;

fragment float4 fx_mirror(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant mirrorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;

    if (u.mode == 0) {
        // Reflete a metade esquerda na direita.
        uv.x = u.center.x - abs(uv.x - u.center.x);
    } else if (u.mode == 1) {
        uv.y = u.center.y - abs(uv.y - u.center.y);
    } else if (u.mode == 2) {
        uv = u.center - abs(uv - u.center);
    } else {
        // Caleidoscópio: converte para coordenada polar, dobra o ângulo dentro
        // de uma fatia, e volta. O `abs` no ângulo dobrado é o que cria o
        // espelhamento dentro de cada fatia — sem ele as fatias ficam iguais e
        // giradas, o que parece um leque e não um caleidoscópio.
        float2 p = (uv - u.center) * float2(eng.acAspect, 1.0);
        float angle = __nv_atan(p.y, p.x) + radians(u.rotation);
        float radius = length(p);

        // `max(u.slices, 2.0)` e nao `max(u.slices, 2)`: TODO slider vira
        // `uniform float`, inclusive o de type="integer" — o `2` inteiro nao
        // casava com nenhuma sobrecarga e o shader inteiro deixava de compilar.
        // Este efeito estava quebrado desde que nasceu, e so apareceu quando os
        // shaders passaram a ser compilados no `./gradlew test`.
        float slice = TAU / max(u.slices, 2.0);
        angle = __nv_mod(angle, slice);
        angle = abs(angle - slice * 0.5);

        p = float2(cos(angle), sin(angle)) * radius;
        uv = u.center + p / float2(eng.acAspect, 1.0);
    }

    // Depois de dobrar as coordenadas é comum sair do intervalo válido.
    // Refletir de volta (em vez de cortar) mantém a imagem contínua.
    uv = abs(uv);
    uv = mix(uv, 2.0 - uv, step(1.0, uv));

    __nv_out = inputImg.sample(__nv_smp, clamp(uv, 0.0, 1.0));
    return __nv_out;
}
