// ---------------------------------------------------------------------------
// Linha vertical (NV)
// origem : assets/effects/nv-nodevideo-fill-audiovisualization-vertical-line.xml
// id     : nv.effect.nodevideo-fill-audiovisualization-vertical-line
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_audiovisualization_vertical_lineParams {
    float4 _color1;
    float4 _color2;
    float _blend;
    float _scale;
    float _offset;
    float _feather;
    float _intensity;
    int _symmetry;
    int _blend_mode;
    int _enable;
    int _randomize;
    float _block_count;
    float _bands_count;
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

float4 u_xlat0;
float4 u_xlat1;
bool3 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
bool u_xlatb6;
float u_xlat12;
int u_xlati12;
float u_xlat18;
bool u_xlatb18;
static void desenhoDoNode()
{
    u_xlat0.x = in.acScreenNorm.x * u._scale + u._offset;
    u_xlat6.x = float(int(u._block_count));
    u_xlat6.x = u_xlat6.x * u_xlat0.x;
    u_xlat6.x = floor(u_xlat6.x);
    u_xlati12 = int(u._block_count) + int(0xFFFFFFFFu);
    u_xlat12 = float(u_xlati12);
    u_xlat6.x = u_xlat6.x / u_xlat12;
    u_xlatb18 = u_xlat6.x>=(-u_xlat6.x);
    u_xlat6.x = fract(abs(u_xlat6.x));
    u_xlat6.x = (u_xlatb18) ? u_xlat6.x : (-u_xlat6.x);
    u_xlat6.x = u_xlat12 * u_xlat6.x;
    u_xlat12 = u_xlat6.x / u_xlat12;
    u_xlatb1.xyz = lessThan(int4(0, 0, 0, 0), int4(int(u._enable), int(u._randomize), int(u._symmetry), int(u._enable))).xyz;
    u_xlat2.xz = u_xlat6.xx * float2(213.897003, 253.098007);
    u_xlat2.y = 0.0;
    u_xlat2.xyz = fract(u_xlat2.xyz);
    u_xlat6.xz = u_xlat2.yx + float2(79.7600021, 79.7600021);
    u_xlat6.x = dot(u_xlat2.xz, u_xlat6.xz);
    u_xlat2.xyz = u_xlat6.xxx + u_xlat2.xyz;
    u_xlat6.x = u_xlat2.y + u_xlat2.x;
    u_xlat6.x = u_xlat2.z * u_xlat6.x;
    u_xlat6.x = fract(u_xlat6.x);
    u_xlat6.x = (u_xlatb1.y) ? u_xlat6.x : u_xlat12;
    u_xlat0.x = (u_xlatb1.x) ? u_xlat6.x : u_xlat0.x;
    u_xlatb6 = 0.5<u_xlat0.x;
    u_xlat12 = (-u_xlat0.x) + 1.0;
    u_xlat6.x = (u_xlatb6) ? u_xlat12 : u_xlat0.x;
    u_xlat0.x = (u_xlatb1.z) ? u_xlat6.x : u_xlat0.x;
    u_xlat1.xyz = nvCor(u._color1).xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = nvCor(u._color1).xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.xyz = nvCor(u._color2).xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat2.xyz = nvCor(u._color2).xyz * u_xlat2.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.xyz = u_xlat2.xyz * nvCor(u._color2).xyz;
    u_xlat0.y = 0.0;
    u_xlat6.x = amostraDoSom(u_xlat0.x);
    u_xlat12 = u_xlat6.x * 4.0;
    u_xlat18 = (-u_xlat6.x) + 1.0;
    u_xlat12 = u_xlat18 * u_xlat12;
    u_xlat12 = log2(u_xlat12);
    u_xlat12 = u_xlat12 * u._blend;
    u_xlat12 = exp2(u_xlat12);
    u_xlat1.xyz = nvCor(u._color1).xyz * u_xlat1.xyz + (-u_xlat2.xyz);
    u_xlat1.xyz = float3(u_xlat12) * u_xlat1.xyz + u_xlat2.xyz;
    u_xlat1.xyz = u_xlat1.xyz * float3(0.00999999978, 0.00999999978, 0.00999999978);
    u_xlat0.x = (-u_xlat0.x) + u_xlat6.x;
    u_xlat1.xyz = u_xlat1.xyz / abs(u_xlat0.xxx);
    u_xlat1.w = nvCor(u._color1).w / abs(u_xlat0.x);
    u_xlat0.x = (-u._feather) + 1.0;
    u_xlat0.x = float(1.0) / u_xlat0.x;
    u_xlat0 = u_xlat0.xxxx * u_xlat1;
    u_xlat0 = clamp(u_xlat0, 0.0, 1.0);
    u_xlat1 = u_xlat0 * float4(-2.0, -2.0, -2.0, -2.0) + float4(3.0, 3.0, 3.0, 3.0);
    u_xlat0 = u_xlat0 * u_xlat0;
    u_xlat2 = u_xlat0 * u_xlat1;
    u_xlat3 = nvEntrada(in.acScreenNorm.xy);
    u_xlatb18 = int(u._blend_mode)==1;
    u_xlat4 = u_xlat2 * u_xlat3;
    u_xlat1.xyz = u_xlat1.xyz * u_xlat0.xyz + u_xlat3.xyz;
    u_xlat1.w = u_xlat2.w;
    u_xlat0 = (bool(u_xlatb18)) ? u_xlat4 : u_xlat1;
    u_xlat4.xyz = u_xlat2.xyz;
    u_xlat0 = (int(u._blend_mode) != 0) ? u_xlat0 : u_xlat4;
    if(int(_use_inner_mask) != 0) {
        u_xlatb1.xy = equal(int4(int(_show_inner_mask), int(_b_clip_mask), int(_show_inner_mask), int(_show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat2 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat3 = u_xlat3 * u_xlat5;
        u_xlat2 = u_xlat2 * u_xlat4 + u_xlat3;
        u_xlat1.x = u_xlat4.x * u_xlat2.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat2.w;
        __nv_out.xyz = u_xlat2.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return;
}

fragment float4 fx_nv_nodevideo_fill_audiovisualization_vertical_line(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_audiovisualization_vertical_lineParams&  u    [[buffer(1)]],
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
