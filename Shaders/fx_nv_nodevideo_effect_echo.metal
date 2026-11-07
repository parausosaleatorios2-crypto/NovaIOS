// ---------------------------------------------------------------------------
// Effect Echo (NV)
// origem : assets/effects/nv-nodevideo-effect-echo.xml
// id     : nv.effect.nodevideo-effect-echo
// passes : 13
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_echoParams {
    float _echo_time;
    float _num_echos;
    float _start_intensity;
    float _decay;
    int _echo_operator;
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
};

// --- funcoes auxiliares do efeito
const int NV_MAX = 11;

// Os RTs do Node: luz linear, cor pré-multiplicada.
static float3 nvLinear(float3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c)); }
static float3 nvGama(float3 l) { return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l)); }
static float4 nvNode(float4 c) { return float4(nvLinear(c.rgb) * c.a, c.a); }
static float4 nvNova(float4 p) {
    if (p.a <= 0.0) return float4(0.0);
    return float4(nvGama(clamp(p.rgb / p.a, 0.0, 1.0)), p.a);
}

static float nvDt() { return eng.acFrameDuration > 0.0 ? eng.acFrameDuration : 1.0 / 30.0; }
static int nvQuadro() { return int(floor(eng.acTime / nvDt() + 0.5)); }
static float nvTempoDoEco() { return max(u._echo_time, nvDt()); }   // if (T < 1/FPS) T = 1/FPS

// 24 bits num texel (com folga de 2^23 para tempo negativo).
static float3 nvGuardar(int n) {
    int u = clamp(n + 8388608, 0, 16777215);
    return float3(float((u >> 16) & 255), float((u >> 8) & 255), float(u & 255)) / 255.0;
}
static int nvLer(float3 c) {
    int3 b = int3(floor(c * 255.0 + 0.5));
    return ((b.r << 16) | (b.g << 8) | b.b) - 8388608;
}
static int2 nvCasa(int i) { return int2(i % 4, i / 4); }

static float4 nvRetrato(int i, float2 uv) {
    if (i == 0) return eco0.sample(__nv_smp, uv);
    if (i == 1) return eco1.sample(__nv_smp, uv);
    if (i == 2) return eco2.sample(__nv_smp, uv);
    if (i == 3) return eco3.sample(__nv_smp, uv);
    if (i == 4) return eco4.sample(__nv_smp, uv);
    if (i == 5) return eco5.sample(__nv_smp, uv);
    if (i == 6) return eco6.sample(__nv_smp, uv);
    if (i == 7) return eco7.sample(__nv_smp, uv);
    if (i == 8) return eco8.sample(__nv_smp, uv);
    if (i == 9) return eco9.sample(__nv_smp, uv);
    return eco10.sample(__nv_smp, uv);
}

static bool nvTirouRetrato() { return agenda.read(uint2(nvCasa(NV_MAX)), uint(0)).r > 0.5; }

// O passe 0 do shader do Node (Effect/echo), conta por conta.
static float4 nvPasse0(float4 e1, float4 e2, float op1, float op2, int operador) {
    float4 u_xlat0 = e2;
    float4 u_xlat2 = e1;
    float4 u_xlat1 = u_xlat0 * op2;
    u_xlat1 = u_xlat2 * op1 + u_xlat1;
    bool4 b = equal(int4(operador), int4(2, 3, 4, 5));
    float4 u_xlat4 = min(u_xlat0, u_xlat2);
    u_xlat1 = b.w ? u_xlat4 : u_xlat1;
    u_xlat4 = max(u_xlat0, u_xlat2);
    u_xlat1 = b.z ? u_xlat4 : u_xlat1;
    u_xlat4 = -u_xlat0 + 1.0;
    u_xlat0 = u_xlat0 * op2 + u_xlat2;
    u_xlat2 = -u_xlat2 + 1.0;
    u_xlat2 = -u_xlat4 * u_xlat2 + 1.0;
    u_xlat1 = b.y ? u_xlat2 : u_xlat1;
    return b.x ? u_xlat0 : u_xlat1;
}

// Blend SrcAlpha OneMinusSrcAlpha num RT de 8 bits (a saída do shader e a mistura presas em 0..1).
static float4 nvMisturar(float4 o, float4 d) {
    o = clamp(o, 0.0, 1.0);
    return clamp(o * o.a + d * (1.0 - o.a), 0.0, 1.0);
}

fragment float4 fx_nv_nodevideo_effect_echo(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_echoParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> agenda [[texture(1)]],
    texture2d<float> eco0 [[texture(2)]],
    texture2d<float> eco1 [[texture(3)]],
    texture2d<float> eco2 [[texture(4)]],
    texture2d<float> eco3 [[texture(5)]],
    texture2d<float> eco4 [[texture(6)]],
    texture2d<float> eco5 [[texture(7)]],
    texture2d<float> eco6 [[texture(8)]],
    texture2d<float> eco7 [[texture(9)]],
    texture2d<float> eco8 [[texture(10)]],
    texture2d<float> eco9 [[texture(11)]],
    texture2d<float> eco10 [[texture(12)]],
    texture2d<float> Mask [[texture(13)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int f = nvQuadro();
    float dt = nvDt();
    float T = nvTempoDoEco();
    float limite = T * (float(int(u._num_echos)) + 1.0);

    // ---------------------------------------------------------------- 0: a agenda
    if (eng.acPass == 0) {
        int fc[NV_MAX];
        bool vale[NV_MAX];
        bool existe = false;
        for (int i = 0; i < NV_MAX; i++) {
            float4 a = agenda.read(uint2(nvCasa(i)), uint(0));
            fc[i] = nvLer(a.rgb);
            float idade = float(f - fc[i]) * dt;
            // CheckReleaseExpiredSchedules: solta idade < 0 ou > T x (N + 1).
            vale[i] = eng.acStateFresh == 0 && a.a > 0.5 && idade >= 0.0 && idade <= limite + 1e-6;
            // ContainsSchedule: há retrato com idade <= T (o próprio quadro conta).
            if (vale[i] && idade <= T + 1e-6) existe = true;
        }
        int2 p = int2(__nv_fragCoord.xy);
        int i = p.x + p.y * 4;
        if (p.x >= 4 || i > NV_MAX) { __nv_out = float4(0.0); return __nv_out; }
        if (i == NV_MAX) { __nv_out = float4(existe ? 0.0 : 1.0, 0.0, 0.0, 1.0); return __nv_out; }
        if (!existe) {
            // AddSchedule: o retrato novo entra na frente; o resto anda uma casa.
            if (i == 0) { __nv_out = float4(nvGuardar(f), 1.0); return __nv_out; }
            __nv_out = vale[i - 1] ? float4(nvGuardar(fc[i - 1]), 1.0) : float4(0.0);
            return __nv_out;
        }
        __nv_out = vale[i] ? float4(nvGuardar(fc[i]), 1.0) : float4(0.0);
        return __nv_out;
    }

    // ------------------------------------------------------- 1..11: os retratos
    if (eng.acPass <= NV_MAX) {
        int k = NV_MAX - eng.acPass;   // o passe 1 escreve o eco10, o 11 o eco0
        bool tirou = nvTirouRetrato();
        if (k == 0) { __nv_out = tirou ? inputImg.sample(__nv_smp, in.acScreenNorm) : eco0.sample(__nv_smp, in.acScreenNorm); return __nv_out; }
        __nv_out = nvRetrato(tirou ? k - 1 : k, in.acScreenNorm);
        return __nv_out;
    }

    // ------------------------------------------------------- 12: a composição
    float2 uv = in.acScreenNorm;
    float4 S = nvNode(inputImg.sample(__nv_smp, uv));
    int n = 0;
    float I[NV_MAX];
    for (int i = 0; i < NV_MAX; i++) {
        float4 a = agenda.read(uint2(nvCasa(i)), uint(0));
        if (a.a < 0.5) { I[i] = 0.0; continue; }
        // a intensidade perde u._decay x 0,1 / FPS x 30 a cada quadro desenhado depois do retrato
        int idade = f - nvLer(a.rgb);
        I[i] = max(u._start_intensity - float(idade) * (u._decay * 0.1 / (1.0 / dt)) * 30.0, 0.0);
        n = i + 1;
    }
    int operador = int(u._echo_operator);
    float4 T1 = float4(0.0);
    float4 T2 = float4(0.0);
    float4 X;
    if (n == 0) {
        X = S;   // não acontece: o quadro sempre tem o retrato de agora
    } else if (operador != 1) {
        // Blit(fonte -> EchoTemp1); do mais novo (k = 0) ao mais velho, alternando os dois RTs.
        T1 = S;
        for (int k = 0; k < NV_MAX; k++) {
            if (k >= n) break;
            float4 r = nvNode(nvRetrato(k, uv));
            if ((k & 1) == 0) T2 = nvMisturar(nvPasse0(T1, r, 1.0 - I[k], I[k], operador), T2);
            else T1 = nvMisturar(nvPasse0(T2, r, 1.0 - I[k], I[k], operador), T1);
        }
        X = ((n - 1) & 1) == 0 ? T2 : T1;
    } else {
        // Composite In Back. Na lista do Node o índice j é o j-ésimo mais VELHO: o retrato n - 1 - j daqui.
        if (n == 1) {
            T2 = nvNode(nvRetrato(0, uv));
            X = T2;
        } else {
            T1 = nvNode(nvRetrato(n - 1, uv));
            for (int j = 0; j < NV_MAX - 1; j++) {
                if (j >= n - 1) break;
                float4 r = nvNode(nvRetrato(n - 2 - j, uv));   // o j + 1 do Node
                float w = I[n - 1 - j];                      // a intensidade do j do Node
                if ((j & 1) == 0) T2 = nvMisturar(nvPasse0(T1, r, w, 1.0 - w, 1), T2);
                else T1 = nvMisturar(nvPasse0(T2, r, w, 1.0 - w, 1), T1);
            }
            X = ((n - 2) & 1) == 0 ? T2 : T1;
        }
        // Blit(fonte -> X) com _echo1 = fonte e _echo2 = X: a camada por cima, com 1 - a intensidade do mais novo.
        X = nvMisturar(nvPasse0(S, X, 1.0 - I[0], I[0], 1), X);
    }

    // O passe 1 do shader (_echo2 = X, máscara interna) com Blend SrcAlpha Zero.
    float4 u_xlat0 = X;
    float4 saida;
    if (u._use_inner_mask != 0.0) {
        float4 u_xlat1 = S;
        bool2 b = equal(int2(int(u._show_inner_mask), int(u._b_clip_mask)), int2(1, 1));
        float4 u_xlat3 = b.x ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        float4 u_xlat4 = nvNode(Mask.sample(__nv_smp, uv));
        u_xlat1 = u_xlat1 * (1.0 - u_xlat4);
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        saida = float4(u_xlat1.xyz, b.y ? u_xlat4.x * u_xlat1.w : u_xlat1.w);
    } else {
        saida = u_xlat0;
    }
    saida = clamp(saida, 0.0, 1.0);
    __nv_out = nvNova(saida * saida.a);
    return __nv_out;
}
