// ---------------------------------------------------------------------------
// Sala neon (NV)
// origem : assets/effects/nv-nodevideo-fill-audiovisualization-neon-room.xml
// id     : nv.effect.nodevideo-fill-audiovisualization-neon-room
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_audiovisualization_neon_roomParams {
    float3 _shape;
    float3 _space;
    float4 _colour;
    float _color_randomize;
    float _phase;
    float _frequency;
    float _intensity;
    int _blend_mode;
    float _bands_count;
    float _bands_shift;
    float startFreq;
    float endFreq;
    float bands;
    float duration;
    float offset;
};

// --- funcoes auxiliares do efeito
// A máscara interna do Node (o editor de máscara dele) fica desligada, como no padrão: a definição não a mostra.
#define _use_inner_mask 0
#define _b_clip_mask 0
#define _show_inner_mask 0
#define Mask inputImg

// ---- a ponte Nova <-> Node (a mesma de tools/nodeluzes/gerar.py) ----
static float3 nvLinear(float3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(0.04045, c)); }
static float3 nvGama(float3 c) { return mix(c * 12.92, 1.055 * pow(c, float3(1.0 / 2.4)) - 0.055, step(0.0031308, c)); }
// SetGlobalColor: num projeto linear o Unity manda a cor já em luz linear.
static float4 nvCor(float4 c) { return float4(nvLinear(c.rgb), c.a); }
// O RT da camada no Node: pré-multiplicada, em luz linear.
static float4 nvEntrada(float2 uv) { float4 c = inputImg.sample(__nv_smp, uv); return float4(nvLinear(c.rgb) * c.a, c.a); }
// A saída do Node (pré-multiplicada, linear, presa a 0..1 como o RT de 8 bits) para a cor reta do Nova. A luz acima do
// alfa vira alfa; NaN (o log2 de 0 na conta do Node) vira 0, como no RT dele.
static float4 nvSaida(float4 p) {
    p = mix(float4(0.0), min(p, float4(1.0)), greaterThanEqual(p, float4(0.0)));
    float a = max(p.a, max(p.r, max(p.g, p.b)));
    return a > 0.0 ? float4(nvGama(p.rgb / a), a) : float4(0.0);
}

// ---- O _audio_sampler do Node (AEAudioVisualizer.RenderNew → AudioSampler.GetCurSampleTexture) ----
// Uma Texture2D de Quantidade de bandas × 1 (RGBA32 sRGB, Repeat, Bilinear) com 1 ÷ (1 + e^(−banda ÷ (1 − Intensidade))).
// O espectro (CheckGetSpectrumBuf → nv_get_spectrum_data, NVSpectrum(10, 1, 3, taxa, 20, 2000)): 1024 pontos espalhados
// pelo quadro, janela Blackman do FFmpeg, chirp-z de 20 a 2000 Hz que o nativo acha ser a 44,1 kHz; os pontos k ≥ 512
// são a sobra do chirp-z, sem o começo da janela. O ponto k é então (20 + k × 1980/511) × (1023 × fps ÷ taxa) Hz.
// Aqui: |X| ≈ altura do src="spectrum" × 465,1. A conta dá 404,5 (Blackman ÷ Hamming em tom puro); o ×1,15 vem de duas
// músicas contra a conta do Node em Python: acesas (luz > 0,8) 1,56% × 1,49% e 6,03% × 5,94%, erro médio 1,5–3%.
const int LARGURA_ESP = 256;
static float alturaDaFaixa(int j) {
    int t = 1 + 3 * j;
    float4 c = floor(faixasImg.read(uint2(int2(t % LARGURA_ESP, t / LARGURA_ESP)), uint(0)) * 255.0 + 0.5);
    return (c.r * 65536.0 + c.g * 256.0 + c.b) / 16777215.0;
}
// O ponto k (de 2 a 1023) do espectro do Node.
static float pontoDoNode(int k) {
    float p = float(k - 2) / 4.0;
    int a = int(p);
    float h = mix(alturaDaFaixa(a), alturaDaFaixa(min(a + 1, 255)), p - float(a));
    float u = clamp(float(k - 511) / 1024.0, 0.0, 1.0);
    float resto = (0.42659 * (1.0 - u) + 0.49656 * sin(6.2831853 * u) / 6.2831853 - 0.076849 * sin(12.5663706 * u) / 12.5663706) / 0.42659;
    return h * 465.1 * resto;
}
// AEAudioVisualizer.freqToIndex(f, 1024, taxa).
static int indiceDaFreq(float f) {
    if (f < 21.533203) return 0;
    if (f > 22028.467) return 511;
    return int(floor(f / 44100.0 * 1024.0 + 0.5));
}
static int limiteDaBanda(float falta) {
    return indiceDaFreq(floor(22050.0 / pow(1.035, falta)) - 1.0);
}
// A banda i do UpdateBandsNew: a média dos pontos da divisão logarítmica, nunca abaixo do ponto i + 2 (com 600 ou 1024
// bandas é sempre só esse ponto). × 0,01; o ponto 1024 em diante não existe.
static float bandaDoNode(int i, int N) {
    int zero = limiteDaBanda(float(N));
    int de = max(limiteDaBanda(float(N - i)) - zero, i + 2);
    int ate = max(limiteDaBanda(float(N - 1 - i)) - zero - 1, i + 2);
    de = min(de, ate);
    if (i == N - 1) ate = 511;
    ate = min(ate, 1023);
    if (ate < de) return 0.0;
    float soma = 0.0;
    int passo = max((ate - de) / 32, 1);
    int quantos = 0;
    for (int k = de; k <= ate; k += passo) { soma += pontoDoNode(k); quantos++; }
    return soma / float(quantos) * 0.01;
}
// O passe 0 escreve em luz linear; o buffer sRGB guarda o byte da Texture2D do Node e devolve linear ao ler.
static float4 texelDoSom(int i) {
    int N = clamp(int(u._bands_count), 1, 1024);
    if (i >= N) return float4(0.0, 0.0, 0.0, 1.0);
    float k = 1.0 - clamp(u._intensity, 0.0, 1.0);
    float b = bandaDoNode(i, N);
    float v = k > 0.0 ? 1.0 / (1.0 + exp(-b / k)) : (b > 0.0 ? 1.0 : 0.5);
    return float4(nvLinear(float3(v)), 1.0);
}
// O Repeat + Bilinear do Node, à mão: só as Quantidade de bandas primeiras colunas do buffer valem.
static float amostraDoSom(float u) {
    int N = clamp(int(u._bands_count), 1, 1024);
    float x = fract(u) * float(N) - 0.5;
    float f0 = floor(x);
    int i0 = int(f0);
    int i1 = i0 + 1 >= N ? 0 : i0 + 1;
    if (i0 < 0) i0 = N - 1;
    return mix(somImg.read(uint2(int2(i0, 0)), uint(0)).r, somImg.read(uint2(int2(i1, 0)), uint(0)).r, x - f0);
}

// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
bool u_xlatb6;
float3 u_xlat7;
float3 u_xlat8;
float3 u_xlat9;
float u_xlat11;
float u_xlat12;
float u_xlat16;
float2 u_xlat21;
float u_xlat22;
float u_xlat26;
float u_xlat30;
bool u_xlatb30;
float u_xlat32;
float u_xlat33;
float u_xlat34;
float u_xlat36;
float u_xlat37;
static void desenhoDoNode()
{
    u_xlat0.xy = in.acScreenNorm.xy * _resolution.xy;
    u_xlat0.xy = u_xlat0.xy * float2(2.0, 2.0) + (-_resolution.xy);
    u_xlat0.xy = u_xlat0.xy / _resolution.yy;
    u_xlat1.y = float(0.0);
    u_xlat21.y = float(0.0);
    u_xlat2.x = float(0.0);
    u_xlat12 = float(0.0);
    while(true){
        u_xlatb30 = u_xlat12>=8.0;
        if(u_xlatb30){break;}
        u_xlat1.x = u_xlat12 * 0.125 + u._bands_shift;
        u_xlat30 = amostraDoSom(u_xlat1.x);
        u_xlat2.x = u_xlat30 + u_xlat2.x;
        u_xlat12 = u_xlat12 + 1.0;
    }
    u_xlat0.z = 1.0;
    u_xlat30 = dot(u_xlat0.xyz, u_xlat0.xyz);
    u_xlat30 = 1.0 / sqrt(u_xlat30);
    u_xlat0.xyz = float3(u_xlat30) * u_xlat0.xyz;
    u_xlat30 = u_xlat2.x * 0.125;
    u_xlat1.x = u._frequency * 10.0;
    u_xlat1.x = float(1.0) / (-u_xlat1.x);
    u_xlat11 = (-u._color_randomize) + 1.0;
    u_xlat12 = _cur_time * 0.100000001;
    u_xlat12 = clamp(u_xlat12, 0.0, 1.0);
    u_xlat22 = u_xlat12 * -2.0 + 3.0;
    u_xlat12 = u_xlat12 * u_xlat12;
    u_xlat12 = u_xlat12 * u_xlat22;
    u_xlat12 = u_xlat12 * 0.199999988 + 0.800000012;
    u_xlat22 = u_xlat12 * 28.8539009;
    u_xlat22 = exp2(u_xlat22);
    u_xlat22 = u_xlat22 + 1.0;
    u_xlat22 = float(1.0) / u_xlat22;
    u_xlat32 = (-u_xlat12) + 1.0;
    u_xlat32 = u_xlat32 * -28.8539009;
    u_xlat32 = exp2(u_xlat32);
    u_xlat32 = u_xlat32 + 1.0;
    u_xlat32 = float(1.0) / u_xlat32;
    u_xlat32 = (-u_xlat22) + u_xlat32;
    u_xlat3.x = 0.0;
    u_xlat3.yz = float2(float2(u._phase, u._phase));
    u_xlat4.x = u._phase;
    u_xlat4.y = float(1.0);
    u_xlat4.z = float(2.0);
    u_xlat5.x = float(0.0);
    u_xlat5.y = float(0.0);
    u_xlat5.z = float(0.0);
    u_xlat33 = 0.0;
    u_xlat34 = 0.0;
    while(true){
        u_xlatb6 = u_xlat33>=30.0;
        if(u_xlatb6){break;}
        u_xlat6.xyz = u_xlat0.xyz * float3(u_xlat34);
        u_xlat7.xyz = floor(abs(u_xlat6.xyz));
        u_xlat8.xyz = fract(u_xlat6.xyz);
        u_xlat8.xyz = u_xlat8.xyz + float3(-0.5, -0.5, -0.5);
        u_xlat8.xyz = abs(u_xlat8.xyz) + (-u._shape.xyz);
        u_xlat9.xyz = max(u_xlat8.xyz, float3(0.0, 0.0, 0.0));
        u_xlat36 = dot(u_xlat9.xyz, u_xlat9.xyz);
        u_xlat36 = sqrt(u_xlat36);
        u_xlat37 = max(u_xlat8.z, u_xlat8.y);
        u_xlat37 = max(u_xlat37, u_xlat8.x);
        u_xlat37 = min(u_xlat37, 0.0);
        u_xlat36 = u_xlat36 + u_xlat37;
        u_xlat6.xyz = abs(u_xlat6.xyz) + (-u._space.xyz);
        u_xlat8.xyz = max(u_xlat6.xyz, float3(0.0, 0.0, 0.0));
        u_xlat37 = dot(u_xlat8.xyz, u_xlat8.xyz);
        u_xlat37 = sqrt(u_xlat37);
        u_xlat16 = max(u_xlat6.z, u_xlat6.y);
        u_xlat6.x = max(u_xlat16, u_xlat6.x);
        u_xlat6.x = min(u_xlat6.x, 0.0);
        u_xlat6.x = u_xlat6.x + u_xlat37;
        u_xlat6.x = (-u_xlat2.x) * 0.0250000004 + abs(u_xlat6.x);
        u_xlat6.x = max(u_xlat6.x, u_xlat36);
        u_xlat16 = (-u._frequency) * 10.0 + u_xlat7.z;
        u_xlat16 = u_xlat1.x * u_xlat16;
        u_xlat16 = clamp(u_xlat16, 0.0, 1.0);
        u_xlat26 = u_xlat16 * -2.0 + 3.0;
        u_xlat16 = u_xlat16 * u_xlat16;
        u_xlat16 = u_xlat16 * u_xlat26;
        u_xlat8.xyz = u_xlat7.xyz * float3(0.103100002, 0.103100002, 0.103100002);
        u_xlat8.xyz = fract(u_xlat8.xyz);
        u_xlat9.xyz = u_xlat8.zyx + float3(31.3199997, 31.3199997, 31.3199997);
        u_xlat26 = dot(u_xlat8.xyz, u_xlat9.xyz);
        u_xlat8.xyz = float3(u_xlat26) + u_xlat8.xyz;
        u_xlat26 = u_xlat8.y + u_xlat8.x;
        u_xlat26 = u_xlat8.z * u_xlat26;
        u_xlat26 = fract(u_xlat26);
        u_xlat26 = u_xlat26 * 1.5;
        u_xlat16 = u_xlat16 * 3.0 + u_xlat26;
        u_xlat7.xyz = u_xlat7.xyz * float3(0.400000006, 0.400000006, 0.400000006) + u_xlat3.xyz;
        u_xlat7.xyz = u_xlat4.xyz + u_xlat7.xyz;
        u_xlat7.xyz = cos(u_xlat7.xyz);
        u_xlat7.xyz = float3(u_xlat11) * float3(10.0, 10.0, 10.0) + u_xlat7.xyz;
        u_xlat7.xyz = u_xlat7.xyz * nvCor(u._colour).xyz;
        u_xlat26 = u_xlat6.x * 50.0 + (-u_xlat30);
        u_xlat26 = log2(abs(u_xlat26));
        u_xlat26 = u_xlat26 * 1.29999995;
        u_xlat26 = exp2(u_xlat26);
        u_xlat26 = u_xlat26 + 1.0;
        u_xlat7.xyz = u_xlat7.xyz / float3(u_xlat26);
        u_xlat16 = exp2(u_xlat16);
        u_xlat21.x = u_xlat16 * 0.0434999987 + u._bands_shift;
        u_xlat21.x = amostraDoSom(u_xlat21.x);
        u_xlat21.x = (-u_xlat12) + u_xlat21.x;
        u_xlat21.x = u_xlat21.x * -28.8539009;
        u_xlat21.x = exp2(u_xlat21.x);
        u_xlat21.x = u_xlat21.x + 1.0;
        u_xlat21.x = float(1.0) / u_xlat21.x;
        u_xlat21.x = (-u_xlat22) + u_xlat21.x;
        u_xlat21.x = u_xlat21.x / u_xlat32;
        u_xlat5.xyz = u_xlat7.xyz * u_xlat21.xxx + u_xlat5.xyz;
        u_xlat34 = u_xlat34 + u_xlat6.x;
        u_xlat33 = u_xlat33 + 1.0;
    }
    u_xlat0 = nvEntrada(in.acScreenNorm.xy);
    u_xlatb1 = int(u._blend_mode)==1;
    u_xlat5.w = 1.0;
    u_xlat2 = u_xlat0 * u_xlat5;
    u_xlat3.xyz = u_xlat0.xyz + u_xlat5.xyz;
    u_xlat3.w = u_xlat0.w;
    u_xlat1 = (bool(u_xlatb1)) ? u_xlat2 : u_xlat3;
    u_xlat3.xyz = u_xlat5.xyz;
    u_xlat1 = (int(u._blend_mode) != 0) ? u_xlat1 : u_xlat3;
    if(int(_use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(_show_inner_mask), int(_b_clip_mask), int(_show_inner_mask), int(_show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat3 * u_xlat4 + u_xlat0;
        u_xlat2.x = u_xlat4.x * u_xlat0.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat0.w;
        __nv_out.xyz = u_xlat0.xyz;
    } else {
        __nv_out = u_xlat1;
    }
    return;
}

fragment float4 fx_nv_nodevideo_fill_audiovisualization_neon_room(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_audiovisualization_neon_roomParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> faixasImg [[texture(1)]],
    texture2d<float> somImg [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        __nv_out = texelDoSom(int(__nv_fragCoord.x));
        return __nv_out;
    }
    desenhoDoNode();
    __nv_out = nvSaida(__nv_out);
    return __nv_out;
}
