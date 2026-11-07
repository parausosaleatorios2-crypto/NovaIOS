// Optical Diffusion, uma camada — `GlowKernel_ApplyDiffusionLayer`: o realce borrado (uCamada) entra "over" no
// acumulador com o peso da camada: D = D·(1 − B.a·w) + B·w, gravado em float16 truncado. Na primeira camada o
// acumulador é zero (`uPrimeira`, sem textura).
uniform highp sampler2D uCamada;
uniform float uPeso;
uniform bool uPrimeira;
out vec4 fragColor;

void main() {
    vec4 d = uPrimeira ? vec4(0.0) : texelFetch(uEntrada, pxMemoria(), 0);
    vec4 b = texelFetch(uCamada, pxMemoria(), 0);
    fragColor = meia(d * (1.0 - b.a * uPeso) + b * uPeso);
}
