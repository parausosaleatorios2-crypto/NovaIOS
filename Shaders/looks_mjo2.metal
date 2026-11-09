// Gerado por Tools/looks_glsl2msl.py a partir de Resources/mblooks/mjo2.frag
// (motor do Looks do app Android). NAO editar: edite o .frag e gere de novo.
#include <metal_stdlib>
using namespace metal;



struct looks_mjo2_U {
    int2 uTamanho;
    int uDePe;
    float3 uExpoFim;
    float3 uExpoIncl;
    float3 uVinheta;
    float uP8;
    float uP9;
    float3 uTomSombra;
    float3 uTomLuz;
    float uSaturacao;
    float3 uAzul;
    float4 uPele;
    float3 uContFim;
    float3 uContIncl;
    float uCor;
    float2 uSaida;
    float uForca;
};

struct __ctx_looks_mjo2 {
    texture2d<float> uEntrada;
    texture2d<float> uCurvas;
    float4 gl_FragCoord;
    int2 uTamanho;
    bool uDePe;
    float3 uExpoFim;
    float3 uExpoIncl;
    float3 uVinheta;
    float uP8;
    float uP9;
    float3 uTomSombra;
    float3 uTomLuz;
    float uSaturacao;
    float3 uAzul;
    float4 uPele;
    float3 uContFim;
    float3 uContIncl;
    float uCor;
    float2 uSaida;
    float uForca;

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

















    float pot(float x, float e) { return exp2(log2(x) * e); }
    float3 pot(float3 x, float e) { return exp2(log2(x) * e); }


    float curvaPe(float v, float a, float b) {
        float pw = pot(v, a);
        return v < 1.0 ? ((pw + 1.0) - pot(max(1.0 - v, 0.0), b)) * 0.5 : (pw + -1.0) * a + 1.0;
    }


    float curvaOmbro(float v, float a, float b, float c1, float d, float c2) {
        float pw = pot(v, a);
        float pe = ((pw + 1.0) - pot(1.0 - v, b)) * 0.5;
        float t1 = clamp((v + -1.0) * c1, 0.0, 1.0);
        float t2 = clamp((v - d) * c2, 0.0, 1.0);
        return v >= 1.0 ? pw : t2 * pw + pe * t1;
    }


    float3 curva(int linha, float3 v, float3 fim, float3 incl) {
        return float3(
            v.r < fim.r ? amostra1d(uCurvas, linha, v.r).r : (v.r - fim.r) * incl.r + fim.r,
            v.g < fim.g ? amostra1d(uCurvas, linha, v.g).g : (v.g - fim.g) * incl.g + fim.g,
            v.b < fim.b ? amostra1d(uCurvas, linha, v.b).b : (v.b - fim.b) * incl.b + fim.b);
    }


    float3 vinheta(float3 y) {
        float3 lin = decodVinheta(y);
        float2 d = float2(pxAe()) - float2(uTamanho) * 0.5;
        float t = clamp(1.0 - sqrt(d.x * d.x + d.y * d.y) * uVinheta.z, 0.0, 1.0);
        t = (max(t, 0.5) + -0.5) + min(t, 0.5);
        float m = exp2(log2(t) * uVinheta.x);
        float mx = max(y.r, max(y.g, y.b));
        float mn = min(y.r, min(y.g, y.b));
        float q = min(max((mx + mn) * 0.5 + -0.75, 0.0) * 4.0, 1.0);
        m = max(1.0 - (1.0 - q * q) * (1.0 - m), 0.0);
        float3 o = uVinheta.y < 0.0
            ? ((6.0 - m * 5.0) * lin - lin) * (-0.0 - uVinheta.y) + lin
            : (m * lin - lin) * uVinheta.y + lin;
        return codVinheta(o);
    }


    float3 filmeP8(float3 y) {
        float3 g = pot(max(y, 1e-6), 0.45454543828964233);
        float3 f;
        float mistura;
        if (uP8 < 0.0) {
            f.r = curvaPe(max(g.r * 1.1549999713897705 + -0.38499999046325684, 1e-6), 0.5263158082962036, 1.899999976158142);
            f.g = curvaPe(max(g.g * 1.092000126838684 + -0.18199999630451202, 1e-6), 0.6211180090904236, 1.6100000143051147);
            f.b = curvaOmbro(max(g.b * 0.7350000143051147 + 0.31499993801116943, 1e-6), 1.3333333730697632, 0.75,
                             -1.2903226613998413, 0.22499999403953552, 1.2903226613998413);
            mistura = uP8 * -0.004999999888241291;
        } else {
            f.r = curvaPe(max(g.r * 1.3224999904632568 + -0.17249996960163116, 1e-6), 0.7662835121154785, 1.3050000667572021);
            f.g = curvaOmbro(max(g.g * 1.123499870300293 + -0.07349999248981476, 1e-6), 1.0946907997131348, 0.9134999513626099,
                             -1.0844223499298096, 0.07785004377365112, 1.0844223499298096);
            f.b = curvaOmbro(max(g.b * 0.949999988079071, 1e-6), 1.6420361995697021, 0.6089999675750732,
                             -1.5429717302322388, 0.35190001130104065, 1.5429717302322388);
            mistura = uP8 * 0.004999999888241291;
        }
        f = pot(max(f, 1e-6), 2.200000047683716);
        return (f - y) * mistura + y;
    }


    float3 filmeP9(float3 y) {
        float3 g = pot(max(y, 1e-6), 0.45454543828964233);
        float3 f;
        float mistura;
        if (uP9 < 0.0) {
            f.r = curvaOmbro(max(g.r * 0.7999999523162842 + 0.20000004768371582, 1e-6), 1.6666666269302368, 0.6000000238418579,
                             -1.5624998807907104, 0.35999995470046997, 1.5624998807907104);
            f.g = curvaPe(max(g.g * 1.5 + -0.5, 1e-6), 0.5263158082962036, 1.899999976158142);
            f.b = curvaOmbro(max(g.b * 0.7999999523162842 + 0.20000004768371582, 1e-6), 1.6666666269302368, 0.6000000238418579,
                             -1.5624998807907104, 0.35999995470046997, 1.5624998807907104);
            mistura = 1.0 - (uP9 + 200.0) * 0.004999999888241291;
        } else {
            f.r = curvaPe(max(g.r * 1.2000000476837158 + -0.19999998807907104, 1e-6), 0.7142857313156128, 1.399999976158142);
            f.g = curvaOmbro(max(g.g * 0.7000000476837158 + 0.2999999523162842, 1e-6), 1.6666666269302368, 0.6000000238418579,
                             -1.5624998807907104, 0.35999995470046997, 1.5624998807907104);
            f.b = curvaPe(max(g.b * 1.2000000476837158 + -0.19999998807907104, 1e-6), 0.7142857313156128, 1.399999976158142);
            mistura = uP9 * 0.004999999888241291;
        }
        f = pot(max(f, 1e-6), 2.200000047683716);
        return (f - y) * mistura + y;
    }


    float tom(float g, float v1, float v2) {
        float a = (v1 + -1.0) + g * (2.0 - v1);
        float inv = 1.0 / v2;
        float d = max(1.0 - v2, 0.0) * 0.8999999761581421;
        float v = max(a, 1e-6);
        if (v2 > 1.0) return curvaPe(v, inv, v2);
        if (v2 < 1.0) return curvaOmbro(v, inv, v2, 1.0 / (d + -1.0), d, 1.0 / (1.0 - d));
        return v;
    }

    float3 splitToning(float3 y) {
        float3 g = pot(max(y, 1e-6), 0.45454543828964233);
        float3 t = float3(tom(g.r, uTomSombra.r, uTomLuz.r), tom(g.g, uTomSombra.g, uTomLuz.g), tom(g.b, uTomSombra.b, uTomLuz.b));
        return pot(max(t, 1e-6), 2.200000047683716);
    }


    float3 paraHsl(float3 c) {
        float mn = min(c.r, min(c.g, c.b));
        float mx = max(c.r, max(c.g, c.b));
        if (mx == 0.0) return float3(0.0);
        if (mn == mx) return float3(0.0, 0.0, mx);
        float soma = mx + mn;
        float l = soma * 0.5;
        float d = mx - mn;
        float s = d / (l <= 0.5 ? soma : (2.0 - mn) - mx);
        float k = 0.1666666716337204 / d;
        float h;
        if (c.r < c.g) {
            if (c.r < c.b) h = c.b < c.g ? 0.5 - k * (mx - c.b) : k * (mx - c.g) + 0.5;
            else h = k * (mx - c.r) + 0.1666666716337204;
        } else {
            if (c.g < c.b) h = c.b < c.r ? k * (mx - c.b) + 0.8333333134651184 : 0.8333333134651184 - k * (mx - c.r);
            else h = 0.1666666716337204 - k * (mx - c.g);
        }
        return float3(h, s, l);
    }

    float3 deHsl(float3 hsl) {
        float h = clamp(hsl.x, 0.0, 1.0);
        float s = clamp(hsl.y, 0.0, 1.0);
        float l = clamp(hsl.z, 0.0, 1.0);
        if (l == 0.0) return float3(0.0);
        if (s == 0.0) return float3(l);
        float q = l <= 0.5 ? l * s + l : (l + s) - l * s;
        float p = l * 2.0 - q;
        float h6 = h * 6.0;
        float dq = q - p;
        if (h6 <= 1.0) return float3(q, dq * h6 + p, p);
        if (h6 <= 3.0) return h6 <= 2.0 ? float3(dq * (2.0 - h6) + p, q, p) : float3(p, q, dq * (h6 + -2.0) + p);
        if (h6 <= 5.0) return h6 <= 4.0 ? float3(p, dq * (4.0 - h6) + p, q) : float3(dq * (h6 + -4.0) + p, p, q);
        return float3(q, p, dq * (6.0 - h6) + p);
    }


    float3 dobraMatiz(float3 c, int linha, float largura, float centro) {
        float3 hsl = paraHsl(clamp(c, 0.0, 1.0));
        float d = hsl.x - centro;
        if (d > 0.5) d = d + -1.0;
        else if (d < -0.5) d = d + 1.0;
        float u = (1.0 / largura) * d + 0.5;
        float v = (u < 0.0 || u >= 1.0) ? u : amostra1d(uCurvas, linha, u).r;
        float h = (v + -0.5) * largura + centro;
        for (int i = 0; i < 64 && !(h < 1.0); i++) h = h + -1.0;
        for (int i = 0; i < 64 && h < 0.0; i++) h = h + 1.0;
        return deHsl(float3(h, hsl.y, hsl.z));
    }

    float4 principal() {
            float4 fragColor = float4(0.0);
        float4 px = uEntrada.read(uint2(pxMemoria()));
        float3 x = px.rgb;
        float3 y = curva(0, max(x, 0.0), uExpoFim, uExpoIncl);
        if (uVinheta.x != 0.0) y = vinheta(y);
        y = filmeP8(y);
        y = filmeP9(y);
        y = splitToning(y);
        float L = dot(y, float3(0.3098039925098419, 0.6078429818153381, 0.08235300332307816));
        y = max((uSaturacao * 0.01) * (y - L) + L, 0.0);
        if (uAzul.x > 0.0) y = dobraMatiz(y, 4, uAzul.y, uAzul.z);
        if (uPele.x > 0.0 || uPele.y != 0.0) y = dobraMatiz(y, 3, uPele.z, uPele.w);
        y = curva(1, max(y, 0.0), uContFim, uContIncl);
        if (uCor > 0.0) {
            float3 hsl = paraHsl(clamp(y, 0.0, 1.0));
            hsl.y = exp2(log2(hsl.z) * 0.4) * hsl.y;
            y = uCor * (deHsl(hsl) - y) + y;
        }
        float3 z = (uSaida.x - x) + (uSaida.y - uSaida.x) * y;
        fragColor = float4(meia(z * uForca + x), px.a);
        return fragColor;
        }
};

fragment float4 looks_mjo2(
    float4 fc [[position]],
    constant looks_mjo2_U& U [[buffer(0)]],
    texture2d<float> uEntrada [[texture(0)]],
    texture2d<float> uCurvas [[texture(1)]])
{
    __ctx_looks_mjo2 __c{uEntrada, uCurvas, fc, U.uTamanho, (U.uDePe != 0), U.uExpoFim, U.uExpoIncl, U.uVinheta, U.uP8, U.uP9, U.uTomSombra, U.uTomLuz, U.uSaturacao, U.uAzul, U.uPele, U.uContFim, U.uContIncl, U.uCor, U.uSaida, U.uForca};
    return __c.principal();
}
