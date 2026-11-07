// Pop (`pop2`, vídeo), Pop < 0, 3º passe — `FXKernel_Upsample2`: o canto de meia resolução do `pop2bilateral.frag`
// ampliado de volta, filtro linear em x/2 + 1/4 (coluna par: ¼ da vizinha de antes + ¾; ímpar: ¾ + ¼ da de depois;
// o mesmo nas linhas), com a borda presa no tamanho inteiro. Host: ContasDoLooks.pop.
out vec4 fragColor;

void main() {
    ivec2 p = pxAe();
    vec2 u = vec2(p) * 0.5 - 0.25;
    vec2 i0 = floor(u);
    vec2 f = u - i0;
    ivec2 a = clamp(ivec2(i0), ivec2(0), uTamanho - 1);
    ivec2 b = clamp(ivec2(i0) + 1, ivec2(0), uTamanho - 1);
    vec3 t00 = lerAe(uEntrada, a).rgb;
    vec3 t01 = lerAe(uEntrada, ivec2(b.x, a.y)).rgb;
    vec3 t10 = lerAe(uEntrada, ivec2(a.x, b.y)).rgb;
    vec3 t11 = lerAe(uEntrada, b).rgb;
    vec3 topo = t00 + (t01 - t00) * f.x;
    vec3 baixo = t10 + (t11 - t10) * f.x;
    fragColor = vec4(meia(topo + (baixo - topo) * f.y), 1.0);
}
