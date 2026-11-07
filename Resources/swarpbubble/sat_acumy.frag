// A tabela de somas (4/4): Y(x, t) = a soma de tudo à esquerda de x (inclusive) nas linhas 0 .. fim do trecho t
// — os L do fim de cada trecho de 8 linhas até t, somados. Alvo RGBA32UI de W × ceil(H/8).
uniform highp usampler2D uLocal;
layout(location = 0) out uvec4 saida;

void main() {
    ivec2 q = ivec2(gl_FragCoord.xy);
    uvec4 s = uvec4(0u);
    for (int t = 0; t <= q.y; t++) s += texelFetch(uLocal, ivec2(q.x, min(t * 8 + 7, uTamanho.y - 1)), 0);
    saida = s;
}
