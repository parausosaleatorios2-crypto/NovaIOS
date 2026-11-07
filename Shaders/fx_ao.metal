// ---------------------------------------------------------------------------
// Oclusão de ambiente
// origem : assets/effects/ao.xml
// id     : nova.effect.ao
// passes : 5
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct aoParams {
    int invertDepth;
    float aoIntensity;
    float aoRadius;
    float sceneDepth;
    float4 aoColor;
    int aoOutput;
    float aoContrast;
    int aoFalloff;
    float aoBias;
    int contactAo;
    float contactStrength;
    int aoQuality;
    float fieldOfView;
    int aoView;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265359;

/** O mapa naquele ponto, 0 (longe) a 1 (perto). */
static float lerMapa(float2 uv) {
    float v = dot(depthMap.sample(__nv_smp, uv).rgb, float3(0.299, 0.587, 0.114));
    return u.invertDepth ? 1.0 - v : v;
}

// ------------------------------------------------ a superfície reconstruída

static int2 tamanhoCheio() {
    return int2(int(dispBuf.get_width()), int(dispBuf.get_height()));
}

/** A disparidade refinada (passe 0), desempacotada. Sempre por texel inteiro. */
static float disparidadeEm(int2 p) {
    int2 t = tamanhoCheio();
    float4 v = dispBuf.read(uint2(clamp(p, int2(0), t - 1)), uint(0));
    return v.r + v.g / 255.0;
}

/** Disparidade -> distância. Ver o cabeçalho. */
static float distanciaEm(int2 p) {
    float r = max(u.sceneDepth, 1.0001);
    return 1.0 / (1.0 / r + disparidadeEm(p) * (1.0 - 1.0 / r));
}

static float tangenteDoCampo() {
    return tan(radians(clamp(u.fieldOfView, 1.0, 170.0)) * 0.5);
}

/** O ponto 3D atrás do pixel p. Câmera na origem, olhando para +z. */
static float3 posicaoEm(int2 p) {
    float2 t = float2(tamanhoCheio());
    float2 uv = (float2(p) + 0.5) / t;
    float z = distanciaEm(p);
    float th = tangenteDoCampo();
    return float3((uv.x * 2.0 - 1.0) * z * th * (t.x / t.y), (uv.y * 2.0 - 1.0) * z * th, z);
}

/** Onde, na tela (0..1), cai um ponto 3D. */
static float2 projetar(float3 q) {
    float2 t = float2(tamanhoCheio());
    float th = tangenteDoCampo();
    return float2(q.x / (q.z * th * (t.x / t.y)), q.y / (q.z * th)) * 0.5 + 0.5;
}

static int2 texelCheio(float2 uv) {
    return int2(uv * float2(tamanhoCheio()));
}

/**
 * A normal por diferença de UM LADO só em cada eixo — o lado de menor salto de
 * profundidade. A diferença central atravessa dois objetos na borda e entorta a
 * normal: é daí que vem o contorno escuro.
 */
static float3 normalEm(int2 p) {
    float3 c = posicaoEm(p);
    float3 xm = posicaoEm(p - int2(1, 0));
    float3 xp = posicaoEm(p + int2(1, 0));
    float3 ym = posicaoEm(p - int2(0, 1));
    float3 yp = posicaoEm(p + int2(0, 1));
    float3 dx = abs(xp.z - c.z) < abs(c.z - xm.z) ? xp - c : c - xm;
    float3 dy = abs(yp.z - c.z) < abs(c.z - ym.z) ? yp - c : c - ym;
    float3 n = normalize(cross(dx, dy));
    // Virada para a câmera (que está na origem).
    return dot(n, -c) < 0.0 ? -n : n;
}

/** O salto relativo de profundidade em volta de p: grande = borda de objeto. */
static float saltoEm(int2 p) {
    float z = distanciaEm(p);
    float m = max(
        max(abs(distanciaEm(p + int2(1, 0)) - z), abs(distanciaEm(p - int2(1, 0)) - z)),
        max(abs(distanciaEm(p + int2(0, 1)) - z), abs(distanciaEm(p - int2(0, 1)) - z))
    );
    return m / max(z, 1e-4);
}

// --------------------------------------------------------------- o estimador

static float bayer4(int2 p) {
    int i = (p.y & 3) * 4 + (p.x & 3);
    const float M[16] = float[16](
         0.0,  8.0,  2.0, 10.0,
        12.0,  4.0, 14.0,  6.0,
         3.0, 11.0,  1.0,  9.0,
        15.0,  7.0, 13.0,  5.0
    );
    return (M[i] + 0.5) / 16.0;
}

/**
 * A amostra i de n do kernel, no hemisfério z >= 0, concentrada perto do
 * centro (escala de 0,1 a 1 pelo quadrado do índice). Espiral dourada com peso
 * de cosseno: determinística, sem tabela.
 */
static float3 amostraDoKernel(int i, int n, float semente) {
    float t = (float(i) + 0.5) / float(n);
    float fi = float(i) * 2.39996323 + semente;
    float cosT = sqrt(1.0 - t * 0.95);
    float sinT = sqrt(max(0.0, 1.0 - cosT * cosT));
    float escala = mix(0.1, 1.0, t * t);
    return float3(cos(fi) * sinT, sin(fi) * sinT, cosT) * escala;
}

static float pesoDaQueda(float t) {
    if (u.aoFalloff == 0) return 1.0 - 0.75 * t;
    if (u.aoFalloff == 2) return exp(-2.5 * t);
    return 1.0 - 0.75 * t * t * (3.0 - 2.0 * t);
}

static float ocluir(float3 P, float3x3 tbn, float raio, int n, float semente) {
    float occ = 0.0;
    float total = 0.0;
    for (int i = 0; i < 32; i++) {
        if (i >= n) break;
        float3 k = amostraDoKernel(i, n, semente);
        float peso = pesoDaQueda(clamp(length(k), 0.0, 1.0));
        total += peso;

        float3 Q = P + tbn * k * raio;
        if (Q.z <= 0.0) continue;
        float2 suv = projetar(Q);
        if (suv.x < 0.0 || suv.y < 0.0 || suv.x > 1.0 || suv.y > 1.0) continue;
        float zCena = distanciaEm(texelCheio(suv));

        // Alcance: cai com a distância entre o ponto e a superfície achada.
        float alcance = smoothstep(0.0, 1.0, raio / max(abs(P.z - zCena), 1e-4));
        // Bloqueada: a cena está NA FRENTE da amostra.
        occ += (zCena <= Q.z - u.aoBias ? 1.0 : 0.0) * alcance * peso;
    }
    return total > 0.0 ? occ / total : 0.0;
}

static int amostrasDaQualidade() {
    if (u.aoQuality == 0) return 8;
    if (u.aoQuality == 2) return 16;
    if (u.aoQuality == 3) return 24;
    return 12;
}

static int amostrasDeContato() {
    if (!u.contactAo || u.contactStrength <= 0.0 || u.aoQuality == 0) return 0;
    return u.aoQuality == 3 ? 8 : 4;
}

// ------------------------------------------------------------------ limpeza

static float aoEm(sampler2D fonte, int2 q) {
    int2 t = int2(int(fonte.get_width()), int(fonte.get_height()));
    return fonte.read(uint2(clamp(q, int2(0), t - 1)), uint(0)).r;
}

/** A distância na superfície embaixo do texel q de um buffer de meia resolução. */
static float distanciaDoTexelReduzido(int2 q, int2 tamanhoReduzido) {
    float2 uv = (float2(q) + 0.5) / float2(tamanhoReduzido);
    return distanciaEm(texelCheio(uv));
}

static float limpar(sampler2D fonte, int2 direcao) {
    int2 t = int2(int(fonte.get_width()), int(fonte.get_height()));
    int2 q0 = int2(in.acScreenNorm * float2(t));
    float z0 = distanciaDoTexelReduzido(q0, t);
    float tolerancia = max(u.aoRadius * 0.5, z0 * 0.02);
    float soma = 0.0;
    float peso = 0.0;
    // 4 texels: a largura exata do ruído 4×4.
    for (int i = -2; i < 2; i++) {
        int2 q = q0 + direcao * i;
        float z = distanciaDoTexelReduzido(q, t);
        float w = exp(-abs(z - z0) / tolerancia);
        soma += aoEm(fonte, q) * w;
        peso += w;
    }
    return peso > 1e-4 ? soma / peso : aoEm(fonte, q0);
}

/** A ampliação ao tamanho cheio, pesando os 4 texels reduzidos pela profundidade. */
static float ampliar(sampler2D fonte) {
    int2 t = int2(int(fonte.get_width()), int(fonte.get_height()));
    float2 base = in.acScreenNorm * float2(t) - 0.5;
    int2 q0 = int2(floor(base));
    float2 f = fract(base);
    float z0 = distanciaEm(texelCheio(in.acScreenNorm));
    float tolerancia = max(u.aoRadius * 0.25, z0 * 0.01);
    float soma = 0.0;
    float peso = 0.0;
    for (int j = 0; j < 2; j++) {
        for (int i = 0; i < 2; i++) {
            int2 q = q0 + int2(i, j);
            float bi = (i == 0 ? 1.0 - f.x : f.x) * (j == 0 ? 1.0 - f.y : f.y);
            float w = (bi + 1e-3) * exp(-abs(distanciaDoTexelReduzido(q, t) - z0) / tolerancia);
            soma += aoEm(fonte, q) * w;
            peso += w;
        }
    }
    return peso > 1e-5 ? soma / peso : aoEm(fonte, q0);
}

// --------------------------------------------------------------------- main

fragment float4 fx_ao(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant aoParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> dispBuf [[texture(1)]],
    texture2d<float> aoRaw [[texture(2)]],
    texture2d<float> aoBlurH [[texture(3)]],
    texture2d<float> aoBlurV [[texture(4)]],
    texture2d<float> depthMap [[texture(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // 0. A reconstrução: o mapa guiado pela cor, empacotado em 16 bits.
    if (eng.acPass == 0) {
        float3 c0 = inputImg.sample(__nv_smp, in.acScreenNorm).rgb;
        float soma = 0.0;
        float peso = 0.0;
        for (int j = -2; j <= 2; j++) {
            for (int i = -2; i <= 2; i++) {
                float2 uv = in.acScreenNorm + float2(float(i), float(j)) * 2.0 * eng.acTexelSize;
                float3 c = inputImg.sample(__nv_smp, uv).rgb - c0;
                float w = exp(-dot(c, c) * 40.0) * exp(-float(i * i + j * j) / 8.0);
                soma += lerMapa(uv) * w;
                peso += w;
            }
        }
        float d = clamp(soma / max(peso, 1e-5), 0.0, 1.0);
        float alto = floor(d * 255.0) / 255.0;
        __nv_out = float4(alto, fract(d * 255.0), 0.0, 1.0);
        return __nv_out;
    }

    // 1. O AO, em meia resolução.
    if (eng.acPass == 1) {
        int2 p = texelCheio(in.acScreenNorm);
        float3 P = posicaoEm(p);
        float3 n = normalEm(p);
        float ang = bayer4(int2(__nv_fragCoord.xy)) * 2.0 * PI;
        float3 giro = float3(cos(ang), sin(ang), 0.0);
        float3 t = giro - n * dot(giro, n);
        if (dot(t, t) < 1e-4) {
            giro = float3(0.0, cos(ang), sin(ang));
            t = giro - n * dot(giro, n);
        }
        t = normalize(t);
        float3x3 tbn = float3x3(t, cross(n, t), n);

        float ao = 1.0 - ocluir(P, tbn, u.aoRadius, amostrasDaQualidade(), 0.0);
        int nContato = amostrasDeContato();
        if (nContato > 0) {
            float contato = 1.0 - ocluir(P, tbn, u.aoRadius * 0.125, nContato, 1.3);
            ao = min(ao, mix(1.0, contato, u.contactStrength));
        }

        // Confiança: perto de borda de objeto e onde o alfa é baixo, menos AO.
        float borda = smoothstep(0.08, 0.25, saltoEm(p));
        float alfa = smoothstep(0.0, 0.5, inputImg.sample(__nv_smp, in.acScreenNorm).a);
        ao = mix(1.0, ao, (1.0 - borda) * alfa);
        __nv_out = float4(ao, ao, ao, 1.0);
        return __nv_out;
    }

    // 2. e 3. A limpeza separável.
    if (eng.acPass == 2) {
        float v = limpar(aoRaw, int2(1, 0));
        __nv_out = float4(v, v, v, 1.0);
        return __nv_out;
    }
    if (eng.acPass == 3) {
        float v = limpar(aoBlurH, int2(0, 1));
        __nv_out = float4(v, v, v, 1.0);
        return __nv_out;
    }

    // 4. Aplicar.
    float4 src = inputImg.sample(__nv_smp, in.acScreenNorm);
    int2 p = texelCheio(in.acScreenNorm);

    if (u.aoView == 1) {
        __nv_out = float4(float3(disparidadeEm(p)), src.a);
        return __nv_out;
    }
    if (u.aoView == 2) {
        __nv_out = float4(normalEm(p) * 0.5 + 0.5, src.a);
        return __nv_out;
    }
    if (u.aoView == 3) {
        __nv_out = float4(float3(aoRaw.sample(__nv_smp, in.acScreenNorm).r), src.a);
        return __nv_out;
    }

    float ao = ampliar(aoBlurV);
    if (u.aoView == 4) {
        __nv_out = float4(float3(ao), src.a);
        return __nv_out;
    }

    ao = pow(clamp(ao, 0.0, 1.0), u.aoContrast);
    float escurecer = clamp((1.0 - ao) * u.aoIntensity, 0.0, 1.0);

    if (u.aoView == 5) {
        __nv_out = float4(float3(escurecer), src.a);
        return __nv_out;
    }

    // "Só o AO": em cinza, para compor com Multiplicar — o jeito de quem vem do
    // After Effects. Opaco onde a camada existe.
    if (u.aoOutput == 1) {
        __nv_out = float4(float3(1.0 - escurecer), src.a);
        return __nv_out;
    }

    // Só o RGB: alfa direto, intacto.
    float3 cor = mix(float3(1.0), u.aoColor.rgb, escurecer * u.aoColor.a);
    __nv_out = float4(src.rgb * cor, src.a);
    return __nv_out;
}
