// A saída: o resultado da engine (float16) vira 8 bits como o AE o recebe, no retângulo da camada; fora dele
// fica o buffer da cadeia como estava (`uOriginal8`).
uniform highp sampler2D uOriginal8;
uniform ivec2 uOrigem;
out vec4 fragColor;

void main() {
    ivec2 m = ivec2(gl_FragCoord.xy);
    vec4 o = texelFetch(uOriginal8, m, 0);
    ivec2 q = m - uOrigem;
    if (any(lessThan(q, ivec2(0))) || any(greaterThanEqual(q, uTamanho))) {
        fragColor = o;
        return;
    }
    fragColor = oito(texelFetch(uEntrada, q, 0));
}
