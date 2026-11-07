// O Strength do efeito do AE: mistura NO LINEAR, num passe próprio, o resultado com a saída do estágio de
// entrada (medido no AE: k = 0,70 para Strength 70; a força interna do Look, `strn`, não muda o render).
uniform highp sampler2D uOriginal;
uniform float uForca;
out vec4 fragColor;

void main() {
    vec4 x = texelFetch(uEntrada, pxMemoria(), 0);
    vec4 x0 = texelFetch(uOriginal, pxMemoria(), 0);
    fragColor = vec4(meia((x.rgb - x0.rgb) * uForca + x0.rgb), x.a);
}
