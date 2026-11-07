// ---------------------------------------------------------------------------
// Grade laser
// origem : assets/effects/laser-grid.xml
// id     : nova.effect.laser-grid
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct laser_gridParams {
    float4 lineColor;
    float4 skyColor;
    float horizon;
    float cameraHeight;
    float speed;
    float lineWidth;
    float glow;
};

// --- funcoes auxiliares do efeito
/** Desenha uma linha fina em `t = fract(x)`: 1 na linha, 0 fora dela. */
float linha(float x, float largura) {
    float f = abs(fract(x) - 0.5) * 2.0;    // 0 no meio da célula, 1 na borda
    return smoothstep(1.0 - largura, 1.0, f);
}

fragment float4 fx_laser_grid(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant laser_gridParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;

    // Céu: pintado uniformemente acima do horizonte.
    if (uv.y < u.horizon) {
        __nv_out = float4(u.skyColor.rgb, u.skyColor.a);
        return __nv_out;
    }

    // Projeção: y sob o horizonte → z metros de distância.
    float alturaNoChao = uv.y - u.horizon;
    float z = u.cameraHeight / max(alturaNoChao, 1e-4);

    // X escala com z (ponto de fuga no centro). O centro do chão fica em x=0.5.
    float xDoChao = (uv.x - 0.5) * eng.acAspect * z;

    // Linhas perpendiculares correndo pra câmera.
    float profundidade = z + eng.acTime * u.speed;
    float linhaPerp = linha(profundidade, u.lineWidth * 2.0);

    // Linhas paralelas (x fixo no mundo).
    float linhaPar = linha(xDoChao, u.lineWidth * 2.0);

    float grade = max(linhaPerp, linhaPar);

    // Halo: queda com a distância ao centro da linha (grosseiro mas vendável).
    float halo = 0.0;
    halo += exp(-abs(fract(profundidade) - 0.5) * 2.0 / max(u.lineWidth, 1e-4)) * u.glow * 0.5;
    halo += exp(-abs(fract(xDoChao) - 0.5) * 2.0 / max(u.lineWidth, 1e-4)) * u.glow * 0.5;

    // As linhas somem com a distância (fog).
    float neblina = exp(-z * 0.08);
    grade *= neblina;
    halo *= neblina;

    float3 cor = u.skyColor.rgb + u.lineColor.rgb * (grade + halo);
    cor = clamp(cor, 0.0, 1.0);

    __nv_out = float4(cor, 1.0);
    return __nv_out;
}
