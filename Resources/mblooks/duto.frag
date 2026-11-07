// Duotone (`duto`, vídeo) — `ColorKernel_Duotone`: as duas cores tomam a luminância do pixel (o modo Color:
// SetLum + ClipColor, com o "máx" do kernel que ignora o verde) e se misturam por uma curva da luminosidade.
uniform vec3 uCorA;
uniform float uForcaA;
uniform vec3 uCorB;
uniform float uForcaB;
uniform float uLo;
uniform float uHi;
out vec4 fragColor;

float lum(vec3 c) { return c.r * 0.3 + c.g * 0.59 + c.b * 0.11; }

vec3 comLum(vec3 cor, float l1) {
    vec3 c = cor + (l1 - lum(cor));
    float l = lum(c);
    float n = min(c.r, min(c.g, c.b));
    float m = max(c.b, max(c.r, c.b));
    if (n < 0.0) c = (c - l) * l * (1.0 / (l - n)) + l;
    if (m > 1.0) c = (c - l) * (1.0 - l) * (1.0 / (m - l)) + l;
    return c;
}

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 x = px.rgb;
    float mn = min(x.r, min(x.g, x.b));
    float mx = max(x.r, max(x.g, x.b));
    float L = clamp((mx + mn) * 0.5, 0.0, 1.0);
    float den = uHi - uLo;
    float t = clamp(den != 0.0 ? (L - uLo) / den : 0.0, 0.0, 1.0);
    float a = clamp(t * 2.0, 0.0, 1.0);
    float w1 = a * a * 0.5;
    float b2 = clamp(1.0 - (t - 0.5) * 2.0, 0.0, 1.0);
    float w = clamp(0.5 - b2 * b2 * 0.5, 0.0, 1.0) + w1;
    float l1 = lum(x);
    vec3 ra = (comLum(uCorA, l1) - x) * uForcaA;
    vec3 rb = (comLum(uCorB, l1) - x) * uForcaB;
    fragColor = vec4(meia(x + rb + (ra - rb) * w), px.a);
}
