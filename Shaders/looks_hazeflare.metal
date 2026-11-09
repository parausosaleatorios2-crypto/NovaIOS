// Gerado por Tools/looks_glsl2msl.py a partir de Resources/mblooks/hazeflare.frag
// (motor do Looks do app Android). NAO editar: edite o .frag e gere de novo.
#include <metal_stdlib>
using namespace metal;



struct looks_hazeflare_U {
    int2 uTamanho;
    int uDePe;
    float uShade;
    float uExpo;
    int uRefl;
    float uReflExpo;
    float3 uTint;
};

struct __ctx_looks_hazeflare {
    texture2d<float> uEntrada;
    texture2d<float> uHaze;
    float4 gl_FragCoord;
    int2 uTamanho;
    bool uDePe;
    float uShade;
    float uExpo;
    bool uRefl;
    float uReflExpo;
    float3 uTint;

    float meia(float x) {
        uint b = as_type<uint>(x);
        uint e = (b >> 23) & 0xFFu;
        if (e == 0xFFu) return x;
        float a = abs(x);
        if (a >= 65504.0) return x < 0.0 ? -65504.0 : 65504.0;
        if (a < 6.103515625e-05) {

            return trunc(x * 16777216.0) * 5.9604644775390625e-08;
        }
        return as_type<float>(b & 0xFFFFE000u);
    }

    float4 meia(float4 v) { return float4(meia(v.x), meia(v.y), meia(v.z), meia(v.w)); }
    float3 meia(float3 v) { return float3(meia(v.x), meia(v.y), meia(v.z)); }


    float meiaPerto(float x) {
        uint b = as_type<uint>(x);
        float normal = as_type<float>((b + 0xFFFu + ((b >> 13) & 1u)) & 0xFFFFE000u);
        float a = abs(x);

        float y = a < 6.103515625e-05 ? rint(x * 16777216.0) * 5.9604644775390625e-08 : normal;
        y = a >= 65520.0 ? as_type<float>((b & 0x80000000u) | 0x7F800000u) : y;

        return (b & 0x7F800000u) == 0x7F800000u ? x : y;
    }

    float4 meiaPerto(float4 v) { return float4(meiaPerto(v.x), meiaPerto(v.y), meiaPerto(v.z), meiaPerto(v.w)); }




    int2 pxMemoria() { return int2(gl_FragCoord.xy); }

    int2 pxAe() {
        int2 p = int2(gl_FragCoord.xy);
        if (uDePe) p.y = uTamanho.y - 1 - p.y;
        return p;
    }


    float4 lerAe(texture2d<float> t, int2 p) {
        if (uDePe) p.y = uTamanho.y - 1 - p.y;
        return t.read(uint2(p));
    }


    float srgbParaLinear(float v) {
        float reto = v * 0.077399380;
        float curva = exp2(log2((max(v, 0.0) + 0.055) / 1.055) * 2.4);
        return max(v < 0.04045 ? reto : curva, 0.0);
    }


    float linearParaSrgb(float l) {
        float reto = l * 12.92;
        float curva = exp2(log2(max(l, 0.0)) * 0.416666667) * 1.055 - 0.055;
        return max(l < 0.0031308 ? reto : curva, 0.0);
    }


    float decodVinheta(float v) {
        float l = v < 0.04045 ? v * 0.0774 : exp2(log2((max(v, 0.0) + 0.055) * 0.94787) * 2.4);
        return max(l, 0.0);
    }

    float codVinheta(float o) {
        float s = o < 0.0031308 ? o * 12.92 : exp2(log2(max(o, 0.0)) * 0.41667) * 1.055 + -0.055;
        return max(s, 0.0);
    }

    float3 decodVinheta(float3 v) { return float3(decodVinheta(v.r), decodVinheta(v.g), decodVinheta(v.b)); }
    float3 codVinheta(float3 o) { return float3(codVinheta(o.r), codVinheta(o.g), codVinheta(o.b)); }

    float3 srgbParaLinear(float3 v) { return float3(srgbParaLinear(v.x), srgbParaLinear(v.y), srgbParaLinear(v.z)); }
    float3 linearParaSrgb(float3 v) { return float3(linearParaSrgb(v.x), linearParaSrgb(v.y), linearParaSrgb(v.z)); }


    float peso8(float f) { return rint(f * 256.0) / 256.0; }


    float4 amostra1d(texture2d<float> t, int linha, float u) {
        int n = int(t.get_width());
        float x = u * float(n) - 0.5;
        float i0 = floor(x);
        float f = peso8(x - i0);
        int a = clamp(int(i0), 0, n - 1);
        int b = clamp(int(i0) + 1, 0, n - 1);
        float4 va = t.read(uint2(int2(a, linha)));
        float4 vb = t.read(uint2(int2(b, linha)));
        return va * (1.0 - f) + vb * f;
    }


    float4 bilinear(texture2d<float> t, float2 pos) {
        float2 q = pos - 0.5;
        float2 i0 = floor(q);
        float2 f = float2(peso8(q.x - i0.x), peso8(q.y - i0.y));
        int2 a = clamp(int2(i0), int2(0), uTamanho - 1);
        int2 b = clamp(int2(i0) + 1, int2(0), uTamanho - 1);
        float4 v00 = lerAe(t, int2(a.x, a.y));
        float4 v10 = lerAe(t, int2(b.x, a.y));
        float4 v01 = lerAe(t, int2(a.x, b.y));
        float4 v11 = lerAe(t, int2(b.x, b.y));
        float4 c0 = v00 * (1.0 - f.x) + v10 * f.x;
        float4 c1 = v01 * (1.0 - f.x) + v11 * f.x;
        return c0 * (1.0 - f.y) + c1 * f.y;
    }







    float4 principal() {
            float4 fragColor = float4(0.0);
        float4 px = uEntrada.read(uint2(pxMemoria()));
        float4 h = uHaze.read(uint2(pxMemoria()));
        float f = (h.a * 1.1 + -1.0) * uShade + 1.0;
        float3 o = ((uExpo * 1.1) * uTint * h.rgb) * f + px.rgb;
        if (uRefl) {
            int2 q = pxAe();
            float3 e = lerAe(uHaze, int2(uTamanho.x - 1 - q.x, q.y)).rgb;
            o = ((uTint * uReflExpo) * f) * e + o;
        }
        fragColor = float4(meia(o), px.a);
        return fragColor;
        }
};

fragment float4 looks_hazeflare(
    float4 fc [[position]],
    constant looks_hazeflare_U& U [[buffer(0)]],
    texture2d<float> uEntrada [[texture(0)]],
    texture2d<float> uHaze [[texture(1)]])
{
    __ctx_looks_hazeflare __c{uEntrada, uHaze, fc, U.uTamanho, (U.uDePe != 0), U.uShade, U.uExpo, (U.uRefl != 0), U.uReflExpo, U.uTint};
    return __c.principal();
}
