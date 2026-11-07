// A grade grossa do ruído (a oitava 0): o nó (origem + q) nos dois canais. Alvo RG32UI do tamanho da grade.
uniform ivec2 uOrigemGrade;
uniform int uSemente;
layout(location = 0) out uvec4 saida;

void main() {
    ivec2 q = ivec2(gl_FragCoord.xy);
    saida = uvec4(floatBitsToUint(no(uOrigemGrade + q, uSemente, 0)), 0u, 0u);
}
