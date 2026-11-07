// uni.VHS — a cor, em um passe (na engine são vários passes ponto a ponto; cada etapa aqui grava `meia` como o alvo
// RGBA16F de lá):
//   lx.saturation(Saturation, 0, [0,0,0]): com os pesos ZERO, a cor só é multiplicada por Saturation/100 (o modo
//     Color depois refaz a luminância) — medido no AE: com os pesos de luma, 200% errava até 60 níveis;
//   fx.levels2(0, 100, 1,25, Black Level, 100) na luminosidade desfocada;
//   bx.color(…, troca): SetLum(croma, Lum(luma)) e a composição do modo;
//   o Interlace Error: a Fields.png (128 linhas, alfa 0/1 alternado) ampliada num cartão de H·(2·Scale), levels
//     (25, 75, 1,5), colorize de três tons (Color 1 → cinza → Color 2, pela luma 709) e bx.hardLight com a imagem;
//   fx.lut3D: a Tape Style — aqui uma grade 9³ ajustada à LUT do plugin (as .cube da Red Giant não vêm com o app).
// Da versão nova do plugin (os presets da pasta do snow): Enable Color Controls desligado = a cor do original
// direto no Color Mix; Color Mix mistura o resultado com o original; Tape Style "None" pula a LUT; o Sharpen
// (APROXIMADO — o AE do snow tem a 2.0, sem ele) é uma máscara de nitidez na luma: l + Mix·(l − l desfocada por
// Sharpen Radius ÷ 10), antes do levels.
uniform highp sampler2D uLuma;
uniform highp sampler2D uLumaBorrada;
uniform float uNitidez;    // Sharpen Mix / 100 (0 = sem o passe)
uniform highp sampler2D uOriginal;
uniform highp sampler3D uLut;
uniform bool uComLut;
uniform bool uControles;
uniform float uSat;        // Saturation / 100
uniform float uPreto;      // Black Level / 100
uniform float uMixCor;     // Color Mix / 100
uniform float uInterlace;  // Interlace Error / 100
uniform float uEscalaI;    // 2 · Scale
uniform vec3 uCor1;
uniform vec3 uCor2;
out vec4 fragColor;

float lum(vec3 c) { return 0.3 * c.r + 0.59 * c.g + 0.11 * c.b; }

vec3 clipColor(vec3 c) {
    float l = lum(c);
    float n = min(c.r, min(c.g, c.b));
    float x = max(c.r, max(c.g, c.b));
    if (n < 0.0) c = l + ((c - l) * l) / (l - n);
    if (x > 1.0) c = l + ((c - l) * (1.0 - l)) / (x - l);
    return c;
}

/** levels2 (valores já em fração): (x − ib)/(iw − ib), |x|^(1/γ) com o sinal, mix(ob, ow, ·). */
vec3 niveis(vec3 x, float ib, float iw, float invGama, float ob, float ow) {
    x = (x - ib) / (iw - ib);
    vec3 y = pow(abs(x), vec3(invGama)) * sign(x);
    return mix(vec3(ob), vec3(ow), y);
}

/** O cartão do interlace na linha y (px da engine, centro em +0,5): o alfa da Fields.png com o bilinear da GPU. */
float campos(float y) {
    float h = float(uTamanho.y);
    float ty = ((y - h * 0.5) / (h * uEscalaI) + 0.5) * 128.0 - 0.5;
    float t0 = floor(ty);
    float f = peso8(ty - t0);
    float a0 = mod(t0, 2.0) == 1.0 ? 1.0 : 0.0;
    return a0 * (1.0 - f) + (1.0 - a0) * f;
}

/** A LUT 9³ (RGBA16F, trilinear à mão). */
vec3 lut(vec3 c) {
    vec3 s = clamp(c, 0.0, 1.0) * 8.0;
    vec3 i0 = min(floor(s), vec3(7.0));
    vec3 f = s - i0;
    ivec3 a = ivec3(i0);
    vec3 r = vec3(0.0);
    for (int k = 0; k < 8; k++) {
        ivec3 d = ivec3(k & 1, (k >> 1) & 1, (k >> 2) & 1);
        vec3 w = mix(1.0 - f, f, vec3(d));
        r += w.x * w.y * w.z * texelFetch(uLut, a + d, 0).rgb;
    }
    return r;
}

void main() {
    ivec2 p = pxAe();
    vec4 orig = lerAe(uOriginal, p);
    vec4 t;
    if (uControles) {
        vec4 croma = lerAe(uEntrada, p);
        croma = meia(max(vec4(croma.rgb * uSat, croma.a), 0.000001));
        vec4 l = lerAe(uLuma, p);
        if (uNitidez > 0.0) l.rgb = meia(max(l.rgb + uNitidez * (l.rgb - lerAe(uLumaBorrada, p).rgb), 0.0));
        l = meia(vec4(niveis(l.rgb, 0.0, 1.0, 0.8, uPreto, 1.0), l.a));
        // bx.color com troca: fg = croma, bg = luma
        float a = clamp(croma.a + l.a - croma.a * l.a, 0.0, 1.0);
        vec3 o = clipColor(croma.rgb + (lum(l.rgb) - lum(croma.rgb))) * a;
        o = mistura(croma.rgb, o, l.a);
        o = mistura(l.rgb * l.a, o, croma.a);
        if (a != 0.0) o /= a;
        t = meia(vec4(o, a));
    } else {
        t = orig;
    }
    if (uMixCor < 1.0) t = meia(mistura(orig, t, uMixCor));
    if (uInterlace != 0.0) {
        float m = meia(campos(float(p.y) + 0.5));
        // levels e colorize fundidos num passe só na engine (_fx_44): sem `meia` entre eles
        vec3 q = niveis(vec3(m), 0.25, 0.75, 1.0 / 1.5, 0.0, 1.0);
        float lq = clamp(0.2126 * q.r + 0.7152 * q.g + 0.0722 * q.b, 0.0, 1.0);
        vec3 meio = vec3(0.5, 0.5, 0.5078431);
        vec3 novo = lq < 0.5 ? mistura(uCor1, meio, lq * 2.0) : mistura(meio, uCor2, (lq - 0.5) * 2.0);
        q = meia(max(novo, 0.0));
        // bx.hardLight com troca: fg = a imagem (decide), bg = o padrão (alfa 1 × Interlace Error)
        float ba = uInterlace;
        float a = clamp(t.a + ba - t.a * ba, 0.0, 1.0);
        vec3 f = t.rgb;
        vec3 hl = vec3(
            f.r < 0.5 ? 2.0 * q.r * f.r : 1.0 - (1.0 - q.r) * (1.0 - f.r) * 2.0,
            f.g < 0.5 ? 2.0 * q.g * f.g : 1.0 - (1.0 - q.g) * (1.0 - f.g) * 2.0,
            f.b < 0.5 ? 2.0 * q.b * f.b : 1.0 - (1.0 - q.b) * (1.0 - f.b) * 2.0) * a;
        hl = mistura(f, hl, ba);
        hl = mistura(q * ba, hl, t.a);
        if (a != 0.0) hl /= a;
        t = meia(vec4(hl, a));
    }
    if (uComLut) t = meia(vec4(lut(t.rgb), t.a));
    fragColor = t;
}
