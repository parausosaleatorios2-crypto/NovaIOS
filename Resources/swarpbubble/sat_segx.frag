// A tabela de somas (1/4): a soma da cor pré-multiplicada (inteiros × 65025) de cada trecho de 8 px de cada linha.
// Alvo RGBA32UI de ceil(W/8) × H. As somas são módulo 2^32: a diferença de quatro cantos é exata enquanto o bloco
// somar menos de 2^32 (65 mil px — muito além dos níveis que o efeito usa).
layout(location = 0) out uvec4 saida;

void main() {
    ivec2 q = ivec2(gl_FragCoord.xy);
    int x0 = q.x * 8;
    uvec4 s = uvec4(0u);
    for (int i = 0; i < 8; i++) {
        int x = x0 + i;
        if (x >= uTamanho.x) break;
        s += pre16(ivec2(x, q.y));
    }
    saida = s;
}
