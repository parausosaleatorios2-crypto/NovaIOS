// Optical Diffusion, o fim: out = acumulador·2^brilho + (1 − alfa do acumulador)·imagem.
uniform highp sampler2D uAcumulador;
uniform float uGanho;
out vec4 fragColor;

void main() {
    vec4 x = texelFetch(uEntrada, pxMemoria(), 0);
    vec4 d = texelFetch(uAcumulador, pxMemoria(), 0);
    fragColor = vec4(meia(d.rgb * uGanho + (1.0 - d.a) * x.rgb), x.a);
}
