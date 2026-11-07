// ---------------------------------------------------------------------------
// Warp (AE)
// origem : assets/effects/ae-warp.xml
// id     : nova.effect.aewarp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_warpParams {
    int warpStyle;
    int warpAxis;
    float bend;
    float horizDistort;
    float vertDistort;
};

// --- funcoes auxiliares do efeito
// ADBE WRPMESH — Warp do After Effects. Mapeamento INVERSO analítico (pixel de saída → pixel de entrada), na camada do
// AE dentro do buffer, com y para BAIXO (a linha 0 é o topo, como no plugin). Bend positivo levanta o meio (o arco do
// arco-íris). Funções do CannedWarp.aex citadas: 0x1800062b0 (arco Bezier), TRiseDeform 180007b90, TSqueezeDeform
// 180007fc0, TFishDeform 180007720, TFlagDeform 180007a20, TFisheyeDeform 1800077c0, TTwistDeform 180008090,
// TInflateDeform 180007ac0.

#define PI      3.14159265358979323846
#define HALF_PI 1.57079632679489661923

// O quanto o meio de uma linha de corda 2·half_chord sobe num arco circular de meio-ângulo |t|·π/2, em u ∈ [0, 1].
static float arcDy(float u, float abs_t, float half_chord) {
    if (abs_t < 0.001) return abs_t * 4.0 * u * (1.0 - u) * half_chord;   // parábola no ângulo pequeno
    float theta = abs_t * HALF_PI;
    float R = half_chord / sin(theta);
    return R * (cos(theta * (2.0 * u - 1.0)) - cos(theta));
}

fragment float4 fx_ae_warp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_warpParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // A camada do AE dentro do buffer (a mídia encaixada; texto, forma e sólido: a composição inteira).
    float2 buf = eng.acResolution;
    float2 tam = clamp(floor(eng.acCamada * buf + 0.5), float2(1.0), buf);
    float2 inicio = floor((buf - tam) * 0.5);
    bool dePe = eng.acEntradaDePe == 1;   // cena guardada de pé: a linha 0 do buffer é a BASE
    float2 op = in.acScreenNorm * buf - inicio;
    if (dePe) op.y = tam.y - op.y;

    float hd = float(u.horizDistort) / 100.0;
    float vd = float(u.vertDistort) / 100.0;
    int axis = int(u.warpAxis);
    // O número do AE (1..15). Projeto salvo antes da 0.785.0 pode trazer 0: vale o padrão do AE (Arc).
    int style = clamp(int(u.warpStyle), 1, 15);

    // Eixo vertical: a mesma conta com x e y trocados.
    float2 work = axis == 0 ? op : op.yx;
    float W = axis == 0 ? tam.x : tam.y;
    float H = axis == 0 ? tam.y : tam.x;

    float t  = float(u.bend) / 100.0;
    float at = abs(t);
    float sg = t < 0.0 ? -1.0 : 1.0;
    float u  = work.x / W;
    float v  = work.y / H;
    float2 ip = work;
    bool fora = false;

    if (style == 1) {
        // Arc: as linhas viram arcos concêntricos e as colunas, raios (o centro do círculo fica do lado de dentro da
        // curva). A linha do meio, de corda W, abre ±|t|·π/2.
        if (at >= 0.001) {
            float theta = at * HALF_PI;
            float R = (W * 0.5) / sin(theta);
            float2 c = float2(W * 0.5, H * 0.5 + sg * R);
            float2 d = work - c;
            float r = length(d);
            float phi = __nv_atan(d.x, -sg * d.y);          // 0 no alto do arco
            ip.x = W * 0.5 + phi / theta * (W * 0.5);
            ip.y = H * 0.5 + sg * (R - r);
            if (abs(phi) > theta + 0.0001) fora = true;
        }
    } else if (style == 2) {
        // Arc Lower: só a borda de baixo curva (o meio desce), o topo fica reto.
        ip.y -= sg * arcDy(u, at, W * 0.5) * clamp(v, 0.0, 1.0);
    } else if (style == 3) {
        // Arc Upper: só a borda de cima curva (o meio sobe), a base fica reta.
        ip.y += sg * arcDy(u, at, W * 0.5) * clamp(1.0 - v, 0.0, 1.0);
    } else if (style == 4) {
        // Arch: cada coluna sobe inteira pelo arco (as laterais ficam em pé).
        ip.y += sg * arcDy(u, at, W * 0.5);
    } else if (style == 5) {
        // Bulge (TArcBuldgeDeform): as duas bordas se abrem para fora a partir do meio.
        float hy = H * 0.5;
        float escalaV = (hy + sg * arcDy(u, at, W * 0.5)) / hy;
        ip.y = hy + (work.y - hy) / max(escalaV, 0.01);
    } else if (style == 6 || style == 7) {
        // Shell Lower / Shell Upper (TShellBottomDeform / TShellTopDeform): a borda de baixo (ou de cima) faz o arco
        // e a outra se aperta em volta dela.
        bool baixo = style == 6;
        float lado = baixo ? clamp(v, 0.0, 1.0) : clamp(1.0 - v, 0.0, 1.0);
        float dy = sg * arcDy(u, at, W * 0.5) * lado;
        ip.y += baixo ? -dy : dy;
        float ang = __nv_atan((work.y - H * 0.5) / max(W * 0.25, 0.001)) * (-4.0 / PI);
        float hscale = 1.0 + sg * at * ang * 0.25 * (baixo ? 1.0 : -1.0);
        ip.x = W * 0.5 + (work.x - W * 0.5) / max(hscale, 0.01);
    } else if (style == 8) {
        // Flag (TFlagDeform): as linhas ondulam, meia onda para cima e meia para baixo.
        ip.y += t * sin(2.0 * PI * u) * H * 0.25;
    } else if (style == 9) {
        // Wave: a onda da bandeira, mais forte no meio da altura.
        ip.y += t * sin(2.0 * PI * u) * H * 0.25 * (1.0 - 0.5 * abs(2.0 * v - 1.0));
    } else if (style == 10) {
        // Fish (TFishDeform): largo no meio, estreito nas pontas.
        float escala = 1.0 + t * sin(PI * u) * 0.5;
        ip.y = H * 0.5 + (work.y - H * 0.5) / max(escala, 0.01);
    } else if (style == 11) {
        // Rise (TRiseDeform): sobe de um lado para o outro, em curva suave.
        ip.y += t * (0.5 - 0.5 * cos(PI * u)) * H * 0.5 - t * H * 0.25;
    } else if (style == 12) {
        // Fisheye (TFisheyeDeform): o centro cresce em lente.
        float2 c = float2(W, H) * 0.5;
        float2 d = work - c;
        float r = length(d);
        if (r > 0.001 && at > 0.001) {
            float rn = r / length(c);
            float rnIn = rn * (1.0 - sg * at * (1.0 - min(rn, 1.0)) * 0.6);
            ip = c + d * (rnIn / rn);
        }
    } else if (style == 13) {
        // Inflate (TInflateDeform): a camada inteira incha como um balão — a distância é medida na elipse da camada,
        // e o centro amplia até 1/(1 − |t|/2) (Bend negativo murcha).
        float2 c = float2(W, H) * 0.5;
        float2 d = work - c;
        float rn = min(length(d / c), 1.0);
        ip = c + d * (1.0 - sg * at * 0.5 * (1.0 - rn * rn));
    } else if (style == 14) {
        // Twist (TTwistDeform): o miolo gira e as bordas ficam — o giro cai do centro (|t|·90°) até zero na elipse da camada.
        float2 c = float2(W, H) * 0.5;
        float2 d = work - c;
        float rn = min(length(d / c), 1.0);
        float ang = -t * HALF_PI * (1.0 - rn) * (1.0 - rn);
        float cs = cos(ang);
        float sn = sin(ang);
        ip = c + float2(d.x * cs - d.y * sn, d.x * sn + d.y * cs);
    } else {
        // 15 — Squeeze (TSqueezeDeform): aperta o meio na altura (Bend negativo abre).
        float escala = 1.0 - t * sin(PI * u) * 0.5;
        ip.y = H * 0.5 + (work.y - H * 0.5) / max(escala, 0.01);
    }

    // Horizontal / Vertical Distortion: a perspectiva de um lado (a borda de um lado cresce, a outra encolhe).
    if (abs(hd) > 0.001 || abs(vd) > 0.001) {
        float sx = 1.0 + hd * (ip.y / H - 0.5);
        float sy = 1.0 + vd * (ip.x / W - 0.5);
        ip.x = W * 0.5 + (ip.x - W * 0.5) / max(sx, 0.01);
        ip.y = H * 0.5 + (ip.y - H * 0.5) / max(sy, 0.01);
    }

    float2 inPix = axis == 0 ? ip : ip.yx;
    if (fora || inPix.x < 0.0 || inPix.y < 0.0 || inPix.x > tam.x || inPix.y > tam.y) {
        __nv_out = float4(0.0);
        return __nv_out;
    }
    if (dePe) inPix.y = tam.y - inPix.y;
    __nv_out = inputImg.sample(__nv_smp, (inPix + inicio) / buf);
    return __nv_out;
}
