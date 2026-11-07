// uni.VHS — bx.infront(100, 100, 100, 100): a camada uEntrada (a dobra desfocada) sobre uFundo, sem pré-multiplicar
// a saída.
uniform highp sampler2D uFundo;
out vec4 fragColor;

void main() {
    ivec2 p = pxAe();
    vec4 f = lerAe(uEntrada, p);
    vec4 b = lerAe(uFundo, p);
    float a = clamp(f.a + b.a - f.a * b.a, 0.0, 1.0);
    vec3 o = f.rgb * f.a + b.rgb * b.a * (1.0 - f.a);
    if (a != 0.0) o /= a;
    fragColor = meia(vec4(o, a));
}
