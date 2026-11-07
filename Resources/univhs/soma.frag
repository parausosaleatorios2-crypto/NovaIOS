// uni.VHS — os três canais de volta: bx.add(100, 100) duas vezes (azul + verde, depois + vermelho), o alfa preso.
uniform highp sampler2D uVerde;
uniform highp sampler2D uVermelho;
out vec4 fragColor;

vec4 mais(vec4 a, vec4 b) {
    vec4 s = a + b;
    s.a = clamp(s.a, 0.0, 1.0);
    return meia(s);
}

void main() {
    ivec2 p = pxAe();
    fragColor = mais(mais(lerAe(uEntrada, p), lerAe(uVerde, p)), lerAe(uVermelho, p));
}
