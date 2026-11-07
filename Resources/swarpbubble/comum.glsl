// ============================================================================================================
//  S_WarpBubble (Sapphire) — o que todos os passes dividem (vem antes de cada shader desta pasta). A conta foi
//  lida na sapphire_ae.dll e conferida no After Effects: tools/swarpbubble/benchmark/LEIAME.md.
//
//  Os alvos internos guardam os bits do float32 em inteiros (RG32UI / RGBA32UI, renderizáveis em todo GLES 3.0):
//  a ida e a volta são exatas. Linha 0 de todo alvo interno = a linha de cima da camada (como o AE).
// ============================================================================================================

precision highp float;
precision highp int;
precision highp sampler2D;
precision highp usampler2D;

uniform ivec2 uTamanho;        // a camada do AE (W × H), em px do buffer

// ---- a camada no buffer da cadeia ----------------------------------------------------------------------------
uniform highp sampler2D uEntrada;
uniform ivec2 uOrigem;         // o canto da camada no buffer
uniform bool uDePe;            // a cena de pé conta as linhas ao contrário

/** O pixel (x, y) da camada (linha 0 = topo), reto, como o buffer o guarda. */
vec4 camada(ivec2 p) {
    if (uDePe) p.y = uTamanho.y - 1 - p.y;
    return texelFetch(uEntrada, p + uOrigem, 0);
}

uvec4 bytes(vec4 c) { return uvec4(floor(clamp(c, 0.0, 1.0) * 255.0 + 0.5)); }

/** A cor pré-multiplicada em inteiros, × 65025 (= 255²): r·a, g·a, b·a, a·255 — exata. */
uvec4 pre16(ivec2 p) {
    uvec4 b = bytes(camada(p));
    return uvec4(b.rgb * b.a, b.a * 255u);
}

// ---- o hash do Sapphire (fnoise.cxx) ---------------------------------------------------------------------------
// A tabela de 256 números de 32 bits (a mesma do S_FilmDamage e do S_TexturePlasma), num R32UI de 256 × 1.
uniform highp usampler2D uHash;

uint rodadas(uint c) {
    for (int i = 0; i < 4; i++) c = (c >> 8) + texelFetch(uHash, ivec2(int(c & 255u), 0), 0).r;
    return c;
}

/**
 * O nó (i, j) da grade, oitava `oitava`, nos DOIS canais do ruído: linha = h4(((−j)·16) ^ semente ^ oitava);
 * h = h4(linha + i); canal 0 = bits 0..12, canal 1 = bits 16..28; valor = (bits − 4096)/4096.
 */
vec2 no(ivec2 ij, int semente, int oitava) {
    uint linha = rodadas(uint(-ij.y * 16) ^ uint(semente) ^ uint(oitava));
    uint h = rodadas(linha + uint(ij.x));
    return vec2(float(int(h & 0x1FFFu) - 4096), float(int((h >> 16) & 0x1FFFu) - 4096)) * (1.0 / 4096.0);
}

vec2 lerGrade(highp usampler2D t, ivec2 p) { return uintBitsToFloat(texelFetch(t, p, 0).rg); }

/**
 * A subdivisão de B-spline cúbica do Sapphire (a variante AVX2), o ponto p da linha nova a partir de a[k], a[k+1],
 * a[k+2] (k = p >> 1): b[2k] = (a[k] + a[k+1])·0,5; b[2k+1] = (fma(a[k+1], 2, 1/4096) + (b[2k+2] + b[2k]))·0,25.
 */
vec2 subdivide(int p, vec2 a0, vec2 a1, vec2 a2) {
    vec2 m0 = (a0 + a1) * 0.5;
    if ((p & 1) == 0) return m0;
    vec2 m1 = (a1 + a2) * 0.5;
    return ((a1 * 2.0 + 1.0 / 4096.0) + (m1 + m0)) * 0.25;
}
