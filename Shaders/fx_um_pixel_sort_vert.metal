// ---------------------------------------------------------------------------
// Pixel Sort Vertical (Ultra Motion)
// origem : assets/effects/um-pixel-sort-vert.xml
// id     : nova.effect.ultramotion.pixelsortvert
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_pixel_sort_vertParams {
    float threshold;
    float maxLen;
    float downward;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_um_pixel_sort_vert(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_pixel_sort_vertParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // Ande para cima varrendo até achar o primeiro píxel ABAIXO do limiar — esse é o que fica neste ponto.
    float2 uv = in.acScreenNorm;
    float4 cor = inputImg.sample(__nv_smp, uv);
    float l = dot(cor.rgb, LUMA);
    if (l < u.threshold) { __nv_out = cor; return __nv_out; }

    float passo = eng.acTexelSize.y;
    float dir = sign(u.downward);
    if (dir == 0.0) dir = 1.0;
    float andar = 0.0;
    float4 melhor = cor;
    for (int i = 1; i <= 128; i++) {
        float t = float(i) * passo * 2.0;
        if (t > u.maxLen) break;
        float2 u = uv + float2(0.0, dir * t);
        if (u.y < 0.0 || u.y > 1.0) break;
        float4 c = inputImg.sample(__nv_smp, u);
        float ll = dot(c.rgb, LUMA);
        if (ll < u.threshold) break;
        melhor = c;
        andar = t;
    }
    // Interpola para suavizar a borda
    float k = smoothstep(0.0, u.maxLen * 0.1, andar);
    __nv_out = mix(cor, melhor, k * abs(u.downward));
    return __nv_out;
}
