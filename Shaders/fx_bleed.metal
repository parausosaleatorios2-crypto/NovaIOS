// ---------------------------------------------------------------------------
// Sangue escorrendo
// origem : assets/effects/bleed.xml
// id     : nova.effect.bleed
// passes : 16
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bleedParams {
    float4 objectColor;
    float4 bloodColor;
    float density;
    float pressure;
    float randomSeed;
    float completion;
    float angle;
    float feather;
    float bevelOpacity;
    int bevelType;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265358979;

// Tudo no template é em pixels de uma comp 1920×1080: `K` é quantos pixels da imagem valem um desses.
float2 tamanhoCheio() { return float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))); }
float K() { float2 r = tamanhoCheio(); return min(r.x / 1920.0, r.y / 1080.0); }
/** Um pixel de referência, em UV. */
float2 px() { return K() / tamanhoCheio(); }
bool dentro(float2 uv) { return uv.x >= 0.0 && uv.y >= 0.0 && uv.x <= 1.0 && uv.y <= 1.0; }
/** O alfa da forma (0 fora do quadro). */
float forma(float2 uv) { return dentro(uv) ? inputImg.sample(__nv_smp, uv).a : 0.0; }
float media(float3 c) { return (c.r + c.g + c.b) / 3.0; }

float h1(float2 p) { float3 q = fract(float3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float3 h3(float3 p) { p = fract(p * float3(0.1031, 0.1030, 0.0973)); p += dot(p, p.yxz + 33.33); return fract((p.xxy + p.yxx) * p.zyx); }

// ------------------------------------------------------------------ 0: o estêncil
// Medido: Minimax (máximo vertical, raio 500) + Offset de 500 para baixo = o máximo do alfa nos
// 1000 px ACIMA do pixel. As gotas só existem nas colunas da forma, dela para baixo.
float estencil() {
    float2 p = px();
    float m = 0.0;
    for (int i = 0; i <= 125; i++) m = max(m, forma(in.acScreenNorm - float2(0.0, float(i) * 8.0 * p.y)));
    return m;
}

// ------------------------------------------------------------------ 1: as gotas
// O CC Particle World do template, medido em 90 quadros seguidos: ~110 gotas por segundo no quadro
// (Density 25), nascendo entre 70 e 720 px de altura, caindo com 576 px/s² (× Pressure/25) a partir de
// −40 px/s; cada uma é um risco de ~25 × 205 px (× 0,5 a 1,5) com a ponta redonda embaixo, que
// clareia para cima e aparece aos poucos (opacidade 0,62 → 1 em 0,75 s). O tempo do mapa anda a
// Pressure/25. O sorteio do plugin não é público: batem a quantidade, o tamanho, a forma e a queda.
float gota(float2 d, float larg, float alt) {
    // d: do centro da ponta redonda, em px de referência (y para baixo)
    float u = d.x / larg;
    float v = 0.94 + d.y / alt;
    float cauda = exp(-0.5 * u * u / (0.18 * 0.18)) * (0.07 + 0.8 * v) * smoothstep(0.0, 0.03, v) * (1.0 - smoothstep(0.93, 0.99, v));
    float rh = 0.36 * larg;
    float ponta = 0.89 * (1.0 - smoothstep(0.55 * rh, 1.3 * rh, length(d)));
    return max(cauda, ponta);
}

float gotasQueCaem() {
    float k = K();
    float2 P = in.acScreenNorm * tamanhoCheio() / k;          // px de referência
    float a = 576.0 * max(u.pressure, 0.0) / 25.0;
    if (a <= 0.0 || u.density <= 0.0) return 0.0;
    float tau = eng.acTime * u.pressure / 25.0;
    float T = clamp(sqrt(2.0 * 1150.0 / a) + 0.3, 1.0, 4.0);   // quanto a gota leva para sair do quadro
    const float CW = 48.0;
    float quantas = min(2.75 * T * u.density / 25.0, 24.0);     // gotas vivas por faixa de 48 px
    float c0 = floor(P.x / CW);
    float resto = 1.0;
    for (int dc = -1; dc <= 1; dc++) {
        float c = c0 + float(dc);
        for (int s = 0; s < 24; s++) {
            if (float(s) >= quantas) break;
            float2 id = float2(c, float(s) + 31.0 * u.randomSeed);
            if (float(s) + 1.0 > quantas && h1(id + 7.7) > fract(quantas)) continue;
            float fase = tau / T + h1(id);
            float n = floor(fase);
            float idade = (fase - n) * T;
            float3 r = h3(float3(id, n) + 0.37);
            float tam = 0.5 + r.z;
            float larg = 25.0 * tam;
            float alt = 205.0 * tam * (1.0 + 0.17 * idade);
            float2 cab = float2((c + r.x) * CW, mix(70.0, 720.0, r.y) - 40.0 * idade + 0.5 * a * idade * idade);
            float2 d = P - cab;
            if (abs(d.x) > 0.6 * larg || d.y > 0.5 * larg || d.y < -alt) continue;
            float op = min(1.0, 0.62 + 0.5 * idade) * (1.0 - smoothstep(T - 0.15, T, idade));
            resto *= 1.0 - op * gota(d, larg, alt);
        }
    }
    return 1.0 - resto;
}

// ------------------------------------------------------------------ borrões gaussianos
// Medido no AE: Gaussian Blur com Blurriness B = gaussiana de σ = 0,283·B px; o Map Softness dos
// efeitos CC (Vector Blur, Glass) = σ de 0,4 × Softness; o Size do Satin (14) = σ 6.
float peso(float i, float n) { float x = 3.0 * i / n; return exp(-0.5 * x * x); }

/** Borrão de um canal de `t` ao longo de `eixo` (UV por px de referência), σ em px de referência. */
float4 borrar(sampler2D t, float2 eixo, float4 sigma) {
    const float N = 20.0;
    float4 soma = float4(0.0); float total = 0.0;
    for (float i = -N; i <= N; i += 1.0) {
        float w = peso(i, N);
        float4 desloc = 3.0 * sigma * i / N;
        soma.r += w * t.sample(__nv_smp, clamp(in.acScreenNorm + eixo * desloc.r, 0.0, 1.0)).r;
        soma.g += w * t.sample(__nv_smp, clamp(in.acScreenNorm + eixo * desloc.g, 0.0, 1.0)).g;
        soma.b += w * t.sample(__nv_smp, clamp(in.acScreenNorm + eixo * desloc.b, 0.0, 1.0)).b;
        soma.a += w * t.sample(__nv_smp, clamp(in.acScreenNorm + eixo * desloc.a, 0.0, 1.0)).a;
        total += w;
    }
    return soma / total;
}

// ------------------------------------------------------------------ CC Vector Blur
// Medido (Type "Direction Fading", sem Vector Map): cada pixel JUNTA a imagem ao longo de uma reta de
// `Amount` px, com peso que cai em linha reta até zero; a direção da reta é o brilho do próprio
// pixel — a média (R+G+B)/3 da cor premultiplicada, borrada pelo Map Softness — virado em ângulo
// (0 = para cima, 1 = uma volta, horário). Fora da forma o brilho é 0 e a reta sobe: a forma
// "escorre" para baixo. Dentro, a cor do sangue decide para que lado: por isso a cor muda o desenho.
float2 direcao(float brilho) { float th = 2.0 * PI * brilho; return float2(sin(th), -cos(th)); }

/** O alfa da camada Drops antes do segundo Vector Blur: 50% do borrão 500 sobre forma × borrão(1 − forma). */
float2 antesDoSegundo(float2 uv) {
    if (!dentro(uv)) return float2(0.0);
    float v = 0.5 * v1.sample(__nv_smp, uv).r;
    float d3 = inputImg.sample(__nv_smp, uv).a * b1.sample(__nv_smp, uv).r;
    return float2(v + d3 * (1.0 - v), v);      // (alfa, quanto dele é sangue)
}

// ------------------------------------------------------------------ Linear Wipe
// Medido: a transição fica a `u.completion`% do caminho entre o primeiro e o último canto do quadro na
// direção do ângulo, e a faixa suave tem 4/3 do Feather.
float wipe(float2 uv) {
    float k = K();
    float2 q = tamanhoCheio() / k;                     // o quadro, em px de referência
    float a = radians(u.angle);
    float2 u = float2(sin(a), -cos(a));
    float t = dot(uv * q, u);
    float t0 = min(min(0.0, q.x * u.x), min(q.y * u.y, dot(q, u)));
    float t1 = max(max(0.0, q.x * u.x), max(q.y * u.y, dot(q, u)));
    float tc = mix(t0, t1, u.completion / 100.0);
    return clamp((t - tc) / max(u.feather * 4.0 / 3.0, 0.001) + 0.5, 0.0, 1.0);
}

// ------------------------------------------------------------------ a camada Bevel
// Medido: Calculations 1 = a forma na Object Color a 50%; Calculations 2 junta a camada Drops com a
// opacidade do Bevel Opacity e o modo do Bevel Type (Copy, Lighten, Darken, Stencil Alpha, Stencil
// Luma); fora da forma a cor reta da camada é BRANCA (é o que o Lighten e o Darken enxergam).
float4 camadaBevel(float2 uv) {
    float s = forma(uv);
    float4 g = dentro(uv) ? gotas.sample(__nv_smp, uv) : float4(0.0);
    float op = clamp(u.bevelOpacity / 100.0, 0.0, 1.0);
    float D = g.r;
    float3 cd = u.bloodColor.rgb * g.b;                  // a cor reta das gotas
    float3 ca = mix(float3(1.0), u.objectColor.rgb, clamp(s * 60.0, 0.0, 1.0));
    float aa = 0.5 * s;
    float4 apm = float4(u.objectColor.rgb * aa, aa);
    if (u.bevelType == 0) return float4(apm.rgb * (1.0 - op * D) + cd * op * D, op * D + aa * (1.0 - op * D));
    if (u.bevelType == 1) { float al = aa + op * D - aa * op * D; return float4(mix(ca, max(ca, cd), op) * al, al); }
    if (u.bevelType == 2) { float al = D * op; return float4(mix(ca, min(ca, cd), op) * al, al); }
    if (u.bevelType == 3) return apm * mix(1.0, D, op);
    return apm * mix(1.0, dot(cd * D, float3(0.299, 0.587, 0.114)), op);
}

/** O Satin dos estilos de camada: 1 − |borrão(alfa)(p + d) − borrão(alfa)(p − d)|, d = 11 px no ângulo. */
float satin(float graus, int canal) {
    float a = radians(graus);
    float2 d = 11.0 * float2(cos(a), -sin(a)) * px();
    float4 m = e1.sample(__nv_smp, clamp(in.acScreenNorm + d, 0.0, 1.0)), n = e1.sample(__nv_smp, clamp(in.acScreenNorm - d, 0.0, 1.0));
    return 1.0 - abs(canal == 0 ? m.r - n.r : m.g - n.g);
}

fragment float4 fx_bleed(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bleedParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> est [[texture(1)]],
    texture2d<float> mapa [[texture(2)]],
    texture2d<float> b1h [[texture(3)]],
    texture2d<float> b1 [[texture(4)]],
    texture2d<float> v1 [[texture(5)]],
    texture2d<float> b2h [[texture(6)]],
    texture2d<float> b2 [[texture(7)]],
    texture2d<float> v2 [[texture(8)]],
    texture2d<float> gotas [[texture(9)]],
    texture2d<float> c1h [[texture(10)]],
    texture2d<float> c1 [[texture(11)]],
    texture2d<float> bvh [[texture(12)]],
    texture2d<float> bv [[texture(13)]],
    texture2d<float> e1h [[texture(14)]],
    texture2d<float> e1 [[texture(15)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float2 p = px();

    if (eng.acPass == 0) { __nv_out = float4(estencil(), 0.0, 0.0, 1.0); return __nv_out; }
    if (eng.acPass == 1) {
        // o Gaussian Blur 20 do estêncil
        float e = 0.0, tot = 0.0;
        for (int i = -2; i <= 2; i++) for (int j = -2; j <= 2; j++) {
            float w = exp(-0.5 * float(i * i + j * j) * 16.0 / (5.66 * 5.66));
            e += w * est.sample(__nv_smp, clamp(uv + float2(float(i), float(j)) * 4.0 * p, 0.0, 1.0)).r; tot += w;
        }
        __nv_out = float4(gotasQueCaem() * e / tot, 0.0, 0.0, 1.0); return __nv_out;
    }
    if (eng.acPass == 2) {
        // X: R = (1 − forma) com σ 28,3 (Gaussian Blur 100, repetindo a borda); G = forma com σ 6 (Map Softness 15)
        const float N = 24.0;
        float2 soma = float2(0.0); float tot = 0.0;
        for (float i = -N; i <= N; i += 1.0) {
            float w = peso(i, N);
            soma.r += w * (1.0 - inputImg.sample(__nv_smp, clamp(uv + float2(3.0 * 28.3 * i / N * p.x, 0.0), 0.0, 1.0)).a);
            soma.g += w * forma(uv + float2(3.0 * 6.0 * i / N * p.x, 0.0));
            tot += w;
        }
        __nv_out = float4(soma / tot, 0.0, 1.0); return __nv_out;
    }
    if (eng.acPass == 3) { __nv_out = float4(borrar(b1h, float2(0.0, p.y), float4(28.3, 6.0, 0.0, 0.0)).rg, 0.0, 1.0); return __nv_out; }
    if (eng.acPass == 4) {
        // CC Vector Blur, Amount 500, na forma pintada de Blood Color
        float2 dir = direcao(media(u.bloodColor.rgb) * b1.sample(__nv_smp, uv).g) * p;
        const float N = 125.0;
        float soma = 0.0, tot = 0.0;
        for (float i = 0.0; i < N; i += 1.0) {
            float w = 1.0 - i / N;
            soma += w * forma(uv + dir * i * 4.0); tot += w;
        }
        __nv_out = float4(soma / tot, 0.0, 0.0, 1.0); return __nv_out;
    }
    if (eng.acPass == 5) { __nv_out = float4(borrar(v1, float2(p.x, 0.0), float4(6.0, 0.0, 0.0, 0.0)).r, 0.0, 0.0, 1.0); return __nv_out; }
    if (eng.acPass == 6) { __nv_out = float4(borrar(b2h, float2(0.0, p.y), float4(6.0, 0.0, 0.0, 0.0)).r, 0.0, 0.0, 1.0); return __nv_out; }
    if (eng.acPass == 7) {
        // CC Vector Blur, Amount 75
        float2 dir = direcao(media(u.bloodColor.rgb) * 0.5 * b2.sample(__nv_smp, uv).r) * p;
        const float N = 38.0;
        float2 soma = float2(0.0); float tot = 0.0;
        for (float i = 0.0; i < N; i += 1.0) {
            float w = 1.0 - i / N;
            soma += w * antesDoSegundo(uv + dir * i * (75.0 / N)); tot += w;
        }
        __nv_out = float4(soma / tot, 0.0, 1.0); return __nv_out;
    }
    if (eng.acPass == 8) {
        // Calculations 4 (o mapa de gotas a 50% por cima) + CC Threshold 110/255 no alfa + Displacement Map
        // (a forma, na Object Color: vermelho empurra em X, verde em Y, ±10 px; fora da forma não mexe).
        float s = forma(uv);
        float2 desl = float2(10.0 * (2.0 * u.objectColor.r - 1.0), -10.0 * (2.0 * u.objectColor.g - 1.0)) * s;
        float2 q = clamp(uv + desl * p, 0.0, 1.0);
        float m = 0.5 * mapa.sample(__nv_smp, q).r;
        float2 v = v2.sample(__nv_smp, q).rg;
        float a6 = m + (1.0 - m) * v.r;
        float larg = max(fwidth(a6), 1e-4);
        float D = smoothstep(0.43137 - larg, 0.43137 + larg, a6);
        __nv_out = float4(D, D + s * (1.0 - D), clamp((1.0 - m) * v.g / max(a6, 1e-4), 0.0, 1.0), 1.0); return __nv_out;
    }
    if (eng.acPass == 9) { __nv_out = float4(borrar(gotas, float2(p.x, 0.0), float4(4.8, 3.0, 0.0, 0.0)).gr, 0.0, 1.0); return __nv_out; }
    if (eng.acPass == 10) { __nv_out = float4(borrar(c1h, float2(0.0, p.y), float4(3.0, 4.8, 0.0, 0.0)).rg, 0.0, 1.0); return __nv_out; }
    if (eng.acPass == 11) {
        const float N = 16.0;
        float4 soma = float4(0.0); float tot = 0.0;
        for (float i = -N; i <= N; i += 1.0) { float w = peso(i, N); soma += w * camadaBevel(uv + float2(3.0 * 5.66 * i / N * p.x, 0.0)); tot += w; }
        __nv_out = soma / tot; return __nv_out;
    }
    if (eng.acPass == 12) { __nv_out = borrar(bvh, float2(0.0, p.y), float4(5.66)); return __nv_out; }

    // O alfa do corpo: Roughen Edges (Border 8) medido como borrão σ 3 + limiar 0,48 de borda firme.
    if (eng.acPass == 13 || eng.acPass == 14) {
        const float N = 16.0;
        float2 eixo = eng.acPass == 13 ? float2(p.x, 0.0) : float2(0.0, p.y);
        float2 soma = float2(0.0); float tot = 0.0;
        for (float i = -N; i <= N; i += 1.0) {
            float w = peso(i, N);
            float2 q = clamp(uv + eixo * 3.0 * 6.0 * i / N, 0.0, 1.0);
            if (eng.acPass == 13) soma += w * float2(clamp((c1.sample(__nv_smp, q).r - 0.48) * 4.0 + 0.5, 0.0, 1.0), bv.sample(__nv_smp, q).a * wipe(q));
            else soma += w * e1h.sample(__nv_smp, q).rg;
            tot += w;
        }
        __nv_out = float4(soma / tot, 0.0, 1.0); return __nv_out;
    }

    // ---------------------------------------------------------------- 15: a imagem
    float ao = clamp((c1.sample(__nv_smp, uv).r - 0.48) * 4.0 + 0.5, 0.0, 1.0);

    // Object: Fill com a Blood Color + Satin (preto, Multiply 50%, 45°, invertido)
    float3 corpo = u.bloodColor.rgb * (1.0 - 0.5 * satin(45.0, 0));

    // Bevel: a camada borrada, cortada pelo Linear Wipe; Satin a 19° e o Bevel and Emboss.
    float4 b = bv.sample(__nv_smp, uv) * wipe(uv);
    float3 cb = b.a > 1e-4 ? b.rgb / b.a : float3(0.0);
    // Bevel and Emboss (Inner Bevel, luz a 90° e 85° de altura, realce branco em Add a 20%): com a luz
    // quase a pino, acende onde o relevo sobe de leve na direção da luz e apaga nas bordas íngremes.
    const float G = 12.0;
    float hx = (e1.sample(__nv_smp, clamp(uv + float2(G * p.x, 0.0), 0.0, 1.0)).g - e1.sample(__nv_smp, clamp(uv - float2(G * p.x, 0.0), 0.0, 1.0)).g) / (2.0 * G);
    float hy = (e1.sample(__nv_smp, clamp(uv + float2(0.0, G * p.y), 0.0, 1.0)).g - e1.sample(__nv_smp, clamp(uv - float2(0.0, G * p.y), 0.0, 1.0)).g) / (2.0 * G);
    const float KB = 6.0, SA = 0.9961947, CA = 0.0871557;
    float nl = (KB * hy * CA + SA) / sqrt(1.0 + KB * KB * (hx * hx + hy * hy));
    float realce = clamp(3000.0 * (nl - SA), 0.0, 1.0);
    float3 bisel = cb * (1.0 - 0.5 * satin(19.0, 1)) + 0.2 * realce;

    // A camada Bevel em Screen sobre o corpo, presa ao alfa dele.
    float3 cor = corpo + b.a * bisel * (1.0 - corpo);

    // CC Glass (relevo = o alfa das gotas, Softness 12; luz distante a 200°, Specular 100, Roughness 0,002):
    // um reflexo branco e fino onde a inclinação do relevo aponta para a luz.
    const float E = 2.0;
    float gx = (c1.sample(__nv_smp, clamp(uv + float2(E * p.x, 0.0), 0.0, 1.0)).g - c1.sample(__nv_smp, clamp(uv - float2(E * p.x, 0.0), 0.0, 1.0)).g) / (2.0 * E);
    float gy = (c1.sample(__nv_smp, clamp(uv + float2(0.0, E * p.y), 0.0, 1.0)).g - c1.sample(__nv_smp, clamp(uv - float2(0.0, E * p.y), 0.0, 1.0)).g) / (2.0 * E);
    float2 dg = float2(gx, gy) - float2(0.01368, -0.03759);
    float reflexo = 2.5 * exp(-dot(dg, dg) / (2.0 * 0.006 * 0.006));

    __nv_out = float4(min(cor + reflexo, 1.0), ao);
    return __nv_out;
}
