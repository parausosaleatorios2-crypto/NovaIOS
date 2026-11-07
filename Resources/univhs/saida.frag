// uni.VHS — a saída: o Frame Jitter (fx.tileClamp: a imagem deslocada uTremor px na vertical, borda presa), o
// recorte do Frame Style 4x3 (fx.crop), e — da versão nova do plugin — o Post Noise e o Render Alpha; o resultado
// vira 8 bits no retângulo da camada; fora dele fica o buffer da cadeia (`uOriginal8`).
uniform highp sampler2D uOriginal8;
uniform ivec2 uOrigem;
uniform float uTremor;
uniform vec2 uCorte;      // [x0, x1] em fração da largura; (0, 1) = sem recorte
uniform float uPosRuido;  // Post Noise / 100
uniform int uSementeQuadro;
uniform bool uAlfa;       // Render Alpha
out vec4 fragColor;

uint mistura32(uint x) {
    x ^= x >> 16; x *= 0x7feb352du;
    x ^= x >> 15; x *= 0x846ca68bu;
    x ^= x >> 16;
    return x;
}

void main() {
    ivec2 m = ivec2(gl_FragCoord.xy);
    vec4 o8 = texelFetch(uOriginal8, m, 0);
    ivec2 q = m - uOrigem;
    if (any(lessThan(q, ivec2(0))) || any(greaterThanEqual(q, uTamanho))) {
        fragColor = o8;
        return;
    }
    ivec2 p = q;
    if (uDePe) p.y = uTamanho.y - 1 - p.y;
    vec2 tam = vec2(uTamanho);
    vec2 uv = vec2(p) + 0.5;
    vec4 t = uTremor == 0.0 ? lerAe(uEntrada, p) : meia(bilinear(uEntrada, clamp(uv - vec2(0.0, uTremor), vec2(0.0), tam)));
    if (uv.x < uCorte.x * tam.x || uv.x > uCorte.y * tam.x) t = vec4(0.0);
    if (uPosRuido > 0.0) {
        uint h = mistura32(uint(p.x) * 0x9E3779B1u ^ mistura32(uint(p.y) * 0x85EBCA77u ^ uint(uSementeQuadro)));
        t.rgb += (float(h >> 8) * (1.0 / 16777216.0) - 0.5) * uPosRuido;
    }
    if (!uAlfa) t.a = 1.0;
    fragColor = oito(t);
}
