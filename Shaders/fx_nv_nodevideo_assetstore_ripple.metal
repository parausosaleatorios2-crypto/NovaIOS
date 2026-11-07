// ---------------------------------------------------------------------------
// Ripple (NV)
// origem : assets/effects/nv-nodevideo-assetstore-ripple.xml
// id     : nv.effect.nodevideo-assetstore-ripple
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_rippleParams {
    float _count;
    float _evolution;
    float2 _position;
    float4 _color;
    float _strength;
    float _intensity;
};

// --- funcoes auxiliares do efeito
// Os RTs do Node: luz linear, cor pré-multiplicada.
float3 nvLinear(float3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c)); }
float3 nvGama(float3 l) { return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l)); }
float4 nvNode(float4 c) { return float4(nvLinear(c.rgb) * c.a, c.a); }
float4 nvNova(float4 p) {
    if (p.a <= 0.0) return float4(0.0);
    return float4(nvGama(clamp(p.rgb / p.a, 0.0, 1.0)), p.a);
}

// As três curvas da definição `_Ripple`: (tempo, valor, tangente de entrada, de saída). A 1ª nas chaves 0..3, a 2ª
// nas 4..10, a 3ª nas 11..19.
const float4 NV_CHAVES[20] = float4[20](
    float4(0.0, 0.5, 0.0, 0.0), float4(0.28238839, 0.99386597, -0.15917036, -0.15917036),
    float4(0.65961272, 0.17230801, -0.09240737, -0.09240737), float4(0.99, 0.5, 0.0, 0.0),

    float4(0.0, 0.5, 0.0, 0.0), float4(0.13742243, 0.98442906, -1.05466390, -1.05466390),
    float4(0.29294750, 0.10813284, -0.05129616, -0.05129616), float4(0.48154014, 0.79211539, 0.05180347, 0.05180347),
    float4(0.62171835, 0.29824442, 0.00806891, 0.00806891), float4(0.82213598, 0.62234515, 0.03460672, 0.03460672),
    float4(0.99, 0.5, 0.0, 0.0),

    float4(0.0, 0.5, 0.0, 0.0), float4(0.10906921, 0.98910040, -0.04458912, -0.04458912),
    float4(0.26105016, 0.11401385, 0.11808521, 0.11808521), float4(0.37284696, 0.80622840, 0.09440441, 0.09440441),
    float4(0.51656520, 0.28599104, -0.05980305, -0.05980305), float4(0.64492840, 0.59532881, -0.00247780, -0.00247780),
    float4(0.74847257, 0.39532873, 0.07517300, 0.07517300), float4(0.87567478, 0.56090033, -0.02498654, -0.02498654),
    float4(0.99, 0.5, 0.0, 0.0)
);

// AERipple::Render: u._count 1 e 2 escolhem a 1ª e a 2ª textura; qualquer outro valor, a 3ª.
int nvQual() { int c = int(u._count); return c == 1 ? 0 : (c == 2 ? 1 : 2); }

// AnimationCurve.Evaluate (weightedMode 0, pré e pós presos).
float nvCurva(float t) {
    int q = nvQual();
    int ini = q == 0 ? 0 : (q == 1 ? 4 : 11);
    int n = q == 0 ? 4 : (q == 1 ? 7 : 9);
    if (t <= NV_CHAVES[ini].x) return NV_CHAVES[ini].y;
    if (t >= NV_CHAVES[ini + n - 1].x) return NV_CHAVES[ini + n - 1].y;
    for (int j = 0; j < 8; j++) {
        if (j >= n - 1) break;
        float4 k0 = NV_CHAVES[ini + j];
        float4 k1 = NV_CHAVES[ini + j + 1];
        if (t > k1.x) continue;
        float dt = k1.x - k0.x;
        float s = (t - k0.x) / dt;
        float s2 = s * s;
        float s3 = s2 * s;
        return (2.0 * s3 - 3.0 * s2 + 1.0) * k0.y + (s3 - 2.0 * s2 + s) * dt * k0.w
             + (-2.0 * s3 + 3.0 * s2) * k1.y + (s3 - s2) * dt * k1.z;
    }
    return NV_CHAVES[ini + n - 1].y;
}

// _GradTex.sample(__nv_smp, (x, 0)).w: a curva no lugar (Clamp). O Node lê a textura de 8 bits com mipmap (Trilinear), que
// alisa o degrau dos 8 bits; a curva sem degrau fica tão perto dele quanto imitar o mipmap (ver o topo do arquivo).
float nvGradTex(float x) { return clamp(nvCurva(clamp(x, 0.0, 2047.0 / 2048.0)), 0.0, 1.0); }

// _SourceTex.sample(__nv_smp, uv) do Node: o RT da camada em sRGB de 8 bits, que a GPU filtra em luz linear (pré-multiplicada,
// Clamp + Bilinear). O filtro é feito à mão sobre os 4 texels já em luz linear: com o deslocamento fracionário em
// toda a imagem, filtrar a cor sRGB (o texture() comum) mudava as bordas em até 50 níveis.
float4 nvFonte(float2 uv) {
    int2 n = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float2 q = uv * float2(n) - 0.5;
    float2 i = floor(q);
    float2 f = q - i;
    int2 a = clamp(int2(i), int2(0), n - 1);
    int2 b = clamp(int2(i) + 1, int2(0), n - 1);
    float4 c00 = nvNode(inputImg.read(uint2(a), uint(0)));
    float4 c10 = nvNode(inputImg.read(uint2(int2(b.x, a.y)), uint(0)));
    float4 c01 = nvNode(inputImg.read(uint2(int2(a.x, b.y)), uint(0)));
    float4 c11 = nvNode(inputImg.read(uint2(b), uint(0)));
    return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

fragment float4 fx_nv_nodevideo_assetstore_ripple(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_rippleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 vs_TEXCOORD0 = in.acScreenNorm;
    // O lugar da gota no uv da composição, Y para cima (no buffer de camada chega com o Y para baixo).
    float2 pos = eng.acEntradaDePe == 1 ? u._position : float2(u._position.x, 1.0 - u._position.y);
    float proporcao = eng.acTamanhoDaTela.x / eng.acTamanhoDaTela.y;   // ResWidth / ResHeight
    float3 _Drop1 = float3(pos.x * proporcao, pos.y, 0.0);
    float4 _Reflection = float4(nvLinear(u._color.rgb), u._color.a);
    float4 _Params1 = float4(proporcao, 1.0, 1.0, 0.0);
    float4 _Params2 = float4(1.0, 1.0 / proporcao, u._strength, u._intensity);

    // O programa do Node, conta por conta.
    float4 u_xlat0;
    float4 u_xlat1;
    bool2 u_xlatb1;
    float4 u_xlat2;
    float2 u_xlat12;
    float2 u_xlat13;
    bool2 u_xlatb13;
    float2 u_xlat14;
    float u_xlat6;
    float u_xlat18;
    u_xlat0.xy = vs_TEXCOORD0.yx * _Params1.yx;
    u_xlat1 = vs_TEXCOORD0.xyxy * _Params1.xyxy + (-_Drop1.xyxy);
    u_xlat12.x = dot(u_xlat1.xy, u_xlat1.xy);
    u_xlat12.x = sqrt(u_xlat12.x);
    u_xlat2.x = (-u_xlat12.x) * _Params1.z + u._evolution;
    u_xlat12.x = nvGradTex(u_xlat2.x);
    u_xlat12.x = u_xlat12.x + -0.5;
    u_xlat12.x = u_xlat12.x + u_xlat12.x;
    u_xlat1.xw = u_xlat1.zw + float2(0.00999999978, 0.00999999978);
    u_xlat1.yz = u_xlat0.xy + (-_Drop1.yx);
    u_xlat0.x = dot(u_xlat1.xy, u_xlat1.xy);
    u_xlat0.x = sqrt(u_xlat0.x);
    u_xlat14.x = (-u_xlat0.x) * _Params1.z + u._evolution;
    u_xlat0.x = nvGradTex(u_xlat14.x);
    u_xlat0.x = u_xlat0.x + -0.5;
    u_xlat0.x = u_xlat0.x * 2.0 + (-u_xlat12.x);
    u_xlat18 = dot(u_xlat1.zw, u_xlat1.zw);
    u_xlat18 = sqrt(u_xlat18);
    u_xlat1.x = (-u_xlat18) * _Params1.z + u._evolution;
    u_xlat18 = nvGradTex(u_xlat1.x);
    u_xlat18 = u_xlat18 + -0.5;
    u_xlat0.y = u_xlat18 * 2.0 + (-u_xlat12.x);
    u_xlat12.xy = u_xlat0.xy * _Params2.xy;
    u_xlat12.xy = u_xlat12.xy * _Params2.zz;
    u_xlat12.xy = u_xlat12.xy * float2(0.200000003, 0.200000003) + vs_TEXCOORD0.xy;
    u_xlatb1.xy = lessThan(u_xlat12.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb13.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat12.xyxy).xy;
    u_xlat2.xy = fract(u_xlat12.xy);
    u_xlat2.xy = (-u_xlat2.xy) + float2(1.0, 1.0);
    u_xlat13.x = (u_xlatb13.x) ? u_xlat2.x : u_xlat12.x;
    u_xlat13.y = (u_xlatb13.y) ? u_xlat2.y : u_xlat12.y;
    u_xlat12.x = (u_xlatb1.x) ? (-u_xlat12.x) : u_xlat13.x;
    u_xlat12.y = (u_xlatb1.y) ? (-u_xlat12.y) : u_xlat13.y;
    u_xlat1 = nvFonte(u_xlat12.xy);
    u_xlat0.x = dot(u_xlat0.xy, u_xlat0.xy);
    u_xlat0.x = sqrt(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * _Params2.w;
    u_xlat0.x = u_xlat0.x * 3.0;
    u_xlat6 = u_xlat0.x * u_xlat0.x;
    u_xlat0.x = u_xlat6 * u_xlat0.x;
    u_xlat2 = (-u_xlat1) + _Reflection;
    u_xlat0 = u_xlat0.xxxx * u_xlat2 + u_xlat1;
    __nv_out = nvNova(clamp(u_xlat0, 0.0, 1.0));
    return __nv_out;
}
