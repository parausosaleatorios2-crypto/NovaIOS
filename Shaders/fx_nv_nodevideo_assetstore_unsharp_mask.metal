// ---------------------------------------------------------------------------
// Unsharp Mask (NV)
// origem : assets/effects/nv-nodevideo-assetstore-unsharp-mask.xml
// id     : nv.effect.nodevideo-assetstore-unsharp-mask
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_unsharp_maskParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _amount;
    float _radius;
    float _threshold;
    float _show_mask;
};

// --- funcoes auxiliares do efeito
// O desfoque do C# (0.915.0): DoGaussianBlur(quantidade = u._radius x 0,01). A gaussiana do Node (node-gaussian-blur.xml)
// tem meio-lado = quantidade x 0,0475 x a diagonal da composicao em px da METADE, sigma = meio-lado x 0,4660; aqui na
// resolucao cheia (o dobro), separavel em dois passes, em cor pre-multiplicada.
static float4 lerPre(sampler2D t, float2 uv) { float4 c = t.sample(__nv_smp, uv); return float4(c.rgb * c.a, c.a); }
static float4 desfoque(sampler2D t, float2 eixo, bool preMultiplicar) {
    float diag = length(eng.acTamanhoDaTela);
    float sigma = 2.0 * (u._radius * 0.01) * 0.0475 * diag * 0.4660 * eng.acEscalaDePixel;
    float2 passo = eixo / float2(int2(int(t.get_width()), int(t.get_height())));
    if (sigma < 0.05) return preMultiplicar ? lerPre(t, in.acScreenNorm) : t.sample(__nv_smp, in.acScreenNorm);
    int raio = min(int(ceil(sigma * 3.0)), 48);
    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int i = -48; i <= 48; i++) {
        if (i < -raio || i > raio) continue;
        float w = exp(-0.5 * float(i * i) / (sigma * sigma));
        float2 uv = clamp(in.acScreenNorm + passo * float(i), 0.0, 1.0);
        soma += w * (preMultiplicar ? lerPre(t, uv) : t.sample(__nv_smp, uv));
        pesos += w;
    }
    return soma / pesos;
}
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
int4 u_xlati2;
bool2 u_xlatb2;
float4 u_xlat3;
int4 u_xlati3;
bool u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;

fragment float4 fx_nv_nodevideo_assetstore_unsharp_mask(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_unsharp_maskParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> blurH [[texture(1)]],
    texture2d<float> bluredTex [[texture(2)]],
    texture2d<float> Mask [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = desfoque(inputImg, float2(1.0, 0.0), true); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = desfoque(blurH, float2(0.0, 1.0), false); return __nv_out; }
    // o passe do Node, em cor pre-multiplicada como os RTs dele
    u_xlat0 = lerPre(inputImg, in.acScreenNorm.xy);
    u_xlat1 = bluredTex.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1 = u_xlat0 + (-u_xlat1);
    u_xlati2 = int4(uint4(lessThan(float4(0.0, 0.0, 0.0, 0.0), u_xlat1)) * 0xFFFFFFFFu);
    u_xlati3 = int4(uint4(lessThan(u_xlat1, float4(0.0, 0.0, 0.0, 0.0))) * 0xFFFFFFFFu);
    u_xlati2 = (-u_xlati2) + u_xlati3;
    u_xlat2 = float4(u_xlati2);
    u_xlat1 = abs(u_xlat1) + (-float4(float4(u._threshold, u._threshold, u._threshold, u._threshold)));
    u_xlat1 = max(u_xlat1, float4(0.0, 0.0, 0.0, 0.0));
    u_xlat1 = u_xlat2 * u_xlat1;
    u_xlat2.x = (-u._threshold) + 1.0;
    u_xlat1 = u_xlat1 / u_xlat2.xxxx;
    u_xlat2.xyz = u_xlat1.xyz * float3(u._amount);
    u_xlat1 = u_xlat1 * float4(u._amount) + u_xlat0;
    u_xlatb3 = int(u._show_mask)==1;
    u_xlat2.w = u_xlat0.w;
    u_xlat1 = (bool(u_xlatb3)) ? u_xlat2 : u_xlat1;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
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
    // o Nova guarda a cor reta
    __nv_out = clamp(__nv_out, 0.0, 1.0);
    __nv_out = __nv_out.a > 1e-5 ? float4(__nv_out.rgb / __nv_out.a, __nv_out.a) : float4(0.0);
    return __nv_out;
    return __nv_out;
}
