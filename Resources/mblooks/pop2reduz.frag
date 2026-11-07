// Pop (`pop2`, vídeo), Pop < 0, 1º passe — `CoreKernel_Downsample2` no canto de cima de uma CÓPIA do original: o
// pixel (x, y) do AE com x < W/2 e y < H/2 (inteiros) vira a média do bloco 2×2 em (2x, 2y), o vizinho da direita e
// o de baixo presos na última coluna e linha; o resto fica o original. É a textura que o `pop2bilateral.frag` lê — e,
// perto da borda do canto, ele lê também o original de fora dele, como o AE. Host: ContasDoLooks.pop.
out vec4 fragColor;

void main() {
    ivec2 p = pxAe();
    ivec2 metade = uTamanho / 2;
    if (p.x >= metade.x || p.y >= metade.y) {
        fragColor = vec4(texelFetch(uEntrada, pxMemoria(), 0).rgb, 1.0);
        return;
    }
    ivec2 q = p * 2;
    int x1 = q.x < uTamanho.x - 1 ? q.x + 1 : q.x;
    int y1 = q.y < uTamanho.y - 1 ? q.y + 1 : q.y;
    vec3 a = lerAe(uEntrada, q).rgb;
    vec3 b = lerAe(uEntrada, ivec2(x1, q.y)).rgb;
    vec3 c = lerAe(uEntrada, ivec2(q.x, y1)).rgb;
    vec3 d = lerAe(uEntrada, ivec2(x1, y1)).rgb;
    fragColor = vec4(meia((((b + a) + c) + d) * 0.25), 1.0);
}
