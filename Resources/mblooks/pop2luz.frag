// Pop (`pop2`, vídeo), Pop > 0, 1º passe — `FXKernel_Lightness`: a lightness HSL (máx + mín)/2, presa em 0..1, nos
// três canais. O gaussiano do motor (`gauss.comp`, o mesmo da Edge Softness) a desfoca, e o `pop2pos.frag` usa as
// duas. Host: ContasDoLooks.pop.
out vec4 fragColor;

void main() {
    vec4 px = texelFetch(uEntrada, pxMemoria(), 0);
    float mx = max(max(px.r, px.g), px.b);
    float mn = min(min(px.r, px.g), px.b);
    float l = meia(clamp((mx + mn) * 0.5, 0.0, 1.0));
    fragColor = vec4(l, l, l, 1.0);
}
