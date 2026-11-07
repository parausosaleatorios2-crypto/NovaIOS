// O começo do Radial Blur: a camada (já com os canais) passa para float16 (fx.blit), o alfa leva a máscara da
// borda (bx.lumaMask com a radial_mask) e vira a imagem POLAR (fx.fromPolar, op 0x163: x = ângulo, y = raio
// em px); depois é pré-multiplicada (o desfoque é feito na cor pré-multiplicada). Cada passe grava meia().
// `uEntrada` = a saída de canais.frag (RGBA8, do tamanho da camada).
uniform vec4 uMascA;
uniform vec4 uMascB;
uniform vec4 uMascC;
out vec4 fragColor;

const float PI = 3.1415926535897;

/** A imagem depois do lumaMask, no texel `p` (calculada na hora). */
vec4 mascarada(ivec2 p) {
    p = clamp(p, ivec2(0), uTamanho - 1);
    vec4 x = meia(lerAe(uEntrada, p));
    float m = mascara(vec2(p) + 0.5, uMascA, uMascB, uMascC);
    x.a *= (1.0 + 1.0 + 1.0) * 0.3333333 * m;
    return meia(x);
}

void main() {
    ivec2 p = pxAe();
    vec2 uv = vec2(p) + 0.5;
    vec2 w = vec2(uTamanho);
    float q = uv.x * (1.0 / w.x);
    float r = uv.y * (1.0 / w.y);
    q = q * PI * 2.0 - PI;
    float x = r * cos(q);
    float y = r * sin(q);
    x /= w.x * (1.0 / w.y);
    x += 0.5;
    y += 0.5;
    vec2 pos = vec2(x * w.x, y * w.y);
    vec2 qq = pos - 0.5;
    vec2 i0 = floor(qq);
    vec2 f = vec2(peso8(qq.x - i0.x), peso8(qq.y - i0.y));
    ivec2 a = ivec2(i0);
    vec4 c0 = mascarada(a) * (1.0 - f.x) + mascarada(a + ivec2(1, 0)) * f.x;
    vec4 c1 = mascarada(a + ivec2(0, 1)) * (1.0 - f.x) + mascarada(a + ivec2(1, 1)) * f.x;
    vec4 v = meia(c0 * (1.0 - f.y) + c1 * f.y);
    fragColor = meia(vec4(v.rgb * v.a, v.a));
}
