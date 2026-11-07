// ---------------------------------------------------------------------------
// Linhas de contorno
// origem : assets/effects/am-contour-lines.xml
// id     : nova.effect.am-contour-lines
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_contour_linesParams {
    float4 color;
    float offset;
    float width;
    float alpha;
    float fill;
    float count;
    float phase;
    int fade;
};

// --- funcoes auxiliares do efeito
// O buffer guarda a distância como fração deste teto (16 bits em dois canais de 8).
const float TETO = 16383.0;

float2 guardar(float d) {
    float v = d / TETO;
    float baixo = fract(v * 255.0);
    return float2(v - baixo / 255.0, baixo);
}

float ler(float2 rg) {
    return (rg.x + rg.y / 255.0) * TETO;
}

// O smoothstep com as pontas em qualquer ordem (o GLSL não garante o resultado com e0 > e1).
float degrau(float e0, float e1, float x) {
    float t = clamp((x - e0) / (e1 - e0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

fragment float4 fx_am_contour_lines(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_contour_linesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> distX [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // "Pixels de 1024²" → pixels deste buffer.
    float escala = length(eng.acResolution) / length(float2(1024.0));
    float inicio = u.offset * escala;
    float largura = u.width * escala;
    float alcance = inicio + largura;
    int n = max(1, int(alcance));
    float longe = alcance * 2.0;

    if (eng.acPass == 0) {
        // Na linha: o pixel opaco mais perto, de −n a n − 1. Do centro para fora, o primeiro achado é o menor.
        float melhor = longe;
        for (int k = 0; k <= n; k++) {
            if (inputImg.sample(__nv_smp, in.acScreenNorm + float2(-float(k) * eng.acTexelSize.x, 0.0)).a > 0.0
                || (k < n && inputImg.sample(__nv_smp, in.acScreenNorm + float2(float(k) * eng.acTexelSize.x, 0.0)).a > 0.0)) {
                melhor = float(k);
                break;
            }
        }
        __nv_out = float4(guardar(melhor), 0.0, 0.0);
        return __nv_out;
    }

    // Na coluna: o menor √(dx² + dy²), de −n a n − 1 linhas. O lado que fica de fora (o +n) é o de CIMA na
    // tela, como no AM; `sentido` acha o "para cima" no buffer (conteúdo de camada: linha 0 no topo).
    float sentido = eng.acEntradaDePe == 1 ? 1.0 : -1.0;
    float melhor = 1e9;
    for (int k = 0; k <= n; k++) {
        float dy = float(k);
        if (dy >= melhor) break;    // daqui para fora nada fica mais perto
        float dx = ler(distX.sample(__nv_smp, in.acScreenNorm - float2(0.0, sentido * dy * eng.acTexelSize.y)).rg);
        melhor = min(melhor, length(float2(dx, dy)));
        if (k < n) {
            dx = ler(distX.sample(__nv_smp, in.acScreenNorm + float2(0.0, sentido * dy * eng.acTexelSize.y)).rg);
            melhor = min(melhor, length(float2(dx, dy)));
        }
    }

    float4 base = inputImg.sample(__nv_smp, in.acScreenNorm);
    float4 camada = float4(base.rgb * base.a, base.a) * u.fill;   // pré-multiplicada

    float linha = 0.0;
    if (largura > 0.0) {
        float aa = 1.0 / largura / 2.0;
        float p = clamp((melhor - inicio) / largura, 0.0, 1.0);
        float faixas = u.count * 2.0 - 1.0;
        float mascara = u.fade
            ? degrau(1.0, 0.0, p) * degrau(0.0, aa, p)
            : degrau(0.0, aa, p) * degrau(1.0, 1.0 - aa, p);
        linha = degrau(1.0 + aa, 1.0 - aa, __nv_mod(mod(p + u.phase, 1.0 + 1.0 / (u.count * 2.0)) * faixas, 2.0)) * mascara;
    }

    float4 c = u.color * (u.alpha * linha * (1.0 - base.a));
    float4 saida = camada * (1.0 - c.a) + c;
    __nv_out = saida.a > 0.0 ? float4(saida.rgb / saida.a, saida.a) : float4(0.0);
    return __nv_out;
}
