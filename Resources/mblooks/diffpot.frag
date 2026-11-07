// Diffusion (`diff`, linear), 1º passe (só com Highlight Bias ≠ 0) — `CoreKernel_PowerKernel` no buffer da imagem:
// v^k por canal, k = 1 + bias (bias > 0) ou 1/(1 − bias); o alfa com 1. pow = exp2(log2(máx(v, 0))·k). O
// gaussiano e o `diff.frag` leem ESTE buffer, e o último passe desfaz o pow com 1/k. Host: ContasDoLooks.diffusion.
uniform float uK;
out vec4 fragColor;

float pot(float v, float k) { return v > 0.0 ? exp2(log2(v) * k) : 0.0; }

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    fragColor = vec4(meia(vec3(pot(px.r, uK), pot(px.g, uK), pot(px.b, uK))), px.a);
}
