// ---------------------------------------------------------------------------
// Random Ripples (NV)
// origem : assets/effects/nv-nodevideo-effect-random-ripples.xml
// id     : nv.effect.nodevideo-effect-random-ripples
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_random_ripplesParams {
    float _amount;
    float _width;
    float _height;
    float _scale;
    float _duration;
    float _refraction;
    float _blend;
    float _seed;
};

// --- funcoes auxiliares do efeito
// globais e tempo do Node ligados ao motor (tools/nodevideo/ligar_globais.py, ligar_tempo.py)
#define _resolution eng.acTamanhoDaTela
#define _cur_time eng.acTime

// Os RTs do Node: luz linear, cor pré-multiplicada.
float3 nvLinear(float3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c)); }
float3 nvGama(float3 l) { return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l)); }
float4 nvNode(float4 c) { return float4(nvLinear(c.rgb) * c.a, c.a); }
float4 nvNova(float4 p) {
    if (p.a <= 0.0) return float4(0.0);
    return float4(nvGama(clamp(p.rgb / p.a, 0.0, 1.0)), p.a);
}

// Um float32 inteiro nos 4 bytes de um texel RGBA8.
float4 nvGuardar(float v) {
    uint u = as_type<uint>(v);
    return float4(float(u & 255u), float((u >> 8) & 255u), float((u >> 16) & 255u), float(u >> 24)) / 255.0;
}
float nvDecodificar(float4 c) {
    uint4 b = uint4(floor(c * 255.0 + 0.5));
    return as_type<float>(b.r | (b.g << 8) | (b.b << 16) | (b.a << 24));
}

// O RT limpo com zero (a 1ª vez, ou depois de pular o cursor): o Node recomeça a simulação.
bool nvNovo() { return eng.acStateFresh == 1; }

float nvTexel(int qual, int2 p) {
    // o `alt` dos passes 0 e 1 é o do quadro anterior (zero se não há); o do passe 3, o deste quadro
    if (qual == 0) return nvNovo() && eng.acPass <= 1 ? 0.0 : nvDecodificar(alt.read(uint2(p), uint(0)));
    if (qual == 1) return nvNovo() ? 0.0 : nvDecodificar(ant.read(uint2(p), uint(0)));
    return nvDecodificar(meio.read(uint2(p), uint(0)));
}

int2 nvTamanho(int qual) {
    if (qual == 0) return int2(int(alt.get_width()), int(alt.get_height()));
    if (qual == 1) return int2(int(ant.get_width()), int(ant.get_height()));
    return int2(int(meio.get_width()), int(meio.get_height()));
}

// O texture() do Node num RT float (Clamp + Bilinear), em coordenadas de texel (o centro do texel i é i + 0,5);
// `lim` = o último texel válido.
float nvLerRT(int qual, float2 px, int2 lim) {
    float2 q = px - 0.5;
    float2 i = floor(q);
    float2 f = q - i;
    int2 a = clamp(int2(i), int2(0), lim);
    int2 b = clamp(int2(i) + 1, int2(0), lim);
    float v00 = nvTexel(qual, a);
    if (f.x == 0.0 && f.y == 0.0) return v00;
    float v10 = nvTexel(qual, int2(b.x, a.y));
    float v01 = nvTexel(qual, int2(a.x, b.y));
    float v11 = nvTexel(qual, b);
    return mix(mix(v00, v10, f.x), mix(v01, v11, f.x), f.y);
}

// O buffer em pixels (o RT do Node é do tamanho da composição: na exportação, o mesmo).
float2 nvPxPorUv() { return float2(nvTamanho(0)); }
// As células da simulação (o u_xlat1 do Node): o vizinho fica a u._scale pixels da composição.
float2 nvCelulas() { return _resolution.xy / float2(float(int(u._scale))); }

/*
 * Como guardar a simulação.
 *  - As RAIAS do Node: o RT inteiro, e o vizinho a u._scale texels (são u._scale x u._scale simulações entrelaçadas, cada
 *    uma com a gota num lugar um pouco diferente). É o Node conta por conta, quando o vizinho cai num número inteiro
 *    de texels: na exportação, com o buffer do tamanho da composição.
 *  - A GRADE: uma célula por texel, no canto do estado. Na prévia reduzida o vizinho cairia entre texels, e a leitura
 *    bilinear borraria a onda a cada passo; a grade faz a mesma onda que uma raia do Node, e a imagem a lê
 *    interpolada (o que as raias vizinhas do Node dão). Sem lugar para a grade (u._scale 1 na prévia reduzida), as
 *    raias com a leitura bilinear.
 */
bool nvGrade() {
    float2 d = nvPxPorUv() / nvCelulas();
    bool inteiro = all(lessThan(abs(d - floor(d + 0.5)), float2(1e-3))) && all(greaterThan(d, float2(0.999)));
    return !inteiro && all(lessThanEqual(ceil(nvCelulas()), nvPxPorUv()));
}
int2 nvLimite(bool grade) { return grade ? int2(ceil(nvCelulas())) - 1 : nvTamanho(0) - 1; }

/*
 * O passe 0 do shader do Node, conta por conta. `atual` e `anterior` são os dois canais do RT lido (o .x e o .y):
 * 0 = alt, 1 = ant, 2 = meio. Devolve a altura nova (o .x que o Node escreve).
 */
float nvPasso(int atual, int anterior) {
    bool grade = nvGrade();
    int2 lim = nvLimite(grade);
    float2 vs_TEXCOORD0;
    float2 px;
    float2 d;   // os vizinhos, em texel do estado
    if (grade) {
        int2 c = int2(__nv_fragCoord.xy);
        if (any(greaterThan(c, lim))) return 0.0;   // fora da grade: não é lido
        px = float2(c) + 0.5;
        vs_TEXCOORD0 = px / nvCelulas();
        d = float2(1.0);
    } else {
        px = __nv_fragCoord.xy;
        vs_TEXCOORD0 = in.acScreenNorm;
        d = nvPxPorUv() / nvCelulas();
    }
    float u_xlat0;
    float2 u_xlat1;
    float2 u_xlat4;
    float u_xlat12;
    bool u_xlatb12;
    float2 u_xlat9;
    u_xlat0 = u._width * 10.0 + -2.5;
    u_xlat0 = float(1.0) / u_xlat0;
    u_xlat4.xy = float2(float2(u._seed, u._seed)) + float2(0.456665009, 0.708617985);
    u_xlat12 = _cur_time * u._amount;
    u_xlat1.x = floor(u_xlat12);
    u_xlat12 = fract(u_xlat12);
    u_xlatb12 = u_xlat12>=0.0500000007;
    u_xlat4.xy = u_xlat4.xy * u_xlat1.xx;
    u_xlat4.xy = fract(u_xlat4.xy);
    u_xlat1.xy = nvCelulas();
    u_xlat9.xy = u_xlat1.xy * vs_TEXCOORD0.xy;
    u_xlat4.xy = u_xlat4.xy * u_xlat1.xy + (-u_xlat9.xy);
    u_xlat4.x = dot(u_xlat4.xy, u_xlat4.xy);
    u_xlat4.x = sqrt(u_xlat4.x);
    u_xlat4.x = u_xlat4.x + -2.5;
    u_xlat0 = u_xlat0 * u_xlat4.x;
    u_xlat0 = clamp(u_xlat0, 0.0, 1.0);
    u_xlat4.x = u_xlat0 * -2.0 + 3.0;
    u_xlat0 = u_xlat0 * u_xlat0;
    u_xlat0 = u_xlat0 * u_xlat4.x;
    u_xlat0 = (u_xlatb12) ? 0.0 : (-u_xlat0);
    float prev = nvLerRT(anterior, px, lim);
    u_xlat12 = nvLerRT(atual, px - float2(0.0, d.y), lim);
    u_xlat12 = u_xlat12 + nvLerRT(atual, px - float2(d.x, 0.0), lim);
    u_xlat12 = u_xlat12 + nvLerRT(atual, px + float2(d.x, 0.0), lim);
    u_xlat12 = nvLerRT(atual, px + float2(0.0, d.y), lim) + u_xlat12;
    float u_xlat8 = prev + -0.5;
    float u_xlat4x = u_xlat8 * -2.0 + u_xlat12;
    u_xlat0 = u_xlat4x + u_xlat0;
    u_xlat0 = u_xlat0 + -2.0;
    u_xlat4x = (-u._duration) + 1.0;
    u_xlat4x = (-u_xlat4x) * 0.100000001 + 1.0;
    u_xlat0 = u_xlat4x * u_xlat0;
    // _frame: 0 no 1º quadro depois da limpeza
    u_xlat4x = nvNovo() ? 0.0 : 1.0;
    u_xlat0 = u_xlat4x * u_xlat0;
    return u_xlat0 * 0.5 + 0.5;
}

fragment float4 fx_nv_nodevideo_effect_random_ripples(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_random_ripplesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> alt [[texture(1)]],
    texture2d<float> ant [[texture(2)]],
    texture2d<float> meio [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = nvGuardar(nvPasso(0, 1)); return __nv_out; }   // A(.x = alt, .y = ant) -> B
    if (eng.acPass == 1) { __nv_out = nvGuardar(nvPasso(2, 0)); return __nv_out; }   // B(.x = meio, .y = o .x de A) -> A.x
    if (eng.acPass == 2) { __nv_out = meio.read(uint2(int2(__nv_fragCoord.xy)), uint(0)); return __nv_out; }   // A.y = B.x

    // O passe 1 do shader do Node, conta por conta (_channel0 = A, já com os dois passos deste quadro).
    float2 vs_TEXCOORD0 = in.acScreenNorm;
    bool grade = nvGrade();
    int2 lim = nvLimite(grade);
    // u._height / _resolution em uv: em texel do estado (na grade, a célula)
    float2 px = grade ? in.acScreenNorm * nvCelulas() : __nv_fragCoord.xy;
    float2 d = float2(u._height) * (grade ? nvCelulas() : nvPxPorUv()) / _resolution.xy;
    float4 u_xlat0;
    float4 u_xlat1;
    float4 u_xlat2;
    float u_xlat6;
    float u_xlat18 = nvLerRT(0, px - float2(0.0, d.y), lim);
    u_xlat1.x = nvLerRT(0, px - float2(d.x, 0.0), lim);
    u_xlat0.x = nvLerRT(0, px + float2(d.x, 0.0), lim);
    u_xlat6 = nvLerRT(0, px + float2(0.0, d.y), lim);
    u_xlat1.x = (-u_xlat1.x) + u_xlat0.x;
    u_xlat1.y = (-u_xlat18) + u_xlat6;
    u_xlat1.z = 1.0;
    u_xlat0.x = dot(u_xlat1.xyz, u_xlat1.xyz);
    u_xlat0.x = 1.0 / sqrt(u_xlat0.x);   // o inversesqrt do Node: as PowerVR recusaram (o CC Jaws, 05/11)
    u_xlat0.xyz = u_xlat0.xxx * u_xlat1.xyz;
    u_xlat1.xy = u_xlat0.xy * float2(float2(u._refraction, u._refraction)) + vs_TEXCOORD0.xy;
    u_xlat1 = nvNode(inputImg.sample(__nv_smp, u_xlat1.xy));
    u_xlat0.x = dot(u_xlat0.xyz, float3(0.226455405, -0.566138506, 0.792593896));
    u_xlat6 = u_xlat0.x + u_xlat0.x;
    u_xlat6 = u_xlat0.z * (-u_xlat6) + 0.792593896;
    u_xlat6 = max((-u_xlat6), 0.0);
    u_xlat6 = log2(u_xlat6);
    u_xlat6 = u_xlat6 * 32.0;
    u_xlat6 = exp2(u_xlat6);
    u_xlat0.x = max(u_xlat0.x, 0.0);
    u_xlat0 = u_xlat1 * u_xlat0.xxxx + float4(u_xlat6);
    u_xlat1 = nvNode(inputImg.sample(__nv_smp, vs_TEXCOORD0.xy));
    u_xlat2.x = (-u._blend) + 1.0;
    u_xlat2 = u_xlat1 * u_xlat2.xxxx;
    u_xlat0 = u_xlat0 * float4(float4(u._blend, u._blend, u._blend, u._blend)) + u_xlat2;
    __nv_out = nvNova(clamp(u_xlat0, 0.0, 1.0));
    return __nv_out;
}
