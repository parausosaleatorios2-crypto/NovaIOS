// A primeira parte do script: cada canal isolado (fx.setBlue/setGreen/setRed), escalado no centro com espelho
// (fx.tileMirror2, op 0x51) e torcido (fx.lensDistortion, op 0x20), e os três somados com bx.add (o modo
// "plus"). Tudo isto roda nos alvos RGBA8 da engine: cada passe guarda oito(meia(x)). Aqui é UM passe: a lente
// lê 4 texels do tileMirror, e cada texel do tileMirror é refeito (4 leituras da camada) — 48 leituras por px.
// A camada vem do buffer da cadeia (`uEntrada`, a partir de `uOrigem`); a saída é RGBA8, do tamanho da camada.
uniform ivec2 uOrigem;
uniform bvec3 uAtivo;          // distorção ≠ 0: só então o canal é escalado e torcido (o `if` do script)
uniform vec3 uInvEscala;       // 1/(escala·0,01) do tileMirror2, por canal
uniform vec4 uLenteA[3];       // (normx, normy, k, flatten·0,99) por canal
uniform vec3 uLenteB[3];       // (1/(1 − flatten), escala x, escala y) por canal
out vec4 fragColor;

/** O pixel (x, y) da camada como a engine o recebe (reta, 8 bits), com a borda presa. */
vec4 camada(ivec2 p) {
    p = clamp(p, ivec2(0), uTamanho - 1);
    if (uDePe) p.y = uTamanho.y - 1 - p.y;
    return texelFetch(uEntrada, p + uOrigem, 0);
}

/** Bilinear da camada, só o canal `c` e o alfa (os outros foram zerados pelo setX). */
vec2 bilinearCamada(vec2 pos, int c) {
    vec2 q = pos - 0.5;
    vec2 i0 = floor(q);
    vec2 f = vec2(peso8(q.x - i0.x), peso8(q.y - i0.y));
    ivec2 a = ivec2(i0);
    vec4 v00 = camada(a), v10 = camada(a + ivec2(1, 0)), v01 = camada(a + ivec2(0, 1)), v11 = camada(a + ivec2(1, 1));
    vec2 w00 = vec2(v00[c], v00.a), w10 = vec2(v10[c], v10.a), w01 = vec2(v01[c], v01.a), w11 = vec2(v11[c], v11.a);
    vec2 c0 = w00 * (1.0 - f.x) + w10 * f.x;
    vec2 c1 = w01 * (1.0 - f.x) + w11 * f.x;
    return c0 * (1.0 - f.y) + c1 * f.y;
}

/** O tileMirror2 no texel `p` (canal c e alfa), como fica no alvo RGBA8. */
vec2 espelho(ivec2 p, int c) {
    p = clamp(p, ivec2(0), uTamanho - 1);
    vec2 w = vec2(uTamanho);
    vec2 centro = w * 0.5;
    vec2 tuv = vec2(p) + 0.5;
    tuv -= centro;
    tuv *= vec2(uInvEscala[c]);
    tuv += centro;
    if (tuv.x <= 0.5 || tuv.x >= w.x - 1.5 || tuv.y <= 0.5 || tuv.y >= w.y - 1.5) {
        vec2 t2 = mod(tuv, w);
        if (mod(floor(tuv.x / w.x), 2.0) == 1.0) t2.x = w.x - t2.x;
        if (mod(floor(tuv.y / w.y), 2.0) == 1.0) t2.y = w.y - t2.y;
        tuv = t2;
    }
    vec2 v = bilinearCamada(tuv, c);
    return oito(vec4(meia(v.x), meia(v.y), 0.0, 0.0)).xy;
}

/** A lente do canal `c` no pixel `uv` (centro do pixel), lendo os texels do tileMirror. */
vec2 lente(vec2 uv, int c) {
    vec4 A = uLenteA[c];
    vec3 B = uLenteB[c];
    vec2 centro = vec2(uTamanho) * 0.5;
    vec2 t1 = uv - centro;
    t1 *= A.xy;
    vec2 t2 = t1 * t1;
    float t3 = t2.x + t2.y;
    if (A.w > 0.0) {
        t3 = sqrt(t3);
        t3 = t3 - A.w;
        t3 = max(t3, 0.0);
        t3 *= B.x;
        t3 *= t3;
    }
    if (A.z >= 0.0) t3 = t3 * A.z + 1.0;
    else t3 = t3 * A.z + 1.0 - A.z;
    t1 *= vec2(t3);
    vec2 pos = t1 * B.yz + centro;
    vec2 q = pos - 0.5;
    vec2 i0 = floor(q);
    vec2 f = vec2(peso8(q.x - i0.x), peso8(q.y - i0.y));
    ivec2 a = ivec2(i0);
    vec2 v00 = espelho(a, c), v10 = espelho(a + ivec2(1, 0), c), v01 = espelho(a + ivec2(0, 1), c), v11 = espelho(a + ivec2(1, 1), c);
    vec2 c0 = v00 * (1.0 - f.x) + v10 * f.x;
    vec2 c1 = v01 * (1.0 - f.x) + v11 * f.x;
    vec2 v = c0 * (1.0 - f.y) + c1 * f.y;
    return oito(vec4(meia(v.x), meia(v.y), 0.0, 0.0)).xy;
}

/** O canal `c` (e o alfa dele) no pixel `p`. */
vec2 canal(ivec2 p, int c) {
    if (!uAtivo[c]) {
        vec4 s = camada(p);
        return vec2(s[c], s.a);
    }
    return lente(vec2(p) + 0.5, c);
}

/** bx.add(100, 100): o modo "plus" (alfa em tela; rgb = fg + bg recomposto pelos alfas). */
vec4 soma(vec4 fg, vec4 bg) {
    float a = clamp(fg.a + bg.a - fg.a * bg.a, 0.0, 1.0);
    vec3 o = fg.rgb + bg.rgb;
    o *= a;
    vec3 bgp = bg.rgb * bg.a;
    o = mistura(fg.rgb, o, bg.a);
    o = mistura(bgp, o, fg.a);
    if (a != 0.0) o /= a;
    return vec4(o, a);
}

void main() {
    ivec2 p = pxAe();
    vec2 r = canal(p, 0), g = canal(p, 1), b = canal(p, 2);
    vec4 s = oito(meia(soma(vec4(0.0, 0.0, b.x, b.y), vec4(0.0, g.x, 0.0, g.y))));
    s = oito(meia(soma(s, vec4(r.x, 0.0, 0.0, r.y))));
    fragColor = s;
}
