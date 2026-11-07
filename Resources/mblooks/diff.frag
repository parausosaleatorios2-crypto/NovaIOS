// Diffusion (`diff`, linear), último passe — `ColorKernel_Diffusion`, sobre a imagem (já com o pow do Highlight
// Bias) e o desfoque B dela (`gauss.comp` com o Size):
//   x = máx((B − 0,7)·1,025 + 0,7, 0)·tint;  m = mín(x, 1);  base = (1 − (1 − (1 − m)·HL)·c)·o
//   g = HL ≠ 0 ? x^(1 + HL) : x;  saída = máx(g·Grade/6 + base, 0)^(1/k)·2^Exposure Compensation
// HL = Highlights Only, c = (1 − Glow)·mín(1, Grade/6); o alfa é o da imagem. Host: ContasDoLooks.diffusion.
uniform highp sampler2D uBorrado;
uniform float uA;
uniform float uHl;
uniform float uC;
uniform float uD;
uniform float uE;
uniform vec3 uTint;
out vec4 fragColor;

vec3 pot(vec3 v, float k) {
    return vec3(v.r > 0.0 ? exp2(log2(v.r) * k) : 0.0, v.g > 0.0 ? exp2(log2(v.g) * k) : 0.0,
                v.b > 0.0 ? exp2(log2(v.b) * k) : 0.0);
}

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 b = texelFetch(uBorrado, pxMemoria(), 0).rgb;
    vec3 x = max((b + -0.7) * 1.025 + 0.7, 0.0) * uTint;
    vec3 m = min(x, 1.0);
    vec3 base = (1.0 - (1.0 - (1.0 - m) * uHl) * uC) * px.rgb;
    vec3 g = uHl != 0.0 ? pot(x, uHl + 1.0) : x;
    fragColor = vec4(meia(pot(g * uA + base, uE) * uD), px.a);
}
