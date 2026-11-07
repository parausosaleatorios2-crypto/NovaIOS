// O estágio de entrada do Looks: a camada (RGBA8, sRGB) vira float16 e passa para o LINEAR
// (`CoreKernel_ConvertPackedBGRAToFloat4` + `CoreKernel_sRGB_to_Linear`, cada um grava o seu buffer).
// `uOrigem`: onde a camada começa no buffer da cadeia do app (ela pode estar no meio de um buffer do tamanho da
// composição); o motor do Looks trabalha só no retângulo dela, do tamanho dela, como no After Effects.
uniform ivec2 uOrigem;
out vec4 fragColor;

void main() {
    vec4 v = meia(texelFetch(uEntrada, pxMemoria() + uOrigem, 0));
    fragColor = vec4(meia(srgbParaLinear(v.rgb)), v.a);
}
