// Gerado por Tools/looks_glsl2msl.py a partir de Resources/mblooks/csta.frag
// (motor do Looks do app Android). NAO editar: edite o .frag e gere de novo.
#include <metal_stdlib>
using namespace metal;

constant float3 LUMA = float3(0.2126, 0.7152, 0.0722);

struct looks_csta_U {
    int2 uTamanho;
    int uDePe;
    int uRodas;
    float uLggForca;
    float uLggGanho;
    float3 uLggA;
    float3 uLggGain;
    float3 uLggGama;
    float3 uLggM1;
    float3 uLggInvG;
    float3 uLggK;
    float3 uLggR8;
    float3 uLggR9;
    int uExpo;
    float uExpoGanho;
    int uTT;
    float4 uTT0;
    float4 uTT1;
    float4 uTT2;
    int uMatiz;
    int uSaturacao;
    int uLuminancia;
    int uRot;
    float uRotV;
    int uSat;
    float uSatV;
    int uCont;
    float3 uContFim;
    float3 uContIncl;
    int uCurvasOn;
    float3 uCurvasFim;
    float uCurvasIncl;
    int uSatEq;
    int uMistura;
    float uMisturaS;
};

struct __ctx_looks_csta {
    texture2d<float> uEntrada;
    texture2d<float> uHsl;
    texture2d<float> uCurvaC;
    texture2d<float> uCurvas;
    texture2d<float> uSatEqT;
    texture2d<float> uPotencia;
    float4 gl_FragCoord;
    int2 uTamanho;
    bool uDePe;
    bool uRodas;
    float uLggForca;
    float uLggGanho;
    float3 uLggA;
    float3 uLggGain;
    float3 uLggGama;
    float3 uLggM1;
    float3 uLggInvG;
    float3 uLggK;
    float3 uLggR8;
    float3 uLggR9;
    bool uExpo;
    float uExpoGanho;
    bool uTT;
    float4 uTT0;
    float4 uTT1;
    float4 uTT2;
    bool uMatiz;
    bool uSaturacao;
    bool uLuminancia;
    bool uRot;
    float uRotV;
    bool uSat;
    float uSatV;
    bool uCont;
    float3 uContFim;
    float3 uContIncl;
    bool uCurvasOn;
    float3 uCurvasFim;
    float uCurvasIncl;
    bool uSatEq;
    bool uMistura;
    float uMisturaS;

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


    float2 produto(float a, float b) {
        float p = a * b;
        float ca = 4097.0 * a;
        float ah = ca - (ca - a);
        float al = a - ah;
        float cb = 4097.0 * b;
        float bh = cb - (cb - b);
        float bl = b - bh;
        return float2(p, ((ah * bh - p) + ah * bl + al * bh) + al * bl);
    }


    float divExata(float a, float b) {
        float q = a / b;
        float2 pe = produto(q, b);
        float r = (a - pe.x) - pe.y;
        return q + r / b;
    }


    float lgg2(float x0, float m1, float a, float gain, float gama, float invG, float k, float r8, float r9) {
        float x = max(x0, 1e-06);
        float v = max((x * m1 + a) * gain, 1e-06);
        float e = exp2(log2(v) * invG);
        float o;
        if (gama > 1.0) {
            float s = exp2(log2(max(1.0 - v, 0.0)) * gama);
            o = v < 1.0 ? ((e + 1.0) - s) * 0.5 : (e + -1.0) * invG + 1.0;
        } else if (gama < 1.0) {
            float s = exp2(log2(1.0 - v) * gama);
            float t = ((e + 1.0) - s) * 0.5;
            float w = min(max((v + -1.0) * r9, 0.0), 1.0);
            float b = min(max((v - k) * r8, 0.0), 1.0) * e + t * w;
            o = v >= 1.0 ? e : b;
        } else {
            o = v;
        }
        float y = max(o, 1e-06);
        return ((y - x0) * uLggForca + x0) * uLggGanho;
    }


    float3 paraHsl(float3 c) {
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
        return float3(H, S, L);
    }

    float3 deHsl(float h, float s, float l) {
        if (l == 0.0) return float3(0.0);
        if (s == 0.0) return float3(l);
        float q = l <= 0.5 ? l * s + l : (l + s) - l * s;
        float p = l * 2.0 - q;
        float h6 = h * 6.0;
        float d = q - p;
        if (!(h6 > 1.0)) return float3(q, d * h6 + p, p);
        if (!(h6 > 3.0)) return h6 <= 2.0 ? float3(d * (2.0 - h6) + p, q, p) : float3(p, q, d * (h6 + -2.0) + p);
        if (!(h6 > 5.0)) return h6 <= 4.0 ? float3(p, d * (4.0 - h6) + p, q) : float3(d * (h6 + -4.0) + p, p, q);
        return float3(q, p, d * (6.0 - h6) + p);
    }






    float potPrecisa(float x, bool inversa) {
        float y = inversa ? 0.45454543828964233 : 2.200000047683716;
        if (!(x > 0.0)) return 0.0;
        if (x < 6.103515625e-05 || x > 65504.0) return pw(x, y);
        uint b = as_type<uint>(x);
        float g = as_type<float>(b & 0xFFFFE000u);
        uint i = (b >> 13u) - 114688u;
        float4 t = uPotencia.read(uint2(int2(int(i & 127u), int(i >> 7u))));
        float hi = inversa ? t.z : t.x;
        float lo = inversa ? t.w : t.y;
        float d = (x - g) / g;
        float c2 = y * (y - 1.0) * 0.5;
        float c3 = c2 * (y - 2.0) * 0.33333334;
        float corr = d * (y + d * (c2 + d * c3));
        return hi + (lo + hi * corr);
    }

    float3 hslCores(float3 x0) {
        float3 c = max(x0, 0.0);
        float m = max(max(c.r, c.g), c.b);
        bool acima = m > 1.0;
        if (acima) c = float3(divExata(c.r, m), divExata(c.g, m), divExata(c.b, m));
        float3 hsl = paraHsl(c);
        float4 t = uHsl.read(uint2(int2(clamp(int(floor(hsl.x * 1024.0)), 0, 1023), 0)));
        if (uMatiz) c = deHsl(clamp(t.x, 0.0, 1.0), clamp(hsl.y, 0.0, 1.0), clamp(hsl.z, 0.0, 1.0));
        if (acima) c = c * m;
        float Y = dot(c, LUMA);
        float3 lin = float3(potPrecisa(c.r, false), potPrecisa(c.g, false), potPrecisa(c.b, false));
        if (uSaturacao) {
            float yl = dot(lin, LUMA);
            float k = max(t.y + 1.0, 0.0);
            lin = lin * k + yl * (1.0 - k);
        }
        if (uLuminancia) {
            float3 dd = x0 - Y;
            float dist = sqrt(dd.r * dd.r + dd.g * dd.g + dd.b * dd.b);
            float a = clamp((-0.04 - Y * 0.02) + dist, 0.0, 1.0);
            float w = clamp(a / (Y * 0.04 + 0.08), 0.0, 1.0);
            lin = max(w * t.z + 1.0, 0.0) * lin;
        }
        lin = max(lin, 0.0);
        return float3(potPrecisa(lin.r, true), potPrecisa(lin.g, true), potPrecisa(lin.b, true));
    }


    float3 girarMatiz(float3 x) {
        float m = max(max(x.r, x.g), x.b);
        bool acima = m > 1.0;
        float3 c = acima ? x / m : x;
        float3 hsl = paraHsl(c);
        float h = clamp(max(fract(hsl.x + uRotV), 0.0), 0.0, 1.0);
        float s = min(max(hsl.y, 0.0), 1.0);
        float l = min(max(hsl.z, 0.0), 1.0);
        float3 o = deHsl(h, s, l);
        return acima ? o * m : o;
    }


    float curva(texture2d<float> t, int canal, float c, float lim, float incl, float fim) {
        float x = max(c, 0.0);
        float a = amostra1d(t, 0, x + 0.000244140625)[canal];
        return x < lim ? a : (x - lim) * incl + fim;
    }


    float3 saturacaoEq(float3 c) {
        float mn = min(c.r, min(c.g, c.b));
        float mx = max(c.r, max(c.g, c.b));
        float S = 0.0;
        if (!(mx == 0.0 || mn == mx)) {
            float soma = mx + mn;
            float L = soma * 0.5;
            S = (mx - mn) / (L <= 0.5 ? soma : (2.0 - mn) - mx);


            if (isinf(S)) S = S > 0.0 ? 4.0 : -4.0;
            if (isnan(S)) S = 0.0;
        }
        float l709 = dot(c, float3(0.2125999927520752, 0.7152000069618225, 0.0722000002861023));
        float f0 = amostra1d(uSatEqT, 0, l709).x;
        float f1 = amostra1d(uSatEqT, 0, S).y;
        float k = f1 * f0;
        float l2 = dot(c, float3(0.30980393290519714, 0.6078431606292725, 0.08235294371843338));
        return k * (c - l2) + l2;
    }

    float4 principal() {
            float4 fragColor = float4(0.0);
        float4 px = uEntrada.read(uint2(pxMemoria()));
        float3 orig = px.rgb;
        float3 y = orig;
        if (uRodas) {
            y = meia(float3(
                lgg2(y.r, uLggM1.r, uLggA.r, uLggGain.r, uLggGama.r, uLggInvG.r, uLggK.r, uLggR8.r, uLggR9.r),
                lgg2(y.g, uLggM1.g, uLggA.g, uLggGain.g, uLggGama.g, uLggInvG.g, uLggK.g, uLggR8.g, uLggR9.g),
                lgg2(y.b, uLggM1.b, uLggA.b, uLggGain.b, uLggGama.b, uLggInvG.b, uLggK.b, uLggR8.b, uLggR9.b)));
        } else if (uExpo) {
            y = meia(y * uExpoGanho);
        }
        if (uTT) {
            float4 v = float4(y, px.a);
            y = meia(float3(((v.x * uTT0.x + v.y * uTT0.y) + v.z * uTT0.z) + v.w * uTT0.w,
                          ((v.x * uTT1.x + v.y * uTT1.y) + v.z * uTT1.z) + v.w * uTT1.w,
                          ((v.x * uTT2.x + v.y * uTT2.y) + v.z * uTT2.z) + v.w * uTT2.w));
        }
        if (uMatiz || uSaturacao || uLuminancia) y = meia(hslCores(y));
        if (uRot) y = meia(girarMatiz(y));
        if (uSat) {
            float l = dot(y, LUMA);
            y = meia((y - l) * uSatV + l);
        }
        if (uCont) {
            y = meia(float3(curva(uCurvaC, 0, y.r, uContFim.r, uContIncl.r, uContFim.r),
                          curva(uCurvaC, 1, y.g, uContFim.g, uContIncl.g, uContFim.g),
                          curva(uCurvaC, 2, y.b, uContFim.b, uContIncl.b, uContFim.b)));
        }
        if (uCurvasOn) {
            y = meia(float3(curva(uCurvas, 0, y.r, 1.0, uCurvasIncl, uCurvasFim.r),
                          curva(uCurvas, 1, y.g, 1.0, uCurvasIncl, uCurvasFim.g),
                          curva(uCurvas, 2, y.b, 1.0, uCurvasIncl, uCurvasFim.b)));
        }
        if (uSatEq) y = meia(saturacaoEq(y));
        if (uMistura) y = meia((orig - y) * uMisturaS + y);
        fragColor = float4(y, px.a);
        return fragColor;
        }
};

fragment float4 looks_csta(
    float4 fc [[position]],
    constant looks_csta_U& U [[buffer(0)]],
    texture2d<float> uEntrada [[texture(0)]],
    texture2d<float> uHsl [[texture(1)]],
    texture2d<float> uCurvaC [[texture(2)]],
    texture2d<float> uCurvas [[texture(3)]],
    texture2d<float> uSatEqT [[texture(4)]],
    texture2d<float> uPotencia [[texture(5)]])
{
    __ctx_looks_csta __c{uEntrada, uHsl, uCurvaC, uCurvas, uSatEqT, uPotencia, fc, U.uTamanho, (U.uDePe != 0), (U.uRodas != 0), U.uLggForca, U.uLggGanho, U.uLggA, U.uLggGain, U.uLggGama, U.uLggM1, U.uLggInvG, U.uLggK, U.uLggR8, U.uLggR9, (U.uExpo != 0), U.uExpoGanho, (U.uTT != 0), U.uTT0, U.uTT1, U.uTT2, (U.uMatiz != 0), (U.uSaturacao != 0), (U.uLuminancia != 0), (U.uRot != 0), U.uRotV, (U.uSat != 0), U.uSatV, (U.uCont != 0), U.uContFim, U.uContIncl, (U.uCurvasOn != 0), U.uCurvasFim, U.uCurvasIncl, (U.uSatEq != 0), (U.uMistura != 0), U.uMisturaS};
    return __c.principal();
}
