// Gerado por Tools/looks_glsl2msl.py a partir de Resources/mblooks/rhsl.frag
// (motor do Looks do app Android). NAO editar: edite o .frag e gere de novo.
#include <metal_stdlib>
using namespace metal;

constant float3 LUMA = float3(0.2126, 0.7152, 0.0722);

struct looks_rhsl_U {
    int2 uTamanho;
    int uDePe;
    int uMatiz;
    int uSaturacao;
    int uLuminancia;
};

struct __ctx_looks_rhsl {
    texture2d<float> uEntrada;
    texture2d<float> uHsl;
    float4 gl_FragCoord;
    int2 uTamanho;
    bool uDePe;
    bool uMatiz;
    bool uSaturacao;
    bool uLuminancia;

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







    float pw(float x, float e) { return exp2(log2(x) * e); }

    float4 principal() {
            float4 fragColor = float4(0.0);
        float4 px = uEntrada.read(uint2(pxMemoria()));
        float3 x0 = px.rgb;
        float3 c = max(x0, 0.0);
        float m = max(max(c.r, c.g), c.b);
        bool acima = m > 1.0;
        if (acima) c = (1.0 / m) * c;


        float mn = min(c.r, min(c.g, c.b));
        float mx = max(c.r, max(c.g, c.b));
        float H = 0.0, S = 0.0, L = 0.0;
        if (mx != 0.0) {
            if (mn == mx) {
                L = mx;
            } else {
                float soma = mx + mn;
                L = soma * 0.5;
                float delta = mx - mn;
                S = delta / (L <= 0.5 ? soma : (2.0 - mn) - mx);
                float k6 = 0.16666667 / delta;
                if (!(c.r < c.g)) {
                    if (!(c.g < c.b)) H = 0.16666667 - k6 * (mx - c.g);
                    else if (!(c.b < c.r)) H = 0.83333331 - k6 * (mx - c.r);
                    else H = k6 * (mx - c.b) + 0.83333331;
                } else {
                    if (!(c.r < c.b)) H = k6 * (mx - c.r) + 0.16666667;
                    else if (!(c.b < c.g)) H = k6 * (mx - c.g) + 0.5;
                    else H = 0.5 - k6 * (mx - c.b);
                }
            }
        }
        float4 t = uHsl.read(uint2(int2(clamp(int(floor(H * 1024.0)), 0, 1023), 0)));

        if (uMatiz) {
            float h = clamp(t.x, 0.0, 1.0);
            float s = clamp(S, 0.0, 1.0);
            float l = clamp(L, 0.0, 1.0);
            if (l == 0.0) {
                c = float3(0.0);
            } else if (s == 0.0) {
                c = float3(l);
            } else {
                float q = l <= 0.5 ? l * s + l : (l + s) - l * s;
                float p = l * 2.0 - q;
                float h6 = h * 6.0;
                float d = q - p;
                if (!(h6 > 1.0)) {
                    c = float3(q, d * h6 + p, p);
                } else if (!(h6 > 3.0)) {
                    c = h6 <= 2.0 ? float3(d * (2.0 - h6) + p, q, p) : float3(p, q, d * (h6 + -2.0) + p);
                } else if (!(h6 > 5.0)) {
                    c = h6 <= 4.0 ? float3(p, d * (4.0 - h6) + p, q) : float3(d * (h6 + -4.0) + p, p, q);
                } else {
                    c = float3(q, p, d * (6.0 - h6) + p);
                }
            }
        }
        if (acima) c = c * m;

        float Y = dot(c, LUMA);
        float3 lin = float3(pw(c.r, 2.2), pw(c.g, 2.2), pw(c.b, 2.2));
        if (uSaturacao) {
            float yl = dot(lin, LUMA);
            lin = max(t.y + 1.0, 0.0) * (lin - yl) + yl;
        }
        if (uLuminancia) {
            float3 dd = x0 - Y;
            float dist = sqrt(dd.r * dd.r + dd.g * dd.g + dd.b * dd.b);
            float a = clamp((-0.04 - Y * 0.02) + dist, 0.0, 1.0);
            float w = clamp(a / (Y * 0.04 + 0.08), 0.0, 1.0);
            lin = max(w * t.z + 1.0, 0.0) * lin;
        }
        lin = max(lin, 0.0);
        float3 y = float3(pw(lin.r, 0.45454544), pw(lin.g, 0.45454544), pw(lin.b, 0.45454544));
        fragColor = float4(meia(y), px.a);
        return fragColor;
        }
};

fragment float4 looks_rhsl(
    float4 fc [[position]],
    constant looks_rhsl_U& U [[buffer(0)]],
    texture2d<float> uEntrada [[texture(0)]],
    texture2d<float> uHsl [[texture(1)]])
{
    __ctx_looks_rhsl __c{uEntrada, uHsl, fc, U.uTamanho, (U.uDePe != 0), (U.uMatiz != 0), (U.uSaturacao != 0), (U.uLuminancia != 0)};
    return __c.principal();
}
