// ---------------------------------------------------------------------------
// Vidro líquido (NV)
// origem : assets/effects/nv-nodevideo-effect-liquid-glass.xml
// id     : nv.effect.nodevideo-effect-liquid-glass
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_liquid_glassParams {
    float2 centro;
    float2 tamanho;
    float rotacao;
    float desfoque;
    int modoDoCanto;
    float2 topo;
    float2 inferior;
    float raioDoCanto;
    float curvaturaDoCanto;
    float anel;
    int modoDoPreenchimento;
    float saturacao;
    float brilho;
    float4 corDoPreenchimento;
    float opacidade;
    float achatar;
    float larguraDoChanfro;
    float curvaturaDoChanfro;
    float elevacao;
    int modoDaRefracao;
    float intensidade;
    float dispersao;
    int brilhoDaBorda;
    float direcao1;
    float direcao2;
    float4 cor1;
    float4 cor2;
    float envolver;
    float nitidez;
};

// --- funcoes auxiliares do efeito
float3 linear(float3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c));
}
float3 srgb(float3 l) {
    l = clamp(l, 0.0, 1.0);
    return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l));
}
// O texel de pé (a linha 0 é a base, como nos RTs do Node): no buffer de camada a linha é espelhada.
float4 texelDePe(sampler2D img) {
    int2 T = int2(int(img.get_width()), int(img.get_height()));
    int2 p = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
    if (eng.acEntradaDePe != 1) p.y = T.y - 1 - p.y;
    return img.read(uint2(p), uint(0));
}
// O DoGaussianBlur do Node na metade do u.tamanho: sigma = |Desfoque| × 0,0475 × diagonal × 0,4660 (px da metade).
float4 gaussiana(sampler2D t, float2 eixo) {
    float sigma = abs(u.desfoque) * 0.0475 * length(eng.acTamanhoDaTela) * 0.4660 * eng.acEscalaDePixel;
    if (abs(u.desfoque) < 0.0001 || sigma < 0.05) return t.sample(__nv_smp, in.acScreenNorm);
    float2 T = float2(int2(int(t.get_width()), int(t.get_height())));
    float passo = max(1.0, sigma * 3.0 / 48.0);
    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int i = -48; i <= 48; i++) {
        float d = float(i) * passo;
        if (abs(d) > sigma * 3.0 + 0.5) continue;
        float w = exp(-0.5 * d * d / (sigma * sigma));
        soma += w * t.sample(__nv_smp, clamp(in.acScreenNorm + eixo * d / T, 0.0, 1.0));
        pesos += w;
    }
    return soma / pesos;
}

// Os uniforms que o C# do Node monta (ver o cabeçalho), aqui contas dos controles.
#define _resolution eng.acTamanhoDaTela
#define _viewport_ratio eng.acProporcaoDoNode
float2 vs_TEXCOORD0;
float sinalDoY;
float2 _center;
float4 _BoxSize;
float4 _Radii;
float _rotation;
float _CornerCurvature;
float _BevelWidth;
float _FilletCurvature;
float _RingThickness;
float _Elevation;
float4 _ForegroundColor;
float _ForegroundOpacity;
float _Vibrancy;
float _Brightness;
float _Flatten;
float _RefractiveIndex;
float4 _RefractiveIndexRatios;
float2 _Glint1Dir;
float2 _Glint2Dir;
float4 _Glint1Color;
float4 _Glint2Color;
float _GlintWrap;
float _GlintSharpness;
int _refraction_mode;
int _background_mode;
int _enable_edge_glint;
int _blur_invert;

// AELiquidGlass.GetRefractiveIndexRatios
float3 razoes(float n, float D) {
    n = n < 1.0 ? 1.0 : n;
    D = D < 0.0 ? 0.0 : D;
    if (D == 0.0) return float3(1.0 / n);
    float B = (n - 1.0) * D / (1.909654 - D * 0.017080);
    float A = n - 2.8795669 * B;
    float3 invL2 = 1.0 / (float3(0.63, 0.532, 0.467) * float3(0.63, 0.532, 0.467));
    return 1.0 / (A + B * invL2);
}

void ligar() {
    _center = eng.acEntradaDePe == 1 ? u.centro : float2(u.centro.x, 1.0 - u.centro.y);
    _BoxSize = float4(max(u.tamanho, 0.0) * 0.5, 0.0, 0.0);
    if (int(u.modoDoCanto) == 1) _Radii = float4(max(u.topo.y, 0.0), max(u.inferior.y, 0.0), max(u.topo.x, 0.0), max(u.inferior.x, 0.0)) * 0.5;
    else _Radii = float4(max(u.raioDoCanto, 0.0) * 0.5);
    _rotation = u.rotacao;
    _CornerCurvature = max(u.curvaturaDoCanto, 0.0) + 1.001;
    _BevelWidth = max(u.larguraDoChanfro, 0.0);
    _FilletCurvature = max(u.curvaturaDoChanfro, 0.0) + 1.001;
    _RingThickness = max(u.anel, 0.0);
    _Elevation = max(u.elevacao, 0.0);
    _ForegroundColor = float4(linear(u.corDoPreenchimento.rgb), u.corDoPreenchimento.a);
    _ForegroundOpacity = clamp(u.opacidade, 0.0, 1.0);
    _Vibrancy = clamp(u.saturacao, -1.0, 2.0);
    _Brightness = clamp(u.brilho, -1.0, 1.0);
    _Flatten = clamp(u.achatar, 0.0, 1.0);
    _refraction_mode = int(u.modoDaRefracao);
    _RefractiveIndex = max(u.intensidade, 0.0) + 1.0;
    _RefractiveIndexRatios = float4(razoes(_RefractiveIndex, max(u.dispersao, 0.0)), 0.0);
    _background_mode = int(u.modoDoPreenchimento);
    float a1 = u.direcao1 * 0.017453292, a2 = u.direcao2 * 0.017453292;
    _Glint1Dir = float2(cos(a1), -sin(a1));
    _Glint2Dir = float2(cos(a2), -sin(a2));
    _Glint1Color = float4(linear(u.cor1.rgb), u.cor1.a);
    _Glint2Color = float4(linear(u.cor2.rgb), u.cor2.a);
    _GlintWrap = clamp(u.envolver, 0.0, 1.0) * 2.0;
    _GlintSharpness = clamp(u.nitidez, 0.0, 1.0) * 150.0 + 0.1;
    _enable_edge_glint = u.brilhoDaBorda ? 1 : -1;
    _blur_invert = u.desfoque >= 0.0 ? -1 : 1;
}

// ---- O programa do Node (NodeVideo/Effect/liquid_glass), conta por conta: _SourceTex = camadaRt,
// _background = fundoRt. A única troca: o dFdy × sinalDoY (no buffer de camada a linha cresce para baixo).
float4 saidaDoNode;
float2 u_xlat0;
bool u_xlatb0;
float4 u_xlat1;
int u_xlati1;
bool u_xlatb1;
float4 u_xlat2;
int u_xlati2;
bool u_xlatb2;
float3 u_xlat3;
float3 u_xlat4;
int2 u_xlati4;
float3 u_xlat5;
float2 u_xlat7;
float3 u_xlat8;
float2 u_xlat11;
float2 u_xlat12;
int u_xlati12;
bool u_xlatb12;
float2 u_xlat13;
int u_xlati13;
bool u_xlatb13;
float2 u_xlat14;
int2 u_xlati14;
bool2 u_xlatb14;
float u_xlat15;
float u_xlat18;
int u_xlati18;
bool u_xlatb18;
float u_xlat19;
int u_xlati19;
bool u_xlatb19;
bool u_xlatb20;
float u_xlat21;
bool u_xlatb21;
void programaDoNode()
{
    u_xlat0.xy = vs_TEXCOORD0.xy + (-_center.xy);
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat12.x = _rotation * 0.0174532924;
    u_xlat1.x = sin(u_xlat12.x);
    u_xlat2.x = cos(u_xlat12.x);
    u_xlat3.x = sin((-u_xlat12.x));
    u_xlat3.y = u_xlat2.x;
    u_xlat2.x = dot(u_xlat3.yx, u_xlat0.xy);
    u_xlat3.z = u_xlat1.x;
    u_xlat2.y = dot(u_xlat3.zy, u_xlat0.xy);
    u_xlat0.xy = vs_TEXCOORD0.xy * _resolution.xy;
    u_xlat12.xy = (-float2(float2(_RingThickness, _RingThickness))) * float2(0.5, 0.5) + _BoxSize.xy;
    u_xlat1 = (-float4(float4(_RingThickness, _RingThickness, _RingThickness, _RingThickness))) * float4(0.5, 0.5, 0.5, 0.5) + _Radii;
    u_xlatb14.xy = lessThan(float4(0.0, 0.0, 0.0, 0.0), u_xlat2.xyxy).xy;
    u_xlat1.xy = (u_xlatb14.x) ? u_xlat1.xy : u_xlat1.zw;
    u_xlat1.x = (u_xlatb14.y) ? u_xlat1.x : u_xlat1.y;
    u_xlat12.xy = (-u_xlat12.xy) + abs(u_xlat2.xy);
    u_xlat12.xy = u_xlat1.xx + u_xlat12.xy;
    u_xlat7.xy = max(u_xlat12.xy, float2(0.0, 0.0));
    u_xlat19 = max(u_xlat7.y, u_xlat7.x);
    u_xlat14.x = min(u_xlat7.y, u_xlat7.x);
    u_xlatb20 = u_xlat19!=0.0;
    u_xlat19 = log2(u_xlat19);
    u_xlat14.x = log2(u_xlat14.x);
    u_xlat3.x = u_xlat19 * _CornerCurvature;
    u_xlat14.x = u_xlat14.x * _CornerCurvature + (-u_xlat3.x);
    u_xlat14.x = exp2(u_xlat14.x);
    u_xlat14.x = u_xlat14.x + 1.0;
    u_xlat14.x = log2(u_xlat14.x);
    u_xlat19 = u_xlat19 * _CornerCurvature + u_xlat14.x;
    u_xlat19 = u_xlat19 / _CornerCurvature;
    u_xlat19 = exp2(u_xlat19);
    u_xlat19 = u_xlatb20 ? u_xlat19 : float(0.0);
    u_xlat14.x = max(u_xlat12.y, u_xlat12.x);
    u_xlat14.x = min(u_xlat14.x, 0.0);
    u_xlat14.x = u_xlat19 + u_xlat14.x;
    u_xlat3.x = (-u_xlat1.x) + u_xlat14.x;
    u_xlati14.xy = int2(uint2(lessThan(float4(0.0, 0.0, 0.0, 0.0), u_xlat2.xyxy).xy) * 0xFFFFFFFFu);
    u_xlati4.xy = int2(uint2(lessThan(u_xlat2.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy) * 0xFFFFFFFFu);
    u_xlati14.xy = (-u_xlati14.xy) + u_xlati4.xy;
    u_xlat14.xy = float2(u_xlati14.xy);
    u_xlatb1 = 0.0<u_xlat19;
    u_xlat7.xy = u_xlat7.xy / float2(u_xlat19);
    u_xlat4.xy = float2(_CornerCurvature, _FilletCurvature) + float2(-1.0, -1.0);
    u_xlat7.xy = log2(u_xlat7.xy);
    u_xlat7.xy = u_xlat7.xy * u_xlat4.xx;
    u_xlat7.xy = exp2(u_xlat7.xy);
    u_xlat1.xy = bool(u_xlatb1) ? u_xlat7.xy : float2(0.0, 0.0);
    u_xlatb13 = u_xlat12.x>=u_xlat12.y;
    u_xlat4.xz = as_type<float>(uint2(lessThan(u_xlat12.xxyx, float4(0.0, 0.0, 0.0, 0.0)).xz) * 0xFFFFFFFFu);
    u_xlati13 = u_xlatb13 ? as_type<int>(u_xlat4.x) : int(0);
    u_xlati13 = int(uint(uint(u_xlati13) & 1u));
    u_xlatb12 = u_xlat12.x<u_xlat12.y;
    u_xlati12 = u_xlatb12 ? as_type<int>(u_xlat4.z) : int(0);
    u_xlati12 = int(uint(uint(u_xlati12) & 1u));
    u_xlat11.x = float(u_xlati13);
    u_xlat11.y = float(u_xlati12);
    u_xlat12.xy = u_xlat1.xy + u_xlat11.xy;
    u_xlat3.yz = u_xlat14.xy * u_xlat12.xy;
    u_xlatb12 = 0.0<_RingThickness;
    u_xlati18 = int((0.0<u_xlat3.x) ? 0xFFFFFFFFu : uint(0));
    u_xlati1 = int((u_xlat3.x<0.0) ? 0xFFFFFFFFu : uint(0));
    u_xlati18 = (-u_xlati18) + u_xlati1;
    u_xlat18 = float(u_xlati18);
    u_xlat1.yz = float2(u_xlat18) * u_xlat3.yz;
    u_xlat1.x = (-_RingThickness) * 0.5 + abs(u_xlat3.x);
    u_xlat1.xyz = (bool(u_xlatb12)) ? u_xlat1.xyz : u_xlat3.xyz;
    u_xlat12.x = (-u_xlat1.x) / _BevelWidth;
    u_xlat12.x = clamp(u_xlat12.x, 0.0, 1.0);
    u_xlat12.x = (-u_xlat12.x) + 1.0;
    u_xlat12.x = log2(u_xlat12.x);
    u_xlat18 = u_xlat12.x * _FilletCurvature;
    u_xlat18 = exp2(u_xlat18);
    u_xlat18 = (-u_xlat18) + 1.0;
    u_xlat19 = float(1.0) / _FilletCurvature;
    u_xlat18 = log2(u_xlat18);
    u_xlat12.x = u_xlat12.x * u_xlat4.y;
    u_xlat3.x = exp2(u_xlat12.x);
    u_xlat12.x = (-u_xlat19) + 1.0;
    u_xlat12.x = u_xlat18 * u_xlat12.x;
    u_xlat3.y = exp2(u_xlat12.x);
    u_xlat12.x = dot(u_xlat3.xy, u_xlat3.xy);
    u_xlat12.x = rsqrt(u_xlat12.x);
    u_xlat14.xy = u_xlat12.xx * u_xlat3.xy;
    u_xlat3.xy = dfdy(u_xlat2.xy) * sinalDoY;
    u_xlat3.y = dot(u_xlat1.yz, u_xlat3.xy);
    u_xlat2.xy = dfdx(u_xlat2.xy);
    u_xlat3.x = dot(u_xlat1.yz, u_xlat2.xy);
    u_xlat12.x = dot(u_xlat3.xy, u_xlat3.xy);
    u_xlat12.x = max(u_xlat12.x, 9.99999994e-09);
    u_xlat12.x = rsqrt(u_xlat12.x);
    u_xlat7.xy = u_xlat12.xx * u_xlat3.xy;
    u_xlat3.xy = u_xlat14.xx * u_xlat7.xy;
    u_xlat12.x = u_xlat12.x * (-u_xlat1.x);
    u_xlat12.x = u_xlat12.x * 0.707106769;
    u_xlat12.x = clamp(u_xlat12.x, 0.0, 1.0);
    if(_refraction_mode == 0) {
        u_xlatb1 = 0<_blur_invert;
        if(u_xlatb1){
            u_xlat4.xyz = camadaRt.sample(__nv_smp, vs_TEXCOORD0.xy).xyz;
        }
        if(!u_xlatb1){
            u_xlat4.xyz = fundoRt.sample(__nv_smp, vs_TEXCOORD0.xy).xyz;
        }
    } else {
        u_xlat18 = u_xlat18 * u_xlat19;
        u_xlat18 = exp2(u_xlat18);
        u_xlat3.z = (-u_xlat14.y);
        u_xlat18 = u_xlat18 * _BevelWidth + _Elevation;
        u_xlatb1 = _refraction_mode==1;
        if(u_xlatb1){
            u_xlat1.z = float(1.0) / _RefractiveIndex;
            u_xlat19 = u_xlat1.z * u_xlat1.z;
            u_xlat2.x = (-u_xlat14.y) * u_xlat14.y + 1.0;
            u_xlat19 = (-u_xlat19) * u_xlat2.x + 1.0;
            u_xlat19 = sqrt(u_xlat19);
            u_xlat19 = u_xlat1.z * u_xlat3.z + u_xlat19;
            u_xlat1.x = float(0.0);
            u_xlat1.y = float(0.0);
            u_xlat1.xyz = (-float3(u_xlat19)) * u_xlat3.xyz + u_xlat1.xyz;
            u_xlat1.xy = float2(u_xlat18) * u_xlat1.xy;
            u_xlat13.xy = u_xlat1.zz * _resolution.xy;
            u_xlat1.xy = u_xlat1.xy / u_xlat13.xy;
            u_xlat1.xy = u_xlat1.xy + vs_TEXCOORD0.xy;
            u_xlatb13 = 0<_blur_invert;
            if(u_xlatb13){
                u_xlat4.xyz = camadaRt.sample(__nv_smp, u_xlat1.xy).xyz;
            }
            if(!u_xlatb13){
                u_xlat4.xyz = fundoRt.sample(__nv_smp, u_xlat1.xy).xyz;
            }
        } else {
            u_xlatb1 = _refraction_mode==2;
            if(u_xlatb1){
                u_xlat1.xyz = _RefractiveIndexRatios.xyz * _RefractiveIndexRatios.xyz;
                u_xlat19 = (-u_xlat14.y) * u_xlat14.y + 1.0;
                u_xlat1.xyz = (-u_xlat1.xyz) * float3(u_xlat19) + float3(1.0, 1.0, 1.0);
                u_xlat1.xyz = sqrt(u_xlat1.xyz);
                u_xlat1.xyz = _RefractiveIndexRatios.xyz * u_xlat3.zzz + u_xlat1.xyz;
                u_xlat5.x = 0.0;
                u_xlat5.z = _RefractiveIndexRatios.x;
                u_xlat2.xyw = (-u_xlat1.xxx) * u_xlat3.xyz + u_xlat5.xxz;
                u_xlat1.xw = float2(u_xlat18) * u_xlat2.xy;
                u_xlat2.xy = u_xlat2.ww * _resolution.xy;
                u_xlat1.xw = u_xlat1.xw / u_xlat2.xy;
                u_xlat1.xw = u_xlat1.xw + vs_TEXCOORD0.xy;
                u_xlatb2 = 0<_blur_invert;
                if(u_xlatb2){
                    u_xlat4.x = camadaRt.sample(__nv_smp, u_xlat1.xw).x;
                }
                if(!u_xlatb2){
                    u_xlat4.x = fundoRt.sample(__nv_smp, u_xlat1.xw).x;
                }
                u_xlat5.x = 0.0;
                u_xlat5.z = _RefractiveIndexRatios.y;
                u_xlat1.xyw = (-u_xlat1.yyy) * u_xlat3.xyz + u_xlat5.xxz;
                u_xlat1.xy = float2(u_xlat18) * u_xlat1.xy;
                u_xlat8.xz = u_xlat1.ww * _resolution.xy;
                u_xlat1.xy = u_xlat1.xy / u_xlat8.xz;
                u_xlat1.xy = u_xlat1.xy + vs_TEXCOORD0.xy;
                if(u_xlatb2){
                    u_xlat4.y = camadaRt.sample(__nv_smp, u_xlat1.xy).y;
                }
                if(!u_xlatb2){
                    u_xlat4.y = fundoRt.sample(__nv_smp, u_xlat1.xy).y;
                }
                u_xlat5.x = 0.0;
                u_xlat5.z = _RefractiveIndexRatios.z;
                u_xlat1.xyz = (-u_xlat1.zzz) * u_xlat3.xyz + u_xlat5.xxz;
                u_xlat1.xy = float2(u_xlat18) * u_xlat1.xy;
                u_xlat13.xy = u_xlat1.zz * _resolution.xy;
                u_xlat1.xy = u_xlat1.xy / u_xlat13.xy;
                u_xlat1.xy = u_xlat1.xy + vs_TEXCOORD0.xy;
                if(u_xlatb2){
                    u_xlat4.z = camadaRt.sample(__nv_smp, u_xlat1.xy).z;
                }
                if(!u_xlatb2){
                    u_xlat4.z = fundoRt.sample(__nv_smp, u_xlat1.xy).z;
                }
            }
        }
    }
    if(_background_mode == 0) {
        u_xlat1.xyz = (-u_xlat4.xyz) + float3(0.5, 0.5, 0.5);
        u_xlat1.xyz = u_xlat1.xyz * float3(float3(_Flatten, _Flatten, _Flatten)) + u_xlat4.xyz;
        u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
        u_xlat18 = dot(u_xlat1.xyz, float3(0.212672904, 0.715152204, 0.0721750036));
        u_xlat1.xyz = (-float3(u_xlat18)) + u_xlat1.xyz;
        u_xlat1.xyz = float3(float3(_Vibrancy, _Vibrancy, _Vibrancy)) * u_xlat1.xyz + float3(u_xlat18);
        u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
        u_xlat18 = _Brightness * _Brightness;
        u_xlati19 = int((0.0<_Brightness) ? 0xFFFFFFFFu : uint(0));
        u_xlati2 = int((_Brightness<0.0) ? 0xFFFFFFFFu : uint(0));
        u_xlati19 = (-u_xlati19) + u_xlati2;
        u_xlat19 = float(u_xlati19);
        u_xlat1.xyz = float3(u_xlat18) * float3(u_xlat19) + u_xlat1.xyz;
        u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
        u_xlat2.xyw = (-u_xlat1.xyz) + _ForegroundColor.xyz;
        u_xlat1.xyz = float3(_ForegroundOpacity) * u_xlat2.xyw + u_xlat1.xyz;
    } else {
        u_xlat18 = _Brightness * 0.5 + 0.5;
        u_xlat19 = dot(u_xlat4.xyz, float3(0.212672904, 0.715152204, 0.0721750036));
        u_xlat2.xyw = (-float3(u_xlat19)) + u_xlat4.xyz;
        u_xlat2.xyw = float3(float3(_Vibrancy, _Vibrancy, _Vibrancy)) * u_xlat2.xyw + float3(u_xlat19);
        u_xlat4.xyz = float3(u_xlat18) * float3(u_xlat18) + (-u_xlat2.xyw);
        u_xlat2.xyw = u_xlat4.xyz * float3(float3(_Flatten, _Flatten, _Flatten)) + u_xlat2.xyw;
        u_xlat19 = dot(u_xlat2.xyw, float3(0.212672904, 0.715152204, 0.0721750036));
        u_xlat18 = u_xlat18 * u_xlat18 + (-u_xlat19);
        u_xlat4.xyz = float3(u_xlat18) + u_xlat2.xyw;
        u_xlat18 = dot(u_xlat4.xyz, float3(0.212672904, 0.715152204, 0.0721750036));
        u_xlat19 = min(u_xlat4.y, u_xlat4.x);
        u_xlat19 = min(u_xlat4.z, u_xlat19);
        u_xlat15 = max(u_xlat4.y, u_xlat4.x);
        u_xlat15 = max(u_xlat4.z, u_xlat15);
        u_xlatb21 = u_xlat19<0.0;
        u_xlat5.xyz = (-float3(u_xlat18)) + u_xlat4.xyz;
        u_xlat5.xyz = float3(u_xlat18) * u_xlat5.xyz;
        u_xlat19 = u_xlat18 + (-u_xlat19);
        u_xlat5.xyz = u_xlat5.xyz / float3(u_xlat19);
        u_xlat5.xyz = float3(u_xlat18) + u_xlat5.xyz;
        u_xlat4.xyz = (bool(u_xlatb21)) ? u_xlat5.xyz : u_xlat4.xyz;
        u_xlatb19 = 1.0<u_xlat15;
        u_xlat5.xyz = (-float3(u_xlat18)) + u_xlat4.xyz;
        u_xlat21 = (-u_xlat18) + 1.0;
        u_xlat5.xyz = float3(u_xlat21) * u_xlat5.xyz;
        u_xlat15 = (-u_xlat18) + u_xlat15;
        u_xlat5.xyz = u_xlat5.xyz / float3(u_xlat15);
        u_xlat5.xyz = float3(u_xlat18) + u_xlat5.xyz;
        u_xlat4.xyz = (bool(u_xlatb19)) ? u_xlat5.xyz : u_xlat4.xyz;
        u_xlat4.xyz = (-u_xlat2.xyw) + u_xlat4.xyz;
        u_xlat2.xyw = float3(_ForegroundOpacity) * u_xlat4.xyz + u_xlat2.xyw;
        u_xlat4.xyz = u_xlat2.xyw * _ForegroundColor.xyz;
        u_xlat18 = dot(u_xlat4.xyz, float3(0.212672904, 0.715152204, 0.0721750036));
        u_xlat19 = min(u_xlat4.y, u_xlat4.x);
        u_xlat19 = min(u_xlat4.z, u_xlat19);
        u_xlat15 = max(u_xlat4.y, u_xlat4.x);
        u_xlat15 = max(u_xlat4.z, u_xlat15);
        u_xlatb21 = u_xlat19<0.0;
        u_xlat2.xyw = u_xlat2.xyw * _ForegroundColor.xyz + (-float3(u_xlat18));
        u_xlat2.xyw = float3(u_xlat18) * u_xlat2.xyw;
        u_xlat19 = u_xlat18 + (-u_xlat19);
        u_xlat2.xyw = u_xlat2.xyw / float3(u_xlat19);
        u_xlat2.xyw = float3(u_xlat18) + u_xlat2.xyw;
        u_xlat2.xyw = (bool(u_xlatb21)) ? u_xlat2.xyw : u_xlat4.xyz;
        u_xlatb19 = 1.0<u_xlat15;
        u_xlat4.xyz = (-float3(u_xlat18)) + u_xlat2.xyw;
        u_xlat21 = (-u_xlat18) + 1.0;
        u_xlat4.xyz = float3(u_xlat21) * u_xlat4.xyz;
        u_xlat15 = (-u_xlat18) + u_xlat15;
        u_xlat4.xyz = u_xlat4.xyz / float3(u_xlat15);
        u_xlat4.xyz = float3(u_xlat18) + u_xlat4.xyz;
        u_xlat1.xyz = (bool(u_xlatb19)) ? u_xlat4.xyz : u_xlat2.xyw;
    }
    u_xlatb18 = 0<_enable_edge_glint;
    u_xlat19 = dot(u_xlat3.xy, _Glint1Dir.xy);
    u_xlat19 = max(u_xlat19, 0.0);
    u_xlat2.x = (-_GlintSharpness) + _GlintWrap;
    u_xlat2.x = u_xlat14.x * u_xlat2.x + _GlintSharpness;
    u_xlat19 = log2(u_xlat19);
    u_xlat19 = u_xlat19 * u_xlat2.x;
    u_xlat1.w = exp2(u_xlat19);
    u_xlat8.x = dot(u_xlat3.xy, float2(_Glint2Dir.x, _Glint2Dir.y));
    u_xlat8.x = max(u_xlat8.x, 0.0);
    u_xlat8.x = log2(u_xlat8.x);
    u_xlat2.x = u_xlat8.x * u_xlat2.x;
    u_xlat2.x = exp2(u_xlat2.x);
    u_xlat8.xyz = u_xlat1.www * _Glint1Color.xyz + u_xlat1.xyz;
    u_xlat2.xyz = u_xlat2.xxx * _Glint2Color.xyz + u_xlat8.xyz;
    u_xlat2.xyz = clamp(u_xlat2.xyz, 0.0, 1.0);
    u_xlat1.xyz = (bool(u_xlatb18)) ? u_xlat2.xyz : u_xlat1.xyz;
    u_xlat2.w = u_xlat12.x * _ForegroundColor.w;
    u_xlat0.x = dot(u_xlat0.xy, float2(0.0671105608, 0.00583714992));
    u_xlat0.x = fract(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * 52.9829178;
    u_xlat0.x = fract(u_xlat0.x);
    u_xlat0.x = u_xlat0.x + -0.5;
    u_xlat0.x = u_xlat0.x * 0.00392156886;
    u_xlat2.xyz = u_xlat1.xyz * u_xlat2.www + u_xlat0.xxx;
    u_xlatb0 = 0<_blur_invert;
    if(u_xlatb0){
        u_xlat1 = fundoRt.sample(__nv_smp, vs_TEXCOORD0.xy);
    }
    if(!u_xlatb0){
        u_xlat1 = camadaRt.sample(__nv_smp, vs_TEXCOORD0.xy);
    }
    u_xlat1.xyz = u_xlat1.www * u_xlat1.xyz;
    u_xlat2 = (-u_xlat1) + u_xlat2;
    saidaDoNode = u_xlat12.xxxx * u_xlat2 + u_xlat1;
    return;
}

fragment float4 fx_nv_nodevideo_effect_liquid_glass(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_liquid_glassParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> camadaRt [[texture(1)]],
    texture2d<float> desfoqueH [[texture(2)]],
    texture2d<float> fundoRt [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        float4 c = texelDePe(inputImg);
        __nv_out = float4(linear(c.rgb) * c.a, c.a);
        return __nv_out;
    }
    if (eng.acPass == 1) { __nv_out = gaussiana(camadaRt, float2(1.0, 0.0)); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = gaussiana(desfoqueH, float2(0.0, 1.0)); return __nv_out; }
    ligar();
    // O UV do Node (Y para cima): os RTs do meio estão de pé.
    vs_TEXCOORD0 = eng.acEntradaDePe == 1 ? in.acScreenNorm : float2(in.acScreenNorm.x, 1.0 - in.acScreenNorm.y);
    sinalDoY = eng.acEntradaDePe == 1 ? 1.0 : -1.0;
    programaDoNode();
    // o RT do Node prende em 0..1; o Nova guarda a cor reta em sRGB
    float4 o = clamp(saidaDoNode, 0.0, 1.0);
    __nv_out = o.a > 1e-5 ? float4(srgb(o.rgb / o.a), o.a) : float4(0.0);
    return __nv_out;
}
