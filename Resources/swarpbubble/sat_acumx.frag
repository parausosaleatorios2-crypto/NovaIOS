// A tabela de somas (2/4): a soma de todos os trechos da linha até este (inclusive). Alvo RGBA32UI de ceil(W/8) × H.
uniform highp usampler2D uTrechos;
layout(location = 0) out uvec4 saida;

void main() {
    ivec2 q = ivec2(gl_FragCoord.xy);
    uvec4 s = uvec4(0u);
    for (int i = 0; i <= q.x; i++) s += texelFetch(uTrechos, ivec2(i, q.y), 0);
    saida = s;
}
