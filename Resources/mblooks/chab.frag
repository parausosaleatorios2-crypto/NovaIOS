// Chromatic Aberration (`chab`, linear) — `FXKernel_ChromAb`: cada canal amostrado com o próprio zoom a partir
// do centro (largura/2, altura/2), filtro linear. As escalas saem do host (`0x18043bfe0`): ContasDoLooks.chromAb.
uniform vec3 uEscala;
out vec4 fragColor;

float canal(int c, float s, vec2 centro, vec2 p) {
    vec2 pos = centro + 0.5 + (p - centro) * s;
    vec2 tam = vec2(uTamanho);
    vec2 uv = pos / tam;
    vec4 v = bilinear(uEntrada, uv * tam);
    return c == 0 ? v.r : (c == 1 ? v.g : v.b);
}

void main() {
    vec2 centro = vec2(uTamanho) * 0.5;
    vec2 p = vec2(pxAe());
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    fragColor = vec4(meia(vec3(canal(0, uEscala.x, centro, p), canal(1, uEscala.y, centro, p), canal(2, uEscala.z, centro, p))), px.a);
}
