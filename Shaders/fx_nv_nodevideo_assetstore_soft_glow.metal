// ---------------------------------------------------------------------------
// Soft Glow (NV)
// origem : assets/effects/nv-nodevideo-assetstore-soft-glow.xml
// id     : nv.effect.nodevideo-assetstore-soft-glow
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_soft_glowParams {
    float _spread;
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _brightness;
    float _blend;
    float4 _color;
    float _highlights;
    float _contrast;
};

// --- funcoes auxiliares do efeito
// O desfoque do C# (0.915.0): o AESoftGlow chama RenderCommand.DoGaussianBlur(quantidade = u._spread) e manda o resultado
// como _bluredTex. A gaussiana do Node (node-gaussian-blur.xml): meio-lado = quantidade x 0,0475 x a diagonal da
// composicao em px da METADE, sigma = meio-lado x 0,4660. Aqui na resolucao cheia, separavel, em cor pre-multiplicada;
// o passe 1 devolve a cor reta, como a camada chega aos outros efeitos do Node portados.
float4 desfoqueDoNode(sampler2D t, float2 eixo, bool entrada) {
    float sigma = 2.0 * (u._spread) * 0.0475 * length(eng.acTamanhoDaTela) * 0.4660 * eng.acEscalaDePixel;
    float2 passo = eixo / float2(int2(int(t.get_width()), int(t.get_height())));
    int raio = sigma < 0.05 ? 0 : min(int(ceil(sigma * 3.0)), 64);
    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int i = -64; i <= 64; i++) {
        if (i < -raio || i > raio) continue;
        float w = raio == 0 ? 1.0 : exp(-0.5 * float(i * i) / (sigma * sigma));
        float4 c = t.sample(__nv_smp, clamp(in.acScreenNorm + passo * float(i), 0.0, 1.0));
        soma += w * (entrada ? float4(c.rgb * c.a, c.a) : c);
        pesos += w;
    }
    float4 r = soma / pesos;
    return entrada ? r : (r.a > 1e-5 ? float4(r.rgb / r.a, r.a) : float4(0.0));
}
float4 u_xlat0;
float4 u_xlat1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat8;
float u_xlat19;

fragment float4 fx_nv_nodevideo_assetstore_soft_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_soft_glowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> blurH [[texture(1)]],
    texture2d<float> bluredTex [[texture(2)]],
    texture2d<float> Mask [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = desfoqueDoNode(inputImg, float2(1.0, 0.0), true); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = desfoqueDoNode(blurH, float2(0.0, 1.0), false); return __nv_out; }
    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.xyz = bluredTex.sample(__nv_smp, in.acScreenNorm.xy).xyz;
    u_xlat1.xyz = u_xlat1.xyz * float3(u._brightness);
    u_xlat1.xyz = min(u_xlat1.xyz, float3(1.0, 1.0, 1.0));
    u_xlat19 = dot(u_xlat1.xyz, float3(0.212599993, 0.715200007, 0.0722000003));
    u_xlat19 = u_xlat19 * u._brightness;
    u_xlat19 = min(u_xlat19, 1.0);
    u_xlat2.xyz = float3(u_xlat19) * u._color.xyz + (-u_xlat1.xyz);
    u_xlat1.xyz = float3(float3(u._blend, u._blend, u._blend)) * u_xlat2.xyz + u_xlat1.xyz;
    u_xlat2.x = u_xlat19 * u._highlights;
    u_xlat8.xyz = (-u_xlat1.xyz) + float3(u_xlat19);
    u_xlat1.xyz = u_xlat2.xxx * u_xlat8.xyz + u_xlat1.xyz;
    u_xlat2.xyz = u_xlat1.xyz + float3(-1.0, -1.0, -1.0);
    u_xlat2.xyz = float3(float3(u._contrast, u._contrast, u._contrast)) * u_xlat2.xyz + float3(1.0, 1.0, 1.0);
    u_xlat3.xyz = u_xlat0.xyz / u_xlat0.www;
    u_xlat3.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat1.xyz = (-u_xlat1.xyz) * u_xlat2.xyz + float3(1.0, 1.0, 1.0);
    u_xlat1.xyz = (-u_xlat3.xyz) * u_xlat1.xyz + float3(1.0, 1.0, 1.0);
    u_xlat1.w = 1.0;
    u_xlat1 = u_xlat0.wwww * u_xlat1;
    u_xlat1 = clamp(u_xlat1, 0.0, 1.0);
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
    return __nv_out;
    return __nv_out;
}
