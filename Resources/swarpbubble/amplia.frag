// Uma volta do laço do fnoise: a grade subdividida em x (se cabe), depois em y (se cabe), e — quando os dois
// ampliaram e ainda há oitava — a oitava nova somada com peso 1/2^oitava. O nó m da grade nova é o ponto
// desl + m da linha subdividida. Alvo RG32UI do tamanho da grade nova.
uniform highp usampler2D uGrade;
uniform ivec2 uAmplia;         // 1 = o eixo amplia nesta volta
uniform ivec2 uDesl;
uniform ivec2 uOrigemGrade;    // da grade NOVA (para o hash da oitava)
uniform int uSemente;
uniform int uOitava;           // −1 = sem oitava nesta volta
uniform float uPesoOitava;     // 2^−oitava
layout(location = 0) out uvec4 saida;

vec2 g(int x, int y) { return lerGrade(uGrade, ivec2(x, y)); }

/** A coluna m da grade nova (ampliada em x, se for o caso) na linha y da antiga. */
vec2 emX(int m, int y) {
    if (uAmplia.x == 0) return g(m, y);
    int p = uDesl.x + m;
    int k = p >> 1;
    return subdivide(p, g(k, y), g(k + 1, y), (p & 1) == 1 ? g(k + 2, y) : vec2(0.0));
}

void main() {
    ivec2 q = ivec2(gl_FragCoord.xy);
    vec2 v;
    if (uAmplia.y == 0) {
        v = emX(q.x, q.y);
    } else {
        int p = uDesl.y + q.y;
        int k = p >> 1;
        v = subdivide(p, emX(q.x, k), emX(q.x, k + 1), (p & 1) == 1 ? emX(q.x, k + 2) : vec2(0.0));
    }
    if (uOitava >= 0) v = no(uOrigemGrade + q, uSemente, uOitava) * uPesoOitava + v;
    saida = uvec4(floatBitsToUint(v), 0u, 0u);
}
