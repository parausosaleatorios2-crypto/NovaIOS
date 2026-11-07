// Hue/Saturation (`husa`, vídeo) — o render do host (`0x1803f4820`) roda até dois kernels, cada um gravando o buffer
// (`meia(...)`, o float16 truncado do AE em 8 bpc): `ColorKernel_HueRotation` (Hue ≠ 0, em voltas) e
// `ColorKernel_Saturation` (Saturation ≠ 100) com os pesos da luma do próprio bloco. As mesmas contas das etapas 4 e 5
// do Colorista (`csta.frag`); o host é o ContasDoLooks.hueSaturation.
uniform bool uRot;
uniform float uRotV;
uniform bool uSat;
uniform float uSatV;
uniform vec3 uPesos;
out vec4 fragColor;

// ---------------------------------------------------------------- RGB ↔ HSL, na ordem do kernel
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

// ---------------------------------------------------------------- Hue Rotation (a divisão rápida, como no AE)
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

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 y = px.rgb;
    if (uRot) y = meia(girarMatiz(y));
    if (uSat) {
        float l = dot(y, uPesos);
        y = meia((y - l) * uSatV + l);
    }
    fragColor = vec4(y, px.a);
}
