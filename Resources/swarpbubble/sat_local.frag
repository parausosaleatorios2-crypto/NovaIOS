// A tabela de somas (3/4): L(x, y) = a soma, nas linhas do trecho de 8 linhas até y, de tudo à esquerda de x
// (inclusive). A soma da tabela inteira é L(x, y) + Y(x, y/8 − 1) (o passe 4). Alvo RGBA32UI de W × H.
uniform highp usampler2D uAcumX;
layout(location = 0) out uvec4 saida;

void main() {
    ivec2 q = ivec2(gl_FragCoord.xy);
    int sx = q.x >> 3;
    int x0 = sx << 3;
    int y0 = (q.y >> 3) << 3;
    uvec4 tot = uvec4(0u);
    for (int y = y0; y <= q.y; y++) {
        uvec4 r = sx > 0 ? texelFetch(uAcumX, ivec2(sx - 1, y), 0) : uvec4(0u);
        for (int x = x0; x <= q.x; x++) r += pre16(ivec2(x, y));
        tot += r;
    }
    saida = tot;
}
