// Optical Diffusion (`odif`, linear), os realces — `GlowKernel_DiffusionHighlights`: a luma (Rec. 709) de
// rgb^0,45 passa por (L − lo)/(hi − lo)·(1 − c) + c e por uma curva em S suave; sai (rgb·m, m). O kernel grava
// float16 TRUNCADO (o compilador da AMD empacota com `v_cvt_pkrtz`) — a mesma `meia` do motor.
uniform float uLo;
uniform float uHi;
uniform float uC;
out vec4 fragColor;

void main() {
    vec3 rgb = texelFetch(uEntrada, pxMemoria(), 0).rgb;
    vec3 g = exp2(log2(rgb) * 0.45);
    float L = g.r * 0.2126 + g.g * 0.7152 + g.b * 0.0722;
    float v = uHi == uLo ? uC : (1.0 / (uHi - uLo)) * (1.0 - uC) * (L - uLo) + uC;
    v = clamp(v, 0.0, 1.0);
    float a = clamp(v * 2.0, 0.0, 1.0);
    a = a * a * 0.5;
    float b = clamp(1.0 - (v - 0.5) * 2.0, 0.0, 1.0);
    b = b * b * 0.5;
    float m = clamp(a + 0.5 - b, 0.0, 1.0);
    fragColor = meia(vec4(m * rgb, m));
}
