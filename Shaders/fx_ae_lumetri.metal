// ---------------------------------------------------------------------------
// Lumetri Color
// origem : assets/effects/ae-lumetri.xml
// id     : nova.effect.aelumetri
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
#include "NovaLut.h"
using namespace metal;

struct ae_lumetriParams {
    float4 lutDeEntrada;
    float4 look;
    float intensidade;
};

// --- funcoes auxiliares do efeito
// Medir a interpolação no AE e trocar se for a trilinear (ver o cabeçalho).
constant bool TETRAEDRICA = true;

fragment float4 fx_ae_lumetri(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_lumetriParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture3d<float> lutDeEntradaTex [[texture(1)]],
    texture3d<float> lookTex [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float4 fonte = inputImg.read(uint2(int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0))), uint(0));
    float3 c = fonte.rgb;

    // Basic Correction: o LUT de entrada, antes de tudo.
    c = nova_lut3d(lutDeEntradaTex, c);

    // Creative: o Look, misturado pela Intensidade.
    if (lookTipo != 0) {
        float3 comLook = nova_lut3d(lookTex, c);
        c = mix(c, comLook, clamp(u.intensidade, 0.0, 200.0) / 100.0);
    }

    __nv_out = float4(clamp(c, 0.0, 1.0), fonte.a);
    return __nv_out;
}
