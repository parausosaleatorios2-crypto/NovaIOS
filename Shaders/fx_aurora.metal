// ---------------------------------------------------------------------------
// Aurora
// origem : assets/effects/aurora.xml
// id     : nova.effect.aurora
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct auroraParams {
    float warp;
    float amount;
    float scale;
    float auroraLength;
    float exposure;
    float auroraDetail;
    float curvature;
    float skyGlow;
    float4 auroraColor;
    float4 auroraColor2;
    float4 skyColor;
    float timeOffset;
    float speed;
    float stars;
    float starBrightness;
    float groundVisibility;
    float groundReflections;
    int useCamera;
    float iterations;
};

// --- funcoes auxiliares do efeito
// --------------------------------------------------------------- o plugin
// Nomes do original (Stormoid): tri, tri2, triNoise2d, aurora, u.stars, bg.

float tri(float x) { return clamp(abs(fract(x) - 0.5), 0.01, 0.49); }

float2 tri2(float2 p) { return float2(tri(p.x) + tri(p.y), tri(p.y + tri(p.x))); }

float2x2 mm2(float a) { float c = cos(a), s = sin(a); return float2x2(c, s, -s, c); }

const float2x2 M2 = float2x2(-0.95534, -0.29552, 0.29552, -0.95534);

/*
 * DESEMPENHO (06/10/2026: "travando bastante"). O que não muda dentro da marcha de 300
 * passos sai dela: a deformação (W), o tempo dela (tw), o número de oitavas e — o maior —
 * a rotação de cada oitava, que tem o MESMO ângulo na cena inteira e era recalculada
 * (seno + cosseno) a cada oitava de cada passo: 3 000 trigonométricas por pixel a menos.
 * A conta é a mesma (conferida de novo contra o AE, `tools/aurora/benchmark`).
 *
 * E o chão desligado (0.660.0): com Ground Reflections 0 a marcha da metade de baixo soma
 * zero (cada passo é multiplicado pelo reflexo) e não roda; com Ground Visibility 0 o passe
 * final não faz a água nem as estrelas do chão (sai multiplicado por zero). O buffer da marcha
 * continua cheio nesse caso: o céu logo acima do horizonte lê a metade de baixo dele pelo
 * filtro bilinear. Os mesmos pixels.
 */
float W_DEF;        // u.warp / 100
float TW_DEF;       // o tempo da deformação
float N_OITAVAS;    // u.auroraDetail × 0,05
float2x2 GIRO;          // mm2(giro) do ruído da aurora

/** O ruído triangular deformado. [rot] é a rotação de cada oitava (mm2 do ângulo). */
float triNoise2d(float2 p, float2x2 rot) {
    float W = W_DEF;
    float tw = TW_DEF;
    for (float k = 1.0; k < 5.0; k += 1.0) {
        float a = k * 1.5;
        float x = W * sin(a * p.y + tw) + p.x;
        p = float2(x, W * cos(a * x + tw) + p.y);
    }
    float z = 2.5, z2 = 1.8, rz = 0.0;
    float2 bp = p;
    for (float i = 0.0; i < N_OITAVAS; i += 1.0) {
        float2 dg = tri2(bp * 1.85) * 0.75;
        dg = dg * rot;
        p -= dg / z;
        z2 *= 0.42;
        float2 q = p * (1.21 + (rz - 1.0) * 0.02);
        p = q * M2;
        z *= 0.45;
        bp *= 2.3;
        rz += tri(q.x + tri(q.y)) * z2;
    }
    return rz;
}

float alfaDaAurora(float rz) {
    return max(clamp(1.0 / pow(rz * 29.0, 2.8 - u.amount / 100.0), 0.0, 0.55), 0.0);
}

/** A marcha pela aurora. [rdy] é |rd.y|; [refl] pondera o reflexo. */
float4 aurora(float3 ro, float3 rd, float rdy, float2 uv, float T, float refl) {
    float4 col = float4(0.0);
    float4 avg = float4(0.0);
    float iter = max(u.iterations, 1.0);
    float passo = 150.0 / iter;
    float dither = fract(sin(dot(uv, float2(12.9898, 4.1414))) * 43758.5469);
    float3 c1 = u.auroraColor.rgb;
    float3 c2x4 = u.auroraColor2.rgb * 4.0;
    for (float i = 0.0; i < iter; i += 1.0) {
        float pt = i * passo;
        float t = dither * -0.006 * smoothstep(0.0, 25.0, pt)
            + ((pow(pt, 1.5) * 0.002 * (u.auroraLength / 100.0) * passo + 0.9) - ro.y)
            / (rdy * 2.0 + u.curvature * 0.01);
        float2 p = (ro + rd * t).zx * (u.scale / 100.0) * 2.0;
        p = p * mm2(p.x * 0.06);
        float a = alfaDaAurora(triNoise2d(p, GIRO));
        float4 col2 = float4(mix(float3(0.0), mix(c1, c2x4, pt * 0.01) * 2.0, a), a);
        avg = mix(avg, col2, 0.5);
        col += avg * refl * exp2(-i * passo * 0.065 - 2.5) * smoothstep(0.0, 5.0, pt) * passo * (u.exposure / 100.0);
    }
    return col;
}

float3 estrelas(float3 p, float largura) {
    float3 c = float3(0.0);
    float n = u.stars * 0.1;
    for (float i = 0.0; i < n; i += 1.0) {
        float3 q = p * (0.15 * largura);
        uint3 id = uint3(int3(floor(q)));
        uint3 h = (id * uint3(374761393u, 1103515245u, 668265263u)) + id.zxy + id.yzx;
        h = h.yzx * (h.zxy ^ (h >> 3u));
        float3 rn = float3(h ^ (h >> 16u)) * 2.3283064365386962890625e-10;
        p *= 1.3;
        c += (mix(float3(1.0, 0.49, 0.1), float3(0.75, 0.9, 1.0), rn.y) * 0.1 + 0.9)
            * ((1.0 - smoothstep(0.0, 0.6, length(fract(q) - 0.5))) * step(rn.x, i * i * 0.001 + 0.0005));
    }
    return c;
}

float3 ceu(float3 rd, float fade) {
    float3 c1335 = mix(u.auroraColor.rgb, u.auroraColor2.rgb * 4.0, 0.1);
    float h = pow(-rd.y * 1.1 + 1.1, 11.0) * (u.skyGlow / 100.0);
    return mix(u.skyColor.rgb, c1335, h) * 0.63 * fade;
}

fragment float4 fx_aurora(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant auroraParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> auroraBuf [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float2 res = eng.acResolution;
    float esc = max(eng.acEscalaDePixel, 1e-4);
    float largura = res.x / esc;   // a largura do AE (px da composição)
    float T = eng.acTime;
    W_DEF = u.warp / 100.0;
    TW_DEF = 0.1 * T * (u.speed * 0.01) + u.timeOffset / 100.0;
    N_OITAVAS = u.auroraDetail * 0.05;
    GIRO = mm2(T * (u.speed * 0.1) * 0.06 + u.timeOffset / 100.0);

    float3 ro;
    float3 rd;
    if (u.useCamera && eng.acCamera3D == 1) {
        // A câmera da composição, em coordenadas do AE (origem no canto, Y para
        // baixo), e o raio deste pixel na TELA; o plugin vira o Y.
        float2 tela = __nv_acTela(in.acScreenNorm);
        float4 longe = eng.acCameraInvVP * float4(tela.x * 2.0 - 1.0, 1.0 - tela.y * 2.0, 1.0, 1.0);
        float3 dir = normalize(longe.xyz / longe.w - eng.acCameraOlhoNova);
        ro = eng.acCameraOlho * 0.0001;
        ro.y = -ro.y;
        rd = float3(dir.x, -dir.y, dir.z);
    } else {
        float2 q = uv - 0.5;
        rd = normalize(float3(q.x * (res.x / res.y), q.y, 1.3));
        rd.y = -rd.y;
        ro = float3(0.0, 0.0, -0.7);
    }

    float rdy = abs(rd.y);
    float fade = smoothstep(0.0, 0.01, rdy) * 0.1 + 0.9;

    // Passe 0: só a marcha da aurora (já com o corte do smoothstep: cabe em 0..1).
    if (eng.acPass == 0) {
        float4 aurBuf;
        if (rd.y > 0.0) {
            aurBuf = smoothstep(float4(0.0), float4(1.5), aurora(ro, rd, rd.y, uv, T, 1.0) * clamp(rd.y * 15.0 + 0.4, 0.0, 1.0) * 1.8) * fade;
        } else if (u.groundReflections == 0.0) {
            aurBuf = float4(0.0);     // o reflexo soma zero: cada passo da marcha seria multiplicado por 0
        } else {
            float3 rrBuf = float3(rd.x, rdy, rd.z);
            aurBuf = smoothstep(float4(0.0), float4(2.5), aurora(ro, rrBuf, rdy, uv, T, u.groundReflections / 100.0) * clamp(rdy * 15.0 + 0.4, 0.0, 1.0) * 1.8);
        }
        __nv_out = clamp(aurBuf, 0.0, 1.0);
        return __nv_out;
    }
    float4 aur = auroraBuf.sample(__nv_smp, uv);

    float3 col;
    if (rd.y > 0.0) {
        float3 s = estrelas(rd, largura);
        col = (ceu(rd, fade) + s * s * (u.starBrightness / 100.0)) * (1.0 - aur.w) + aur.xyz;
    } else if (u.groundVisibility == 0.0) {
        col = float3(0.0);            // o chão inteiro sai multiplicado por zero
    } else {
        float3 rr = float3(rd.x, rdy, rd.z);
        float3 s = estrelas(rr, largura);
        float2 pl = (ro + rr * ((0.5 - ro.y) / rdy)).xz * float2(0.5, 0.7);
        pl = pl * mm2(pl.x * 0.06);
        float rz2 = triNoise2d(pl, mm2(u.timeOffset / 100.0));
        float3 agua = mix(u.skyColor.rgb * 0.08, float3(0.21, 0.21, 0.35), alfaDaAurora(rz2) * 0.4);
        col = ((ceu(rr, fade) * 0.6 + s * s * (u.starBrightness / 100.0) * 0.1) * (1.0 - aur.w) + aur.xyz + agua)
            * (u.groundVisibility / 100.0);
    }
    // A camada fica por baixo do céu opaco: lida só para o efeito ter entrada.
    float4 fonte = inputImg.sample(__nv_smp, uv);
    __nv_out = float4(clamp(col, 0.0, 1.0), 1.0) + fonte * 0.0;
    return __nv_out;
}
