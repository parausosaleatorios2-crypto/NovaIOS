// A saída do Looks: linear -> sRGB (`CoreKernel_Linear_to_sRGB`) e 8 bits como o
// `CoreKernel_ConvertFloat4ToPackedBGRA`: min(255, max(0, v·255 + 0,5)), truncado. O alfa é o da entrada.
// Este passe desenha no buffer da cadeia (`uOriginal8`, a entrada do efeito): o retângulo da camada (de `uOrigem`,
// do tamanho `uTamanho`) recebe o resultado; fora dele fica o que já estava.
uniform highp sampler2D uOriginal8;
uniform ivec2 uOrigem;
out vec4 fragColor;

void main() {
    ivec2 p = ivec2(gl_FragCoord.xy);
    vec4 o = texelFetch(uOriginal8, p, 0);
    ivec2 q = p - uOrigem;
    if (any(lessThan(q, ivec2(0))) || any(greaterThanEqual(q, uTamanho))) {
        fragColor = o;
        return;
    }
    vec4 x = texelFetch(uEntrada, q, 0);
    vec3 y = meia(linearParaSrgb(x.rgb));
    vec3 k = floor(min(vec3(255.0), max(vec3(0.0), y * 255.0 + 0.5)));
    fragColor = vec4(k / 255.0, o.a);
}
