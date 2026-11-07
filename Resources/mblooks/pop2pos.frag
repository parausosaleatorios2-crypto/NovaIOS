// Pop (`pop2`, vídeo), Pop > 0, último passe — `FXKernel_Pop2Pos` como o AE o roda (medido na rodada `pop`; o DXIL
// somava a diferença de luma nos três canais, e o vermelho puro saía 12 níveis abaixo): a lightness L ganha
// k·(L − L desfocada), presa em 0..1 e pesada pelos meios-tons; a cor sai com a lightness nova e o MESMO matiz e
// saturação HSL — L' + (o − L)·f(L')/f(L), f(t) = 1 − |2t − 1|. Onde f(L) = 0 (preto ou branco, ou L presa em 1
// acima do branco) a cor nova é a própria lightness. L é recalculada da cor SEM o float16 do `pop2luz.frag` (esse
// só vai para o desfoque): com ele, 2,6% dos valores saíam 1 nível abaixo do AE. Host: ContasDoLooks.pop.
uniform highp sampler2D uBorrado;
uniform float uK;
out vec4 fragColor;

float faixa(float t) { return 1.0 - abs(2.0 * t - 1.0); }

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    vec3 o = px.rgb;
    float mx = max(max(o.r, o.g), o.b);
    float mn = min(min(o.r, o.g), o.b);
    float l = clamp((mx + mn) * 0.5, 0.0, 1.0);
    float lb = texelFetch(uBorrado, pxMemoria(), 0).r;
    float m = (mx + mn) * 1.25;
    float peso = clamp(m + -0.125, 0.0, 1.0) * clamp(2.375 - m, 0.0, 1.0);
    float d = uK * (l - lb);
    float ln = (clamp(l + d, 0.0, 1.0) - l) * peso + l;
    float fl = faixa(l);
    vec3 y = fl == 0.0 ? vec3(ln) : ln + (o - l) * (faixa(ln) / fl);
    fragColor = vec4(meia(y), px.a);
}
