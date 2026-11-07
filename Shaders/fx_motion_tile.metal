// ---------------------------------------------------------------------------
// Ladrilho de movimento
// origem : assets/effects/motion-tile.xml
// id     : nova.effect.motiontile
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct motion_tileParams {
    float2 tileCenter;
    float tileWidth;
    float tileHeight;
    float outputWidth;
    float outputHeight;
    int mirrorEdges;
    float phase;
    int horizontalPhase;
};

// --- funcoes auxiliares do efeito
// O índice inteiro para baixo (o `/` de int arredonda para o zero, e à esquerda os índices são negativos).
int divBaixo(int a, int b) { return a >= 0 ? a / b : -((-a - 1) / b) - 1; }

// Índice GLOBAL de pixel da camada (pode ser de um ladrilho vizinho) -> o pixel dentro dela, com o espelho.
int dobrar(int g, int n, out int ladrilho) {
    ladrilho = divBaixo(g, n);
    int q = g - ladrilho * n;
    if (u.mirrorEdges && (ladrilho & 1) != 0) q = n - 1 - q;
    return q;
}

int2 inicioDaCamada;
float4 texel(int qx, int qy) {
    float4 c = inputImg.read(uint2(inicioDaCamada + int2(qx, qy)), uint(0));
    return float4(c.rgb * c.a, c.a);
}

fragment float4 fx_motion_tile(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant motion_tileParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // A CAMADA dentro do buffer (`eng.acCamada`, centrada), em pixels inteiros. Num grupo e numa camada de ajuste o
    // buffer é a camada.
    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 N = clamp(int2(floor(max(eng.acCamada, float2(0.001)) * float2(T) + 0.5)), int2(1), T);
    inicioDaCamada = (T - N) / 2;
    float2 Nf = float2(N);
    // `xL`: este pixel em px da camada (de 0 a N por dentro, além disso por fora).
    float2 xL = in.acScreenNorm * float2(T) - float2(inicioDaCamada);

    // O campo de saída, em volta do centro da camada: fora dele, nada. A saída NÃO muda o tamanho do que está
    // dentro — acima de 100% ela só ladrilha além da borda, como no AE.
    float2 saida = float2(u.outputWidth, u.outputHeight) * 0.01;
    if (any(greaterThan(abs(xL / Nf - 0.5), saida * 0.5))) {
        __nv_out = float4(0.0);
        return __nv_out;
    }

    // As 4 amostras do AE, as mesmas do compositor (`EngineShaders.LADRILHO_FRAGMENT`), lendo a própria camada:
    // amostra linear no centro do pixel que JUNTA o ladrilho vizinho na emenda (sem linha, também com o centro
    // fracionado), o ímpar espelhado, e a Phase da coluna (ou fileira) de cada amostra. O sentido da Phase (o
    // desenho da coluna ímpar DESCE) foi medido no AE: tools/motiontile/benchmark. Com o ladrilho menor que 100%
    // o AE reduz a camada por área antes; aqui a leitura é direta (isso é o passe do compositor).
    float2 tam = max(float2(u.tileWidth, u.tileHeight) * 0.01 * Nf, float2(1e-3));   // o ladrilho, em px da camada
    float2 pxR = tam / Nf;                                                   // um pixel da camada no ladrilho
    float2 org = u.tileCenter * Nf - tam * 0.5;                                // o canto do ladrilho 0
    float fase = u.phase / 360.0;
    float4 c = float4(0.0);
    if (!u.horizontalPhase) {
        float ux = (xL.x - org.x) / pxR.x - 0.5;
        float gx = floor(ux); float fx = ux - gx;
        for (int a = 0; a < 2; a++) {
            int kx; int qx = dobrar(int(gx) + a, N.x, kx);
            float wx = a == 0 ? 1.0 - fx : fx;
            float desloc = (kx & 1) != 0 ? fase * tam.y : 0.0;
            float vy = (xL.y - org.y - desloc) / pxR.y - 0.5;
            float gy = floor(vy); float fy = vy - gy;
            int k0; int k1;
            int q0 = dobrar(int(gy), N.y, k0);
            int q1 = dobrar(int(gy) + 1, N.y, k1);
            c += wx * ((1.0 - fy) * texel(qx, q0) + fy * texel(qx, q1));
        }
    } else {
        float vy = (xL.y - org.y) / pxR.y - 0.5;
        float gy = floor(vy); float fy = vy - gy;
        for (int b = 0; b < 2; b++) {
            int ky; int qy = dobrar(int(gy) + b, N.y, ky);
            float wy = b == 0 ? 1.0 - fy : fy;
            float desloc = (ky & 1) != 0 ? fase * tam.x : 0.0;
            float ux = (xL.x - org.x - desloc) / pxR.x - 0.5;
            float gx = floor(ux); float fx = ux - gx;
            int k0; int k1;
            int q0 = dobrar(int(gx), N.x, k0);
            int q1 = dobrar(int(gx) + 1, N.x, k1);
            c += wy * ((1.0 - fx) * texel(q0, qy) + fx * texel(q1, qy));
        }
    }
    __nv_out = c.a > 0.0 ? float4(c.rgb / c.a, c.a) : float4(0.0);
    return __nv_out;
}
