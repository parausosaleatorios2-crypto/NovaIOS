// uni.VHS — a entrada: o retângulo da camada no buffer da cadeia (8 bits, reta) vira o "original" da engine
// (float16). Com Frame Style 4x3 e Image Offset, o fx.transform2 do começo do script: a camada deslocada uDesloc px
// para a direita (bilinear, transparente fora — "Edge Clamp" desligado).
uniform ivec2 uOrigem;
uniform float uDesloc;
out vec4 fragColor;

vec4 camada(ivec2 p) {
    if (any(lessThan(p, ivec2(0))) || any(greaterThanEqual(p, uTamanho))) return vec4(0.0);
    if (uDePe) p.y = uTamanho.y - 1 - p.y;
    return texelFetch(uEntrada, p + uOrigem, 0);
}

void main() {
    ivec2 p = pxAe();
    if (uDesloc == 0.0) {
        fragColor = meia(camada(p));
        return;
    }
    vec2 q = vec2(p) + 0.5 - vec2(uDesloc, 0.0) - 0.5;
    vec2 i0 = floor(q);
    vec2 f = vec2(peso8(q.x - i0.x), peso8(q.y - i0.y));
    ivec2 a = ivec2(i0);
    vec4 c0 = camada(a) * (1.0 - f.x) + camada(a + ivec2(1, 0)) * f.x;
    vec4 c1 = camada(a + ivec2(0, 1)) * (1.0 - f.x) + camada(a + ivec2(1, 1)) * f.x;
    fragColor = meia(c0 * (1.0 - f.y) + c1 * f.y);
}
