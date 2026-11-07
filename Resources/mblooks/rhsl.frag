// HSL Colors (`rhsl`, vídeo) — `ColorKernel_RangedHSL`: o pixel vai a HSL; a textura do host (`uHsl`, 1024 × 1:
// matiz novo, saturação, luminância, montada por `ContasDoLooks.hslColors` — `0x180402410` no DLL) é lida no
// matiz do pixel com filtro PONTO (o host a liga assim; o Mojo II, linear); com a parte do matiz ligada o pixel
// volta de HSL com o matiz novo. Saturação e luminância são feitas em gama 2,2 (`pow`), e a luminância só pega
// onde o pixel tem cor (a distância dele à luma, Rec. 709). Cada parte liga se algum dos 8 valores dela é ≠ 0.
uniform highp sampler2D uHsl;
uniform bool uMatiz;
uniform bool uSaturacao;
uniform bool uLuminancia;
out vec4 fragColor;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

float pw(float x, float e) { return exp2(log2(x) * e); }

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 x0 = px.rgb;
    vec3 c = max(x0, 0.0);
    float m = max(max(c.r, c.g), c.b);
    bool acima = m > 1.0;
    if (acima) c = (1.0 / m) * c;

    // RGB -> HSL, na ordem do kernel
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
    vec4 t = texelFetch(uHsl, ivec2(clamp(int(floor(H * 1024.0)), 0, 1023), 0), 0);

    if (uMatiz) {
        float h = clamp(t.x, 0.0, 1.0);
        float s = clamp(S, 0.0, 1.0);
        float l = clamp(L, 0.0, 1.0);
        if (l == 0.0) {
            c = vec3(0.0);
        } else if (s == 0.0) {
            c = vec3(l);
        } else {
            float q = l <= 0.5 ? l * s + l : (l + s) - l * s;
            float p = l * 2.0 - q;
            float h6 = h * 6.0;
            float d = q - p;
            if (!(h6 > 1.0)) {
                c = vec3(q, d * h6 + p, p);
            } else if (!(h6 > 3.0)) {
                c = h6 <= 2.0 ? vec3(d * (2.0 - h6) + p, q, p) : vec3(p, q, d * (h6 + -2.0) + p);
            } else if (!(h6 > 5.0)) {
                c = h6 <= 4.0 ? vec3(p, d * (4.0 - h6) + p, q) : vec3(d * (h6 + -4.0) + p, p, q);
            } else {
                c = vec3(q, p, d * (6.0 - h6) + p);
            }
        }
    }
    if (acima) c = c * m;

    float Y = dot(c, LUMA);
    vec3 lin = vec3(pw(c.r, 2.2), pw(c.g, 2.2), pw(c.b, 2.2));
    if (uSaturacao) {
        float yl = dot(lin, LUMA);
        lin = max(t.y + 1.0, 0.0) * (lin - yl) + yl;
    }
    if (uLuminancia) {
        vec3 dd = x0 - Y;
        float dist = sqrt(dd.r * dd.r + dd.g * dd.g + dd.b * dd.b);
        float a = clamp((-0.04 - Y * 0.02) + dist, 0.0, 1.0);
        float w = clamp(a / (Y * 0.04 + 0.08), 0.0, 1.0);
        lin = max(w * t.z + 1.0, 0.0) * lin;
    }
    lin = max(lin, 0.0);
    vec3 y = vec3(pw(lin.r, 0.45454544), pw(lin.g, 0.45454544), pw(lin.b, 0.45454544));
    fragColor = vec4(meia(y), px.a);
}
