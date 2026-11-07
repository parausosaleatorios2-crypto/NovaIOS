// A troca de espaço entre ferramentas: o motor só converte quando a próxima pede o outro espaço.
// uParaVideo: linear -> sRGB codificado; falso: o contrário. (Cada conversão corta o negativo em 0.)
uniform bool uParaVideo;
out vec4 fragColor;

void main() {
    vec4 x = texelFetch(uEntrada, pxMemoria(), 0);
    fragColor = vec4(meia(uParaVideo ? linearParaSrgb(x.rgb) : srgbParaLinear(x.rgb)), x.a);
}
