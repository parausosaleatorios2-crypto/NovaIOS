// O blur do RASCUNHO (play/arraste; ver PasseDoLooks.blur), 1º passe: a média de cada bloco uFator.x × uFator.y
// da entrada (o último bloco, cortado na borda, pela média do que existe). Nunca roda na exportação nem na prévia
// parada: lá o gaussiano é o do motor, na resolução da camada.
out vec4 fragColor;

uniform ivec2 uFator;
uniform ivec2 uTamanhoCheio;

void main() {
    ivec2 p = pxAe() * uFator;
    ivec2 fim = min(p + uFator, uTamanhoCheio);
    vec4 s = vec4(0.0);
    for (int y = p.y; y < fim.y; y++) {
        for (int x = p.x; x < fim.x; x++) {
            ivec2 q = ivec2(x, uDePe ? uTamanhoCheio.y - 1 - y : y);
            s += texelFetch(uEntrada, q, 0);
        }
    }
    fragColor = s / float((fim.x - p.x) * (fim.y - p.y));
}
