// Pop (`pop2`, vídeo), Pop < 0, 2º passe — `FXKernel_Bilateral2` em meia resolução, no canto de cima: para
// x < ⌈W/2⌉ e y < ⌈H/2⌉, a média dos vizinhos (dx, dy) em [−r, r]² pesada por exp2(ks·(dx² + dy²))·exp2(kr·|Δcor|²)
// (ks e kr já × −log2 e no host), lendo a textura do `pop2reduz.frag` no CENTRO do texel com a borda presa no
// tamanho INTEIRO — o AE lê assim (o DXIL leria o canto do texel e deslocaria a imagem 1 px). Fora do canto: o
// original (`uOriginal`). O `pop2amplia.frag` amplia o canto de volta. Host: ContasDoLooks.pop; com raio grande o
// passe vai em faixas de linhas (PasseDoLooks.bilateral).
uniform highp sampler2D uOriginal;
uniform int uRaio;
uniform float uKs;
uniform float uKr;
out vec4 fragColor;

void main() {
    ivec2 p = pxAe();
    ivec2 canto = min(ivec2(ceil(vec2(uTamanho) * 0.5)), uTamanho);
    if (p.x >= canto.x || p.y >= canto.y) {
        fragColor = vec4(texelFetch(uOriginal, pxMemoria(), 0).rgb, 1.0);
        return;
    }
    ivec2 fim = uTamanho - 1;
    vec3 c0 = lerAe(uEntrada, p).rgb;
    vec3 soma = vec3(0.0);
    float peso = 0.0;
    for (int dy = -uRaio; dy <= uRaio; dy++) {
        for (int dx = -uRaio; dx <= uRaio; dx++) {
            vec3 s = lerAe(uEntrada, clamp(p + ivec2(dx, dy), ivec2(0), fim)).rgb;
            float ws = exp2(uKs * float(dx * dx + dy * dy));
            vec3 d = s - c0;
            float q = (d.r * d.r + d.g * d.g) + d.b * d.b;
            float wt = exp2(uKr * q) * ws;
            soma += wt * s;
            peso += wt;
        }
    }
    fragColor = vec4(meia(soma * (1.0 / peso)), 1.0);
}
