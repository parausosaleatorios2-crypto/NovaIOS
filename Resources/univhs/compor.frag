// uni.VHS — a fita sobre a imagem (o bloco "Tape Noise Type ≠ None" do script):
//   gx.gray + bx.screen com o ruído + levels(γ 0,428) = o mapa neutro; fx.displacementMap pela média dele − 0,5
//     (uDist = Distortion/100 em x; bicúbico de 4 leituras, espelho nas bordas — o Gpu_DisplacementMap capturado);
//   bx.hardLight com o ruído por cima (o ruído decide; o alfa dele × Tape Noise);
//   bx.infront sobre o original (o alfa × (100 − Blend with Original)). O Blend só existe aqui, como no script.
uniform highp sampler2D uMapa;
uniform highp sampler2D uOriginal;
uniform vec2 uDist;
uniform float uMixRuido;
uniform float uMixFrente;
out vec4 fragColor;

vec4 cinza(ivec2 p) {
    vec3 n = lerAe(uMapa, p).rgb;
    vec3 s = meia(1.0 - 0.5 * (1.0 - n));
    return vec4(meia(pow(s, vec3(1.0 / 0.428))), 1.0);
}

vec4 cubica(float x) {
    float x2 = x * x;
    float x3 = x2 * x;
    return vec4(-x3 + 3.0 * x2 - 3.0 * x + 1.0, 3.0 * x3 - 6.0 * x2 + 4.0, -3.0 * x3 + 3.0 * x2 + 3.0 * x + 1.0, x3) / 6.0;
}

vec4 bicubica(vec2 uv, vec2 tc) {
    if (abs(uv.x - tc.x) < 0.5 && abs(uv.y - tc.y) < 0.5) return lerAe(uEntrada, ivec2(uv));
    float fx = fract(tc.x);
    float fy = fract(tc.y);
    tc -= vec2(fx, fy);
    vec4 xc = cubica(fx);
    vec4 yc = cubica(fy);
    vec4 c = vec4(tc.x - 0.5, tc.x + 1.5, tc.y - 0.5, tc.y + 1.5);
    vec4 s = vec4(xc.x + xc.y, xc.z + xc.w, yc.x + yc.y, yc.z + yc.w);
    vec4 o = c + vec4(xc.y, xc.w, yc.y, yc.w) / s;
    vec4 s0 = bilinear(uEntrada, vec2(o.x, o.z));
    vec4 s1 = bilinear(uEntrada, vec2(o.y, o.z));
    vec4 s2 = bilinear(uEntrada, vec2(o.x, o.w));
    vec4 s3 = bilinear(uEntrada, vec2(o.y, o.w));
    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);
    return mix(mix(s3, s2, sx), mix(s1, s0, sx), sy);
}

void main() {
    ivec2 p = pxAe();
    vec2 tam = vec2(uTamanho);
    vec2 uv = vec2(p) + 0.5;
    vec4 bg = cinza(p);
    // o shader da engine prende em 0,5 o que está entre 126,9/255 e 128,1/255
    bg = mix(bg, vec4(0.5), step(vec4(126.9 / 255.0), bg) * step(bg, vec4(128.1 / 255.0)));
    float m = (bg.r + bg.g + bg.b) * 0.333333 - 0.5;
    vec2 d = uv - m * uDist * tam;
    if (mod(floor(d.x / tam.x), 2.0) == 1.0) d.x = tam.x - mod(d.x, tam.x);
    if (mod(floor(d.y / tam.y), 2.0) == 1.0) d.y = tam.y - mod(d.y, tam.y);
    d = clamp(d, vec2(0.5), tam - 0.5);
    vec4 post = meia(bicubica(uv, d));
    // bx.hardLight: fg = o ruído (decide), bg = a imagem deslocada
    vec4 n = lerAe(uMapa, p);
    float fa = n.a * uMixRuido;
    float a = clamp(fa + post.a - fa * post.a, 0.0, 1.0);
    vec3 f = n.rgb;
    vec3 b = post.rgb;
    vec3 hl = vec3(
        f.r < 0.5 ? 2.0 * b.r * f.r : 1.0 - (1.0 - b.r) * (1.0 - f.r) * 2.0,
        f.g < 0.5 ? 2.0 * b.g * f.g : 1.0 - (1.0 - b.g) * (1.0 - f.g) * 2.0,
        f.b < 0.5 ? 2.0 * b.b * f.b : 1.0 - (1.0 - b.b) * (1.0 - f.b) * 2.0) * a;
    hl = mistura(f, hl, post.a);
    hl = mistura(b * post.a, hl, fa);
    if (a != 0.0) hl /= a;
    vec4 g = meia(vec4(hl, a));
    // bx.infront sobre o original
    vec4 o = lerAe(uOriginal, p);
    float ga = g.a * uMixFrente;
    float aa = clamp(ga + o.a - ga * o.a, 0.0, 1.0);
    vec3 r = g.rgb * ga + o.rgb * o.a * (1.0 - ga);
    if (aa != 0.0) r /= aa;
    fragColor = meia(vec4(r, aa));
}
