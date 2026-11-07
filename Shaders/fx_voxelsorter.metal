// ---------------------------------------------------------------------------
// Voxel Sorter
// origem : assets/effects/voxelsorter.xml
// id     : nova.effect.voxelsorter
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct voxelsorterParams {
    int depthSource;
    int invertDepth;
    float gridSize;
    float depthAmplitude;
    int fillMode;
    float voxelSize;
    int bevel;
    float depthFalloff;
    float saturation;
    float positionX;
    float positionY;
    float positionZ;
    float rotationX;
    float rotationY;
    float rotationZ;
    float blend;
};

// --- funcoes auxiliares do efeito
// Calibrados no benchmark (tools/voxelsorter/benchmark):
const float FOCO = 1.3889;          // o zoom da câmera padrão do AE, em larguras do quadro
const float ALTURA = 0.5;      // a coluna de brilho 1, em larguras do quadro

float2 tamanho() { return float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))); }

float brilho(float4 c) {
    float v = u.depthSource == 1 ? c.a : (c.r + c.g + c.b) / 3.0 * c.a;    // medido: a média dos três canais
    return u.invertDepth ? 1.0 - v : v;
}

/** A cor da célula (i, j) da grade. */
float4 celula(float2 ij, float2 celulas) { return grade.sample(__nv_smp, (ij + 0.5) / celulas); }

/**
 * A altura da coluna de brilho 1, em larguras do quadro. Medido: com Grid Size 512 (16:9) as colunas
 * param em 112 cubos, não em 256 — bate com um teto de 2^24 voxels na grade inteira (512 × 288 × 113),
 * arredondado para baixo de 16 em 16. Com 256 o teto não é alcançado (128 cubos, a metade da largura).
 */
float alturaMaxima() {
    float2 R = tamanho();
    float linhas = ceil(R.y * u.gridSize / R.x - 0.001);
    float teto = max(floor(16777216.0 / (u.gridSize * linhas) / 16.0) * 16.0, 16.0);
    return min(ALTURA, teto / u.gridSize);
}

/** Quantos cubos de profundidade a célula tem. */
float cubosDe(float4 c, float G) {
    return max(floor(brilho(c) * alturaMaxima() * G + 0.5), 1.0);
}

/** A altura (px) da coluna vizinha (0 fora da grade). */
float altDaVizinha(float2 ij, float2 celulas, float G, float lado, float propria) {
    if (ij.x < 0.0) return propria;
    // medido (e só isto): na borda DIREITA, a coluna de brilho máximo (branco puro) ganha parede até o fundo
    if (ij.x >= celulas.x) return propria >= alturaMaxima() * G * lado - 0.5 ? 0.0 : propria;
    if (ij.y < 0.0 || ij.y >= celulas.y) return propria;
    float4 c = celula(ij, celulas);
    return c.a > 0.01 ? cubosDe(c, G) * lado : propria;
}

float3x3 giro() {
    float3 a = radians(float3(u.rotationX, u.rotationY, u.rotationZ));
    float3 s = sin(a), c = cos(a);
    float3x3 rx = float3x3(1.0, 0.0, 0.0, 0.0, c.x, s.x, 0.0, -s.x, c.x);
    float3x3 ry = float3x3(c.y, 0.0, -s.y, 0.0, 1.0, 0.0, s.y, 0.0, c.y);
    float3x3 rz = float3x3(c.z, s.z, 0.0, -s.z, c.z, 0.0, 0.0, 0.0, 1.0);
    return rx * ry * rz;
}

fragment float4 fx_voxelsorter(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant voxelsorterParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> grade [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float2 R = tamanho();
    if (eng.acPass == 0) {
        __nv_out = inputImg.sample(__nv_smp, uv); return __nv_out;      // (o filtro linear já faz a média de 2 × 2)
    }

    float G = u.gridSize;
    float lado = R.x / G;                              // o cubo, em px da camada
    float2 celulas = float2(G, ceil(R.y / lado - 0.001));
    // Medido: a Depth Amplitude NÃO muda a altura das colunas (brilho 1 = metade da largura, sempre):
    // ela é a PERSPECTIVA. A distância da câmera é a do zoom padrão do AE (50 mm: 1,3889 larguras)
    // dividida por Amplitude/100 — com 0 a vista é ortográfica, negativa inverte a perspectiva.
    float amp = u.depthAmplitude / 100.0;
    // (com 0 o volume fica achatado no plano: uma escala mínima dá a vista paralela sem dividir por zero)
    float escalaZ = abs(amp) < 0.003 ? 0.003 : amp;
    float zMax = max(alturaMaxima() * G, 1.0) * lado;

    // O MUNDO: px da camada, +z para a câmera, a camada em z = 0. Sem câmera na composição, o olho
    // é o da câmera padrão do AE (zoom de 50 mm = 1,3889 larguras, no eixo do quadro) — conferido:
    // com a câmera padrão na comp o plugin dá exatamente a mesma imagem.
    float3 centro = float3(0.5 * R, 0.0);
    float3 olho, dir;
    if (eng.acCamera3D == 1) {
        float2 tela = __nv_acTela(uv);
        float4 longe = eng.acCameraInvVP * float4(tela.x * 2.0 - 1.0, 1.0 - tela.y * 2.0, 1.0, 1.0);
        float3 dn = longe.xyz / longe.w - eng.acCameraOlhoNova;          // mundo do Nova: Z para longe
        olho = float3(eng.acCameraOlho.xy, -eng.acCameraOlho.z) * eng.acEscalaDePixel;
        dir = float3(dn.xy, -dn.z);
    } else {
        olho = float3(0.5 * R, FOCO * R.x);
        dir = float3(uv * R, 0.0) - olho;
    }
    // O volume no mundo: gira em volta do centro da camada, DEPOIS a profundidade é multiplicada por
    // Amplitude/100 (é o que se mediu: a Amplitude não muda a altura das colunas na grade, estica o
    // eixo da câmera — 0 achata, negativa espelha), e por fim a World Position.
    float3x3 M = giro();
    // medido: World Position em % do quadro (X e Z pela largura, Y pela altura)
    float3 T = float3(u.positionX * R.x, u.positionY * R.y, -u.positionZ * R.x) / 100.0;
    float3 ow = olho - centro - T, dw = dir;
    ow.z /= escalaZ; dw.z /= escalaZ;
    float3 o = transpose(M) * ow + centro;
    float3 d = normalize(transpose(M) * dw);

    // a caixa da grade inteira
    float3 bmin = float3(0.0), bmax = float3(celulas * lado, zMax);
    float3 inv = 1.0 / (abs(d) + 1e-9) * sign(d + 1e-12);
    float3 t0 = (bmin - o) * inv, t1 = (bmax - o) * inv;
    float3 tn = min(t0, t1), tf = max(t0, t1);
    float tEntra = max(max(tn.x, tn.y), max(tn.z, 0.0)), tSai = min(tf.x, min(tf.y, tf.z));
    float4 saida = float4(0.0);
    if (tEntra < tSai) {
        float3 p = o + d * (tEntra + 1e-4);
        float2 ij = clamp(floor(p.xy / lado), float2(0.0), celulas - 1.0);
        float2 passo = sign(d.xy + 1e-12);
        float2 tDelta = abs(lado * inv.xy);
        float2 tProx = ((ij + max(passo, 0.0)) * lado - o.xy) * inv.xy;
        float t = tEntra;
        float3 normal = float3(0.0, 0.0, 1.0);
        // por qual face o raio entrou na caixa
        if (tEntra == tn.x) normal = float3(-passo.x, 0.0, 0.0); else if (tEntra == tn.y) normal = float3(0.0, -passo.y, 0.0);
        bool achou = false;
        float4 c = float4(0.0);
        float fracao = clamp(u.voxelSize / 100.0, 0.02, 1.0);
        for (int n = 0; n < 1100; n++) {
            if (ij.x < 0.0 || ij.y < 0.0 || ij.x >= celulas.x || ij.y >= celulas.y || t > tSai) break;
            c = celula(ij, celulas);
            float tFim = min(min(tProx.x, tProx.y), tSai);
            if (c.a > 0.01) {
                float h = cubosDe(c, G) * lado;
                // Skirt: a coluna só desce até a vizinha mais baixa (fecha os buracos da casca, sem
                // virar um bloco maciço). Surface: maciço até o fundo. Points: só o cubo de cima.
                float base = max(h - lado, 0.0);
                if (u.fillMode == 0) {
                    float m = h;
                    m = min(m, altDaVizinha(ij + float2(1.0, 0.0), celulas, G, lado, h));
                    m = min(m, altDaVizinha(ij - float2(1.0, 0.0), celulas, G, lado, h));
                    m = min(m, altDaVizinha(ij + float2(0.0, 1.0), celulas, G, lado, h));
                    m = min(m, altDaVizinha(ij - float2(0.0, 1.0), celulas, G, lado, h));
                    base = min(base, m);
                } else if (u.fillMode == 1) base = 0.0;
                // o trecho do raio com z dentro da coluna
                float ta = (base - o.z) / (d.z + sign(d.z + 1e-12) * 1e-9), tb = (h - o.z) / (d.z + sign(d.z + 1e-12) * 1e-9);
                float tzE = min(ta, tb), tzS = max(ta, tb);
                float e = max(t, tzE), s = min(tFim, tzS);
                if (e <= s) {
                    if (fracao > 0.995) {
                        if (tzE > t) normal = float3(0.0, 0.0, d.z < 0.0 ? 1.0 : -1.0);
                        t = e; achou = true; break;
                    }
                    // Size < 100: cada cubo encolhe em volta do próprio centro e a coluna vira uma pilha
                    // de cubos soltos — testa os cubos que o raio atravessa nesta célula, um a um.
                    float3 meio = float3((ij + 0.5) * lado, 0.0);
                    float k = floor((o.z + d.z * (e + 1e-3)) / lado);
                    for (int m = 0; m < 24; m++) {
                        if (k * lado >= h || (k + 1.0) * lado <= base) break;
                        float3 cc = float3(meio.xy, (k + 0.5) * lado);
                        float3 a0 = (cc - 0.5 * fracao * lado - o) * inv, a1 = (cc + 0.5 * fracao * lado - o) * inv;
                        float3 an = min(a0, a1), af = max(a0, a1);
                        float te = max(an.x, max(an.y, an.z)), ts = min(af.x, min(af.y, af.z));
                        if (te <= ts && ts >= t && te <= s + 1e-3) {
                            normal = te == an.x ? float3(-passo.x, 0.0, 0.0) : te == an.y ? float3(0.0, -passo.y, 0.0) : float3(0.0, 0.0, d.z < 0.0 ? 1.0 : -1.0);
                            t = max(te, t); achou = true; break;
                        }
                        k += d.z < 0.0 ? -1.0 : 1.0;
                    }
                    if (achou) break;
                }
            }
            // anda para a próxima célula
            if (tProx.x < tProx.y) { t = tProx.x; tProx.x += tDelta.x; ij.x += passo.x; normal = float3(-passo.x, 0.0, 0.0); }
            else { t = tProx.y; tProx.y += tDelta.y; ij.y += passo.y; normal = float3(0.0, -passo.y, 0.0); }
        }
        if (achou) {
            float3 q = o + d * t;
            float3 cor = c.rgb;
            // Saturation
            float y = dot(cor, float3(0.2126, 0.7152, 0.0722));
            cor = clamp(y + (cor - y) * (1.0 + u.saturation / 100.0), 0.0, 1.0);
            // A LUZ. Medido face a face em ~100 renders: é uma luz direcional presa ao MUNDO (vem de cima,
            // da direita e da frente), não ao volume — girar o volume muda a luz de cada face. Com a
            // Depth Amplitude perto de 0 sobra só a luz ambiente. Bevel desligado = a cor pura da célula.
            float luz = 1.0;
            if (u.bevel) {
                float difusa = max(dot(M * normal, float3(0.475, -0.394, 0.314)), 0.0) * clamp(abs(amp) / 1.4, 0.0, 1.0);
                luz = 0.568 + difusa;
            }
            // Bevel: a aresta de cada cubo escurece
            if (u.bevel) {
                float3 f = fract(q / lado);
                float3 borda = min(f, 1.0 - f) * lado;                 // px até a aresta, em cada eixo
                float2 nasFaces = abs(normal.z) > 0.5 ? borda.xy : abs(normal.x) > 0.5 ? borda.yz : borda.xz;
                float aresta = min(nasFaces.x, nasFaces.y);
                luz *= mix(0.935, 1.0, smoothstep(0.0, 0.065 * lado, aresta));
            }
            // Depth Falloff (medido: o fundo some — é o alfa que cai, não a cor que escurece)
            float some = mix(1.0, clamp(q.z / zMax, 0.0, 1.0), u.depthFalloff / 100.0);
            saida = float4(clamp(cor * luz, 0.0, 1.0), some);
        }
    }
    float4 orig = inputImg.sample(__nv_smp, uv);
    __nv_out = mix(orig, saida, u.blend / 100.0);
    return __nv_out;
}
