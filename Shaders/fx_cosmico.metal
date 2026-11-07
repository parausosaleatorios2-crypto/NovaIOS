// ---------------------------------------------------------------------------
// Cósmico
// origem : assets/effects/cosmico.xml
// id     : nova.effect.cosmico
// passes : 24
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct cosmicoParams {
    int colors;
    float4 color1;
    float4 color2;
    float4 color3;
    float4 color4;
    float4 color5;
    float angle;
    float cycles;
    float offset;
    float phase;
    float saturation;
    float brightness;
    float depthAngle;
    float contrast;
    float bulge;
    float rounding;
    float turbulence;
    float sizeX;
    float sizeY;
    float evolution;
    float softness;
    float glowRadius;
    float glowFalloff;
    float glowThreshold;
    float glowIntensity;
    float softClip;
    float grain;
    float grainSize;
    float grainColor;
    int grainAnimate;
    float diffusion;
    float2 center;
    float focus;
    float feather;
    int invert;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265358979;
// Calibrados no benchmark (tools/cosmic/benchmark):
const float SIGMA_M0 = 12.0, SIGMA_M1 = 24.0;    // o borrão do Rounding: σ = 12 + 24 × Rounding/100 px
const float K_SOFT = 0.34;                        // Softness: σ = 0,34 × Softness px
const float TURB = 0.00035;                        // Turbulence: desvio de t por unidade de Amount
const float TURB_ESCALA = 80.0;                   // o tamanho do ruído: 40 px × Size
const float GLOW_A0 = 0.2592, GLOW_A = 0.3437, GLOW_C0 = -1.864, GLOW_C1 = 0.5, GLOW_S = 4.0;   // pesos do glow e o corte
const float HALO_A0 = 2.98, HALO_A = 0.96, HALO_C0 = 0.204, HALO_C1 = 0.725, HALO_S = 2.907;
const float GRAO = 0.153;                          // grão: desvio = 0,13 × Amount/100 × √cor
const float K_DIF = 0.32;                         // Optical Diffusion: σ = 0,32 × Blur px

const float3 PRESETS[55] = float3[55](
    float3(0.0118, 0.0216, 0.0807), float3(0.0294, 0.1786, 0.5181), float3(0.0999, 0.5493, 0.9197), float3(0.4471, 0.8482, 0.9990), float3(0.9230, 0.9941, 1.0000),
    float3(0.8493, 0.0412, 0.1909), float3(0.9689, 0.7713, 0.8072), float3(0.7900, 0.6949, 0.5462), float3(0.1508, 0.5459, 0.4935), float3(0.0881, 0.1976, 0.5269),
    float3(0.9503, 0.9385, 0.9618), float3(0.3294, 0.4546, 0.4587), float3(0.6597, 0.7461, 0.7421), float3(0.0245, 0.1419, 0.1383), float3(0.3851, 0.5307, 0.4443),
    float3(0.9842, 1.0000, 0.9999), float3(0.9219, 0.7892, 0.7538), float3(0.8318, 0.5151, 0.5737), float3(0.7177, 0.2152, 0.2121), float3(0.8110, 0.6647, 0.4880),
    float3(0.1586, 0.0515, 0.5479), float3(0.2151, 0.0664, 0.7497), float3(0.0955, 0.0552, 0.3504), float3(0.0244, 0.0462, 0.1489), float3(0.9495, 0.2943, 0.2934),
    float3(0.8326, 0.5507, 0.9490), float3(0.2208, 0.2550, 0.9490), float3(0.2389, 0.3449, 0.9490), float3(0.2390, 0.4730, 0.9490), float3(0.4923, 0.9059, 0.9490),
    float3(0.5026, 0.0000, 0.5011), float3(0.6617, 0.0000, 0.4478), float3(0.8351, 0.0000, 0.2827), float3(0.9169, 0.0000, 0.1421), float3(1.0000, 0.0000, 0.0000),
    float3(0.7693, 0.8828, 0.9994), float3(0.0175, 0.4007, 0.7493), float3(0.0111, 0.6221, 0.8557), float3(0.0205, 0.7581, 0.2845), float3(0.0013, 0.4422, 0.1582),
    float3(0.9497, 0.7174, 0.0201), float3(0.9483, 0.5301, 0.0194), float3(0.9511, 0.3619, 0.0199), float3(0.3483, 0.0082, 0.0071), float3(0.9986, 0.2333, 0.2355),
    float3(0.8851, 0.0273, 0.0796), float3(0.9171, 0.3508, 0.0507), float3(1.0000, 0.8625, 0.0549), float3(0.0455, 0.5975, 0.2258), float3(0.0521, 0.2521, 0.5812),
    float3(0.9602, 0.0209, 0.2497), float3(0.0109, 0.2877, 0.6494), float3(0.9898, 0.7614, 0.8719), float3(1.0000, 0.4698, 0.2294), float3(0.9991, 0.7935, 0.0000));

float2 tamanho() { return float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))); }
/** Um px da composição, em UV do quadro. */
float2 px() { return eng.acEscalaDePixel / tamanho(); }
float forma(float2 uv) { return (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) ? 0.0 : inputImg.sample(__nv_smp, uv).a; }
float h1(float2 p) { float3 q = fract(float3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float3 h3(float3 p) { p = fract(p * float3(0.1031, 0.1030, 0.0973)); p += dot(p, p.yxz + 33.33); return fract((p.xxy + p.yxx) * p.zyx); }

// 16 bits num par de canais de 8.
float2 emDois(float v) { v = clamp(v, 0.0, 1.0) * 65535.0; return float2(floor(v / 256.0), __nv_mod(floor(v), 256.0)) / 255.0; }
float deDois(float2 c) { return (floor(c.x * 255.0 + 0.5) * 256.0 + floor(c.y * 255.0 + 0.5)) / 65535.0; }

// ------------------------------------------------------------------ a paleta
// Medido: cinco cores numa volta (a última volta para a primeira), interpoladas em linha reta na cor
// do monitor. As do "Custom" ficam a 0, 20, 40, 60 e 80% da volta; os presets também, menos o 1
// (Ocean, o azul de fábrica), que tem as paradas a 0, 25, 50, 72 e 88%.
float3 paleta(float t) {
    t = fract(t);
    float3 c[5]; float p[5];
    int pr = u.colors - 1;
    if (pr < 0) { c[0] = u.color1.rgb; c[1] = u.color2.rgb; c[2] = u.color3.rgb; c[3] = u.color4.rgb; c[4] = u.color5.rgb; }
    else for (int i = 0; i < 5; i++) c[i] = PRESETS[pr * 5 + i];
    if (pr == 0) { p[0] = 0.0; p[1] = 0.25; p[2] = 0.5; p[3] = 0.72; p[4] = 0.88; }
    else { p[0] = 0.0; p[1] = 0.2; p[2] = 0.4; p[3] = 0.6; p[4] = 0.8; }
    for (int i = 0; i < 4; i++) if (t < p[i + 1]) return mix(c[i], c[i + 1], (t - p[i]) / (p[i + 1] - p[i]));
    return mix(c[4], c[0], (t - p[4]) / (1.0 - p[4]));
}

// ------------------------------------------------------------------ Turbulence
float ruidoGrad(float3 p) {
    float3 i = floor(p), f = fract(p), u = f * f * (3.0 - 2.0 * f);
    float n = 0.0;
    for (int z = 0; z < 2; z++) for (int y = 0; y < 2; y++) for (int x = 0; x < 2; x++) {
        float3 o = float3(float(x), float(y), float(z));
        float3 g = normalize(h3(i + o) * 2.0 - 1.0 + 1e-4);
        float3 w = mix(1.0 - u, u, o);
        n += w.x * w.y * w.z * dot(g, f - o);
    }
    return n;
}
float turbulencia(float2 P) {
    float3 q = float3(P.x / (TURB_ESCALA * u.sizeX), P.y / (TURB_ESCALA * u.sizeY), u.evolution / 360.0);
    // duas oitavas; o fator leva o desvio do ruído a ~1
    return 3.2 * ruidoGrad(q);
}

// ------------------------------------------------------------------ o campo t do degradê
// Medido: t = projeção do pixel no ângulo, a partir do meio do quadro, em alturas do quadro, + 0,5;
// × Cycles (a partir de t = 0), + Offset/100 + Phase/360. O Depth soma Bulge/100 × r × m, onde r é a
// mesma rampa no ângulo do Depth, medida na CAIXA da forma (dividida pela diagonal dela) e com o
// Contrast em volta de 0,5; m é o alfa borrado (o "domo" do Rounding).
float campoT(float2 uv) {
    float2 R = tamanho();
    float2 P = uv * R;
    float a = radians(u.angle);
    float t = (dot(P - 0.5 * R, float2(cos(a), sin(a))) / R.y + 0.5) * u.cycles + u.offset / 100.0 + u.phase / 360.0;
    if (u.bulge != 0.0) {
        float4 cx = caixa.read(uint2(int2(0, 0)), uint(0)), cy = caixa.read(uint2(int2(1, 0)), uint(0));
        float2 p0 = float2(deDois(cx.rg), deDois(cy.rg)) * R, p1 = float2(deDois(cx.ba), deDois(cy.ba)) * R;
        float th = radians(u.depthAngle);
        float r = 0.5 + dot(P - 0.5 * (p0 + p1), float2(cos(th), sin(th))) / max(length(p1 - p0), 1.0);
        r = clamp((r - 0.5) * u.contrast / 100.0 + 0.5, 0.0, 1.0);
        t += u.bulge / 100.0 * r * mv.sample(__nv_smp, uv).r;
    }
    if (u.turbulence > 0.0) t += u.turbulence * TURB * turbulencia(P / eng.acEscalaDePixel);
    return t;
}

/** Saturation (luma Rec.601) e Brightness (multiplica), na cor do monitor. */
float3 ajustar(float3 c) {
    float y = dot(c, float3(0.299, 0.587, 0.114));
    return clamp((y + (c - y) * u.saturation / 100.0) * u.brightness / 100.0, 0.0, 1.0);
}

float peso(float i, float n) { float x = 3.0 * i / n; return exp(-0.5 * x * x); }

/** Gaussiana separável num canal ou em todos; `volta` = borda que dá a volta (o Softness). */
float4 borrar(sampler2D t, float2 eixo, float sigmaPx, bool volta) {
    if (sigmaPx < 0.3) return t.sample(__nv_smp, in.acScreenNorm);
    const float N = 24.0;
    float4 soma = float4(0.0); float tot = 0.0;
    for (float i = -N; i <= N; i += 1.0) {
        float w = peso(i, N);
        float2 q = in.acScreenNorm + eixo * (3.0 * sigmaPx * i / N);
        soma += w * t.sample(__nv_smp, volta ? fract(q) : clamp(q, 0.0, 1.0)); tot += w;
    }
    return soma / tot;
}

// ------------------------------------------------------------------ o glow
// Medido: em luz linear (gama 2,2), soma de borrões gaussianos da cor × alfa, CADA UM DIVIDIDO PELO
// PICO do próprio nível no quadro (é por isso que um ponto pequeno brilha longe e um texto grosso
// não estoura). O Radius corta os níveis acima do tamanho dele (o Falloff empurra o corte); o alfa
// da camada ganha o mesmo halo (preto) mesmo com Intensity 0.
float sigmaDoNivel(int k) { return 3.0 * exp2(float(k - 1)); }    // px: 3, 6, 12 … 768
float corte(int k, float A, float c0, float c1, float s) {
    float x = log2(sigmaDoNivel(k) / max(u.glowRadius, 1.0));
    float c = c0 + c1 * (50.0 - u.glowFalloff) / 50.0;
    return A / (1.0 + exp((x - c) * s));
}
float4 nivel(int k, float2 uv) {
    float4 v = k == 1 ? g1.sample(__nv_smp, uv) : k == 2 ? g2.sample(__nv_smp, uv) : k == 3 ? g3.sample(__nv_smp, uv) : k == 4 ? g4.sample(__nv_smp, uv) :
             k == 5 ? g5.sample(__nv_smp, uv) : k == 6 ? g6.sample(__nv_smp, uv) : k == 7 ? g7.sample(__nv_smp, uv) : k == 8 ? g8.sample(__nv_smp, uv) : g9.sample(__nv_smp, uv);
    return v * v;                         // cor e alfa vão em raiz quadrada (8 bits)
}
float picoDo(int k) { return max(deDois(picos.read(uint2(int2((k - 1) % 3, (k - 1) / 3)), uint(0)).rg), 1e-4); }

/** Um nível a partir do anterior (ou da imagem, no primeiro): só o σ que falta. */
float4 descer(int k) {
    float2 uv = in.acScreenNorm;
    float falta = sqrt(max(sigmaDoNivel(k) * sigmaDoNivel(k) - (k == 1 ? 0.0 : sigmaDoNivel(k - 1) * sigmaDoNivel(k - 1)), 0.0));
    float2 passo = falta / 1.2 * px();
    float4 soma = float4(0.0); float tot = 0.0;
    for (int j = -3; j <= 3; j++) for (int i = -3; i <= 3; i++) {
        float2 o = float2(float(i), float(j));
        float w = exp(-0.5 * dot(o, o) / (1.2 * 1.2));
        float2 q = uv + o * passo;
        float4 v;
        if (k == 1) {
            float s = forma(q);
            float3 c = sv.sample(__nv_smp, clamp(q, 0.0, 1.0)).rgb;
            float3 l = pow(c, float3(2.2)) * s;
            // Threshold: só o que passa do limiar (em luz linear)
            l *= smoothstep(u.glowThreshold / 100.0, u.glowThreshold / 100.0 + 0.05, dot(c, float3(0.299, 0.587, 0.114)));
            v = float4(l, s);
        } else v = nivel(k - 1, clamp(q, 0.0, 1.0));
        soma += w * v; tot += w;
    }
    soma /= tot;
    return sqrt(soma);
}

/** O pico do alfa de um nível no quadro: os três primeiros pelos máximos em blocos (`mp`), os outros texel a texel. */
float picoDeNivel(int k) {
    float m = 0.0;
    int2 t = k <= 3 ? int2(int(mp.get_width()), int(mp.get_height())) : k == 4 ? int2(int(g4.get_width()), int(g4.get_height())) : k == 5 ? int2(int(g5.get_width()), int(g5.get_height())) : k == 6 ? int2(int(g6.get_width()), int(g6.get_height())) : k == 7 ? int2(int(g7.get_width()), int(g7.get_height())) : k == 8 ? int2(int(g8.get_width()), int(g8.get_height())) : int2(int(g9.get_width()), int(g9.get_height()));
    for (int j = 0; j < 128; j++) {
        if (j >= t.y) break;
        for (int i = 0; i < 256; i++) {
            if (i >= t.x) break;
            int2 q = int2(i, j);
            float4 v = k <= 3 ? mp.read(uint2(q), uint(0)) : k == 4 ? g4.read(uint2(q), uint(0)) : k == 5 ? g5.read(uint2(q), uint(0)) : k == 6 ? g6.read(uint2(q), uint(0)) : k == 7 ? g7.read(uint2(q), uint(0)) : k == 8 ? g8.read(uint2(q), uint(0)) : g9.read(uint2(q), uint(0));
            float a = k == 1 ? v.r : k == 2 ? v.g : k == 3 ? v.b : v.a;
            m = max(m, a * a);
        }
    }
    return m;
}

/** O máximo (em raiz) do alfa dos níveis 1, 2 e 3 em cada bloco deste buffer. */
float4 maximosEmBloco() {
    float3 m = float3(0.0);
    int2 o = int2(__nv_fragCoord.xy);
    for (int j = 0; j < 8; j++) for (int i = 0; i < 8; i++) {
        m.r = max(m.r, g1.read(uint2(min(o * 8 + int2(i, j), int2(int(g1.get_width()), int(g1.get_height())) - 1)), uint(0)).a);
        if (i < 4 && j < 4) m.g = max(m.g, g2.read(uint2(min(o * 4 + int2(i, j), int2(int(g2.get_width()), int(g2.get_height())) - 1)), uint(0)).a);
        if (i < 2 && j < 2) m.b = max(m.b, g3.read(uint2(min(o * 2 + int2(i, j), int2(int(g3.get_width()), int(g3.get_height())) - 1)), uint(0)).a);
    }
    return float4(m, 1.0);
}

fragment float4 fx_cosmico(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant cosmicoParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> linhas [[texture(1)]],
    texture2d<float> caixa [[texture(2)]],
    texture2d<float> mh [[texture(3)]],
    texture2d<float> mv [[texture(4)]],
    texture2d<float> cor [[texture(5)]],
    texture2d<float> sh [[texture(6)]],
    texture2d<float> sv [[texture(7)]],
    texture2d<float> g1 [[texture(8)]],
    texture2d<float> g2 [[texture(9)]],
    texture2d<float> g3 [[texture(10)]],
    texture2d<float> g4 [[texture(11)]],
    texture2d<float> g5 [[texture(12)]],
    texture2d<float> g6 [[texture(13)]],
    texture2d<float> g7 [[texture(14)]],
    texture2d<float> g8 [[texture(15)]],
    texture2d<float> g9 [[texture(16)]],
    texture2d<float> mp [[texture(17)]],
    texture2d<float> picos [[texture(18)]],
    texture2d<float> nitido [[texture(19)]],
    texture2d<float> d1h [[texture(20)]],
    texture2d<float> d1 [[texture(21)]],
    texture2d<float> d2h [[texture(22)]],
    texture2d<float> d2 [[texture(23)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float2 p = px();

    if (eng.acPass == 0) {
        // a caixa da forma, numa grade de 240 × 135: cada texel varre a SUA linha j e guarda a primeira e a última
        // coluna com alfa. Até a 0.659 dois pixels varriam a grade inteira em fila (8–9 ms na GPU do PC, quase tudo
        // espera); agora são 135 linhas ao mesmo tempo e a junção (abaixo) lê 135 texels.
        int j = int(__nv_fragCoord.x);
        int primeira = -1, ultima = -1;
        for (int i = 0; i < 240; i++) {
            float2 q = (float2(float(i), float(j)) + 0.5) / float2(240.0, 135.0);
            if (inputImg.sample(__nv_smp, q).a > 0.004) { if (primeira < 0) primeira = i; ultima = i; }
        }
        __nv_out = primeira < 0 ? float4(0.0) : float4(float(primeira), float(ultima), 255.0, 255.0) / 255.0;
        return __nv_out;
    }
    if (eng.acPass == 1) {
        // a caixa: a junção das linhas. As contas de cada canto são as de antes, no mesmo ponto da grade — o menor de
        // q − meio texel numa linha é o da primeira coluna (a conta só cresce com a coluna), e o maior, o da última.
        int2 o = int2(__nv_fragCoord.xy);
        if (o.y != 0 || o.x > 1) { __nv_out = float4(0.0); return __nv_out; }
        float2 mn = float2(1.0), mx = float2(0.0);
        for (int j = 0; j < 135; j++) {
            float4 l = linhas.read(uint2(int2(j, 0)), uint(0));
            if (l.b < 0.5) continue;
            int primeira = int(l.r * 255.0 + 0.5), ultima = int(l.g * 255.0 + 0.5);
            float2 q0 = (float2(float(primeira), float(j)) + 0.5) / float2(240.0, 135.0);
            float2 q1 = (float2(float(ultima), float(j)) + 0.5) / float2(240.0, 135.0);
            mn = min(mn, q0 - 0.5 / float2(240.0, 135.0)); mx = max(mx, q1 + 0.5 / float2(240.0, 135.0));
        }
        if (mx.x < mn.x) { mn = float2(0.0); mx = float2(1.0); }
        __nv_out = o.x == 0 ? float4(emDois(mn.x), emDois(mx.x)) : float4(emDois(mn.y), emDois(mx.y));
        return __nv_out;
    }
    float sm = SIGMA_M0 + SIGMA_M1 * u.rounding / 100.0;
    if (eng.acPass == 2) {
        const float N = 20.0;
        float soma = 0.0, tot = 0.0;
        for (float i = -N; i <= N; i += 1.0) { float w = peso(i, N); soma += w * forma(uv + float2(3.0 * sm * i / N * p.x, 0.0)); tot += w; }
        __nv_out = float4(soma / tot, 0.0, 0.0, 1.0); return __nv_out;
    }
    if (eng.acPass == 3) { __nv_out = float4(borrar(mh, float2(0.0, p.y), sm, false).r, 0.0, 0.0, 1.0); return __nv_out; }
    if (eng.acPass == 4) { __nv_out = float4(ajustar(paleta(campoT(uv))), 1.0); return __nv_out; }
    float ss = K_SOFT * u.softness;
    if (eng.acPass == 5) { __nv_out = borrar(cor, float2(p.x, 0.0), ss, true); return __nv_out; }
    if (eng.acPass == 6) { __nv_out = borrar(sh, float2(0.0, p.y), ss, true); return __nv_out; }
    if (eng.acPass >= 7 && eng.acPass <= 15) { __nv_out = descer(eng.acPass - 6); return __nv_out; }
    if (eng.acPass == 16) { __nv_out = maximosEmBloco(); return __nv_out; }
    if (eng.acPass == 17) {
        int2 o = int2(__nv_fragCoord.xy);
        if (o.x > 2 || o.y > 2) { __nv_out = float4(0.0); return __nv_out; }
        __nv_out = float4(emDois(picoDeNivel(o.y * 3 + o.x + 1)), 0.0, 1.0); return __nv_out;
    }
    if (eng.acPass == 18) {
        float s = forma(uv);
        float3 c = sv.sample(__nv_smp, uv).rgb;
        float3 l = pow(c * s, float3(2.2));       // medido: a borda suave da forma escurece a cor na cor do monitor
        float3 brilho = float3(0.0);
        float resto = 1.0 - s;
        for (int k = 1; k <= 9; k++) {
            float4 n = nivel(k, uv);
            float pk = picoDo(k);
            brilho += corte(k, k == 1 ? GLOW_A0 : GLOW_A, GLOW_C0, GLOW_C1, GLOW_S) * n.rgb / pk;
            resto *= 1.0 - clamp(corte(k, k == 1 ? HALO_A0 : HALO_A, HALO_C0, HALO_C1, HALO_S) * n.a / pk, 0.0, 1.0);
        }
        float3 luz = l + u.glowIntensity / 100.0 * brilho;
        // Soft Clip: comprime o que passa de 1 em vez de cortar
        float sc = u.softClip / 100.0;
        if (sc > 0.0) luz = mix(luz, luz / (1.0 + luz), sc);
        float3 corFinal = pow(clamp(luz, 0.0, 1.0), float3(1.0 / 2.2));
        // a cor já vem "por cima de preto" (premultiplicada); o alfa nunca fica abaixo dela
        float alfa = max(1.0 - resto, max(corFinal.r, max(corFinal.g, corFinal.b)));
        __nv_out = float4(corFinal, alfa);
        return __nv_out;
    }
    // Optical Diffusion: σ = 0,32 × Blur × smoothstep(Focus, Focus + Feather, distância ao Center)
    float sd = K_DIF * u.diffusion;
    if (eng.acPass == 19) { __nv_out = borrar(nitido, float2(p.x, 0.0), 0.5 * sd, false); return __nv_out; }
    if (eng.acPass == 20) { __nv_out = borrar(d1h, float2(0.0, p.y), 0.5 * sd, false); return __nv_out; }
    if (eng.acPass == 21) { __nv_out = borrar(nitido, float2(p.x, 0.0), sd, false); return __nv_out; }
    if (eng.acPass == 22) { __nv_out = borrar(d2h, float2(0.0, p.y), sd, false); return __nv_out; }

    float2 R = tamanho();
    float dist = length((uv - u.center) * R) / eng.acEscalaDePixel;
    float w = smoothstep(u.focus, u.focus + max(u.feather, 1e-3), dist);
    if (u.invert) w = 1.0 - w;
    float4 n0 = nitido.sample(__nv_smp, uv), n1 = d1.sample(__nv_smp, uv), n2 = d2.sample(__nv_smp, uv);
    float4 r = sd < 0.3 ? n0 : (w < 0.5 ? mix(n0, n1, w * 2.0) : mix(n1, n2, w * 2.0 - 1.0));
    float3 c = r.a > 1e-4 ? min(r.rgb / r.a, 1.0) : float3(0.0);

    // Grain: ruído por canal (o Color mistura com um ruído só para os três), proporcional a √cor
    if (u.grain > 0.0) {
        float quadro = u.grainAnimate ? floor(eng.acTime * 30.0 + 0.5) : 0.0;
        float2 cel = uv * R / (eng.acEscalaDePixel * u.grainSize);
        // medido: células quadradas de Size px, sem interpolação (autocorrelação 0 com 1 px, 2/3 com 3 px)
        float2 i0 = floor(cel);
        float3 a = h3(float3(i0, quadro)), b = h3(float3(i0 + 17.0, quadro + 3.0));
        // gaussiana aproximada: soma de dois uniformes
        float4 n = float4(a + b - 1.0, (a.x + b.y + a.z + b.x - 2.0) * 0.7071) * 2.449;
        float3 rg = mix(float3(n.a), n.rgb, u.grainColor / 100.0);
        c = clamp(c + GRAO * u.grain / 100.0 * sqrt(max(c, 0.0)) * rg, 0.0, 1.0);
    }
    __nv_out = float4(c, r.a);
    return __nv_out;
}
