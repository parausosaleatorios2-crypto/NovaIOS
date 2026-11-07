// Pop (`pop2`, vídeo), Pop < 0, último passe — `FXKernel_Pop2Neg`: o + (bil − o)·k·peso por canal, o peso dos
// meios-tons vezes o do Preserve Detail clamp(1 − inclinação·(máx|Δ| + mín|Δ|)), Δ = o − bil. A inclinação é
// 50·d^2,5 (d = Preserve/100), medida no AE na varredura `pop_d` — o DXIL dizia d·0,5, bem mais fraco.
// Host: ContasDoLooks.pop.
uniform highp sampler2D uBil;
uniform float uK;
uniform float uInclinacao;
out vec4 fragColor;

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 o = px.rgb;
    vec3 b = texelFetch(uBil, pxMemoria(), 0).rgb;
    float m = (max(max(o.r, o.g), o.b) + min(min(o.r, o.g), o.b)) * 1.25;
    float peso = clamp(m + -0.125, 0.0, 1.0) * clamp(2.375 - m, 0.0, 1.0);
    vec3 a = abs(o - b);
    float s = max(max(a.r, a.g), a.b) + min(min(a.r, a.g), a.b);
    float w = peso * clamp(1.0 - uInclinacao * s, 0.0, 1.0);
    fragColor = vec4(meia(((b - o) * uK) * w + o), px.a);
}
