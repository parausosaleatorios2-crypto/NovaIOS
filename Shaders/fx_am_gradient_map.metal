// ---------------------------------------------------------------------------
// Mapa de gradiente (AM)
// origem : assets/effects/am-gradient-map.xml
// id     : nova.effect.am-gradient-map
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_gradient_mapParams {
    float4 color1;
    float4 color2;
};

fragment float4 fx_am_gradient_map(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_gradient_mapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 camada = inputImg.sample(__nv_smp, in.acScreenNorm);
    float a = camada.a;
    // Na MESMA precisão do AM: o `<shader>` dele não pede `precision`, e aí o AM compila com `precision // float` (`ssl/BI`, `ShaderPrecision.MEDIUM`) — no celular, meia precisão. Variável por variável: um
    // `precision` global vazaria para os efeitos da cor junta. A GPU do PC ignora a precisão; o celular, não.
    float4 pre = float4(camada.rgb * a, a);                  // o AM trabalha pré-multiplicado
    float4 cor1 = u.color1;
    float4 cor2 = u.color2;
    float brilho = dot(pre.rgb, float3(0.2126, 0.7152, 0.0722));
    // As cores do parâmetro entram RETAS, como no AM; a saída é pré-multiplicada (o buffer de 8 bits corta em 0 e 1).
    float4 saida = clamp(mix(cor1, cor2, brilho) * pre.a, 0.0, 1.0);
    __nv_out = saida.a > 0.0 ? float4(min(saida.rgb / saida.a, float3(1.0)), saida.a) : float4(0.0);
    return __nv_out;
}
