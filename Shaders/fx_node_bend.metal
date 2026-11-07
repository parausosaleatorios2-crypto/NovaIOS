// ---------------------------------------------------------------------------
// Curvatura (Node)
// origem : assets/effects/node-bend.xml
// id     : nova.effect.node-bend
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct node_bendParams {
    int pivot;
    float amount;
    float offset;
    int bendType;
    float2 texOffset;
    float2 texScale;
    float texAngle;
};

// --- funcoes auxiliares do efeito
// k/255 pelo mais perto, montado nos bits do float: o valor exato que a textura de 8 bits devolve (o
// `floor(..)/255.0` vai pelo recíproco e erra o último bit — ver `am-color-balance.xml`).
float oitoBits(float k) {
    uint n = uint(k);
    if (n == 0u) return 0.0;
    if (n == 255u) return 1.0;
    int j = 0;                                                    // o bit mais alto de n
    for (int i = 1; i < 8; i++) if (n >= (1u << uint(i))) j = i;
    int e = 31 - j;
    uint q = ((n << uint(e)) + 127u) / 255u;                      // entre 2^23 e 2^24
    return as_type<float>((uint(150 - e) << 23) + (q - 0x800000u));
}

float3 oitoBits3(float3 k) {
    return float3(oitoBits(k.r), oitoBits(k.g), oitoBits(k.b));
}

float3 linear(float3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c));
}

float3 srgb(float3 l) {
    l = clamp(l, 0.0, 1.0);
    return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l));
}

// Os bytes que um RT sRGB de 8 bits guarda para esta cor linear.
float3 bytesSrgb(float3 l) {
    return floor(srgb(l) * 255.0 + 0.5);
}

// O texel exato de uma imagem do tamanho da tela no pixel de pé (a linha 0 é a base, como nos RTs do Node): no
// buffer de camada (`eng.acEntradaDePe` = 0, a linha 0 é o topo) a linha é espelhada. Lê a entrada para o RT de pé e o RT
// de pé para a saída — os dois espelhos se desfazem, e a conta do meio é a da tela.
float4 texelDePe(sampler2D img) {
    int2 T = int2(int(img.get_width()), int(img.get_height()));
    int2 p = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
    if (eng.acEntradaDePe != 1) p.y = T.y - 1 - p.y;
    return img.read(uint2(p), uint(0));
}

// O `~` de inteiro do HLSL, como o Unity o escreve: o programa guarda "o Pivô não é Direita" como os bits de um float
// (0 ou 0xFFFFFFFF) e mais adiante testa esses bits para escolher o ramo vertical (Topo e Inferior).
int op_not(int value) { return -value - 1; }

// O programa do Node, conta por conta (o `_SourceTex` é o `camadaRt`, os parâmetros com os nomes do Nova).
// [in.vs_TEXCOORD0]: o UV do Node (cresce para cima). Sem a máscara interna do Node: o ramo dela desligado, nas duas
// saídas do programa (a antecipada, do lado parado, e a do fim).
float4 bend(float2 in.vs_TEXCOORD0) {
    // Os uniforms do Node com os nomes dele: o `_resolution` do `RCEffect::Render` é o `eng.acTamanhoDaTela` (o tamanho
    // da composição); os Enum chegam como o inteiro, o Float por `SetGlobalFloat`, os Vector2 inteiros.
    float2 _resolution = eng.acTamanhoDaTela;
    int _pivot = u.pivot;
    float _amount = u.amount;
    float _offset = u.offset;
    int _type = u.bendType;
    float2 _tex_offset = u.texOffset;
    float2 _tex_scale = u.texScale;
    float _tex_angle = u.texAngle;
    float4 u_xlat0;
    bool2 u_xlatb0;
    float4 u_xlat1;
    int3 u_xlati1;
    bool2 u_xlatb1;
    float4 u_xlat2;
    bool4 u_xlatb2;
    float4 u_xlat3;
    float4 u_xlat4;
    float4 u_xlat5;
    int u_xlati5;
    bool2 u_xlatb5;
    float4 u_xlat6;
    bool u_xlatb6;
    float4 u_xlat7;
    float4 u_xlat8;
    float2 u_xlat9;
    float3 u_xlat10;
    int u_xlati10;
    float2 u_xlat11;
    bool u_xlatb11;
    float u_xlat14;
    bool u_xlatb14;
    float2 u_xlat18;
    bool2 u_xlatb18;
    float2 u_xlat19;
    bool2 u_xlatb19;
    float u_xlat20;
    float u_xlat23;
    bool u_xlatb23;
    bool u_xlatb27;
    float u_xlat28;
    bool u_xlatb28;
    float u_xlat29;
    int u_xlati29;
    float u_xlat30;
    bool u_xlatb30;
    float u_xlat32;
    bool u_xlatb32;

    u_xlat0.x = _tex_angle * 0.0174532998;
    u_xlat1.x = cos(u_xlat0.x);
    u_xlat0.x = sin(u_xlat0.x);
    u_xlat2.x = (-u_xlat0.x);
    u_xlat9.xy = in.vs_TEXCOORD0.xy + float2(-0.5, -0.5);
    u_xlat9.xy = u_xlat9.xy / float2(_tex_scale.x, _tex_scale.y);
    u_xlat2.y = u_xlat1.x;
    u_xlat2.z = u_xlat0.x;
    u_xlat10.x = dot(u_xlat9.xy, u_xlat2.yz);
    u_xlat10.y = dot(u_xlat9.xy, u_xlat2.xy);
    u_xlat0.xy = u_xlat10.xy + _tex_offset.xy;
    u_xlat0.yz = u_xlat0.xy + float2(0.5, 0.5);
    u_xlati1.xyz = int3(uint3(equal(int4(_pivot), int4(1, 2, 3, 0)).xyz) * 0xFFFFFFFFu);
    u_xlat2.z = as_type<float>(op_not(u_xlati1.x));
    u_xlat3.x = float(0.5);
    u_xlat3.y = float(0.0);
    u_xlat3.w = (-_amount);
    u_xlat4.x = 0.0;
    u_xlat4.z = _amount;
    u_xlat3.xyz = (u_xlati1.z != 0) ? u_xlat3.xyw : u_xlat4.xxz;
    u_xlat4.y = float(0.5);
    u_xlat4.z = float(0.0);
    u_xlat4.w = float(0.5);
    u_xlat4.x = _offset * -0.99000001 + 1.0;
    u_xlat5.x = float(0.5);
    u_xlat5.z = float(0.5);
    u_xlat5.w = float(1.0);
    u_xlat5.y = _offset * 0.99000001;
    u_xlat6 = (u_xlati1.y != 0) ? u_xlat4.wxwz : u_xlat5;
    u_xlat7.x = float(0.5);
    u_xlat7.y = float(1.0);
    u_xlat7.w = _amount;
    u_xlat10.xyz = (u_xlati1.y != 0) ? u_xlat7.xyw : u_xlat3.xyz;
    u_xlat3.x = float(1.0);
    u_xlat3.y = float(0.5);
    u_xlat3.w = (-_amount);
    u_xlat2.xyw = (u_xlati1.x != 0) ? u_xlat3.xyw : u_xlat10.xyz;
    u_xlat1 = (u_xlati1.x != 0) ? u_xlat4 : u_xlat6;
    u_xlat3.yw = (_pivot != 0) ? u_xlat1.xy : u_xlat5.yz;
    u_xlat1.xy = (_pivot != 0) ? u_xlat1.zw : float2(1.0, 0.5);
    u_xlat4.x = float(0.0);
    u_xlat4.y = float(0.5);
    u_xlat4.w = _amount;
    u_xlat2 = (_pivot != 0) ? u_xlat2.wxyz : u_xlat4.wxyx;
    u_xlat1.xy = (-u_xlat3.yw) + u_xlat1.xy;
    u_xlat19.xy = u_xlat0.yz + (-u_xlat3.yw);
    u_xlat19.x = dot(u_xlat1.xy, u_xlat19.xy);
    // (o `u_xlat4 = camadaRt.sample(__nv_smp, in.vs_TEXCOORD0.xy)` do Node só serve à máscara interna)
    u_xlatb19.x = u_xlat19.x<0.0;
    if(u_xlatb19.x){
        u_xlatb19.x = _type==0;
        u_xlatb28 = 0.0>=_offset;
        u_xlatb19.x = u_xlatb28 || u_xlatb19.x;
        if(u_xlatb19.x){
            u_xlatb19.xy = lessThan(u_xlat0.yzyz, float4(0.0, 0.0, 0.0, 0.0)).xy;
            u_xlatb5.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.yzyy).xy;
            u_xlatb19.x = u_xlatb19.x || u_xlatb5.x;
            u_xlatb19.x = u_xlatb19.y || u_xlatb19.x;
            u_xlatb19.x = u_xlatb5.y || u_xlatb19.x;
            u_xlat5 = camadaRt.sample(__nv_smp, u_xlat0.yz);
            u_xlat19.x = (u_xlatb19.x) ? 0.0 : 1.0;
            u_xlat5 = u_xlat19.xxxx * u_xlat5;
            return u_xlat5;
        } else {
            u_xlat1.xy = (-u_xlat3.yw) + u_xlat2.yz;
            u_xlatb19.x = _type==2;
            u_xlat2.x = (u_xlatb19.x) ? (-u_xlat2.x) : u_xlat2.x;
        }
    }
    u_xlat19.x = u_xlat2.x * 0.00872664619;
    u_xlat1.x = dot(u_xlat1.xy, u_xlat1.xy);
    u_xlat1.x = sqrt(u_xlat1.x);
    u_xlat1.x = u_xlat19.x / u_xlat1.x;
    if(uint(as_type<uint>(u_xlat2.w)) != uint(0)) {
        u_xlat10.xy = _resolution.xy / _resolution.yx;
        u_xlat0.x = u_xlat0.y * u_xlat10.x;
        u_xlat3.z = u_xlat10.x * u_xlat3.y;
        u_xlat10.xz = u_xlat0.xz + (-u_xlat3.zw);
        u_xlatb0.x = abs(u_xlat1.x)<0.00100000005;
        u_xlat2.x = u_xlat10.z;
        u_xlat2.x = clamp(u_xlat2.x, 0.0, 1.0);
        u_xlat2.x = u_xlat10.z + (-u_xlat2.x);
        u_xlat2.y = (u_xlatb0.x) ? u_xlat2.x : u_xlat10.z;
        u_xlat20 = 0.5 / u_xlat1.x;
        u_xlat2.x = u_xlat10.x + (-u_xlat20);
        u_xlati29 = int((0.0<u_xlat1.x) ? 0xFFFFFFFFu : uint(0));
        u_xlati5 = int((u_xlat1.x<0.0) ? 0xFFFFFFFFu : uint(0));
        u_xlati29 = (-u_xlati29) + u_xlati5;
        u_xlat29 = float(u_xlati29);
        u_xlat5.x = dot(u_xlat2.xy, u_xlat2.xy);
        u_xlat5.x = sqrt(u_xlat5.x);
        u_xlat5.x = abs(u_xlat20) + (-u_xlat5.x);
        u_xlat11.x = u_xlat2.y * u_xlat29;
        u_xlat2.x = u_xlat2.x * (-u_xlat29);
        u_xlat14 = min(abs(u_xlat2.x), abs(u_xlat11.x));
        u_xlat23 = max(abs(u_xlat2.x), abs(u_xlat11.x));
        u_xlat23 = float(1.0) / u_xlat23;
        u_xlat14 = u_xlat23 * u_xlat14;
        u_xlat23 = u_xlat14 * u_xlat14;
        u_xlat32 = u_xlat23 * 0.0208350997 + -0.0851330012;
        u_xlat32 = u_xlat23 * u_xlat32 + 0.180141002;
        u_xlat32 = u_xlat23 * u_xlat32 + -0.330299497;
        u_xlat23 = u_xlat23 * u_xlat32 + 0.999866009;
        u_xlat32 = u_xlat23 * u_xlat14;
        u_xlatb6 = abs(u_xlat2.x)<abs(u_xlat11.x);
        u_xlat32 = u_xlat32 * -2.0 + 1.57079637;
        u_xlat32 = u_xlatb6 ? u_xlat32 : float(0.0);
        u_xlat14 = u_xlat14 * u_xlat23 + u_xlat32;
        u_xlatb23 = u_xlat2.x<(-u_xlat2.x);
        u_xlat23 = u_xlatb23 ? -3.14159274 : float(0.0);
        u_xlat14 = u_xlat23 + u_xlat14;
        u_xlat23 = min(u_xlat2.x, u_xlat11.x);
        u_xlat2.x = max(u_xlat2.x, u_xlat11.x);
        u_xlatb11 = u_xlat23<(-u_xlat23);
        u_xlatb2.x = u_xlat2.x>=(-u_xlat2.x);
        u_xlatb2.x = u_xlatb2.x && u_xlatb11;
        u_xlat2.x = (u_xlatb2.x) ? (-u_xlat14) : u_xlat14;
        u_xlat11.y = u_xlat2.x * u_xlat20;
        u_xlat11.x = u_xlat29 * u_xlat5.x;
        u_xlat2.yz = (u_xlatb0.x) ? u_xlat10.xz : u_xlat11.xy;
        u_xlat2.x = u_xlat10.y * u_xlat2.y;
        u_xlat3.x = u_xlat10.y * u_xlat3.z;
        u_xlat10.xy = u_xlat3.xw + u_xlat2.xz;
        u_xlatb2.xy = greaterThanEqual(u_xlat10.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlatb2.zw = greaterThanEqual(float4(0.0, 0.0, 1.0, 1.0), u_xlat10.xxxy).zw;
        u_xlat2.x = u_xlatb2.x ? float(1.0) : 0.0;
        u_xlat2.y = u_xlatb2.y ? float(1.0) : 0.0;
        u_xlat2.z = u_xlatb2.z ? float(1.0) : 0.0;
        u_xlat2.w = u_xlatb2.w ? float(1.0) : 0.0;
;
        u_xlat0.x = u_xlat2.z * u_xlat2.x;
        u_xlat0.x = u_xlat2.y * u_xlat0.x;
        u_xlat0.x = u_xlat2.w * u_xlat0.x;
        u_xlat2 = camadaRt.sample(__nv_smp, u_xlat10.xy);
        u_xlat2 = u_xlat0.xxxx * u_xlat2;
    } else {
        u_xlat10.xy = _resolution.yx / _resolution.xy;
        u_xlat0.w = u_xlat0.z * u_xlat10.x;
        u_xlat3.x = u_xlat10.x * u_xlat3.w;
        u_xlat0.xy = u_xlat0.yw + (-u_xlat3.yx);
        u_xlatb27 = abs(u_xlat1.x)<0.00100000005;
        u_xlat10.x = u_xlat0.y;
        u_xlat10.x = clamp(u_xlat10.x, 0.0, 1.0);
        u_xlat10.x = u_xlat0.y + (-u_xlat10.x);
        u_xlat10.x = (u_xlatb27) ? u_xlat10.x : u_xlat0.y;
        u_xlat28 = 0.5 / u_xlat1.x;
        u_xlat0.z = (-u_xlat28) + u_xlat10.x;
        u_xlati10 = int((0.0<u_xlat1.x) ? 0xFFFFFFFFu : uint(0));
        u_xlati1.x = int((u_xlat1.x<0.0) ? 0xFFFFFFFFu : uint(0));
        u_xlati1.x = (-u_xlati10) + u_xlati1.x;
        u_xlat1.x = float(u_xlati1.x);
        u_xlat10.x = dot(u_xlat0.xz, u_xlat0.xz);
        u_xlat10.x = sqrt(u_xlat10.x);
        u_xlat10.x = (-u_xlat10.x) + abs(u_xlat28);
        u_xlat30 = u_xlat0.x * u_xlat1.x;
        u_xlat18.x = u_xlat0.z * (-u_xlat1.x);
        u_xlat5.x = min(abs(u_xlat18.x), abs(u_xlat30));
        u_xlat14 = max(abs(u_xlat18.x), abs(u_xlat30));
        u_xlat14 = float(1.0) / u_xlat14;
        u_xlat5.x = u_xlat14 * u_xlat5.x;
        u_xlat14 = u_xlat5.x * u_xlat5.x;
        u_xlat23 = u_xlat14 * 0.0208350997 + -0.0851330012;
        u_xlat23 = u_xlat14 * u_xlat23 + 0.180141002;
        u_xlat23 = u_xlat14 * u_xlat23 + -0.330299497;
        u_xlat14 = u_xlat14 * u_xlat23 + 0.999866009;
        u_xlat23 = u_xlat14 * u_xlat5.x;
        u_xlatb32 = abs(u_xlat18.x)<abs(u_xlat30);
        u_xlat23 = u_xlat23 * -2.0 + 1.57079637;
        u_xlat23 = u_xlatb32 ? u_xlat23 : float(0.0);
        u_xlat5.x = u_xlat5.x * u_xlat14 + u_xlat23;
        u_xlatb14 = u_xlat18.x<(-u_xlat18.x);
        u_xlat14 = u_xlatb14 ? -3.14159274 : float(0.0);
        u_xlat5.x = u_xlat14 + u_xlat5.x;
        u_xlat14 = min(u_xlat18.x, u_xlat30);
        u_xlat18.x = max(u_xlat18.x, u_xlat30);
        u_xlatb30 = u_xlat14<(-u_xlat14);
        u_xlatb18.x = u_xlat18.x>=(-u_xlat18.x);
        u_xlatb18.x = u_xlatb18.x && u_xlatb30;
        u_xlat18.x = (u_xlatb18.x) ? (-u_xlat5.x) : u_xlat5.x;
        u_xlat5.x = u_xlat18.x * u_xlat28;
        u_xlat5.y = u_xlat1.x * u_xlat10.x;
        u_xlat0.xy = (bool(u_xlatb27)) ? u_xlat0.xy : u_xlat5.xy;
        u_xlat0.z = u_xlat10.y * u_xlat0.y;
        u_xlat3.z = u_xlat10.y * u_xlat3.x;
        u_xlat0.xy = u_xlat0.xz + u_xlat3.yz;
        u_xlatb18.xy = greaterThanEqual(u_xlat0.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlat18.x = u_xlatb18.x ? float(1.0) : 0.0;
        u_xlat18.y = u_xlatb18.y ? float(1.0) : 0.0;
;
        u_xlatb1.xy = greaterThanEqual(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.xyxx).xy;
        u_xlat1.x = u_xlatb1.x ? float(1.0) : 0.0;
        u_xlat1.y = u_xlatb1.y ? float(1.0) : 0.0;
;
        u_xlat18.x = u_xlat18.x * u_xlat1.x;
        u_xlat18.x = u_xlat18.y * u_xlat18.x;
        u_xlat18.x = u_xlat1.y * u_xlat18.x;
        u_xlat1 = camadaRt.sample(__nv_smp, u_xlat0.xy);
        u_xlat2 = u_xlat18.xxxx * u_xlat1;
    }
    return u_xlat2;
}

fragment float4 fx_node_bend(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant node_bendParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> camadaRt [[texture(1)]],
    texture2d<float> saidaRt [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        // A camada como o RT dela no Node: a cor em luz linear vezes o alfa, de pé; a GPU guarda em sRGB.
        float4 c = texelDePe(inputImg);
        __nv_out = float4(linear(c.rgb) * c.a, c.a);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        // O RT da camada está de pé: o UV do Node é o da tela, nos dois casos.
        // `Blend One Zero`: a saída como está (o alvo sRGB de 8 bits prende, como o do Node).
        __nv_out = bend(in.acScreenNorm);
        return __nv_out;
    }

    // Os bytes do RT de saída do Node (a GPU decodificou ao ler; codificar de novo devolve o byte guardado), de volta
    // à orientação da entrada.
    float4 o = texelDePe(saidaRt);
    float3 kc = bytesSrgb(o.rgb);
    float ka = floor(o.a * 255.0 + 0.5);
    if (ka <= 0.0) {
        __nv_out = float4(0.0);
        return __nv_out;
    }
    if (ka >= 255.0) {
        __nv_out = float4(oitoBits3(kc), 1.0);
        return __nv_out;
    }
    // O Nova guarda reto: a cor linear guardada dividida pelo alfa, de volta ao sRGB (acima de 1 fica em 1).
    float a = oitoBits(ka);
    __nv_out = float4(srgb(min(linear(oitoBits3(kc)) / a, float3(1.0))), a);
    return __nv_out;
}
