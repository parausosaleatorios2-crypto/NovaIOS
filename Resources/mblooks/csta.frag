// Colorista (`csta`, vídeo) — o render do host (`0x1803ecc40`) é uma CADEIA de kernels; aqui ela roda num passe só,
// e cada etapa grava `meia(...)` (o float16 truncado que cada kernel do AE grava no buffer em 8 bpc). As contas, as
// constantes e a ordem são as dos kernels do Looks (DXIL); o host (ContasDoLooks.colorista) liga cada etapa e
// manda as constantes e as tabelas, como o render faz:
//   1. as três rodas — `ColorKernel_LGG2` (lift, gamma, gain, a força e o ganho da exposição) — ou, sem rodas, a
//      exposição pelo `CoreKernel_MulAdd`;
//   2. Temperature/Tint — `ColorKernel_ColorTempTint` (matriz 3×4 sobre o RGBA);
//   3. HSL das 8 cores — `ColorKernel_RangedHSL` (a mesma tabela e o mesmo kernel do HSL Colors, `rhsl.frag`);
//   4. Hue Rotation — `ColorKernel_HueRotation`;
//   5. Saturation — `ColorKernel_Saturation` (luma 709);
//   6. o contraste e 7. as curvas — `ColorKernel_Curves2` (tabela de 1024, filtro LINEAR, reta além do limite);
//   8. a saturação pela luma e pela saturação — `ColorKernel_SaturationEq`;
//   9. a força < 100 — `CoreKernel_MulAddBlendBuffer` com a entrada da ferramenta.
uniform highp sampler2D uHsl;
uniform highp sampler2D uCurvaC;
uniform highp sampler2D uCurvas;
uniform highp sampler2D uSatEqT;
uniform highp sampler2D uPotencia;   // 128 × 248: g^2,2 e g^(1/2,2) em dois floats, para cada float16 g > 0

uniform bool uRodas;
uniform float uLggForca;
uniform float uLggGanho;
uniform vec3 uLggA;       // lift − 1
uniform vec3 uLggGain;
uniform vec3 uLggGama;    // max(gamma, 0,1)
uniform vec3 uLggM1;      // 2 − lift
uniform vec3 uLggInvG;
uniform vec3 uLggK;       // max(1 − gama, 0) · 0,9
uniform vec3 uLggR8;      // 1 / (1 − k)
uniform vec3 uLggR9;      // 1 / (k − 1)
uniform bool uExpo;
uniform float uExpoGanho;
uniform bool uTT;
uniform vec4 uTT0;
uniform vec4 uTT1;
uniform vec4 uTT2;
uniform bool uMatiz;
uniform bool uSaturacao;
uniform bool uLuminancia;
uniform bool uRot;
uniform float uRotV;
uniform bool uSat;
uniform float uSatV;
uniform bool uCont;
uniform vec3 uContFim;
uniform vec3 uContIncl;
uniform bool uCurvasOn;
uniform vec3 uCurvasFim;
uniform float uCurvasIncl;
uniform bool uSatEq;
uniform bool uMistura;
uniform float uMisturaS;
out vec4 fragColor;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

float pw(float x, float e) { return exp2(log2(x) * e); }

// a·b exato em dois floats (Dekker): o produto arredondado e o erro dele
vec2 produto(float a, float b) {
    float p = a * b;
    float ca = 4097.0 * a;
    float ah = ca - (ca - a);
    float al = a - ah;
    float cb = 4097.0 * b;
    float bh = cb - (cb - b);
    float bl = b - bh;
    return vec2(p, ((ah * bh - p) + ah * bl + al * bh) + al * bl);
}

/** a / b arredondado certo (a divisão da GPU pode errar 1 bit; o `c / m` do AE é exato). */
float divExata(float a, float b) {
    float q = a / b;
    vec2 pe = produto(q, b);
    float r = (a - pe.x) - pe.y;
    return q + r / b;
}

// ---------------------------------------------------------------- 1. LGG2 (um canal)
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

// ---------------------------------------------------------------- RGB ↔ HSL, na ordem dos kernels
vec3 paraHsl(vec3 c) {
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
    return vec3(H, S, L);
}

vec3 deHsl(float h, float s, float l) {
    if (l == 0.0) return vec3(0.0);
    if (s == 0.0) return vec3(l);
    float q = l <= 0.5 ? l * s + l : (l + s) - l * s;
    float p = l * 2.0 - q;
    float h6 = h * 6.0;
    float d = q - p;
    if (!(h6 > 1.0)) return vec3(q, d * h6 + p, p);
    if (!(h6 > 3.0)) return h6 <= 2.0 ? vec3(d * (2.0 - h6) + p, q, p) : vec3(p, q, d * (h6 + -2.0) + p);
    if (!(h6 > 5.0)) return h6 <= 4.0 ? vec3(p, d * (4.0 - h6) + p, q) : vec3(d * (h6 + -4.0) + p, p, q);
    return vec3(q, p, d * (6.0 - h6) + p);
}

// ---------------------------------------------------------------- 3. HSL (o kernel do HSL Colors)
// O AE roda o código OpenCL do Looks: `pow()` preciso (o DXIL o escreve exp2(log2·e)), `c / m` exato e a mistura da
// saturação `lin·k + Yl·(1 − k)`, exata em k = 1 (a do DXIL, `k·(lin − Yl) + Yl`, mede pior). O float16 truncado
// do fim depende do último bit: um canal que passa sem mudança e volta 1 bit abaixo perde um degrau inteiro.
/**
 * x^y como o `pow()` do OpenCL do AE (praticamente o arredondado certo), para y = 2,2 ou 1/2,2: o valor da tabela
 * no float16 g logo abaixo de x (alto + baixo, do host em double) vezes (1 + d)^y, d = (x − g)/g < 2^-10, pela
 * série até d³. O exp2(log2·y) da GPU erra alguns bits — e no float16 truncado de depois isso vira um degrau.
 */
float potPrecisa(float x, bool inversa) {
    float y = inversa ? 0.45454543828964233 : 2.200000047683716;
    if (!(x > 0.0)) return 0.0;
    if (x < 6.103515625e-05 || x > 65504.0) return pw(x, y);
    uint b = floatBitsToUint(x);
    float g = uintBitsToFloat(b & 0xFFFFE000u);
    uint i = (b >> 13u) - 114688u;
    vec4 t = texelFetch(uPotencia, ivec2(int(i & 127u), int(i >> 7u)), 0);
    float hi = inversa ? t.z : t.x;
    float lo = inversa ? t.w : t.y;
    float d = (x - g) / g;
    float c2 = y * (y - 1.0) * 0.5;
    float c3 = c2 * (y - 2.0) * 0.33333334;
    float corr = d * (y + d * (c2 + d * c3));
    return hi + (lo + hi * corr);
}

vec3 hslCores(vec3 x0) {
    vec3 c = max(x0, 0.0);
    float m = max(max(c.r, c.g), c.b);
    bool acima = m > 1.0;
    if (acima) c = vec3(divExata(c.r, m), divExata(c.g, m), divExata(c.b, m));
    vec3 hsl = paraHsl(c);
    vec4 t = texelFetch(uHsl, ivec2(clamp(int(floor(hsl.x * 1024.0)), 0, 1023), 0), 0);
    if (uMatiz) c = deHsl(clamp(t.x, 0.0, 1.0), clamp(hsl.y, 0.0, 1.0), clamp(hsl.z, 0.0, 1.0));
    if (acima) c = c * m;
    float Y = dot(c, LUMA);
    vec3 lin = vec3(potPrecisa(c.r, false), potPrecisa(c.g, false), potPrecisa(c.b, false));
    if (uSaturacao) {
        float yl = dot(lin, LUMA);
        float k = max(t.y + 1.0, 0.0);
        lin = lin * k + yl * (1.0 - k);
    }
    if (uLuminancia) {
        vec3 dd = x0 - Y;
        float dist = sqrt(dd.r * dd.r + dd.g * dd.g + dd.b * dd.b);
        float a = clamp((-0.04 - Y * 0.02) + dist, 0.0, 1.0);
        float w = clamp(a / (Y * 0.04 + 0.08), 0.0, 1.0);
        lin = max(w * t.z + 1.0, 0.0) * lin;
    }
    lin = max(lin, 0.0);
    return vec3(potPrecisa(lin.r, true), potPrecisa(lin.g, true), potPrecisa(lin.b, true));
}

// ---------------------------------------------------------------- 4. Hue Rotation
vec3 girarMatiz(vec3 x) {
    float m = max(max(x.r, x.g), x.b);
    bool acima = m > 1.0;
    vec3 c = acima ? x / m : x;
    vec3 hsl = paraHsl(c);
    float h = clamp(max(fract(hsl.x + uRotV), 0.0), 0.0, 1.0);
    float s = min(max(hsl.y, 0.0), 1.0);
    float l = min(max(hsl.z, 0.0), 1.0);
    vec3 o = deHsl(h, s, l);
    return acima ? o * m : o;
}

// ---------------------------------------------------------------- 6/7. Curves2
float curva(highp sampler2D t, int canal, float c, float lim, float incl, float fim) {
    float x = max(c, 0.0);
    float a = amostra1d(t, 0, x + 0.000244140625)[canal];
    return x < lim ? a : (x - lim) * incl + fim;
}

// ---------------------------------------------------------------- 8. SaturationEq
vec3 saturacaoEq(vec3 c) {
    float mn = min(c.r, min(c.g, c.b));
    float mx = max(c.r, max(c.g, c.b));
    float S = 0.0;
    if (!(mx == 0.0 || mn == mx)) {
        float soma = mx + mn;
        float L = soma * 0.5;
        S = (mx - mn) / (L <= 0.5 ? soma : (2.0 - mn) - mx);
        // acima de 1 (perto do branco, depois da exposição) o denominador zera: a textura do AE prende o ±infinito
        // na borda; a amostragem à mão faria NaN (r5: 3 presets com 1 a 3 pixels pretos)
        if (isinf(S)) S = S > 0.0 ? 4.0 : -4.0;
        if (isnan(S)) S = 0.0;
    }
    float l709 = dot(c, vec3(0.2125999927520752, 0.7152000069618225, 0.0722000002861023));
    float f0 = amostra1d(uSatEqT, 0, l709).x;
    float f1 = amostra1d(uSatEqT, 0, S).y;
    float k = f1 * f0;
    float l2 = dot(c, vec3(0.30980393290519714, 0.6078431606292725, 0.08235294371843338));
    return k * (c - l2) + l2;
}

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 orig = px.rgb;
    vec3 y = orig;
    if (uRodas) {
        y = meia(vec3(
            lgg2(y.r, uLggM1.r, uLggA.r, uLggGain.r, uLggGama.r, uLggInvG.r, uLggK.r, uLggR8.r, uLggR9.r),
            lgg2(y.g, uLggM1.g, uLggA.g, uLggGain.g, uLggGama.g, uLggInvG.g, uLggK.g, uLggR8.g, uLggR9.g),
            lgg2(y.b, uLggM1.b, uLggA.b, uLggGain.b, uLggGama.b, uLggInvG.b, uLggK.b, uLggR8.b, uLggR9.b)));
    } else if (uExpo) {
        y = meia(y * uExpoGanho);
    }
    if (uTT) {
        vec4 v = vec4(y, px.a);
        y = meia(vec3(((v.x * uTT0.x + v.y * uTT0.y) + v.z * uTT0.z) + v.w * uTT0.w,
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
        y = meia(vec3(curva(uCurvaC, 0, y.r, uContFim.r, uContIncl.r, uContFim.r),
                      curva(uCurvaC, 1, y.g, uContFim.g, uContIncl.g, uContFim.g),
                      curva(uCurvaC, 2, y.b, uContFim.b, uContIncl.b, uContFim.b)));
    }
    if (uCurvasOn) {
        y = meia(vec3(curva(uCurvas, 0, y.r, 1.0, uCurvasIncl, uCurvasFim.r),
                      curva(uCurvas, 1, y.g, 1.0, uCurvasIncl, uCurvasFim.g),
                      curva(uCurvas, 2, y.b, 1.0, uCurvasIncl, uCurvasFim.b)));
    }
    if (uSatEq) y = meia(saturacaoEq(y));
    if (uMistura) y = meia((orig - y) * uMisturaS + y);
    fragColor = vec4(y, px.a);
}
