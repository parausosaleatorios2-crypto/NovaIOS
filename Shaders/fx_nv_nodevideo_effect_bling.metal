// ---------------------------------------------------------------------------
// Effect Bling (NV)
// origem : assets/effects/nv-nodevideo-effect-bling.xml
// id     : nv.effect.nodevideo-effect-bling
// passes : 7
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_blingParams {
    int _type;
    float _amount;
    float _threshold_x;
    float _threshold_y;
    float _size;
    float _intensity;
    float _angle;
    float4 _color;
    int _blend_mode;
};

// --- funcoes auxiliares do efeito
// ---- a ponte Nova <-> Node (tools/nodeluzes/gerar.py)
float2 nvUV;   // o in.vs_TEXCOORD0 dos programas do Node: o in.acScreenNorm, ou outro ponto que o passe escolhe
float3 nvLinear(float3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(0.04045, c)); }
float3 nvGama(float3 c) { return mix(c * 12.92, 1.055 * pow(c, float3(1.0 / 2.4)) - 0.055, step(0.0031308, c)); }
// O passe 0: a camada como o Node a guarda (pre-multiplicada, luz linear; o buffer `pre` e sRGB de 8 bits).
float4 nvCor(float4 c) { return float4(nvLinear(c.rgb), c.a); }
float4 nvEntrada() { float4 c = inputImg.sample(__nv_smp, in.acScreenNorm); return float4(nvLinear(c.rgb) * c.a, c.a); }
// A saída do Node (pre-multiplicada, linear, presa a 0..1 como o RT de 8 bits) para a cor reta do Nova. A luz que
// o Node soma acima do alfa (o brilho fora do recorte) vira alfa: a = max(alfa, r, g, b). NaN (0 x infinito na
// conta do Node) vira 0, como no RT de 8 bits dele; a escolha pelo bvec não faz conta com o NaN.
float4 nvSaida(float4 p) {
    p = mix(float4(0.0), min(p, float4(1.0)), greaterThanEqual(p, float4(0.0)));
    float a = max(p.a, max(p.r, max(p.g, p.b)));
    return a > 0.0 ? float4(nvGama(p.rgb / a), a) : float4(0.0);
}
// A máscara interna do Node (o editor de máscara dele) fica desligada, como no padrão.
#define _use_inner_mask 0
#define _b_clip_mask 0
#define _show_inner_mask 0
// A grade do AEBling.InitBuffer: 512 px no lado maior da composição, o outro trunc(proporção x 512).
int2 nvGrade() {
    float2 t = eng.acTamanhoDaTela;
    return t.x <= t.y ? int2(max(int(t.x / t.y * 512.0), 2), 512) : int2(512, max(int(t.y / t.x * 512.0), 2));
}
// O ponto que a CPU do Node leva: o alfa (a luz do pixel aceso) lido em bytes, a / 255 > 0,05.
bool nvAceso(int2 c) { return floor(det.read(uint2(c), uint(0)).a * 255.0 + 0.5) > 12.75; }
// Contagens (até 65535) em dois bytes de um RGBA8.
float4 nvGuarda(int n) { n = min(n, 65535); return float4(float(n & 255), float(n >> 8), 0.0, 255.0) / 255.0; }
int nvConta(sampler2D t, int y) { float4 e = t.read(uint2(int2(0, y)), uint(0)); return int(floor(e.r * 255.0 + 0.5)) + 256 * int(floor(e.g * 255.0 + 0.5)); }
// O _threshold do Node é um Vector2 de faixa (a luz entre o mínimo e o máximo).
#define _threshold float2(u._threshold_x, u._threshold_y)

// ---- programa 0 do Node: NodeVideo_Effect_bling_0.glsl
float3 p0_x0;
float2 p0_x1;
bool p0_xb1;
float2 p0_x2;
float3 p0_x3;
float p0_x5;
bool p0_xb5;
float2 p0_x9;
bool p0_xb9;
float2 p0_x10;
bool p0_xb10;
float p0_x12;
void p0_main()
{
    p0_x0.xyz = pre.sample(__nv_smp, nvUV.xy).xyz;
    p0_x12 = dot(p0_x0.xyz, float3(0.300000012, 0.589999974, 0.109999999));
    p0_x1.x = float(0.0);
    p0_x1.y = float(0.0);
    p0_x2.x = -3.0;
    while(true){
        p0_xb9 = 3.0<p0_x2.x;
        if(p0_xb9){break;}
        p0_x9.xy = p0_x1.xy;
        p0_x2.y = -3.0;
        while(true){
            p0_xb10 = 3.0<p0_x2.y;
            if(p0_xb10){break;}
            p0_x10.xy = p0_x2.xy / eng.acTamanhoDaTela.xy;
            p0_x10.xy = p0_x10.xy + nvUV.xy;
            p0_x3.xyz = pre.sample(__nv_smp, p0_x10.xy).xyz;
            p0_x10.x = dot(p0_x3.xyz, float3(0.300000012, 0.589999974, 0.109999999));
            p0_x9.x = p0_x9.x + p0_x10.x;
            p0_x9.y = as_type<float>(as_type<int>(p0_x9.y) + 1);
            p0_x2.y = p0_x2.y + 1.0;
        }
        p0_x1.xy = p0_x9.xy;
        p0_x2.x = p0_x2.x + 1.0;
    }
    p0_x5 = float(as_type<int>(p0_x1.y));
    p0_x1.x = p0_x1.x / p0_x5;
    p0_x5 = (-u._amount) * 0.499000013 + 0.5;
    p0_x1.x = p0_x12 + (-p0_x1.x);
    p0_xb1 = p0_x5<p0_x1.x;
    p0_xb5 = _threshold.xxyx.y<p0_x12;
    p0_xb1 = p0_xb5 && p0_xb1;
    p0_xb5 = p0_x12<_threshold.xxyx.z;
    p0_xb1 = p0_xb5 && p0_xb1;
    __nv_out.w = p0_xb1 ? p0_x12 : float(0.0);
    __nv_out.xyz = p0_x0.xyz;
    return;
}

// ---- programa 1 do Node: NodeVideo_RenderCommand__blend_mode_masking_0.glsl
float4 p1_x0;
float4 p1_x1;
float4 p1_x2;
bool2 p1_xb2;
float4 p1_x3;
bool2 p1_xb3;
float4 p1_x4;
float3 p1_x5;
float3 p1_x6;
void p1_main()
{
    p1_x0 = pre.sample(__nv_smp, nvUV.xy);
    p1_x1 = spr.sample(__nv_smp, nvUV.xy);
    p1_x2 = p1_x0 * p1_x1;
    p1_xb3.xy = equal(int4(int(u._blend_mode)), int4(1, 2, 0, 0)).xy;
    p1_x4.xyz = p1_x0.xyz + p1_x1.xyz;
    p1_x5.xyz = (-p1_x1.xyz) + float3(1.0, 1.0, 1.0);
    p1_x6.xyz = (-p1_x0.xyz) + float3(1.0, 1.0, 1.0);
    p1_x5.xyz = (-p1_x5.xyz) * p1_x6.xyz + float3(1.0, 1.0, 1.0);
    p1_x4.xyz = (p1_xb3.y) ? p1_x4.xyz : p1_x5.xyz;
    p1_x4.w = p1_x0.w;
    p1_x3 = (p1_xb3.x) ? p1_x2 : p1_x4;
    p1_x2.xyz = p1_x1.xyz;
    p1_x1 = (int(u._blend_mode) != 0) ? p1_x3 : p1_x2;
    if(int(_use_inner_mask) == 0) {
        __nv_out = p1_x1;
        return;
    }
    p1_xb2.xy = equal(int4(int(_show_inner_mask), int(_b_clip_mask), int(_show_inner_mask), int(_show_inner_mask)), int4(1, 1, 0, 0)).xy;
    p1_x1 = (p1_xb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : p1_x1;
    p1_x3 = pre.sample(__nv_smp, nvUV.xy);
    p1_x4 = (-p1_x3) + float4(1.0, 1.0, 1.0, 1.0);
    p1_x0 = p1_x0 * p1_x4;
    p1_x0 = p1_x1 * p1_x3 + p1_x0;
    p1_x1.x = p1_x3.x * p1_x0.w;
    __nv_out.w = (p1_xb2.y) ? p1_x1.x : p1_x0.w;
    __nv_out.xyz = p1_x0.xyz;
    return;
}

fragment float4 fx_nv_nodevideo_effect_bling(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_blingParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pre [[texture(1)]],
    texture2d<float> det [[texture(2)]],
    texture2d<float> filas [[texture(3)]],
    texture2d<float> acum [[texture(4)]],
    texture2d<float> lista [[texture(5)]],
    texture2d<float> spr [[texture(6)]],
    texture2d<float> sprites [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    nvUV = in.acScreenNorm;
    if (eng.acPass == 0) { __nv_out = nvEntrada(); return __nv_out; }
    if (eng.acPass == 1) { int2 c = int2(__nv_fragCoord.xy), gr = nvGrade(); if (c.x >= gr.x || c.y >= gr.y) { __nv_out = float4(0.0); return __nv_out; } nvUV = (float2(c) + 0.5) / float2(gr); p0_main(); return __nv_out; }
    if (eng.acPass == 2) { int y = int(__nv_fragCoord.y), n = 0; int2 gr = nvGrade(); if (y < gr.y) for (int x = 0; x < 512; x++) { if (x < gr.x && nvAceso(int2(x, y))) n++; } __nv_out = nvGuarda(n); return __nv_out; }
    if (eng.acPass == 3) { int y = int(__nv_fragCoord.y), n = 0; for (int r = 0; r < 512; r++) { if (r <= y) n += nvConta(filas, r); } __nv_out = nvGuarda(n); return __nv_out; }
    if (eng.acPass == 4) { int2 p = int2(__nv_fragCoord.xy); int k = p.x + 64 * p.y; int2 gr = nvGrade(); int total = nvConta(acum, gr.y - 1); if (k >= 5001 || k >= total) { __nv_out = float4(0.0); return __nv_out; } int lo = 0, hi = gr.y - 1; for (int i = 0; i < 10; i++) { int m = (lo + hi) / 2; bool d = nvConta(acum, m) > k; if (lo < hi) { if (d) hi = m; else lo = m + 1; } } int j = k - (lo > 0 ? nvConta(acum, lo - 1) : 0), x = 0, n = 0; for (int i = 0; i < 512; i++) { bool a = i < gr.x && nvAceso(int2(i, lo)); if (a && n == j) x = i; if (a) n++; } __nv_out = float4(float(x & 255), float(lo & 255), float((x >> 8) + 4 * (lo >> 8) + 16), 255.0) / 255.0; return __nv_out; }
    if (eng.acPass == 5) { __nv_out = float4(0.0); return __nv_out; }
    if (eng.acPass == 6) { p1_main(); __nv_out = nvSaida(float4(__nv_out.rgb * __nv_out.a, __nv_out.a * __nv_out.a)); return __nv_out; }
    __nv_out = float4(0.0);
    return __nv_out;
}
