// uni.VHS — fx.setX: só o canal uCanal (0 = R, 1 = G, 2 = B) e o alfa do original.
uniform int uCanal;
out vec4 fragColor;

void main() {
    vec4 o = lerAe(uEntrada, pxAe());
    vec4 r = vec4(0.0, 0.0, 0.0, o.a);
    r[uCanal] = o[uCanal];
    fragColor = r;
}
