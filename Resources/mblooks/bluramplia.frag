// O blur do RASCUNHO, 3º passe (o 2º é o gaussiano do motor na cópia reduzida, com sigma / fator): a cópia
// borrada ampliada de volta ao tamanho da camada, bilinear com a borda presa. `uTamanho` é o da camada; a cópia
// tem `uTamanhoReduzido`.
out vec4 fragColor;

uniform ivec2 uFator;
uniform ivec2 uTamanhoReduzido;

vec4 reduzida(ivec2 q) {
    q = clamp(q, ivec2(0), uTamanhoReduzido - 1);
    if (uDePe) q.y = uTamanhoReduzido.y - 1 - q.y;
    return texelFetch(uEntrada, q, 0);
}

void main() {
    vec2 u = (vec2(pxAe()) + 0.5) / vec2(uFator) - 0.5;
    vec2 i0 = floor(u);
    vec2 f = u - i0;
    ivec2 a = ivec2(i0);
    vec4 topo = mix(reduzida(a), reduzida(a + ivec2(1, 0)), f.x);
    vec4 baixo = mix(reduzida(a + ivec2(0, 1)), reduzida(a + ivec2(1, 1)), f.x);
    fragColor = meia(mix(topo, baixo, f.y));
}
