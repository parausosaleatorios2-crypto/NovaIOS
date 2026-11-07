// ---------------------------------------------------------------------------
// Mesclar com o original
// origem : assets/effects/mesclar-com-o-original.xml
// id     : nova.effect.mesclarcomoriginal
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct mesclar_com_o_originalParams {
    int modo;
    float opacidade;
};

fragment float4 fx_mesclar_com_o_original(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant mesclar_com_o_originalParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> originalImg [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 topo = inputImg.sample(__nv_smp, in.acScreenNorm);
    float4 base = originalImg.sample(__nv_smp, in.acScreenNorm);

    // A u.opacidade entra no alfa do que vem de cima: a 0 sobra a camada crua, e
    // no caminho é a mesma conta de uma camada com u.opacidade no AM e no Nova.
    float as_ = topo.a * clamp(u.opacidade, 0.0, 1.0);
    float ab = base.a;

    // A composição do W3C, a mesma da mesclagem de camada e da de efeito.
    float3 mesclado = mesclarComoACamada(u.modo, base.rgb, topo.rgb);
    float a = as_ + ab * (1.0 - as_);
    float3 cor = as_ * (1.0 - ab) * topo.rgb
             + as_ * ab * mesclado
             + (1.0 - as_) * ab * base.rgb;

    __nv_out = a > 0.0 ? float4(clamp(cor / a, 0.0, 1.0), a) : float4(0.0);
    return __nv_out;
}
